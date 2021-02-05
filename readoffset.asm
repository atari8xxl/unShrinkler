readoffset
           lda #.hi(probs_offset)
           jsr getnumber
           lda #$03             ;  C=0 (#$02)
           sbc _number
           sta _offsetL
           tya
           sbc _number+1
           sta _offsetH
           ora _offsetL
           bne readlength
           rts                   ; koniec
