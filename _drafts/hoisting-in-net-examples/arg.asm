[MethodImpl(MethodImplOptions.NoInlining)]
public int Arg(int a)
{
    var sum = 0;

    for (var i = 0; i < 11; i++)
    {
        sum += a;
    }

    return sum;
}



0:003> !U 00007fff23a86148
Normal JIT generated code
HoistingInDotNetExamples.HoistingArg.Arg(Int32)
Begin 00007fff23b907e0, size e

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingArg.cs @ 10:
00007fff`23b907e0 33c0            xor     eax,eax

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingArg.cs @ 12:
00007fff`23b907e2 33c9            xor     ecx,ecx

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingArg.cs @ 14:
00007fff`23b907e4 03c2            add     eax,edx

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingArg.cs @ 12:
00007fff`23b907e6 ffc1            inc     ecx
00007fff`23b907e8 83f90b          cmp     ecx,0Bh
00007fff`23b907eb 7cf7            jl      00007fff`23b907e4

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingArg.cs @ 17:
00007fff`23b907ed c3              ret
