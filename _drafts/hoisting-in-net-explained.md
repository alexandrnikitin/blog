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

The documentation page has a short description of the Loop Code Hoisting. The knowledge that such kind of optimizations exist is already enough for development.
Searching [Google for hoisting][google-hoisting] doesn't show anything. But trivial examples of hoisting length of array and a lot of javascipt.

But we want to dig deeper, right?

The main entry point

It goes through the operations of
// importing, morphing, optimizations and code generation.  This is called from the EE through the
// code:CILJit::compileMethod function.  

[compiler-compCompile]


From numerous of optimizations, It has hoisting optimization too.

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




  [compiler-compCompile]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/compiler.cpp#L2990
  [github-docs-lch]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/Documentation/botr/ryujit-overview.md#loop-invariant-code-hoisting
  [google-hoisting]: https://www.google.com/?q=Hoisting+.NET
  [github-helpers-list]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/inc/corinfo.h#L266
  [github-helpers]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/vm/jithelpers.cpp
  [github-helpers-sideeffect]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/gentree.cpp#L10792
