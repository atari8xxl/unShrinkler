; Zero Page

_src     .word packed_data_addr
_dst     .word unpacked_addr
_copy    .word $0000
_number  .word $0000
_Cp      .word $0000
_d2      .word $0000
_xC      .word $0000
_lit     .byte $00
_xH      .byte $00
_d3      .word $0000
_tabs    .word $0000 

; unSrinkler

getnumber  sta _tabs+1
_numberloop
           inc _tabs
           inc _tabs
           jsr getbit
           bcs _numberloop

           sty _number+1
           lda #$01
           sta _number

_bitsloop  dec _tabs
           jsr getbit
           rol _number
           rol _number+1
           dec _tabs
           bne _bitsloop
           rts

getkind    sty _tabs
           lda #.hi(probs)
getprob    sta _tabs+1
           bne getbit     ; zawsze

readbit    asl _d3
           rol _d3+1
           asl _lit
           bne _rbok
           lda (_src),y
           inc _src
           bne @+
           inc _src+1
@          rol @        ; C=1
           sta _lit
_rbok      rol _d2
           rol _d2+1

getbit     lda _d3+1
           bpl readbit
           lda (_tabs),y
           sta _Cp+1
           lsr @
           sta _xC+1
           inc _tabs+1
           lda (_tabs),y
           sta _Cp
           ror @
           lsr _xC+1
           ror @
           lsr _xC+1
           ror @
           lsr _xC+1
           ror @
           eor #$ff
           sec
           adc _Cp
           sta _xC
           lda _Cp+1
           sbc _xC+1
           sta _xC+1

           tya
           sty _xH
           ldy #$10
muluw      asl @
           rol _xH
           rol _Cp
           rol _Cp+1
           bcc _mulcont
           clc
           adc _d3
           tax
           lda _xH
           adc _d3+1
           sta _xH
           txa
           bcc _mulcont
           inc _Cp
           bne _mulcont
           inc _Cp+1
_mulcont
           dey
           bne muluw

           sec
           lda _d2
           sbc _Cp
           tax
           lda _d2+1
           sbc _Cp+1
           bcs zero
one
           lda _xC
           sbc #0       ; C=0
           sta _xC
           lda _xC+1
           sbc #$F0
           sta _xC+1

           lda _Cp
           sta _d3
           lda _Cp+1

           sec
           bcs _probret ; zawsze

zero       sta _d2+1    ; c=1
           stx _d2
           lda _d3
           sbc _Cp
           sta _d3
           lda _d3+1
           sbc _Cp+1
           clc

_probret   sta _d3+1
           lda _xC
           sta (_tabs),y
           dec _tabs+1
           lda _xC+1
           sta (_tabs),y
           rts

shrinkler_decrunch
           ldx #.hi(buffers+$500)
           lda #1
           sta _d3
           lsr @
           sta _d3+1
           sta _tabs
           tay
@          stx _tabs+1
@          sta (_tabs),y
           iny
           bne @-
           sta _lit     ; eventually $80
           eor #$80
           dex
           cpx #.hi(buffers)
           bcs @-1

literal    sec
           bcs @+
getlit     jsr getbit
@          rol _tabs
           bcc getlit

           lda _tabs
           sta (_dst),y
           inc _dst
           bne @+
           inc _dst+1
@          jsr getkind
           bcc literal

           lda #.hi(probs_ref)
           jsr getprob
           bcc readoffset

readlength
           lda #.hi(probs_length)
           jsr getnumber
           lda #$ff
_offsetL   equ *-1
           adc _dst ; C=0
           sta _copy
           lda #$ff
_offsetH   equ *-1
           adc _dst+1
           sta _copy+1

           ldx _number+1
           beq _lcoplp
_lcop      lda (_copy),y
           sta (_dst),y
           iny
           bne _lcop
           inc _copy+1
           inc _dst+1
           dex
           bne _lcop

_lcoplp    ldx _number
           beq _lcopfin
_lcopS     lda (_copy),y
           sta (_dst),y
           iny
           dex
           bne _lcopS
           tya
           clc
           adc _dst
           sta _dst
           bcc @+
           inc _dst+1
@          ldy #$00

_lcopfin   jsr getkind
           bcc literal

readoffset
           lda #.hi(probs_offset)
           jsr getnumber
           lda #$03
           sbc _number  ; C=0
           sta _offsetL
           tya
           sbc _number+1
           sta _offsetH
           bcc readlength
           rts                   ; koniec

             .align
buffers      equ *
probs        equ buffers
probs_ref    equ buffers+$200
probs_length equ buffers+$200
probs_offset equ buffers+$400













