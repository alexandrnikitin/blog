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

Isn't hoisted. Multithreading, backward compatibility. TODO link to discussion.

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

#### Try catch block

Isn't hoisted

```csharp
public int Test(int a)
{
    var sum = 0;

    for (var i = 0; i < 11; i++)
    {
        try
        {
            sum += a;
        }
        catch { }
    }

    return sum;
}
```

```
00007fff`23b706f0 55              push    rbp
00007fff`23b706f1 4883ec10        sub     rsp,10h
00007fff`23b706f5 488d6c2410      lea     rbp,[rsp+10h]
00007fff`23b706fa 48892424        mov     qword ptr [rsp],rsp
00007fff`23b706fe 895518          mov     dword ptr [rbp+18h],edx
00007fff`23b70701 33c0            xor     eax,eax
00007fff`23b70703 8945fc          mov     dword ptr [rbp-4],eax
00007fff`23b70706 8945f8          mov     dword ptr [rbp-8],eax
00007fff`23b70709 8b45fc          mov     eax,dword ptr [rbp-4]
00007fff`23b7070c 8b5518          mov     edx,dword ptr [rbp+18h]
00007fff`23b7070f 03c2            add     eax,edx
00007fff`23b70711 8945fc          mov     dword ptr [rbp-4],eax
00007fff`23b70714 8b45f8          mov     eax,dword ptr [rbp-8]
00007fff`23b70717 ffc0            inc     eax
00007fff`23b70719 8945f8          mov     dword ptr [rbp-8],eax
00007fff`23b7071c 8b45f8          mov     eax,dword ptr [rbp-8]
00007fff`23b7071f 83f80b          cmp     eax,0Bh
00007fff`23b70722 7ce5            jl      00007fff`23b70709
00007fff`23b70724 8b45fc          mov     eax,dword ptr [rbp-4]
00007fff`23b70727 488d6500        lea     rsp,[rbp]
00007fff`23b7072b 5d              pop     rbp
00007fff`23b7072c c3              ret
00007fff`23b7072d 55              push    rbp
00007fff`23b7072e 4883ec10        sub     rsp,10h
00007fff`23b70732 488b29          mov     rbp,qword ptr [rcx]
00007fff`23b70735 48892c24        mov     qword ptr [rsp],rbp
00007fff`23b70739 488d6d10        lea     rbp,[rbp+10h]
00007fff`23b7073d 488d05d0ffffff  lea     rax,[00007fff`23b70714]
00007fff`23b70744 4883c410        add     rsp,10h
00007fff`23b70748 5d              pop     rbp
00007fff`23b70749 c3              ret
```

#### Field

```csharp
public class HoistingField
{
    public int a = 123;

    [MethodImpl(MethodImplOptions.NoInlining)]
    public int Field()
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
00007fff`23b907b0 33c0            xor     eax,eax
00007fff`23b907b2 33d2            xor     edx,edx
00007fff`23b907b4 8b4908          mov     ecx,dword ptr [rcx+8]
00007fff`23b907b7 03c1            add     eax,ecx
00007fff`23b907b9 ffc2            inc     edx
00007fff`23b907bb 83fa0b          cmp     edx,0Bh
00007fff`23b907be 7cf7            jl      00007fff`23b907b7
00007fff`23b907c0 c3              ret
```

#### Arg

Hoisted, we don't read from stack at each iteration.

TODO combine local var, field and arg into one example.

```csharp
public int Arg(int a)
{
    var sum = 0;

    for (var i = 0; i < 11; i++)
    {
        sum += a;
    }

    return sum;
}
```

```
00007fff`23b907e0 33c0            xor     eax,eax
00007fff`23b907e2 33c9            xor     ecx,ecx
00007fff`23b907e4 03c2            add     eax,edx
00007fff`23b907e6 ffc1            inc     ecx
00007fff`23b907e8 83f90b          cmp     ecx,0Bh
00007fff`23b907eb 7cf7            jl      00007fff`23b907e4
00007fff`23b907ed c3              ret
```  

.

#### Many exits in a loop

Not hoisted, read from main memory, JIT optimizes only the first entry block in that case.

```csharp
public class HoistingManyExits
{
    public int a = 123;

    public int ManyExits()
    {
        var sum = 0;

        for (var i = 0; i < 11; i++)
        {
            if (sum > 123) return sum;
            sum += a;
        }

        return sum;
    }
}
```

```
00007fff`23ba0810 33c0            xor     eax,eax
00007fff`23ba0812 33d2            xor     edx,edx
00007fff`23ba0814 83f87b          cmp     eax,7Bh
00007fff`23ba0817 7e01            jle     00007fff`23ba081a
00007fff`23ba0819 c3              ret
00007fff`23ba081a 448b4108        mov     r8d,dword ptr [rcx+8]
00007fff`23ba081e 4103c0          add     eax,r8d
00007fff`23ba0821 ffc2            inc     edx
00007fff`23ba0823 83fa0b          cmp     edx,0Bh
00007fff`23ba0826 7cec            jl      00007fff`23ba0814
00007fff`23ba0828 c3              ret
```

.

#### Many vars

Not hoisted, read from main memory, too less registers

```csharp
public class HoistingManyVars
{
    public int a = 123;

    public int ManyVars(int x1, int x2, int x3, int x4, int x5, int x6, int x7,
        int x8, int x9, int x10)
    {
        var sum = 0;

        for (var i = 0; i < 11; i++)
        {
            sum += x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + a;
        }

        return sum;
    }
}
```

```
00007fff`23b808b0 4157            push    r15
00007fff`23b808b2 4156            push    r14
00007fff`23b808b4 4154            push    r12
00007fff`23b808b6 57              push    rdi
00007fff`23b808b7 56              push    rsi
00007fff`23b808b8 55              push    rbp
00007fff`23b808b9 53              push    rbx
00007fff`23b808ba 8b442460        mov     eax,dword ptr [rsp+60h]
00007fff`23b808be 448b542468      mov     r10d,dword ptr [rsp+68h]
00007fff`23b808c3 448b5c2470      mov     r11d,dword ptr [rsp+70h]
00007fff`23b808c8 8b742478        mov     esi,dword ptr [rsp+78h]
00007fff`23b808cc 8bbc2480000000  mov     edi,dword ptr [rsp+80h]
00007fff`23b808d3 8b9c2488000000  mov     ebx,dword ptr [rsp+88h]
00007fff`23b808da 8bac2490000000  mov     ebp,dword ptr [rsp+90h]
00007fff`23b808e1 4533f6          xor     r14d,r14d
00007fff`23b808e4 4533ff          xor     r15d,r15d
00007fff`23b808e7 4403f2          add     r14d,edx
00007fff`23b808ea 4503f0          add     r14d,r8d
00007fff`23b808ed 4503f1          add     r14d,r9d
00007fff`23b808f0 4403f0          add     r14d,eax
00007fff`23b808f3 4503f2          add     r14d,r10d
00007fff`23b808f6 4503f3          add     r14d,r11d
00007fff`23b808f9 4403f6          add     r14d,esi
00007fff`23b808fc 4403f7          add     r14d,edi
00007fff`23b808ff 4403f3          add     r14d,ebx
00007fff`23b80902 4403f5          add     r14d,ebp
00007fff`23b80905 448b6108        mov     r12d,dword ptr [rcx+8]
00007fff`23b80909 4503f4          add     r14d,r12d
00007fff`23b8090c 41ffc7          inc     r15d
00007fff`23b8090f 4183ff0b        cmp     r15d,0Bh
00007fff`23b80913 7cd2            jl      00007fff`23b808e7
00007fff`23b80915 418bc6          mov     eax,r14d
00007fff`23b80918 5b              pop     rbx
00007fff`23b80919 5d              pop     rbp
00007fff`23b8091a 5e              pop     rsi
00007fff`23b8091b 5f              pop     rdi
00007fff`23b8091c 415c            pop     r12
00007fff`23b8091e 415e            pop     r14
00007fff`23b80920 415f            pop     r15
00007fff`23b80922 c3              ret
```

#### Math & double

Here I wanted to check `double` type and Math functions
Math.Abs() isn't hoisted. Why?




```csharp
public double Run(int a)
{
    var sum = 0d;

    for (var i = 0; i < 11; i++)
    {
        sum += Math.Abs(a) + Math.Pow(2, 2);
    }

    return sum;
}
```

```
00007fff`23b80970 57              push    rdi
00007fff`23b80971 56              push    rsi
00007fff`23b80972 53              push    rbx
00007fff`23b80973 4883ec30        sub     rsp,30h
00007fff`23b80977 c4e17829742420  vmovaps xmmword ptr [rsp+20h],xmm6
00007fff`23b8097e c5f877          vzeroupper
00007fff`23b80981 8bf2            mov     esi,edx
00007fff`23b80983 c4e14957f6      vxorpd  xmm6,xmm6,xmm6
00007fff`23b80988 33ff            xor     edi,edi
00007fff`23b8098a 85f6            test    esi,esi
00007fff`23b8098c 7c04            jl      00007fff`23b80992
00007fff`23b8098e 8bde            mov     ebx,esi
00007fff`23b80990 eb09            jmp     00007fff`23b8099b
00007fff`23b80992 8bce            mov     ecx,esi
00007fff`23b80994 e8a7c0545e      call    mscorlib_ni+0x45ca40 (00007fff`820cca40) (System.Math.AbsHelper(Int32), mdToken: 0000000006000f17)
00007fff`23b80999 8bd8            mov     ebx,eax
00007fff`23b8099b c4e17b100544000000 vmovsd xmm0,qword ptr [00007fff`23b809e8]
00007fff`23b809a4 c4e17b100d43000000 vmovsd xmm1,qword ptr [00007fff`23b809f0]
00007fff`23b809ad e86e45d15f      call    clr!NGenCreateNGenWorker+0xa7880 (00007fff`83894f20) (System.Math.Pow(Double, Double), mdToken: 0000000006000f10)
00007fff`23b809b2 c4e17057c9      vxorps  xmm1,xmm1,xmm1
00007fff`23b809b7 c4e1732acb      vcvtsi2sd xmm1,xmm1,ebx
00007fff`23b809bc c4e17b58c1      vaddsd  xmm0,xmm0,xmm1
00007fff`23b809c1 c4e14b58f0      vaddsd  xmm6,xmm6,xmm0
00007fff`23b809c6 ffc7            inc     edi
00007fff`23b809c8 83ff0b          cmp     edi,0Bh
00007fff`23b809cb 7cbd            jl      00007fff`23b8098a
00007fff`23b809cd c4e17828c6      vmovaps xmm0,xmm6
00007fff`23b809d2 c5f877          vzeroupper
00007fff`23b809d5 c4e17828742420  vmovaps xmm6,xmmword ptr [rsp+20h]
00007fff`23b809dc 4883c430        add     rsp,30h
00007fff`23b809e0 5b              pop     rbx
00007fff`23b809e1 5e              pop     rsi
00007fff`23b809e2 5f              pop     rdi
00007fff`23b809e3 c3              ret
```

#### Not do while loop

Isn't hoisted. JIT isn't sure that the loop will be executed. JIT tries to optimize the path that definitely will be executed so that doesn't perform unnecessary read from the main memory.

```csharp
public class HoistingNotDoWhile
{
    public int a = 123;

    public int Run()
    {
        var sum = 0;
        for (; ShouldContinue(); )
        {
            sum += a;
        }
        return sum;
    }
}
```

```
00007fff`23ba0a40 57              push    rdi
00007fff`23ba0a41 56              push    rsi
00007fff`23ba0a42 4883ec28        sub     rsp,28h
00007fff`23ba0a46 488bf1          mov     rsi,rcx
00007fff`23ba0a49 33ff            xor     edi,edi
00007fff`23ba0a4b 488bce          mov     rcx,rsi
00007fff`23ba0a4e e835f8ffff      call    00007fff`23ba0288 (HoistingInDotNetExamples.HoistingNotDoWhile.ShouldContinue(), mdToken: 000000000600000a)
00007fff`23ba0a53 84c0            test    al,al
00007fff`23ba0a55 7411            je      00007fff`23ba0a68
00007fff`23ba0a57 8b4e08          mov     ecx,dword ptr [rsi+8]
00007fff`23ba0a5a 03f9            add     edi,ecx
00007fff`23ba0a5c 488bce          mov     rcx,rsi
00007fff`23ba0a5f e824f8ffff      call    00007fff`23ba0288 (HoistingInDotNetExamples.HoistingNotDoWhile.ShouldContinue(), mdToken: 000000000600000a)
00007fff`23ba0a64 84c0            test    al,al
00007fff`23ba0a66 75ef            jne     00007fff`23ba0a57
00007fff`23ba0a68 8bc7            mov     eax,edi
00007fff`23ba0a6a 4883c428        add     rsp,28h
00007fff`23ba0a6e 5e              pop     rsi
00007fff`23ba0a6f 5f              pop     rdi
00007fff`23ba0a70 c3              ret
```

structs?

### Epilogue

We've taken a close look at some examples of the JIT hoisting optimization.
Examples can be found on github TODO Please, create a pull request if you want to add an interesting.


  [post-part1]: https://alexandrnikitin.github.io/blog/hoisting-in-net-explained/
  [post-generics]: https://alexandrnikitin.github.io/blog/dotnet-generics-under-the-hood/
