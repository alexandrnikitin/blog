---
layout: post
title: Access null pointer without exception
date: 2015-10-26
modified: 2015-10-26
excerpt: A story about a pattern with interest, conviction, indignation and compassion in the end.
tags: [C++, CLR, WTF, Anti-patterns]
comments: true
share: true
---

_Note: Uneducated view of a .NET developer on the quintessence of computer science. :blush:_

### Interest

I want to introduce you a pattern that allows you to access a null pointer without any exception. Excited? Me too!

Imaging you have a class and some data that you want to access regardless of a pointer. For the sake of the concocted example and to present the pattern... :grimacing: well, you need to mark the field and the "getter" method as `static`, in addition mark the "getter" method with `inline` keyword.

```cpp
class MyConcoctedClass
{
	static int get_data();
	static int data;
};

int MyConcoctedClass::data;

inline int MyConcoctedClass::get_data()
{
	return data;
}
```

Voila! You can access the data without any errors:

```cpp
int main()
{
	MyConcoctedClass* myClass = 0;
	myClass->get_data;
}
```

### Conviction

Where can you apply it? In big codebases, of course, and .NET Core CLR fits really well. Why? To make it even more complicated! :japanese_ogre:
Let's take a look at the Garbage Collector code in [gc.cpp][gc.cpp] which is more than 36K lines of code, 36K LOC of the pure quintessence of computer science! Scroll down to the line number 34463, where you will find the following code:

```cpp
...
size_t
GCHeap::GarbageCollectGeneration (unsigned int gen, gc_reason reason)
{
    dprintf (2, ("triggered a GC!"));

#ifdef MULTIPLE_HEAPS
    gc_heap* hpt = gc_heap::g_heaps[0];
#else
    gc_heap* hpt = 0;
#endif //MULTIPLE_HEAPS
    Thread* current_thread = GetThread();
    BOOL cooperative_mode = TRUE;
    dynamic_data* dd = hpt->dynamic_data_of (gen);
...
```

Attentive reader will notice that if `MULTIPLE_HEAPS` isn't defined then the `hpt` pointer is null. But we access it a few lines below.

So I raised [an issue on github][issue] with desire to know how it works. "This is by design," they answered, "The null pointer is never actually dereferenced." After some more digging I found that lovely pattern.

If we don't define `MULTIPLE_HEAPS` we define `PER_HEAP` as `static` in [gcimpl.h][gcimpl.h]

```cpp
#ifdef MULTIPLE_HEAPS
#define PER_HEAP
#else //MULTIPLE_HEAPS
#define PER_HEAP static
#endif // MULTIPLE_HEAPS
```

In that case `dynamic_data_table` field in [`gc_heap` class][gcpriv.h-static] becomes static:

```cpp
PER_HEAP
dynamic_data dynamic_data_table [NUMBERGENERATIONS+1];
```

Taking into account that we inline [the `dynamic_data_of` method][gcpriv.h-inline]:

```cpp
inline
dynamic_data* gc_heap::dynamic_data_of (int gen_number)
{
    return &dynamic_data_table [ gen_number ];
}
```

everything works...

:see_no_evil:

A question that I couldn't keep in...

### Indignation

Guys, how do you work on that codebase?????

I have extensive .NET background and that's far away from common. Abusing directives. I could understand if it would be linux or win. I consider it as ugly code. Unreadable and leads to bugs.
DRY?
Is it common in C++ world?

### Compassion

TBA

  [gc.cpp]: https://raw.githubusercontent.com/dotnet/coreclr/release/1.0.0-rc1/src/gc/gc.cpp
  [issue]: https://github.com/dotnet/coreclr/issues/1860
  [gcimpl.h]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/gc/gcimpl.h#L22
  [gcpriv.h-static]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/gc/gcpriv.h#L3431
  [gcpriv.h-inline]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/gc/gcpriv.h#L4276
