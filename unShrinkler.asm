_src	equ	unshrinkler_zp
_dst	equ	unshrinkler_zp+2
_copy	equ	unshrinkler_zp+4
_tabs	equ	unshrinkler_zp+4
_number	equ	unshrinkler_zp+6
_Cp	equ	unshrinkler_zp+8
_d2	equ	unshrinkler_zp+10
_d3	equ	unshrinkler_zp+12
_lit	equ	unshrinkler_zp+14
_xH	equ	unshrinkler_zp+15

	ert	[unshrinkler_data&$ff]!=0
probs	equ	unshrinkler_data
probs_ref	equ	unshrinkler_data+$200
probs_length	equ	unshrinkler_data+$200
probs_offset	equ	unshrinkler_data+$400

	org	unshrinkler
	ldx	#>[unshrinkler_data+$500]
	lda	#1
	sta	_d3
	lsr	@
	sta	_d3+1
	sta	_tabs
	tay
unshrinkler_initPage
	stx	_tabs+1
unshrinkler_initByte
	sta	(_tabs),y
	iny
	bne	unshrinkler_initByte
	sta	_lit	; eventually $80
	eor	#$80
	dex
	cpx	#>unshrinkler_data
	bcs	unshrinkler_initPage

unshrinkler_literal
	inc	_tabs	; #1
unshrinkler_literalBit
	jsr	unshrinkler_getBit
	rol	_tabs
	bcc	unshrinkler_literalBit

	lda	_tabs
	sta	(_dst),y
	inc	_dst
	bne	unshrinkler_storeSamePage
	inc	_dst+1
unshrinkler_storeSamePage
	jsr	unshrinkler_getKind
	bcc	unshrinkler_literal

	lda	#>probs_ref
	jsr	unshrinkler_getBitFrom
	bcc	unshrinkler_readOffset

unshrinkler_readLength
	lda	#>probs_length
	jsr	unshrinkler_getNumber
	lda	#$ff
unshrinkler_offsetL	equ	*-1
	adc	_dst	; C=0
	sta	_copy
	lda	#$ff
unshrinkler_offsetH	equ	*-1
	adc	_dst+1
	sta	_copy+1

	ldx	_number+1
	beq	unshrinkler_copyRemainder
unshrinkler_copyPage
	lda	(_copy),y
	sta	(_dst),y
	iny
	bne	unshrinkler_copyPage
	inc	_copy+1
	inc	_dst+1
	dex
	bne	unshrinkler_copyPage

unshrinkler_copyRemainder
	ldx	_number
	beq	unshrinkler_copyDone
unshrinkler_copyByte
	lda	(_copy),y
	sta	(_dst),y
	iny
	dex
	bne	unshrinkler_copyByte
	tya
	clc
	adc	_dst
	sta	_dst
	bcc	unshrinkler_copySamePage
	inc	_dst+1
unshrinkler_copySamePage
	ldy	#0

unshrinkler_copyDone
	jsr	unshrinkler_getKind
	bcc	unshrinkler_literal

unshrinkler_readOffset
	lda	#>probs_offset
	jsr	unshrinkler_getNumber
	lda	#$03
	sbc	_number	; C=0
	sta	unshrinkler_offsetL
	tya
	sbc	_number+1
	sta	unshrinkler_offsetH
	bcc	unshrinkler_readLength
	rts	; finish

unshrinkler_getNumber
	sta	_tabs+1
unshrinkler_getNumberCount
	inc	_tabs
	inc	_tabs
	jsr	unshrinkler_getBit
	bcs	unshrinkler_getNumberCount

	sty	_number+1
	lda	#$01
	sta	_number

unshrinkler_getNumberBit
	dec	_tabs
	jsr	unshrinkler_getBit
	rol	_number
	rol	_number+1
	dec	_tabs
	bne	unshrinkler_getNumberBit
	rts

unshrinkler_getKind
	sty	_tabs
	lda	#>probs
unshrinkler_getBitFrom
	sta	_tabs+1
	bne	unshrinkler_getBit	; always

unshrinkler_readBit
	asl	_d3
	rol	_d3+1
	asl	_lit
	bne	unshrinkler_gotBit
	lda	(_src),y
	inc	_src
	bne	unshrinkler_readSamePage
	inc	_src+1
unshrinkler_readSamePage
	rol	@	; C=1
	sta	_lit
unshrinkler_gotBit
	rol	_d2
	rol	_d2+1

unshrinkler_getBit
	lda	_d3+1
	bpl	unshrinkler_readBit
	lda	(_tabs),y
	sta	_Cp+1
	lsr	@
	sta	_xH
	inc	_tabs+1
	lda	(_tabs),y
	sta	_Cp
	ror	@
	lsr	_xH
	ror	@
	lsr	_xH
	ror	@
	lsr	_xH
	ror	@
	eor	#$ff
	sec
	adc	_Cp
	sta	(_tabs),y
	lda	_Cp+1
	sbc	_xH
	pha

	tya
	sty	_xH
	ldy	#$10
unshrinkler_mulLoop
	asl	@
	rol	_xH
	rol	_Cp
	rol	_Cp+1
	bcc	unshrinkler_mulNext
	clc
	adc	_d3
	tax
	lda	_xH
	adc	_d3+1
	sta	_xH
	txa
	bcc	unshrinkler_mulNext
	inc	_Cp
	bne	unshrinkler_mulNext
	inc	_Cp+1
unshrinkler_mulNext
	dey
	bne	unshrinkler_mulLoop

	lda	_d2
	sec
	sbc	_Cp
	tax
	lda	_d2+1
	sbc	_Cp+1
	bcs	unshrinkler_zero

	lda	(_tabs),y
	sbc	#0	; C=0
	sta	(_tabs),y
	pla
	sbc	#$F0
	pha
	lda	_Cp
	sta	_d3
	lda	_Cp+1
	sec
	bcs	unshrinkler_retBit	; always

unshrinkler_zero
	stx	_d2
	sta	_d2+1
	lda	_d3
	sbc	_Cp	; C=1
	sta	_d3
	lda	_d3+1
	sbc	_Cp+1
	clc

unshrinkler_retBit
	sta	_d3+1
	dec	_tabs+1
	pla
	sta	(_tabs),y
	rts
