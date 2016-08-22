---
layout: single
title: "High performance .NET by example: Aho-Corasick algorithm"
date:
modified:
categories: [.NET, Algorithms]
excerpt:
tags: [.NET, High-performance]
comments: true
share: true
---

We have a feature in Adform that identifies unwanted bot traffic. It’s backed by the Aho–Corasick algorithm, a string searching algorithm that matches all strings simultaneously. We will discover the algorithm and its current implementation. We will learn how to write micro benchmarks, profile code and read assembly code. We will improve performance by 20-30 times by different techniques: re-implement BCL data structures, fix CPU cache misses, reduce main memory reads by putting values in CPU registers by force, avoid calls to Method table, evaluate .NET Core (try SIMD?)


This workshop consists of two parts: basics and hardcore.
The first one is a workshop. We will learn how to write micro benchmarks, profile code using different profiles.
We will learn how to read IL and assembly code for saner understanding how our code works.
We will find main bottlenecks and optimize performance significantly.

The second part will be a demonstration. I'll show you how we can use different tools and improve performance by tens times using different optimization techniques.

Slides: http://alexandrnikitin.github.io/workshops/high-performance-dotnet-by-example/slides/
Slack: https://adform.slack.com/archives/workshop-highperf-net

### Prerequisites:
- Laptop (or a peer with a laptop) with dev environment
- Aho-Corasick algorithm: study and try to implement it by yourself
- ILSpy
- WinDBG
- PerfView
- Intel VTune Amplifier

What it isn't about:
* .NET vs JVM vs C++ vs ...
* .NET is awesome!!!
* Business logic
* GC

What it is about:

* Pure performance



0. Intro
  * What it's about and what isn't
  * Domain field
0. About the Aho-Corasick algorithm
  * The algorithm explained
  * Implement the algorithm by ourselves
  * The current implementation
0. Harness
  * How to write micro-benchmarks
  * How to profile code
  * How to get and read assembly code
0. Optimizations:
  * Re-implement BCL
  * Open address hashset
  * Branchless code
  * Further micro optimizations
0. Experiments
  * Static
  * .NET Core
  * SIMD?


  ### Domain:

  All websites receive bot traffic. A study shows that bots drive 16% of Internet traffic in the US, in Singapore this number reaches 56%.
  Source http://news.solvemedia.com/post/32450539468/solve-media-the-bot-stops-here-infographic

  Not all bots are bad, and some of them are vital for the Internet.
  White bots (good) search engines (Google, Bing), robot.txt
  Grey bots (neutral) - don't bring clients directly, generate load. Frameworks, utilities,
  Black bots (bad) - fraud, intentionaly fake impression, clicks, etc.

  My user agent: "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
  Google Web search: "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
  Google UAs: https://support.google.com/webmasters/answer/1061943?hl=en


  IAB - Interactive Advertising Bureau
  http://www.iab.com/guidelines/iab-abc-international-spiders-bots-list/

  https://gitz.adform.com/marius.kazlauskas/serving/blob/master/Adform.AdServing.Lib/Resources/IAB/exclude.txt

  DSP, AdServing, etc


  ### Algorithm:
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



  Efficiency vs performance
  Commute: sport car vs bicycle

  Lesson 0: First efficiency then performance



  ### Harness:

  #### Microbenchmarks:

  is hard!

  DOs & DON'Ts from Microsoft:

  - **DO** use a microbenchmark when you have an isolated piece of code whose performance you want to analyze.
  - **DO NOT** use a microbenchmark for code that has non-deterministic dependences (e.g. network calls, file I/O etc.)
  - **DO** run all performance testing against retail optimized builds.
  - **DO** run many iterations of the code in question to filter out noise.
  - **DO** minimize the effects of other applications on the performance of the microbenchmark by closing as many unnecessary applications as possible.

  https://github.com/dotnet/coreclr/blob/master/Documentation/project-docs/performance-guidelines.md#creating-a-microbenchmark

  Pipeline:
  A task -> C#
  C# + Compiler -> IL
  IL + BCL + 3rdParty -> App
  App + CLR -> ASM
  ASM + CPU -> Result

  Infrastructure:
  OS: Windows, Linux, OS X
  Compilers: Legacy, Roslyn
  CLR: CLR2, CLR4, CoreCLR, Mono
  GC: MS, Boehm, Sgen
  JIT: Legacy x86 & x64, RyuJIT
  Compilation: JIT, NGen, MPGO, .NET Native


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
  TODO
  $$$

  AMD Code XL


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
  GC modes: Server vs Workstation (BenchmarkDotNet?) CPU groups?
  Try Server GC: less GCs

  Task: find reason for the allocation using Perfview & ILSpy



  #### Lesson 3: Know basic data structures
  BCL is too generic and isn't suitable for high performance


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
