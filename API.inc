include 'encoding\win1251.inc'
include 'win32w.inc'
include 'OpenGL.inc'

virtual at 0
  file 'res\toasty.wav':4Ah,4
  load WavSize dword from 0
end virtual

IPPROTO_TCP     = 6
SOCKET_ERROR    = -1

WAVE_FORMAT_PCM = 1
WAVE_MAPPER     = -1

struct WAVEFORMATEX
  wFormatTag      rw 1
  nChannels       rw 1
  nSamplesPerSec  rd 1
  nAvgBytesPerSec rd 1
  nBlockAlign     rw 1
  wBitsPerSample  rw 1
  cbSize          rw 1
ends

struct WAVEHDR
  lpData          rd 1
  dwBufferLength  rd 1
  dwBytesRecorded rd 1
  dwUser          rd 1
  dwFlags         rd 1
  dwLoops         rd 1
  lpNext          rd 1
  reserved        rd 1
ends

struct TPreview
  pfd             PIXELFORMATDESCRIPTOR
  DC              rd 1
  RC              rd 1
  Width           rd 1
  Height          rd 1
  Scale           rd 1
  MetricMat       rd 16
  PixelMat        rd 16
ends

sizeof.TCutter.Name=28

struct TCutter
  Name   rb sizeof.TCutter.Name
  hres   rw 1
  vres   rw 1
  Flags  rb 1
  init   rb 19
  Move   rb 3
  Cut    rb 3
  Delim  rb 2
  Term   rb 4
  End    rb 9
ends

struct TCutterParams
  ID          rw 1
  hres        rw 1
  vres        rw 1
  Flags       rb 1
  Init        rb 19
  Move        rb 3
  Cut         rb 3
  Delim       rb 2
  Term        rb 4
  End         rb 10
  Radius      rd 1
  AngleStep   rd 1
  IP          rd 1
  TCPPort     rw 1
  Port        rw 7
ends

HEAP_REALLOC_IN_PLACE_ONLY       =16
CLSCTX_LOCAL_SERVER              =4
DIGCF_PRESENT                    =2;
DIGCF_DEVICEINTERFACE            =16;
SPDRP_FRIENDLYNAME               =12;
SPDRP_PHYSICAL_DEVICE_OBJECT_NAME=14;

struct SP_DEVINFO_DATA
  cbSize     rd 1
  ClassGuid  rb 16
  DevInst    rd 1
  Reserved   rd 1
ends

struct SP_DEVICE_INTERFACE_DATA
  cbSize              rd 1
  InterfaceClassGuid  rb 16
  Flags               rd 1
  Reserved            rd 1
ends

struct SP_DEVICE_INTERFACE_DETAIL_DATA_W
  cbSize     rd 1
  DevicePath rw 4096
ends

struct DCB
  DCBlength  rd 1
  BaudRate   rd 1
  Flags      rd 1
  wReserved  rw 1
  XonLim     rw 1
  XoffLim    rw 1
  ByteSize   rb 1
  Parity     rb 1
  StopBits   rb 1
  XonChar    rb 1
  XoffChar   rb 1
  ErrorChar  rb 1
  EofChar    rb 1
  EvtChar    rb 1
  wReserved1 rw 1
ends

struct COMMCONFIG
  dwSize            rd 1
  wVersion          rw 1
  wReserved         rw 1
  dcb               DCB
  dwProviderSubType rd 1
  dwProviderOffset  rd 1
  dwProviderSize    rd 1
  wcProviderData    rw 2
ends

  FLAG_FLIP_X       =1
  FLAG_SWAP_COORDS  =2
  FLAG_DTR_DSR      =4
  FLAG_XON_XOFF     =8
  FLAG_RTS_CTS      =16
  FLAG_KNIFE_ROTATE =32
  FLAG_SHOW_VERTICES=64