0:003> !U 00007ffaa0415b50    
Normal JIT generated code
HoistingInDotNetExamples.HoistingStatic.Static()
Begin 00007ffaa0520590, size 14
*** WARNING: Unable to verify checksum for HoistingInDotNetExamples.exe

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 41:
00007ffa`a0520590 33c0            xor     eax,eax

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 43:
00007ffa`a0520592 33d2            xor     edx,edx

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 45:
00007ffa`a0520594 8b0dc241efff    mov     ecx,dword ptr [00007ffa`a041475c]
00007ffa`a052059a 03c1            add     eax,ecx

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 43:
00007ffa`a052059c ffc2            inc     edx
00007ffa`a052059e 83fa0b          cmp     edx,0Bh
00007ffa`a05205a1 7cf1            jl      00007ffa`a0520594

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 48:
00007ffa`a05205a3 c3              ret
