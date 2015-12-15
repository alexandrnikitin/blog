---
layout: post
title: "Hoisting in .NET Examples"
date: 2015-11-26T01:07:33+02:00
modified:
categories: [.NET, CLR, JIT, Optimizations]
excerpt:
tags: [.NET, CLR, JIT, Optimizations]
comments: true
share: true
---

:warning: This post contains a bunch of examples of the JIT hoisting optimization with assembly listings. It's based on the theoretical part ["Hoisting in .NET Explained"][post-part1]

### Preamble: How to get assembly code

Windbg

Library?

BenchmarkDotNet

### Examples

#### Array's length and element

The first example will be a classic one. We access the array's length property and an element in a loop.

```csharp
public int Test(int[] arr)
{
    var sum = 0;
    for (var i = 0; i < arr.Length; i++)
    {
        sum += arr[1] + arr[i];
    }
    return sum;
}
```

```
00007fff`23bb0580 4883ec28        sub     rsp,28h
00007fff`23bb0584 33c0            xor     eax,eax
00007fff`23bb0586 33c9            xor     ecx,ecx
00007fff`23bb0588 448b4208        mov     r8d,dword ptr [rdx+8]
00007fff`23bb058c 4585c0          test    r8d,r8d
00007fff`23bb058f 7e1f            jle     00007fff`23bb05b0
00007fff`23bb0591 4183f801        cmp     r8d,1
00007fff`23bb0595 761e            jbe     00007fff`23bb05b5
00007fff`23bb0597 448b4a14        mov     r9d,dword ptr [rdx+14h]
00007fff`23bb059b 4103c1          add     eax,r9d
00007fff`23bb059e 4c63d1          movsxd  r10,ecx
00007fff`23bb05a1 468b549210      mov     r10d,dword ptr [rdx+r10*4+10h]
00007fff`23bb05a6 4103c2          add     eax,r10d
00007fff`23bb05a9 ffc1            inc     ecx
00007fff`23bb05ab 443bc1          cmp     r8d,ecx
00007fff`23bb05ae 7feb            jg      00007fff`23bb059b
00007fff`23bb05b0 4883c428        add     rsp,28h
00007fff`23bb05b4 c3              ret
00007fff`23bb05b5 e84e14a85f      call    clr!TranslateSecurityAttributes+0x900d4 (00007fff`83631a08) (JitHelp: CORINFO_HELP_RNGCHKFAIL)
00007fff`23bb05ba cc              int     3
```


The fun part.

Hoisted:
array length & element
jit helper



Not hoisted:
static var


try block
local var
many vars


not do while loop
structs?
many exits


  [post-part1]: https://alexandrnikitin.github.io/blog/hoisting-in-net-explained/
