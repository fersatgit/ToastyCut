format PE GUI 4.0 at 400000h
stack 1*1024*1024
include 'API.inc'

BMPSize     =406
GMSSize     =14866
ICOSize     =2686
CuttersCount=184

CutterParams TCutterParams  117,1000,1000,FLAG_FLIP_X+FLAG_SWAP_COORDS+FLAG_XON_XOFF+FLAG_RTS_CTS+FLAG_KNIFE_ROTATE,'IN;PA','PU','PD',',',';','!PG;',0.42,0.1,$C0A80001,901Fh,0

align 16
data resource from 'res\1.res'
end data

include 'LZMADec.asm'

align 16
entry $
  mov    eax,1
  cpuid
  test   ecx,1
  mov    eax,ErrCPU
  je Init.Error
  invoke WSAStartup,0202h,Temp
  call   [InitCommonControls]
  invoke CreateThread,0,4*1024*1024,Init,0,0,0
  mov    [CurPoint],eax
  invoke DialogBoxParamW,400000h,1,0,DlgProc,0

ShowControls:
  pushad
  mov ebx,[esp+36]
  mov esi,hwnds.count-2
  @@:invoke ShowWindow,[hwnds+esi*4],ebx
     dec    esi
  jne @b
  popad
ret 4

GetCutterParams:
  push   edi
  mov    ecx,sizeof.TCutterParams shr 2
  mov    edi,ActiveParams
  xor    eax,eax
  rep    stosd
  invoke SendMessageW,[hwnds.Cutters_combo],CB_GETCURSEL,0,0
  mov    [ActiveParams.ID],ax
  invoke SendMessageA,[hwnds.Init_edit],WM_GETTEXT,19,ActiveParams.Init
  invoke SendMessageA,[hwnds.Move_edit],WM_GETTEXT,3,ActiveParams.Move
  invoke SendMessageA,[hwnds.Cut_edit],WM_GETTEXT,3,ActiveParams.Cut
  invoke SendMessageA,[hwnds.Delim_edit],WM_GETTEXT,2,ActiveParams.Delim
  invoke SendMessageA,[hwnds.Term_edit],WM_GETTEXT,3,ActiveParams.Term
  invoke SendMessageA,[hwnds.End_edit],WM_GETTEXT,9,ActiveParams.End
  invoke SendMessageA,[hwnds.HRes_edit],WM_GETTEXT,TSize,Temp
  mov    eax,Temp
  call   StrToUInt
  mov    [ActiveParams.hres],ax
  invoke SendMessageA,[hwnds.VRes_edit],WM_GETTEXT,TSize,Temp
  mov    eax,Temp
  call   StrToUInt
  mov    [ActiveParams.vres],ax
  invoke SendMessageW,[hwnds.ShowVertices_check],BM_GETCHECK,0,0
  mov    edi,eax
  invoke SendMessageW,[hwnds.KnifeRotate_check],BM_GETCHECK,0,0
  lea    edi,[edi*2+eax]
  invoke SendMessageW,[hwnds.RTS_check],BM_GETCHECK,0,0
  lea    edi,[edi*2+eax]
  invoke SendMessageW,[hwnds.XON_check],BM_GETCHECK,0,0
  lea    edi,[edi*2+eax]
  invoke SendMessageW,[hwnds.DTR_check],BM_GETCHECK,0,0
  lea    edi,[edi*2+eax]
  invoke SendMessageW,[hwnds.Swap_check],BM_GETCHECK,0,0
  lea    edi,[edi*2+eax]
  invoke SendMessageW,[hwnds.Flip_check],BM_GETCHECK,0,0
  lea    eax,[edi*2+eax]
  mov    [ActiveParams.Flags],al
  invoke SendMessageA,[hwnds.Radius_edit],WM_GETTEXT,TSize,Temp
  mov    eax,Temp
  call   StrToFloatU
  mulss  xmm0,[flt_100]
  movss  [ActiveParams.Radius],xmm0
  invoke SendMessageA,[hwnds.AngleStep_edit],WM_GETTEXT,TSize,Temp
  mov    eax,Temp
  call   StrToFloatU
  mulss  xmm0,[flt_100]
  movss  [ActiveParams.AngleStep],xmm0
  invoke SendMessageW,[hwnds.IP_addr],IPM_GETADDRESS,0,ActiveParams.IP
  invoke SendMessageA,[hwnds.IP_port],WM_GETTEXT,TSize,Temp
  mov    eax,Temp
  call   StrToUInt
  rol    ax,8
  mov    [ActiveParams.TCPPort],ax
  invoke SendMessageW,[hwnds.Port_combo],WM_GETTEXT,7,ActiveParams.Port
  pop    edi
ret

PortOpen:
    push   ebp
    mov    [Write],_WriteFile
    invoke closesocket,ebx
    invoke CloseHandle,ebx
    invoke SendMessageW,[hwnds.Port_combo],CB_GETCURSEL,0,0
    mov    ebp,eax
    invoke SendMessageW,[hwnds.Port_combo],CB_GETCOUNT,0,0
    sub    eax,ebp
    dec    eax
    jne @f
      mov    word[Temp],0
      invoke GetSaveFileNameW,ofn
      test   eax,eax
      je CutterProc.quit
        invoke CreateFileW,Temp,GENERIC_READ+GENERIC_WRITE,0,0,CREATE_ALWAYS,0,0
        mov    ebp,[GetLastError]
        jmp .errtest
    @@:
    dec    eax
    jne @f
      invoke socket,AF_INET,SOCK_STREAM,IPPROTO_TCP
      mov    ebx,eax
      sub    esp,8
      mov    ecx,[ActiveParams.IP]
      bswap  ecx
      push   ecx
      push   [ActiveParams.TCPPort]
      pushw  AF_INET
      mov    edx,esp
      invoke connect,eax,edx,16
      add    esp,16
      mov    ebp,[WSAGetLastError]
      mov    [Write],_Send
      jmp .errtest2
    @@:
      shl    ebp,10
      add    ebp,COMPorts
      invoke CreateFileW,ebp,GENERIC_READ+GENERIC_WRITE,0,0,OPEN_EXISTING,0,0
      push   dword[esp]
      mov    dword[esp+4],@f
      mov    ebp,[GetLastError]
      jmp    .errtest
      @@:
      invoke GetDefaultCommConfigW,ActiveParams.Port,COMMConfig,COMMConfig.dwSize
      movzx  eax,[ActiveParams.Flags]
      and    eax,FLAG_DTR_DSR+FLAG_XON_XOFF+FLAG_RTS_CTS
      shr    eax,1
      movzx  eax,[.DCBFlags+eax]
      mov    [COMMConfig.dcb.Flags],eax
      invoke SetCommConfig,ebx,COMMConfig,[COMMConfig.dwSize]
      ret
    .errtest:
    mov ebx,eax
    .errtest2:
    cmp eax,INVALID_HANDLE_VALUE
    jne @f
      call   ebp
      invoke FormatMessageW,FORMAT_MESSAGE_FROM_SYSTEM,0,eax,0,Temp,TSize,0
      mov    word[Temp+eax*2],0
      invoke MessageBoxW,[ofn.hwndOwner],Temp,0,0
      jmp    CutterProc.quit
    @@:
    pop ebp
ret
.DCBFlags dw 20497,20521,21265,21289,24597,24621,25365,25389

_WriteFile:
  invoke WriteFile,ebx,esi,edi,act_len,0
  test   eax,eax
  mov    eax,[act_len]
ret

_Send:
  invoke send,ebx,esi,edi,0
  cmp    eax,SOCKET_ERROR
ret

_SendCommand:  ;eax - command, st0,st1 - x,y
  pushad
  test [ActiveParams.Flags],FLAG_SWAP_COORDS
  je @f
    fxch st1
  @@:
  sub   esp,28
  mov   dword[esp],Temp
  mov   dword[esp+4],fmt_sisis
  mov   dword[esp+8],eax
  fmul  st0,st5
  fistp dword[esp+12]
  mov   dword[esp+16],ActiveParams.Delim
  fmul  st0,st5
  fistp dword[esp+20]
  mov   dword[esp+24],ActiveParams.Term
  call  [wsprintfA]
  add   esp,28
  mov   edi,eax
  mov   esi,Temp
  .send:call    [Write]
        jne @f
          call PortOpen
        @@:
        add     esi,eax
        sub     edi,eax
  jne .send
  popad
ret

macro SendCommand Command{
    fld     st0
    fsincos
    fxch    st1
    fmul    [ActiveParams.Radius]
    fadd    dword[ebp+4]
    fxch    st1
    fmul    [ActiveParams.Radius]
    fadd    dword[ebp]
    mov     eax,Command
    call    _SendCommand
}

macro cinvoke2 func,[args]{
  common
  local i
  i equ 0
  forward
  if args eq st0
    fistp dword[esp+i]
  else
    mov dword[esp+i],args
  end if
  i equ i+4
  common
  call [func]
}

CutterProc: ;(lParam: dword);stdcall;
  sub       esp,16
  call      PortOpen
  invoke    SetTimer,[hwnds.Preview],1,100,0

  finit
  fild      [ActiveParams.vres]
  fmul      [.flt_mm2inch]
  fild      [ActiveParams.hres]
  fmul      [.flt_mm2inch]

  fld       [CutHeight]
  fmul      st0,st2
  fld       [CutWidth]
  fmul      st0,st2
  test      [ActiveParams.Flags],FLAG_SWAP_COORDS
  je @f
    fxch st1
  @@:
  cinvoke2  wsprintfA,Temp,ActiveParams.Init,st0,ActiveParams.Delim,st0
  cinvoke2  wsprintfA,Temp,fmt_ss,Temp,ActiveParams.Term
  invoke    WriteFile,ebx,Temp,eax,act_len,0
  mov       [CurPoint],0

  fldz
  fldz
  fldz
  test      [ActiveParams.Flags],FLAG_KNIFE_ROTATE
  je @f
    fldz
    fld  [ActiveParams.Radius]
    fadd st0,st0
    fadd [ActiveParams.Radius]
    fchs
    mov  eax,ActiveParams.Move
    call _SendCommand
    fldz
    fldz
    mov  eax,ActiveParams.Cut
    call _SendCommand
  @@:

  xor   esi,esi
  mov   ebp,[SortedPoints]
  .Path:
    SendCommand ActiveParams.Move
    mov         eax,[SortedPathsLen]
    mov         edi,[eax+esi*4]
    dec         edi
    .Point:
      fstp    st0
      fld     dword[ebp+12]
      fsub    dword[ebp+4]
      fld     dword[ebp+8]
      fsub    dword[ebp]
      fpatan
      fld     st0
      fsub    st0,st2
      fstp    dword[esp-4]
      movss   xmm0,[esp-4]
      comiss  xmm0,[.flt_PI]
      jna @f
        subss xmm0,[.flt_2PI]
      @@:
      comiss  xmm0,[.flt_minusPI]
      ja @f
        addss xmm0,[.flt_2PI]
      @@:
      movss    xmm1,xmm0
      movss    xmm2,[flt_abs]
      andps    xmm1,xmm2
      mulss    xmm1,[ActiveParams.Radius]
      divss    xmm1,[ActiveParams.AngleStep]
      cvtss2si edx,xmm1
      test     edx,edx
      je @f
        cvtsi2ss xmm1,edx
        divss    xmm0,xmm1
      @@:
      movss    [esp-4],xmm0
      fld      dword[esp-4]
      fstp     st3
      fxch     st1
      @@:SendCommand ActiveParams.Cut
         fadd        st0,st2
         dec         edx
      jns @b
      inc      [CurPoint]
      add      ebp,8
      dec      edi
    jne .Point
    SendCommand ActiveParams.Cut
    inc         [CurPoint]
    add         ebp,8
    inc         esi
    cmp         esi,[NumPaths]
  jne .Path
  fld    dword[ebp-4]
  fldz
  mov    eax,ActiveParams.Move
  call   _SendCommand
  invoke lstrlenA,ActiveParams.End
  invoke WriteFile,ebx,ActiveParams.End,eax,act_len,0
  invoke SetTimer,[hwnds.Preview],1,50,0
  test   [CurCoordSpace],FLAG_FLIP_X
  mov    eax,65-128
  jne @f
     movss    xmm0,[Preview.Width]
     cvtss2si eax,xmm0
     sub      eax,5+128
  @@:
  mov    [ToastyPos],eax
  mov    [ToastyInc],0
  mov    esi,esp
  invoke waveOutOpen,esi,WAVE_MAPPER,wForm,0,0,0
  mov    esi,[esi]
  invoke waveOutPrepareHeader,esi,hdr,sizeof.WAVEHDR
  invoke waveOutWrite,esi,hdr,sizeof.WAVEHDR
  invoke Sleep,WavSize/8
  mov    [ToastyInc],128/(WavSize/800)
  invoke Sleep,WavSize/16
  mov    [ToastyPos],1 shl 31-1
  invoke waveOutUnprepareHeader,esi,hdr,sizeof.WAVEHDR
  invoke waveOutClose,esi
  .quit:
  mov     [CurPoint],0
  mov     [CutterThread],0
  invoke  closesocket,ebx
  invoke  CloseHandle,ebx
  invoke  SendMessageW,[hwnds.Start_button],WM_SETTEXT,0,strStart
  invoke  KillTimer,[hwnds.Preview],1
  stdcall ShowControls,SW_SHOW
  stdcall DlgProc,0,WM_COMMAND,CBN_SELCHANGE shl 16+(hwnds.Port_combo-hwnds)/4,0
  invoke  InvalidateRect,[hwnds.Preview],0,0
  invoke  ExitThread,0
.flt_mm2inch dd 0.000393701,0.000393701
.flt_PI      dd 3.1415926535897932384626433832795
.flt_minusPI dd -3.1415926535897932384626433832795
.flt_2PI     dd 6.283185307179586476925286766559

EditProc:
  cmp dword[esp+8],WM_CHAR
  jne .default
    mov eax,[esp+12]
    bt  dword[chars],eax
    jnc .quit
      cmp al,'.'
      jne .default
        invoke  SendMessageW,dword[esp+16],EM_GETSEL,0,0
        test    ax,ax
        je      .quit
          push    edi
          mov     edi,Temp
          invoke  SendMessageA,dword[esp+20],WM_GETTEXT,TSize,edi
          mov     ecx,eax
          mov     al,'.'
          repne   scasb
          pop     edi
          je .quit
  .default:
  jmp [defEditProc]
  .quit:
ret 16

PreviewProc:
  mov eax,[esp+8]
  cmp eax,WM_TIMER
  je .WM_TIMER
  cmp eax,WM_PAINT
  je .WM_PAINT
  cmp eax,WM_MOUSEMOVE
  je .WM_MOUSEMOVE
  cmp eax,WM_LBUTTONDOWN
  je .WM_LBUTTONDOWN
  cmp eax,WM_ERASEBKGND
  je  .quit
    jmp [DefWindowProcW]
        .WM_TIMER:invoke SendInput,1,input,28
                  mov    eax,[ToastyInc]
                  add    [ToastyPos],eax
        .WM_PAINT:invoke glClear,GL_COLOR_BUFFER_BIT
                  invoke glLoadMatrixf,Preview.MetricMat
                  invoke glColor3f,0,0,0
                  pushad
                  mov    ebx,[NumPoints]
                  mov    esi,[SortedPathsLen]
                  mov    edi,[NumPaths]
                  @@:sub    ebx,[esi+edi*4-4]
                     invoke glDrawArrays,GL_LINE_STRIP,ebx,dword[esi+edi*4-4]
                     dec    edi
                  jne @b
                  popad
                  invoke glColor3f,0,255.0,0
                  invoke glDrawArrays,GL_LINE_STRIP,0,[CurPoint]
                  invoke glColor3f,0,0,255.0
                  invoke glEnable,GL_LINE_STIPPLE
                  mov    eax,[NumPaths]
                  mov    edx,[NumPoints]
                  add    eax,eax
                  add    edx,117
                  invoke glDrawArrays,GL_LINES,edx,eax
                  invoke glDisable,GL_LINE_STIPPLE
                  test   [ActiveParams.Flags],FLAG_SHOW_VERTICES
                  je @f
                    invoke glDrawArrays,GL_POINTS,0,[NumPoints]
                  @@:
                  invoke glLoadMatrixf,Preview.PixelMat
                  invoke glColor3f,0,0,0
                  invoke glDrawArrays,GL_TRIANGLES,[NumPoints],117
                  invoke glRasterPos2i,[ToastyPos],-5
                  invoke glDrawPixels,128,128,GL_BGRA,GL_UNSIGNED_BYTE,ToastyBMP
                  invoke SwapBuffers,[Preview.DC]
                  invoke ValidateRect,dword[esp+8],0
                  ret 16
    .WM_MOUSEMOVE:test dword[esp+12],MK_LBUTTON
                  je @f
                    movd      xmm0,[esp+16]
                    pxor      xmm1,xmm1
                    punpcklwd xmm0,xmm1
                    cvtdq2ps  xmm0,xmm0
                    movsd     xmm2,qword[Preview.Width]
                    movsd     xmm3,qword[Preview.MetricMat+48]
                    movsd     xmm1,[MousePos]
                    movsd     [MousePos],xmm0
                    subps     xmm1,xmm0
                    divps     xmm1,xmm2
                    addps     xmm1,xmm1
                    addsubps  xmm3,xmm1
                    movsd     qword[Preview.MetricMat+48],xmm3
                    invoke    InvalidateRect,dword[esp+12],0,0
                  @@:
                  invoke SetFocus,dword[esp+4]
                  ret 16
  .WM_LBUTTONDOWN:movd      xmm0,[esp+16]
                  pxor      xmm1,xmm1
                  punpcklwd xmm0,xmm1
                  cvtdq2ps  xmm0,xmm0
                  movsd     [MousePos],xmm0
            .quit:ret 16

SyncExit: ;(lParam: dword);stdcall;
  invoke WaitForSingleObject,dword[esp+8],-1
  invoke ExitProcess,0

DlgProc: ;(wnd,msg,wParam,lParam: dword): dword;stdcall;
  mov eax,[esp+8]
  cmp eax,WM_MOUSEWHEEL
  je .WM_MOUSEWHEEL
  cmp eax,WM_SIZE
  je .WM_SIZE
  cmp eax,WM_COMMAND
  je .WM_COMMAND
  cmp eax,WM_INITDIALOG
  je .WM_INITDIALOG
  cmp eax,WM_CLOSE
  je .WM_CLOSE
  xor eax,eax
  ret 16
   .WM_INITDIALOG:pushad
                  stdcall LZMADecode,ToastyWAV,CompressedData
                  mov     ebp,[esp+36]
                  mov     [ofn.hwndOwner],ebp
                  mov     esi,CutterParams
                  mov     edi,ActiveParams
                  mov     ecx,sizeof.TCutterParams
                  rep     movsb
                  mov     ebx,hwnds.count
                  @@:invoke GetDlgItem,ebp,ebx
                     mov    [hwnds+ebx*4],eax
                     dec    ebx
                  jns @b

                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Сканируем COM-порты;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                  sub    esp,8
                  invoke SetupDiGetClassDevsW,GUID_SERENUM_BUS_ENUMERATOR,0,0,DIGCF_DEVICEINTERFACE+DIGCF_PRESENT
                  mov    ebx,eax
                  xor    edi,edi
                  mov    ebp,COMPorts
                  jmp .StartScan
                  .EnumDev:
                    mov    [DeviceInterfaceDetailData.cbSize],6
                    invoke SetupDiGetDeviceInterfaceDetailW,ebx,DeviceInterfaceData,DeviceInterfaceDetailData,sizeof.SP_DEVICE_INTERFACE_DETAIL_DATA_W,0,0
                    test   eax,eax
                    je .EnumIf
                      invoke  lstrcpyW,ebp,strGlobalRoot
                      lea     eax,[ebp+sizeof.strGlobalRoot-2]
                      invoke  SetupDiGetDeviceRegistryPropertyW,ebx,DeviceInfoData,SPDRP_PHYSICAL_DEVICE_OBJECT_NAME,0,eax,1024-sizeof.strGlobalRoot,0
                      invoke  SetupDiGetDeviceInstanceIdW,ebx,DeviceInfoData,InstanceID,sizeof.InstanceID,0
                      cinvoke wsprintfW,Temp,fmt_RegDeviceParameters,InstanceID
                      mov     word[Temp+eax*2],0
                      invoke  RegOpenKeyExW,HKEY_LOCAL_MACHINE,Temp,0,KEY_QUERY_VALUE,esp
                      lea     eax,[esp+4]
                      mov     dword[eax],TSize
                      invoke  RegQueryValueExW,dword[esp+20],strPortName,0,0,Temp,eax
                      invoke  RegCloseKey,dword[esp]
                      invoke  SendMessageW,[hwnds.Port_combo],CB_ADDSTRING,0,Temp
                      add     ebp,1024
                    .EnumIf:
                    invoke  SetupDiEnumDeviceInterfaces,ebx,DeviceInfoData,GUID_SERENUM_BUS_ENUMERATOR,esi,DeviceInterfaceData
                    inc     esi
                    test    eax,eax
                    jne .EnumDev
                    .StartScan:
                    invoke  SetupDiEnumDeviceInfo,ebx,edi,DeviceInfoData
                    inc     edi
                    xor     esi,esi
                    test    eax,eax
                  jne .EnumIf
                  invoke  SetupDiDestroyDeviceInfoList,ebx
                  invoke  SendMessageW,[hwnds.Port_combo],CB_ADDSTRING,0,strTCP
                  invoke  SendMessageW,[hwnds.Port_combo],CB_ADDSTRING,0,strFile
                  sub     ebp,COMPorts
                  shr     ebp,10
                  invoke  SendMessageW,[hwnds.Port_combo],CB_SETCURSEL,ebp,0
                  invoke  SendMessageW,[hwnds.Port_combo],CB_SELECTSTRING,-1,ActiveParams.Port
                  add     esp,8
                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                  invoke   SendMessageW,[hwnds.Init_edit],EM_LIMITTEXT,18,0
                  invoke   SendMessageW,[hwnds.Move_edit],EM_LIMITTEXT,2,0
                  invoke   SendMessageW,[hwnds.Cut_edit],EM_LIMITTEXT,2,0
                  invoke   SendMessageW,[hwnds.Delim_edit],EM_LIMITTEXT,1,0
                  invoke   SendMessageW,[hwnds.Term_edit],EM_LIMITTEXT,3,0
                  invoke   SendMessageW,[hwnds.End_edit],EM_LIMITTEXT,8,0
                  invoke   SendMessageW,[hwnds.HRes_edit],EM_LIMITTEXT,4,0
                  invoke   SendMessageW,[hwnds.VRes_edit],EM_LIMITTEXT,4,0
                  invoke   SendMessageW,[hwnds.Radius_edit],EM_LIMITTEXT,4,0
                  invoke   SendMessageW,[hwnds.AngleStep_edit],EM_LIMITTEXT,4,0
                  invoke   SendMessageW,[hwnds.IP_port],EM_LIMITTEXT,5,0
                  invoke   SetWindowLongW,[hwnds.Radius_edit],GWL_WNDPROC,EditProc
                  invoke   SetWindowLongW,[hwnds.AngleStep_edit],GWL_WNDPROC,EditProc
                  mov      [defEditProc],eax
                  mov      ebx,1
                  @@:movss     xmm0,[CutterParams.Radius+ebx*4]
                     cvttss2si eax,xmm0
                     cvtsi2ss  xmm1,eax
                     subss     xmm0,xmm1
                     mulss     xmm0,[flt_100]
                     cvtss2si  edx,xmm0
                     cinvoke   wsprintfW,Temp,fmt_u.u,eax,edx
                     invoke    SendMessageW,[hwnds.Radius_edit+ebx*8],WM_SETTEXT,0,Temp
                     dec       ebx
                 jns @b
                 invoke     SendMessageW,[hwnds.IP_addr],IPM_SETADDRESS,0,[CutterParams.IP]
                 movzx      eax,[CutterParams.TCPPort]
                 rol        ax,8
                 cinvoke    wsprintfW,Temp,fmt_u.u+6,eax
                 invoke     SendMessageW,[hwnds.IP_port],WM_SETTEXT,0,Temp
                 invoke     GetDC,[hwnds.Preview]
                 mov        [Preview.DC],eax
                 invoke     ChoosePixelFormat,eax,Preview.pfd
                 invoke     SetPixelFormat,[Preview.DC],eax,Preview.pfd
                 invoke     wglCreateContext,[Preview.DC]
                 mov        [Preview.RC],eax
                 invoke     wglMakeCurrent,[Preview.DC],[Preview.RC]
                 invoke     glEnableClientState,GL_VERTEX_ARRAY
                 invoke     glClearColor,1.0,1.0,1.0,0
                 invoke     glEnable,GL_LINE_SMOOTH
                 invoke     glLineStipple,2,$CCCC
                 invoke     wglGetProcAddress,glGenBuffers
                 mov        dword[glGenBuffers],eax
                 mov        esi,eax
                 invoke     wglGetProcAddress,glBindBuffer
                 mov        dword[glBindBuffer],eax
                 and        esi,eax
                 invoke     wglGetProcAddress,glBufferData
                 mov        dword[glBufferData],eax
                 test       esi,eax
                 mov        eax,ErrVideo
                 je Init.Error
                 invoke     glGenBuffers,1,vbo
                 invoke     glBindBuffer,GL_ARRAY_BUFFER,[vbo]
                 invoke     glVertexPointer,2,GL_FLOAT,0,0
                 invoke     glEnable,GL_POINT_SMOOTH
                 invoke     glPointSize,6.0
                 invoke     glEnable,GL_ALPHA_TEST
                 invoke     glAlphaFunc,GL_GREATER,0
                 invoke     WaitForSingleObject,[CurPoint],-1
                 mov        [CurPoint],0
                 mov        esi,-CuttersCount*sizeof.TCutter
                 @@:lea     eax,[Cutters+CuttersCount*sizeof.TCutter+esi]
                    invoke SendMessageA,[hwnds.Cutters_combo],CB_ADDSTRING,0,eax
                    add     esi,sizeof.TCutter
                 jne @b
                 movzx      eax,[CutterParams.ID]
                 invoke     SendMessageW,[hwnds.Cutters_combo],CB_SETCURSEL,eax,0
                 invoke     SetWindowLongW,[hwnds.Preview],GWL_WNDPROC,PreviewProc

                 movzx      esi,[CutterParams.Flags]
                 mov        eax,esi
                 and        eax,FLAG_KNIFE_ROTATE
                 invoke     SendMessageW,[hwnds.KnifeRotate_check],BM_SETCHECK,eax,0
                 mov        eax,esi
                 and        eax,FLAG_SHOW_VERTICES
                 invoke     SendMessageW,[hwnds.ShowVertices_check],BM_SETCHECK,eax,0
                 stdcall    DlgProc,0,WM_COMMAND,(CBN_SELCHANGE shl 16)+(hwnds.Port_combo-hwnds)/4,0
                 xor        ebx,ebx
                 cmp        [CutterParams.ID],CuttersCount-1
                 sete       bl
                 test       [CutterParams.Flags],FLAG_FLIP_X
                 jne .Flip
                 jmp .PathOptimize
  .WM_MOUSEWHEEL:movsx     eax,word[esp+14]
                 cvtsi2ss  xmm0,eax
                 movaps    xmm2,dqword[Preview.Width]
                 movaps    xmm3,dqword[Preview.MetricMat+48]
                 movaps    xmm4,dqword[flt_1]
                 movq      xmm5,qword[flt_neg-4]
                 mulss     xmm0,[.flt_1_480]
                 addss     xmm0,xmm4
                 shufps    xmm0,xmm0,0
                 sub       esp,16
                 invoke    GetWindowRect,[hwnds.Preview],esp
                 punpcklwd mm0,[esp+32]
                 psrld     mm0,16
                 psubd     mm0,[esp]
                 cvtpi2ps  xmm1,mm0
                 subps     xmm1,xmm2
                 addss     xmm1,xmm2
                 xorps     xmm1,xmm5
                 divps     xmm1,xmm2
                 addps     xmm1,xmm1
                 subps     xmm1,xmm3
                 subps     xmm1,xmm4
                 addps     xmm3,xmm1
                 mulps     xmm1,xmm0
                 subps     xmm3,xmm1
                 mulss     xmm0,[Preview.Scale]
                 movq      qword[Preview.MetricMat+48],xmm3
                 movss     [Preview.Scale],xmm0
                 emms
                 jmp      .Rescale
        .WM_SIZE:sub      esp,16
                 invoke   GetClientRect,dword[esp+24],esp
                 sub      dword[esp+8],230
                 cvtpi2ps xmm0,[esp+8]
                 movaps   xmm1,dqword[flt_2]
                 movaps   xmm3,dqword[flt_1]
                 movq     qword[Preview.Width],xmm0
                 divps    xmm1,xmm0
                 movss    [Preview.PixelMat],xmm1
                 movq     qword[Preview.PixelMat+16],xmm1
                 mov      [Preview.PixelMat+16],0
                 mulps    xmm1,dqword[flt_5]
                 subps    xmm1,xmm3
                 movq     qword[Preview.PixelMat+48],xmm1
                 test     [CurCoordSpace],FLAG_FLIP_X
                 je @f
                   movss  xmm1,[.flt_118]
                   divss  xmm1,xmm0
                   subss  xmm3,xmm1
                   movss  [Preview.PixelMat+48],xmm3
                 @@:
                 mov     esi,[esp+8]
                 invoke  glViewport,0,0,esi,dword[esp+12]
                 invoke  MoveWindow,[hwnds.Preview],0,0,esi,dword[esp+16],1
                 pushad
                 add      esi,5
                 invoke   MoveWindow,[hwnds.Cutters_combo],esi,5,225,15,1
                 mov      edi,330
                 mov      ebx,104
                 @@:invoke  MoveWindow,[hwnds+ebx+4],esi,edi,110,18,1
                    lea     eax,[esi+115]
                    invoke  MoveWindow,[hwnds+ebx+8],eax,edi,110,18,1
                    sub     edi,25
                    sub     ebx,8
                 jne @b
                 invoke  MoveWindow,[hwnds.DTR_check],esi,355,70,20,1
                 invoke  MoveWindow,[hwnds.IP_lbl],esi,360,20,20,1
                 add     esi,20
                 invoke  MoveWindow,[hwnds.IP_addr],esi,360,130,20,1
                 add     esi,33
                 mov     eax,[esp+44]
                 sub     eax,25
                 invoke  MoveWindow,[hwnds.Start_button],esi,eax,100,20,1
                 add     esi,5
                 invoke  MoveWindow,[hwnds.PortParams_button],esi,380,90,20,1
                 add     esi,17
                 invoke  MoveWindow,[hwnds.XON_check],esi,355,90,20,1
                 add     esi,80
                 invoke  MoveWindow,[hwnds.IP_delim],esi,360,10,20,1
                 add     esi,5
                 invoke  MoveWindow,[hwnds.RTS_check],esi,355,65,20,1
                 add     esi,5
                 invoke  MoveWindow,[hwnds.IP_port],esi,360,50,20,1
                 popad
                 .Rescale:
                 add     esp,16
                 movss   xmm0,[flt_2]
                 movss   xmm1,xmm0
                 divss   xmm0,[Preview.Width]
                 divss   xmm1,[Preview.Height]
                 mulss   xmm0,[Preview.Scale]
                 mulss   xmm1,[Preview.Scale]
                 mov     eax,[CurCoordSpace]
                 shl     eax,31
                 movd    xmm2,eax
                 xorps   xmm0,xmm2
                 movss   [Preview.MetricMat],xmm0
                 movss   [Preview.MetricMat+20],xmm1
                 invoke  InvalidateRect,[hwnds.Preview],0,0
                 mov     eax,1
                 ret 16
     .WM_COMMAND:cmp   word[esp+14],1 ;CBN_SELCHANGE, BN_CLICKED, STN_CLICKED, STN_DBLCLK
                 ja .quit
                   movzx eax,word[esp+12]
                   jmp   [.commands+eax*4]
                        .FlipX:
                       .Rotate:call GetCutterParams
                      .Cutters:pushad
                               invoke  SendMessageW,[hwnds.Cutters_combo],CB_GETCURSEL,0,0
                               mov     ebx,1
                               mov     [ActiveParams.ID],ax
                               cmp     eax,CuttersCount-1
                               je @f
                                 xor     ebx,ebx
                                 imul    eax,eax,sizeof.TCutter
                                 lea     esi,[Cutters.hres+eax]
                                 mov     edi,ActiveParams.hres
                                 mov     ecx,sizeof.TCutter-sizeof.TCutter.Name
                                 rep     movsb
                               @@:
                               movzx   eax,[ActiveParams.Flags]
                               xor     eax,[CurCoordSpace]
                               test    eax,FLAG_FLIP_X
                               je .noFlip
                                 .Flip:
                                 mov      eax,[NumPoints]
                                 mov      edx,[Points]
                                 cvtsd2ss xmm0,[CutWidth]
                                 @@:movss xmm1,xmm0
                                    subss xmm1,[edx+eax*8-8]
                                    movss [edx+eax*8-8],xmm1
                                    dec   eax
                                 jne @b
                                 .PathOptimize:
                                 divss  xmm0,[Preview.Width]
                                 addss  xmm0,xmm0
                                 mulss  xmm0,[Preview.Scale]
                                 mov    eax,[CurCoordSpace]
                                 shl    eax,31
                                 movd   xmm1,eax
                                 xorps  xmm0,xmm1
                                 addss  xmm0,[Preview.MetricMat+48]
                                 movss  [Preview.MetricMat+48],xmm0
                                 push   ebx
                                 mov    edx,[NumPaths]
                                 xorps  xmm0,xmm0
                                 movq   xmm3,qword[flt_exp_3]
                                 movq   xmm4,qword[flt_abs]
                                 xorps  xmm6,xmm6
                                 mov    edi,[SortedPoints]
                                 .loop1:movss  xmm5,[flt_inf]
                                        mov    ebx,[NumPaths]
                                        mov    ebp,[NumPoints]
                                        shl    ebp,3
                                        add    ebp,[Points]
                                        .loop2:mov  eax,[PathsLen]
                                               mov  eax,[eax+ebx*4-4]
                                               shl  eax,3
                                               add  ebp,eax
                                               test eax,eax
                                               js .skip
                                                 sub    ebp,eax
                                                 movsd  xmm1,[ebp-8]
                                                 sub    ebp,eax
                                                 comisd xmm1,[ebp]
                                                 je .loop3
                                                   mov eax,8
                                                 .loop3:movq     xmm1,[ebp+eax-8]
                                                        subps    xmm1,xmm0
                                                        shufps   xmm1,xmm1,1
                                                        comiss   xmm1,xmm6
                                                        jna @f
                                                          paddd    xmm1,xmm3        ;Прокрутка вперёд в 64 раза дороже
                                                        @@:
                                                        paddd    xmm1,xmm3          ;Прокрутка назад в 8 раз дороже (прибавляем к экспоненте 3)
                                                        andps    xmm1,xmm4
                                                        haddps   xmm1,xmm1
                                                        comiss   xmm1,xmm5
                                                        ja @f
                                                          movss xmm5,xmm1
                                                          mov   ecx,ebx
                                                          lea   esi,[ebp+eax-8]
                                                          mov   [esp-4],ebp
                                                        @@:
                                                        sub      eax,8
                                                 jne .loop3
                                               .skip:
                                               dec ebx
                                        jne .loop2
                                        mov      eax,[PathsLen]
                                        mov      ebp,[eax+ecx*4-4]
                                        neg      dword[eax+ecx*4-4]
                                        mov      eax,[SortedPathsLen]
                                        mov      [eax],ebp
                                        add      [SortedPathsLen],4
                                        mov      eax,[esp-4]
                                        lea      ecx,[eax+ebp*8]
                                        movsd    xmm1,[ecx-8]
                                        sub      ecx,esi
                                        shr      ecx,2
                                        mov      ebp,esi
                                        rep      movsd
                                        mov      ecx,ebp
                                        sub      ecx,eax
                                        comisd   xmm1,[eax]
                                        jne @f
                                          mov   ebx,8
                                          sub   edi,ebx
                                          movsd xmm7,[ebp]
                                          movsd [edi+ecx],xmm7
                                        @@:
                                        mov      esi,eax
                                        shr      ecx,2
                                        rep      movsd
                                        add      edi,ebx
                                        movq     xmm0,[edi-8]
                                        dec      edx
                                 jne .loop1
                                 mov ecx,[NumPaths]
                                 shl ecx,2
                                 sub [SortedPathsLen],ecx
                                 mov ebx,[PathsLen]
                                 mov eax,[NumPoints]
                                 shl eax,3
                                 add eax,[SortedPoints]
                                 mov edx,[InterconnectLines]
                                 mov esi,[SortedPathsLen]
                                 @@:mov    edi,[esi+ecx-4]
                                    shl    edi,3
                                    sub    eax,edi
                                    neg    dword[ebx+ecx-4]
                                    movups xmm0,[eax-8]
                                    movups [edx+ecx*4-16],xmm0
                                    sub    ecx,4
                                 jne @b
                                 movq [edx],xmm6
                                 pop  ebx
                               .noFlip:
                               movzx   eax,[ActiveParams.Flags]
                               and     eax,FLAG_FLIP_X+FLAG_SWAP_COORDS
                               mov     [CurCoordSpace],eax
                               mov     ecx,234
                               mul     ecx
                               lea     esi,[Axis+eax*4]
                               mov     edi,[AxisArrows]
                               rep     movsd
                               mov     eax,[NumPaths]
                               add     eax,eax
                               add     eax,[NumPoints]
                               lea     eax,[eax*8+234*4]
                               invoke  glBufferData,GL_ARRAY_BUFFER,eax,[SortedPoints],GL_STATIC_DRAW
                               invoke  SendMessageA,[hwnds.Init_edit],WM_SETTEXT,0,ActiveParams.Init
                               invoke  SendMessageA,[hwnds.Move_edit],WM_SETTEXT,0,ActiveParams.Move
                               invoke  SendMessageA,[hwnds.Cut_edit],WM_SETTEXT,0,ActiveParams.Cut
                               invoke  SendMessageA,[hwnds.Delim_edit],WM_SETTEXT,0,ActiveParams.Delim
                               invoke  SendMessageA,[hwnds.Term_edit],WM_SETTEXT,0,ActiveParams.Term
                               invoke  SendMessageA,[hwnds.End_edit],WM_SETTEXT,0,ActiveParams.End
                               movzx   eax,[ActiveParams.hres]
                               cinvoke wsprintfW,Temp,fmt_u.u+6,eax
                               invoke  defEditProc,[hwnds.HRes_edit],WM_SETTEXT,0,Temp
                               movzx   eax,[ActiveParams.vres]
                               cinvoke wsprintfW,Temp,fmt_u.u+6,eax
                               invoke  defEditProc,[hwnds.VRes_edit],WM_SETTEXT,0,Temp
                               movzx   edi,[ActiveParams.Flags]
                               mov     eax,edi
                               and     eax,FLAG_FLIP_X
                               invoke  SendMessageW,[hwnds.Flip_check],BM_SETCHECK,eax,0
                               mov     eax,edi
                               and     eax,FLAG_SWAP_COORDS
                               invoke  SendMessageW,[hwnds.Swap_check],BM_SETCHECK,eax,0
                               mov     esi,(hwnds.Swap_check-hwnds.Init_lbl)/4+1
                               @@:invoke EnableWindow,[hwnds.Init_lbl+esi*4],ebx
                                  dec     esi
                               jns @b
                               mov     eax,edi
                               and     eax,FLAG_DTR_DSR
                               invoke  SendMessageW,[hwnds.DTR_check],BM_SETCHECK,eax,0
                               mov     eax,edi
                               and     eax,FLAG_XON_XOFF
                               invoke  SendMessageW,[hwnds.XON_check],BM_SETCHECK,eax,0
                               mov     eax,edi
                               and     eax,FLAG_RTS_CTS
                               invoke  SendMessageW,[hwnds.RTS_check],BM_SETCHECK,eax,0
                               test    edi,FLAG_DTR_DSR+FLAG_XON_XOFF+FLAG_RTS_CTS
                               sete    al
                               or      bl,al
                               invoke  EnableWindow,[hwnds.DTR_check],ebx
                               invoke  EnableWindow,[hwnds.XON_check],ebx
                               invoke  EnableWindow,[hwnds.RTS_check],ebx
                               popad
                               jmp .WM_SIZE
                   .ShowPoints:call   GetCutterParams
                               invoke InvalidateRect,[hwnds.Preview],0,0
                               ret 16
                         .Port:pusha
                               invoke  SendMessageW,[hwnds.Port_combo],CB_GETCOUNT,0,0
                               lea     esi,[eax-2]
                               invoke  SendMessageW,[hwnds.Port_combo],CB_GETCURSEL,0,0
                               xor     ebx,ebx
                               mov     edi,eax
                               cmp     eax,esi
                               setb    bl
                               invoke  ShowWindow,[hwnds.DTR_check],ebx
                               invoke  ShowWindow,[hwnds.XON_check],ebx
                               invoke  ShowWindow,[hwnds.RTS_check],ebx
                               invoke  ShowWindow,[hwnds.PortParams_button],ebx
                               cmp     edi,esi
                               sete    bl
                               invoke  ShowWindow,[hwnds.IP_lbl],ebx
                               invoke  ShowWindow,[hwnds.IP_addr],ebx
                               invoke  ShowWindow,[hwnds.IP_delim],ebx
                               invoke  ShowWindow,[hwnds.IP_port],ebx
                               popa
                               ret 16
                   .PortParams:invoke SendMessageW,[hwnds.Port_combo],WM_GETTEXT,256,Temp
                               invoke GetDefaultCommConfigW,Temp,COMMConfig,COMMConfig.dwSize
                               invoke CommConfigDialogW,Temp,[hwnds.Port_combo],COMMConfig
                               invoke SetDefaultCommConfigW,Temp,COMMConfig,COMMConfig.dwSize
                               ret 16
                        .Start:cmp [CutterThread],0
                               jne @f
                                 call    GetCutterParams
                                 stdcall ShowControls,SW_HIDE
                                 invoke  SendMessageW,[hwnds.Start_button],WM_SETTEXT,0,strPause
                                 invoke  CreateThread,0,0,CutterProc,0,0,0
                                 mov     [CutterThread],eax
                                 ret 16
                               @@:
                               cmp [ThreadSuspended],0
                               je @f
                                 invoke SendMessageW,[hwnds.Start_button],WM_SETTEXT,0,strPause
                                 invoke ResumeThread,[CutterThread]
                                 mov    [ThreadSuspended],0
                                 ret 16
                               @@:
                               invoke SendMessageW,[hwnds.Start_button],WM_SETTEXT,0,strContinue
                               invoke SuspendThread,[CutterThread]
                               mov    [ThreadSuspended],1
                 .quit:ret 16
       .WM_CLOSE:call GetCutterParams
                 movq  xmm0,qword[ActiveParams.Radius]
                 mulps xmm0,dqword[flt_001]
                 movq  qword[ActiveParams.Radius],xmm0
                 mov   esi,CutterParams
                 mov   edi,ActiveParams
                 mov   ecx,sizeof.TCutterParams
                 repe  cmpsb
                 je @f
                    mov     esi,ActiveParams
                    mov     edi,CutterParams
                    mov     ecx,sizeof.TCutterParams
                    repe    movsb
                    invoke  CreateEventW,0,0,0,strToastyCut
                    invoke  CreateThread,0,0,SyncExit,eax,0,Temp
                    invoke  CoInitialize,0
                    invoke  CoCreateInstance,CorelCLSID,0,CLSCTX_LOCAL_SERVER,IID_IVGApplication,CorelApp
                    cominvk CorelApp,Get_GMSManager,GMSManager
                    cominvk GMSManager,RunMacro,strToastyCut,strSaveParams,PParams,Temp
                 @@:
                 invoke ExitProcess,0
.commands  dd .quit,.Cutters,.quit,.quit,.quit,.quit,.quit,.quit,.quit,.quit,.quit,.quit,.quit,.quit,.quit,.quit,.quit,.quit,.quit,.FlipX,.Rotate,.quit,.quit,.quit,.quit,.quit,.ShowPoints,.quit,.Port,.quit,.quit,.quit,.PortParams,.quit,.quit,.quit,.quit,.Start
.flt_1_480 dd 0.00208333333333333333333333333333 ;1/480
.flt_118   dd 118.0

Init: ;(lParam: dword);stdcall;
  pushad
  invoke  CoInitialize,0
  invoke  CLSIDFromProgID,CorelProgID,CorelCLSID
  test    eax,eax
  mov     eax,ErrNoCorel
  jne     .Error
  invoke  CoCreateInstance,CorelCLSID,0,CLSCTX_LOCAL_SERVER,IID_IVGApplication,CorelApp
  test    eax,eax
  mov     eax,ErrNoApp
  jne     .Error
  cominvk CorelApp,Get_SetupPath,SetupPath
  cinvoke wsprintfW,EXEFile,EXEPath,[SetupPath]
  mov     esi,eax
  add     eax,eax
  mov     [EXEFileLen],eax
  cinvoke wsprintfW,GMSFile,GMSPath,[SetupPath]
  mov     edi,eax
  invoke  GetFileAttributesW,EXEFile
  mov     ebx,eax
  invoke  GetFileAttributesW,GMSFile
  or      eax,ebx
  inc     eax
  jne .GetCorelData
    invoke MessageBoxW,0,strInstallToastyCut,strToastyCut,MB_YESNO
    cmp     eax,IDYES
    jne .Quit
      mov     word[GMSFile+edi*2-28],0
      invoke  CreateDirectoryW,GMSFile,0
      mov     word[GMSFile+edi*2-28],'\'
      mov     [EXEFile+esi*2-28],0
      invoke  CreateDirectoryW,EXEFile,0
      mov     [EXEFile+esi*2-28],'\'
      invoke  GetModuleFileNameW,0,Temp,TSize
      invoke  CopyFileW,Temp,EXEFile,0
      test    eax,eax
      mov     eax,ErrCopying
      je .Error
      stdcall LZMADecodeToFile,GMS,GMSFile,GMSSize
      test    eax,eax
      mov     eax,ErrCopying
      je .Error
      cominvk CorelApp,Set_Visible,1
      cominvk CorelApp,Get_CommandBars,CommandBars
      cominvk CommandBars,Add,strToastyCut,cuiBarTop,0,CommandBar
      cominvk CommandBars,Release
      cominvk CommandBar,Set_Visible,1
      cominvk CommandBar,Set_Enabled,1
      cominvk CommandBar,Get_Controls,Controls
      cominvk CommandBar,Release
      cominvk Controls,AddCustomButton,cdrCmdCategoryMacros,strMacroName,1,0,Control
      cominvk Controls,Release
      cominvk Control,Set_ToolTipText,strOutToPlotter
      cominvk Control,Set_Caption,strOutToPlotter
      cominvk CorelApp,Get_VersionMajor,Shape
      cmp     [Shape],17
      jae @f
        mov     dword[EXEFile+esi*2-6],6D0062h
        mov     dword[EXEFile+esi*2-2],70h
        stdcall LZMADecodeToFile,BMP,EXEFile,BMPSize
        cominvk Control,SetCustomIcon,EXEFile
        jmp .Finish
      @@:
        mov     dword[EXEFile+esi*2-6],630069h
        mov     dword[EXEFile+esi*2-2],6Fh
        stdcall LZMADecodeToFile,ICO,EXEFile,ICOSize
        cominvk Control,SetIcon2,EXEFile
      .Finish:
      cominvk CorelApp,Get_Version,Shape
      cinvoke wsprintfW,Temp,strSuccessInstall,[Shape]
      invoke  MessageBoxW,0,Temp,strToastyCut,0
      invoke  ExitProcess,0
  .GetCorelData:
  cominvk  CorelApp,Get_ActiveDocument,CorelDoc
  mov      eax,ErrNoDocument
  cmp      [CorelDoc],0
  je       .Error
  cominvk  CorelApp,Release
  cominvk  CorelDoc,BeginCommandGroup,0
  cominvk  CorelDoc,Set_Unit,cdrMillimeter
  cominvk  CorelDoc,Get_SelectionRange,Selection
  cominvk  Selection,Get_Count,OrigX
  mov      eax,ErrNoSelection
  cmp      dword[OrigX],0
  je       .Error
  cominvk  Selection,GetBoundingBox,OrigX,OrigY,CutWidth,CutHeight,0
  movapd   xmm0,dqword[CutWidth]
  mulpd    xmm0,dqword[dbl_100]
  movapd   dqword[CutWidth],xmm0
  cvtps2pd xmm1,qword[Preview.Width]
  divpd    xmm1,xmm0
  movhlps  xmm0,xmm1
  minsd    xmm0,xmm1
  cvtsd2ss xmm0,xmm0
  movss    [Preview.Scale],xmm0
  cominvk  Selection,UngroupAll
  cominvk  Selection,ConvertToCurves
  cominvk  Selection,Combine,Shape
  cmp      eax,[Shape]
  mov      eax,ErrCombine
  je       .Error
  cominvk  Selection,Release
  cominvk  Shape,Get_Curve,Curve
  cominvk  Shape,Release
  cominvk  Curve,Get_SubPaths,SubPaths
  cominvk  Curve,GetCurveInfo,CurveInfo
  cominvk  Curve,Release
  cominvk  SubPaths,Get_Count,NumPaths
  cominvk  SubPaths,Release
  invoke   GlobalMemoryStatus,memstatus
  call     [GetProcessHeap]
  mov      ebx,eax
  mov      edi,[memstatus.dwAvailVirtual]
  @@:mov     [memstatus.dwAvailVirtual],edi
     invoke  HeapAlloc,ebx,0,edi
     shr     edi,1
     test    eax,eax
  je @b
  add      [memstatus.dwAvailVirtual],eax
  mov      ebp,eax
  mov      [PathsLen],eax
  mov      edx,[NumPaths]
  lea      eax,[eax+edx*4]
  mov      [SortedPathsLen],eax
  lea      edi,[eax+edx*4]
  mov      [Points],edi
  mov      eax,[CurveInfo]
  mov      esi,[eax+SAFEARRAY.pvData]
  mov      eax,[eax+SAFEARRAY.rgsabound.cElements]
  shl      eax,5
  add      eax,esi
  jmp .start
  @@:mov edx,[esi+16] ;TCurveElement.ElementType
     jmp dword[.case+edx*4]
       .cdrElementStart:sub     ecx,edi
                        neg     ecx
                        shr     ecx,3
                        mov     [ebp],ecx
                        add     [NumPoints],ecx
                        add      ebp,4
                 .start:mov      ecx,edi
        .cdrElementLine:
       .cdrElementCurve:movupd   xmm0,[esi]
                        subpd    xmm0,dqword[OrigX]
                        mulpd    xmm0,dqword[dbl_100]
                        cvtpd2ps xmm0,xmm0
                        cmp      edi,[memstatus.dwAvailVirtual]
                        jae      .ErrNoRAM
                        movq     [edi],xmm0
                        add      edi,8
                        add      esi,32
                        cmp      esi,eax
                        jnae @b
                        jmp @f
     .cdrElementControl:movupd   xmm0,[esi-32*1]
                        movupd   xmm1,[esi+32*0]
                        movupd   xmm2,[esi+32*1]
                        movupd   xmm3,[esi+32*2]
                        movupd   xmm7,dqword[dbl_05]
                        call     Bezier2Polyline
                        movupd   xmm0,[esi+32*2]
                        subpd    xmm0,dqword[OrigX]
                        mulpd    xmm0,dqword[dbl_100]
                        cvtpd2ps xmm0,xmm0
                        cmp      edi,[memstatus.dwAvailVirtual]
                        jae      .ErrNoRAM
                        movq     [edi],xmm0
                        add      edi,8
                        add      esi,96
                        cmp      esi,eax
                        jnae @b
  @@:
  sub     edi,ecx
  shr     edi,3
  mov     [ebp],edi
  add     [NumPoints],edi
  mov     edi,[NumPoints]
  mov     eax,[Points]
  lea     eax,[eax+edi*8]
  mov     [SortedPoints],eax
  lea     eax,[eax+edi*8]
  mov     [AxisArrows],eax
  lea     eax,[eax+234*4]
  mov     [InterconnectLines],eax
  sub     eax,[PathsLen]
  imul    edi,[NumPaths],32
  lea     eax,[eax+edi]
  invoke  HeapReAlloc,ebx,HEAP_REALLOC_IN_PLACE_ONLY,[PathsLen],eax
  cominvk CorelDoc,EndCommandGroup
  cominvk CorelDoc,Undo,0
  cominvk CorelDoc,Release
  call    [CoUninitialize]
  popad
ret 4
.ErrNoRAM:
  mov    eax,ErrNoRAM
.Error:
  invoke MessageBoxW,0,eax,0,0
.Quit:
  invoke ExitProcess,0
.case dd .cdrElementStart,.cdrElementLine,.cdrElementCurve,.cdrElementControl

Bezier2Polyline:
 .P3 equ esp
 .Q2 equ esp+10h
 .R1 equ esp+20h
 .B  equ esp+30h

  sub     esp,40h
  movapd  xmm4,xmm0
  movupd  [.P3],xmm3
  addpd   xmm0,xmm1
  addpd   xmm1,xmm2
  addpd   xmm2,xmm3
  mulpd   xmm0,xmm7
  mulpd   xmm1,xmm7
  mulpd   xmm2,xmm7
  movapd  xmm5,xmm0
  movupd  [.Q2],xmm2
  addpd   xmm0,xmm1
  addpd   xmm1,xmm2
  mulpd   xmm0,xmm7
  mulpd   xmm1,xmm7
  movapd  xmm6,xmm0
  movupd  [.R1],xmm1
  addpd   xmm0,xmm1
  mulpd   xmm0,xmm7
  movupd  [.B],xmm0

  addpd   xmm3,xmm4
  mulpd   xmm3,xmm7
  subpd   xmm3,xmm0
  mulpd   xmm3,xmm3        ;
  haddpd  xmm3,xmm3        ;dppd    xmm3,xmm3,110011b
  comisd  xmm3,[precision]
  ja @f
    subpd    xmm0,dqword[OrigX]
    mulpd    xmm0,dqword[dbl_100]
    cvtpd2ps xmm0,xmm0
    cmp      edi,[memstatus.dwAvailVirtual]
    jae      Init.ErrNoRAM
    movq     [edi],xmm0
    add      edi,8
    add      esp,40h
    retn
  @@:

  movapd  xmm3,xmm0
  movapd  xmm0,xmm4
  movapd  xmm1,xmm5
  movapd  xmm2,xmm6
  call    Bezier2Polyline
  movupd  xmm0,[.B]
  movupd  xmm1,[.R1]
  movupd  xmm2,[.Q2]
  movupd  xmm3,[.P3]
  call    Bezier2Polyline

  add     esp,40h
retn

StrToUInt: ;(s: PAnsiChar): Cardinal;
  mov edx,eax
  xor eax,eax
  xor ecx,ecx
  jmp .s
  @@:lea  eax,[eax*4+eax]
     lea  eax,[eax*2+ecx-'0']
  .s:mov  cl,[edx]
     inc  edx
     cmp  cl,'0'
  jae @b
ret

StrToFloatU: ;(s: PAnsiChar): single;
  call     StrToUInt
  cvtsi2ss xmm0,eax
  test     cl,cl
  je @f
    mov      eax,edx
    mov      edi,edx
    call     StrToUInt
    sub      edx,edi
    cvtsi2ss xmm1,eax
    mulss    xmm1,dword[.scale+edx*4-8]
    addss    xmm0,xmm1
  @@:
ret
.scale dd 0.1,0.01,0.001,0.0001,0.00001,0.000001,0.0000001,0.00000001,0.000000001,0.0000000001

align 16
data import
include 'imports.inc'
end data

include 'VGCore.inc'
align 16
GUID_SERENUM_BUS_ENUMERATOR db 0x78,0xe9,0x36,0x4d,0x25,0xe3,0xce,0x11,0xbf,0xc1,0x08,0x00,0x2b,0xe1,0x03,0x18
dbl_05                      dq 0.5,0.5
dbl_100                     dq 100.0,100.0
flt_001                     dd 0.01,0.01
                            rd 2
flt_1                       dd 1.0,1.0
                            rd 2
flt_2                       dd 2.0,2.0
                            rd 2
flt_5                       dd 5.0,5.0
                            rd 2
flt_abs                     dd 7FFFFFFFh,7FFFFFFFh
                            dd 0
flt_neg                     dd 80000000h
precision                   dq 0.01
flt_100                     dd 100.0
flt_inf                     dd 7F800000h
Preview:
  .Width           dd 577.0
  .Height          dd 587.0
  .DC              rd 1
  .RC              rd 1
  .MetricMat       dd  1.0, 0.0, 0.0, 0.0,\
                       0.0, 1.0, 0.0, 0.0,\
                       0.0, 0.0, 1.0, 0.0,\
                      -1.0,-1.0, 0.0, 1.0
  .PixelMat        dd  1.0, 0.0, 0.0, 0.0,\
                       0.0, 1.0, 0.0, 0.0,\
                       0.0, 0.0, 1.0, 0.0,\
                      -1.0,-1.0, 0.0, 1.0
  .Scale           dd 1.0
  .pfd             PIXELFORMATDESCRIPTOR sizeof.PIXELFORMATDESCRIPTOR,1,PFD_SUPPORT_OPENGL+PFD_DRAW_TO_WINDOW+PFD_DOUBLEBUFFER,PFD_TYPE_RGBA,32
flt_exp_3                   dd 3 shl 23,0
memstatus                   MEMORYSTATUS sizeof.MEMORYSTATUS
CutterParamsArray           TSAFEARRAY VT_UI1,1,90h,1,1,CutterParams,sizeof.TCutterParams,0
ParamsData                  dd VT_ARRAY+VT_UI1,0,CutterParamsArray.SafeArr.cDims,0
Params                      SAFEARRAY 1,815h,16,0,ParamsData,1,0
PParams                     dd Params
align 2
                            dd 54
strSaveParams               du 'ThisMacroStorage.SaveParams',0
                            dd 72
strMacroName                du 'ToastyCut.ThisMacroStorage.ToastyCut',0
strInstallToastyCut         du 'Установить ToastyCut?',0
                            dd 18
strToastyCut                du 'ToastyCut',0
strStart                    du 'Пуск',0
strPause                    du 'Пауза',0
strContinue                 du 'Продолжить',0
strTCP                      du 'TCP/IP',0
strFile                     du 'Файл',0
strOutToPlotter             du 'Вывод на плоттер',0
strSuccessInstall           du 'ToastyCut успешно установлен в CorelDraw %s. Перезапустите CorelDraw и переместите панель ToastyCut в удобное для вас место.',0
strplt                      du 'plt',0,'*.PLT',0,0
strGlobalRoot               du '\\?\Global\GLOBALROOT',0
sizeof.strGlobalRoot = $-strGlobalRoot
strPortName                 du 'PortName',0
EXEPath                     du '%sprograms\addons\ToastyCut.exe',0
GMSPath                     du '%sDraw\GMS\ToastyCut.gms',0
CorelProgID                 du 'CorelDRAW.Application',0
ErrNoCorel                  du 'Интерфейс Corel Draw не зарегистрирован в системе.',0
ErrNoApp                    du 'Нет доступа к Corel Draw.',0
ErrCopying                  du 'Не удалось скопировать файлы в каталог Corel Draw.',0
ErrNoDocument               du 'Нет открытых документов в Corel Draw.',0
ErrNoSelection              du 'Ничего не выбрано.',0
ErrCombine                  du 'Не удалось объединить кривые.',0
ErrNoRAM                    du 'Не достаточно оперативной памяти.',0
ErrVideo                    du 'Видеокарта не поддерживает GL_ARB_VERTEX_BUFFER_OBJECT.',0
ErrCPU                      du 'Процессор не поддерживает SSE3.',0
fmt_RegDeviceParameters     du 'SYSTEM\ControlSet001\Enum\%s\Device Parameters',0
fmt_u.u                     du '%u.%u',0
fmt_ss                      db '%s%s',0
fmt_sisis                   db '%s%i%s%i%s',0
label glGenBuffers:         DWORD at $
                            db 'glGenBuffersARB',0
label glBindBuffer:         DWORD at $
                            db 'glBindBufferARB',0
label glBufferData:         DWORD at $
                            db 'glBufferDataARB',0
CompressedData:             file 'res\CompressedData.lzma'
GMS:                        file 'res\ToastyCut.gms.lzma'
ICO:                        file 'res\ToastyCut.ico.lzma'
BMP:                        file 'res\ToastyCut.bmp.lzma'
ToastyPos                   dd 1 shl 31-1
input                       dd 0,0,0,0,MOUSEEVENTF_MOVE,0,0
chars                       dq 3FF400000000100h,0,0,0
ofn                         OPENFILENAME sizeof.OPENFILENAME,0,0,strplt,0,0,0,Temp,TSize,0,0,0,0,0,0,0,strplt
wForm                       WAVEFORMATEX WAVE_FORMAT_PCM,1,8000,8000,1,8,0
hdr                         WAVEHDR ToastyWAV,WavSize
DeviceInfoData              SP_DEVINFO_DATA sizeof.SP_DEVINFO_DATA
DeviceInterfaceData         SP_DEVICE_INTERFACE_DATA sizeof.SP_DEVICE_INTERFACE_DATA
COMMConfig                  COMMCONFIG sizeof.COMMCONFIG,0,0,sizeof.DCB
align 16
CorelCLSID                  rq 2
OrigX                       rq 1
OrigY                       rq 1
CutWidth                    rq 1
CutHeight                   rq 1
Temp:                       rb 6295552
TSize=$-Temp
COMPorts                    rw 255*512
label hwnds:DWORD
  .Preview                  rd 1
  .Cutters_combo            rd 1
  .reserved                 rd 1
  .Init_lbl                 rd 1
  .Init_edit                rd 1
  .Move_lbl                 rd 1
  .Move_edit                rd 1
  .Cut_lbl                  rd 1
  .Cut_edit                 rd 1
  .Delim_lbl                rd 1
  .Delim_edit               rd 1
  .Term_lbl                 rd 1
  .Term_edit                rd 1
  .End_lbl                  rd 1
  .End_edit                 rd 1
  .HRes_lbl                 rd 1
  .HRes_edit                rd 1
  .VRes_lbl                 rd 1
  .VRes_edit                rd 1
  .Flip_check               rd 1
  .Swap_check               rd 1
  .Radius_lbl               rd 1
  .Radius_edit              rd 1
  .AngleStep_lbl            rd 1
  .AngleStep_edit           rd 1
  .KnifeRotate_check        rd 1
  .ShowVertices_check       rd 1
  .Port_lbl                 rd 1
  .Port_combo               rd 1
  .DTR_check                rd 1
  .XON_check                rd 1
  .RTS_check                rd 1
  .PortParams_button        rd 1
  .IP_lbl                   rd 1
  .IP_addr                  rd 1
  .IP_delim                 rd 1
  .IP_port                  rd 1
  .Start_button             rd 1
  .count=($-hwnds)/4
DeviceInterfaceDetailData   SP_DEVICE_INTERFACE_DETAIL_DATA_W
align 2
ActiveParams                TCutterParams
CorelApp                    IVGApplication
CorelDoc                    IVGDocument
Selection                   IVGShapeRange
Shape                       IVGShape
Curve                       IVGCurve
SubPaths                    IVGSubPaths
CommandBars                 ICUICommandBars
CommandBar                  ICUICommandBar
Controls                    ICUIControls
Control                     ICUIControl
GMSManager                  IVGGMSManager
vbo                         rd 1
CurveInfo                   rd 1
MousePos                    rq 1
SetupPath                   rd 1
EXEFileLen                  rd 1
defEditProc                 rd 1
PathsLen                    rd 1
SortedPathsLen              rd 1
Points                      rd 1
SortedPoints                rd 1
AxisArrows                  rd 1
InterconnectLines           rd 1
NumPoints                   rd 1
NumPaths                    rd 1
CurCoordSpace               rd 1
CurPoint                    rd 1
CutterThread                rd 1
ThreadSuspended             rd 1
ToastyInc                   rd 1
act_len                     rd 1
Write                       rd 1
EXEFile                     rw 1024
GMSFile                     rw 1024
InstanceID                  rw 1024
sizeof.InstanceID=$-InstanceID
ToastyWAV                   rb WavSize
ToastyBMP                   rb 65536
Axis                        rd 234*4
Cutters                     TCutter
                            rb (CuttersCount-1)*sizeof.TCutter