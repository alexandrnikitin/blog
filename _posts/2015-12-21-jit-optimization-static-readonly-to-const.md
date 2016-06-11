---
layout: single
title: "JIT optimization: static readonly to const"
date: 2015-12-21T20:07:12+02:00
modified:
categories: [TIL, .NET, CLR, JIT, Optimizations]
excerpt: "TIL: JIT can treat static readonly fields as constants"
tags: [TIL, .NET, CLR, JIT, Optimizations]
comments: true
share: true
---

Today I learned that JIT can optimize static readonly fields of the primitive types. JIT can treat those static readonly fields as constants while compiling methods. Those fields can be in any class, not necessarily in the compiling one.

### Example

```csharp
public class MyExampleClass
{
    public static readonly bool IsLoggingEnabled = false; // e.g. from config

    public void Run()
    {
        if (IsLoggingEnabled)
            Console.WriteLine("This is a log entry");

        // some logic below
        var sum = 0;
        for (int i = 0; i < 11; i++)
        {
            sum += i;
        }
    }
}
```

The `Run()` method will be compiled to the following assembly code:

```
00007ffa`4fa00540 33c0            xor     eax,eax
00007ffa`4fa00542 33d2            xor     edx,edx
00007ffa`4fa00544 03c2            add     eax,edx
00007ffa`4fa00546 ffc2            inc     edx
00007ffa`4fa00548 83fa0b          cmp     edx,0Bh
00007ffa`4fa0054b 7cf7            jl      00007ffa`4fa00544
00007ffa`4fa0054d c3              ret
```

As you can see there's only `for` loop left. The `if (IsLoggingEnabled)` condition check and its body are completely eliminated. I was glad to find out that. One more point to JIT compilers. :relaxed:
