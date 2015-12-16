[MethodImpl(MethodImplOptions.NoInlining)]
public int Test(int[] arr)
{
    var sum = 0;

    for (var i = 0; i < arr.Length; i++)
    {
        try
        {
            sum += arr[1] + arr[i];
        }
        catch {}
    }

    return sum;
}



0:003> !U 00007fff23a95fc8
Normal JIT generated code
HoistingInDotNetExamples.HoistingTryCatchBlock.Test(Int32[])
Begin 00007fff23ba0700, size 97
*** WARNING: Unable to verify checksum for HoistingInDotNetExamples.exe

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingTryCatchBlock.cs @ 11:
00007fff`23ba0700 55              push    rbp
00007fff`23ba0701 4883ec30        sub     rsp,30h
00007fff`23ba0705 488d6c2430      lea     rbp,[rsp+30h]
00007fff`23ba070a 4889642420      mov     qword ptr [rsp+20h],rsp
00007fff`23ba070f 48895518        mov     qword ptr [rbp+18h],rdx
00007fff`23ba0713 33c0            xor     eax,eax
00007fff`23ba0715 8945fc          mov     dword ptr [rbp-4],eax

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingTryCatchBlock.cs @ 13:
00007fff`23ba0718 8945f8          mov     dword ptr [rbp-8],eax
00007fff`23ba071b 488b4518        mov     rax,qword ptr [rbp+18h]
00007fff`23ba071f 8b4008          mov     eax,dword ptr [rax+8]
00007fff`23ba0722 85c0            test    eax,eax
00007fff`23ba0724 7e49            jle     00007fff`23ba076f

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingTryCatchBlock.cs @ 17:
00007fff`23ba0726 8b55fc          mov     edx,dword ptr [rbp-4]
00007fff`23ba0729 83f801          cmp     eax,1
00007fff`23ba072c 7625            jbe     00007fff`23ba0753
00007fff`23ba072e 488b4d18        mov     rcx,qword ptr [rbp+18h]
00007fff`23ba0732 8b4914          mov     ecx,dword ptr [rcx+14h]
00007fff`23ba0735 03d1            add     edx,ecx
00007fff`23ba0737 8b4df8          mov     ecx,dword ptr [rbp-8]
00007fff`23ba073a 3bc8            cmp     ecx,eax
00007fff`23ba073c 7315            jae     00007fff`23ba0753
00007fff`23ba073e 488b4518        mov     rax,qword ptr [rbp+18h]
00007fff`23ba0742 8b4df8          mov     ecx,dword ptr [rbp-8]
00007fff`23ba0745 4863c9          movsxd  rcx,ecx
00007fff`23ba0748 8b448810        mov     eax,dword ptr [rax+rcx*4+10h]
00007fff`23ba074c 03c2            add     eax,edx
00007fff`23ba074e 8945fc          mov     dword ptr [rbp-4],eax
00007fff`23ba0751 eb06            jmp     00007fff`23ba0759
*** ERROR: Symbol file could not be found.  Defaulted to export symbols for C:\Windows\Microsoft.NET\Framework64\v4.0.30319\clr.dll -
00007fff`23ba0753 e8b012a95f      call    clr!TranslateSecurityAttributes+0x900d4 (00007fff`83631a08) (JitHelp: CORINFO_HELP_RNGCHKFAIL)
00007fff`23ba0758 cc              int     3

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingTryCatchBlock.cs @ 13:
00007fff`23ba0759 8b45f8          mov     eax,dword ptr [rbp-8]
00007fff`23ba075c ffc0            inc     eax
00007fff`23ba075e 8945f8          mov     dword ptr [rbp-8],eax
00007fff`23ba0761 488b4518        mov     rax,qword ptr [rbp+18h]
00007fff`23ba0765 8b4008          mov     eax,dword ptr [rax+8]
00007fff`23ba0768 8b55f8          mov     edx,dword ptr [rbp-8]
00007fff`23ba076b 3bc2            cmp     eax,edx
00007fff`23ba076d 7fb7            jg      00007fff`23ba0726

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingTryCatchBlock.cs @ 22:
00007fff`23ba076f 8b45fc          mov     eax,dword ptr [rbp-4]
00007fff`23ba0772 488d6500        lea     rsp,[rbp]
00007fff`23ba0776 5d              pop     rbp
00007fff`23ba0777 c3              ret

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingTryCatchBlock.cs @ 11:
00007fff`23ba0778 55              push    rbp
00007fff`23ba0779 4883ec30        sub     rsp,30h
00007fff`23ba077d 488b6920        mov     rbp,qword ptr [rcx+20h]
00007fff`23ba0781 48896c2420      mov     qword ptr [rsp+20h],rbp
00007fff`23ba0786 488d6d30        lea     rbp,[rbp+30h]
00007fff`23ba078a 488d05c8ffffff  lea     rax,[00007fff`23ba0759]

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingTryCatchBlock.cs @ 22:
00007fff`23ba0791 4883c430        add     rsp,30h
00007fff`23ba0795 5d              pop     rbp
00007fff`23ba0796 c3              ret














[MethodImpl(MethodImplOptions.NoInlining)]
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


0:005> !U 00007fff23a65fc8
Normal JIT generated code
HoistingInDotNetExamples.HoistingTryCatchBlock.Test(Int32)
Begin 00007fff23b706f0, size 5a
*** WARNING: Unable to verify checksum for HoistingInDotNetExamples.exe

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingTryCatchBlock.cs @ 10:
00007fff`23b706f0 55              push    rbp
00007fff`23b706f1 4883ec10        sub     rsp,10h
00007fff`23b706f5 488d6c2410      lea     rbp,[rsp+10h]
00007fff`23b706fa 48892424        mov     qword ptr [rsp],rsp
00007fff`23b706fe 895518          mov     dword ptr [rbp+18h],edx
00007fff`23b70701 33c0            xor     eax,eax
00007fff`23b70703 8945fc          mov     dword ptr [rbp-4],eax

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingTryCatchBlock.cs @ 12:
00007fff`23b70706 8945f8          mov     dword ptr [rbp-8],eax

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingTryCatchBlock.cs @ 16:
00007fff`23b70709 8b45fc          mov     eax,dword ptr [rbp-4]
00007fff`23b7070c 8b5518          mov     edx,dword ptr [rbp+18h]
00007fff`23b7070f 03c2            add     eax,edx
00007fff`23b70711 8945fc          mov     dword ptr [rbp-4],eax

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingTryCatchBlock.cs @ 12:
00007fff`23b70714 8b45f8          mov     eax,dword ptr [rbp-8]
00007fff`23b70717 ffc0            inc     eax
00007fff`23b70719 8945f8          mov     dword ptr [rbp-8],eax
00007fff`23b7071c 8b45f8          mov     eax,dword ptr [rbp-8]
00007fff`23b7071f 83f80b          cmp     eax,0Bh
00007fff`23b70722 7ce5            jl      00007fff`23b70709

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingTryCatchBlock.cs @ 21:
00007fff`23b70724 8b45fc          mov     eax,dword ptr [rbp-4]
00007fff`23b70727 488d6500        lea     rsp,[rbp]
00007fff`23b7072b 5d              pop     rbp
00007fff`23b7072c c3              ret

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingTryCatchBlock.cs @ 10:
00007fff`23b7072d 55              push    rbp
00007fff`23b7072e 4883ec10        sub     rsp,10h
00007fff`23b70732 488b29          mov     rbp,qword ptr [rcx]
00007fff`23b70735 48892c24        mov     qword ptr [rsp],rbp
00007fff`23b70739 488d6d10        lea     rbp,[rbp+10h]
00007fff`23b7073d 488d05d0ffffff  lea     rax,[00007fff`23b70714]

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingTryCatchBlock.cs @ 21:
00007fff`23b70744 4883c410        add     rsp,10h
00007fff`23b70748 5d              pop     rbp
00007fff`23b70749 c3              ret
