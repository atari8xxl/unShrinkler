;----
           ldx _number
           lda _number+1
           beq _lcop_short

_lcop      lda (_copy),y
           sta (_dst),y

           iny
           bne _lcopc

           inc _copy+1
           inc _dst+1

_lcopc
           txa
           bne @+
           dec _number+1
@          dex
           bne _lcop
           lda _number+1
           bne _lcop

           beq _lcopfin


_lcop_short
_lcopS     lda (_copy),y
           sta (_dst),y
           iny
           dex
           bne _lcopS

_lcopfin
           clc
           tya
           adc _dst
           sta _dst
           bcc @+
           inc _dst+1
@          ldy #$00
;----
