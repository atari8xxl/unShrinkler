unshrinkler_FAST	equ	1
unshrinkler_PARITY	equ	0
unshrinkler_data	equ	$2200
unshrinkler_zp	equ	$80

	org	$3000
main
	lda	20
	cmp:req	20
	mwa	#0	19
	mwa	#dl	$230
	mwa	#packed_data_addr	unshrinkler_zp
	mwa	#unpacked_addr	unshrinkler_zp+2
	jsr	unshrinkler
	lda	20
	ldx	19
	jmp	*
	icl	'unShrinkler.asm'

packed_data_addr
	ift	unshrinkler_PARITY
	ins	'conan.srp'
	els
	ins	'conan.srk'
	eif

	org	$4000
dl
:3	dta	$70
	dta	$4e,a(unpacked_addr)
:95	dta	$0e
	dta	$4e,a(unpacked_addr+$f00)
:95	dta	$0e
	dta	$41,a(dl)

unpacked_addr	equ	$4100

	run	main
