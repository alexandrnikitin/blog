0:003> !U 00007fff23bb0580 
Normal JIT generated code
HoistingInDotNetExamples.HoistingArray.Test(Int32[])
Begin 00007fff23bb0580, size 3b
*** WARNING: Unable to verify checksum for HoistingInDotNetExamples.exe

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingArray.cs @ 10:
>>> 00007fff`23bb0580 4883ec28        sub     rsp,28h
00007fff`23bb0584 33c0            xor     eax,eax

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingArray.cs @ 12:
00007fff`23bb0586 33c9            xor     ecx,ecx
00007fff`23bb0588 448b4208        mov     r8d,dword ptr [rdx+8]
00007fff`23bb058c 4585c0          test    r8d,r8d
00007fff`23bb058f 7e1f            jle     00007fff`23bb05b0
00007fff`23bb0591 4183f801        cmp     r8d,1
00007fff`23bb0595 761e            jbe     00007fff`23bb05b5
00007fff`23bb0597 448b4a14        mov     r9d,dword ptr [rdx+14h]

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingArray.cs @ 14:
00007fff`23bb059b 4103c1          add     eax,r9d
00007fff`23bb059e 4c63d1          movsxd  r10,ecx
00007fff`23bb05a1 468b549210      mov     r10d,dword ptr [rdx+r10*4+10h]
00007fff`23bb05a6 4103c2          add     eax,r10d

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingArray.cs @ 12:
00007fff`23bb05a9 ffc1            inc     ecx
00007fff`23bb05ab 443bc1          cmp     r8d,ecx
00007fff`23bb05ae 7feb            jg      00007fff`23bb059b

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingArray.cs @ 17:
00007fff`23bb05b0 4883c428        add     rsp,28h
00007fff`23bb05b4 c3              ret

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingArray.cs @ 10:
*** ERROR: Symbol file could not be found.  Defaulted to export symbols for C:\Windows\Microsoft.NET\Framework64\v4.0.30319\clr.dll -
00007fff`23bb05b5 e84e14a85f      call    clr!TranslateSecurityAttributes+0x900d4 (00007fff`83631a08) (JitHelp: CORINFO_HELP_RNGCHKFAIL)
00007fff`23bb05ba cc              int     3
