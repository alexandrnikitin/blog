---
layout: post
title: .NET generics under the hood
date: 2015-09-25
modified: 2015-09-25
excerpt: About .NET memory layout and how generics affect it, how they work under the hood and a JITter bug for dessert.
tags: [.NET, CLR]
comments: true
share: true
---

Note: This post is based on the talk I gave at [a .NET meetup][meetup]. You can find [slides here][slides].
{: .notice}

### Intro

I wanted to start from comparison with Java and C++ just to show that .NET is awesome. But decided not to do that because we already know that .NET is awesome. Don't we? So let's leave it as a statement :smile:  So we will recall .NET memory layout and how objects lay in memory, what's `Method Table` and `EEClass`. We will take a look at how generics affect them and how they work under the hood. Then there's a dessert prepared with performance degradation and a bug in CLR.

When I was developing for .NET I always thought that it's cool somewhere else, in another world, stack or language. That everything is interesting and easy there. Hey, Scala has pattern matching, they shouted. Once we introduce Kafka we could process millions of events easily. Or Akka Streams, that's a bleeding edge and would solve all our stream processing problems. And interest took root and I moved to JVM. And more than half a year I write code on Scala. I noticed that I started to curse more often, I don't sleep well, come home and cry on my pillow sometimes. I don't have accustomed things and tools anymore that I had in .NET. And generics of cause which don't exist in JVM :sob: People say here in Lithuania: `"Šuo ir kariamas pripranta."` That means dog get used even to gallows. Ok, let's not talk about it.

### Generics in .NET

And they are awesome! Probably there are no developers who didn't use them or love them. Is there? They have a lot of advantages and benefits. In CLR documentation it's written that they **make programming easier**, yes it's [bold there][coreclr-generics]. They reduce code duplication. They are smart and support constraints such as class or struct, implements class or interface. They can preserve inheritance through covariance and contravariance. They improve performance: no more boxings/unboxings, no castings. And all that happen during compilation. How cool is that?! But nothing goes for free and we'll figure out the price :wink:

### .NET memory layout

At first let's recall how objects are stored in memory. When we create an instance of an object then the following structure allocated in the heap:

```cs
var o = new object();
```

```
+----------------------+
|     An instance      |
+----------------------+
| Header               |
| Method Table address |
| Field1               |
| FieldN               |
+----------------------+
```

Where the first element called "Header" and contains hashcode or address in the lock table. The second element contains the `Method Table` address. Next goes fields of the object. So the variable `o` is just a number (pointer) that points to the `Method Table`. And the `Method Table` is ...

##### EEClass
Let me start from `EEClass` :wink: `EEClass` is a class, it knows everything about the type it represents. It gives access to its data through getter and setters. It's a quite complex class which consists of [more than 2000 lines of code][EEClass] and contains other classes and structs which are also not so small. For example [`EEClassOptionalFields`][EEClassOptionalFields] that is something like a dictionary that stores optional data. Or [`EEClassPackedFields`][EEClassPackedFields] which is optimization for memory. `EEClass` stores a lot of numeric data such as number of method, fields, static methods, static fields and etc. So `EEClassPackedFields` optimizes them and cuts leading zeros and pack into one array with access by index. `EEClass` is also called "cold data". So getting back to `Method Table`.

##### Method Table
`Method Table` is optimization! Everything that runtime needs is extracted from `EEClass` to the `Method Table`. It's an array with access by index. It is also called "hot data". It contains the following data:

```
+-------------------------------------+
|            Method Table             |
+-------------------------------------+
| EEClass address                     |
| Interface Map Table address         |
| Inherited Virtual Method addresses  |
| Introduced Virtual Method addresses |
| Instance Method addresses           |
| Static Method addresses             |
| Static Fields values                |
| InterfaceN method addresses         |
+-------------------------------------+
```

##### WinDbg

To take a look at how they are presented in CLR [`WinDbg`][WinDbg] comes to the rescue - the great and powerful. It's a very powerful tool for debugging any application for Windows but it has awful user interface and user experience :flushed: There are plugins: [`SOS`][SOS] (Son of Strike) from CLR team and [`SOSex`][SOSex] from a 3rd party developer. The Son of Strike isn't just a nice name. When the CLR team was created they had informal name "Lightning". They created a tool for debugging Runtime and called it "Strike". It was a very powerful tool that could do everything in CLR. When time came to first release they limited it and called "Son of Strike". True story :wink:

##### Plain class example
Let's take a simple class:

```cs
public class MyClass
{
    private int _myField;

    public int MyMethod()
    {
        return _myField;
    }
}
```

It has a field and a method. If we create an instance of it and make a dump of the memory then we will see our object there:

```cs
var myClass = new MyClass();
```

```
0:003> !DumpHeap -type GenericsUnderTheHood.MyClass
Address          MT                     Size
0000004a2d912de8 00007fff8e7540d8       24

Statistics:
MT                      Count       TotalSize   Class Name
00007fff8e7540d8        1           24          GenericsUnderTheHood.MyClass
Total 1 objects
```

and its `Method Table`:

```
 0:003> !dumpmt -md 00007fff8e7540d8
EEClass:         00007fff8e8623f0
Module:          00007fff8e752fc8
Name:            GenericsUnderTheHood.MyClass
mdToken:         0000000002000002
File:            C:\Projects\my\GenericsUnderTheHood\GenericsUnderTheHood\bin\Debug\GenericsUnderTheHood.exe
BaseSize:        0x18
ComponentSize:   0x0
Slots in VTable: 6
Number of IFaces in IFaceMap: 0
--------------------------------------
MethodDesc Table
Entry            MethodDesc       JIT    Name
00007fffecc86300 00007fffec8380e8 PreJIT System.Object.ToString()
00007fffeccce760 00007fffec8380f0 PreJIT System.Object.Equals(System.Object)
00007fffeccd1ad0 00007fffec838118 PreJIT System.Object.GetHashCode()
00007fffeccceb50 00007fffec838130 PreJIT System.Object.Finalize()
00007fff8e8701c0 00007fff8e7540d0    JIT GenericsUnderTheHood.MyClass..ctor()
00007fff8e75c048 00007fff8e7540c0   NONE GenericsUnderTheHood.MyClass.MyMethod()
```

We can see its name, some statics and table of methods. WinDbg/SOS has a problem it doesn't show all information but shows additional from other sources too. And the `EEClass`:

```
0:003> !DumpClass 00007fff8e8623f0
Class Name:      GenericsUnderTheHood.MyClass
mdToken:         0000000002000002
File:            C:\Projects\my\GenericsUnderTheHood\GenericsUnderTheHood\bin\Debug\GenericsUnderTheHood.exe
Parent Class:    00007fffec824908
Module:          00007fff8e752fc8
Method Table:    00007fff8e7540d8
Vtable Slots:    4
Total Method Slots:  5
Class Attributes:    100001
Transparency:        Critical
NumInstanceFields:   1
NumStaticFields:     0
MT                Field          Offset    Type          VT Attr     Value Name
00007fffecf03980  4000001        8         System.Int32  1 instance  _myField
```

### Generics under the hood

##### Generic class example
Let's take a look at how generics affect our `Method Table`s and `EEClass`es. Let's take a simple generic class:

```cs
public class MyGenericClass<T>
{
    private T _myField;

    public T MyMethod()
    {
        return _myField;
    }
}
```

After compilation we get:

```cs
.class public auto ansi beforefieldinit
    GenericsUnderTheHood.MyGenericClass`1<T>
        extends [mscorlib]System.Object
{
    .field private !T _myField

    .method public hidebysig
        instance !T MyMethod () cil managed
    {
        ...
    }

    ...
}
```

The name has type [arity][wiki-arity] "\`1" showing the number of generic types and `!T` instead of type. It's a template that tells JIT that the type is generic and unknown at the compile time and will be defined later. Miracle! CLR knows about generics :relieved: Let's create an instance of our generic with type `object` and take a look at the Method Table:

```cs
var myObject = new MyGenericClass<object>();
```

```
0:003> !DumpMT -md 00007fff8e754368
EEClass:         00007fff8e862510
Module:          00007fff8e752fc8
Name:            GenericsUnderTheHood.MyGenericClass`1[[System.Object, mscorlib]]
mdToken:         0000000002000003
File:            C:\Projects\my\GenericsUnderTheHood\GenericsUnderTheHood\bin\Debug\GenericsUnderTheHood.exe
BaseSize:        0x18
ComponentSize:   0x0
Slots in VTable: 6
Number of IFaces in IFaceMap: 0
--------------------------------------
MethodDesc Table
Entry            MethodDesc       JIT    Name
00007fffecc86300 00007fffec8380e8 PreJIT System.Object.ToString()
00007fffeccce760 00007fffec8380f0 PreJIT System.Object.Equals(System.Object)
00007fffeccd1ad0 00007fffec838118 PreJIT System.Object.GetHashCode()
00007fffeccceb50 00007fffec838130 PreJIT System.Object.Finalize()
00007fff8e870210 00007fff8e754280    JIT GenericsUnderTheHood.MyGenericClass`1[[System.__Canon, mscorlib]]..ctor()
00007fff8e75c098 00007fff8e754278   NONE GenericsUnderTheHood.MyGenericClass`1[[System.__Canon, mscorlib]].MyMethod()
```

The name has `System.Object` parameter type but methods have strange signature. Mystic `System.__Canon` appeared. The `EEClass`:

```
0:003> !DumpClass 00007fff8e862510
Class Name:      GenericsUnderTheHood.MyGenericClass`1[[System.__Canon, mscorlib]]
mdToken:         0000000002000003
File:            C:\Projects\my\GenericsUnderTheHood\GenericsUnderTheHood\bin\Debug\GenericsUnderTheHood.exe
Parent Class:    00007fffec824908
Module:          00007fff8e752fc8
Method Table:    00007fff8e7542a0
Vtable Slots:    4
Total Method Slots:  6
Class Attributes:    100001
Transparency:        Critical
NumInstanceFields:   1
NumStaticFields:     0
MT                Field          Offset  Type            VT Attr       Value Name
00007fffecf05c80  4000002        8       System.__Canon  0 instance    _myField
```

The name with the same mystic `System.__Canon` and type of field is also `System.__Canon`. Let's create an instance with string type:

```csharp
var myString = new MyGenericClass<string>();
```

```
0:003> !DumpMT -md 00007fff8e754400
EEClass:         00007fff8e862510
Module:          00007fff8e752fc8
Name:            GenericsUnderTheHood.MyGenericClass`1[[System.String, mscorlib]]
mdToken:         0000000002000003
File:            C:\Projects\my\GenericsUnderTheHood\GenericsUnderTheHood\bin\Debug\GenericsUnderTheHood.exe
BaseSize:        0x18
ComponentSize:   0x0
Slots in VTable: 6
Number of IFaces in IFaceMap: 0
--------------------------------------
MethodDesc Table
Entry       MethodDesc    JIT Name
00007fffecc86300 00007fffec8380e8 PreJIT System.Object.ToString()
00007fffeccce760 00007fffec8380f0 PreJIT System.Object.Equals(System.Object)
00007fffeccd1ad0 00007fffec838118 PreJIT System.Object.GetHashCode()
00007fffeccceb50 00007fffec838130 PreJIT System.Object.Finalize()
00007fff8e870210 00007fff8e754280    JIT GenericsUnderTheHood.MyGenericClass`1[[System.__Canon, mscorlib]]..ctor()
00007fff8e75c098 00007fff8e754278   NONE GenericsUnderTheHood.MyGenericClass`1[[System.__Canon, mscorlib]].MyMethod()
```

The name with string type but methods have the same strange signature with `System.__Canon`. If we take a look more closer then we'll se that addresses are the same as in previous example with `object` type. So the `EEClass` is the same. Let's create and instance of value type.

```csharp
var myInt = new MyGenericClass<int>();
```

```
0:003> !DumpMT -md 00007fff8e7544c0
EEClass:         00007fff8e862628
Module:          00007fff8e752fc8
Name:            GenericsUnderTheHood.MyGenericClass`1[[System.Int32, mscorlib]]
mdToken:         0000000002000003
File:            C:\Projects\my\GenericsUnderTheHood\GenericsUnderTheHood\bin\Debug\GenericsUnderTheHood.exe
BaseSize:        0x18
ComponentSize:   0x0
Slots in VTable: 6
Number of IFaces in IFaceMap: 0
--------------------------------------
MethodDesc Table
Entry       MethodDesc    JIT Name
00007fffecc86300 00007fffec8380e8 PreJIT System.Object.ToString()
00007fffeccce760 00007fffec8380f0 PreJIT System.Object.Equals(System.Object)
00007fffeccd1ad0 00007fffec838118 PreJIT System.Object.GetHashCode()
00007fffeccceb50 00007fffec838130 PreJIT System.Object.Finalize()
00007fff8e870260 00007fff8e7544b8    JIT GenericsUnderTheHood.MyGenericClass`1[[System.Int32, mscorlib]]..ctor()
00007fff8e75c0c0 00007fff8e7544b0   NONE GenericsUnderTheHood.MyGenericClass`1[[System.Int32, mscorlib]].MyMethod()
```

Name with `int` type, signature too. The `EEClass` is typed with `int` too.

```
0:003> !DumpClass 00007fff8e862628
Class Name:      GenericsUnderTheHood.MyGenericClass`1[[System.Int32, mscorlib]]
mdToken:         0000000002000003
File:            C:\Projects\my\GenericsUnderTheHood\GenericsUnderTheHood\bin\Debug\GenericsUnderTheHood.exe
Parent Class:    00007fffec824908
Module:          00007fff8e752fc8
Method Table:    00007fff8e7544c0
Vtable Slots:    4
Total Method Slots:  6
Class Attributes:    100001
Transparency:        Critical
NumInstanceFields:   1
NumStaticFields:     0
MT    Field   Offset                 Type VT     Attr            Value Name
00007fffecf03980  4000002        8         System.Int32  1 instance           _myField
```

##### Under the hood
So how does it work then? Value types do not share anything and have their own `Method Tables`, `EEClasses` and method code. Reference types share code of methods and `EEClass` between each other but they have their own `Method Tables`. So `Method Table` uniquely describes a type. `System.__Canon` is an internal type. Its main goal to tell JIT that the type will be defined during Runtime.

What means does CLR have to do that?
Classloader - it goes through all hierarchy of objects and their methods and tries what will be called. Obviously it's the slowest way to do it.
So CLR adds cache for a type. then...
And the fastest that possible? A slot in Method Table.
One important note: CLR optimizes a call of a generic method in __your__ method, not the generic method itself. I.e. it adds slots to your class `Method Table` not to generic class `Method Table`.
TODO Add the performance of each method.

### The dessert
The most interesting part for me. I work on high-load low latency and other fancy-schmancy systems. At that time I worked on the [Real Time Bidding][RTB] system that handled ~500K RPS with latencies below 5ms. After some changes we encountered with the performance degradation in one of our modules that parsed User-Agent header and extracted some data from it. I simplified the code as much as I could to reproduce the issue:

```csharp
public class BaseClass<T>
{
    private List<T> _list = new List<T>();

    public BaseClass()
    {
        Enumerable.Empty<T>();
        // or Enumerable.Repeat(new T(), 10);
        // or even new T();
        // or foreach (var item in _list) {}
    }

    public void Run()
    {
        for (var i = 0; i < 8000000; i++)
        {
            if (_list.Any())
            // or if (_list.Count() > 0)
            // or if (_list.FirstOrDefault() != null)
            // or if (_list.SingleOrDefault() != null)
            // or other IEnumerable<T> method
            {
                return;
            }
        }
    }
}

public class DerivedClass : BaseClass<object>
{
}
```

We have a generic class `BaseClass<T>` which has a generic field and a method `Run` to perform some logic. In constructor we call a generic method and in method `Run()` too. And we have an empty class `DerivedClass` which is inherited from the `BaseClass<T>`. And a benchmark:

```csharp
public class Program
{
    public static void Main()
    {
        Measure(new DerivedClass());
        Measure(new BaseClass<object>());
    }

    private static void Measure(BaseClass<object>> baseClass)
    {
        var sw = Stopwatch.StartNew();
        baseClass.Run();
        sw.Stop();
        Console.WriteLine(sw.ElapsedMilliseconds);
    }
}
```

And the empty `DerivedClass` 3.5 times slower. Can you explain it??
I asked [a question on SO][SO]. A lot of developers appeared and started to teach me how to write benchmarks :laughing: Meanwhile [on RSDN][RSDN] an interesting workaround was found: "Just add two empty methods":

```csharp
public class BaseClass<T>
{
...
    public void Method1()
    {
    }

    public void Method2()
    {
    }
...
}
```

My first thoughts were like WAT?? What programming is that when you add two empty methods and it performs faster?? Then I got [an answer from Microsoft][MicrosoftConnect] with the same workaround and saying that the thing is in JIT heuristic algorithm. I felt relieve. No more magic there. Then sources of CLR were opened and I raise [an issue on github][github-issue]. Then I got [an explanation][github-explanation] from @cmckinsey one of CLR engineers/managers who explained everything in details and admitted that it's a bug in JITter. [Here's the fix:][github-fix]
<figure>
	<a href="{{ site.url }}/images/dotnet-generics-under-the-hood/the-fix.png"><img src="{{ site.url }}/images/dotnet-generics-under-the-hood/the-fix.png"></a>
</figure>
Take a look at the comment above the changed lines - it wasn't changed because was right. That rare moment :open_mouth:


### Moral
Is your code slow? Just add two empty methods :laughing:
Everyone had this bug for years. I just was lucky to find it and pushed and asked CLR team to fix it. Actually .NET is being done by developer as you and me. They also make bugs. And that's normal.
Just for fun. If there wouldn't be an interest then nothing would happen.

  [meetup]: https://www.facebook.com/events/106836509655188/
  [slides]: http://alexandrnikitin.github.io/slides/generics-under-the-hood/#/
  [coreclr-generics]: https://github.com/dotnet/coreclr/blob/master/Documentation/botr/intro-to-clr.md#parameterized-types-generics
  [EEClass]: https://github.com/dotnet/coreclr/blob/4cf8a6b082d9bb1789facd996d8265d3908757b2/src/vm/class.cpp
  [EEClassOptionalFields]: https://github.com/dotnet/coreclr/blob/4cf8a6b082d9bb1789facd996d8265d3908757b2/src/vm/class.h#L659
  [EEClassPackedFields]: https://github.com/dotnet/coreclr/blob/4cf8a6b082d9bb1789facd996d8265d3908757b2/src/vm/packedfields.inl
  [SOS]: https://msdn.microsoft.com/en-us/library/bb190764(v=vs.110).aspx
  [SOSex]: http://www.stevestechspot.com/default.aspx
  [WinDbg]: http://www.windbg.org/
  [RTB]: https://en.wikipedia.org/wiki/Real-time_bidding
  [SO]: http://stackoverflow.com/questions/27176159/performance-type-derived-from-generic
  [RSDN]: http://rsdn.ru/
  [MicrosoftConnect]: https://connect.microsoft.com/VisualStudio/feedback/details/1041830/performance-type-derived-from-generic
  [github-issue]: https://github.com/dotnet/coreclr/issues/55
  [github-fix]: https://github.com/dotnet/coreclr/pull/618/files
  [github-explanation]: https://github.com/dotnet/coreclr/issues/55#issuecomment-89026823
  [wiki-arity]: https://en.wikipedia.org/wiki/Arity
