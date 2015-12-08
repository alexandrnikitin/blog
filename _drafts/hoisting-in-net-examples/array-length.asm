0:005> !U 00007ffaa0425a58    
Normal JIT generated code
HoistingInDotNetExamples.HoistingArray.Length(Int32[])
Begin 00007ffaa05304f0, size 17
*** WARNING: Unable to verify checksum for HoistingInDotNetExamples.exe

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 10:
00007ffa`a05304f0 33c0            xor     eax,eax

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 12:
00007ffa`a05304f2 33c9            xor     ecx,ecx
00007ffa`a05304f4 8b5208          mov     edx,dword ptr [rdx+8]
00007ffa`a05304f7 85d2            test    edx,edx
00007ffa`a05304f9 7e0b            jle     00007ffa`a0530506

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 14:
00007ffa`a05304fb b801000000      mov     eax,1

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 12:
00007ffa`a0530500 ffc1            inc     ecx
00007ffa`a0530502 3bd1            cmp     edx,ecx
00007ffa`a0530504 7ff5            jg      00007ffa`a05304fb

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 17:
00007ffa`a0530506 c3              ret




C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 10:
00007ffa`a05304f0 4883ec28        sub     rsp,28h
00007ffa`a05304f4 33c0            xor     eax,eax

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 12:
00007ffa`a05304f6 33c9            xor     ecx,ecx
00007ffa`a05304f8 448b4208        mov     r8d,dword ptr [rdx+8]
00007ffa`a05304fc 4585c0          test    r8d,r8d
00007ffa`a05304ff 7e1f            jle     00007ffa`a0530520
00007ffa`a0530501 4183f800        cmp     r8d,0
00007ffa`a0530505 761e            jbe     00007ffa`a0530525
00007ffa`a0530507 448b4a10        mov     r9d,dword ptr [rdx+10h]

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 14:
00007ffa`a053050b 4103c1          add     eax,r9d
00007ffa`a053050e 4c63d1          movsxd  r10,ecx
00007ffa`a0530511 468b549210      mov     r10d,dword ptr [rdx+r10*4+10h]
00007ffa`a0530516 4103c2          add     eax,r10d

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 12:
00007ffa`a0530519 ffc1            inc     ecx
00007ffa`a053051b 443bc1          cmp     r8d,ecx
00007ffa`a053051e 7feb            jg      00007ffa`a053050b

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 17:
00007ffa`a0530520 4883c428        add     rsp,28h
00007ffa`a0530524 c3              ret

00007ffa`a0530525 e8de14a95f      call    clr!TranslateSecurityAttributes+0x900d4 (00007ffa`fffc1a08) (JitHelp: CORINFO_HELP_RNGCHKFAIL)
00007ffa`a053052a cc              int     3
