public class HoistinMath
{
    [MethodImpl(MethodImplOptions.NoInlining)]
    public double Run(int a)
    {
        var sum = 0d;

        for (var i = 0; i < 11; i++)
        {
            sum += Math.Abs(a) + Math.Sqrt(2);
        }

        return sum;
    }
}


0:003> !U 00007fff23a86398
Normal JIT generated code
HoistingInDotNetExamples.HoistinMath.Run(Int32)
Begin 00007fff23b90970, size 74
*** WARNING: Unable to verify checksum for HoistingInDotNetExamples.exe

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistinMath.cs @ 11:
00007fff`23b90970 57              push    rdi
00007fff`23b90971 56              push    rsi
00007fff`23b90972 53              push    rbx
00007fff`23b90973 4883ec30        sub     rsp,30h
00007fff`23b90977 c4e17829742420  vmovaps xmmword ptr [rsp+20h],xmm6
00007fff`23b9097e c5f877          vzeroupper
00007fff`23b90981 8bf2            mov     esi,edx
00007fff`23b90983 c4e14957f6      vxorpd  xmm6,xmm6,xmm6

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistinMath.cs @ 13:
00007fff`23b90988 33ff            xor     edi,edi
00007fff`23b9098a c4e17b510555000000 vsqrtsd xmm0,xmm0,mmword ptr [00007fff`23b909e8]

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistinMath.cs @ 15:
00007fff`23b90993 85f6            test    esi,esi
00007fff`23b90995 7c04            jl      00007fff`23b9099b
00007fff`23b90997 8bde            mov     ebx,esi
00007fff`23b90999 eb09            jmp     00007fff`23b909a4
00007fff`23b9099b 8bce            mov     ecx,esi
*** WARNING: Unable to verify checksum for C:\WINDOWS\assembly\NativeImages_v4.0.30319_64\mscorlib\fa8eef6f6cb67c660d71e15c5cad71b5\mscorlib.ni.dll
*** ERROR: Module load completed but symbols could not be loaded for C:\WINDOWS\assembly\NativeImages_v4.0.30319_64\mscorlib\fa8eef6f6cb67c660d71e15c5cad71b5\mscorlib.ni.dll
00007fff`23b9099d e89ec0535e      call    mscorlib_ni+0x45ca40 (00007fff`820cca40) (System.Math.AbsHelper(Int32), mdToken: 0000000006000f17)
00007fff`23b909a2 8bd8            mov     ebx,eax
00007fff`23b909a4 c4e17857c0      vxorps  xmm0,xmm0,xmm0
00007fff`23b909a9 c4e17b2ac3      vcvtsi2sd xmm0,xmm0,ebx
00007fff`23b909ae c4e17b510d39000000 vsqrtsd xmm1,xmm0,mmword ptr [00007fff`23b909f0]
00007fff`23b909b7 c4e17b58c1      vaddsd  xmm0,xmm0,xmm1
00007fff`23b909bc c4e17b58c6      vaddsd  xmm0,xmm0,xmm6
00007fff`23b909c1 c4e17828f0      vmovaps xmm6,xmm0

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistinMath.cs @ 13:
00007fff`23b909c6 ffc7            inc     edi
00007fff`23b909c8 83ff0b          cmp     edi,0Bh
00007fff`23b909cb 7cc6            jl      00007fff`23b90993

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistinMath.cs @ 18:
00007fff`23b909cd c4e17828c6      vmovaps xmm0,xmm6
00007fff`23b909d2 c5f877          vzeroupper
00007fff`23b909d5 c4e17828742420  vmovaps xmm6,xmmword ptr [rsp+20h]
00007fff`23b909dc 4883c430        add     rsp,30h
00007fff`23b909e0 5b              pop     rbx
00007fff`23b909e1 5e              pop     rsi
00007fff`23b909e2 5f              pop     rdi
00007fff`23b909e3 c3              ret










[MethodImpl(MethodImplOptions.NoInlining)]
public double Run(int a)
{
    var sum = 0d;

    for (var i = 0; i < 11; i++)
    {
        sum += Math.Abs(a) + Math.Pow(2, 2);
    }

    return sum;
}





0:003> !U 00007fff23a76398
Normal JIT generated code
HoistingInDotNetExamples.HoistinMath.Run(Int32)
Begin 00007fff23b80970, size 74
*** WARNING: Unable to verify checksum for HoistingInDotNetExamples.exe

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistinMath.cs @ 11:
00007fff`23b80970 57              push    rdi
00007fff`23b80971 56              push    rsi
00007fff`23b80972 53              push    rbx
00007fff`23b80973 4883ec30        sub     rsp,30h
00007fff`23b80977 c4e17829742420  vmovaps xmmword ptr [rsp+20h],xmm6
00007fff`23b8097e c5f877          vzeroupper
00007fff`23b80981 8bf2            mov     esi,edx
00007fff`23b80983 c4e14957f6      vxorpd  xmm6,xmm6,xmm6

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistinMath.cs @ 13:
00007fff`23b80988 33ff            xor     edi,edi

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistinMath.cs @ 15:
00007fff`23b8098a 85f6            test    esi,esi
00007fff`23b8098c 7c04            jl      00007fff`23b80992
00007fff`23b8098e 8bde            mov     ebx,esi
00007fff`23b80990 eb09            jmp     00007fff`23b8099b
00007fff`23b80992 8bce            mov     ecx,esi
*** WARNING: Unable to verify checksum for C:\WINDOWS\assembly\NativeImages_v4.0.30319_64\mscorlib\fa8eef6f6cb67c660d71e15c5cad71b5\mscorlib.ni.dll
*** ERROR: Module load completed but symbols could not be loaded for C:\WINDOWS\assembly\NativeImages_v4.0.30319_64\mscorlib\fa8eef6f6cb67c660d71e15c5cad71b5\mscorlib.ni.dll
00007fff`23b80994 e8a7c0545e      call    mscorlib_ni+0x45ca40 (00007fff`820cca40) (System.Math.AbsHelper(Int32), mdToken: 0000000006000f17)
00007fff`23b80999 8bd8            mov     ebx,eax
00007fff`23b8099b c4e17b100544000000 vmovsd xmm0,qword ptr [00007fff`23b809e8]
00007fff`23b809a4 c4e17b100d43000000 vmovsd xmm1,qword ptr [00007fff`23b809f0]
*** ERROR: Symbol file could not be found.  Defaulted to export symbols for C:\Windows\Microsoft.NET\Framework64\v4.0.30319\clr.dll -
00007fff`23b809ad e86e45d15f      call    clr!NGenCreateNGenWorker+0xa7880 (00007fff`83894f20) (System.Math.Pow(Double, Double), mdToken: 0000000006000f10)
00007fff`23b809b2 c4e17057c9      vxorps  xmm1,xmm1,xmm1
00007fff`23b809b7 c4e1732acb      vcvtsi2sd xmm1,xmm1,ebx
00007fff`23b809bc c4e17b58c1      vaddsd  xmm0,xmm0,xmm1
00007fff`23b809c1 c4e14b58f0      vaddsd  xmm6,xmm6,xmm0

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistinMath.cs @ 13:
00007fff`23b809c6 ffc7            inc     edi
00007fff`23b809c8 83ff0b          cmp     edi,0Bh
00007fff`23b809cb 7cbd            jl      00007fff`23b8098a

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistinMath.cs @ 18:
00007fff`23b809cd c4e17828c6      vmovaps xmm0,xmm6
00007fff`23b809d2 c5f877          vzeroupper
00007fff`23b809d5 c4e17828742420  vmovaps xmm6,xmmword ptr [rsp+20h]
00007fff`23b809dc 4883c430        add     rsp,30h
00007fff`23b809e0 5b              pop     rbx
00007fff`23b809e1 5e              pop     rsi
00007fff`23b809e2 5f              pop     rdi
00007fff`23b809e3 c3              ret
