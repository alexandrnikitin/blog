---
layout: single
title: "Bloom filter in Scala, the fastest for JVM"
categories: [Scala, Data structures]
excerpt: The fastest implementation of Bloom filter for Scala
tags: [High-performance]

comments: true
share: true
---


### TL;DR

[The source code on github][github-source]  
The fastest implementation for JVM. _[(Take me straight to the benchmarks)](#benchmarks)_  
Zero allocation and highly optimized code
No memory limits, therefore no limits to the number of elements and false positive rate.  
Extendable - plug-in any hash algorithm or element type to hash.  
Yes, it uses `sun.misc.unsafe` :blush:

### Intro

>"A Bloom filter is a space-efficient probabilistic data structure that is used to test whether an element is a member of a set. False positive matches are possible, but false negatives are not. In other words, a query returns either "possibly in set" or "definitely not in set". Elements can be added to the set, but not removed," says [Wikipedia][wiki-bloom-filter].

What's Bloom filter in a nutshell:

- Optimization for memory. It comes into play when the whole set doesn't fit into memory.
- Solves the membership problem. It can answer one question: does an element belong to a set or not?
- Probabilistic (lossy) data structure. It can answer that the element **probably belongs** to the set with some probability.

I find the following post quite comprehensive ["What are Bloom filters, and why are they useful?"][sc5-bloom-filter] by [Max Pagels TODO][twitter-pagels]. I couldn't do it better, take a look if you aren't familiar with Bloom filters.


### Why yet another Bloom filter?

Because available ones suck! :rage: They don't suit our needs because of performance and memory limitations. Or you just know that you can do it better. ~~Frankly, nothing is true. The reason is that you just get bored sometimes.~~ [(theme song)][youtube-bored]

The major reason is performance. Working on high-performance and low latency systems, you don't want to see that you are slow because of an external library and it allocates more than your code does. Believe me :neckbeard:, you want to focus on your business logic and have the dependencies as efficient as possible.

Another reason is memory limitations. All of them have size limitation caused by JVM array size limit. In JVM, arrays use integers for indexes, therefore the max size is limited by the max size of integers which is 2 147 483 647. If we create an array of longs to store bits then we can store 64 bit * 2 147 483 647 = 137 438 953 408 bits. This takes ~15 GB of memory. You can put ~10 000 000 000 elements with 0.1% probability into this Bloom filter. This is more than enough for most software. But when you work with Big Data such as web urls, banner impressions, RTB bid requests, or streams of events and Machine Learning, then 10 billion elements is just the beginning. Sure, you can have workarounds for that: multiple Bloom filters, distribute them across multiple nodes but those workarounds aren't always efficient, can be pricey TODO or don't fit into your architecture.

Let's take a look at some of the available solutions.

### Google's Guava

[Guava][github-guava] is a high quality core library from Google which contains such modules as collections, primitives, concurrency, I/O, caching, etc. And it has the [Bloom filter][github-guava-bloomfilter] data structure. Guava is the default option to start with for me. It works as expected. It's fast. But...

 Surprisingly, it allocates! I used [the Google's Allocation Instrumenter][github-allocation-instrumenter] to print out all allocations. The following allocations happened for a check whether a 100 symbols string present in a Bloom filter or not. Here's the list:

```
I just allocated the object [B@39420d59 of type byte whose size is 40 It's an array of size 23
I just allocated the object java.nio.HeapByteBuffer[pos=0 lim=23 cap=23] of type java/nio/HeapByteBuffer whose size is 48
I just allocated the object com.google.common.hash.Murmur3_128HashFunction$Murmur3_128Hasher@5dd227b7 of type com/google/common/hash/Murmur3_128HashFunction$Murmur3_128Hasher whose size is 48
I just allocated the object [B@3d3b852e of type byte whose size is 24 It's an array of size 1
I just allocated the object [B@14ba7f15 of type byte whose size is 24 It's an array of size 1
I just allocated the object sun.nio.cs.UTF_8$Encoder@55cb3b7 of type sun/nio/cs/UTF_8$Encoder whose size is 56
I just allocated the object [B@497fd334 of type byte whose size is 320 It's an array of size 300
I just allocated the object [B@280c3dc0 of type byte whose size is 312 It's an array of size 296
I just allocated the object java.nio.HeapByteBuffer[pos=0 lim=296 cap=296] of type java/nio/HeapByteBuffer whose size is 48
I just allocated the object [B@6f89ad03 of type byte whose size is 32 It's an array of size 16
I just allocated the object java.nio.HeapByteBuffer[pos=0 lim=16 cap=16] of type java/nio/HeapByteBuffer whose size is 48
I just allocated the object 36db757cdd5ae408ef61dca2406d0d35 of type com/google/common/hash/HashCode$BytesHashCode whose size is 16
```

This is 1016 bytes!! This is A LOT!! Just think about, we take a hash (number) of a short string and check whether the bits are set, and it allocates ~1Kb of data. You could argue that allocations are cheap.
Yes, they are, and you most probably won't see an impact in isolated micro-benchmarks, but in production it gets much worse: it can stress the GC, cause slow allocation paths, trigger the GC. TODO

Anyway, it was fun to review the code. Sometimes you can find some nice Easter eggs there. For example this one:

![The song]({{ site.url }}{{ site.baseurl }}/images/bloom-filter-for-scala/guava-review.png)

These lines are from [the "O.P.P." song by "Naughty by Nature" group][wiki-opp] which was very popular in the early 1990s. He's probably in his 50s at the moment (or was it she?). (Disturbed should be over by this moment. Enjoy [the clip:][youtube-opp])

### Twitter's Algebird

TODO
It's functional, immutable and monadic and very slooooow!!
It supports only `string` as the element type.  Yeah, string is the universal format, you know, you can store everything there.

It uses Murmur hash. takes 128 bit and splits it to 4 32 bit hashes. It sets bit for each 32 bit number. Which is quite disputable solution.

Going deeper
What's interesting Twitter's Bloom filter uses `EWAHCompressedBitmap` under the hood which is TODO  
normal sparse bitsets.
It's optimization for memory but its random access is slow (really slow). because

uniform distribution
as uniform as better.

Here's what they say https://github.com/lemire/javaewah#when-should-you-use-compressed-bitmaps
Again, quite disputable solution in my opinion.

I performed rough tests to check total allocated memory.
I put 100,000 random 1000 symbols string to both Bloom filters, Twitter's and mine. And it appeared that Algebird's Bloom filter allocated even more memory than the Bloom filter.

I won't post the list of all allocations because it's pretty long. Allocations for 100 symbol string is 1808 bytes. Assuming that we don't allocate new `EWAHCompressedBitmap`s


Price to be functional
going ahead, it's performance is 120 times worse than the Bloom filter proposed by me.

### ScalaNLP's Breeze

"Breeze is a generic, clean and powerful Scala numerical processing library... Breeze is a part of ScalaNLP project, a scientific computing platform for Scala."

That sounds interesting, like a fresh wind. But...
There's [a surprise lurked inside.][github-breeze-hashcode] It takes a hash of the object. "WAT?? Where's beloved Murmur?" you ask. It's used only for "finalizing" the object's hash. for what, distribution? seriously? If you don't know that little nuance you are done with large datasets.

And again allocations - 544 bytes this time.
Scala specific TODO

```scala
for {
  i <- 0 to numHashFunctions
} yield {
  val h = hash1 + i * hash2
  val nextHash = if (h < 0) ~h else h
  nextHash % numBuckets
}
```

It compiles to:



#### Others

TODO

### How does it work?

Zero allocations - tricks with string

Uses unsafe to create huge arrays.
MurmurHash3
Generic version of it
Pluggable via implicit, type class pattern. TODO link to tpole
Contravariant implicits -> Dotty

```scala
implicit object CanGenerate128HashFromString extends CanGenerate128HashFrom[String] {

  import scala.concurrent.util.Unsafe.{instance => unsafe}

  private val valueOffset = unsafe.objectFieldOffset(classOf[String].getDeclaredField("value"))
  private val charBase = unsafe.arrayBaseOffset(classOf[Array[java.lang.Character]])

  override def generateHash(from: String): (Long, Long) = {
    val value = unsafe.getObject(from, valueOffset).asInstanceOf[Array[Char]]
    MurmurHash3Generic.murmurhash3_x64_128(value, charBase, from.length * 2, 0)
  }
}
```


Small, No dependencies TODO

128 bit version

Limitations: TODO
CanGenerateHashFrom is invariant
You need to implement the hash function for you types by yourself.
But I believe it's a reasonable price to pay for performance.

Can I use it from Java?

Yes you can. Unfortunately, it won't be as nice as in Scala but you got used to it, uh? No implicits and compiler won't help you. Integration with Scala is ugly in some parts but it works.

```java
long expectedElements = 10000000;
double falsePositiveRate = 0.1;
BloomFilter<byte[]> bf = BloomFilter.apply(
        expectedElements,
        falsePositiveRate,
        CanGenerateHashFrom.CanGenerateHashFromByteArray$.MODULE$);

byte[] element = new byte[100];
bf.add(element);
bf.mightContain(element);
```


### Benchmarks

We all love benchmarks, right? Numbers in vacuum, they are cool. And here they are:

Warning: synthetic benchmarks in vacuum. Usually, the difference is more significant in production systems. GC stress.

Here's a benchmark for the `String` type:

```
[info] Benchmark                                              (length)   Mode  Cnt          Score         Error  Units
[info] alternatives.algebird.StringItemBenchmark.algebirdGet      1024  thrpt   20    1181080.172 ▒    9867.840  ops/s
[info] alternatives.algebird.StringItemBenchmark.algebirdPut      1024  thrpt   20     157158.453 ▒     844.623  ops/s
[info] alternatives.breeze.StringItemBenchmark.breezeGet          1024  thrpt   20    5113222.168 ▒   47005.466  ops/s
[info] alternatives.breeze.StringItemBenchmark.breezePut          1024  thrpt   20    4482377.337 ▒   19971.209  ops/s
[info] alternatives.guava.StringItemBenchmark.guavaGet            1024  thrpt   20    5712237.339 ▒  115453.495  ops/s
[info] alternatives.guava.StringItemBenchmark.guavaPut            1024  thrpt   20    5621712.282 ▒  307133.297  ops/s

[info] bloomfilter.mutable.StringItemBenchmark.myGet              1024  thrpt   20   11483828.730 ▒  342980.166  ops/s
[info] bloomfilter.mutable.StringItemBenchmark.myPut              1024  thrpt   20   11634399.272 ▒   45645.105  ops/s
[info] bloomfilter.mutable._128bit.StringItemBenchmark.myGet      1024  thrpt   20   11119086.965 ▒   43696.519  ops/s
[info] bloomfilter.mutable._128bit.StringItemBenchmark.myPut      1024  thrpt   20   11303765.075 ▒   52581.059  ops/s
```


No difference in element size, within statistic error
ThreadLocal - no difference in synthetic tests - Allocation is extremely cheap
I hope JVM will get structs during my dev life.


### Where to use?

High performance and low latency systems.  
Big Data and Machine Learning systems with a lot of data and unique elements.


When not to use it:  
You are ok with your current solution. Most software don’t have to be fast.  
You trust only proven and battle tested libraries from loud names like Google or Twitter.  
You want it to work out of the box.


### TODO

Feedback is welcome and appreciated
Stable Bloom filter
Cuckoo Bloom filer any experience anybody?

  [github-source]: https://github.com/alexandrnikitin/bloom-filter-scala
  [youtube-bored]: https://www.youtube.com/watch?v=-WdYo3WlETY
  [wiki-bloom-filter]: https://en.wikipedia.org/wiki/Bloom_filter
  [sc5-bloom-filter]: https://sc5.io/posts/what-are-bloom-filters-and-why-are-they-useful/
  [github-allocation-instrumenter]: https://github.com/google/allocation-instrumenter
  [youtube-opp]: https://www.youtube.com/watch?v=6xGuGSDsDrM
  [wiki-opp]: https://en.wikipedia.org/wiki/O.P.P._(song)
  [github-breeze-hashcode]: https://github.com/scalanlp/breeze/blob/c12763387cb0741e6d588435d7da92b505f12843/math/src/main/scala/breeze/util/BloomFilter.scala#L36
  [github-guava]: https://github.com/google/guava
  [github-guava-bloomfilter]: https://github.com/google/guava/wiki/HashingExplained#bloomfilter
  [twitter-pagels]: TODO
