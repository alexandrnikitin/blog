---
layout: post
title: Access null pointer without exception
date: 2015-10-26
modified: 2015-10-26
excerpt: A story about a pattern with interest, conviction, indignation and compassion in the end.
tags: C++ CLR WTF Anti-patterns
comments: true
share: true
---

### Interest

I want to introduce you a pattern that allows you access null pointer without any exception. Excited? Me too!


### Conviction

Where can you apply it? In big codebases, of course, and .NET Core CLR fits really good. Why? To make them even more complicated! TODO!
Let's take a look at the Garbage Collector code in [gc.cpp][gc.cpp] which is more than 36K lines of code. Scroll down to the line number 34464 where you will find the following code:

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

Attentive reader will notice that if `MULTIPLE_HEAPS` isn't defined then the `hpt` pointer is null. But we access it a few lines latter.

So I raised [an issue on github][issue] with desire to know how it works. "This is by design," they pointed me, "The null pointer is never actually dereferenced." After some more digging I found that lovely pattern.

If we don't define `MULTIPLE_HEAPS` we define `PER_HEAP` as `static` in TODO

```cpp
#ifdef MULTIPLE_HEAPS
#define PER_HEAP
#else //MULTIPLE_HEAPS
#define PER_HEAP static
#endif // MULTIPLE_HEAPS
```

In that case `dynamic_data_table` field in `gc_heap` class becomes static: TODO

```cpp
PER_HEAP
dynamic_data dynamic_data_table [NUMBERGENERATIONS+1];
```

Taking into account that we inline the `dynamic_data_of` method:

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
