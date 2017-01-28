all:
	clang -x objective-c -arch x86_64 -framework AppKit images2pdf.m -o images2pdf
