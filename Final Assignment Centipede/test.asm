# test CSC258 Fall 2020
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#

.data
	displayAddress:	.word	0x10008000

.text
	lw $t0, displayAddress
	li $t1, 0x2ecc71
	li $t2, 0x27ae60
	
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	
	li $t1, 0x118800
	li $t2, 0x005500
	sw $t1, 8($t0)
	sw $t2, 12($t0)
	
EXIT:
	li $v0, 10
	
