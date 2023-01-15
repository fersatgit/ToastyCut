set include=D:\program files\fasm\include
set xz="D:\program files\xz\xz.exe" -e -k --format=lzma
set fasm="D:\program files\fasm\fasm.exe"

del res\CompressedData.lzma
del res\ToastyCut.bmp.lzma
del res\ToastyCut.gms.lzma
del res\ToastyCut.ico.lzma
%fasm% res\CompressedData.asm
%xz% res\CompressedData
%xz% res\ToastyCut.bmp
%xz% res\ToastyCut.gms
%xz% res\ToastyCut.ico
%fasm% ToastyCut.asm ToastyCut.exe
pause