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
They have a lot of advantages and benefits. In documentation it's written that they let you write simple maintainable code, it's even bold. They reduce code duplication. They are smart and support constraints such as class or struct, implements class or interface. They can save inheritance through co and contravariance. They improve performance, no more boxings/unboxings, no castings. And everything happens during compilation. How cool is that? But all that is not for free. Let's take a look how much they cost.

At first let's recall how objects are stored in memory. When we create an instance of an object then such structure appears in heap. Where the first element called header which contains hashcode of address in lock table. The second element is Method table. Next goes fields of the object. So the variable "o" is just a number(pointer) that points to Method table.

And the Method table is ...

Let me start from EEClass ;) EEClass is a class, it knows everything about the type it represents, it give access to it's knowledge through getter and setters. It's a quite complex class that consists of 2000 lines of code and contains other classes and structs which are also not so small :) For example `EEClassOptionalFields` that is something like a dictionary that stores optional data. Or `EEClassPackedFields` which is optimization for memory. EEClass stores a lot of numeric data such as number of method, fields, static methods, static fields and etc. So EEClassPackedFields optimizes them and cuts leading zeros and pack into one array with access by index. EEClass is also called "cold data". So getting back to Method Table.

Method table is optimization! Everything that runtime needs is extracted here from EEClass. It's an array with access by index. It is also called "hot data". It contains... TBA

To take a look at how they are presented in Runtime WinDBG comes to the rescue, the great and powerful. It's a very powerful tool for debugging of any application for Windows but it has awful user interface and user experience. There are plugins: SOS (Son of Strike) from CLR team and SOSex from 3rd party developer. Son of Strike isn't just a nice name. When the CLR team was created they had informal name called "Lightning". They created a tool for debug of Runtime and called it Lightning Strike. It was a very powerful tool that could do everything in Runtime. When time came to release they limited it and called Son of Strike. Such a nice story.

Let's take a simple class. It has a field and a method. If we create an instance of it and make a dump of memory then we will see our object there. and its method table.
Pay attension to its name, some statics and table of methods. WinDBG and SOS has a problem it doesn't show some information but shows unnecessary too.

Let's take a loot at the EEClass

Links
