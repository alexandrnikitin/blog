---
layout: post
title: "Bloom filter for Scala"
date: 2016-02-09T18:03:32+02:00
modified:
categories: [Scala, Algorithms]
excerpt: The fastest implementation of Bloom filter for Scala
tags: [Scala, Algorithms]
comments: true
share: true
---


### TL;DR

[Sources on github](github-source)  
The fastest implementation for JVM.  
No limits to the number of elements and false positive rate.  
Extendable - plug-in any hash algorithm or element type to hash.  

### Intro

>A Bloom filter is a space-efficient probabilistic data structure that is used to test whether an element is a member of a set. False positive matches are possible, but false negatives are not. In other words, a query returns either "possibly in set" or "definitely not in set". Elements can be added to the set, but not removed

from wikipedia

Short intro
Optimization for memory.
It can answer one question: does an element belong to a set or not.
(on the source of truth.)(wiki-bloom-filter)
I find the following explanation very I couldn't do it better. ["What are Bloom filters, and why are they useful?" by Max Pagels][sc5-bloom-filter]


### WHY?

Because alternatives suck! They don't fit our needs. You just know that you can do better. Frankly, nothing is true. You just get bored sometimes. [theme song][youtube-bored]

All have size limits caused by JVM array index size.
You cannot create a bloom filter for m elements with false positive rate 1% There are workarounds for that.

#### Google's Guava

Guava: - the best. But
Hashing - allocations

It was fun to review. It always fun.
// You down with FPP? (Yeah you know me!) Who's down with FPP? (Every last homie!)

#### Twitter's Algebird

String is universal format you know
Hashes x4??
Performance? Pooooooor
EWAHCompressedBitmap - random access, arguable solution


#### Breeze
It takes a hash of the object. WTF?? Murmur? for what, distribution? seriously?
Allocations
Syntax

#### Others

TODO

### How does it work?

Uses unsafe to create huge arrays.
MurmurHash3
Generic version of it
Pluggable via implicit, type class pattern.
Still have doubts?

Small, No dependencies TODO

### Benchmarks

We all love benchmarks, right? Numbers in vacuum, they are cool. And here they are:

No difference in element size, within statistic error
ThreadLocal - no difference in synthetic tests - Allocation is extremely cheap
I hope JVM will get structs during my dev life.


### When to use?

You are not satisfied with existing solutions.
High performance systems.
Systems with a lot of data and unique items.


When not
You are ok with your current solution. Most software doesn’t have to be fast.
You want to use only proven and battle tested libraries from loud names like Google or Twitter


### TODO

Feedback is really welcome and appreciated
Java support
Immutable version. I don't know why?)

  [github-source]: https://github.com/alexandrnikitin/bloom-filter-scala
  [youtube-bored]: https://www.youtube.com/watch?v=-WdYo3WlETY
  [wiki-bloom-filter]: https://en.wikipedia.org/wiki/Bloom_filter
  [sc5-bloom-filter]: https://sc5.io/posts/what-are-bloom-filters-and-why-are-they-useful/
