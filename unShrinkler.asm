unshrinkler_src	equ	unshrinkler_zp
unshrinkler_dst	equ	unshrinkler_zp+2
unshrinkler_copy	equ	unshrinkler_zp+4
unshrinkler_factor	equ	unshrinkler_zp+4
unshrinkler_tabs	equ	unshrinkler_zp+6
unshrinkler_number	equ	unshrinkler_zp+8
unshrinkler_cp	equ	unshrinkler_zp+10
unshrinkler_d2	equ	unshrinkler_zp+12
unshrinkler_d3	equ	unshrinkler_zp+14
unshrinkler_srcBits	equ	unshrinkler_zp+16
unshrinkler_tmpH	equ	unshrinkler_zp+17

unshrinkler_probs	equ	unshrinkler_data
unshrinkler_probsRef	equ	unshrinkler_data+$200
unshrinkler_probsLength	equ	unshrinkler_data+$200
unshrinkler_probsOffset	equ	unshrinkler_data+$400

	org	unshrinkler

	ldx	#>[unshrinkler_data+$500]
	ldy	#1
	sty	unshrinkler_d3
	dey
	sty	unshrinkler_d3+1
	ift	[unshrinkler_data&$ff]==0
	sty	unshrinkler_tabs
	els
	lda	#<unshrinkler_data
	sta	unshrinkler_tabs
	eif
	tya
unshrinkler_initPage
	stx	unshrinkler_tabs+1
unshrinkler_initByte
	sta	(unshrinkler_tabs),y
	iny
	bne	unshrinkler_initByte
	sta	unshrinkler_srcBits	; eventually $80
	eor	#$80
	dex
	cpx	#>unshrinkler_data
	bcs	unshrinkler_initPage
	tax	; #0

unshrinkler_literal
	ldy	#1
unshrinkler_literalBit
	jsr	unshrinkler_getBit
	tya
	rol	@
	tay
	bcc	unshrinkler_literalBit

	sta	(unshrinkler_dst,x)	; X=0
	inc	unshrinkler_dst
	bne	unshrinkler_storeSamePage
	inc	unshrinkler_dst+1
unshrinkler_storeSamePage
	jsr	unshrinkler_getKind
	bcc	unshrinkler_literal

	lda	#>unshrinkler_probsRef
	jsr	unshrinkler_getBitFrom
	bcc	unshrinkler_readOffset

unshrinkler_readLength
	lda	#>unshrinkler_probsLength
	jsr	unshrinkler_getNumber
	lda	#$ff
unshrinkler_offsetL	equ	*-1
	adc	unshrinkler_dst	; C=0
	sta	unshrinkler_copy
	lda	#$ff
unshrinkler_offsetH	equ	*-1
	adc	unshrinkler_dst+1
	sta	unshrinkler_copy+1

	ldx	unshrinkler_number+1
	beq	unshrinkler_copyRemainder
unshrinkler_copyPage
	lda	(unshrinkler_copy),y
	sta	(unshrinkler_dst),y
	iny
	bne	unshrinkler_copyPage
	inc	unshrinkler_copy+1
	inc	unshrinkler_dst+1
	dex
	bne	unshrinkler_copyPage

unshrinkler_copyRemainder
	ldx	unshrinkler_number
	beq	unshrinkler_copyDone
unshrinkler_copyByte
	lda	(unshrinkler_copy),y
	sta	(unshrinkler_dst),y
	iny
	dex
	bne	unshrinkler_copyByte
	tya
	clc
	adc	unshrinkler_dst
	sta	unshrinkler_dst
	bcc	unshrinkler_copyDone
	inc	unshrinkler_dst+1

unshrinkler_copyDone
	jsr	unshrinkler_getKind
	bcc	unshrinkler_literal

unshrinkler_readOffset
	lda	#>unshrinkler_probsOffset
	jsr	unshrinkler_getNumber
	lda	#3
	sbc	unshrinkler_number	; C=0
	sta	unshrinkler_offsetL
	tya	; #0
	sbc	unshrinkler_number+1
	sta	unshrinkler_offsetH
	bcc	unshrinkler_readLength
	rts	; finish

unshrinkler_getNumber
	sta	unshrinkler_tabs+1
	lda	#1
	sta	unshrinkler_number
	sty	unshrinkler_number+1	; #0
unshrinkler_getNumberCount
	iny
	iny
	jsr	unshrinkler_getBit
	bcs	unshrinkler_getNumberCount

unshrinkler_getNumberBit
	dey
	jsr	unshrinkler_getBit
	rol	unshrinkler_number
	rol	unshrinkler_number+1
	dey
	bne	unshrinkler_getNumberBit
	rts

unshrinkler_getKind
	ldy	#0
	lda	#>unshrinkler_probs
unshrinkler_getBitFrom
	sta	unshrinkler_tabs+1
	bne	unshrinkler_getBit	; always

unshrinkler_readBit
	asl	unshrinkler_d3
	rol	unshrinkler_d3+1
	asl	unshrinkler_srcBits
	bne	unshrinkler_gotBit
	lda	(unshrinkler_src,x)	; X=0
	inc	unshrinkler_src
	bne	unshrinkler_readSamePage
	inc	unshrinkler_src+1
unshrinkler_readSamePage
	rol	@	; C=1
	sta	unshrinkler_srcBits
unshrinkler_gotBit
	rol	unshrinkler_d2
	rol	unshrinkler_d2+1

unshrinkler_getBit
	lda	unshrinkler_d3+1
	bpl	unshrinkler_readBit
	lda	(unshrinkler_tabs),y
	sta	unshrinkler_factor+1
	lsr	@
	sta	unshrinkler_tmpH
	inc	unshrinkler_tabs+1
	lda	(unshrinkler_tabs),y
	sta	unshrinkler_factor
	ror	@
	lsr	unshrinkler_tmpH
	ror	@
	lsr	unshrinkler_tmpH
	ror	@
	lsr	unshrinkler_tmpH
	ror	@
	eor	#$ff
	sec
	adc	unshrinkler_factor
	sta	(unshrinkler_tabs),y
	lda	unshrinkler_factor+1
	sbc	unshrinkler_tmpH
	pha

	txa	; #0
	sta	unshrinkler_cp+1
	lsr	unshrinkler_factor+1
	ror	unshrinkler_factor
	ldx	#16
unshrinkler_mulLoop
	bcc	unshrinkler_mulNext
	clc
	adc	unshrinkler_d3
	pha
	lda	unshrinkler_cp+1
	adc	unshrinkler_d3+1
	sta	unshrinkler_cp+1
	pla
unshrinkler_mulNext
	ror	unshrinkler_cp+1
	ror	@
	ror	unshrinkler_factor+1
	ror	unshrinkler_factor
	dex
	bne	unshrinkler_mulLoop
	sta	unshrinkler_cp

	eor	#$ff
	sec
	adc	unshrinkler_d2
	tax
	lda	unshrinkler_d2+1
	sbc	unshrinkler_cp+1
	bcs	unshrinkler_zero

	lda	(unshrinkler_tabs),y
	sbc	#0	; C=0
	sta	(unshrinkler_tabs),y
	pla
	sbc	#$f0
	pha
	lda	unshrinkler_cp
	sta	unshrinkler_d3
	lda	unshrinkler_cp+1
	sec
	bcs	unshrinkler_retBit	; always

unshrinkler_zero
	stx	unshrinkler_d2
	sta	unshrinkler_d2+1
	lda	unshrinkler_d3
	sbc	unshrinkler_cp	; C=1
	sta	unshrinkler_d3
	lda	unshrinkler_d3+1
	sbc	unshrinkler_cp+1
	clc

unshrinkler_retBit
	sta	unshrinkler_d3+1
	dec	unshrinkler_tabs+1
	pla
	sta	(unshrinkler_tabs),y
	ldx	#0
	rts
