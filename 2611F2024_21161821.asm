#YI, Lanxin 
#21161821
#lyiaf@connect.ust.hk 
.data
title: 		.asciiz "COMP2611 Aircraft War Game"

space_string:		.asciiz " "

total_cnt:	.word 1 # the total number of 30 milliseconds

bullet_number:	.word 0 # the number of 30 milliseconds, every 10 * 30 milliseconds, generate a bullet

small_enemy_number:	.word 0 # the number of small enemies, 2 small enemies, one medium boss

medium_enemy_number:	.word 0 # the number of medium enemies, 2 medium enemies, one large boss

bullet_enemy_number:	.word 0 # the number of 30 milliseconds, 40 to generate a bullet for the enemy

input_key:	.word 0 # input key from the player

width:		.word 480 # the width of the screen
height:		.word 700 # the height of the screen

# list of self bullets, 100-119
self_bullet_list:	.word -1:25
# [100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119]
# all the elements are -1 at first, which means no bullet
# if a bullet is created, the id of the bullet will be stored in the list
# if a bullet is destoried, the id of the bullet will be set to -1
self_bullet_address:	.word self_bullet_list

# list of enemies, 500-519
enemy_list:		.word -1:25
# [500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519]
# all the elements are -1 at first, which means no enemy
# if an enemy is created, the id of the enemy will be stored in the list
# if an enemy is destoried, the id of the enemy will be set to -1
enemy_address:	.word enemy_list

# list of enemy bullets, 900-999
enemy_bullet_list:	.word -1:105
# [900, 901, ..., 999]
# all the elements are -1 at first, which means no bullet
# if a bullet is created, the id of the bullet will be stored in the list
# if a bullet is destoried, the id of the bullet will be set to -1
enemy_bullet_address:	.word enemy_bullet_list


# score and left blood
score:		.word 0
left_blood:	.word 20
# destor small enemy: +3, medium enemy: +5, large enemy: +10, the score is obtained by syscall, you should not use 3 5 10 directly

# current_enemy_number
current_enemy_number:	.word 0 # temporary variable to store the current enemy number for your reference
current_enemy_number_2:	.word 0 # temporary variable to store the current enemy number for your reference

# current enemy bullet number
current_enemy_bullet_number:	.word 0 # temporary variable to store the current enemy bullet number for your reference

# current self bullet number
current_self_bullet_number:	.word 0 # temporary variable to store the current self bullet number for your reference

# TODO: [Optional] You can add more data variables here
enemy_blood:		.word -1:25
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.text
main:		
	la $a0, title
	la $t0, width
	lw $a1, 0($t0)
	la $t0, height
	lw $a2, 0($t0)
	li $a3, 1 # 1: play the music, 0: stop the music
	li $v0, 100 # Create the Game Screen
	syscall		
	li $t8, 899


init_game:
	# 1. create the ship
	li $v0, 101
	li $a0, 1 # the id of ship is 1
	li $a1, 180 # the x_loc of ship
	li $a2, 500 # the y_loc of ship
	li $a3, 25 # set the speed
	syscall

m_loop:		
	jal get_time
	add $s6, $v0, $zero # $s6: starting time of the game

	# store s6
	addi $sp, $sp, -4
	sw $s6, 0($sp)
	la $t0, enemy_bullet_list

	jal is_game_over # task 1: 15 points

	jal process_input # task 2: 15 points
	jal generate_self_bullet
	jal move_self_bullet
	jal destory_self_bullet

	jal create_enemy
	jal move_enemy
	jal destory_enemy

	jal generate_enemy_bullet # task 3: 20 points
	jal move_enemy_bullet
	jal destory_enemy_bullet

	jal collide_detection_enemy # task 4: 15 points
	jal collide_detection_shoot_by_enemy # task 5: 15 points
	jal collide_detection_shoot_enemy # task 6: 20 points


	# refresh the screen
	li $v0, 119
	syscall

	# restore s6
	lw $s6, 0($sp)
	addi $sp, $sp, 4
	add $a0, $s6, $zero
	addi $a1, $zero, 30 # iteration gap: 30 milliseconds
	jal have_a_nap

	# total_cnt += 1
	lw $t0, total_cnt
	addi $t0, $t0, 1
	sw $t0, total_cnt


	j m_loop	


#--------------------------------------------------------------------
# func: is_game_over
# Check whether the game is over
# Pseduo code:
# if total_cnt >= 2000, then game over, win (2000 means 2000 * 30 ms)
# if blood <= 0, then game over, lose
#--------------------------------------------------------------------
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# TODO: check the total_cnt and blood {
#is_game_over:
is_game_over:
    lw $t0, total_cnt
    li $t1, 2000
    bge $t0, $t1, game_over_win

    lw $t0, left_blood
    blez $t0, game_over_lose

    jr $ra
    
exit_game:
    li $v0, 10
    syscall

#game_over_win:
game_over_win:
    # ��ʾʤ����Ϣ
    li $v0, 140
    la $a0, 1
    syscall
    j exit_game


#game_over_lose:
game_over_lose:
    # ��ʾʧ����Ϣ
    li $v0, 140
    la $a0, 0
    syscall
    j exit_game

#game_over_win:


#game_over_lose:

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}

#--------------------------------------------------------------------
# func process_input
# Read the keyboard input and handle it!
#--------------------------------------------------------------------
process_input:	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal get_keyboard_input # $v0: the return value
	addi $t0, $zero, 119 # corresponds to key 'w'
	beq $v0, $t0, move_airplane_up
	# TODO: add more key bindings here, e.g., move_airplane_down: key 's', value 115, move_airplane_left: key 'a', value 97, move_airplane_right: key 'd', value 100 {
	addi $t0, $zero, 115
	beq $v0, $t0, move_airplane_down

	addi $t0, $zero, 97
	beq $v0, $t0, move_airplane_left

	addi $t0, $zero, 100
	beq $v0, $t0, move_airplane_right
	#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
	j pi_exit
pi_exit:	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#--------------------------------------------------------------------
# func get_keyboard_input
# $v0: ASCII value of the input character if input is available;
#      otherwise, the value is 0;
#--------------------------------------------------------------------
get_keyboard_input:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	add $v0, $zero, $zero
	lui $a0, 0xFFFF
	lw $a1, 0($a0)
	andi $a1, $a1, 1
	beq $a1, $zero, gki_exit
	lw $v0, 4($a0)


gki_exit:	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


#--------------------------------------------------------------------
# func: move_airplane
# Move the airplane
#--------------------------------------------------------------------
move_airplane_up:
	# if keyboard input is 'w', move the airplane up
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	li $v0, 110 # get the location of the airplane
	li $a0, 1 # id of the airplane
	syscall
	add $s0, $v0, $zero # x location
	add $s1, $v1, $zero # y	location
	
	# judge $s1 - 25 >= 0
	addi $t0, $s1, -25
	bltz $t0, move_airplane_exit
	# move the airplane up
	addi $s1, $s1, -25
	li $v0, 120
	li $a0, 1 # id of the airplane
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	syscall
	j move_airplane_exit

# TODO: add more contents here, e.g., move_airplane_down, move_airplane_left, move_airplane_right, please consider the boundary of the screen {
move_airplane_down:
	# ������������� 's'���������ƶ��ɻ�
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	li $v0, 110  # ��ȡ�ɻ�λ��
	li $a0, 1  # �ɻ�ID
	syscall
	add $s0, $v0, $zero  # xλ��
	add $s1, $v1, $zero  # yλ��
	
	# �ж� $s1 + 25 <= 700
	addi $t0, $s1, 25
	bgt $t0, 700, move_airplane_exit
	# �����ƶ��ɻ�
	addi $s1, $s1, 25
	li $v0, 120
	li $a0, 1  # �ɻ�ID
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	syscall
	j move_airplane_exit


move_airplane_left:
	# ������������� 'a'���������ƶ��ɻ�
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	li $v0, 110  # ��ȡ�ɻ�λ��
	li $a0, 1  # �ɻ�ID
	syscall
	add $s0, $v0, $zero  # xλ��
	add $s1, $v1, $zero  # yλ��
	
	# �ж� $s0 - 25 >= 0
	addi $t0, $s0, -25
	bltz $t0, move_airplane_exit
	# �����ƶ��ɻ�
	addi $s0, $s0, -25
	li $v0, 120
	li $a0, 1  # �ɻ�ID
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	syscall
	j move_airplane_exit

move_airplane_right:
	# ������������� 'd'���������ƶ��ɻ�
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	li $v0, 110  # ��ȡ�ɻ�λ��
	li $a0, 1  # �ɻ�ID
	syscall
	add $s0, $v0, $zero  # xλ��
	add $s1, $v1, $zero  # yλ��
	
	# �ж� $s0 + 25 <= 480
	addi $t0, $s0, 25
	bgt $t0, 480, move_airplane_exit
	# �����ƶ��ɻ�
	addi $s0, $s0, 25
	li $v0, 120
	li $a0, 1  # �ɻ�ID
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	syscall
	j move_airplane_exit

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}

move_airplane_exit:
	lw $ra, 8($sp)
	lw $s0, 4($sp)
	lw $s1, 0($sp)
	addi $sp, $sp, 12
	jr $ra

	
#--------------------------------------------------------------------
# func: generate_self_bullet
# Generate airplane's bullet
#--------------------------------------------------------------------
generate_self_bullet:
	# if bullet_number == 10, generate a bullet, else bullet_number++
	lw $t0, bullet_number
	addi $t1, $zero, 10

	beq $t0, $t1, generate_self_bullet_create
	addi $t0, $t0, 1
	sw $t0, bullet_number
	jr $ra


generate_self_bullet_create:
	# set bullet_number = 0
	addi $t0, $zero, 0
	sw $t0, bullet_number

	# get the location of the airplane
	li $v0, 110
	li $a0, 1 # id of the airplane
	syscall
	add $s0, $v0, $zero # x location
	add $s1, $v1, $zero # y	location

	# create a bullet, id starts from 100
	addi $t0, $zero, 100
	lw $t1, self_bullet_address
	la $t2, self_bullet_list

	# difference between t1 and t2
	sub $t2, $t1, $t2

	# t2 = t2 / 4
	srl $t2, $t2, 2

	beq $t2, 20, generate_self_bullet_from_beginning

	add $t0, $t0, $t2

	# store t0 to t1-th element of self_bullet_list
	sw $t0, 0($t1)

	addi $t1, $t1, 4
	sw $t1, self_bullet_address

	li $v0, 106 # create a bullet
	move $a0, $t0 # the id of the bullet
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	add $a3, $s2, $zero
	syscall

	jr $ra

generate_self_bullet_from_beginning:
	la $t2, self_bullet_list
	sw $t2, self_bullet_address
	j generate_self_bullet_create

#--------------------------------------------------------------------
# func: move_self_bullet
# Move the airplane's bullet
#--------------------------------------------------------------------
move_self_bullet:
	# find all the bullets in the self_bullet_list
	la $t0, self_bullet_list
	li $t3, -1

	j find_all_self_bullet


find_all_self_bullet:
	# get the first element of self_bullet_list
	lw $t1, ($t0)

	# if t3 == 20 then exit
	beq $t3, 20, move_self_bullet_exit
	addi $t3, $t3, 1

	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_available


	# get the location of the bullet
	move $a0, $t1
	li $v0, 110
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location

	j move_self_bullet_up


continue_find_next_available:
	addi $t0, $t0, 4
	j find_all_self_bullet

move_self_bullet_up:

	addi $s1, $s1, -6
	move $a0, $t1
	move $a1, $s0
	move $a2, $s1


	li $v0, 120
	syscall

	addi $t0, $t0, 4
	j find_all_self_bullet
	
move_self_bullet_exit:
	jr $ra

#--------------------------------------------------------------------
# func: destory_self_bullet
# Destory the airplane's bullet if it is out of the screen
#--------------------------------------------------------------------
destory_self_bullet:
	# find all the bullets in the self_bullet_list
	la $t0, self_bullet_list
	li $t3, -1

	j find_all_self_bullet_destory

find_all_self_bullet_destory:
	# get the first element of self_bullet_list
	lw $t1, ($t0)

	# if t3 == 20 then exit
	beq $t3, 20, destory_self_bullet_exit
	addi $t3, $t3, 1

	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_available_destory

	# get the location of the bullet
	move $a0, $t1
	li $v0, 110
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location

	# if y location <= 0, destory the bullet
	bltz $s1, destory_self_bullet_destory

	addi $t0, $t0, 4
	j find_all_self_bullet_destory

continue_find_next_available_destory:
	addi $t0, $t0, 4
	j find_all_self_bullet_destory

destory_self_bullet_destory:
	# destory the bullet
	move $a0, $t1
	li $v0, 116
	syscall

	# set the bullet to -1
	addi $t2, $zero, -1
	sw $t2, ($t0)

	addi $t0, $t0, 4
	j find_all_self_bullet_destory

destory_self_bullet_exit:
	jr $ra

#--------------------------------------------------------------------
# func: create_enemy
# Create the enemy
#--------------------------------------------------------------------
create_enemy:
	# if total_cnt % 120 == 0, create an enemy
	lw $t0, total_cnt
	addi $t1, $zero, 120
	div $t0, $t1
	mfhi $t2
	beq $t2, $zero, create_enemy_generate

	jr $ra

create_enemy_generate:
	# create an enemy, id starts from 500
	# small_enemy_number += 1
	lw $t7, small_enemy_number
	addi $t7, $t7, 1
	sw $t7, small_enemy_number

	addi $t0, $zero, 500
	lw $t1, enemy_address
	la $t2, enemy_list

	# difference between t1 and t2
	sub $t2, $t1, $t2

	# t2 = t2 / 4
	srl $t2, $t2, 2

	beq $t2, 20, create_enemy_from_beginning

	add $t0, $t0, $t2

	# store t0 to t1-th element of enemy_list
	sw $t0, 0($t1)

	addi $t1, $t1, 4
	sw $t1, enemy_address

	# judge small_enemy_number == 3
	lw $t4, small_enemy_number
	addi $t5, $zero, 3
	beq $t4, $t5, create_enemy_boss_1

	li $v0, 130 # create an enemy
	move $a0, $t0 # the id of the enemy
	li $a1, 1
	syscall

	jr $ra

create_enemy_boss_1:

	# compare medium_enemy_number == 2
	lw $t4, medium_enemy_number
	addi $t5, $zero, 2
	beq $t4, $t5, create_enemy_boss_2

	# medium_enemy_number += 1
	lw $t7, medium_enemy_number
	addi $t7, $t7, 1
	sw $t7, medium_enemy_number

	sw $zero, small_enemy_number

	li $v0, 130 # create an enemy
	move $a0, $t0 # the id of the enemy
	li $a1, 2
	syscall

	jr $ra

create_enemy_boss_2:

	sw $zero, medium_enemy_number
	sw $zero, small_enemy_number

	li $v0, 130 # create an enemy
	move $a0, $t0 # the id of the enemy
	li $a1, 3
	syscall

	jr $ra


create_enemy_from_beginning:
	la $t2, enemy_list
	sw $t2, enemy_address
	j create_enemy_generate

#--------------------------------------------------------------------
# func: move_enemy
# Move the enemy automatically
#--------------------------------------------------------------------
move_enemy:
	# find all the enemies in the enemy_list
	la $t0, enemy_list
	li $t3, -1

	j find_all_enemy

find_all_enemy:
	# get the first element of enemy_list
	lw $t1, ($t0)

	# if t3 == 20 then exit
	beq $t3, 20, move_enemy_exit
	addi $t3, $t3, 1

	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_available_enemy

	# get the location of the enemy
	move $a0, $t1
	li $v0, 110
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location

	j move_enemy_down


continue_find_next_available_enemy:
	addi $t0, $t0, 4
	j find_all_enemy

move_enemy_down:

	addi $s1, $s1, 2
	move $a0, $t1
	move $a1, $s0
	move $a2, $s1


	li $v0, 120
	syscall

	addi $t0, $t0, 4
	j find_all_enemy

move_enemy_exit:
	jr $ra

#--------------------------------------------------------------------
# func: destory_enemy
# Destory the enemy if it is out of the screen
#--------------------------------------------------------------------
destory_enemy:
	# find all the enemies in the enemy_list
	la $t0, enemy_list
	li $t3, -1

	j find_all_enemy_destory

find_all_enemy_destory:

	# get the first element of enemy_list
	lw $t1, ($t0)

	# if t3 == 20 then exit
	beq $t3, 20, destory_enemy_exit
	addi $t3, $t3, 1

	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_available_enemy_destory

	# get the location of the enemy
	move $a0, $t1
	li $v0, 110
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location

	# if y location >= 700, destory the enemy
	addi $t7, $s1, -700
	bgez $t7, destory_enemy_destory

	addi $t0, $t0, 4
	j find_all_enemy_destory

continue_find_next_available_enemy_destory:
	addi $t0, $t0, 4
	j find_all_enemy_destory

destory_enemy_destory:
	# destory the enemy
	move $a0, $t1
	li $v0, 116
	syscall

	# set the enemy to -1
	addi $t2, $zero, -1
	sw $t2, ($t0)

	addi $t0, $t0, 4
	j find_all_enemy_destory

destory_enemy_exit:
	jr $ra

#--------------------------------------------------------------------
# func: generate_enemy_bullet
# Generate enemy's bullet, each 40 * 30 milliseconds, generate a bullet
#--------------------------------------------------------------------
generate_enemy_bullet:
	la $t0, enemy_list
	li $t3, -1
	la $t6, enemy_bullet_list

	# if total_cnt % 41 == 0, generate a bullet
	lw $t4, total_cnt
	addi $t1, $zero, 41
	div $t4, $t1
	mfhi $t2
	beq $t2, $zero, generate_enemy_bullet_create

	jr $ra

# TODO: add more contents here {
generate_enemy_bullet_create:
# Pseduo code
# enemy_bullet_list: array of enemy bullets from 900 to 999, 100 slots. Consider circular search.
# enemy_list: array of enemies from 500 to 519, 20 slots. Consider circular search.
# for each enemy in enemy_list:
# 	if enemy != -1:
#		get the location of the enemy with syscall 110
#		generate a bullet for the enemy
#		if enemy is type 1:
#			generate a bullet for the enemy
#		if enemy is type 2:
#			generate two bullets for the enemy
#		if enemy is type 3:
#			generate three bullets for the enemy
#   else: continue to the next enemy
	# ��ȡ�����б��еĵ�ǰ����
	lw $t1, 0($t0)
	# �������idΪ-1�������Ѱ����һ��
	beq $t1, -1, continue_find_next_enemy
	# if t3 == 20 then exit
	beq $t3, 20, generate_enemy_bullet_exit
	addi $t3, $t3, 1

	# ��ȡ���˵�λ��
	move $a0, $t1
	li $v0, 110
	syscall
	move $s0, $v0 # xλ��
	move $s1, $v1 # yλ��
	
	addi $t0, $t0, 4 #����list
	addi $t1, $t1, -500
	div $t1, $t1, 9       # �Խ��ȡģ
	mfhi $t2              # ��ȡ�������洢�� $t2
	beqz $t2, generate_bullet_instance_type1
	beq $t2, 1, generate_bullet_instance_type1
	beq $t2, 2, generate_bullet_instance_type2
	beq $t2, 3, generate_bullet_instance_type1
	beq $t2, 4, generate_bullet_instance_type1
	beq $t2, 5, generate_bullet_instance_type2
	beq $t2, 6, generate_bullet_instance_type1
	beq $t2, 7, generate_bullet_instance_type1
	beq $t2, 8, generate_bullet_instance_type3
# continue_find_next_enemy:
continue_find_next_enemy:
	addi $t0, $t0, 4
	beq $t3, 20, generate_enemy_bullet_exit
	addi $t3, $t3, 1
	j generate_enemy_bullet_create

# generate_bullet_instance_type1:
# Pseduo code:
# create a bullet, id starts from 900
# store the id into the enemy_bullet_list and maintain the pointer
# get the location of the enemy
# store the location of the enemy to the bullet
# syscall 106 to create a bullet, with bullet_type is 1
generate_bullet_instance_type1:
	lw $t6, enemy_bullet_address
	la $t7, enemy_bullet_list

	# ���㵱ǰ�ӵ���ַƫ��
	sub $t7, $t6, $t7
	srl $t7, $t7, 2

	beq $t7, 100, reset_enemy_bullet_address
	
	addi $t8, $t7, 900

	# ���ӵ�id�洢���ӵ��б���
	sw $t8, 0($t6)

	# �����ӵ���ַ
	addi $t6, $t6, 4
	sw $t6, enemy_bullet_address
	
	# ����ϵͳ���ô�����һ���ӵ�
	li $v0, 106
	move $a0, $t8 # �ӵ���id
	move $a1, $s0
	move $a2, $s1
	li $a3, 1 # �ӵ�����1
	syscall

	j generate_enemy_bullet_create
# generate_bullet_instance_type2:
# Pseduo code:
# create a bullet, id starts from 900
# store the id into the enemy_bullet_list and maintain the pointer
# get the location of the enemy
# store the location of the enemy to the bullet
# syscall 106 to create a bullet, with bullet_type is 2 and 3
generate_bullet_instance_type2:
	lw $t6, enemy_bullet_address
	la $t7, enemy_bullet_list

	# ���㵱ǰ�ӵ���ַƫ��
	sub $t7, $t6, $t7
	srl $t7, $t7, 2

	beq $t7, 100, reset_enemy_bullet_address
	
	addi $t8, $t7, 900

	# ���ӵ�id�洢���ӵ��б���
	sw $t8, 0($t6)

	# �����ӵ���ַ
	addi $t6, $t6, 4
	sw $t6, enemy_bullet_address
	
	li $v0, 106
	move $a0, $t8 # �ӵ���id
	move $a1, $s0
	move $a2, $s1
	li $a3, 2 # �ӵ�����2
	syscall

	# �����ӵ�id
	addi $t7, $t7, 1
	beq $t7, 100, reset_enemy_bullet_address
	addi $t8, $t7, 900

	# ���ӵ�id�洢���ӵ��б���
	sw $t8, 0($t6)

	# �����ӵ���ַ
	addi $t6, $t6, 4
	sw $t6, enemy_bullet_address

	# ����ϵͳ���ô����ڶ����ӵ�
	li $v0, 106
	move $a0, $t8 # �ӵ���id
	move $a1, $s0
	move $a2, $s1
	li $a3, 3 # �ӵ�����3
	syscall

	j generate_enemy_bullet_create
# generate_bullet_instance_type3:
# Pseduo code:
# create a bullet, id starts from 900
# store the id into the enemy_bullet_list and maintain the pointer
# get the location of the enemy
# store the location of the enemy to the bullet
# syscall 106 to create a bullet, with bullet_type is 4, 5 and 6
generate_bullet_instance_type3:
	lw $t6, enemy_bullet_address
	la $t7, enemy_bullet_list

	# ���㵱ǰ�ӵ���ַƫ��
	sub $t7, $t6, $t7
	srl $t7, $t7, 2

	beq $t7, 100, reset_enemy_bullet_address
	
	addi $t8, $t7, 900

	# ���ӵ�id�洢���ӵ��б���
	sw $t8, 0($t6)

	# �����ӵ���ַ
	addi $t6, $t6, 4
	sw $t6, enemy_bullet_address
	
	# ����ϵͳ���ô�����һ���ӵ�
	li $v0, 106
	move $a0, $t8 # �ӵ���id
	move $a1, $s0
	move $a2, $s1
	li $a3, 4 # �ӵ�����4
	syscall

	# �����ӵ�id
	addi $t7, $t7, 1
	beq $t7, 100, reset_enemy_bullet_address
	addi $t8, $t7, 900

	# ���ӵ�id�洢���ӵ��б���
	sw $t8, 0($t6)

	# �����ӵ���ַ
	addi $t6, $t6, 4
	sw $t6, enemy_bullet_address

	# ����ϵͳ���ô����ڶ����ӵ�
	li $v0, 106
	move $a0, $t8 # �ӵ���id
	move $a1, $s0
	move $a2, $s1
	li $a3, 5 # �ӵ�����5
	syscall

	# �����ӵ�id
	addi $t7, $t7, 1
	beq $t7, 100, reset_enemy_bullet_address
	addi $t8, $t7, 900

	# ���ӵ�id�洢���ӵ��б���
	sw $t8, 0($t6)

	# �����ӵ���ַ
	addi $t6, $t6, 4
	sw $t6, enemy_bullet_address

	# ����ϵͳ���ô����������ӵ�
	li $v0, 106
	move $a0, $t8 # �ӵ���id
	move $a1, $s0
	move $a2, $s1
	li $a3, 6 # �ӵ�����6
	syscall

	j generate_enemy_bullet_create
	
reset_enemy_bullet_address:
	# �����ӵ���ַָ��
	la $t5, enemy_bullet_list
	sw $t5, enemy_bullet_address
	li $t7, 0
	j generate_enemy_bullet_create


generate_enemy_bullet_exit:
	jr $ra

# continue_find_next_enemy:

# generate_bullet_instance_type1:
# Pseduo code:
# create a bullet, id starts from 900
# store the id into the enemy_bullet_list and maintain the pointer
# get the location of the enemy
# store the location of the enemy to the bullet
# syscall 106 to create a bullet, with bullet_type is 1

# generate_bullet_instance_type2:
# Pseduo code:
# create a bullet, id starts from 900
# store the id into the enemy_bullet_list and maintain the pointer
# get the location of the enemy
# store the location of the enemy to the bullet
# syscall 106 to create a bullet, with bullet_type is 2 and 3

# generate_bullet_instance_type3:
# Pseduo code:
# create a bullet, id starts from 900
# store the id into the enemy_bullet_list and maintain the pointer
# get the location of the enemy
# store the location of the enemy to the bullet
# syscall 106 to create a bullet, with bullet_type is 4, 5 and 6

# Note: enemy type is different from bullet type. Enemy type 1: small enemy, 2: medium enemy, 3: large enemy
# small enemy: bullet_type 1, medium enemy: bullet_type 2 and 3, large enemy: bullet_type 4, 5 and 6



# generate_enemy_bullet_exit:
#	 jr $ra

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}

#--------------------------------------------------------------------
# func: move_enemy_bullet
# Move the enemy's bullet
#--------------------------------------------------------------------
move_enemy_bullet:
	# find all the bullets in the enemy_bullet_list
	la $t0, enemy_bullet_list
	li $t3, -1

	j find_all_enemy_bullet

find_all_enemy_bullet:
	# get the first element of enemy_bullet_list
	lw $t1, ($t0)

	# if t3 == 100 then exit
	beq $t3, 100, move_enemy_bullet_exit
	addi $t3, $t3, 1

	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_enemy_bullet

	# get the location of the bullet
	move $a0, $t1
	li $v0, 110
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location
	andi $s2, $a1, 3 # type, here are only 3 types 0 1 2

	# if s2 == 1, move_enemy_bullet_down
	addi $t7, $zero, 1
	beq $s2, 1, move_enemy_bullet_down

	# if s2 == 2, move_enemy_bullet_right_down
	addi $t7, $zero, 2
	beq $s2, 2, move_enemy_bullet_right_down

	# if s2 == 0, move_enemy_bullet_left_down
	addi $t7, $zero, 0
	beq $s2, 0, move_enemy_bullet_left_down


continue_find_next_enemy_bullet:
	addi $t0, $t0, 4
	j find_all_enemy_bullet

move_enemy_bullet_down: # 1
	
	addi $s1, $s1, 3
	move $a0, $t1
	move $a1, $s0
	move $a2, $s1

	li $v0, 120
	syscall

	addi $t0, $t0, 4
	j find_all_enemy_bullet

move_enemy_bullet_right_down: # 0

	addi $s0, $s0, 2
	addi $s1, $s1, 3
	move $a0, $t1
	move $a1, $s0
	move $a2, $s1

	li $v0, 120
	syscall

	addi $t0, $t0, 4
	j find_all_enemy_bullet

move_enemy_bullet_left_down: # 2
	addi $s0, $s0, -2
	addi $s1, $s1, 3
	move $a0, $t1
	move $a1, $s0
	move $a2, $s1

	li $v0, 120
	syscall

	addi $t0, $t0, 4
	j find_all_enemy_bullet

move_enemy_bullet_exit:
	jr $ra

#--------------------------------------------------------------------
# func: destory_enemy_bullet
# Destory the enemy's bullet if it is out of the screen
#--------------------------------------------------------------------
destory_enemy_bullet:
	# find all the bullets in the enemy_bullet_list
	la $t0, enemy_bullet_list
	li $t3, -1

	j find_all_enemy_bullet_destory

find_all_enemy_bullet_destory:

	# get the first element of enemy_bullet_list
	lw $t1, ($t0)

	# if t3 == 100 then exit
	beq $t3, 100, destory_enemy_bullet_exit
	addi $t3, $t3, 1

	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_enemy_bullet_destory

	# get the location of the bullet
	move $a0, $t1
	li $v0, 110
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location
	andi $s2, $a1, 3 # type, here are only 3 types 0 1 2

	# if y location >= 700, destory the bullet
	addi $t7, $s1, -700
	bgez $t7, destory_enemy_bullet_destory

	addi $t0, $t0, 4
	j find_all_enemy_bullet_destory

continue_find_next_enemy_bullet_destory:
	addi $t0, $t0, 4
	j find_all_enemy_bullet_destory

destory_enemy_bullet_destory:
	# destory the bullet
	move $a0, $t1
	li $v0, 116
	syscall

	# set the bullet to -1
	addi $t2, $zero, -1
	sw $t2, ($t0)

	addi $t0, $t0, 4
	j find_all_enemy_bullet_destory

destory_enemy_bullet_exit:
	jr $ra

#--------------------------------------------------------------------
# func: collide_detection_enemy
# Detect whether the airplane crashes with the enemy
#--------------------------------------------------------------------

collide_detection_enemy:
	# get the location of the airplane
	li $v0, 110
	li $a0, 1 # id of the airplane
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location
	move $s7, $a2 # blood left

	# find all the enemies in the enemy_list
	la $t0, enemy_list
	li $t3, -1

 	j find_all_enemy_collide

# TODO: add more contents here {

find_all_enemy_collide:
	# ��ȡ�����б��еĵ�ǰ����
	lw $t1, 0($t0)
	# �������idΪ-1�������Ѱ����һ��
	beq $t1, -1, continue_find_next_enemy_collision
	
	# ��ȡ���˵�λ��
	move $a0, $t1
	li $v0, 110
	syscall
	move $s6, $a3
	#x_enemy  y_enemy
	move $s0, $v0
	move $s1, $v1
	# ��ȡ width
	andi $t2, $a1, 0x3FFC000   # ���ε�����λ��ֻ���� width ����
	srl $t2, $t2, 14           # ����14λ���� width �ƶ��������Чλ
	# ��ȡ height
	andi $s4, $a1, 0x3FFC  # ���ε�����λ��ֻ���� height ����
	srl $s4, $s4, 2            # ����2λ���� height �ƶ��������Чλ

	j collide_detection_enemy_with_airplane
	
continue_find_next_enemy_collision:
	addi $t0, $t0, 4
	# if t3 == 20 then exit
	beq $t3, 20, collide_detection_enemy_exit
	addi $t3, $t3, 1
	j find_all_enemy_collide
	
# Pseduo code:
# for each enemy in enemy_list:
# 	if enemy != -1:
#		get the location of the enemy with syscall 110
#		jump to collide_detection_enemy_with_airplane
#   else: continue to the next enemy


collide_detection_enemy_with_airplane:
# This is the basic function for collision detection, you can use this function to detect the collision between the airplane and the enemy
# These three collide_detection functions all have one basic function, they are extremely similar except for some minor different variables
# Pseduo code:
# x_enermy, y_enermy, width, height, x_self, y_self
# if (x_self <= x_enermy + width && x_self + 102 >= x_enermy && y_self <= y_enermy + height && y_self + 126 >= y_enermy), collide, where 102 is the width of the airplane, 126 is the height of the airplane
# if collide, destory the enemy, set the enemy to -1, blood left -= enemy attribute, score += enemy attribute, update the blood left, update the score, check the next enemy
# else: check the next enemy
	li $v0, 110
	li $a0, 1
	syscall
	addi $t5, $v0, 102  
	addi $t7, $v1, 126
	
	add $s2, $s0, $t2 		#x_enemy + width 
	ble $v0, $s2, check_cond2  # ��� x_self <= x_enemy + width�������һ������
    	j continue_find_next_enemy_collision             # ������ת����һ���л�
    	
check_cond2:
    	# ��ײ���� 2: x_self + 102 >= x_enemy
    	bge $t5, $s0, check_cond3  # ��� x_self + 102 >= x_enemy�������һ������
    	j continue_find_next_enemy_collision           # ������ת����һ���л�

check_cond3:
    	# ��ײ���� 3: y_self <= y_enemy + height
    	add $s3, $s1, $s4
    	ble $v1, $s3, check_cond4  # ��� y_self <= y_enemy + height�������һ������
    	j continue_find_next_enemy_collision          # ������ת����һ���л�

check_cond4:
    	# ��ײ���� 4: y_self + 126 >= y_enemy
    	bge $t7, $s1, collide      # ��� y_self + 126 >= y_enemy��������ײ
    	j continue_find_next_enemy_collision          # ������ת����һ���л�

collide:
    	# ��ײ�����߼�
	move $a0, $t1
	li $v0, 116
	syscall
	li $t1, -1
	sw $t1, ($t0)
	
	lw $s4, score
	lw $s5, left_blood
	
	add $s4, $s4, $s6
	sw $s4, score
	sub $s5, $s5, $s6
	sw $s5, left_blood
	li $v0, 117
	move $a0, $s4
	move $a1, $s5
	syscall
	 
	j continue_find_next_enemy_collision

collide_detection_enemy_exit:
	jr $ra

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}


#--------------------------------------------------------------------
# func: collide_detection_shoot_by_enemy
# Detect whether the airplane is shot by the enemy
#--------------------------------------------------------------------
collide_detection_shoot_by_enemy:
	# get the location of the airplane
	li $v0, 110
	li $a0, 1 # id of the airplane
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location
	move $s7, $a2 # blood left

	# find all the bullets in the enemy_bullet_list
	la $t0, enemy_bullet_list
	li $t3, -1

	j find_all_enemy_bullet_shoot

# TODO: add more contents here {
# find_all_enemy_bullet_shoot:
# Pseduo code:
# for each bullet in enemy_bullet_list:
# 	if bullet != -1:
#		get the location of the bullet with syscall 110
#		jump to collide_detection_shoot_by_enemy_down
#   else: jump to continue to the next bullet
find_all_enemy_bullet_shoot:
	lw $t1, 0($t0)
	# ���idΪ-1�������Ѱ����һ��
	beq $t1, -1, continue_find_next_enemy_bullet_shoot
	
	# ��ȡ�ӵ���λ��
	move $a0, $t1
	li $v0, 110
	syscall
	move $s0, $v0 # xλ��
	move $s1, $v1 # yλ��
	
	j collide_detection_shoot_by_enemy_down
	
continue_find_next_enemy_bullet_shoot:
	addi $t0, $t0, 4
	beq $t3, 100, collide_detection_shoot_by_enemy_exit
	addi $t3, $t3, 1
	j find_all_enemy_bullet_shoot
	

collide_detection_shoot_by_enemy_down:
	li $v0, 110
	li $a0, 1
	syscall
	addi $t5, $v0, 102  
	addi $t7, $v1, 126
	
	addi $t8, $s0, 5
	ble $v0, $t8, check_condi2  # �����һ������
    	j continue_find_next_enemy_bullet_shoot             # ������ת����һ���л�

check_condi2:
	bge $t5, $s0, check_condi3  # �����һ������
    	j continue_find_next_enemy_bullet_shoot             # ������ת����һ���л�
    	
check_condi3:
	addi $t9, $s1, 11
	ble $v1, $t9, check_condi4  # �����һ������
    	j continue_find_next_enemy_bullet_shoot             # ������ת����һ���л�
    	
check_condi4:
	bge $t7, $s1, shot
	j continue_find_next_enemy_bullet_shoot             # ������ת����һ���л�
	
shot:
	# ��ײ�����߼�
	move $a0, $t1
	li $v0, 116
	syscall
	li $t1, -1
	sw $t1, ($t0)
	
	lw $s4, score
	lw $s5, left_blood
	
	addi $s5, $s5, -1
	sw $s5, left_blood
	li $v0, 117
	move $a0, $s4
	move $a1, $s5
	syscall
	 
	j continue_find_next_enemy_bullet_shoot
# Basic function for collision detection, you can use this function to detect the collision between the airplane and the enemy's bullet
# Pseduo code:
# x_bullet, y_bullet, x_self, y_self
# if (x_self <= x_bullet + 5 && x_self + 102 >= x_bullet && y_self <= y_bullet + 11 && y_self + 126 >= y_bullet), collide, where 102 is the width of the airplane, 126 is the height of the airplane
# if collide, destory the bullet, set the bullet to -1, self blood left -= 1, score unchanged, check the next bullet
# else: check the next bullet

collide_detection_shoot_by_enemy_exit:
	jr $ra
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}


#--------------------------------------------------------------------
# func: collide_detection_shoot_enemy
# Detect whether the enemy is shoot by the airplane
#--------------------------------------------------------------------
collide_detection_shoot_enemy:
	# find all the bullets in the bullet_list
	la $t0, self_bullet_list
	li $t3, -1 # like counter
	j find_all_bullet

# TODO: add more contents here {

find_all_bullet:
# Pseduo code:
# for each bullet in bullet_list:
# 	if bullet != -1:
#		get the location of the bullet with syscall 110
#		jump to collide_detection_shoot_enemy_down
#   else: jump to continue to the next bullet
	lw $t1, ($t0)
	beq $t1, -1, continue_find_next_bullet
	
	
	# ��ȡ�ӵ���λ��
	move $a0, $t1
	li $v0, 110
	syscall
	move $s0, $v0 # xλ��
	move $s1, $v1 # yλ��
	
	#addi $t0, $t0, 4 #����list
	j collide_detection_shoot_enemy_down


collide_detection_shoot_enemy_down:
	# get all the enemies in the enemy_list

	la $s6, enemy_list
	li $t5, -1 # like counter
	
	j find_all_enemy_in_enemy_list
	
	

find_all_enemy_in_enemy_list:
# Pseduo code:
# for each enemy in enemy_list:
# 	if enemy != -1:
#		get the location of the enemy with syscall 110
#		jump to judge_hit_enermy
#   else: continue to the next enemy
	lw $t2, 0($s6)
	beq $t2, -1, continue_find_next_enemy_in_enemy_list
	
	
	# ��ȡ���˵�λ��
	move $a0, $t2
	li $v0, 110
	syscall
	# ��ȡ width
	andi $s2, $a1, 0x3FFC000   # ���ε�����λ��ֻ���� width ����
	srl $s2, $s2, 14           # ����14λ���� width �ƶ��������Чλ
	# ��ȡ height
	andi $s4, $a1, 0x3FFC  # ���ε�����λ��ֻ���� height ����
	srl $s4, $s4, 2            # ����2λ���� height �ƶ��������Чλ
	
	la $s5, enemy_list
	sub $s5, $s6, $s5
	la $a2, enemy_blood
	add $a2, $s5, $a2
	
	lw $s5, ($a2)
	beq $s5, -1, fill_original
	
	j judge_hit_enermy

fill_original:
	sw $a3, ($a2) #syscall��$a3
	addi $s6, $s6, 4
	j judge_hit_enermy
	
# judge_hit_enermy:
# Basic function for collision detection, you can use this function to detect the collision between the enemy and the airplane's bullet.
# Pseduo code:
# x_bullet, y_bullet, width, height, x_enemy, y_enemy
# if (x_enemy <= x_bullet + 5 && x_enemy + width >= x_bullet && y_enemy <= y_bullet + 11 && y_enemy + height >= y_bullet), collide
# if collide, destory the bullet, set the bullet to -1, enemy blood left -= 1
# if enemy blood left <= 0, destory the enemy, set the enemy to -1, score += enemy attribute, update the score, check the next enemy
# else: check the next enemy
judge_hit_enermy:
	addi $t8, $s0, 5
	ble $v0, $t8, check_condit2  # �����һ������
    	j continue_find_next_enemy_in_enemy_list            # ������ת����һ���л�

check_condit2:
	add $s3, $v0, $s2
	bge $s3, $s0, check_condit3  # �����һ������
    	j continue_find_next_enemy_in_enemy_list             # ������ת����һ���л�
    	
check_condit3:
	addi $t9, $s1, 11
	ble $v1, $t9, check_condit4  # �����һ������
    	j continue_find_next_enemy_in_enemy_list             # ������ת����һ���л�
    	
check_condit4:
	add $t7, $v1, $s4
	bge $t7, $s1, shoot
	j continue_find_next_enemy_in_enemy_list            # ������ת����һ���л�
	
shoot:
	# ��ײ�����߼�
	move $a0, $t1
	li $v0, 116
	syscall
	li $t1, -1
	sw $t1, ($t0)
	
	lw $s5, ($a2)
	addi $s5, $s5, -1
	sw $s5, ($a2)	
	
	beqz $s5, destroy_enemy 
	 
	j continue_find_next_enemy_in_enemy_list

destroy_enemy:
	move $a0, $t2
	li $v0, 116
	syscall 
	li $t2, -1
	sw $t2, ($s6)
	
	lw $s7, score
	add $s7, $s7, $a3
	sw $s7, score
	
	lw $a1, left_blood
	move $a0, $s7
	li $v0, 117
	syscall
	
	j continue_find_next_enemy_in_enemy_list

continue_find_next_enemy_in_enemy_list:
	addi $s6, $s6, 4
	beq $t5, 20, continue_find_next_bullet
	addi $t5, $t5, 1
	j find_all_enemy_in_enemy_list

continue_find_next_bullet:

	addi $t0, $t0, 4
	
	
	beq $t3, 20, collide_detection_shoot_enemy_exit
	addi $t3, $t3, 1
	j find_all_bullet

collide_detection_shoot_enemy_exit:
	jr $ra

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}



#--------------------------------------------------------------------
# func: get_time
# Get the current time
# $v0 = current time
#--------------------------------------------------------------------
get_time:	li $v0, 30
		syscall # this syscall also changes the value of $a1
		andi $v0, $a0, 0x3FFFFFFF # truncated to milliseconds from some years ago
		jr $ra

#--------------------------------------------------------------------
# func: have_a_nap(last_iteration_time, nap_time)
# Let the program sleep for a while
#--------------------------------------------------------------------
have_a_nap:
	addi $sp, $sp, -8
	sw $ra, 4($sp)
	sw $s0, 0($sp)
	add $s0, $a0, $a1
	jal get_time
	sub $a0, $s0, $v0
	slt $t0, $zero, $a0 
	bne $t0, $zero, han_p
	li $a0, 1 # sleep for at least 1ms
han_p:	li $v0, 32 # syscall: let mars java thread sleep $a0 milliseconds
	syscall
	lw $ra, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 8
	jr $ra
