one
           lda _Cp
           sta _d3
           lda _Cp+1
           sta _d3+1

           lda _xC+1
           sbc #$EF    ; C=0 ($F0)
           sta _xC+1
           lda _xC
           bne @+
           dec _xC+1
@          dec _xC
           sec
           bcs _probret ; zawsze
