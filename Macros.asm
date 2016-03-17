; ================
; Macros
; ================

IF      !DEF(INC_MACROS)
INC_MACROS  SET  1

DisableLCD:	MACRO
	xor	a	; faster than ld a,0
	ldh	[rLCDC],a	; turn off LCD
	ENDM

EnableLCD:	MACRO
	ld	a,%10000000+STATF_MODE01+STATF_VB
	ldh	[rLCDC],a	;turn on the LCD, BG, etc
	ENDM
	
SetVBlank:	MACRO
	ld	a,%10000000+STATF_MODE01+STATF_VB
	ldh	[rLCDC],a
	ENDM

SetHBlank:	MACRO
	ld	a,%10000000+STATF_MODE00+STATF_HB
	ldh	[rLCDC],a
	ENDM
	
CheckDMG:	MACRO
	ld	a,[GBCFlag]
	or a	; are we on DMG? (also applies to GB Pocket, GB Light, SGB, and SGB2)
	ENDM
	
break:		MACRO
	IF	(DEBUG_FLAG)
	ld	b,b
	ENDC
	ENDM
	
FUCK:	MACRO
	ld	b,b
	ld	a,$ff
	ld	hl,RST_00
.SHIT:
	ld	a,[hl+]
	jp	.SHIT
	ENDM
	
	ENDC
	ENDC	; ?