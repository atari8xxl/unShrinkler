6502 unShrinkler
================

This is a [Shrinkler](https://github.com/askeksa/Shrinkler) decompressor
in 6502 assembly language.

Compilation
-----------

Use [MADS](http://mads.atari8.info) or [xasm](https://github.com/pfusik/xasm).

The routine is compiled conditionally to support one of two Shrinkler variants:

* `unshrinkler_PARITY=0` is the recommended "no parity context" variant that
  is almost sure to perform better with the data you have on an 8-bit machine
* `unshrinkler_PARITY=1` is the original variant for Amiga

Three memory areas are used:

* `unshrinkler` - code (about 320 bytes)
* `unshrinkler_data` - uninitialized data (1.5 KB for "no parity context",
  2 KB for the original variant)
* `unshrinkler_zp` - zero-page variables (19 bytes)

You must select these locations at compile time.
`unshrinkler` is defined at the current origin.

Usage
-----

The decompressor assumes that the compressed and the uncompressed data fit
in the memory. Before calling `unshrinkler`, set the locations in the zero-page
variables:

    lda #<packed_data
    sta unshrinkler_zp
    lda #>packed_data
    sta unshrinkler_zp+1
    lda #<unpacked_data
    sta unshrinkler_zp+2
    lda #>unpacked_data
    sta unshrinkler_zp+3
    jsr unshrinkler

As the compressed data is read sequentially and only once, it is possible
to overlap the compressed and uncompressed data. That is, the data being
uncompressed can be stored in place of some compressed data which has been
already read.

See [test.asm](test.asm) for an example for Atari 8-bit.

Compression
-----------

Download the "no parity context" compressor from
https://www.cpcwiki.eu/forum/programming/modified-shrinkler-without-parity-context

Use as follows:

    Shrinkler -d -p -9 INPUT_FILE OUTPUT_FILE

The original compresser is available at https://github.com/askeksa/Shrinkler
