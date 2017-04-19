---
layout: single
title: "High-performance .NET by example: Filter bot traffic"
date: 2017-01-27
modified:
categories: [.NET, Algorithms]
excerpt: TODO
tags: [.NET, High-performance]
comments: true
share: true
---

### TL;DR

This post is based on a real-world feature that is used under high-load scenarios. The post walks through a series of various performance optimization steps, from BCL API usage to "advanced" data structures, from bit twiddling hacks to addressing CPU cache misses. It also covers tools I usually use to analyze code.

If you find it interesting you can continue reading or jump to any of the sections:

- Intro
- Domain
- The fundamentals of performance:
  - Measure, measure, measure!
  - First efficiency then performance
- Tools and libraries:
  - BenchmarkDotNet
  - ILSpy
  - WinDBG
  - PerfView
  - Intel VTune Amplifier
  - TODO PCM Tools??
- Algorithm
- Optimizations
  - API
  - TODO



## Intro:

 and we have a feature that identifies and filters unwanted bot traffic. In this post we explore the domains area, the algorithm used and its original implementation.

 It’s backed by the Aho–Corasick algorithm, a string searching algorithm that matches all strings simultaneously.
TODO
We will learn how to write micro benchmarks, profile code and read IL and assembly code. Step by step we will improve performance by 30 times using different techniques: re-implementing .NET BCL data structures, fixing CPU cache misses, reduce main memory reads by putting values in CPU registers? by force, avoid calls to Method table, evaluate .NET Core (try SIMD?)


This is a story about one real-world performance optimization that I implemented some time ago. I often hear people blaming languages and platforms for being slow, not suitable for high-performance requirements.
The intentions is to show that in 99%

This post isn't about .NET vs JVM vs C++ vs... I won't praise .NET as being awesome. It's not about any kind of business logic optimizations. It's definitely not about GC tunning, blaming.

This story is about pure performance optimizations based on a real-world case. Step by step we'll improve performance of one production feature.



## Domain:

I work for an advertising technology company. The comics shows the lowdown:
![About code purpose!]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/about-code-purpose.jpg)

It's a bit exaggerated but... (sigh) yes, this is all about banners at the end, I'm sorry for this 😞

All websites receive bot traffic! Not a surprise, right? There were quite a few studies from all sides of the advertising business. For instance, [the one from Incapsula](https://www.incapsula.com/blog/bot-traffic-report-2016.html) shows that websites receive 50% of bot traffic in average. [Another one from Solve Media](http://news.solvemedia.com/post/32450539468/solve-media-the-bot-stops-here-infographic) shows that bots drive 16% of Internet traffic in the US, this number reaches 56% in Singapore. In general, commercials tend to reduce the numbers, for obvious reasons - banner impression or click = money. Academics and not so involved parties, in their turn, increase the numbers and spread panic, that's the goal of a research after all. I believe truth is somewhere in the middle.

But, surprisingly, not all bots are bad, and some of them are even vital for the Internet. The classification could look like this:

- **White bots** (good) - various search engines bots like Google, Bing or [DuckDuckGo](https://duckduckgo.com/). They are crucial, that's how we all discover things on the Internet. They respect and follow [the robots exclusion protocol (robot.txt)](https://en.wikipedia.org/wiki/Robots_exclusion_standard), aware of [the Robots HTML \<META\> tag](https://www.w3.org/TR/html401/appendix/notes.html#h-B.4.1.2). What's the most important is that they clearly identify themselves by providing User Agent and IP addresses lists.

- **Grey bots** (neutral) - feed fetchers, website crawlers and data scrappers. They are similar to the white bots. Except they usually don't bring users/clients/money directly, but generate additional load. They may or may not identify themselves, may or may not follow the robots protocol.

- **Black bots** (harmful) - fraud and criminal activity, intentional impersonation for profit. They imitate user behavior to get fake impression, clicks, etc.

We won't cover black bots because it is a huge topic with sophisticated analysis and Machine learning algorithms. We will focus on the white and grey bots that identify themselves as such.

There's no reason to show a banner for a bot, right? It's pointless, waste of resources and money. Clients don't want to pay for that and our goal is to filter bots out. There are few ways to identify bot traffic. One of the ways that became a standard in the industry is to use a defined list of User Agent strings.

Let's take a look at an example:

My browser's user agent string looks like this at the moment: `Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36`

One of [the Google's crawlers](https://support.google.com/webmasters/answer/1061943) has the following user agent: `Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"` As you can see Google shares information on their bots and how to identify them.


There are bot user agent lists available on the Internet for free. But... There's [The Interactive Advertising Bureau (IAB)](https://en.wikipedia.org/wiki/Interactive_Advertising_Bureau) which "is an advertising business organization that develops industry standards, conducts research, and provides legal support for the online advertising industry." They maintain [their own International Spiders and Bots List](http://www.iab.com/guidelines/iab-abc-international-spiders-bots-list/) (which costs... wait WHAT? $14000 for non-members???) The list "is required for compliance to the IAB’s Client Side Counting (CSC) Measurement Guidelines". Oh, industry standards, everything fell into place. It seems that we don't have much choice here 😀

The bot list contains a list of string tokens that we can find in user agent strings. There are hundreds of those tokens. The simplified version looks like this.

```
googlebot
bingbot
twitterbot
duckduckbot
curl
yandex
...
```

What we need is to find any of those tokens in a user agent and, if there's a match, filter the request out as it comes from a bot.

The feature is used in few high-load systems like [Real-time bidding](https://en.wikipedia.org/wiki/Real-time_bidding), [Ad serving](https://en.wikipedia.org/wiki/Ad_serving), etc. This is all about. banners (sigh).



## Measure, measure, measure!

>"If you can not measure it, you can not improve it." Lord Kelvin

That's basically all. Measurement is vital! It's difficult to add anything to that.

Measurement is hard! Variety of versions, libraries, languages, OSes, hardware and tools to measure only aggravate the situation.

Essentially you are interested in two levels, let's call them macro and micro.

On macro level, metrics and macro-benchmarks help you understand how your code works in production and on real data and show the real impact of changes.

Microbenchmarks - are crucial. They provide fast feedback and increase confidence. They are like unit tests when performance is a feature.
Microbenchmarking is hard!

[Microbenchmarking DOs & DON'Ts from Microsoft:](https://github.com/dotnet/coreclr/blob/master/Documentation/project-docs/performance-guidelines.md#creating-a-microbenchmark)

- **DO** use a microbenchmark when you have an isolated piece of code whose performance you want to analyze.
- **DO NOT** use a microbenchmark for code that has non-deterministic dependences (e.g. network calls, file I/O etc.)
- **DO** run all performance testing against retail optimized builds.
- **DO** run many iterations of the code in question to filter out noise.
- **DO** minimize the effects of other applications on the performance of the microbenchmark by closing as many unnecessary applications as possible.

Your development pipeline looks like the following:

```
A feature -> C# code
C# code + Compiler -> IL assembly
IL assembly + BCL + 3rdParty libs -> Application
Application + CLR -> ASM
ASM + CPU -> Result
```

And variety of implementations:

```
C# Compilers: Legacy, Roslyn
IL Compilation: JIT, NGen, MPGO, .NET Native, LLVM
JIT: Legacy x86 & x64, RyuJIT, Mono
CLR: CLR2, CLR4, CoreCLR, Mono
GC: Microsoft GC (few modes), Boehm, Sgen
OS: Windows, Linux, OS X
Hardware: ...
```

## First efficiency then performance

This is the second most important aspect in all performance stories. Efficiency means how much work you need to do. Performance means how fast you do the work. The main goal is to reduce the amount of work to be done. And only then do it fast.

![Indian Pacific Wheel Race]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/Bicycle.jpg)


The best analogy is commuting to work. I live in 10 km away from my office. I usually commute on a bicycle and choose the direct route without obstacles like traffic lights or traffic jams. I pedal at 20 km/h at average which takes me to the office in 30 minutes. I think I'm quite efficient because I choose the shortest route. But I can be faster of course.

I have a car too. But GPS sends me on 20 km detour because of traffic jams on the main road. The average speed is low because of traffic. The parking isn't near the office. Yes, a car is obviously much faster than a bicycle. But because of the amount of work, it usually takes me more time to get to the office.

TODO Tradeoffs?


## Algorithm

Following the first principle, we think about efficiency first. Our goal is to check whether a user agent string contains any of the given tokens. We have several hundred tokens. We perform the check once per network request. We don't need to find TODO Basically, omitting all unnecessary details, our problem comes down to the multiple string matching problem.

Multiple string/ pattern matching problem is an important problem in many areas of computer science. For example, spam detection, filtering spam based on the content of the email, detecting keywords, is a very popular technique.
Another applications is plagiarism detection, using pattern matching algorithms we can compare texts and detect similarities between them. An important usage appears in biology and bioinformatics area, matching of nucleotide sequences in DNA is an important application of multiple pattern matching algorithms. There's application in network intrusion detection systems and anti-virus software, such systems should check network traffic and disks content against large amount of malicious patterns. Aaaand we have banners...

There are [several string searching algorithms](https://en.wikipedia.org/wiki/String_searching_algorithm) and few of them with a finite set of patterns. The most suitable for our needs is [Aho–Corasick algorithm.](https://en.wikipedia.org/wiki/Aho%E2%80%93Corasick_algorithm) It was invented by Alfred V. Aho and Margaret J. Corasick in 1975.

Key features of the Aho–Corasick algorithm:

- a pattern matching algorithm
- accepts a finite set of patterns
- matches all patterns simultaneously
- constructs a finite state machine from patterns backed by [a Trie](https://en.wikipedia.org/wiki/Trie)
- additional "failure" links between nodes that allows to continue traversal in case of match failure

The algorithm was used in the `fgrep` utility (an early version of `grep`)

You can play with [the animated version of the algorithm here.](http://blog.ivank.net/aho-corasick-algorithm-in-as3.html)



## Tools

## BenchmarkDotNet

![BenchmarkDotNet]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/BenchmarkDotNet.png)

BenchmarkDotNet is a powerful FOSS .NET library for benchmarking. It is like NUnit for unit tests, it provides fast feedback for code changes. I believe that it's a must to have it in your solution even if you don't write high-performance code.

"Benchmarking is really hard (especially microbenchmarking), you can easily make a mistake during performance measurements. BenchmarkDotNet will protect you from the common pitfalls..." It supports Full .NET Framework, .NET Core, Mono, x86, x64, LegacyJit and RuyJIT, and works on Windows, Linux, MacOS. It has some useful diagnosers based on ETW events like GC and Memory allocation, JIT Inlining and even [some hardware counters.](http://adamsitnik.com/Hardware-Counters-Diagnoser/)

You can find documentation and how to use it [on its website](http://benchmarkdotnet.org/), review, star or even contribute [on github.](https://github.com/PerfDotNet/BenchmarkDotNet)


## PerfView

![PerfView]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/PerfView.png)

PerfView is a general purpose performance-analysis tool for .NET.
It's like a Swiss army knife and can do many things, from CPU and Memory profiling to heap dump analysis, from capturing ETW events to hardware counters like CPU cache misses, branch mispredictions, etc. It has an ugly interface but after few ~~days~~ weeks you will find it functional. I believe that PerfView is a great tool to have in your tool belt. It's FOSS with [the sources hosted on github.](https://github.com/Microsoft/perfview)

## Intel VTune Amplifier

![Intel VTune Amplifier]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/IntelVTune.png)

Intel VTune Amplifier is a commercial application for software performance analysis. It supports many programming languages including C#. In my opinion, it's the best tool for the low level performance analysis on the market. It shows not only what code CPU executes but **how** it does that. It answers not only how long CPU executes a piece of code but **why** it takes that much time. It exposes hundreds of **hardware** counters and registers. It has low overhead hence. You can read about it on [the Intel website](https://software.intel.com/en-us/intel-vtune-amplifier-xe) BTW, VTune Amplifier has pretty good documentation and explanation for all major counters.


## ILSpy

![ILSpy]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/ILSpy.png)

"ILSpy is the open-source .NET assembly browser and decompiler." It is very useful

It's FOSS with [the sources hosted on github.](https://github.com/icsharpcode/ILSpy)

Website: http://ilspy.net/

TODO

## WinDbg

![WinDbg]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/WinDbg.png)

WinDbg - the great and powerful! It is a powerful debugging and exploring tool for Windows. It can be used to debug user applications, device drivers, and the operating system itself. I use it to get assembly code and CLR internals, analyze process dumps or debug an ugly problem.

There are few extensions to help us with that:

- SOS (Sun of Strike): provides information about the internal (CLR) environment. https://msdn.microsoft.com/en-us/library/bb190764(v=vs.110).aspx SOS is distributed with the .NET Framework
- SOSex: by Steve Johnson http://www.stevestechspot.com/default.aspx
- WinDbgCs https://github.com/southpolenator/WinDbgCs
This is an interesting option to execute C# scripts inside WinDbg and automate some analysis.

I find [the "Debugging .NET with WinDbg"](https://docs.google.com/document/d/1yMQ8NAQZEBtsfVp7AsFLSA_MkIKlYNuSowG72_nU0ek) document by [Sebastian Solnica](https://twitter.com/lowleveldesign) concise and good as an intro and a reference book.

## Performance optimizations

To be fair, the feature and algorithm were implemented by another developer. My interest in this case lies mostly in the performance optimizations.

You can find [the algorithm code in this gist](https://gist.github.com/alexandrnikitin/e4176d6b472b39155a7e0e5d68264e65)

In short, Trie based on Dictionary

## Measurement

Following the main principle, we want to have a reliable way to measure the performance and further code changes. BenchmarkDotNet will help us with that, it is as simple as installing the library via NuGet, creating a test method with a `[Benchmark]` attribute.

A simple benchmark could looks like this:

```
public class ManyKeywordsBenchmarkSimple
{
    private const string UserAgent = "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36";
    private readonly AhoCorasickTree _tree;
    public ManyKeywordsBenchmarkSimple()
    {
        var keywords = ResourcesUtils.GetKeywords().ToArray();
        _tree = new AhoCorasickTree(keywords);
    }

    [Benchmark]
    public bool Baseline()
    {
        return _tree.Contains(UserAgent);
    }
}
```

And the results:


``` ini
BenchmarkDotNet=v0.10.3.0, OS=Microsoft Windows NT 6.2.9200.0
Processor=Intel(R) Core(TM) i7-4600U CPU 2.10GHz, ProcessorCount=4
Frequency=2630635 Hz, Resolution=380.1364 ns, Timer=TSC
  [Host]     : Clr 4.0.30319.42000, 64bit RyuJIT-v4.6.1637.0
  Job-ECROUK : Clr 4.0.30319.42000, 64bit RyuJIT-v4.6.1637.0

Jit=RyuJit  Platform=X64  LaunchCount=5  
TargetCount=20  WarmupCount=20  
```

|  Method |      Mean |    StdDev |
|-------- |---------- |---------- |
| Control | 6.1364 us | 0.0314 us |

This is less than 7 microsecond per execution. It means that we can do ~150K call per second on one CPU Core. It's pretty fast and good enough. But can we do better?

## Know APIs of libraries you use!

Let's quickly review the code. We have the `AhoCorasickTree` class that contains logic on how to build itself and traverse/ search for patterns. The tree class consists of `AhoCorasickTreeNode` nodes. The `AhoCorasickTreeNode` class backed by `Dictionary<char, AhoCorasickTreeNode>` for prefix keys and further traversal, it stores its results in `List<string>`. If we take a look at the code that check the existence of the given prefix then we find the following code:

```csharp
public AhoCorasickTreeNode GetTransition(char c)
{
    return _transitionsDictionary.ContainsKey(c)
               ? _transitionsDictionary[c]
               : null;
}
```

We have two calls to the dictionary in the hot path: one to check whether the dictionary has the key or not, and then we get the next node. But we know that there's a method that can do both at once - `bool TryGetValue(TKey key, out TValue value)`. Let's fix that:

```csharp
public AhoCorasickTreeNode GetTransition(char c)
{
    _transitionsDictionary.TryGetValue(c, out AhoCorasickTreeNode node);
    return node;
}
```

And the results:

|    Method |      Mean |    StdDev |    Median | Scaled | Scaled-StdDev |
|---------- |---------- |---------- |---------- |------- |-------------- |
|   Control | 6.1577 us | 0.0523 us | 6.1466 us |   1.00 |          0.00 |
| Treatment | 5.8706 us | 0.0432 us | 5.8850 us |   0.95 |          0.01 |


Not so bad, almost 5% improvement just using proper API methods. Lesson learnt: know APIs of libraries you use. Let's move to profiling.

## Know CLR internals

Let's start from a high-level analysis and try to understand how the code performs. PerfView is the best tool for the general purpose analysis. What we need is to create an isolated console application that executes the code in a loop with close to production usage. Let's launch PerfView and profile the application using it.

PerfView shows a lot of useful .NET related (and not only) information. For example JIT and GC stats. For instance, we can take a look at the activity of the GC in the "GCStats" view under the "Memory Group" folder. If we open the view for our application it shows us that the GC is pretty busy allocating and cleaning garbage up:

![Allocations]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/Allocations.png)

Hmmm... That's not what I would expect. We prebuilt a Trie  TODO
Why would we ever need to allocate anything just to traverse the tree?? Luckily PerfView is able to trace allocation object stack traces. Let's enable the ".NET SampleAlloc" option and switch to the "GC Heap Net Mem stacks" view. If we take a look at the allocation stacktrace:

![AllocationStack]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/AllocationStack.png)

We find that we allocate an instance of `Enumerator[String]` class which is `List<String>.Enumerator` in our case. What? We all know that List's enumerator is a `struct`. How is that possible to have a struct on the heap? Let's go up the stack and find that out. The `Any<T>` IEnumerable extension:

```csharp
public static bool Any<TSource>(this IEnumerable<TSource> source)
{
  ...
  using (IEnumerator<TSource> enumerator = source.GetEnumerator())
  {
    if (enumerator.MoveNext())
      return true;
  }
  return false;
}
```

Here we call the IEnumerable<TSource>'s `GetEnumerator()` method to get an enumerator. The List's `GetEnumerator()` implementation:

```csharp
IEnumerator<T> IEnumerable<T>.GetEnumerator()
{
  return (IEnumerator<T>) new List<T>.Enumerator(this);
}
```

We create an instance of the Enumerator struct, cast it to an interface and return it as an interface. To make it more clearer we need to
ILSpy will help us here. Let's launch ILSpy and review the IL code:

```
.method private final hidebysig newslot virtual
	instance class System.Collections.Generic.IEnumerator`1<!T> 'System.Collections.Generic.IEnumerable<T>.GetEnumerator' () cil managed
{
...
    IL_0000: ldarg.0
    IL_0001: newobj instance void valuetype System.Collections.Generic.List`1/Enumerator<!T>::.ctor(class System.Collections.Generic.List`1<!0>)
=>  IL_0006: box valuetype System.Collections.Generic.List`1/Enumerator<!T>
    IL_000b: ret
}
```

Indeed we clearly see the `box`ing operation. The reason for the boxing is that calls to interface methods happen via [a Virtual Method Table](https://en.wikipedia.org/wiki/Virtual_method_table). A value type doesn't have a virtual method table and to obtain one it has to become a reference type with all consequences.

Knowing that fact, the fix is quite easy, let's get rid of `IEnumerable<T>` for `List<T>` and check for `Count > 0` instead of `Any()`.

|    Method |      Mean |    StdDev |    Median | Scaled | Scaled-StdDev |
|---------- |---------- |---------- |---------- |------- |-------------- |
|   Control | 5.7016 us | 0.0669 us | 5.6759 us |   1.00 |          0.00 |
| Treatment | 2.8440 us | 0.0357 us | 2.8433 us |   0.50 |          0.01 |

Wow, that's 2 times faster! We achieved that just joggling .NET internals.
Lesson learnt: know .NET internals.


## Know Basic data structures

Now it's time to find the bottleneck of the code. Let's launch PerfView again and profile the application. At this time we are interested in the "CPU Stacks" view:

![BottleneckDictionary]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/BottleneckDictionary.png)


PerfView shows that the bottleneck is in the BCL `Dictionary`. This will stop most developers from further optimizations. Dictionary (a hash table) is an awesome data structure. It's generic, it's fast enough, it's efficient memory-wise. It was bestowed upon us from above.

But, out of curiosity, let's take a look how it work under the hood.
The `TryGetValue` method, identified as the bottleneck, calls the `FindEntry` method under the hood which looks like this:

```csharp
private int FindEntry(TKey key)
{
  if ((object) key == null) ThrowHelper.ThrowArgumentNullException(ExceptionArgument.key);
  if (this.buckets != null)
  {
    int num = this.comparer.GetHashCode(key) & int.MaxValue;
    for (int index = this.buckets[num % this.buckets.Length]; index >= 0; index = this.entries[index].next)
    {
      if (this.entries[index].hashCode == num && this.comparer.Equals(this.entries[index].key, key))
        return index;
    }
  }
  return -1;
}
```

The first thing is the `null` checks useless in our case, which don't affect performance in this situation, to be fair. Next thing is the `this.comparer.GetHashCode()` call where `this.comparer` is an `IEqualityComparer<TKey>` implementation. That makes the call a virtual interface call which cannot be inlined. All the same with the `this.comparer.Equals()` call.

Having said that, the call stack of the hot path looks like the following in our case:

```csharp
Dictionary<TKey, TValue>.TryGetValue()
  Dictionary<TKey, TValue>.FindEntry()
    GenericEqualityComparer<T>.GetHashCode()
    (inlined) Char.GetHashCode()
    GenericEqualityComparer<TKey>.Equals()
    (inlined) Char.Equals()
    // repeat if hash collision
```

That's understandable, Dictionary must handle any type. But we don't need that generic solution, we know all our types in advance.

Let's just remove the Dictionary data structure from our `AhoCorasickTreeNode` class and implement a hash table for the `char` type. What we need is an array for hashcodes and an array for values. That's it. The code in that case could look like this:

Basically remove all unnecessary code and flatten the call stack. TODO

```csharp
public AhoCorasickTreeNode GetTransition(char c)
{
    var bucket = c % _buckets.Length;
    for (int i = _buckets[bucket]; i >= 0; i = _entries[i].Next)
    {
        if (_entries[i].Key == c)
        {
            return _entries[i].Value;
        }
    }

    return null;
}
```

The results:


|    Method |      Mean |    StdDev | Scaled | Scaled-StdDev |
|---------- |---------- |---------- |------- |-------------- |
|   Control | 2.7514 us | 0.0249 us |   1.00 |          0.00 |
| Treatment | 1.7416 us | 0.0216 us |   0.63 |          0.01 |


Yeah, that's 1.5 time faster. Lesson learnt:

## How CPU works

Now we came to the point when it's important to understand how CPU works to perform analyses and optimizations. Here's a necessary picture to show how complex CPUs are:

![CPU]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/CPU.jpg)


Yes, a modern CPU is a complex beast and I'm not in a position to explain how it works, especially within a blog post. I just want to give a starting point, from where you can start the journey. In few words, CPU is a message passing system with multiple cache layers. Access next layer is slower than the previous one.  For example, cache layers and latency for my Intel i7-4770 (Haswell) 3.4 GHz are the following:

```ini
Caches:
Cache line = 64 bytes
L1 Data cache = 32 KB
L1 Instruction cache = 32 KB
L2 cache = 256 KB
L3 cache = 8 MB

Latency:
L1 Data Cache Latency = 4 cycles for simple access via pointer
L1 Data Cache Latency = 5 cycles for access with complex address calculation
L2 Cache Latency = 12 cycles
L3 Cache Latency = 36 cycles
RAM Latency = 36 cycles + 57 ns
```

Essentially, CPU can be divided into the Front-end and the Back-end. The Front-end is where instructions are fetched and decoded. The Back-end is where the computation performed. Optimizations are based on that concept.

The Out-of-Order Execution Engine
TODO Branch prediction
TODO CPU ports

Capable of executing few instruction per second.

There's [a question on Stack Overflow](http://stackoverflow.com/questions/8389648/how-do-i-achieve-the-theoretical-maximum-of-4-flops-per-cycle), a guy asks a pretty serious and interesting question: How to achieve the theoretical maximum number of operations per CPU cycle. But [the answer](http://stackoverflow.com/a/8391601/974487) is rather entertaining: "I've done this exact task before. But it was mainly to measure power consumption and CPU temperatures." The code looks like the following:

```
double test_dp_mac_AVX(double x,double y,uint64 iterations){
    register __m256d r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,rA,rB,rC,rD,rE,rF;

    //  Generate starting data.
    r0 = _mm256_set1_pd(x);
    r1 = _mm256_set1_pd(y);

    r8 = _mm256_set1_pd(-0.0);

    r2 = _mm256_xor_pd(r0,r8);
    r3 = _mm256_or_pd(r0,r8);
    r4 = _mm256_andnot_pd(r8,r0);
    r5 = _mm256_mul_pd(r1,_mm256_set1_pd(0.37796447300922722721));
    r6 = _mm256_mul_pd(r1,_mm256_set1_pd(0.24253562503633297352));
    r7 = _mm256_mul_pd(r1,_mm256_set1_pd(4.1231056256176605498));
    r8 = _mm256_add_pd(r0,_mm256_set1_pd(0.37796447300922722721));
...

and many more lines like this

```

That's basically assembly code written in C++ that works directly with CPU registers and instructions. It is amazing how much power and control C++ gives you. The author warns you: "If you decide to compile and run this, pay attention to your CPU temperatures!!! ... I take no responsibility for whatever damage that may result from running this code."


["Intel 64 and IA-32 Architectures Software Developer Manuals"](https://software.intel.com/en-us/articles/intel-sdm) and ["Intel 64 and IA-32 Architectures Optimization Reference Manual"](http://www.intel.com/content/www/us/en/architecture-and-technology/64-ia-32-architectures-optimization-manual.html) are the most thorough manuals I've seen. I haven't read them all though and use them as a reference mostly.



## Advanced data structures

At this point PerfView won't show us any useful insight. It's time for the heavy artillery - Intel VTune Amplifier.

VTune has several predefined analyses

Advanced Hotspots analysis is the best place to start from  Event-based sampling analysis that monitors all the software on your system including the OS. To identify bottlenecks. We already did that using PerfView and more interested in why they are there.

Run General Exploration analysis to triage hardware issues in your application. This type collects a complete list of events for analyzing a typical client application.

The General Exploration analysis type uses hardware event-based sampling collection. This analysis is a good starting point to triage hardware issues in your application. Once you have used Basic Hotspots or Advanced Hotspots analysis to determine hotspots in your code, you can perform General Exploration analysis to understand how efficiently your code is passing through the core pipeline. During General Exploration analysis, the VTune Amplifier collects a complete list of events for analyzing a typical client application.

Event-based analysis that helps identify the most significant hardware issues affecting the performance of your application. Consider this analysis type as a starting point when you do hardware-level analysis.

Shows a nice view:

![VTune Amplifier General Exploration analysis]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/VTuneGE.png)


Use Memory Access analysis to identify memory-related issues, like NUMA problems and bandwidth-limited accesses, and attribute performance events to memory objects (data structures), which is provided due to instrumentation of memory allocations/de-allocations and getting static/global variables from symbol information.


Let's take a look at the whys

One we can spot is L1 cache misses. as we know the L2 latency is ~12 CPU cycles CPU stalls doing nothing. It's worth to address.

Why?
we have two arrays located in different place of the heap. One for hashes another entries.
First we load one
Prefetch TODO

```csharp
// load the array with buckets TODO
var bucket = c % _buckets.Length;

// access an element
for (int i = _buckets[bucket]; i >= 0; i = _entries[i].Next)
{
    // load another array and access
    if (_entries[i].Key == c)
    {
        return _entries[i].Value;
    }


}
```

collisions can lead to more misses


Why can't we have just one array for hashes and values

Open addressing only saves memory if the entries are small

On the other hand, normal open addressing is a poor choice for large elements


Generally speaking, open addressing is better used for hash tables with small records that can be stored within the table

https://en.wikipedia.org/wiki/Hash_table


Trade offs




```csharp
if (pointer.Results.Count > 0)
```

```
mov rax, qword ptr [rsp+0x28]
mov rax, qword ptr [rax+0x10]
cmp dword ptr [rax+0x18], 0x0
jle 0x7ffcbc4238a1
```


Why classic hashset is bad? Two arrays, pointer indirection, cache misses, collisions -> more misses.

Classic hashset -> open address hashset



## Know hacks

Performance optimization is an iterative process. Let's take a look at the General Exploration analysis of the current state again.

![General Exploration - Divider]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/VTuneGEDivider.png)

We can see that the DIV unit is pretty loaded. VTune Amplifier tries to help use: "The DIV unit is active for a significant portion of execution time. Locate the hot long-latency operation\(s\) and try to eliminate them. For example, if dividing by a constant, consider replacing the divide by a product of the inverse of the constant. If dividing an integer, see whether it is possible to right-shift instead."

Indeed we have a modulo operation in the following code that calculates an array index for the key:

```csharp
public AhoCorasickTreeNode GetTransition(char c)
{
    if (_size == 0) return null;
=>  var ind = c % _size;
    var keyThere = _entries[ind].Key;
...
}
```

That compiles to

```ini
sub rsp, 0x28 ; bump the stack pointer
mov r8d, dword ptr [rcx+0x28] ; _size field value to r8d
test r8d, r8d ; check for null
jnz ; jump if not
xor eax, eax
add rsp, 0x28
ret ; return null

movzx r9d, dx ; char argument to r9d
mov eax, r9d ; r9d to eax
cdq ; double the eax
idiv r8d ; divide eax by r8d (_size)
mov eax, edx ; result to eax
...
```

`idiv` instruction consumes considerably more cycles than `mov` for example. It can be from 20 to 100 cycles depending on CPU and register type.

VTune gave us a hint, let's replace our `mod` operation with a bit hack
Needs to be a power of two.
https://graphics.stanford.edu/~seander/bithacks.html

```csharp
public AhoCorasickTreeNode GetTransition(char c)
{
    if (_size == 0) return null;
    var ind = c & (_size - 1);
    var keyThere = _entries[ind].Key;
...
}
```

The benchmark results show almost 2 times improvement! Awesome!


|    Method |        Mean |    StdDev | Scaled | Scaled-StdDev |
|---------- |------------ |---------- |------- |-------------- |
|   Control | 757.1089 ns | 8.5518 ns |   1.00 |          0.00 |
| Treatment | 427.0176 ns | 6.4534 ns |   0.56 |          0.01 |

## A huge mistake

I made a huge mistake 😞 I benchmarked and profiled the code in a tight loop like the following:

```csharp
for (var i = 0; i < 1000000; i++)
{
    tree.Contains(UserAgent);
}
```

It is completely out of context and has different load profile. It shows completely different picture.
Our tree is relatively small and only ~30Kb that perfectly fits into L1 cache. In a tight loop, all data resides in L1 cache and hides all memory related issues. While in the wild the code works under different memory pattern, we call the data structure only once per network request and there's a bunch of other business logic around it. That means that even L3 cache doesn't have the data. CPU stalls for memory.

Having said that, all CPU optimizations are useless, CPU wait for requested memory to received from RAM -> L3 -> L2 -> L1 -> registers

Load array from the heap

range check

CPI ~5 cycles per one instruction.

Source Line	Source	CPU Time	L1 Bound	LLC Miss	Loads	Stores	LLC Miss Count	Average Latency (cycles)	Source File

```
83	            var keyThere = _entries[ind].Key;	2.580s	8.8%	0.0%	10,628,118,834	0	0	8	AhoCorasickTreeNode.cs
```

```
Address	Source Line	Assembly	CPU Time	L1 Bound	LLC Miss	Loads	Stores	LLC
Miss Count	Average Latency (cycles)
0x7fff7a2b09fb	82	and edx, eax	0.960s	5.8%	0.0%	0	0	0	0
0x7fff7a2b09fd	83	mov rcx, qword ptr [rcx+0x20]	0.073s	25.7%	0.0%	1,774,253,226	0	0	8
0x7fff7a2b0a01	83	mov r8, rcx	0.038s	92.2%	0.0%	0	0	0	0
0x7fff7a2b0a04	83	mov r9d, dword ptr [r8+0x8]	0.001s	0.0%	0.0%	4,134,724,038	0	0	8
0x7fff7a2b0a08	83	cmp edx, r9d	2.007s	6.6%	0.0%	600,018	0	0	0

Address	Source Line	Assembly	CPU Time	L1 Bound	LLC Miss	Loads	Stores	LLC Miss Count	Average Latency (cycles)

Wait? again?
0x7fff7a2b0b84	86	cmp edx, r9d	0.431s	15.0%	0.0%	0	0	0	0
0x7fff7a2b0b87	86	jnb 0x7fff7a2b0b9a <Block 9>							

```

Let's take a look what we have:
Reminder: cache sizes, latency. analyze sizes. scattered around the heap. Every next reference to a not yet meet node or array = cache miss = 50-100ns latency.

What can we do here?

Sequential memory access, optimizer can help and prefetch data.

Every tree can be put into array

Also we want to keep the tree as small as possible.

Now we came to the point where microbenchmarking doesn't show us the real picture and scary to say useless.
And it's quite difficult (if not impossible) to measure changes and their impact.
The only CPU hardware counters. We identified the bottleneck as LLC misses. We are going to monitor only this counter via VTune Amplifier Custom analysis.

Array pointer will still point somewhere in the heap. TODO

Unsafe ins the only

![Unsafe]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/Unsafe.jpg)



We managed to reduce number of LLC misses by 3 times. Which is great!




## Summary

TODO
We improved by bla-bla-bla.


"If you can not measure it, you can not improve it." Lord Kelvin

We are at the point when it's impossible to reliably benchmark the code and it's quite difficult to profile it and measure the impact of changes.
All further optimization steps should be focused on reducing LLC misses and can include compacting the array size, generating the perfect hash function,
TODO [prefetch ](https://github.com/dotnet/coreclr/issues/5025)

Sequential memory access
Prefetch
C/C++ gives you more control

Or we came to the point where we have to re-iterate and think about efficiency again.

In 99% cases the bottleneck is a developer not a platform
