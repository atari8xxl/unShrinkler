run: test.xex
	start $<

test.xex: test.asm unShrinkler.asm conan.srk
	mads $< -o:$@ -l
