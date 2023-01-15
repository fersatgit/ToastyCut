LZMADecodeToFile: ;(input: pointer; FileName: PWideChar; outSize: Cardinal): boolean;stdcall;
  invoke CreateFileW,dword[esp+32],GENERIC_READ+GENERIC_WRITE,0,0,CREATE_ALWAYS,0,0
  inc     eax
  je .quit
    dec     eax
    push    eax
    invoke  CreateFileMappingW,eax,0,PAGE_READWRITE,0,dword[esp+20],0
    push    eax
    invoke  MapViewOfFile,eax,FILE_MAP_READ+FILE_MAP_WRITE,0,0,dword[esp+20]
    push    eax
    stdcall LZMADecode,eax,dword[esp+16]
    call    [UnmapViewOfFile]
    call    [CloseHandle]
    call    [CloseHandle]
  .quit:
ret 12

;Code based on Ilya Kurdyukov source
;https://github.com/ilyakurdyukov/micro-lzmadec
lc        equ ebp-4
pb        equ ebp-8
lp        equ ebp-12
Code      equ ebp-16
Range     equ ebp-20
_rep0     equ dword[ebp-24]
_rep1     equ dword[ebp-28]
_rep2     equ dword[ebp-32]
_rep3     equ dword[ebp-36]
loc_rep   equ 36
_state    equ dword[ebp-40]
; src + 1+4+8+1+4
Src       equ dword[ebp+40]
Dest      equ dword[ebp+36]

_rc_bit:
  push    edx
  call    _rc_norm
  movzx   eax,word[Temp+esi*2]
  mov     edx,[Range]
  shr     edx,11
  imul    edx,eax        ; bound
  sub     [Range],edx
  sub     [Code],edx
  jae @f
    mov     [Range],edx
    add     [Code],edx
    cdq
    sub     eax, 2048-31
  @@:
  shr     eax,5          ; eax >= 0
  sub     [Temp+esi*2],ax
  neg     edx
  pop     edx
ret

_rc_norm:
  cmp     byte[Range+3], 0
  jne     @f
    shl     dword[Range], 8
    shl     dword[Code], 8
    mov     eax, Src
    mov     al, [eax]
    inc     Src
    mov     [Code], al
    @@:
ret

LZMADecode: ;(dst,src: pointer);stdcall;
        pushad
        mov     ebp,esp
        mov     edx,Src
        mov     edi,[edx+14]
        bswap   edi
        add     Src,18
        movzx   eax,byte[edx]
        cdq
        mov     ecx,9
        div     ecx
        push    edx     ;lc
        cdq
        mov     ecx,5
        div     ecx
        mov     ecx,edx
        mov     edx,1
        shl     edx,cl
        dec     edx
        mov     ecx,eax
        mov     eax,1
        shl     eax,cl
        dec     eax
        push    eax      ;pb
        push    edx      ;lp
        push    edi      ;Code
        push    -1       ;Range
        xor     eax, eax
        inc     eax
        push    eax
        push    eax
        push    eax
        push    eax
        mov     ecx,TSize/2
        mov     edi, Temp
        shl     eax, 10
        rep     stosw
        push    ecx             ; _state
        ; bh=4, but it doesn't matter
        xchg    ebx, eax        ; Prev = 0
_loop:  mov     ecx, Dest
        mov     bh,[lp]
_rel_lp:
        mov     esi,[esp]     ; _state
        and     bh, cl
        and     ecx,[pb]      ; posState
_rel_pb:
        shl     esi, 5          ; state * 16

        ; probs + state * 16 + posState
        lea     esi, [esi+ecx*2+64]
        call    _rc_bit
        cdq
        pop     eax
        jc      _case_rep
        mov     ecx,[lc]
        shl     ebx,cl
        mov     bl, 0
        lea     ecx, [ebx+ebx*2+2048]
_case_lit:
        lea     ebx, [edx+1]
        ; state = 0x546543210000 >> state * 4 & 15;
        ; state = state < 4 ? 0 : state - (state > 9 ? 6 : 3)
.4:     add     al, -3
        sbb     dl, dl
        and     al, dl
        cmp     al, 7
        jae     .4
        push    eax             ; _state
        cmp     al, 7-3
        jb      .2
        mov     bh, 1    ; offset
        mov     eax, Dest
        sub     eax, _rep0
        ; dl = -1, dh = 0, bl = 1
        xor     dl, [eax]
.1:     xor     dh, bl
        and     bh, dh
.2:     shl     edx, 1
        mov     esi, ebx
        and     esi, edx
        add     esi, ebx
        add     esi, ecx
        call    _rc_bit
        adc     bl, bl
        jnc     .1
        cdq     ; _len
        jmp     _copy.2

_case_rep:
        mov     ebx, esi
        lea     esi, [edx+eax*4+16]     ; IsRep
        add     al, -7
        sbb     al, al
        and     al, 3
        push    eax             ; _state
        call    _rc_bit
        jc      .2
        pop     eax             ; _state
        pop     ebx             ; r3
        pop     ebx             ; ebx = r2
        pop     esi             ; esi = r1
        push    _rep0           ; r1 = r0
        push    esi             ; r2 = r1
        push    ebx             ; r3 = r2
        push    eax             ; _state
        ; state = state < 7 ? 0 : 3
        mov     dl, 819/9       ; LenCoder
        jmp     _case_len

.2:     inc     esi
        call    _rc_bit
        jc      .3
        lea     esi, [ebx+1]    ; IsRep0Long
        call    _rc_bit
        jc      .5
        ; state = state < 7 ? 9 : 11
        or      _state, 9
        ; edx = 0, _len
        jmp     _copy.1

.3:     mov     dl, 3
        mov     ebx, _rep0
.6:     inc     esi
        dec     edx
        xchg    [ebp-loc_rep+edx*4], ebx
        je      .4
        call    _rc_bit
        jc      .6
.4:     mov     _rep0, ebx
.5:     ; state = state < 7 ? 8 : 11
        or      _state, 8
        mov     dl, 1332/9      ; RepLenCoder
_case_len:
        lea     esi, [edx*8+edx]
        cdq
        call    _rc_bit
        inc     esi
        lea     ebx, [esi+ecx*8]        ; +1 unnecessary
        mov     cl, 3
        jnc     .4
        inc     edx     ; edx = 8/8
        call    _rc_bit
        jnc     .3
        ; the first byte of BitTree tables is not used,
        ; so it's safe to add 255 instead of 256 here
        lea     ebx, [esi+127]
        mov     cl, 8
        add     edx, 16/8-(1 shl 8)/8      ; edx = -29
.3:     sub     ebx, -128       ; +128
.4:     ; BitTree
        mov     esi,1
.5:     push    esi
        add     esi, ebx
        call    _rc_bit
        pop     esi
        adc     esi, esi
        loop    .5
        lea     ebx, [esi+edx*8+2-8-1]
        cmp     _state, 4
        push    ebx     ; _len
        jae     _copy
_case_dist:
        add     _state,7
        sub     ebx,3+2-1
        sbb     eax,eax
        and     ebx,eax
        lea     ebx,[ebx*8+(432+16-128)/8+(3+2)*8]       ; PosSlot
        mov     edx,1
        ; BitTree
        @@:lea     esi, [edx+ebx*8]
           call    _rc_bit
           adc     edx, edx
           mov     ecx, edx
           sub     ecx, 1 shl 6
        jb @b
        mov     ebx,1
_case_model:
        cmp     ecx, 4
        jb      .9
        mov     esi, ebx
        shr     ecx, 1
        rcl     ebx, cl
        dec     ecx
        not     dl      ; 256-edx-1
        mov     dh, 2
        add     edx, ebx
;       lea     edx, [edx+ebx+688+16+64-256*3]  ; SpecPos
        cmp     ecx, 6
        jb      .4
.1:     dec     ecx
        call    _rc_norm
        shr     dword[Range], 1
        mov     edx,[Range]
        cmp     [Code],edx
        jb      .3
        sub     [Code],edx
        bts     ebx, ecx
.3:     cmp     ecx, 4
        jne     .1
        cdq             ; Align
.4:
        @@:push    esi
           add     esi, edx
           call    _rc_bit
           pop     esi
           adc     esi, esi
        loop @b
.6:     adc     ecx, ecx
        shr     esi, 1
        jne     .6
        add     ecx, ebx
.9:     inc     ecx
        mov     _rep0, ecx
        je      _end
_copy:  pop     edx
.1:     mov     eax, Dest
        sub     eax, _rep0
        movzx   ebx, byte [eax]
.2:     mov     eax, Dest
        mov     [eax], bl       ; Dict + Pos
        inc     Dest
        dec     edx
        jns     .1
        jmp     _loop
_end:   mov    esp,ebp
        popad
ret 8