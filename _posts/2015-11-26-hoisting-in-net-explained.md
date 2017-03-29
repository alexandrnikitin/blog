---
layout: single
title: "Hoisting in .NET Explained"
date: 2015-11-26T17:59:46+02:00
modified: 2017-03-29T13:58:00+02:00
categories: [.NET]
excerpt: "Hoisting is a compiler optimization that moves loop-invariant code out of the loop. The post reveals hoisting in .NET and explains what code will be optimized and why."
tags: [.NET, CLR, JIT, High-performance]
comments: true
share: true
---

### Prelude

[__"Hoisting"__][wiki-hoisting] is a compiler optimization that moves loop-invariant code out of loops. __"Loop-invariant code"__ is code that is [referentially transparent][wiki-reftransparency] to the loop and can be replaced with its values, so that it doesn't change the semantic of the loop. This optimization improves runtime performance by executing the code only once rather than at each iteration.

#### An example
Let's take a look at the following code:

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


![Good news everyone!]({{ site.url }}{{ site.baseurl }}/images/hoisting-in-net-explained/good-news.jpg)

Unfortunately, there's no information on the internet at all. Searching [Google for "hoisting .NET"][google-hoisting] doesn't show anything, but trivial examples of hoisting a length of an array and a lot of JavaScript. MSDN keep silent too. There's the RyuJIT overview page on github that has a short description of [the "Loop Code Hoisting".][github-docs-lch]
The fact that the hoisting optimization exists in JIT is already a good sign and good enough to know. But good enough isn't enough for us, right? We're lucky ones, we have the sources of CoreCLR! Let's take a look at what is there.


### The sources

I didn't have a clue about where to start, so that I started from the main JIT function, namely [the `CILJit::compileMethod` function][github-compiler-compilemethod], went down the call stack to the interesting part in [the `Compiler::compCompile` method][github-compiler-compcompile]. It's the main entry point and the place where all magic happens. It consists of [a lot of JIT phases][github-jitphases], from initialization and expression tree generation, to optimizations and code generation. From numerous of optimizations, there is the hoisting optimization too.

The entry point for it is the [`Compiler::optHoistLoopCode()`][github-optimizer-optHoistLoopCode] method. It traverses all the loop nests, from the outer loop to the inner one and analyzes them.

#### Examine the loop

The next interesting method is [`Compiler::optHoistThisLoop`][github-optimizer-optHoistThisLoop] that works with one loop at a time, it picks out only those that meet certain conditions:

* The loop should be a "do-while" loop. This doesn't mean exactly `do {} while ()` keywords in your code. But that implies that the compiler knows that the loop will definitely be executed and conditions will be check at the end of an iteration. "For" loops will be transformed to "do-while" ones if possible.
* The loop shouldn't start from a `try {} catch {}` block. The compiler won't optimize it.
* The compiler won't bother optimizing code inside of a `catch {}` block too.

>And now we come close to what's called basic blocks. [__A basic block__][wiki-basicblocks] is a unit of analysis for the compiler, a sequence of code with exactly one entry point and exactly one exit point. Whenever we enter a basic block, the code sequence is executed exactly once and in order. Each method is represented as a doubly linked list of basic blocks.

If the loop meets the conditions we continue with its content, namely the basic blocks. The compiler tries to find the set of definitely-executed basic blocks.
If the loop has only one exit then we take all [post-dominator][wiki-dominator] blocks for further analysis. If the loop has more than one exits then we take only __the first__ "entry" basic block because we assume that the first block is definitely executed.

Then we iterate over the selected blocks.


#### Examine the basic block

The compiler calculates the basic block's "weight", and decides whether it's worth to optimize the block or not.  There's [a heuristic algorithm][github-lclvars-getBBWeight] behind that decision, which depends on several factors, such as the dynamic execution weight of this block, the number of times this block was called and some magic constants.

Each basic block contains a list of doubly-linked statements (operators), which in their turn can be represented as a tree of expressions. Then we iterate over each tree of expressions in the basic block.


#### Examine the expression

The expression is a unit that can be optimized and moved out of the loop body. The compiler checks whether we can hoist the expression or not. That logic happens in the [`Compiler::optHoistLoopExprsForTree` method.][github-optimizer-optHoistLoopExprsForTree]

The following conditions need to be met:

* All children of the expression tree should be hoistable
* The expression tree is a CSE candidate. Please see details below.
* The compiler supports `call` operations, but only calls to internal JIT helper methods. Please see details below.
* The compiler won't optimize an expression that might raise an exception
* It won't optimize reads from static variables


#### What the heck is CSE?

CSE stands for Common Subexpression Elimination. It's another type of optimization. It identifies redundant computations, which are then evaluated to new temp "variables", and then reused.  Hoisting can leverage it because they have pretty similar semantic. The logic is in the [`Compiler::optIsCSEcandidate`][github-optcse-optIsCSEcandidate] method.

The following conditions need to be met:

* The expression doesn't contain an assignment
* The type of the expression isn't `struct` and `void`
* The compiler doesn't optimize `float` types on x86
* The compiler doesn't optimize `double` and `float` types on x64
* It tries to check the expression's code execution cost, whether it worth to optimize or not, and won't optimize if savings are low.
* The optimizer supports `call` operations, but only calls to internal JIT helper methods. Generally all call operations are considered to have side-effects. But we may have a JIT helper call that doesn't have any side effects. The list of helper functions defined [in the corinfo.h file][github-helpers-list] and [the implementations in `jithelpers.cpp`][github-helpers]. So that some helper methods are considered as side-effects free.
[The logic behind][github-helpers-sideeffect] that check.

To addition to those restrictions, the compiler can optimize operations on constants, arrays' elements and lengths, local variables access, some unary and binary operators, casts, comparison operators, math functions.

If all those conditions are met, then we consider that the expression can be hoisted and moved out of the loop to its "header" block.

###  Final checks  

At this point, we have all suitable candidates for the optimization, but there are some final checks left before we can do that. The compiler performs additional validation of the tree and makes sure that it's safe to put it in the header.

Then it checks whether it's worth to introduce a new "variable" or not. The main focus is on available CPU registers. The advantage of using registers is speed, but CPUs have a limited number of them. So not all variables can be assigned to registers and some of them will be placed in the stack, which is much slower. If there's not enough registers the compiler won't hoist expressions that are not heavy. The logic resides in the [`Compiler::optIsProfitableToHoistableTree`][github-optimizer-optIsProfitableToHoistableTree] method.

And finally we're done! Thank you for your time! As you can see, hoisting exists in .NET! JIT performs a lot of sophisticated logic to make it work. I hope you found the post interesting and useful. There will be the part 2 with a bunch of examples. If you have an interesting case that you want to share or analyze, drop me a line please.


_P.S. The post is actual for RyuJIT and I'm not sure about legacy JIT compilers. Probably, most of the statements are valid for them too._

**Update:** [The part 2 "Hoisting in .NET Examples" is here.]({{ site.url }}{{ site.baseurl }}/hoisting-in-net-examples/)

  [github-docs-lch]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/Documentation/botr/ryujit-overview.md#loop-invariant-code-hoisting
  [google-hoisting]: https://www.google.com/search?q=Hoisting+.NET

  [github-compiler-compilemethod]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/ee_il_dll.cpp#L140
  [github-compiler-compcompile]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/compiler.cpp#L2990

  [github-jitphases]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/Documentation/botr/ryujit-overview.md#phases-of-ryujit

  [github-optimizer-optHoistLoopCode]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/optimizer.cpp#L5401
  [github-optimizer-optHoistThisLoop]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/optimizer.cpp#L5554
  [github-optimizer-optHoistLoopExprsForTree]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/optimizer.cpp#L5862
  [github-optcse-optIsCSEcandidate]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/optcse.cpp#L1914
  [github-lclvars-getBBWeight]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/lclvars.cpp#L2048
  [github-optimizer-optIsProfitableToHoistableTree]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/optimizer.cpp#L5767


  [github-helpers-list]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/inc/corinfo.h#L266
  [github-helpers]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/vm/jithelpers.cpp
  [github-helpers-sideeffect]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/jit/gentree.cpp#L10785
  [github-staticvars]: https://github.com/dotnet/coreclr/issues/2157

  [wiki-hoisting]: https://en.wikipedia.org/wiki/Loop-invariant_code_motion
  [wiki-basicblocks]: https://en.wikipedia.org/wiki/Basic_block
  [wiki-reftransparency]: https://en.wikipedia.org/wiki/Referential_transparency
  [wiki-dominator]: https://en.wikipedia.org/wiki/Dominator_(graph_theory)
