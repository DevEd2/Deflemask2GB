;********************************************************************************************************
;*	Deflemask2GB v2
;********************************************************************************************************

; Debug flag
; If set to 1, enable debugging features.
DEBUG_FLAG	SET 1

;******************************************************************************************************
;*	Includes
;******************************************************************************************************

	; system includes
	INCLUDE	"hardware.inc"

	; project includes
    INCLUDE	"Variables.asm"

;******************************************************************************************************
;*	cartridge header
;******************************************************************************************************

	SECTION	"Org $00",HOME[$00]
RST_00:	
	jp	$100

	SECTION	"Org $08",HOME[$08]
RST_08:	
	jp	$100

	SECTION	"Org $10",HOME[$10]
RST_10:
	jp	$100

	SECTION	"Org $18",HOME[$18]
RST_18:
	jp	$100

	SECTION	"Org $20",HOME[$20]
RST_20:
	jp	$100

	SECTION	"Org $28",HOME[$28]
RST_28:
	jp	$100

	SECTION	"Org $30",HOME[$30]
RST_30:
	jp	$100

	SECTION	"Org $38",HOME[$38]
RST_38:
	ret	; because reasons

	SECTION	"V-Blank IRQ Vector",HOME[$40]
VBL_VECT:
	call	VBlank
	reti
	
	SECTION	"LCD IRQ Vector",HOME[$48]
LCD_VECT:
	reti

	SECTION	"Timer IRQ Vector",HOME[$50]
TIMER_VECT:
	reti

	SECTION	"Serial IRQ Vector",HOME[$58]
SERIAL_VECT:
	reti

	SECTION	"Joypad IRQ Vector",HOME[$60]
JOYPAD_VECT:
	reti

    SECTION	"Start",HOME[$100]
	nop
	jp	Start

	; $0104-$0133 (Nintendo logo - do _not_ modify the logo data here or the GB will not run the program)
	nintendoLogo

	; $0134-$013E (Game title - up to 11 upper case ASCII characters; pad with $00)
	;	 ---------------
	db	"DM HW PLAYER   "

	; $0143 (Game Boy Color compatibility code)
	db	$00	; $00 - DMG 
			; $80 - DMG/GBC
			; $C0 - GBC Only cartridge

	; $0144 (High-nibble of license code - normally $00 if $014B != $33)
	db	0

	; $0145 (Low-nibble of license code - normally $00 if $014B != $33)
	db	0

	; $0146 (Game Boy/Super Game Boy indicator)
	db	0

	; $0147 (Cartridge type - all Game Boy Color cartridges are at least $19)
	db	$19	; $19 - MBC5

	; $0148 (ROM size)
	db	$3	; $3 = 256Kb (16 banks)
    ; Music data takes up a total of 11 banks so we should specify 16 banks

	; $0149 (RAM size)
	db	0	; $00 - None

	; $014A (Destination code)
	db	1	; $01 - All others
			; $00 - Japan

	; $014B (Licensee code - this _must_ be $33)
	db	$33	; $33 - Check $0144/$0145 for Licensee code.

	; $014C (Mask ROM version)
	db	0

	; $014D (Complement check - handled by post-linking tool)
	db	0
	
	; $014E-$014F (Cartridge checksum - handled by post-linking tool)
	dw	0


;******************************************************************************************************
;*	Program Start
;******************************************************************************************************

	SECTION "Program Start",HOME[$0150]
Start:
	di
	and	a	; 1 = DMG/SGB, FF = GBP/SGB2, 11 = GBC/GBA
	cp	$11	; check if GBC flag is already set
	ld	a,0	; xor a can't be used since it changes the zero flag
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
    ldh  [rLCDC],a   ; disable LCD

    call ClearMap
    ld	hl,MainFont
	ld	bc,$10*$64
	call	LoadTiles

    ld  hl,MainScreenTilemap
    call    LoadMap

    ld	a,%10000000+STATF_MODE01+STATF_VB
	ldh	[rLCDC],a	; enable LCD
    
    ld  a,%11010010
    ld  [rBGP],a
    
    ld	sp,$E000	;set the stack to $E000
    ; Load song data and init playback

    ld  a,1
    ld  [SoundEnabled],a

    call    $500
    call    $5ec

    ; Main loop
MainLoop:
    call    $544
    call    VBlank
    jp      MainLoop

;***************************************************************
;* Subroutines
;***************************************************************

	SECTION "Support Routines",HOME

VBlank:
	ldh	a,[rLY]		;get current scanline
	cp	$91			;Are we in v-blank yet?
	jr	nz,VBlank	;if A !=91 then MainLoop
	ret

	include	"SystemRoutines.asm"

ClearMap:
    ld	hl,_SCRN0		;loads the address of the bg map ($9800) into HL
    ld	bc,32*32		;since we have 32x32 tiles, we'll need a counter so we can clear all of them
.loop:
    xor	a
    ld	[hl+],a		; load A into HL, then increment HL (the HL+)
    dec	bc			; decrement our counter
    ld	a,b			; load B into A
    or	c			; if B or C != 0
    jr	nz,.loop	; then loop
    ret				; done

LoadTiles:
    ld	de,_VRAM
.loop:
    ld	a,[hl+]     ; get a byte from our tiles, and increment.
    ld	[de],a      ; put that byte in VRAM and
    inc	de          ; increment.
    dec	bc          ; bc=bc-1.
    ld	a,b         ; load B into A
    or	c           ; if B or C != 0
    jr	nz,.loop	; then loop.
    ret             ; done


LoadMap:
    ld	de,_SCRN0	;where our map goes
    ld	b,$12
    ld	c,$14
.loop:
    ld	a,[hl+]	; get a byte of the map and inc hl
    ld	[de],a	; put the byte at de
    inc	de      ; increment de
    dec	c		; decrement our counter
    jr	nz,.loop
    ld	c,$14
    rept	12
    inc	de
    endr
    dec	b
    jr	nz,.loop	; and of the counter != 0 then MainLoop
    ret             ; done

; Music data starts here.
; Note that the frontend code must fit within $500 bytes.

; Failsafe in case there is no music data to play.
SECTION	"Load routine failsafe",HOME[$500]
LoadDummy:	ret
SECTION "Play routine failsafe",HOME[$544]
PlayDummy:	ret
SECTION "Init routine failsafe",HOME[$5EC]
InitDummy:	ret

SECTION "Graphics data",ROMX,BANK[$1F]
MainFont:           incbin  "Data/Font.bin"

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
	db	5,"SONG NAME HERE    ",4    ; placeholder for song name (18 bytes, pad w/ spaces)
	db	5,"AUTHOR HERE       ",4    ; placeholder for author name (18 bytes, pad w/ spaces) 
	db	$b,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,$c
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


; end of ROM