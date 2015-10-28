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

I want to introduce you a pattern that allows you access null pointer without any exception.

### Conviction

Where can you apply it? In big codebases like .NET Core CLR? Why? To make them even more complicated! of course.

A question that I couldn't keep in:

### Indignation

Guys, how do you work on that codebase?????

### Compassion

TBA

https://github.com/dotnet/coreclr/issues/1860

I started to review .NET Core CLR code recently and found the code:

If MULTIPLE_HEAPS isn't defined then hpt is null. But we access it a few lines latter.
So I raised an issue on github with desire to know how it works.
"This is by design... The null pointer is never actually dereferenced."
After some digging I found that pattern:
If we don't define `MULTIPLE_HEAPS` we define `PER_HEAP` as `static`

```cpp
#ifdef MULTIPLE_HEAPS
#define PER_HEAP
#else //MULTIPLE_HEAPS
#define PER_HEAP static
#endif // MULTIPLE_HEAPS
```

And in `gc_heap` class `dynamic_data_table` field becomes static:

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



I have extensive .NET background and that's far away from common. Abusing directives. I could understand if it would be linux or win. I consider it as ugly code. Unreadable and leads to bugs.
DRY?
Is it common in C++ world?
