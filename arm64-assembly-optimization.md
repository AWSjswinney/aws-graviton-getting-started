# Assembly Optimization Guide for Graviton Arm64 Processors

## Introduction

This document is a reference for software developers who want to optimize code
for Graviton Arm64 processors at the assembly level. Some of the documented
transforms could be applied to optimize code written in higher level languages
like C or C++, and in that respect this document is not restrictive to assembly
level programming.

The code patterns in this document could also be useful to spot inefficient code
generated for the hot code. Profilers such as Linux perf allow the inspection of
the assembly level code. During the review of the hot code, software developers
could reference this guide to find better ways to optimize inner loops.

Some techniques for writing optimized assembly:
1. Be aware of instruction level parallelism
1. Split data dependency chains
1. Modulo Scheduling
1. Use the widest load and store instructions possible, or use loads which match the data structure
1. Test everything and make no assumptions
1. Specialize functions for known input conditions
1. Know which code is hot and which is cold
1. Use efficient instructions

## Instruction Level Parallelism
When writing in C, or any higher level language, the programmer writes a sequence
of statements which are presumed to execute in strict sequence. In the following
example, each statement logically occurs after the previous one.

```c
int foo (int a, int b, int c)
{
    if (c < 0) {
        int d = a + b;
        return d;
    } else {
        int e = a * b;
        return e;
    }
}
```

However when we compile this code with gcc version 7.3 with `-O1`, this is the output:
```
foo(int, int, int):
    add     w3, w0, w1
    mul     w0, w0, w1
    cmp     w2, 0
    csel    w0, w0, w3, ge
    ret
```

Here we can see the add and the multiply instruction are executed independently
if the result of `c < 0`. The compiler knows that the CPU can execute these
instructions in parallel. If we use the machine code analyzer from the LLVM
project, we can can see what is happening. We will use Graviton2 as our target
platform, which uses the Neoverse-N1 core.

`llvm-mca -mcpu=neoverse-n1 -timeline -iterations 1 foo.s`
```
...
Timeline view:
Index     012345

[0,0]     DeER .   add  w3, w0, w1
[0,1]     DeeER.   mul  w0, w0, w1
[0,2]     DeE-R.   cmp  w2, #0
[0,3]     D==eER   csel w0, w0, w3, ge
[0,4]     DeE--R   ret
...
```

In this output we can see that all five instructions from this function are decoded
in parallel in the first cycle. Then in the second cycle the instructions for which
all dependencies are already resolved begin executing. There is only one instruction
which has dependencies: the conditional select, `csel`. The four remaining
instructions all begin executing, including the `ret` instruction at the end. In
effect, nearly the entire C function is executing in parallel. The
`csel` has to wait for the result of the comparison instruction to check
`c < 0` and the result of the multiplication. Even the return has
completed by this point and the CPU front end has already decoded
instructions in the return path and some of them will already be
executing as well.

It is important to understand this when writing assembly. Instructions
do not execute in the order they appear. Their effects will be logically
sequential, but execution order will not be.

When writing assembly for arm64 or any platform, be aware that the CPU has more
than one pipeline of different types. The types and quantities are outlined in
the Software Optimization Guide, often abbreviated as SWOG. The guide
for each Graviton processor is linked from the [main page of this
technical guide](README.md). Using this knowledge, the programmer can arrange instructions of
different types next to each other to take advantage of instruction level
parallelism, ILP. For example, interleaving load instructions with vector or
floating point instructions can keep both pipelines busy.


## Splitting data dependence chains

To increase instruction level parallelism it is possible to duplicate
computations. The redundant computations can execute in parallel as they belong
to different dependence chains.

For example, it is possible to issue several loads to break data dependent
instructions.  The data becomes available earlier and avoids stalls due to data
dependences.  Instead of using a load and an extract instructions:

```
ld1  {v0.16b}, [x1]
// v0 is available after ld1 finishes execution
ext  v1.16b, v0.16b, v0.16b, #1   // x1 + 1
// v1 is available only after ld1 and ext finish execution
```
we can issue two independent loads that can execute in parallel:
```
ld1  {v0.16b}, [x1]
ld1  {v1.16b}, [x1, #1]     // x1 + 1
// v0 and v1 are available after the two independent ld1 instructions finish execution
// Both Graviton2 and Graviton3 will execute the two loads in parallel.
```

### Instruction selection and scheduling

ARM provides several Software Optimization Guides (SWOG) for each CPU:
- [Graviton2 - Neoverse-N1 SWOG](https://developer.arm.com/documentation/swog309707/a/)
- [Graviton3 - Neoverse-V1 SWOG](https://developer.arm.com/documentation/PJDOC-466751330-9685/0101/)

The SWOG documents for each instruction the latency (number of cycles it takes
to finish the execution of an instruction) and the throughput (the number of
similar instructions that can execute in parallel.) The SWOG also documents the
execution units that can execute an instruction. The information provided by the
SWOG is sometimes encoded in compilers (GCC and LLVM) under the form of specific
tuning flags for different CPUs. Tuning flags allow compilers to produce a good
instruction scheduling and a good instruction selection.

LLVM has a tool [llvm-mca](https://www.llvm.org/docs/CommandGuide/llvm-mca.html)
that allows software developers to see on their input assembly code how the
compiler reasons about the execution of instructions by a specific processor.


## Modulo scheduling

Data loaded for iteration `i` can be used in the next iteration `i + 1` by
keeping it in a register.  The registers used for modulo scheduling are pre-load
before the loop starts, and each iteration saves the data needed in the next
iteration in those registers.

## Use wide loads

Use the widest available load instruction compatible with the algorithm. In a
loop over and array of 4-byte integers, it is generally faster to load many at a
time than loading once per iteration. For example, this single instruction loads
16 4-byte values, for 64 bytes at once.

```
ld1 {v0.4s, v1.4s, v2.4s, v3.4s}, [x0], #64
```

The same is true for store operations.

## Test Everything

Do not make assumptions about performance; test everything.

While many optimizations are all but certain to improve things, not all
processors behave the same way and subtle or other unintuitive behaviors make it
essential to benchmark your code after every iteration of optimization. Create a
test harness which can execute the function you are working on independently and
benchmark it. Ideally this would be a standalone executable which can be
compiled and executed very quickly to allow rapid iteration without waiting on a
large application with a lengthy build process to complete.


## Specialization
When input conditions are known, write a specialized version of a function that
can allow skipping of entire branches, deeper unrolling, or skipping entire
chunks of code.

### Unrolling an inner loop
Suppose the following C code needs to be optimized:

```C
int foo(uint16_t *a, int a_size, uint16_t *b, int b_size, int16_t *dst)
{
    for (int i = 0; i < a_size; i++) {
        uint16_t v = 0;
        for (int j = 0; j < b_size; j++) {
            v += a[i] * b[j];
        }
        dst[i] = v;
    }
}
```

Suppose that you also know that 75% of the time this function is called,
`b_size == 16` and the other 25% it can be any other value. Armed with this
knowledge, it is possible to write a specialization of this function which tests
the `b_size` at the beginning and jumps to a special implementation which can
completely unroll the inner loop, eliminating a branch and allowing the use of a
single instruction which can load all of the values in `b` for each iteration of
`i`.

### Optimizing a dot product by a constant vector

When the data is known ahead of execution time, it is possible to specialize the
code based on the data. For example in the x265 encoder a filter is using the
constant coefficients that need to be multiplied by data read from memory and
then summing up all the results. The C code does the following:

```
const int16_t g_lumaFilter[4][NTAPS_LUMA] =
{
    {  0, 0,   0, 64,  0,   0, 0,  0 },
    { -1, 4, -10, 58, 17,  -5, 1,  0 },
    { -1, 4, -11, 40, 40, -11, 4, -1 },
    {  0, 1,  -5, 17, 58, -10, 4, -1 }
};
[...]
    const int16_t* coeff = g_lumaFilter[coeffIdx];
    for (int row = 0; row < blkheight; row++) {
        for (int col = 0; col < width; col++) {
            int sum;
            sum  = src[col + 0] * coeff[0];
            sum += src[col + 1] * coeff[1];
            sum += src[col + 2] * coeff[2];
            sum += src[col + 3] * coeff[3];
            sum += src[col + 4] * coeff[4];
            sum += src[col + 5] * coeff[5];
            sum += src[col + 6] * coeff[6];
            sum += src[col + 7] * coeff[7];
[...]
```

The C code generates 8 multiplies and 7 adds for each row in g_lumaFilter.
For g_lumaFilter[0] the assembly code only uses 1 shift left.
For g_lumaFilter[1], the assembly code only uses 4 multiplies, 1 shift left, and 6 adds:

```
//          a, b,   c,  d,  e,  f, g,  h
// .hword  -1, 4, -10, 58, 17, -5, 1,  0
    movi            v24.16b, #58
    movi            v25.16b, #10
    movi            v26.16b, #17
    movi            v27.16b, #5
[... loop logic ...]
    umull           v19.8h, v2.8b, v25.8b  // c*10
    umull           v17.8h, v3.8b, v24.8b  // d*58
    umull           v21.8h, v4.8b, v26.8b  // e*17
    umull           v23.8h, v5.8b, v27.8b  // f*5
    ushll           v18.8h, v1.8b, #2      // b*4
    sub             v17.8h, v17.8h, v19.8h // d*58 - c*10
    add             v17.8h, v17.8h, v21.8h // d*58 - c*10 + e*17
    usubl           v21.8h, v6.8b, v0.8b   // g - a
    add             v17.8h, v17.8h, v18.8h // d*58 - c*10 + e*17 + b*4
    sub             v21.8h, v21.8h, v23.8h // g - a - f*5
    add             v17.8h, v17.8h, v21.8h // d*58 - c*10 + e*17 + b*4 + g - a - f*5
```

## Know Which Code is Hot

An assembly implementation is only worth the effort for the most performance
critical of functions. However, even within such a function, there may be
necessary code which only executes a fraction of the number of times of an
inner loop. Pay attention to which parts of the code are in loops and which code
is supporting code, such as entry and exit code. Spend the most time optimizing
the loops and the least time optimizing "colder" code.

## Use efficient instructions

- When multiplying or dividing by powers of two, use shifts instead of multiply
and divide instructions.
- Use saturating shifts
- Use zip, uzip, instructions
