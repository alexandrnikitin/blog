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

This post is based on a real-world feature that is used under high-load scenarios. The post narrates a series of various performance optimization steps, from BCL API usage to advanced data structures, from bit twiddling hacks to SIMD instructions. It also covers tools that I usually use to analyze code.

### Content

If you find it interesting you can continue reading or jump to any of the following parts:

- Intro
- Domain
- The fundamentals of performance:
  - Measure, measure, measure
  - First efficiency then performance
- Tools and libraries:
  - BenchmarkDotNet - for benchmarks
  - ILSpy - c# compiler
  - WinDBG - .NET under the hood
  - PerfView - swiss army knife
  - Intel VTune Amplifier - heavy artillery for low level profiling
TODO PCM Tools??

- Algorithm
- Optimizations
  - API



### Intro:

I work for an advertising technology company (yeah, this is all about banners at the end, I'm sorry for this 😞) and we have a feature that identifies and filters out unwanted bot traffic.

In this post we discover the algorithm itself and its original implementation.

 It’s backed by the Aho–Corasick algorithm, a string searching algorithm that matches all strings simultaneously.
TODO
We will learn how to write micro benchmarks, profile code and read IL and assembly code. Step by step we will improve performance by 30 times using different techniques: re-implementing .NET BCL data structures, fixing CPU cache misses, reduce main memory reads by putting values in CPU registers? by force, avoid calls to Method table, evaluate .NET Core (try SIMD?)


This is a story about one real-world performance optimization that I implemented some time ago. I often hear people blaming languages and platforms for being slow, not suitable for high-performance requirements.
The intentions is to show that in 99%

This story isn't about .NET vs JVM vs C++ vs ... I won't praise .NET as being awesome. It's not about any kind of business logic optimizations. It's definitely not about GC tunning, blaming.

This story is about pure performance optimizations based on a real-world case. Step by step we'll improve performance of one production feature.

### Domain:

All websites receive bot traffic! Not a surprise, right? There were quite a few studies from all sides of the advertising business. Commercials tend to reduce the numbers, for obvious reasons, banner impression or click = money. Academics in their turn increase numbers and spread panic, that's the goal of the research after all. I think truth is somewhere in the middle.

Here's just a few to name:
- one from Incapsula shows that websites receive 50% of bot traffic in average. https://www.incapsula.com/blog/bot-traffic-report-2016.html

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


There are quite a few bot User Agent lists available on the Internet for free. But... There's The Interactive Advertising Bureau (IAB) which "is an advertising business organization that develops industry standards, conducts research, and provides legal support for the online advertising industry."

http://www.iab.com/guidelines/iab-abc-international-spiders-bots-list/


https://gitz.adform.com/marius.kazlauskas/serving/blob/master/Adform.AdServing.Lib/Resources/IAB/exclude.txt

The feature is used in few high-load applications like DSP and AdServing.


TODO
https://www.axios.com/most-internet-traffic-doesnt-come-from-humans-2233708130.html

Yeah, it's all about banners.

![About code purpose!]({{ site.url }}{{ site.baseurl }}/images/high-performance-dotnet-by-example/about-code-purpose.jpg)

### Measure, measure, measure

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
A feature -> C#
C# + Compiler -> IL assembly
IL assembly + BCL + 3rdParty libs -> Application
Application + CLR -> ASM
ASM + CPU -> Result

Infrastructure:
OS: Windows, Linux, OS X
Compilers: Legacy, Roslyn
CLR: CLR2, CLR4, CoreCLR, Mono
GC: Microsoft GC (different modes), Boehm, Sgen
JIT: Legacy x86 & x64, RyuJIT
Compilation: JIT, NGen, MPGO, .NET Native


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

https://github.com/PerfDotNet/BenchmarkDotNet

- A sample benchmark
- Config
- Diagnosers

Task: A benchmark

How does it work: https://github.com/PerfDotNet/BenchmarkDotNet#how-it-works

Review the sources
- Isolated project based on templates
- MethodInvoker: Pilot, Idle, Warmup, Target, Clocks
- Generated project
- Results: + R plot


Tasks:
x86 vs x64
RuyJIT vs LegacyJit



#### Profiling:
"Profilers Are Lying Hobbits (and we hate them!)" https://www.infoq.com/presentations/profilers-hotspots-bottlenecks

Sandbox console app

#### dotTrace & co


##### Perfview
Swiss army knife
Tutorial
Videos https://channel9.msdn.com/Series/PerfView-Tutorial

Time based - sampling
Memory profiling
ETW events

CMD args: https://github.com/lowleveldesign/debug-recipes/blob/master/perfview/perfview-cmdline.txt



##### Intel VTune Amplifier
heavy metal of profilers
$$$
low overhead
Languages: C, C++, C#, Fortran, Java, ASM and more.

use production data?

AMD Code XL

Shows how CPU executes your code.
Driver hundreds of hardware! counters and metrics


#### IL:

Ildasm.exe (IL Disassembler):

https://msdn.microsoft.com/en-us/library/f7dy01k1(v=vs.110).aspx

ILSpy

Tasks: Check sources


#### Assembly code:

Visual Studio
TODO options

Windbg - the great and powerful
SOS Sun of Strike : https://msdn.microsoft.com/en-us/library/bb190764(v=vs.110).aspx
SOSex: http://www.stevestechspot.com/default.aspx
HOWTO: Debugging .NET with WinDbg https://docs.google.com/document/d/1yMQ8NAQZEBtsfVp7AsFLSA_MkIKlYNuSowG72_nU0ek
WinDbgCs https://github.com/southpolenator/WinDbgCs

CLRMD https://github.com/Microsoft/clrmd/blob/master/Documentation/MachineCode.md

Task: Sources

More reads:
A fundamental introduction to x86 assembly programming https://www.nayuki.io/page/a-fundamental-introduction-to-x86-assembly-programming

### Optimizations!!!

### Basics

#### Lesson 1: Know APIs of libraries you use!

Task: Profile current version and find a bottleneck.
Task: Sandbox lib + Benchmark

#### Lesson 2: Know BCL collections and data structures
Demo: profile dotTrace
Demo: Perfview
Profilers are lying hobbits!!!

BenchmarkDotNet MemoryDiagnoser

Side:
Try Server GC: less GCs

Task: find reason for the allocation using Perfview & ILSpy



#### Lesson 3: Know basic data structures
BCL is too generic and isn't suitable for high performance

indirections
vcalls

#### Lesson 4: Know overheads

Basic hotspots
Memory access

Memory writes:
By Ref

Memory reads
```
if (pointer.Results.Count > 0)
```
```
mov rax, qword ptr [rsp+0x28]
mov rax, qword ptr [rax+0x10]
cmp dword ptr [rax+0x18], 0x0
jle 0x7ffcbc4238a1
```


#### Lesson 4: Know how CPU works

Obligated picture to show how complex CPUs are

CPU: Front-End & Back-End
TODO video

CPU cache

Intel i7-4770 (Haswell), 3.4 GHz

Sizes:
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


FLOPs per cycle: http://stackoverflow.com/questions/8389648/how-do-i-achieve-the-theoretical-maximum-of-4-flops-per-cycle

TODO Branch prediction


#### Lesson 5: Know advanced data structures



Classic hashset -> open address hashset

Memory exploration



#### Lesson 6: Know hacks

MOD is expensive


#### Lesson 7: Loop unrolling


#### Lesson: Going unsafe
"All is Fair in Love and War"


#### MOAR
Reconstruct array with data based on real production load.



###

* .NET vs JVM vs C++ vs ...
* In 99% cases the bottleneck is a developer not a platform


### Experiments
#### .NET Core
