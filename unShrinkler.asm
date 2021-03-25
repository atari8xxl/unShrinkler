	opt	?+
unshrinkler

?src	equ	unshrinkler_zp
?dst	equ	unshrinkler_zp+2
?copy	equ	unshrinkler_zp+4
?factor	equ	unshrinkler_zp+4
?tabs	equ	unshrinkler_zp+6
?number	equ	unshrinkler_zp+8
?cp	equ	unshrinkler_zp+10
?d2	equ	unshrinkler_zp+12
?d3	equ	unshrinkler_zp+14
?frac	equ	unshrinkler_zp+16
?srcBits	equ	unshrinkler_zp+18

?probs	equ	unshrinkler_data
?probsRef	equ	unshrinkler_data+$200
?probsLength	equ	unshrinkler_data+$200
?probsOffset	equ	unshrinkler_data+$400

	ldx	#>[unshrinkler_data+$500]
	ldy	#1
	sty	?d3
	dey
	sty	?d3+1
	ift	0==<unshrinkler_data
	sty	?tabs
	els
	lda	#<unshrinkler_data
	sta	?tabs
	eif
	tya
?initPage
	stx	?tabs+1
?initByte
	sta	(?tabs),y
	iny
	bne	?initByte
	sta	?srcBits	; eventually $80
	eor	#$80
	dex
	cpx	#>unshrinkler_data
	bcs	?initPage
	tax	; #0

?literal
	ldy	#1
?literalBit
	jsr	?getBit
	tya
	rol	@
	tay
	bcc	?literalBit

	sta	(?dst,x)	; X=0
	inc	?dst
	bne	?storeSamePage
	inc	?dst+1
?storeSamePage
	jsr	?getKind
	bcc	?literal

	lda	#>?probsRef
	jsr	?getBitFrom
	bcc	?readOffset

?readLength
	lda	#>?probsLength
	jsr	?getNumber
	lda	#$ff
?offsetL	equ	*-1
	adc	?dst	; C=0
	sta	?copy
	lda	#$ff
?offsetH	equ	*-1
	adc	?dst+1
	sta	?copy+1

	ldx	?number+1
	beq	?copyRemainder
?copyPage
	lda	(?copy),y
	sta	(?dst),y
	iny
	bne	?copyPage
	inc	?copy+1
	inc	?dst+1
	dex
	bne	?copyPage

?copyRemainder
	ldx	?number
	beq	?copyDone
?copyByte
	lda	(?copy),y
	sta	(?dst),y
	iny
	dex
	bne	?copyByte
	tya
	clc
	adc	?dst
	sta	?dst
	bcc	?copyDone
	inc	?dst+1

?copyDone
	jsr	?getKind
	bcc	?literal

?readOffset
	lda	#>?probsOffset
	jsr	?getNumber
	lda	#3
	sbc	?number	; C=0
	sta	?offsetL
	tya	; #0
	sbc	?number+1
	sta	?offsetH
	bcc	?readLength
	rts	; finish

?getNumber
	sta	?tabs+1
	lda	#1
	sta	?number
	sty	?number+1	; #0
?getNumberCount
	iny
	iny
	jsr	?getBit
	bcs	?getNumberCount

?getNumberBit
	dey
	jsr	?getBit
	rol	?number
	rol	?number+1
	dey
	bne	?getNumberBit
	rts

?getKind
	ldy	#0
	lda	#>?probs
?getBitFrom
	sta	?tabs+1
	bne	?getBit	; always

?readBit
	asl	?d3
	rol	?d3+1
	asl	?srcBits
	bne	?gotBit
	lda	(?src,x)	; X=0
	inc	?src
	bne	?readSamePage
	inc	?src+1
?readSamePage
	rol	@	; C=1
	sta	?srcBits
?gotBit
	rol	?d2
	rol	?d2+1

?getBit
	lda	?d3+1
	bpl	?readBit
	lda	(?tabs),y
	sta	?factor+1
	inc	?tabs+1
	lda	(?tabs),y
	sta	?factor

	txa	; #0
	sta	?cp+1
	ldx	#16
?mulLoop
	lsr	?factor+1
	ror	?factor
	bcc	?mulNext
	clc
	adc	?d3
	pha
	lda	?cp+1
	adc	?d3+1
	sta	?cp+1
	pla
?mulNext
	ror	?cp+1
	ror	@
	cpx	#13
	bne	?notFrac
	ldx	?factor
	stx	?frac
	ldx	?factor+1
	stx	?frac+1
	ldx	#13
?notFrac
	dex
	bne	?mulLoop
	sta	?cp

	eor	#$ff
	sec
	adc	?d2
	tax
	lda	?d2+1
	sbc	?cp+1
	bcs	?zero

	lda	?cp
	sta	?d3
	lda	?cp+1
	bcc	?setD3	; always

?zero
	stx	?d2
	sta	?d2+1
	lda	?d3
	sbc	?cp	; C=1
	sta	?d3
	lda	?d3+1
	sbc	?cp+1

?setD3
	sta	?d3+1
	php
	lda	(?tabs),y
	sbc	?frac
	sta	(?tabs),y
	dec	?tabs+1
	lda	(?tabs),y
	sbc	?frac+1
	plp
	bcs	?retZero
	sbc	#$ef	; C=0
	sec
	dta	{bit 0}
?retZero
	clc
	sta	(?tabs),y
	ldx	#0
	rts
