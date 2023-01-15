library kernel,'kernel32.dll',\
        user,'user32.dll',\
        gdi,'gdi32.dll',\
        ole,'ole32.dll',\
        OpenGL,'OpenGL32.dll',\
        SetupAPI,'SetupAPI',\
        comdlg,'comdlg32.dll',\
        AdvAPI,'Advapi32.dll',\
        Comctl,'Comctl32.dll',\
        wsock,'wsock32.dll',\
        winmm,'winmm.dll'

import kernel,\
       CreateFileW,'CreateFileW',\
       CreateFileMappingW,'CreateFileMappingW',\
       MapViewOfFile,'MapViewOfFile',\
       UnmapViewOfFile,'UnmapViewOfFile',\
       CloseHandle,'CloseHandle',\
       ExitThread,'ExitThread',\
       ExitProcess,'ExitProcess',\
       GlobalMemoryStatus,'GlobalMemoryStatus',\
       HeapAlloc,'HeapAlloc',\
       HeapReAlloc,'HeapReAlloc',\
       CreateThread,'CreateThread',\
       SuspendThread,'SuspendThread',\
       ResumeThread,'ResumeThread',\
       CreateEventW,'CreateEventW',\
       WaitForSingleObject,'WaitForSingleObject',\
       GetDefaultCommConfigW,'GetDefaultCommConfigW',\
       SetCommConfig,'SetCommConfig',\
       CommConfigDialogW,'CommConfigDialogW',\
       GetLastError,'GetLastError',\
       FormatMessageW,'FormatMessageW',\
       GetFileAttributesW,'GetFileAttributesW',\
       CopyFileW,'CopyFileW',\
       WriteFile,'WriteFile',\
       CreateDirectoryW,'CreateDirectoryW',\
       GetModuleFileNameW,'GetModuleFileNameW',\
       GetProcessHeap,'GetProcessHeap',\
       lstrlenA,'lstrlenA',\
       lstrcpyW,'lstrcpyW',\
       Sleep,'Sleep'

import user,\
       DefWindowProcW,'DefWindowProcW',\
       SetWindowLong,'SetWindowLong',\
       SetTimer,'SetTimer',\
       KillTimer,'KillTimer',\
       GetDC,'GetDC',\
       wsprintfA,'wsprintfA',\
       wsprintfW,'wsprintfW',\
       GetDlgItem,'GetDlgItem',\
       GetWindowRect,'GetWindowRect',\
       GetClientRect,'GetClientRect',\
       MoveWindow,'MoveWindow',\
       EnableWindow,'EnableWindow',\
       ShowWindow,'ShowWindow',\
       SetWindowLongW,'SetWindowLongW',\
       ValidateRect,'ValidateRect',\
       MessageBoxW,'MessageBoxW',\
       InvalidateRect,'InvalidateRect',\
       SendMessageA,'SendMessageA',\
       SendMessageW,'SendMessageW',\
       SetFocus,'SetFocus',\
       SendInput,'SendInput',\
       DialogBoxParamW,'DialogBoxParamW'

import gdi,\
       ChoosePixelFormat,'ChoosePixelFormat',\
       SetPixelFormat,'SetPixelFormat',\
       SwapBuffers,'SwapBuffers'

import ole,\
       CoInitialize,'CoInitialize',\
       CoUninitialize,'CoUninitialize',\
       CLSIDFromProgID,'CLSIDFromProgID',\
       CoCreateInstance,'CoCreateInstance'

import OpenGL,\
       wglGetProcAddress,'wglGetProcAddress',\
       wglMakeCurrent,'wglMakeCurrent',\
       wglCreateContext,'wglCreateContext',\
       glClear,'glClear',\
       glLoadMatrixf,'glLoadMatrixf',\
       glColor3f,'glColor3f',\
       glVertexPointer,'glVertexPointer',\
       glDrawArrays,'glDrawArrays',\
       glClearColor,'glClearColor',\
       glEnable,'glEnable',\
       glDisable,'glDisable',\
       glViewport,'glViewport',\
       glPointSize,'glPointSize',\
       glLineStipple,'glLineStipple',\
       glEnableClientState,'glEnableClientState',\
       glDrawPixels,'glDrawPixels',\
       glLoadIdentity,'glLoadIdentity',\
       glRasterPos2i,'glRasterPos2i',\
       glRasterPos2f,'glRasterPos2f',\
       glAlphaFunc,'glAlphaFunc'

import SetupAPI,\
       SetupDiGetClassDevsW,'SetupDiGetClassDevsW',\
       SetupDiGetDeviceInterfaceDetailW,'SetupDiGetDeviceInterfaceDetailW',\
       SetupDiGetDeviceRegistryPropertyW,'SetupDiGetDeviceRegistryPropertyW',\
       SetupDiGetDeviceInstanceIdW,'SetupDiGetDeviceInstanceIdW',\
       SetupDiEnumDeviceInterfaces,'SetupDiEnumDeviceInterfaces',\
       SetupDiEnumDeviceInfo,'SetupDiEnumDeviceInfo',\
       SetupDiDestroyDeviceInfoList,'SetupDiDestroyDeviceInfoList'

import comdlg,\
       GetSaveFileNameW,'GetSaveFileNameW'

import AdvAPI,\
       RegOpenKeyExW,'RegOpenKeyExW',\
       RegQueryValueExW,'RegQueryValueExW',\
       RegCloseKey,'RegCloseKey'

import Comctl,\
       InitCommonControls,'InitCommonControls'

import wsock,\
       WSAStartup,'WSAStartup',\
       WSAGetLastError,'WSAGetLastError',\
       socket,'socket',\
       connect,'connect',\
       closesocket,'closesocket',\
       send,'send'

import winmm,\
       waveOutOpen,'waveOutOpen',\
       waveOutPrepareHeader,'waveOutPrepareHeader',\
       waveOutUnprepareHeader,'waveOutUnprepareHeader',\
       waveOutWrite,'waveOutWrite',\
       waveOutClose,'waveOutClose'












