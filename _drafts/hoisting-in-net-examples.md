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

This post contents a bunch of examples of the hoisting optimization with assembly listings. It's based on the theoretical part ["Hoisting in .NET Explained"][post-part1]

### Examples

The first example will be a classic one. We access the array length property and an element in a loop.

```csharp
public int Method(int[] arr)
{
    var sum = 0;
    for (var i = 0; i < arr.Length; i++)
    {
        sum += arr[0] + arr[i];
    }
    return sum;
}
```

```
00007ffa`a05304f0 4883ec28        sub     rsp,28h
00007ffa`a05304f4 33c0            xor     eax,eax
00007ffa`a05304f6 33c9            xor     ecx,ecx
00007ffa`a05304f8 448b4208        mov     r8d,dword ptr [rdx+8]
00007ffa`a05304fc 4585c0          test    r8d,r8d
00007ffa`a05304ff 7e1f            jle     00007ffa`a0530520
00007ffa`a0530501 4183f800        cmp     r8d,0
00007ffa`a0530505 761e            jbe     00007ffa`a0530525
00007ffa`a0530507 448b4a10        mov     r9d,dword ptr [rdx+10h]
00007ffa`a053050b 4103c1          add     eax,r9d
00007ffa`a053050e 4c63d1          movsxd  r10,ecx
00007ffa`a0530511 468b549210      mov     r10d,dword ptr [rdx+r10*4+10h]
00007ffa`a0530516 4103c2          add     eax,r10d
00007ffa`a0530519 ffc1            inc     ecx
00007ffa`a053051b 443bc1          cmp     r8d,ecx
00007ffa`a053051e 7feb            jg      00007ffa`a053050b
00007ffa`a0530520 4883c428        add     rsp,28h
00007ffa`a0530524 c3              ret
00007ffa`a0530525 e8de14a95f      call    clr!TranslateSecurityAttributes+0x900d4 (00007ffa`fffc1a08) (JitHelp: CORINFO_HELP_RNGCHKFAIL)
00007ffa`a053052a cc              int     3
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
