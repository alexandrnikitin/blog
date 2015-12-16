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


0:003> !U 00007fff23a86098
Normal JIT generated code
HoistingInDotNetExamples.HoistingField.Field()
Begin 00007fff23b907b0, size 11
*** WARNING: Unable to verify checksum for HoistingInDotNetExamples.exe

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingField.cs @ 12:
00007fff`23b907b0 33c0            xor     eax,eax

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingField.cs @ 14:
00007fff`23b907b2 33d2            xor     edx,edx
00007fff`23b907b4 8b4908          mov     ecx,dword ptr [rcx+8]

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingField.cs @ 16:
00007fff`23b907b7 03c1            add     eax,ecx

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingField.cs @ 14:
00007fff`23b907b9 ffc2            inc     edx
00007fff`23b907bb 83fa0b          cmp     edx,0Bh
00007fff`23b907be 7cf7            jl      00007fff`23b907b7

C:\temp\HoistingInDotNetExamples\HoistingInDotNetExamples\HoistingField.cs @ 19:
00007fff`23b907c0 c3              ret
