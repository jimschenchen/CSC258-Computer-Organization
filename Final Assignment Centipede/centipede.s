### CSC258 2021 Winter Project
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
	width: .word 32
	height: .word 32
	pgFirstLineIndex: .word 160
	maxLocation: .word 1023
	lastLineLeft: .word 992
	lastLineRight: .word 1023
	# -32 means the last -32 index does not auto generate mushroom
	mushroonNotInitSpace: .word -96
	gameRate: .word 30000	# default 30000

	# Data
	score: .word 0
	lives: .word 5
	totalLives: .word 5
	level: .word 0	# centipedeElimination functional determine level
	levelMax: .word 5
	centipedeElimination: .word 0
	
	# Score
	# mushroomScore: .word 1
	# revertedmushroomScore: .word 5
	# spiderScore: .word 300, 600, 900
	# scorpionScore: .word 1000
	# extraLifeScore: .word 12000
	
	# Obj - Bug Blaster
	bugLocation: .word 1008
	
	# Obj - Centipede

	
	centipedeNum: .word 10
	centipedeLocation: .word -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
	centipedeDefaultLocation: .word 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159
	centipedeDirection: .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	# Obj - Flea
	fleaLocation: .word -1
	fleaOriginalLocationColor: .word 0x000000

	# rate / Speed
	mushroomGenerateRate: .word 2	# num/100
	fleaSpeedCounter: .word 0
	centipedeSpeedCounter: .word 0	# start at 0; Do not change
	
		# leve changed
	fleaFallingRate: .word 10	# num/100
	# Max has to be the (mutiple of Num) -1, eg 9 19 29 if num = 10
	centipedeSpeedCounterMax: .word 49	# 9 fast 29 slow
	fleaSpeedCounterMax: .word 2	# 0fast 5 slow
	fleaGenerateRate: .word 10	# num / 500

	# Obj - Dart
	dartNum: .word 10
	dartLocation: .word -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
	
	# Color Ref: Flat UI
	bugColor: .word 0x2980b9
	dartColor: .word 0x3498db
	
	mushroom4LivesColor: .word 0x2ecc71
	mushroom3LivesColor: .word 0x27ae60
	mushroom2LivesColor: .word 0x118800
	mushroom1LivesColor: .word 0x005500
	mushroomPoisColor: .word  0xffff00
	
	# centipedeHeadColor: .word 0xe74c3c
	centipedeBodyColor: .word 0xe67e22
	
	# spiderColor: .word 0xf1c40f
	# scorpionsColor: .word 0x8e44ad
	fleaColor: .word 0xbdc3c7
	
	livesColor: .word 0xc0392b
	greyColor: .word 0x999999
	scoreColor: .word 0xecf0f1
	levelColor: .word 0x16a085
	
	bgColor: .word 0x000000


######################################################################
#
# MAIN
#
######################################################################
.globl main
.text
main:
# init game
init_game:

# set all pixels to bgColor
addi $a3, $zero, 1024	 # load a3 with the loop count (10)
clear_loop:
	addi $a3, $a3, -1	 # decrement $a3 by 1
	lw $t2, displayAddress
	lw $t3, bgColor
	sll $t4, $a3, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)
bne $a3, $zero, clear_loop
	
	
# init_bug
la $t0, bugLocation	# load the address of buglocation from memory
lw $t1, 0($t0)		# load the bug location itself in t1	
lw $t2, displayAddress  # $t2 stores the base address for display
sll $t4,$t1, 2		# $t4 the bias of the old buglocation
add $t4, $t2, $t4	# $t4 is the address of the old bug location
lw $t3, bugColor	# $t3 stores bug color code
sw $t3, 0($t4)		# paint the first (top-left) unit white.
	
# place mush room
jal mushroom_generate
	
# set level / speed 
	
# set s
	
######################################################################
#
# Game Loop
#
######################################################################
game_loop:

	jal level_increase # before level func
	jal level_function
	jal display_level
	
	
	jal bug_function
	jal dart_function
	
	jal centipede_auto_generate
	jal centipede_function
	jal bug_display
	
	jal flea_generate
	jal flea_function
	
	jal display_lives
	
	# Delay
	lw $a2, gameRate
	delay:
	addi $a2, $a2, -1
	bgtz $a2, delay
	
	j game_loop	
	
Exit:
	li $v0, 10		# terminate the program gracefully
	syscall


######################################################################
#
# Level
#
######################################################################
level_increase:
	addi $sp, $sp, -4
	sw $ra, 0($sp)	
	
	lw $a0, centipedeElimination

	addi $t0, $zero, 5
	bgt $a0, $t0, level_set_to_max
	addi $t0, $zero, 4
	bgt $a0, $t0, level_set_to_four
	addi $t0, $zero, 3
	bgt $a0, $t0, level_set_to_three
	addi $t0, $zero, 2
	bgt $a0, $t0, level_set_to_two
	addi $t0, $zero, 1
	bgt $a0, $t0, level_set_to_one
	j level_set_to_zero
	level_set_to_zero:
		la $t0, level
		addi $t1, $zero, 0
		sw $t1, 0($t0)
		j level_set_else
	level_set_to_one:
		la $t0, level
		addi $t1, $zero, 1
		sw $t1, 0($t0)
		j level_set_else
	level_set_to_two:
		la $t0, level
		addi $t1, $zero, 2
		sw $t1, 0($t0)
		j level_set_else
	level_set_to_three:
		la $t0, level
		addi $t1, $zero, 3
		sw $t1, 0($t0)
		j level_set_else
	level_set_to_four:
		la $t0, level
		addi $t1, $zero, 4
		sw $t1, 0($t0)
		j level_set_else
	level_set_to_max:
		la $t0, level
		addi $t1, $zero, 5
		sw $t1, 0($t0)
		j level_set_else
	level_set_else:
	
	# pop ra
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

display_level:
	addi $sp, $sp, -4
	sw $ra, 0($sp)	
	
	lw $a3, levelMax
	li $a0, 0
	addi $a1, $zero, 33	# level position
	lw $a2, level
	
	level_loop:
		blt $a0, $a2, display_level_else
			lw $t0, greyColor
			j display_level_if
		display_level_else:
			lw $t0, levelColor
		display_level_if:
		
		lw $t1, displayAddress
		
		addi $t2, $a1, 0
		sll $t2, $t2, 2
		add $t2, $t2, $t1
		sw $t0, 0($t2)
		
		addi $t2, $a1, 1
		sll $t2, $t2, 2
		add $t2, $t2, $t1
		sw $t0, 0($t2)
		
		# increament
		addi $a0, $a0, 1
		addi $a1, $a1, 3
	bne $a0, $a3, level_loop
	
	# pop ra
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

level_function:
	addi $sp, $sp, -4
	sw $ra, 0($sp)	
	
	lw $a0, level
	
	addi $t0, $zero, 0
	beq $a0, $t0, level_zero
	addi $t0, $zero, 1
	beq $a0, $t0, level_one
	addi $t0, $zero, 2
	beq $a0, $t0, level_two
	addi $t0, $zero, 3
	beq $a0, $t0, level_three
	addi $t0, $zero, 4
	beq $a0, $t0, level_four
	j level_max
	level_zero:
		
		la $t1, fleaFallingRate	# /100
		addi $t0, $zero, 5
		sw $t0, 0($t1)
		
		la $t1, centipedeSpeedCounterMax # 0 9 19 29 slow
		addi $t0, $zero, 59
		sw $t0, 0($t1)
		
		la $t1, fleaSpeedCounterMax # 0fast 5 slow
		addi $t0, $zero, 5
		sw $t0, 0($t1)
		
		la $t1, fleaGenerateRate # num / 500
		addi $t0, $zero, 5
		sw $t0, 0($t1)
		
		la $t1, centipedeNum 
		addi $t0, $zero, 10
		sw $t0, 0($t1)
		
		j level_end
		
	level_one:
	
		la $t1, fleaFallingRate	# /100
		addi $t0, $zero, 8
		sw $t0, 0($t1)
		
		la $t1, centipedeSpeedCounterMax # 9 19 29 slow
		addi $t0, $zero, 49
		sw $t0, 0($t1)
		
		la $t1, fleaSpeedCounterMax # 0fast 5 slow
		addi $t0, $zero, 4
		sw $t0, 0($t1)
		
		la $t1, fleaGenerateRate # num / 500
		addi $t0, $zero, 8
		sw $t0, 0($t1)
		
		la $t1, centipedeNum 
		addi $t0, $zero, 11
		sw $t0, 0($t1)
		
		j level_end
		
	level_two:
	
		la $t1, fleaFallingRate	# /100
		addi $t0, $zero, 11
		sw $t0, 0($t1)
		
		la $t1, centipedeSpeedCounterMax # 9 19 29 slow
		addi $t0, $zero, 39
		sw $t0, 0($t1)
		
		la $t1, fleaSpeedCounterMax # 0fast 5 slow
		addi $t0, $zero, 3
		sw $t0, 0($t1)
		
		la $t1, fleaGenerateRate # num / 500
		addi $t0, $zero, 11
		sw $t0, 0($t1)
		
		la $t1, centipedeNum 
		addi $t0, $zero, 12
		sw $t0, 0($t1)
		
		j level_end
		
	level_three:
		
		la $t1, fleaFallingRate	# /100
		addi $t0, $zero, 14
		sw $t0, 0($t1)
		
		la $t1, centipedeSpeedCounterMax # 9 19 29 slow
		addi $t0, $zero, 29
		sw $t0, 0($t1)
		
		la $t1, fleaSpeedCounterMax # 0fast 5 slow
		addi $t0, $zero, 2
		sw $t0, 0($t1)
		
		la $t1, fleaGenerateRate # num / 500
		addi $t0, $zero, 14
		sw $t0, 0($t1)
		
		la $t1, centipedeNum 
		addi $t0, $zero, 13
		sw $t0, 0($t1)
		
		j level_end
		
	level_four:
		
		la $t1, fleaFallingRate	# /100
		addi $t0, $zero, 17
		sw $t0, 0($t1)
		
		la $t1, centipedeSpeedCounterMax # 9 19 29 slow
		addi $t0, $zero, 19
		sw $t0, 0($t1)
		
		la $t1, fleaSpeedCounterMax # 0fast 5 slow
		addi $t0, $zero, 1
		sw $t0, 0($t1)
		
		la $t1, fleaGenerateRate # num / 500
		addi $t0, $zero, 17
		sw $t0, 0($t1)
		
		la $t1, centipedeNum 
		addi $t0, $zero, 14
		sw $t0, 0($t1)
		
		j level_end

	level_max:
	
		la $t1, fleaFallingRate	# /100
		addi $t0, $zero, 20
		sw $t0, 0($t1)
		
		la $t1, centipedeSpeedCounterMax # 9 19 29 slow
		addi $t0, $zero, 9
		sw $t0, 0($t1)
		
		la $t1, fleaSpeedCounterMax # 1 fast 5 slow
		addi $t0, $zero, 1
		sw $t0, 0($t1)
		
		la $t1, fleaGenerateRate # num / 500
		addi $t0, $zero, 20
		sw $t0, 0($t1)
		
		la $t1, centipedeNum 
		addi $t0, $zero, 15
		sw $t0, 0($t1)
		
		j level_end
		
	level_end:
	
	
	
	
	# pop ra
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
######################################################################
#
# Lives
#
######################################################################
display_lives:
	# push ra
	addi $sp, $sp, -4
	sw $ra, 0($sp)	
	
	lw $a0, totalLives
	addi $a1, $zero, 63
	lw $a2, lives
	
	lives_loop:
		ble $a0, $a2, display_lives_else
			lw $t0, greyColor
			j display_lives_if
		display_lives_else:
			lw $t0, livesColor
		display_lives_if:
		
		
		lw $t1, displayAddress
		
		addi $t2, $a1, 0
		sll $t2, $t2, 2
		add $t2, $t2, $t1
		sw $t0, 0($t2)
		
		addi $t2, $a1, 32
		sll $t2, $t2, 2
		add $t2, $t2, $t1
		sw $t0, 0($t2)
		
		addi $t2, $a1, 64
		sll $t2, $t2, 2
		add $t2, $t2, $t1
		sw $t0, 0($t2)
		
		# increament
		addi $a0, $a0, -1
		addi $a1, $a1, -2
	bne $a0, $zero, lives_loop
	
	# pop ra
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

######################################################################
#
# lose_lives
#
######################################################################	
lose_lives:
	# lose lives
	la $t0, lives
	lw $t1, lives
	addi $t1, $t1, -1
	sw $t1, 0($t0)
	
	
	# upon death
	lw $t1, lives
	bne $t1, $zero, lose_lives_not_dead
		# dead
		j EXIT
	lose_lives_not_dead:

	# reset centipedeSpeedCounter
	la $t0, centipedeSpeedCounter
	sw $zero, 0($t0)
	# reset centipede
	lw $a0, centipedeNum
	add $a1, $zero, $a0	 	# a1: loop counter
	la $a2, centipedeLocation 	# a2: location addr
	lose_lives_centipede:
		lw $t0, 0($a2)
			
		lw $t1, displayAddress
		sll $t2, $t0, 2
		add $t2, $t2, $t1
		lw $t3, bgColor
		sw $t3, 0($t2)	
		
		### LOOP INCREAMENT ###
		addi $a2, $a2, 4
		addi $a1, $a1, -1	 # counter --
		bne $a1, $zero, lose_lives_centipede
	jal spawning_centipede
	

	# reset flea
	la $t0, fleaLocation
	addi $t1, $zero, -1
	sw $t1, 0($t0)
	
	# jump to game_loop
	j game_loop

######################################################################
#
# MUSHROOM
#
######################################################################
# param: generate rate out of 100 (eg: 20 -> 20/100)
mushroom_generate:
	# push ra
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# func start
	
	# Loop 
	lw $a2, maxLocation	# a2: loop counter 1023
	lw $t0, mushroonNotInitSpace
	add $a2, $a2, $t0	# last line not generate
	lw $a3, pgFirstLineIndex	# a3: loop end at pgFirstLineIndex
	mushroom_generate_loop:
	
		# random 0 - 100
		li $v0, 42
		li $a0, 0
		li $a1, 100
		syscall
		add $t0, $zero, $a0	# t0: random 0 - 100
		
		lw $t7, mushroomGenerateRate
		bgt $t0, $t7, mushroom_not_generate	
		# generate mushroom
		lw $t2, mushroom4LivesColor	# t2: mush color
		lw $t3, displayAddress
		sll $t4, $a2, 2
		add $t4, $t4, $t3		# t4: mush address
		sw $t2, 0($t4)
		mushroom_not_generate:
		
		addi $a2, $a2, -1
		bne $a2, $a3, mushroom_generate_loop
	# loop end
	
	# pop ra
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

######################################################################
#
# FLEA
#
######################################################################
flea_generate:
# pop generate rate
	# push ra
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# func start

	lw $t0, fleaLocation
	addi $t1, $zero, -1
	bne $t0, $t1, flea_generate_else	# -1 not generate
		# random 0 - 500
		li $v0, 42
		li $a0, 0
		li $a1, 500
		syscall
		add $t0, $zero, $a0	# t0: random 0 - 100
		lw $t7, fleaGenerateRate
		bgt $t0, $t7, flea_not_generate	# random geneate
		
			# random 0 - 100
			li $v0, 42
			li $a0, 0
			li $a1, 31
			syscall
			add $t0, $zero, $a0	# t0: random 0 - 31 position
		
			lw $t1, pgFirstLineIndex
			add $t2, $t1, $t0
			addi $t2, $t2, -32
			la $t3, fleaLocation
			sw $t2, 0($t3)		# update flea location before the first line

		flea_not_generate:
	flea_generate_else:
	
	# pop ra
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
flea_function:
	# push ra
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# func start
	
	###### Speed Countrol #####
	la $t0, fleaSpeedCounter
	lw $t1, fleaSpeedCounter
	lw $t2, fleaSpeedCounterMax
	addi $t3, $t1, 1
	blt $t3, $t2, flea_speed_control_else
		# counter = max
		addi $t3, $zero, 0
	flea_speed_control_else:
	sw $t3, 0($t0)		# save counter

	bne $t1, $zero, flea_skip_all
	
	##### skip location -1 ######
	lw $t0, fleaLocation
	addi $t1, $zero, -1
	beq $t0, $t1, flea_skip_all
	
	########## Update status ##########
	
	##### get the next pixel #####
	lw $a2, fleaOriginalLocationColor
	
	##### save original location ######
	lw $a3, fleaLocation
	
	##### save next pixel #####
	la $t0, fleaOriginalLocationColor
	lw $t1, fleaLocation
	lw $t2, displayAddress
	addi $t3, $t1, 32
	sll $t3, $t3, 2
	add $t3, $t3, $t2	# t3: addr of next pixel
	lw $t4, 0($t3)		# t4: color of t3
	sw $t4, 0($t0)		# store color to fleaNextColor

	##### Collide bug and game will clear #####
	lw $t0, fleaLocation	# dart location
	lw $t1, bugLocation	# bug location
	bne $t0, $t1, flea_not_collide_bug
		j lose_lives
	flea_not_collide_bug:
	
	##### collide botton set next to bg and skip natural #####
	lw $t6, lastLineLeft
	lw $t0, fleaLocation
	blt $t0, $t6, flea_function_bottom_else
		# last line
		
		# reset orin color
		lw $t1, bgColor
		la $t0, fleaOriginalLocationColor
		sw $t1, 0($t0)
		
		# set location to -1
		la $t0, fleaLocation
		addi $t1, $zero, -1
		sw $t1, 0($t0)
		
		# update display
		# fill original color
		lw $t2, displayAddress
		sll $t3, $a3, 2
		add $t3, $t3, $t2	# t3: original addr
		sw $a2, 0($t3)		# save original color to orginal location
		
		# skip all
		j flea_skip_all
	flea_function_bottom_else:
	
	##### Natural Movement #####
	la $t0, fleaLocation
	lw $t1, fleaLocation
	addi $t1, $t1, 32
	sw $t1, 0($t0)
	
	##### Fall mushroom (after natural movement) #####
	
	# random 0 - 100
	li $v0, 42
	li $a0, 0
	li $a1, 100
	syscall
	add $t0, $zero, $a0	# t0: random 0 - 100
	lw $t7, fleaFallingRate
	
	bgt $t0, $t7, flea_not_fall_mush	# not in rate
	lw $t3, maxLocation	
	lw $t4, mushroonNotInitSpace
	lw $t5, pgFirstLineIndex
	addi $t5, $t5, 32
	add $t4, $t4, $t3	
	lw $t1, fleaLocation
	blt $t1, $t5, flea_not_fall_mush
	bgt $t1, $t4, flea_not_fall_mush	# last mushroonNotInitSpace line not fall
		lw $t6, bgColor	
		bne $a2, $t6, flea_not_bg
			# if original is bg, fall mush
			lw $t0, mushroom4LivesColor
			lw $t2, displayAddress
		sll $t3, $a3, 2		# a1: orinal location
		add $t3, $t3, $t2	# t3: original addr
			sw $t0, 0($t3)
			# skip update
			j flea_skip_update_original
		flea_not_bg:
	flea_not_fall_mush:

	
	########## Update display ##########
	# fill original color
	lw $t2, displayAddress
	sll $t3, $a3, 2
	add $t3, $t3, $t2	# t3: original addr
	
	
	lw $t0, centipedeBodyColor
	bne $a2, $t0, flea_original_color_else
		lw $t4, bgColor
		add $a2, $zero, $t4	#  if original is centipede, set to bgColor
	flea_original_color_else:
	sw $a2, 0($t3)		# save original color to orginal location
	
	flea_skip_update_original:
	
	# fill new color
	lw $t0, fleaColor
	lw $t1, fleaLocation
	sll $t3, $t1, 2
	add $t3, $t3, $t2	# t3: addr of flea
	sw $t0, 0($t3)		# paint new flea

	### skip all ###
	flea_skip_all:
	
	# pop ra
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
######################################################################
#
# CENTIPEDE
#
######################################################################
spawning_centipede:
	# push ra
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# func start
	
	lw $a0, centipedeNum
	add $a1, $zero, $a0	 	# a1: loop counter
	la $a2, centipedeLocation 	# a2: location addr
	la $a3, centipedeDefaultLocation	# a3: default location
	la $a0, centipedeDirection	# a0: direction
	centipede_auto_generate_loop2:
		lw $t0, 0($a3)
		sw $t0, 0($a2)		# set location to default
			
		addi $t1, $zero, 1
		sw $t1, 0($a0)		# direction set to 1
			
		### LOOP INCREAMENT ###
		addi $a2, $a2, 4
		addi $a3, $a3, 4	
		addi $a0, $a0, 4
		addi $a1, $a1, -1	 # counter --
		bne $a1, $zero, centipede_auto_generate_loop2
	
	# pop ra
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
centipede_auto_generate:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	### LOOP ### 
	lw $a0, centipedeNum
	add $a1, $zero, $a0	 	# a1: loop counter
	la $a2, centipedeLocation 	# a2: location addr
	centipede_auto_generate_loop:
		lw $t0, 0($a2)	# t0: centipede value
		addi $t1, $zero, -1
		bne $t0, $t1, centipede_generate_not_all_dead

		### LOOP INCREAMENT ###
		addi $a2, $a2, 4	 # centipedeLocation revered order
		addi $a1, $a1, -1	 # counter --
		bne $a1, $zero, centipede_auto_generate_loop
	##### end of the centipede_auto_generate_loop
	centipede_generate_all_dead:
	
		la $t0, centipedeElimination	# increase value
		lw $t1, centipedeElimination
		addi $t2, $t1, 1
		sw $t2, 0($t0)
		
		jal spawning_centipede
	centipede_generate_not_all_dead:
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra 

centipede_function:
	# Direction -1:left 1:Right
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $a0, centipedeNum
	add $a3, $zero, $a0	 # load a3 with the loop count: centipedeNum
	
	la $a1, centipedeLocation # load the address of the array into $a1
	lw $t0, centipedeNum
	add $t0, $t0, -1
	sll $t0, $t0, 2
	add $a1, $a1, $t0	# a0 + (10 - 1) * 4: in reversed order
	
	la $a2, centipedeDirection # load the address of the array into $a2

##### centipde_loop start
centipede_loop:	#iterate over the loops elements to draw each body in the centiped

	### Save old position
	lw $s0, 0($a1)	# s0: old centipedeLocation
	
	########## Centipede Logic (Update status) ##########
	
	
	##### Collide dart and turn into mushroom (prior 1) #####
	la $t5, dartLocation	# t5: dart arr
	lw $t6, dartNum		# t6: loop counter
	centipede_dart_loop:
		lw $t1, 0($t5) 	# t1: dart position
		lw $t0, 0($a1)	# t0: centipedeLocation
		# IF collide
		bne $t1, $t0, centipede_dart_else
			# t1 == t0  eliminate this centipede
			addi $t2, $zero, -1
			sw $t2, 0($a1)	# save -1 to centipede
			sw $t2, 0($t5)	# save -1 to dart
		
			### generate mushroom ###
			lw $t3, displayAddress
			sll $t4, $t1, 2
			add $t4, $t4, $t3
			lw $t7, mushroom4LivesColor
			sw $t7, 0($t4)
		
		centipede_dart_else:
		# IF END
		
		addi $t5, $t5, 4	# increament
		addi $t6, $t6, -1
		bne $zero, $t6, centipede_dart_loop
	# centipede_dart_loop end
	
	##### Collide bug and game will clear #####
	lw $t0, 0($a1)		# dart location
	lw $t1, bugLocation	# bug location
	bne $t0, $t1, centipede_not_collide_bug
		j lose_lives
	centipede_not_collide_bug:
	
	
	##### Speed Control (after dart check) #####
	lw $t1, centipedeNum
	la $t2, centipedeSpeedCounter
	lw $t3, 0($t2)
	lw $t4, centipedeSpeedCounterMax
	bgt $t4, $t3, centipede_speed_if	# if counter meet the max counter
		sw $zero, 0($t2)		# reset counter to 0
		j centipede_speed_else
	centipede_speed_if:
		addi $t5, $t3, 1
		sw $t5, 0($t2)		# counter ++
	centipede_speed_else:
		
	
	# counter >= 10  0-9
	bge $t3, $t1, centipede_skip_all_movement
	
	##### Collide bound (prior 2) #####
	lw $t5, 0($a1)	# t5: centipede current location
	lw $t8, 0($a2)	# t8: centipede current direction
	lw $t6, height	# t6: counter of height	
	lw $t7, width	# t6: counter of height	
	addi $t1, $zero, 0	# t1: left bound
	addi $t2, $t7, -1 	# t2: right bound
	centipede_bound_loop:
		
		# If == left bond and direciont == -1
		bne $t5, $t1, centipede_left_bound_else
		addi $t0, $zero, -1
		bne $t8, $t0, centipede_left_bound_else
			# change direciton to right 1
			addi $t3, $zero, 1
			sw $t3, 0($a2)
			
			# move
			lw $t6, lastLineLeft
			bne $t5, $t6, centipede_left_bound_movedown
				# centipede_bound_moveup
				lw $t0, 0($a1)		# t0: centipedeLocation
				addi $t3, $t0, -32	# t1: new position index
				sw $t3, 0($a1)		# save new position
				j centipede_left_bound_move_end
			centipede_left_bound_movedown:
				lw $t0, 0($a1)		# t0: centipedeLocation
				addi $t3, $t0, 32	# t1: new position index
				sw $t3, 0($a1)		# save new position
			centipede_left_bound_move_end:
			
			j centipede_update_display
		centipede_left_bound_else:
		
		# If == right bond and direciont == 1
		bne $t5, $t2, centipede_right_bound_else
		addi $t0, $zero, 1
		bne $t8, $t0, centipede_right_bound_else
			# change direciton to left -1
			addi $t3, $zero, -1
			sw $t3, 0($a2)
			
			# move
			lw $t6, lastLineRight
			bne $t5, $t6, centipede_right_bound_movedown
				# centipede_bound_moveup
				lw $t0, 0($a1)		# t0: centipedeLocation
				addi $t3, $t0, -32	# t1: new position index
				sw $t3, 0($a1)		# save new position
				j centipede_right_bound_move_end
			centipede_right_bound_movedown:
				lw $t0, 0($a1)		# t0: centipedeLocation
				addi $t3, $t0, 32	# t1: new position index
				sw $t3, 0($a1)		# save new position
			centipede_right_bound_move_end:
			
			j centipede_update_display
		centipede_right_bound_else:
		
		# loop increament
		addi $t6, $t6, -1
		add $t1, $t1, $t7	# left bound + width
		add $t2, $t2, $t7	# right bound + width
		bne $t6, $zero, centipede_bound_loop
	# end of centipede_bound_loop
	

	### *** Deadth cheack (before the natural movement) *** ###
	lw $t1, 0($a1) 		# t1: centipede position
	addi $t2, $zero, -1
	# IF	
	ble $t1, $t2, centipede_dead
	
	##### Natural Movement #####	
	# Update status (turn BGcolor)
	lw $t0, 0($a1)		# t0: centipede Location
	lw $t3, 0($a2)		# t1: centipede Directon
	
	add $t1, $t0, $t3	# t1: new position index
	sw $t1, 0($a1)		# save new position

	##### *** Skip natural Movement *** #####
	centipede_skip_natual_movement:
	
	
	
	##### Collide mushroom (prior 3) #####
	# after natural movement coz we check the location after move is mush or not

	lw $t0, 0($a1)	# t0: centipede current location
	lw $t1, 0($a2)	# t1: centipede current direction
	lw $t2, displayAddress
	
	sll $t3, $t0, 2
	add $t3, $t3, $t2	# t3: current address
	
	lw $t4, 0($t3)		# t4: current color at t3
	
	lw $t5, mushroom4LivesColor
	beq $t5, $t4, centipede_collide_mushroom
	lw $t5, mushroom3LivesColor
	beq $t5, $t4, centipede_collide_mushroom
	lw $t5, mushroom2LivesColor
	beq $t5, $t4, centipede_collide_mushroom
	lw $t5, mushroom1LivesColor
	beq $t5, $t4, centipede_collide_mushroom
	# no condition meet
	j centipede_not_collide_mushroom
	centipede_collide_mushroom:
		
		lw $t8, 0($a2)	# t8: centipede current direction
	
		# IF direction is left
		addi $t0, $zero, -1
		bne $t8, $t0, centipede_left_bound_else2
			# change direciton to right 1
			addi $t3, $zero, 1
			sw $t3, 0($a2)
			# move down
			lw $t0, 0($a1)		# t0: centipedeLocation
			addi $t3, $t0, 33	# t1: new position index  33 is because we need to withdraw the natural move
			sw $t3, 0($a1)		# save new position
			
		centipede_left_bound_else2:
		
		# If direction to left
		addi $t0, $zero, 1
		bne $t8, $t0, centipede_right_bound_else2
			# change direciton to left -1
			addi $t3, $zero, -1
			sw $t3, 0($a2)
			# move down
			lw $t0, 0($a1)		# t0: centipedeLocation
			addi $t3, $t0, 31	# t1: new position index
			sw $t3, 0($a1)		# save new position

		centipede_right_bound_else2:
	centipede_not_collide_mushroom:
	

	### *** Skip Updating display *** ###
	# does not display in the first 5 lines
	lw $t1, 0($a1) 		# t1: centipede position
	lw $t2, pgFirstLineIndex
	# IF	
	blt $t1, $t2, centipede_skip_display
	
	centipede_update_display:
	########## Update Display ##########
	lw $t2, displayAddress
	# Update old display 
	sll $t3, $s0, 2		# s0 is the old postion 
	add $t3, $t2, $t3	# t3: t0's display addr
	lw $t4, bgColor	# t4: bg color
	sw $t4, 0($t3)	

	# Update display
	lw $t1, 0($a1) 		# t1: centipede position
	sll $t3, $t1, 2		# t3: t1's display addr
	add $t3, $t3, $t2
	lw $t4, centipedeBodyColor		# t4: dart color
	sw $t4, 0($t3)	# fill old position with bg Color
	
	##### *** Deadth cheack END *** #####
	centipede_dead:
	##### *** centipede skip display *** #####
	centipede_skip_display:
		
	### Skip all ###
	centipede_skip_all_movement:
	
	########## LOOP INCREAMENT ##########	
	addi $a1, $a1, -4	 # centipedeLocation revered order
	addi $a2, $a2, 4
	addi $a3, $a3, -1	 # decrement $a3 by 1
	bne $a3, $zero, centipede_loop
##### end of the centipede_loop
	centipede_skip_all:
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

######################################################################
#
# BUG
#
######################################################################
bug_display:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, displayAddress
	lw $t2, bugColor	# $t3 stores bug color code
	sll $t3, $t0, 2
	add $t3, $t1, $t3
	sw $t2, 0($t3)
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

bug_function:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# check key input
	lw $t8, 0xffff0000
	beq $t8, 1, get_keyboard_input # if key is pressed, jump to get this key
	addi $t8, $zero, 0
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# function to get the input key
get_keyboard_input:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t2, 0xffff0004
	addi $v0, $zero, 0	#default case
	beq $t2, 0x6A, respond_to_j
	beq $t2, 0x6B, respond_to_k
	beq $t2, 0x78, respond_to_x
	beq $t2, 0x73, respond_to_s
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# Call back function of j key
respond_to_j:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	lw $t3, bgColor		# $t3 stores bgColor
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the first (top-left) unit white.
	
	lw $t5, lastLineLeft
	beq $t1, $t5, skip_movement # prevent the bug from getting out of the canvas
	addi $t1, $t1, -1	# move the bug one location to the left
skip_movement:
	sw $t1, 0($t0)		# save the bug location

	lw $t3, bugColor	# $t3 stores bug color code
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# paint the first (top-left) unit white.
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# Call back function of k key
respond_to_k:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	lw $t3, bgColor	# $t3 stores bgColor
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the block with black
	
	lw $t5, lastLineRight
	beq $t1, $t5, skip_movement2 #prevent the bug from getting out of the canvas
	addi $t1, $t1, 1	# move the bug one location to the right
skip_movement2:
	sw $t1, 0($t0)		# save the bug location

	lw $t3, bugColor	# $t3 stores the bug colour code
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# paint the block with white
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_x:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# active shoot
	jal dart_shoot
	
	addi $v0, $zero, 3
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_s:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $v0, $zero, 4
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

######################################################################
#
# DART
#
######################################################################
dart_function:
	# Push ra
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $a0, dartLocation	# a0: dart addr
	lw $t1, dartNum
	add $a3, $zero, $t1	# a3: counter set to dartNum
dart_loop:
	# IF dart is available
	lw $t0, 0($a0)		# t0: dart value
	addi $t1, $zero, -1
	beq $t0, $t1, dart_else2	# if == -1 go else
		
		### save old position ###
		lw $s0, 0($a0)
		########## Dart Logic ##########
	
	
		##### Collide top #####
		lw $t0, 0($a0)		# t0: dart value
		lw $t1, pgFirstLineIndex	# load the First line index
		addi $t1, $t1, 32	# t1: second line
		# IF
		bge $t0, $t1, dart_else	# t0 >= t1
			# t0 < t1: dart is at the first line
			# Update status: disappeat
			addi $t2, $zero, -1
			sw $t2, 0($a0)		# a0 = -1
			j dart_skip_natural_movement
		dart_else:
		
		######### Natural Movement ##########
		# Update status
		lw $t0, 0($a0)		# t0: dart Location
		addi $t1, $t0, -32	# t1: new position index
		sw $t1, 0($a0)		# save new dart position
		
		# skip
		dart_skip_natural_movement:
		
		##### Collide flea #####
		la $t0, fleaLocation
		lw $t1, fleaLocation
		lw $t3, 0($a0)
		bne $t3, $t1, dart_not_collide_flea
			addi $t2, $zero, -1
			sw $t2, 0($t0)
			sw $t2, 0($a0)	# dart value
			
			# paint with fleaOriginalLocationColor
			lw $t2, displayAddress 
			sll $t3, $t1, 2
			add $t3, $t2, $t3
			lw $t4, bgColor
			sw $t4, 0($t3)
			# reset original color
			la $t5, fleaOriginalLocationColor
			sw $t4, 0($t5)
		dart_not_collide_flea: 
		
		
		##### Collide mushroom (after natural movement) #####
		lw $t4, 0($a0)		# t4: dart location
		lw $t2, displayAddress  
		sll $t3, $t4, 2
		add $t3, $t3, $t2	# t3: address
		lw $t4, 0($t3)		# t4: pixel color
	
		lw $t5, mushroom4LivesColor
		beq $t5, $t4, dart_collide_mushroom4
		lw $t5, mushroom3LivesColor
		beq $t5, $t4, dart_collide_mushroom3
		lw $t5, mushroom2LivesColor
		beq $t5, $t4, dart_collide_mushroom2
		lw $t5, mushroom1LivesColor
		beq $t5, $t4, dart_collide_mushroom1
		j dart_not_collide_mushroom	# default
		
		# mushroom lives - 1
		dart_collide_mushroom4:
			lw $t5, mushroom3LivesColor
			sw $t5, 0($t3)
			j dart_collide_mushroom_disappear
		dart_collide_mushroom3:
			lw $t5, mushroom2LivesColor
			sw $t5, 0($t3)
			j dart_collide_mushroom_disappear
		dart_collide_mushroom2:
			lw $t5, mushroom1LivesColor
			sw $t5, 0($t3)
			j dart_collide_mushroom_disappear
		dart_collide_mushroom1:
			lw $t5, bgColor
			sw $t5, 0($t3)
			j dart_collide_mushroom_disappear
		
		# dart disappear
		dart_collide_mushroom_disappear:
			addi $t2, $zero, -1
			sw $t2, 0($a0)
			j dart_skip_natural_movement
		dart_not_collide_mushroom:
	

		##### Dispaly Update #####
		# Update old display s0
		lw $t5, bgColor
		lw $t2, displayAddress
		sll $t3, $s0, 2
		add $t3, $t2, $t3	# t3: t0's display addr
		lw $t4, bgColor	# t4: bg color
		sw $t4, 0($t3)	
		
		# Update display
		# IF dart is available
		lw $t0, 0($a0)		# t0: dart value
		addi $t1, $zero, -1
		beq $t0, $t1, dart_else3
			lw $t0, 0($a0)	
			sll $t3, $t0, 2		# t3: t1's display addr
			add $t3, $t3, $t2
			lw $t4, dartColor		# t4: dart color
			sw $t4, 0($t3)	# fill old position with bg Color	
		dart_else3:
	dart_else2:
	# IF NEDS	

	########## LOOP INCREAMENT ##########
	addi $a0, $a0, 4	# increase dartLocation address
	addi $a3, $a3, -1	# decreament a3 counter
	
	bne $a3, $zero, dart_loop	
# end loop dart_loop
	
	# pop start
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

######################################################################
# Shoot the dart, find the unshot dart in the array and move its position to 
dart_shoot:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# push end
	
	la $t0, bugLocation
	lw $t1, 0($t0)
	addi $t1, $t1, 0	# t1: position of dart generate - same pos as bug (we need to print bug every loop)
	
	#dart loop
	la $a0, dartLocation	# load dart location
	lw $t2, dartNum
	add $a3, $zero, $t2	# a3 counter set to dartNum
dart_loop2:
	lw $t2, 0($a0)		# t2: dart value
	
	addi $t3, $zero, -1
	beq $t2, $t3, dart_available	# if dart value == -1, we can shoot it
	
	# increament
	addi $a0, $a0, 4	# increase dartLocation address
	addi $a3, $a3, -1	# decreament a3 counter
	
	bne $a3, $zero, dart_loop2	
	# end loop dart_loop2
	j dart_unavailable	# all dart are not ready
dart_available:		# find dart a0 that is ready to shoot,
	sw $t1, 0($a0)	# generate the dart to the position t1
	
dart_unavailable:	# not generate the dart

	# pop start
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
######################################################################
#
# Utilities
#
######################################################################
# display - not used
update_display:
	# pop color
	lw $a0, 0($sp)
	addi $sp, $sp, 4
	# pop pixel position
	lw $a1, 0($sp)
	addi $sp, $sp, 4
	# push ra
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# func start
	
	lw $t0, displayAddress
	sll $a1, $a1, 2
	add $a1, $a1, $t0
	sw $a0, 0($a1)

	# return
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# Speed countroller
obstacle_speed_control_example:
	# push ra
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#lw $t1, centipedeSpeed
	#la $t2, centipedeSpeedCounter
	#lw $t3, 0($t2)
	
	# beq $t1, $t3, centipede_skip_this_turn
	
	# return
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
######################################################################
EXIT:
	lw $t0, displayAddress
	lw $t2, scoreColor
		
	# I
	addi $t1, $zero, 592
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	
	addi $t1, $zero, 560
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	
	addi $t1, $zero, 528
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	
	addi $t1, $zero, 496
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
		
	addi $t1, $zero, 464
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
		
	# D
	addi $t1, $zero, 584
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	
	addi $t1, $zero, 552
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	
	addi $t1, $zero, 520
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	
	addi $t1, $zero, 488
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
		
	addi $t1, $zero, 456
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	
	
	addi $t1, $zero, 585
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	
	addi $t1, $zero, 554
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	
	addi $t1, $zero, 522
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	
	addi $t1, $zero, 490
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
		
	addi $t1, $zero, 457
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	
	# E
	addi $t1, $zero, 598
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	addi $t1, $zero, 599
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	addi $t1, $zero, 600
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	
	addi $t1, $zero, 566
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	
	addi $t1, $zero, 534
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	addi $t1, $zero, 535
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	addi $t1, $zero, 536
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	
	addi $t1, $zero, 502
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
		
	addi $t1, $zero, 470
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	addi $t1, $zero, 471
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
	addi $t1, $zero, 472
	sll $t1, $t1, 2
	add $t1, $t1, $t0
	sw $t2, 0($t1)
		
		
