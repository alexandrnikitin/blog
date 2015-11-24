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


// We must have a do-while loop
if ((pLoopDsc->lpFlags & LPFLG_DO_WHILE) == 0)
    return;


// If DO-WHILE loop mark it as such.
if (head->bbNext == entry)
{
    optLoopTable[loopInd].lpFlags |= LPFLG_DO_WHILE;
}


// Try to find loops that have an iterator (i.e. for-like loops) "for (init; test; incr){ ... }"
// We have the following restrictions:
//     1. The loop condition must be a simple one i.e. only one JTRUE node
//     2. There must be a loop iterator (a local var) that is
//        incremented (decremented or lsh, rsh, mul) with a constant value
//     3. The iterator is incremented exactly once
//     4. The loop condition must use the iterator.



// if lbeg is the start of a new try block then we won't be able to hoist
if (!BasicBlock::sameTryRegion(head, lbeg))
    return;

// We don't bother hoisting when inside of a catch block
if ((lbeg->bbCatchTyp != BBCT_NONE) && (lbeg->bbCatchTyp != BBCT_FINALLY))
    return;



FP treated separately

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




Only one exit
if (pLoopDsc->lpFlags & LPFLG_ONE_EXIT)




else  // More than one exit
{
    // We'll assume that only the entry block is definitely executed.  
    // We could in the future do better.
    defExec.Push(pLoopDsc->lpEntry);
}

Check only entry block



Weight



bool Compiler::optHoistLoopExprsForTree


Check tree of expressions

In addition check:

// Tree must be a suitable CSE candidate for us to be able to hoist it.
treeIsHoistable = optIsCSEcandidate(tree);


Assignments or GTF_DONT_CSE
if  (tree->gtFlags & (GTF_ASG|GTF_DONT_CSE))
{
    return  false;
}


if (type == TYP_STRUCT || type == TYP_VOID)
    return false;


#ifdef _TARGET_X86_
    if (type == TYP_FLOAT)
    {
        // TODO-X86-CQ: Revisit this
        // Don't CSE a TYP_FLOAT on x86 as we currently can only enregister doubles
        return false;
    }
#else
    if (oper == GT_CNS_DBL)
    {
        // TODO-CQ: Revisit this
        // Don't try to CSE a GT_CNS_DBL as they can represent both float and doubles
        return false;
    }
#endif



expression code size cost
expression code execution cost


/* Check for some special cases */

switch (oper)
{
case GT_CALL:        
// If we have a simple helper call with no other persistent side-effects
// then we allow this tree to be a CSE candidate
//
if (gtTreeHasSideEffects(tree, GTF_PERSISTENT_SIDE_EFFECTS_IN_CSE) == false)
{
    return true;
}
else
{
    // Calls generally cannot be CSE-ed
    return false;
}

operations on

1. calls
Only JIT helper calls
  mutates heap
  cctor
  throw
  // If this is a Pure helper call or an allocator (that will not need to run a finalizer)

Check arguments too


2. constants

array oper

static
field

// Can't CSE a volatile LCL_VAR


 // CSE these Binary Operators

 Comparison

 Math


 // For now, we give up on an expression that might raise an exception if it is after the


 // Currently we must give up on reads from static variables (even if we are in the first block).
 contradiction with operations, issue?


optIsProfitableToHoistableTree
registers


  [compiler-compCompile]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/compiler.cpp#L2990
  [github-docs-lch]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/Documentation/botr/ryujit-overview.md#loop-invariant-code-hoisting
  [google-hoisting]: https://www.google.com/?q=Hoisting+.NET
