---
layout: post
title: "Hoisting in .NET Explained"
date: 2015-11-24T10:59:52+02:00
modified:
categories: [.NET, CLR, JIT, Optimizations]
excerpt:
tags: [.NET, CLR, JIT, Optimizations]
comments: true
share: true
---

_Note: TODO RyuJIT related_


### Prelude

[__"Hoisting"__][wiki-hoisting] is a compiler optimization that moves loop-invariant code out of loops. __"Loop-invariant code"__ is code that is [referentially transparent][wiki-reftransparency] to the loop and can be replaced with its values, so that it doesn't change the semantic of the loop. This optimization improves run-time performance by executing the code only once rather than at each iteration.

#### An example
Let's take a look at the following example:

```csharp
public void Update(int[] arr, int x, int y)
{
    for (var i = 0; i < arr.Length; i++)
    {
        arr[i] = x + y;
    }
}
```

There's no point to calculate array's length at each iteration, it won't change and we can consider that code as loop-invariant one. The result of sum operation  of `x` and `y` will always be the same at each iteration. So that the code can be optimized and moved out of the loop in the following way:

```csharp
public void Update(int[] arr, int x, int y)
{
    var temp = x + y;
    var length = arr.Length;
    for (var i = 0; i < length; i++)
    {
        arr[i] = temp;
    }
}
```

These two methods are semantically the same and produce the same effect. That movement of some statements is called __"hoisting"__.


### What does JIT have to do with it?

Everything it can! And it does! JIT performs the hoisting optimization for us and even better us!!!


![Good news everyone!]({{ site.url }}/images/hoisting-in-net-explained/good-news.jpg)

Unfortunately, there's no information on the internet at all. Searching [Google for "hoisting .NET"][google-hoisting] doesn't show anything, but trivial examples of hoisting a length of an array and a lot of JavaScript. MSDN keep silent too. There's the RyuJIT overview page on github that has a short description of [the "Loop Code Hoisting".][github-docs-lch]
The fact that the hoisting optimization exists in JIT is already good enough to know. But good enough isn't enough, right? We're lucky ones, we have the sources of CoreCLR! Let's take a look at what is there.


### The sources

I didn't have a clue about where to start, so that I started from the main JIT function, namely [`CILJit::compileMethod` function][github-compiler-compilemethod], went down the call stack to the interesting part in [the `Compiler::compCompile` method][github-compiler-compcompile]. It's the main entry point and the place where all magic happens. It consists of [a lot of JIT phases][github-jitphases], from initialization and importing to optimizations and code generation.
From numerous of optimizations, there is hoisting optimization there.

The entry point void Compiler::optHoistLoopCode()


traverses all the loop nests, in outer-to-inner order

optHoistThisLoop

It should be a "do-while" loop. That doesn't mean exact `do {} while ()` loop in your code.
That means that the compiler can be sure that the loop will be executed at least once and condition can be check at the end of an iteration.

It shouldn't start from a try block. the compiler won't optimize.
And it won't bother hoisting when inside of a catch block.


Each method is represented as a doubly-linked list of BasicBlock objects.
BasicBlock nodes contain a list of doubly-linked statements.
Block is a method's building unit, a sequence of commands .

Then JIT tries to find the set of definitely-executed blocks. todo what's block?
If a loop has only one exit then we take all blocks.
If a loop has more than one exits then we take only first entry block because assume that the entry block is definitely executed.

Then iterate over blocks
Check block's weight

Iterate over block's statement expressions
Then the compiler tries to hoist statement expressions in block that are invariant in loop.
bool Compiler::optHoistLoopExprsForTree


Check tree of expressions

In addition check:

// Tree must be a suitable CSE candidate for us to be able to hoist it.
Common Subexpression Elimination (CSE) - identifies redundant computations, which are then evaluated to a new temp lvlVar, and then reused.
Checks is it worth to introduce a new temp variable or not.

Not if expression contains explicit assignment operator

No for structs and void?

Do not support float for x86, but x86 isn't supported, so that not relevant.
#ifdef _TARGET_X86_
    if (type == TYP_FLOAT)
    {
        // TODO-X86-CQ: Revisit this
        // Don't CSE a TYP_FLOAT on x86 as we currently can only enregister doubles
        return false;
    }



Do not support double/float constant 'dconst' il

    if (oper == GT_CNS_DBL)
    {
        // TODO-CQ: Revisit this
        // Don't try to CSE a GT_CNS_DBL as they can represent both float and doubles
        return false;
    }



expression code size cost
expression code execution cost



The compiler supports call operations, but only calls to internal JIT helper methods.
Generally all call operations are considered to have side-effects.
But we may have a helper call that doesn't have any important side effects.
The list of helper functions defined [here][github-helpers-list] and [their implementations][github-helpers].
So that some helper methods are considered as side-effects free.
[The logic behind][github-helpers-sideeffect]


The compiler can optimizer operation on constants,
array's element and length, local variables access, some unary and binary operators,
casts, comparison operators, math functions.




 For now, we give up on an expression that might raise an exception if it is after the


 // Currently we must give up on reads from static variables (even if we are in the first block).
 contradiction with operations, issue?
[github-staticvars]

Check if hoisting is profitable based on available registers.
optIsProfitableToHoistableTree


// TODO FP treated separately

if (floatVarsCount > 0)
{
    VARSET_TP VARSET_INIT_NOCOPY(loopFPVars,  VarSetOps::Intersection(this, loopVars, lvaFloatVars));
    VARSET_TP VARSET_INIT_NOCOPY(inOutFPVars, VarSetOps::Intersection(this,  pLoopDsc->lpVarInOut, lvaFloatVars));                                                        

    pLoopDsc->lpLoopVarFPCount     = VarSetOps::Count(this, loopFPVars);
    pLoopDsc->lpVarInOutFPCount    = VarSetOps::Count(this, inOutFPVars);
    pLoopDsc->lpHoistedFPExprCount = 0;

    pLoopDsc->lpLoopVarCount  -= pLoopDsc->lpLoopVarFPCount;
    pLoopDsc->lpVarInOutCount -= pLoopDsc->lpVarInOutFPCount;

}
else // (floatVarsCount == 0)
{
    pLoopDsc->lpLoopVarFPCount     = 0;
    pLoopDsc->lpVarInOutFPCount    = 0;
    pLoopDsc->lpHoistedFPExprCount = 0;
}


### Examples

The fun part.

array length

try block

var

static

jit helper

not do while loop

structs

many exits

  [github-compiler-compilemethod]: https://github.com/dotnet/coreclr/blob/master/src/jit/ee_il_dll.cpp#L140
  [github-compiler-compcompile]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/compiler.cpp#L2990
  [github-jitphases]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/Documentation/botr/ryujit-overview.md#phases-of-ryujit
  [github-docs-lch]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/Documentation/botr/ryujit-overview.md#loop-invariant-code-hoisting
  [google-hoisting]: https://www.google.com/?q=Hoisting+.NET
  [github-helpers-list]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/inc/corinfo.h#L266
  [github-helpers]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/vm/jithelpers.cpp
  [github-helpers-sideeffect]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/gentree.cpp#L10792
  [github-staticvars]: https://github.com/dotnet/coreclr/issues/2157

  [wiki-hoisting]: https://en.wikipedia.org/wiki/Loop-invariant_code_motion
  [wiki-basicblocks]: https://en.wikipedia.org/wiki/Basic_block
  [wiki-reftransparency]: https://en.wikipedia.org/wiki/Referential_transparency
