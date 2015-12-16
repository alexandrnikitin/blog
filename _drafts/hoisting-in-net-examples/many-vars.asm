public class HoistingManyVars
{
    public int a = 123;

    public int ManyVars(
        int x1,
        int x2,
        int x3,
        int x4,
        int x5,
        int x6,
        int x7,
        int x8,
        int x9,
        int x10)
    {
        var sum = 0;

        for (var i = 0; i < 11; i++)
        {
            sum += x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + a;
        }

        return sum;
    }
}



0:003> !U 00007fff23a762d8
Normal JIT generated code
HoistingInDotNetExamples.HoistingManyVars.ManyVars(Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32)
Begin 00007fff23b808b0, size 73
*** WARNING: Unable to verify checksum for HoistingInDotNetExamples.exe

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingManyVars.cs @ 22:
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

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingManyVars.cs @ 24:
00007fff`23b808e4 4533ff          xor     r15d,r15d

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingManyVars.cs @ 26:
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

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingManyVars.cs @ 24:
00007fff`23b8090c 41ffc7          inc     r15d
00007fff`23b8090f 4183ff0b        cmp     r15d,0Bh
00007fff`23b80913 7cd2            jl      00007fff`23b808e7

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingManyVars.cs @ 29:
00007fff`23b80915 418bc6          mov     eax,r14d
00007fff`23b80918 5b              pop     rbx
00007fff`23b80919 5d              pop     rbp
00007fff`23b8091a 5e              pop     rsi
00007fff`23b8091b 5f              pop     rdi
00007fff`23b8091c 415c            pop     r12
00007fff`23b8091e 415e            pop     r14
00007fff`23b80920 415f            pop     r15
00007fff`23b80922 c3              ret
