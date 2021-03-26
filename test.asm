unshrinkler_PARITY	equ	0
unshrinkler_data	equ	$3000
unshrinkler_zp	equ	$80

	org	$3800
main
	mwa	#dl	$230
	mwa	#packed_data_addr	unshrinkler_zp
	mwa	#unpacked_addr	unshrinkler_zp+2
	jsr	unshrinkler
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
