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
Pay attention to its name, some statics and table of methods. WinDBG and SOS has a problem it doesn't show some information but shows unnecessary too.

Let's take a loot at the EEClass

Links

Let's take a look at how generics affect our Method tables and EEClasses. Let's take a simple generic class and compile it. We got. The name has type arity. and !T instead of type. It's a template that tells JIT that the type is generic and will be compile in it's own way. O Miracle! CLR knows about generics.

let's create an instance of our generic with type `object` and take a look at the method table. The name has parameter object but methods have strange signature. Magical `System.__Canon` appeared. EEClass. The name with `System.__Canon` and type of field is also `System.__Canon`

Let's create an instance with string type. The name with string type but methods have the same strange signature with `System.__Canon`. If we take a look more closer then we'll se that addresses are the same as in previous type. The same in EEClass.

Let's create and instance of value type. Name with int type, signature too. EEClass is typed with int too.

So how does it work then? Value type do not share anything and have their own method tables, EEClasses, methods. Reference types share code of methods and EEClass between each other. But they have their own Method tables. `System.__Canon` is an internal type. Its main goal to tell JIT that the type will be defined during Runtime.

What means does CLR have to do that?
Classloader - it goes through all hierarchy of objects and their methods and tries what will be called. Obviously it's the slowest way to do it.
So CLR adds cache for a type. then...
And the fastest that possible? A slot in method table.
One important nore: CLR optimizes call of generics from your method, but not the generics methods itselves. i.e. It add slots to your class but not in generic class.
And the performance of each method.

And the dessert. The most interesting part imo. I work on high-load low latency and other fancy systems. At that time I worked on Real Time Bidding system that hanlded ~500k RPS with latencies below 5ms. After some changes? we encountered with performance drawdown in one of our modules that parsed user agent and extracted some data from it. I maximally simplified the code that reproduces the issue.
We have a generic class which has a generic field. In ctr we call generic method. in Method Run too. And an empty class derived from it.
And a benchmark. And derived type 3.5 times slower.
Who can explain it??
I asked a question on SO. A lot of people appeared and started to teach me how to write benchmarks. Meanwhile on RSDN an interesting workaround was found. Just add two empty methods. My first thoughts were like WAT?? What programming is it when you ad two empty methods and it flies?? Then i got an answer from Microsoft with the same workaround and saying that the thing is in JIT heuristic algorithm. I relieved. Then sources of CLR were opened. Then I got an explanation from one of CLR core developers who explained everything in details and admitted that it's a bug in JITter. Here's the fix. They didn't touch the comment which says the right thing that wasn't done.


### Moral.
You code is slow? Just add two empty methods. Just kidding. There's no such. Everyone has This bug
I just was lucky to find it and pushed CLR team to fix it. Actually .NET is being done by developer as you and me. They also make bugs. And that's normal.
Just for fun. If there wouldn't be an interest then nothing would happen.
