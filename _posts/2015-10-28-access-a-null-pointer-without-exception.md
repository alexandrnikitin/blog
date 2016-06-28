---
layout: single
title: Access a null pointer without exception
date: 2015-10-28
modified: 2015-11-30 16:56:00
excerpt: A story about a pattern, with interest, conviction, rejection and compassion in the end.
categories: [.NET]
tags: [.NET, C++, CLR, WTF, Sarcasm, Anti-patterns]
comments: true
share: true
---

_Note: Uneducated view of a .NET developer on the quintessence of computer science. :blush:_


### Interest

I want to introduce you a pattern that allows you to access a null pointer without any exception. Excited? Me too!

Imaging, you have a class and some data that you want to access regardless of a pointer. For the sake of the concocted example and to present the pattern... :grimacing: well, you need to mark the field and the "getter" method as `static`, that's it.

```cpp
class MyConcoctedClass
{
	static int get_data();
	static int data;
};

int MyConcoctedClass::data;

int MyConcoctedClass::get_data()
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

Where can you apply it? In complex codebases, of course, and .NET Core CLR fits really well. Why? DRY, optimization, you name. _(To make it even more complicated!)_ :japanese_ogre:

Let's take a look at the Garbage Collection code in [gc.cpp][gc.cpp] which is more than 36K lines of code, 36K LOC of the pure quintessence of computer science! Scroll down to the line number 34463, where you will find the following code:

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

The attentive reader will notice that if `MULTIPLE_HEAPS` isn't defined then the `hpt` pointer is null. But we access it a few lines below.

So I raised [an issue on github][issue] with desire to know how it works. "This is by design," they answered, "The null pointer is never actually dereferenced." After some more digging, I found the lovely pattern I described above.

If we don't define `MULTIPLE_HEAPS` we define `PER_HEAP` as `static` in [gcimpl.h][gcimpl.h]

```cpp
#ifdef MULTIPLE_HEAPS
#define PER_HEAP
#else //MULTIPLE_HEAPS
#define PER_HEAP static
#endif // MULTIPLE_HEAPS
```

In that case [the `dynamic_data_table` field][gcpriv.h-static] and [the `dynamic_data_of` method][gcpriv.h-static-method] in `gc_heap` class become static:

```cpp
PER_HEAP
dynamic_data dynamic_data_table [NUMBERGENERATIONS+1];
...
PER_HEAP
dynamic_data* dynamic_data_of (int gen_number);
```

and everything works...

:see_no_evil:

A question arose that I cannot keep in:

### Rejection

> Guys, how do you work on that codebase?????

I imagined the Garbage Collection as the edge of technologies, the masterpiece. I wanted to admire the code and learn from it. Instead I drown in a swamp of directives. I can understand if it would be "linux or windows" case. "DRY!" you say, but it's better to repeat, "Optimizations!" you would object, but I won't believe. I have strong .NET background and that's far away from common. I consider it as ugly code which is unreadable and leads only to bugs.

A colleague of mine once said, "Maybe you don't know how to read that code?!" Maybe I don't, so that I keep learning.

### Compassion

TBA :worried:

  [gc.cpp]: https://raw.githubusercontent.com/dotnet/coreclr/release/1.0.0-rc1/src/gc/gc.cpp
  [issue]: https://github.com/dotnet/coreclr/issues/1860
  [gcimpl.h]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/gc/gcimpl.h#L22
  [gcpriv.h-static]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/gc/gcpriv.h#L3431
  [gcpriv.h-static-method]: https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/gc/gcpriv.h#L1895
