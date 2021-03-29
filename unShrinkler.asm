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
	ift	unshrinkler_FAST
?mal	equ	unshrinkler_zp+19
?msl	equ	unshrinkler_zp+21
?mah	equ	unshrinkler_zp+23
?msh	equ	unshrinkler_zp+25
	eif

?probs	equ	unshrinkler_data
?probsRef	equ	unshrinkler_data+$200+$200*unshrinkler_PARITY
?probsLength	equ	?probsRef
?probsOffset	equ	?probsRef+$200
	ift	unshrinkler_FAST
	ert	0!=<unshrinkler_data
?sqrZeroLo	equ	?probsOffset+$300
?sqrZeroHi	equ	?probsOffset+$600
	eif

	ldx	#>[?probsOffset+$100]
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

	ift	unshrinkler_FAST
	lda	#>?sqrZeroLo
	sta	?mal+1
	lda	#>?sqrZerohi
	sta	?mah+1
	stx	?sqrZeroLo
	stx	?sqrZeroHi
	ldy	#$ff
?initSqr1
	txa
	lsr	@
	adc	?sqrZeroLo,x
	sta	?sqrZeroLo+1,x
	sta	?sqrZeroLo-$100,y
	lda	#0
	adc	?sqrZeroHi,x
	sta	?sqrZeroHi+1,x
	sta	?sqrZeroHi-$100,y
	inx
	dey
	bne	?initSqr1
?initSqr2
	tya
	sbc	#0	; C=0
	ror	@
	adc	?sqrZeroLo+$ff,y
	sta	?sqrZeroLo+$100,y
	lda	#0
	adc	?sqrZeroHi+$ff,y
	sta	?sqrZeroHi+$100,y
	iny
	bne	?initSqr2
	eif

?literal
	ift	unshrinkler_FAST

	lda	#1
	sta	?tabs
?literalBit
	jsr	?getBit
	rol	?tabs
	bcc	?literalBit
	lda	?tabs
	sta	(?dst),y	; Y=0
	els

	ldy	#1
?literalBit
	jsr	?getBit
	tya
	rol	@
	tay
	bcc	?literalBit
	sta	(?dst,x)	; X=0
	eif

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
:unshrinkler_FAST	sty	?tabs
?getNumberCount
:2*unshrinkler_FAST	inc	?tabs
:2*!unshrinkler_FAST	iny
	jsr	?getBit
	bcs	?getNumberCount

?getNumberBit
:unshrinkler_FAST	dec	?tabs
:!unshrinkler_FAST	dey
	jsr	?getBit
	rol	?number
	rol	?number+1
:unshrinkler_FAST	dec	?tabs
:!unshrinkler_FAST	dey
	bne	?getNumberBit
	rts

?getKind
	ldy	#0
:unshrinkler_FAST	sty	?tabs
	ift	unshrinkler_PARITY
	lda	?dst
	and	#1
	asl	@
	adc	#>?probs
	els
	lda	#>?probs
	eif
?getBitFrom
	sta	?tabs+1
	bne	?getBit	; always

?readBit
	asl	?d3
	rol	?d3+1
	asl	?srcBits
	bne	?gotBit
:unshrinkler_FAST	lda	(?src),y	; Y=0
:!unshrinkler_FAST	lda	(?src,x)	; X=0
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
:unshrinkler_FAST	lsr	@
	sta	?frac+1
	inc	?tabs+1
	lda	(?tabs),y

	ift	unshrinkler_FAST
; fast multiplication
	ror	@
	lsr	?frac+1
	ror	@
	lsr	?frac+1
	ror	@
	lsr	?frac+1
	ror	@
	sta	?frac

	lda	(?tabs),y
	jsr	?setupMul
; result byte 0
	ldy	?d3
	lda	(?mal),y
	cmp	(?msl),y
; result byte 1
	lda	(?mah),y
	sbc	(?msh),y
	ldy	?d3+1
	adc	(?mal),y	; C=1
	php
	clc
	sbc	(?msl),y
	sta	?cp+1
; result byte 2
	lda	#0
	tax
	adc	(?mah),y
	bcc	?mulNoCarry1
	inx
?mulNoCarry1
	plp
	sbc	(?msh),y
	bcs	?mulNoBorrow1
	dex
?mulNoBorrow1
	sta	?cp
; result byte 1
	lda	?factor+1
	jsr	?setupMul
	ldy	?d3
	lda	?cp+1
	clc
	adc	(?mal),y
	php
	cmp	(?msl),y
; result byte 2
	lda	?cp
	adc	(?mah),y
	bcc	?mulNoCarry2
	inx
?mulNoCarry2
	plp
	sbc	(?msh),y
	bcs	?mulNoBorrow2
	dex
?mulNoBorrow2
	ldy	?d3+1
	clc
	adc	(?mal),y
	bcc	?mulNoCarry3
	inx
?mulNoCarry3
	sec
	sbc	(?msl),y
	sta	?cp
; result byte 3
	txa
	adc	(?mah),y
	clc
	sbc	(?msh),y
	sta	?cp+1

	ldy	#0
	lda	?d2
	sbc	?cp	; C=1

	els
; slow multiplication
	sta	?factor
	ldx	#4
?computeFrac
	lsr	?frac+1
	ror	@
	dex
	bne	?computeFrac
	sta	?frac

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
	dex
	bne	?mulLoop
	sta	?cp

	eor	#$ff
	sec
	adc	?d2

	eif

	tax
	lda	?d2+1
	sbc	?cp+1
	bcs	?zero

	ldx	?cp
	lda	?cp+1
	bcc	?setD3	; always

?zero
	stx	?d2
	sta	?d2+1
	lda	?d3
	sbc	?cp	; C=1
	tax
	lda	?d3+1
	sbc	?cp+1

?setD3
	stx	?d3
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
	dta	{ldx #}
?retZero
	clc
	sta	(?tabs),y
:!unshrinkler_FAST	ldx	#0
	rts

	ift	unshrinkler_FAST
?setupMul
	sta	?mal
	sta	?mah
	eor	#$ff
	clc
	adc	#1
	sta	?msl
	sta	?msh
	lda	#0
	adc	#>[?sqrZeroLo-$100]
	sta	?msl+1
	adc	#>[?sqrZeroHi-?sqrZeroLo]
	sta	?msh+1
	rts
	eif
