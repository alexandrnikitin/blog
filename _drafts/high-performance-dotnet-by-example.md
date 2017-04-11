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

This post is based on a real-world feature that is used under high-load scenarios. The post walks through a series of various performance optimization steps, from BCL API usage to advanced data structures, from bit twiddling hacks to SIMD instructions. It also covers tools that I usually use to analyze code.

### Content

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
TODO PCM Tools??

- Algorithm
- Optimizations
  - API
  - TODO



### Intro:

I work for an advertising technology company (yeah, this is all about banners at the end, I'm sorry for this 😞) and we have a feature that identifies and filters out unwanted bot traffic. In this post we discover the domains area, algorithm used and its original implementation.

 It’s backed by the Aho–Corasick algorithm, a string searching algorithm that matches all strings simultaneously.
TODO
We will learn how to write micro benchmarks, profile code and read IL and assembly code. Step by step we will improve performance by 30 times using different techniques: re-implementing .NET BCL data structures, fixing CPU cache misses, reduce main memory reads by putting values in CPU registers? by force, avoid calls to Method table, evaluate .NET Core (try SIMD?)


This is a story about one real-world performance optimization that I implemented some time ago. I often hear people blaming languages and platforms for being slow, not suitable for high-performance requirements.
The intentions is to show that in 99%

This post isn't about .NET vs JVM vs C++ vs... I won't praise .NET as being awesome. It's not about any kind of business logic optimizations. It's definitely not about GC tunning, blaming.

This story is about pure performance optimizations based on a real-world case. Step by step we'll improve performance of one production feature.

I

### Domain:

![About code purpose!]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/about-code-purpose.jpg)

(sigh) Yes, this is all about banners.


All websites receive bot traffic! Not a surprise, right? There [were quite](https://www.incapsula.com/blog/bot-traffic-report-2016.html) a [few](http://news.solvemedia.com/post/32450539468/solve-media-the-bot-stops-here-infographic) studies from all sides of the advertising business. Commercials tend to reduce the numbers, for obvious reasons, banner impression or click = money. Academics in their turn increase numbers and spread panic, that's the goal of the research after all. I think truth is somewhere in the middle.

[The one from Incapsula](https://www.incapsula.com/blog/bot-traffic-report-2016.html) shows that websites receive 50% of bot traffic in average.

A study shows that bots drive 16% of Internet traffic in the US, in Singapore this number reaches 56%.
Source http://news.solvemedia.com/post/32450539468/solve-media-the-bot-stops-here-infographic

But, surprisingly, not all bots are bad, and some of them are even vital for the Internet. The classification could look like this:
- White bots (good) - various search engines bots (Google, Bing, [DuckDuckGo](https://duckduckgo.com/)). They are crucial, that's how we discover things on the Internet. They respect and follow [the robots exclusion protocol (robot.txt)](https://en.wikipedia.org/wiki/Robots_exclusion_standard), aware of the Robots HTML <META> tag. That's the most important is that they clearly identify themselves by providing User Agent and IP address lists.
- Grey bots (neutral) - feed fetchers, crawlers and scrappers. The are similar to the white bots. They don't bring users/clients/money directly, but generate load. They may or may not identify themselves, may or may not follow the robots protocol.
- Black bots (bad) - fraud, intentional impersonation for profit. They imitate user behavior to get fake impression, clicks, etc.


There's no reason to show a banner for a bot, right? It's pointless, waste of resources and money. And clients don't want to pay for that. The goal is to filter them out.

I won't cover the black bots because it a separate huge area with sophisticated analysis and ML algorithms.
We will focus on the white and grey bots that identify themselves as such.
List of IP addresses and User Agent strings.
There are few ways to identify the bot traffic. One of the ways that became a standard in the industry is to use a defined list of
How to identify them?

Let's take a look at an example:

My user agent looks like this at the moment "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36"

One of [the Google's crawlers](https://support.google.com/webmasters/answer/1061943) has the following user agent: "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"


There are quite a few bot User Agent lists available on the Internet for free. But... There's [The Interactive Advertising Bureau (IAB)](https://en.wikipedia.org/wiki/Interactive_Advertising_Bureau) which "is an advertising business organization that develops industry standards, conducts research, and provides legal support for the online advertising industry."

They maintain ["the only right and thorough list of bots"](http://www.iab.com/guidelines/iab-abc-international-spiders-bots-list/) (which costs $14000 for non-members)  The list is required for compliance to ~~bla-bla-bla~~ their own standards. It seems that we don't have much choice here.

The list contains a list of tokens that we can find in user agent strings. The simplified version looks like this. There are hundreds of those tokens.

```
googlebot
bingbot
twitterbot
duckduckbot
curl
yandex
...
```

What we need is to find all those token in a user agent and, if there's a match, filter out the request if it comes from a bot.

https://gitz.adform.com/marius.kazlauskas/serving/blob/master/Adform.AdServing.Lib/Resources/IAB/exclude.txt

The feature is used in few high-load applications like DSP and AdServing.


Yeah, it's all about banners.

### Measure, measure, measure!

"If you can not measure it, you can not improve it." Lord Kelvin
Right measurement is hard!

Macro-benchmarks and metrics help you understand how your code works in production and on real data and real impact of your changes. I won't cover metrics here as they too application specific.

Microbenchmarks - fast feedback, confidence. unit tests
Microbenchmarking is hard!

[DOs & DON'Ts from Microsoft:](https://github.com/dotnet/coreclr/blob/master/Documentation/project-docs/performance-guidelines.md#creating-a-microbenchmark)

- **DO** use a microbenchmark when you have an isolated piece of code whose performance you want to analyze.
- **DO NOT** use a microbenchmark for code that has non-deterministic dependences (e.g. network calls, file I/O etc.)
- **DO** run all performance testing against retail optimized builds.
- **DO** run many iterations of the code in question to filter out noise.
- **DO** minimize the effects of other applications on the performance of the microbenchmark by closing as many unnecessary applications as possible.

You development pipeline looks like the following:
```
A feature -> C#
C# + Compiler -> IL assembly
IL assembly + BCL + 3rdParty libs -> Application
Application + CLR -> ASM
ASM + CPU -> Result
```

Infrastructure:
```
OS: Windows, Linux, OS X
Compilers: Legacy, Roslyn
CLR: CLR2, CLR4, CoreCLR, Mono
GC: Microsoft GC (different modes), Boehm, Sgen
JIT: Legacy x86 & x64, RyuJIT, (Llvm MONO TODO)
Compilation: JIT, NGen, MPGO, .NET Native
```

### First efficiency then performance

This is the most crucial aspect in all performance stories.

Efficiency vs performance
Efficiency means How much work you need to do?
Performance means How fast you do the work (that you need to do)?

The main goal is to reduce the amount of work to do. And only then do it fast.

Commute: sport car vs bicycle
Analogy
Imagine I live in 10 kilometers from my office. I commute on a bicycle There's a direct I pedal at 20 km/h at average. I think I'm quite efficient because I choose the shortest route without many obstacles (traffic jams or lights). Am I fast? I doubt.

I have a sport car which is quite fast. sends me through the nearest city and the route takes 100 kilometers. Am I efficient doing this? Of course no. But I'm god damn fast, the fastest on the road.

pic



#### Algorithm:

Following the main principle we think about efficiency first.

Multiple string matching is an important problem in many application areas
of computer science. For example, in computational biology, with the availability
of large amounts of DNA data, matching of nucleotide sequences has become an
important application and there is an increasing demand for fast computer methods
for analysis and data retrieval. Similarly, in metagenomics [22], we have a set
of patterns which are the extracted DNA fragments of some species, and would
like to check if they exist in another living organism. Another important usage
of multiple pattern matching algorithms appears in network intrusion detection
systems as well as in anti-virus software, where such systems should check an
increasing number of malicious patterns on disks or high–speed network traffic.
The common properties of systems demanding for multi–pattern matching is
ever increasing size of both the sets and pattern lengths. Hence, searching of
multiple long strings over a sequence is becoming a more significant problem.



https://en.wikipedia.org/wiki/Aho%E2%80%93Corasick_algorithm
a string searching algorithm
accepts a finite set of strings we want to find
it matches all strings simultaneously
backed by a trie
additional "failure" collections between nodes

Grep

Animated:
http://blog.ivank.net/aho-corasick-algorithm-in-as3.html


TODO: http://www.cs.uku.fi/~kilpelai/BSA05/lectures/slides04.pdf
TODO: https://www.quora.com/What-is-the-most-intuitive-explanation-of-the-Aho-Corasick-string-matching-algorithm


the only .NET implementation: https://www.informit.com/guides/content.aspx?g=dotnet&seqNum=769





### Tools:

##### BenchmarkDotNet:

TODO pic with a bench?

http://benchmarkdotnet.org/
https://github.com/PerfDotNet/BenchmarkDotNet
FOSS

"Benchmarking is really hard (especially microbenchmarking)" and BenchmarkDotNet is here to help us. Harness.

It supported Full .NET Framework, .NET Core, Mono and works on Windows, Linux, MacOS.
x86, x64
LegacyJit and RuyJIT


Like unit tests, fast feedback.


Diagnosers

Creates an isolated project per benchmark based on templates.
It supports various reporting formats such as markdown, csv, html, plain text, png plots.

More details on how does it work: http://benchmarkdotnet.org/HowItWorks.htm



##### PerfView

TODO pic

Free, can do a lot.
PerfView is a general purpose performance-analysis tool for .NET that's like a Swiss army knife. It can do many things. PerfView is a must to have in your tool belt.

CPU profiling, Memory profiling and heap dumps analysis, capturing ETW events, it supports even most important hardware counters like Cache misses, branch mispredictions, instructions retired.

https://github.com/Microsoft/perfview

Video series: https://channel9.msdn.com/Series/PerfView-Tutorial

##### Intel VTune Amplifier

TODO pic

Intel VTune Amplifier is a commercial application for software performance analysis. It supports many programming languages including C#. In my opinion, it's the best tool for low level performance analysis on the market. It shows not only what and how long CPU executes a piece of code but **how** CPU executes that. It exposes hundreds if not thousands of **hardware** counters and registers. It has low overhead hence. It's not so usable for general application development as it's too low level. Tools like PerfView show better overview.

Awesome documentation.

https://software.intel.com/en-us/intel-vtune-amplifier-xe

#### ILSpy:

TODO pic

The best FOSS and easy to use .NET decompiler.

https://github.com/icsharpcode/ILSpy
http://ilspy.net/
TODO

#### Assembly code:

How to get Assembly code

Visual Studio
TODO options

Windbg - the great and powerful
SOS Sun of Strike : https://msdn.microsoft.com/en-us/library/bb190764(v=vs.110).aspx
SOSex: http://www.stevestechspot.com/default.aspx
HOWTO: Debugging .NET with WinDbg https://docs.google.com/document/d/1yMQ8NAQZEBtsfVp7AsFLSA_MkIKlYNuSowG72_nU0ek
WinDbgCs https://github.com/southpolenator/WinDbgCs

TODO
CLRMD https://github.com/Microsoft/clrmd/blob/master/Documentation/MachineCode.md

Task: Sources

### Optimizations!!!

### Measurement

Create a benchmark for quick feedback
TODO

Is good enough.

#### Know APIs of libraries you use!

```
public AhoCorasickTreeNode GetTransition(char c)
{
    return _transitionsDictionary.ContainsKey(c)
               ? _transitionsDictionary[c]
               : null;
}
```


```
public AhoCorasickTreeNode GetTransition(char c)
{
    _transitionsDictionary.TryGetValue(c, out AhoCorasickTreeNode node);
    return node;
}
```

Results:

```
// * Summary *

BenchmarkDotNet=v0.10.3.0, OS=Microsoft Windows NT 6.2.9200.0
Processor=Intel(R) Core(TM) i7-4600U CPU 2.10GHz, ProcessorCount=4
Frequency=2630627 Hz, Resolution=380.1375 ns, Timer=TSC
  [Host]     : Clr 4.0.30319.42000, 64bit RyuJIT-v4.6.1637.0
  Job-TTMHSM : Clr 4.0.30319.42000, 64bit RyuJIT-v4.6.1637.0

Jit=RyuJit  LaunchCount=3  TargetCount=10
WarmupCount=10

       Method |      Mean |    StdDev | Scaled | Scaled-StdDev |
------------- |---------- |---------- |------- |-------------- |
         Test | 6.3114 us | 0.0530 us |   1.00 |          0.00 |
 TestImproved | 5.7869 us | 0.0584 us |   0.92 |          0.01 |
```

Great, almost 10% of improvement just using proper API methods.

Lesson learnt: know APIs of libraries you use.

TODO

#### Know CLR internals

Fire PerfView
Allocations


Enumerator? Wait what?


If we take a look at the allocation stacktrace:
```
```


```
public static bool Any<TSource>(this IEnumerable<TSource> source)
{
  if (source == null)
    throw Error.ArgumentNull("source");
  using (IEnumerator<TSource> enumerator = source.GetEnumerator())
  {
    if (enumerator.MoveNext())
      return true;
  }
  return false;
}
```

GetEnumerator() implementation


ILSpy will help us here

```
.method private final hidebysig newslot virtual
	instance class System.Collections.Generic.IEnumerator`1<!T> 'System.Collections.Generic.IEnumerable<T>.GetEnumerator' () cil managed
{
	.custom instance void __DynamicallyInvokableAttribute::.ctor() = (
		01 00 00 00
	)
	.override method instance class System.Collections.Generic.IEnumerator`1<!0> class System.Collections.Generic.IEnumerable`1<!T>::GetEnumerator()
	// Method begins at RVA 0xd3f33
	// Code size 12 (0xc)
	.maxstack 8

	IL_0000: ldarg.0
	IL_0001: newobj instance void valuetype System.Collections.Generic.List`1/Enumerator<!T>::.ctor(class System.Collections.Generic.List`1<!0>)
	IL_0006: box valuetype System.Collections.Generic.List`1/Enumerator<!T>
	IL_000b: ret
} // end of method List`1::'System.Collections.Generic.IEnumerable<T>.GetEnumerator'
```

Call to interface method happen via MethodTable structure.

Struct as interface, no MethodTable they need to be wrapped into object layout which is header, MethodTable, data...

Get rid of IEnumerable<T> for List<T> and check for `Count > 0` instead of Any()

```
Method |      Mean |    StdDev | Scaled | Scaled-StdDev |
------------- |---------- |---------- |------- |-------------- |
  Test | 5.8257 us | 0.0527 us |   1.00 |          0.00 |
TestImproved | 2.7908 us | 0.0387 us |   0.48 |          0.01 |
```

Wow, 2x improvement just joggling .NET internals methods. Can we do faster?


#### Know Basic data structures

Fire PerfView and find the bottleneck.

TODO pic from PerfView


```
private int FindEntry(TKey key)
{
  if ((object) key == null)
    ThrowHelper.ThrowArgumentNullException(ExceptionArgument.key);
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

Call stack of the happy path

Dictionary<TKey, TValue>.FindEntry()
IEqualityComparer<TKey>.GetHashCode(T obj)
Char.GetHashCode()
IEqualityComparer<TKey>.Equals(T x, T y)
Char.Equals(char obj)

We know all our data types, no need in generic code.
No need in hashcode and additional comparisons.

Dictionary is an awesome data structure, it's generic it works.
But there are trade offs. There are always trade offs.
But BCL is too generic and isn't suitable for high performance.

vcalls


```
Method |      Mean |    StdDev | Scaled | Scaled-StdDev |
------------- |---------- |---------- |------- |-------------- |
  Test | 2.7792 us | 0.0033 us |   1.00 |          0.00 |
TestImproved | 1.8074 us | 0.0161 us |   0.65 |          0.01 |
```

That's 1.5 time faster.

#### How CPU works

Obligated picture to show how complex CPUs are
TODO pic


complex beasts
message passing layered cache system

CPU cache

Intel i7-4770 (Haswell), 3.4 GHz

Sizes:
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

Source: http://www.7-cpu.com/cpu/Haswell.html


Sequential memory access
Prefetch
C/C++ gives you more control
.NET can get it too https://github.com/dotnet/coreclr/issues/5025


Essentially CPU can be divided to Front-End & Back-End

TODO CPU ports

Capable of executing few instruction per second.

There's a question on Stack Overflow, a guy asks a pretty serious and interesting question: How to achieve the maximum number of FLOPS per CPU cycle.

But the answer is rather entertaining: "I've done this exact task before. But it was mainly to measure power consumption and CPU temperatures."

The code looks like the following

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

That's basically assembly code written in C++ that works directly with CPU registers and instructions. It amazing how much power and control C++ gives you (not sure about register keyword though)

The author warns you: "If you decide to compile and run this, pay attention to your CPU temperatures!!!"
FLOPs per cycle: http://stackoverflow.com/questions/8389648/how-do-i-achieve-the-theoretical-maximum-of-4-flops-per-cycle


The Out-of-Order Execution Engine

TODO Branch prediction

Reference: "Intel® 64 and IA-32 Architectures Optimization Reference Manual"
http://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-optimization-manual.pdf

#### Know overheads
v5

Run General Exploration analysis to triage hardware issues in your application. This type collects a complete list of events for analyzing a typical client application.
See the tutorial for a C++ sample code.
Use Memory Access analysis to identify memory-related issues, like NUMA problems and bandwidth-limited accesses, and attribute performance events to memory objects (data structures), which is provided due to instrumentation of memory allocations/de-allocations and getting static/global variables from symbol information.

At this point PerfView won't show us any useful insights. It's time for the heavy artillery.

VTune

Basic hotspots
Memory access

TODO Memory writes & memory reads

By Ref


```
if (pointer.Results.Count > 0)
```

```
mov rax, qword ptr [rsp+0x28]
mov rax, qword ptr [rax+0x10]
cmp dword ptr [rax+0x18], 0x0
jle 0x7ffcbc4238a1
```


#### Lesson: Know advanced data structures
v6

Memory exploration

Why classic hashset is bad? Two arrays, pointer indirection, cache misses, collisions -> more misses.

Classic hashset -> open address hashset

I believe the open address hashset should be the default one in BCL.


#### Know hacks
v7
MOD is expensive

Back-End -> Division unit

```
Method |        Mean |    StdDev | Scaled | Scaled-StdDev |
------------- |------------ |---------- |------- |-------------- |
  Test | 787.3592 ns | 3.9424 ns |   1.00 |          0.00 |
TestImproved | 435.0724 ns | 1.7562 ns |   0.55 |          0.00 |
```

#### ???

I made a huge mistake. I benchmarked and profiled the code in a tight loop like the following:

```
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
And it's quite difficult if not impossible to measure changes and their impact.
The only CPU hardware counters. We identified the bottleneck as LLC misses. We are going to monitor only this counter via VTune Amplifier Custom analysis.



#### Analyze data
TODO
ASCII with some special symbols. Hashing is not needed.

```
Method |        Mean |    StdDev | Scaled | Scaled-StdDev |
------------- |------------ |---------- |------- |-------------- |
  Test | 451.1660 ns | 2.0661 ns |   1.00 |          0.00 |
TestImproved | 287.9745 ns | 2.5764 ns |   0.64 |          0.01 |
```


#### Lesson: Going unsafe
"All is Fair in Love and War"


#### Lesson 7: Loop unrolling
???



#### MOAR
Reconstruct array with data based on real production load.


TODO NUMA?

###

* .NET vs JVM vs C++ vs ...
* In 99% cases the bottleneck is a developer not a platform


### Experiments
#### .NET Core
