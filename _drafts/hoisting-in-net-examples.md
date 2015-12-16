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


#### JIT helper method call

Actually, this example attracted my attention to the hoisting optimization. JIT can hoist calls to internal helper methods. This example is based on my post [".NET Generics under the hood"][post-generics] Take a look if you want to get familiar with the topic.

```csharp
public void JitHelper(List<T> list)
{
    for (var i = 0; i < 11; i++)
    {
        if (list.Any())
        {
            return;
        }
    }
}
```

```
00007ffa`a0530650 57              push    rdi
00007ffa`a0530651 56              push    rsi
00007ffa`a0530652 55              push    rbp
00007ffa`a0530653 53              push    rbx
00007ffa`a0530654 4883ec28        sub     rsp,28h
00007ffa`a0530658 48894c2420      mov     qword ptr [rsp+20h],rcx
00007ffa`a053065d 488bf9          mov     rdi,rcx
00007ffa`a0530660 488bf2          mov     rsi,rdx
00007ffa`a0530663 33db            xor     ebx,ebx
00007ffa`a0530665 488b2f          mov     rbp,qword ptr [rdi]
00007ffa`a0530668 488bcd          mov     rcx,rbp
00007ffa`a053066b 488b5130        mov     rdx,qword ptr [rcx+30h]
00007ffa`a053066f 488b12          mov     rdx,qword ptr [rdx]
00007ffa`a0530672 488b4208        mov     rax,qword ptr [rdx+8]
00007ffa`a0530676 4885c0          test    rax,rax
00007ffa`a0530679 750f            jne     00007ffa`a053068a
00007ffa`a053067b 48ba281757a0fa7f0000 mov rdx,7FFAA0571728h
00007ffa`a0530685 e8269d6b5f      call    clr!LogHelp_LogAssert+0x3e810 (00007ffa`ffbea3b0) (JitHelp: CORINFO_HELP_RUNTIMEHANDLE_CLASS)
00007ffa`a053068a 488bc8          mov     rcx,rax
00007ffa`a053068d 488bd6          mov     rdx,rsi
00007ffa`a0530690 e81b0bd85c      call    System_Core_ni+0x2f11b0 (00007ffa`fd2b11b0) (System.Linq.Enumerable.Any[[System.__Canon, mscorlib]](System.Collections.Generic.IEnumerable`1<System.__Canon>), mdToken: 0000000006000748)
00007ffa`a0530695 84c0            test    al,al
00007ffa`a0530697 7409            je      00007ffa`a05306a2
00007ffa`a0530699 4883c428        add     rsp,28h
00007ffa`a053069d 5b              pop     rbx
00007ffa`a053069e 5d              pop     rbp
00007ffa`a053069f 5e              pop     rsi
00007ffa`a05306a0 5f              pop     rdi
00007ffa`a05306a1 c3              ret
00007ffa`a05306a2 ffc3            inc     ebx
00007ffa`a05306a4 83fb0b          cmp     ebx,0Bh
00007ffa`a05306a7 7cbf            jl      00007ffa`a0530668
00007ffa`a05306a9 4883c428        add     rsp,28h
00007ffa`a05306ad 5b              pop     rbx
00007ffa`a05306ae 5d              pop     rbp
00007ffa`a05306af 5e              pop     rsi
00007ffa`a05306b0 5f              pop     rdi
00007ffa`a05306b1 c3              ret
```

#### Static field

Isn't hoisted. Multithreading, backward compatibility.

```csharp
public class HoistingStatic
{
    public static int a = 123;

    public int Static()
    {
        var sum = 0;
        for (var i = 0; i < 11; i++)
        {
            sum += a;
        }
        return sum;
    }
}
```

```
00007ffa`a0520590 33c0            xor     eax,eax
00007ffa`a0520592 33d2            xor     edx,edx
00007ffa`a0520594 8b0dc241efff    mov     ecx,dword ptr [00007ffa`a041475c]
00007ffa`a052059a 03c1            add     eax,ecx
00007ffa`a052059c ffc2            inc     edx
00007ffa`a052059e 83fa0b          cmp     edx,0Bh
00007ffa`a05205a1 7cf1            jl      00007ffa`a0520594
00007ffa`a05205a3 c3              ret
```

Hoisted:



Not hoisted:


try block
local var
many vars


not do while loop
structs?
many exits


  [post-part1]: https://alexandrnikitin.github.io/blog/hoisting-in-net-explained/
  [post-generics]: https://alexandrnikitin.github.io/blog/dotnet-generics-under-the-hood/
