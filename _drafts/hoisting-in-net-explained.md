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

I didn't have a clue about where to start, so that I started from the main JIT function, namely [`CILJit::compileMethod` function][github-compiler-compilemethod], went down the call stack to the interesting part in [the `Compiler::compCompile` method][github-compiler-compcompile]. It's the main entry point and the place where all magic happens. It consists of [a lot of JIT phases][github-jitphases], from initialization and expression tree generation, to optimizations and code generation. From numerous of optimizations, there is the hoisting optimization too.

The entry point for it is [`Compiler::optHoistLoopCode()`][github-optimizer-optHoistLoopCode]
It traverses all the loop nests, from the outer loop to the inner one.

The next interesting method is [`Compiler::optHoistThisLoop`][github-optimizer-optHoistThisLoop] that works with one loop at a time, it picks out only those that suits certain conditions:

* The loop should be a __"do-while"__ loop. This doesn't mean exactly `do {} while ()` keywords in your code. But that implies that the compiler knows that the loop will definitely be executed and conditions will be check at the end of an iteration. "For" loops will be transformed to do-while ones if possible.
* The loop shouldn't start from a `try {} catch {}` block. The compiler won't optimize it.
* The compiler won't bother optimizing code inside of a `catch {}` block.

TODO dominates

>And now we come close to what's called Basic Blocks. [__A Basic Block__][wiki-basicblocks] is an analysis unit for the compiler, a sequence of code with exactly one entry point and exactly one exit point. Whenever we enter a basic block, the code sequence is executed exactly once and in order. Each method is represented as a doubly linked list of basic blocks.

If the loop suits the conditions we continue with its content, namely the basic blocks. The compiler tries to find the set of definitely-executed basic blocks.
If the loop has only one exit then we take all [post-dominator][wiki-dominator] blocks for further analysis. If the loop has more than one exits then we take only __the first__ "entry" basic block because we assume that the entry block is definitely executed.

Then we iterate over selected blocks.

The compiler check block's weight TODO

A basic block contains a list of doubly-linked statements, which in their turn can be represented as an expression - tree of TODO
Then we iterate over each expression in the block and check whether we can hoist the expression or not. That logic happens in [`Compiler::optHoistLoopExprsForTree` method.][github-optimizer-optHoistLoopExprsForTree]

The expression can be hoisted if:

* All children of the expression tree are hoistable, then "tree" itself can be hoisted
* The expression tree is a CSE candidate. See below.
* The compiler supports call operations, but only calls to internal JIT helper methods. See below
* For now, we give up on an expression that might raise an exception if it is after the
* Currently we must give up on reads from static variables (even if we are in the first block). contradiction with CSE, issue? [github-staticvars]


#### CSE

Common Subexpression Elimination (CSE) - identifies redundant computations, which are then evaluated to a new temp lvlVar, and then reused.

The logic is in [`Compiler::optIsCSEcandidate`][github-optcse-optIsCSEcandidate] method.

Not if expression contains explicit assignment operator
No for structs and void?

Do not support float type on x86, as we currently can only enregister doubles
but x86 isn't supported, so that not relevant.

Do not support double/float constant 'dconst' il  can represent both float and doubles

Try to check the expression code execution cost, whether it worth to optimize or not. Heuristic?

The compiler supports call operations, but only calls to internal JIT helper methods. Generally all call operations are considered to have side-effects.
But we may have a helper call that doesn't have any important side effects.
The list of helper functions defined [in the corinfo.h file][github-helpers-list] and [the implementations in `jithelpers.cpp`][github-helpers]. So that some helper methods are considered as side-effects free.
[The logic behind][github-helpers-sideeffect]

In addition to all the above, the compiler can optimizer operation on constants, array's element and length, local variables access, some unary and binary operators, casts, comparison operators, math functions.










Checks is it worth to introduce a new temp variable or not.




Check if hoisting is profitable based on available registers.
optIsProfitableToHoistableTree


// TODO FP treated separately




P.S. Thank you for your time! I hope you found the post interesting and useful. There will be the part 2 with a bunch of examples. If you have an interesting case that you want to share or analyze, then you can send it to me to nikitin.alexandr.a at gmail.

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

  [github-docs-lch]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/Documentation/botr/ryujit-overview.md#loop-invariant-code-hoisting
  [google-hoisting]: https://www.google.com/search?q=Hoisting+.NET

  [github-compiler-compilemethod]: https://github.com/dotnet/coreclr/blob/master/src/jit/ee_il_dll.cpp#L140
  [github-compiler-compcompile]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/compiler.cpp#L2990

  [github-jitphases]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/Documentation/botr/ryujit-overview.md#phases-of-ryujit

  [github-optimizer-optHoistLoopCode]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/optimizer.cpp#L5401
  [github-optimizer-optHoistThisLoop]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/optimizer.cpp#L5554
  [github-optimizer-optHoistLoopExprsForTree]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/optimizer.cpp#L5862
  [github-optcse-optIsCSEcandidate]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/optcse.cpp#L1914


  [github-helpers-list]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/inc/corinfo.h#L266
  [github-helpers]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/vm/jithelpers.cpp
  [github-helpers-sideeffect]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/gentree.cpp#L10785
  [github-staticvars]: https://github.com/dotnet/coreclr/issues/2157

  [wiki-hoisting]: https://en.wikipedia.org/wiki/Loop-invariant_code_motion
  [wiki-basicblocks]: https://en.wikipedia.org/wiki/Basic_block
  [wiki-reftransparency]: https://en.wikipedia.org/wiki/Referential_transparency
  [wiki-dominator]: https://en.wikipedia.org/wiki/Dominator_(graph_theory)
