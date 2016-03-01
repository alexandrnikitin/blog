---
layout: post
title: "Bloom filter for Scala"
date: 2016-02-09T18:03:32+02:00
modified:
categories: [Scala, Algorithms]
excerpt:
tags: [Scala, Algorithms]
comments: true
share: true
---


# TLDR
Super fast (the fastest)
No elements amount limitation
Extendable - plug in any hash algorithm or type

# What beast is that Bloom filter?

Short intro

# WHY?

Because alternatives sucks!!!

All have size limitations

Guava:
Hashing - allocations

It was fun to review. It always fun.
// You down with FPP? (Yeah you know me!) Who's down with FPP? (Every last homie!)

Breeze:
Hash of object. WTF?? Murmur? seriously?
Allocations
Syntax

Algebird:
Hashes x4??
String is universal format you know
Performance? Pooooooor
EWAHCompressedBitmap - random access

# How does it work?

MurmurHash3
Generic version of it
Pluggable via implicit, type class pattern.

Small, No dependencies TODO

# Benchmarks

Everybody love benchmarks
Here they are.

No difference in element size, within statistic error
ThreadLocal - no difference in synthetic tests - Allocation is extremely cheap


# When to use?

You are not satisfied with existing solutions.
High performance systems
Systems with high amount of unique items.


When not
You are ok with your current solution
Most software doesn’t have to be fast
You want to use only proven libraries from loud names like Google or Twitter (it wasn't me :)


# TODO

Java support
Immutable version
