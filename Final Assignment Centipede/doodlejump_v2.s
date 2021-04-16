# Doodle Jump CSC258 Fall 2020
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
	skyColour: .word 0xfff9f4
  byeColor: .word  0x37659E
	doodleColour: .word 0x0070ff
	platformColour: .word 0x9ccf8b
	platformWidth: .word 9
	
	screenHeight: .word 32
	screenWidth: .word 32
	
	jumpThresh: .word 10		# If we move within 10 units of top, scroll
	jumpTime: .word 20
	
	platformAddress: .word 0x10010080
	numPlatforms: .word 3

############################################################################################
#   Doodle location always stored in: 	$s0, $s1  (half loader)     x y
#		Doodle #frames jumped up is in	: 	$s2
#		Doodle jumpTime (from label) in : 	$s3 
#		Doodle jumpThresh (from label) in: 	$s4
#
############################################################################################


############################################################################################
# Initialize Game Data

.globl main
.text
main:	
	li $t0, 0					# Counter for num platforms
	lw $t1, numPlatforms		# Maximum platforms from config
	lw $t2, platformAddress		# Location of *current* platform data
	li $t3, 9					# Y-location of current platform
	
############################################################################################
# Initialize Platforms

platform_init_loop:

	# Initialize the game data...
	jal get_random_number		# Get random number (0-24) in $a0
	sh $a0, 0($t2)				# Store into current platform x
	
	sh $t3, 2($t2)				# Store Y location
	 	
	addi $t0, $t0, 1			# Increment platform counter
	addi $t3, $t3, 11			# Increment Y offset				
	addi $t2, $t2, 4			# Go to address of next platform data
	blt $t0, $t1, platform_init_loop	# If not done all platforms, loop

############################################################################################
# Initialize Doodle Location
# Doodle is placed above the platform on the bottom. (platformAddress + (2 * 4b))
	
	lw $t0, platformAddress		# t0 = platformAddress
	addi $t0, $t0, 8			# t0 = platformAddress of 3rd one (index 2)
	
	lh $s0, 0($t0)				# s0 = platform[2].x
	addi $s0, $s0, 3			# Offset to be in middle of platform
	
	lh $s1, 2($t0)				# s0 = platform[2].y
	addi $s1, $s1, -3			# Offset to be a bit higher than platform
	
	li $s2, 0					# Currently not jumping up.
	lw $s3, jumpTime			# Set jump time to register for fast accesses
	lw $s4, jumpThresh			# Set jump thresh to register for fast accesses
	
############################################################################################
# Draw Background

draw_bg:
	lw $t0, displayAddress		# Location of current pixel data
	addi $t1, $t0, 4096			# Location of last pixel data. Hard-coded below.
								          # 32x32 = 1024 pixels x 4 bytes = 4096.
	lw $t2, skyColour			# Colour of the background
	
draw_bg_loop:
	sw $t2, 0($t0)				# Store the colour
	addi $t0, $t0, 4			# Next pixel
	blt $t0, $t1, draw_bg_loop
	
	lw $a0, platformColour		# Initially draw platforms
	jal draw_platforms			
	
############################################################################################
# GAME LOOP

game_loop_main:
	################################################################################
	# Clear drawings from screen
	
	lw $a0, skyColour		# Load sky colour into $a0 to reset drawings....
	jal draw_doodle			# Reset doodle colour
	
	################################################################################
	# Get Keyboard Input, move doodle accordingly:
	
	lw $t0, screenWidth				# Load in screenWidth
	addi $t0, $t0, -1				# t0 = screenWidth - 1
	
	lw $t8, 0xffff0000				# Check MMIO location for keypress 
	beq $t8, 1, keyboard_input		# If we have input, jump to handler
	j keyboard_input_done			# Otherwise, jump till end

	keyboard_input:
		lw $t8, 0xffff0004				# Read Key value into t8
		beq $t8, 0x6A, keyboard_left	# If `j`, move left
		beq $t8, 0x6B, keyboard_right	# If `k`, move right
    beq $t8, 0x73, keyboard_restart # If `r`, restart the game from end screen
    beq $t8, 0x63, Exit # If `c`, terminate the program gracefully

		j keyboard_input_done		# Otherwise, ignore...

		keyboard_left:
			beq $s0, $zero, transfer_left	# If at left wall, warp to right
			addi $s0, $s0, -1				# Otherwise, decrement x
			j keyboard_input_done			# done

			transfer_left:			
				move $s0, $t0				# doodle.x = screenWdith-1
				j keyboard_input_done		# done

		keyboard_right:
			beq $s0, $t0, transfer_right
			addi $s0, $s0, 1
			j keyboard_input_done

			transfer_right:
				li $s0, 0
				j keyboard_input_done

    keyboard_restart:
      j main

	keyboard_input_done:
		# do nothing


	################################################################################
	# Move doodle!
	
	beq $s2, 0, doodle_move_down
	
	doodle_move_up:
		addi $s2, $s2, -1	# Decrease jump-counter
		bgt $s1, $s4, doodle_below_thresh

		doodle_above_thresh:
			jal draw_platforms		# Reset platform colour			
			jal scroll_screen		# Scroll the screen
			j doodle_move_end

		doodle_below_thresh:
			addi $s1, $s1, -1	# Move y coord for doodle
			j doodle_move_end	
		
	doodle_move_down:
		jal did_doodle_hit	# Go check if doodle has hit something
		beqz $v0, doodle_hit_false

		doodle_hit_true:
			move $s2, $s3			# Doodle be jump now
			j doodle_move_end

		doodle_hit_false:
			addi $s1, $s1, 1
			lw $a1, screenHeight				# Load in screenHeight
			beq $s1, $a1, bye_loop_FINISH  # if doodle.y == screenheight (off the screen)

doodle_move_end:
	################################################################################
	# Doodle is done moving, platforms have been updated if needed.
	# Draw doodle's new location.
	lw $a0, doodleColour	# Load doodle colour
	jal draw_doodle			# Draw the doodle

	lw $a0, platformColour	# Load platform colour
	jal draw_platforms		# Draw platforms
	
	################################################################################
	# Sleep for a bit before restarting the loop
	
	li $v0, 32				# Sleep op code
	li $a0, 50				# Sleep 1/20 second 
	syscall

	j game_loop_main


############################################################################################
	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall

############################################################################################

get_random_number:
  	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0          # Select random generator 0
  	li $a1, 24             
  	syscall             # Generate random int (returns in $a0)
  	jr $ra
 
############################################################################################

# Loops over all the current platform positions, and draws over them.
# 	Input: 		
#		- Colour:		$a0
#	Overwrites: 		$t0-$t5
draw_platforms:					
	li $t0, 0					# START DRAW PLATFORM 
	lw $t1, numPlatforms
	lw $t2, platformAddress		
	lw $t3, platformWidth
	
draw_platform_loop:
	lh $t4, 2($t2)				# idx = Platform Y
	sll $t4, $t4, 5				# idx = Platform Y * 32
	lh $t5, 0($t2)				# 		Platform X
	add $t4, $t4, $t5			# idx = Platform Y * 32 + Platform X
	sll $t4, $t4, 2				# idx = (Platform Y * 32 + Platform X) * 4
	add $t4, $t4, $gp			# idx = $gp + (p.y * 32 + p.x)*4   
	li $t5, 0					# 		counter for platform width
	
draw_platform_inner:	
	sw $a0, 0($t4)				# Store colour from $a0 into current pixel
	addi $t5, $t5, 1			# 		counter ++ (move to next pixel)
	addi $t4, $t4, 4			# idx += 4 (move to next horizontal pixel)
	blt $t5, $t3, draw_platform_inner	# Jump back to start of loop if not done with platform
	
	addi $t0, $t0, 1			# Increment platform Number
	addi $t2, $t2, 4			# Increment address of platform data
  	blt $t0, $t1, draw_platform_loop	# Jump back if not done with all platforms

	jr $ra

############################################################################################
# Draw the doodle with colour in $a0

# * marks a cursor
#   x
#  xxx
#  x*x 

draw_doodle:
	sll $t0, $s1, 5				# idx = doodle.y * 32
	add $t0, $t0, $s0			# idx = (doodle.y * 32) + x
	sll $t0, $t0, 2				# idx = (doodle.y * 32 + x) * 4
	add $t0, $t0, $gp			# idx = $gp + (doodle.y * 32 + x) * 4

	# draw two legs (bottom)
	sw $a0, -4($t0)				# left leg
	sw $a0, 4($t0)				# right leg

	# draw middle layer
	sw $a0, -124($t0)			# left body
	sw $a0, -132($t0)			# middle body
  	sw $a0, -128($t0)        	# right body
    
	# draw top
	sw $a0, -256($t0)			

	jr $ra						# byeee

############################################################################################
# Check if doodle is atop a platform. Returns 0/1 in $v0


did_doodle_hit:
	li $t0, 0					# START DOODLE HIT
	lw $t1, numPlatforms
	lw $t2, platformAddress		
	lw $t3, platformWidth
	li $v0, 0					# HIT = FALSE

doodle_hit_loop: 
	lh $a0, 2($t2)						# Load in Y of current platform
	addi $a0, $a0, -1					#  a0 = platform.y - 1 (above)
	bne $a0, $s1, doodle_hit_loop_inc	# If doodle.y != plat.y - 1: continue

	lh $a0, 0($t2)						# a0 = platform.x
	addi $a0, $a0, -1					# subtract 1 to account for left leg
	blt $s0, $a0, doodle_hit_loop_inc	# if doodle.x < plat.x: continue (left side)

	addi $a0, $a0, 2					# add 1 to restore zero-position, and 2 again for right leg
	add $a0, $a0, $t3
	bge $s0, $a0, doodle_hit_loop_inc	# if doodle.x > plat.x + width: continue  (right side)

	## Platform has been hit here...
	li $v0, 1							# hit platform, return = true
	jr $ra

doodle_hit_loop_inc:
	addi $t0, $t0, 1
	addi $t2, $t2, 4
	blt $t0, $t1, doodle_hit_loop
	
doodle_hit_loop_end:
	jr $ra						# bye
	

############################################################################################
# Scroll screen up by 1 unit. If any of the platforms overflow below the screen,
#	then move them to the top of the screen. We get infitnite platforms for free!


scroll_screen:
	li $t0, 0					# START SCROLL SCREEN
	lw $t1, numPlatforms
	lw $t2, platformAddress	

	lw $t3, screenHeight				# Load in screenHeight
	addi $t3, $t3, -1					#	idx of bottom row on screen	

scroll_loop: 
	lh $t4, 2($t2)						# Load in Y of current platform
	beq $t4, $t3, scroll_transfer		# if plat.y == bottom.y : move to top

	addi $t4, $t4, 1					#  a0 = platform.y + 1 (incremented)
	sh $t4, 2($t2)						# move platform down
	j scroll_loop_inc
	
scroll_transfer:
	sh $zero, 2($t2)					# Reset platform y to 0
	
	move $t5, $ra						# Backup register
	jal get_random_number
	move $ra, $t5
	sh $a0, 0($t2)

scroll_loop_inc:
	addi $t0, $t0, 1
	addi $t2, $t2, 4
	blt $t0, $t1, scroll_loop
	
	jr $ra						# bye
	
############################################################################################

bye_loop_FINISH:
	# draw b
	lw $t0, displayAddress
	addi $t0, $t0, 1576
	lw $t1, byeColor
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 388($t0)
	sw $t1, 392($t0)
	sw $t1, 520($t0)
	sw $t1, 512($t0)
	sw $t1, 640($t0)
	sw $t1, 644($t0)
	sw $t1, 648($t0)
	#draw y
	sw $t1, 400($t0)
	sw $t1, 528($t0)
	sw $t1, 656($t0)
	sw $t1, 408($t0)
	sw $t1, 536($t0)
	sw $t1, 660($t0)
	sw $t1, 664($t0)
	sw $t1, 792($t0)
	sw $t1, 920($t0)
	sw $t1, 916($t0)
	sw $t1, 912($t0)
	#draw E
	sw $t1, 672($t0)
	sw $t1, 676($t0)
	sw $t1, 680($t0)
	sw $t1, 544($t0)
	sw $t1, 416($t0)
	sw $t1, 420($t0)
	sw $t1, 424($t0)
	sw $t1, 288($t0)
	sw $t1, 160($t0)
	sw $t1, 164($t0)
	sw $t1, 168($t0)
	#draw !
	sw $t1, 176($t0)
	sw $t1, 304($t0)
	sw $t1, 432($t0)
	sw $t1, 688($t0)
	li $v0, 32 # sleep
	li $a0, 1000
  j keyboard_input
