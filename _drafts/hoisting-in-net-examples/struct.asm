0:003> !U 00007ffaa0405c28    
Normal JIT generated code
HoistingInDotNetExamples.HoistingStruct.Struct(System.Nullable`1<Int32>)
Begin 00007ffaa05105f0, size 3c
*** WARNING: Unable to verify checksum for HoistingInDotNetExamples.exe

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 60:
00007ffa`a05105f0 57              push    rdi
00007ffa`a05105f1 56              push    rsi
00007ffa`a05105f2 55              push    rbp
00007ffa`a05105f3 53              push    rbx
00007ffa`a05105f4 4883ec28        sub     rsp,28h
00007ffa`a05105f8 4889542458      mov     qword ptr [rsp+58h],rdx
00007ffa`a05105fd 33f6            xor     esi,esi

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 62:
00007ffa`a05105ff 33ff            xor     edi,edi
00007ffa`a0510601 0fb65c2458      movzx   ebx,byte ptr [rsp+58h]
00007ffa`a0510606 8b6c245c        mov     ebp,dword ptr [rsp+5Ch]

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 64:
00007ffa`a051060a 85db            test    ebx,ebx
00007ffa`a051060c 750a            jne     00007ffa`a0510618
00007ffa`a051060e b926000000      mov     ecx,26h
*** WARNING: Unable to verify checksum for C:\WINDOWS\assembly\NativeImages_v4.0.30319_64\mscorlib\fa8eef6f6cb67c660d71e15c5cad71b5\mscorlib.ni.dll
*** ERROR: Module load completed but symbols could not be loaded for C:\WINDOWS\assembly\NativeImages_v4.0.30319_64\mscorlib\fa8eef6f6cb67c660d71e15c5cad71b5\mscorlib.ni.dll
00007ffa`a0510613 e8983dcb5e      call    mscorlib_ni+0xbc43b0 (00007ffa`ff1c43b0) (System.ThrowHelper.ThrowInvalidOperationException(System.ExceptionResource), mdToken: 0000000006000326)
00007ffa`a0510618 03f5            add     esi,ebp

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 62:
00007ffa`a051061a ffc7            inc     edi
00007ffa`a051061c 83ff0b          cmp     edi,0Bh
00007ffa`a051061f 7ce9            jl      00007ffa`a051060a

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 67:
00007ffa`a0510621 8bc6            mov     eax,esi
00007ffa`a0510623 4883c428        add     rsp,28h
00007ffa`a0510627 5b              pop     rbx
00007ffa`a0510628 5d              pop     rbp
00007ffa`a0510629 5e              pop     rsi
00007ffa`a051062a 5f              pop     rdi
00007ffa`a051062b c3              ret










0:003> !U 00007ffaa0415c30    
Normal JIT generated code
HoistingInDotNetExamples.HoistingStruct.Struct(MyStruct)
Begin 00007ffaa05205e0, size e
*** WARNING: Unable to verify checksum for HoistingInDotNetExamples.exe

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 70:
00007ffa`a05205e0 33c0            xor     eax,eax

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 72:
00007ffa`a05205e2 33c9            xor     ecx,ecx

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 74:
00007ffa`a05205e4 03c2            add     eax,edx

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 72:
00007ffa`a05205e6 ffc1            inc     ecx
00007ffa`a05205e8 83f90b          cmp     ecx,0Bh
00007ffa`a05205eb 7cf7            jl      00007ffa`a05205e4

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\Array.cs @ 77:
00007ffa`a05205ed c3              ret
