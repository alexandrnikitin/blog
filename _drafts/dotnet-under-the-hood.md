---
layout: post
title: .NET generics under the hood
date: 2015-07-11 16:46:00
summary: .NET generics, memory layout and how generics affect it, under the hood, JITter bug
categories: .NET CLR
---

### Plan

  1. Generics in general
  2. .NET memory layout
  3. How generics affect the layout
  4. Generics under the hood
  5. JITter bug we encountered
  6. Slides from the talk

The post is based on the talk I gave at a .NET meetup todo.

I wanted to start from comparison with Java and C++ just to show that .NET is awesome. But decided not to do that because we already know that .NET is awesome. Don't we? So let's leave it as a statement :smile:
We will recall .NET memory layout and how objects lay in memory, what's Method table and EEClass. We will take a look how generics affects them and how they work under the hood. Then I'll tell you about performance degradation we encountered and about a bug in JITter.

Yes, Java. When I developed for .NET I always thought that it's cool there, somewhere else, in another world, stack or language. That everything is interesting and easy there. E.g. when we introduce Kafka we could process millions of event easily. Or Akka-stream, that's a bomb and would solve all our streaming problems. Or hey, Scala has pattern matching... And interest took root and I moved to JVM. And move than half a year I write on Scala. I noticed that I started to curse more often, don't sleep well, come home and cry on my pillow sometimes. I don't have accustomed  things and tools anymore that I had in .NET. And generics of cause which don't exist in JVM.

People say here in Lithuania: todo That means dog can get used even to gallows. Ok, let's not talk about bad things.

Generics in .NET. And they are awesome! Probably there's no developers who didn't use them or love them. Is there?
They have a lot of advantages. In documentation it's written that they let you write simple maintainable code, it's even bold. They reduce code duplication. They are smart and support constraints such as class or struct, implements class or interface. They can save inheritance through co and contravariance. They improve performance, not more boxing/unboxings, no castings. And everything happens during compilation. How cool is that? But all that is not for free. Let's take a look how much they cost.
