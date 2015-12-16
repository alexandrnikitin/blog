
        public class BaseClass<T>
        {
            private List<T> _list = new List<T>();

            public void Run()
            {
                for (var i = 0; i < 11; i++)
                    if (list.Any())
                        return;
            }
        }



0:000> !U eip
Normal JIT generated code
PerformanceProblem.BaseClass`1[[System.__Canon, mscorlib]].Run()
Begin 00007ffc8c2e0b00, size 50

C:\temp\trace\ConsoleApplication1\ConsoleApplication1\Program.cs @ 44:
00007ffc`8c2e0b00 57              push    rdi
00007ffc`8c2e0b01 56              push    rsi
00007ffc`8c2e0b02 53              push    rbx
00007ffc`8c2e0b03 4883ec30        sub     rsp,30h
00007ffc`8c2e0b07 48894c2428      mov     qword ptr [rsp+28h],rcx
00007ffc`8c2e0b0c 488bf1          mov     rsi,rcx
>>> 00007ffc`8c2e0b0f 33ff            xor     edi,edi
00007ffc`8c2e0b11 488b0e          mov     rcx,qword ptr [rsi]
00007ffc`8c2e0b14 48ba281c328cfc7f0000 mov rdx,7FFC8C321C28h
00007ffc`8c2e0b1e e80d90685f      call    clr!DllCanUnloadNowInternal+0x32c90 (00007ffc`eb969b30) (JitHelp: CORINFO_HELP_RUNTIMEHANDLE_CLASS)
00007ffc`8c2e0b23 488bd8          mov     rbx,rax

C:\temp\trace\ConsoleApplication1\ConsoleApplication1\Program.cs @ 46:
00007ffc`8c2e0b26 488bcb          mov     rcx,rbx
00007ffc`8c2e0b29 488b5608        mov     rdx,qword ptr [rsi+8]
00007ffc`8c2e0b2d e80edacc5c      call    System_Core_ni+0x2be540 (00007ffc`e8fae540) (System.Linq.Enumerable.Any[[System.__Canon, mscorlib]](System.Collections.Generic.IEnumerable`1<System.__Canon>), mdToken: 0000000006000732)
00007ffc`8c2e0b32 84c0            test    al,al
00007ffc`8c2e0b34 7408            je      00007ffc`8c2e0b3e

C:\temp\trace\ConsoleApplication1\ConsoleApplication1\Program.cs @ 55:
00007ffc`8c2e0b36 4883c430        add     rsp,30h
00007ffc`8c2e0b3a 5b              pop     rbx
00007ffc`8c2e0b3b 5e              pop     rsi
00007ffc`8c2e0b3c 5f              pop     rdi
00007ffc`8c2e0b3d c3              ret

C:\temp\trace\ConsoleApplication1\ConsoleApplication1\Program.cs @ 44:
00007ffc`8c2e0b3e ffc7            inc     edi
00007ffc`8c2e0b40 81ff00127a00    cmp     edi,7A1200h
00007ffc`8c2e0b46 7cde            jl      00007ffc`8c2e0b26

C:\temp\trace\ConsoleApplication1\ConsoleApplication1\Program.cs @ 55:
00007ffc`8c2e0b48 4883c430        add     rsp,30h
00007ffc`8c2e0b4c 5b              pop     rbx
00007ffc`8c2e0b4d 5e              pop     rsi
00007ffc`8c2e0b4e 5f              pop     rdi
00007ffc`8c2e0b4f c3              ret






public void JitHelper(List<T> list)
{
    for (var i = 0; i < 11; i++)
        if (list.Any())
            return;
}



0:003> !U 00007ffaa0425e70
Normal JIT generated code
HoistingInDotNetExamples.HoistingJitHelperMethod`1[[System.__Canon, mscorlib]].JitHelper(System.Collections.Generic.List`1<System.__Canon>)
Begin 00007ffaa0530650, size 62
*** WARNING: Unable to verify checksum for HoistingInDotNetExamples.exe

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 89:
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

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 90:
00007ffa`a0530668 488bcd          mov     rcx,rbp
00007ffa`a053066b 488b5130        mov     rdx,qword ptr [rcx+30h]
00007ffa`a053066f 488b12          mov     rdx,qword ptr [rdx]
00007ffa`a0530672 488b4208        mov     rax,qword ptr [rdx+8]
00007ffa`a0530676 4885c0          test    rax,rax
00007ffa`a0530679 750f            jne     00007ffa`a053068a
00007ffa`a053067b 48ba281757a0fa7f0000 mov rdx,7FFAA0571728h
*** ERROR: Symbol file could not be found.  Defaulted to export symbols for C:\Windows\Microsoft.NET\Framework64\v4.0.30319\clr.dll -
00007ffa`a0530685 e8269d6b5f      call    clr!LogHelp_LogAssert+0x3e810 (00007ffa`ffbea3b0) (JitHelp: CORINFO_HELP_RUNTIMEHANDLE_CLASS)
00007ffa`a053068a 488bc8          mov     rcx,rax
00007ffa`a053068d 488bd6          mov     rdx,rsi
*** WARNING: Unable to verify checksum for C:\WINDOWS\assembly\NativeImages_v4.0.30319_64\System.Core\5034a88e58f966dd7d69fe9b9875832c\System.Core.ni.dll
*** ERROR: Module load completed but symbols could not be loaded for C:\WINDOWS\assembly\NativeImages_v4.0.30319_64\System.Core\5034a88e58f966dd7d69fe9b9875832c\System.Core.ni.dll
00007ffa`a0530690 e81b0bd85c      call    System_Core_ni+0x2f11b0 (00007ffa`fd2b11b0) (System.Linq.Enumerable.Any[[System.__Canon, mscorlib]](System.Collections.Generic.IEnumerable`1<System.__Canon>), mdToken: 0000000006000748)
00007ffa`a0530695 84c0            test    al,al
00007ffa`a0530697 7409            je      00007ffa`a05306a2

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 92:
00007ffa`a0530699 4883c428        add     rsp,28h
00007ffa`a053069d 5b              pop     rbx
00007ffa`a053069e 5d              pop     rbp
00007ffa`a053069f 5e              pop     rsi
00007ffa`a05306a0 5f              pop     rdi
00007ffa`a05306a1 c3              ret

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 89:
00007ffa`a05306a2 ffc3            inc     ebx
00007ffa`a05306a4 83fb0b          cmp     ebx,0Bh
00007ffa`a05306a7 7cbf            jl      00007ffa`a0530668

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 92:
00007ffa`a05306a9 4883c428        add     rsp,28h
00007ffa`a05306ad 5b              pop     rbx
00007ffa`a05306ae 5d              pop     rbp
00007ffa`a05306af 5e              pop     rsi
00007ffa`a05306b0 5f              pop     rdi
00007ffa`a05306b1 c3              ret
