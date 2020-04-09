; ================================================================
; Deflemask2GB v3
; 2020 version because apparently people still care about this
; ================================================================

; ================================================================
; Includes
; ================================================================

	; system includes
	INCLUDE	"hardware.inc"

	; project includes
	INCLUDE	"Variables.asm"

; ================================================================
; Reset vectors (actual ROM starts here)
; ================================================================

SECTION	"Reset $00",ROM0[$00]
Reset00:	ret

SECTION	"Reset $08",ROM0[$08]
Reset08:	ret

SECTION	"Reset $10",ROM0[$10]
Reset10:	ret

SECTION	"Reset $18",ROM0[$18]
Reset18:	ret

SECTION	"Reset $20",ROM0[$20]
Reset20:	ret

SECTION	"Reset $28",ROM0[$28]
Reset28:	ret

SECTION	"Reset $30",ROM0[$30]
Reset30:	ret

SECTION	"Reset $38",ROM0[$38]
Reset38:	jp	Reset

; ================================================================
; Interrupt vectors
; ================================================================

SECTION	"VBlank interrupt",ROM0[$40]
IRQ_VBlank:
	reti

SECTION	"LCD STAT interrupt",ROM0[$48]
IRQ_STAT:
	reti

SECTION	"Timer interrupt",ROM0[$50]
IRQ_Timer:
	reti

SECTION	"Serial interrupt",ROM0[$58]
IRQ_Serial:
	reti

SECTION	"Joypad interrupt",ROM0[$60]
IRQ_Joypad:
	reti
	
; ================================================================
; ROM header
; ================================================================

SECTION	"ROM header",ROM0[$100]

EntryPoint:
	nop
	jp	Start

NintendoLogo:	; DO NOT MODIFY OR ROM WILL NOT BOOT!!!
	db	$ce,$ed,$66,$66,$cc,$0d,$00,$0b,$03,$73,$00,$83,$00,$0c,$00,$0d
	db	$00,$08,$11,$1f,$88,$89,$00,$0e,$dc,$cc,$6e,$e6,$dd,$dd,$d9,$99
	db	$bb,$bb,$67,$63,$6e,$0e,$ec,$cc,$dd,$dc,$99,$9f,$bb,$b9,$33,$3e

ROMTitle:		db	"DM HW PLAYER V3"	; ROM title (11 bytes)
GBCSupport:		db	0					; GBC support (0 = DMG only, $80 = DMG/GBC, $C0 = GBC only)
NewLicenseCode:	dw						; new license code (2 bytes)
SGBSupport:		db	0					; SGB support
CartType:		db	$19					; Cart type (MBC5)
ROMSize:		db						; ROM size (handled by post-linking tool)
RAMSize:		db	0					; RAM size
DestCode:		db	1					; Destination code (0 = Japan, 1 = All others)
OldLicenseCode:	db	$33					; Old license code (if $33, check new license code)
ROMVersion:		db	0					; ROM version
HeaderChecksum:	db						; Header checksum (handled by post-linking tool)
ROMChecksum:	dw						; ROM checksum (2 bytes) (handled by post-linking tool)


;******************************************************************************************************
;*	Program Start
;******************************************************************************************************

	SECTION "Program Start",ROM0[$0150]
Start:
	di
	ld	sp,$e000		;set the stack to $E000
	push	af
	call	ClearWRAM
	call	ClearVRAM
	pop	af
	
	and	a		; 1 = DMG/SGB, FF = GBP/SGB2, 11 = GBC/GBA
	cp	$11		; check if GBC flag is already set
	ld	a,0		; xor a can't be used since it changes the zero flag
	jr	nz,.noGBC
	inc	a
.noGBC
	ld	[GBCFlag],a
	ld	b,a
	ld	[GBAFlag],a
	
Reset:
	ld  a,$1f
	ld  [rROMB0],a

	ld  a,0
	ldh  [rLCDC],a		; disable LCD

	ld	hl,MainFont
	ld	bc,$10*$64
	ld	de,$8000
	call	LoadTiles

	ld  hl,MainScreenTilemap
	call	LoadMap

	ld	a,%10010001
	ldh	[rLCDC],a	; enable LCD
	
	ld  a,%11010010
	ld  [rBGP],a		; set BG palette
	
	; Load song data and initialize playback.
	call	InitDummy	; init routine

MainLoop:
	call	PlayDummy	; play routine
;	ei	; The play routine keeps disabling interrupts for some reason so we need to re-enable them
	ld	a,IEF_VBLANK
	ldh	[rIE],a
	halt
	jp	MainLoop

;***************************************************************
;* Subroutines
;***************************************************************

	SECTION "Support Routines",ROM0

; ================================================================
; Clear work RAM
; ================================================================

ClearWRAM:
	ld	hl,$c000
	ld	bc,$1ff0
	jr	ClearLoop	; routine continues in ClearLoop
	
; ================================================================
; Clear video RAM
; ================================================================

ClearVRAM:
	ld	hl,$8000
	ld	bc,$2000
	; routine continues in ClearLoop

; ================================================================
; Clear a section of RAM
; ================================================================
	
ClearLoop:
	xor	a
	ld	[hl+],a
	dec	bc
	ld	a,b
	or	c
	jr	nz,ClearLoop
	ret
	
; ================================================================

LoadTiles:						; WARNING: Do not use while LCD is on!
	ld	a,[hl+]						; get byte
	ld	[de],a						; write byte
	inc	de
	dec	bc
	ld	a,b							; check if bc = 0
	or	c
	jr	nz,LoadTiles				; if bc != 0, loop
	ret


LoadMap:
	ld	de,_SCRN0					; BG map address in VRAM
	ld	bc,$1214					; size of map (YX)
.loop:
	ld	a,[hl+]						; get tile ID
	ld	[de],a						; copy to BG map
	inc	de							; go to next tile
	dec	c
	jr	nz,.loop					; loop until current row has been completely copied
	ld	c,$14						; reset C
	ld	a,e
	add	$c							; go to next row
	jr	nc,.continue				; if carry isn't set, continue
	inc	d
.continue
	ld	e,a
	dec	b
	jr	nz,.loop					; loop until all rows have been copied
	ret

; Music data starts here.
; Note that the frontend code must fit within $500 bytes.

; Failsafe in case there is no music data to play.
SECTION	"Load routine failsafe",ROM0[$500]
LoadDummy:	ret
SECTION "Play routine failsafe",ROM0[$544]
PlayDummy:	ret
SECTION "Init routine failsafe",ROM0[$5EC]
InitDummy:	ret

SECTION "Graphics data",ROMX,BANK[$1F]
MainFont:	incbin  "Data/Font.bin"

MainScreenTilemap:
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	9,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,$a
	db	5,"DEFLEMASK HARDWARE",4
	db	5," PLAYER BY DEVED  ",4
	db	5,"                  ",4
	db	5,"NOW PLAYING:      ",4
	db	5,"SONG NAME HERE    ",4	; placeholder for song name (18 bytes, pad w/ spaces)
	db	5,"AUTHOR HERE       ",4	; placeholder for author name (18 bytes, pad w/ spaces) 
	db	$b,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,$c
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


; end of ROM
