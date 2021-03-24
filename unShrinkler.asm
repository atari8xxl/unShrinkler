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
	ldx	#.hi(unshrinkler_data+$500)
	lda	#1
	sta	_d3
	lsr	@
	sta	_d3+1
	sta	_tabs
	tay
@	stx	_tabs+1
@	sta	(_tabs),y
	iny
	bne	@-
	sta	_lit	; eventually $80
	eor	#$80
	dex
	cpx	#.hi(unshrinkler_data)
	bcs	@-1

literal
	inc	_tabs	; #1
getlit
	jsr	getbit
	rol	_tabs
	bcc	getlit

	lda	_tabs
	sta	(_dst),y
	inc	_dst
	bne	@+
	inc	_dst+1
@	jsr	getkind
	bcc	literal

	lda	#.hi(probs_ref)
	jsr	getprob
	bcc	readoffset

readlength
	lda	#.hi(probs_length)
	jsr	getnumber
	lda	#$ff
_offsetL	equ	*-1
	adc	_dst	; C=0
	sta	_copy
	lda	#$ff
_offsetH	equ	*-1
	adc	_dst+1
	sta	_copy+1

	ldx	_number+1
	beq	_lcoplp
_lcop
	lda	(_copy),y
	sta	(_dst),y
	iny
	bne	_lcop
	inc	_copy+1
	inc	_dst+1
	dex
	bne	_lcop

_lcoplp
	ldx	_number
	beq	_lcopfin
_lcopS
	lda	(_copy),y
	sta	(_dst),y
	iny
	dex
	bne	_lcopS
	tya
	clc
	adc	_dst
	sta	_dst
	bcc	@+
	inc	_dst+1
@	ldy	#$00

_lcopfin
	jsr	getkind
	bcc	literal

readoffset
	lda	#.hi(probs_offset)
	jsr	getnumber
	lda	#$03
	sbc	_number	; C=0
	sta	_offsetL
	tya
	sbc	_number+1
	sta	_offsetH
	bcc	readlength
	rts	; finish

getnumber
	sta	_tabs+1
_numberloop
	inc	_tabs
	inc	_tabs
	jsr	getbit
	bcs	_numberloop

	sty	_number+1
	lda	#$01
	sta	_number

_bitsloop
	dec	_tabs
	jsr	getbit
	rol	_number
	rol	_number+1
	dec	_tabs
	bne	_bitsloop
	rts

getkind
	sty	_tabs
	lda	#.hi(probs)
getprob
	sta	_tabs+1
	bne	getbit	; always

readbit
	asl	_d3
	rol	_d3+1
	asl	_lit
	bne	_rbok
	lda	(_src),y
	inc	_src
	bne	@+
	inc	_src+1
@	rol	@	; C=1
	sta	_lit
_rbok
	rol	_d2
	rol	_d2+1

getbit
	lda	_d3+1
	bpl	readbit
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
muluw
	asl	@
	rol	_xH
	rol	_Cp
	rol	_Cp+1
	bcc	_mulcont
	clc
	adc	_d3
	tax
	lda	_xH
	adc	_d3+1
	sta	_xH
	txa
	bcc	_mulcont
	inc	_Cp
	bne	_mulcont
	inc	_Cp+1
_mulcont
	dey
	bne	muluw

	sec
	lda	_d2
	sbc	_Cp
	tax
	lda	_d2+1
	sbc	_Cp+1
	bcs	zero
one
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
	bcs	_probret	; always

zero
	sta	_d2+1
	stx	_d2
	lda	_d3
	sbc	_Cp	; C=1
	sta	_d3
	lda	_d3+1
	sbc	_Cp+1
	clc

_probret
	sta	_d3+1
	dec	_tabs+1
	pla
	sta	(_tabs),y
	rts
