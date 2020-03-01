
		.data
		.eqv buffer_len 5000 # rozmiar bufora
		.eqv var -150 #wartoœæ wspó³czynnika kontrastu *100
		.eqv mode 1 #0-kontrast/1-histogram
buff:		.space 4
offset:		.space 4
size:		.space 4
width:		.space 4
height:		.space 4
buffer:		.space buffer_len

msgIntro:	.asciiz "   Kontrast bmp    \n"
msgIntro1:	.asciiz "   Histogram bmp    \n"
msgTemp:	.asciiz "Wczytano: "
msgFileExc:	.asciiz "Blad zwiazany z plikiem\n"
fileNameIn:	.asciiz "test4.bmp"
fileNameOut:	.asciiz "out.bmp"

		.text
		.globl main

main:
	la $a0, msgIntro
	li $t7, mode
	beqz  $t7, msg
	la $a0, msgIntro1
	
msg:
	# wyswietlenie informacji startowej:
	li $v0, 4
	syscall
	
readFile:
	# otworzenie pliku:
	la $a0, fileNameIn
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall	
	
	move $t9, $v0 		# deskryptor pliku do $t9
	
	bltz $t9, fileExc
	
	# odczytanie 2 bajtow 'BM':
	move $a0, $t9
	la $a1, buff
	li $a2, 2
	li $v0, 14
	syscall
	
	# odczytanie 4 bajtow okreslajacych rozmiar pliku
	la $a1, size
	li $a2, 4
	li $v0, 14
	syscall
	
	lw $s0, size		# zapisanie rozmiaru w $s0
	
	# odczytanie 4 bajtow zarezerwowanych:
	la $a1, buff
	li $a2, 4
	li $v0, 14
	syscall
	
	# odczytanie offsetu:
	la $a1, offset
	li $a2, 4
	li $v0, 14
	syscall
	
	lw $s1, offset			# zapisanie offset do $s1
	
	# odczytanie 4 bajtow naglowka informacyjnego:
	la $a1, buff
	li $a2, 4
	li $v0, 14
	syscall
	
	# odczytanie szerokosci obrazka:
	la $a1, width
	li $a2, 4
	li $v0, 14
	syscall
	
	lw $s2, width			# zaladowanie width do $s2
	
	
	# odczytanie wysokosci obrazka:
	la $a1, height
	li $a2, 4
	li $v0, 14
	syscall
	
	lw $a3, height			# zaladowanie width do $s2
	
	mul $a3, $a3, $s2		#ilosc pikseli
	
	# zamkniecie pliku:
	li $v0, 16
	syscall
	
openFiles:
	# ponowne otworzenie pliku:
	la $a0, fileNameIn
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall	
	
	move $t9, $v0 		# deskryptor pliku do $t9
	
	bltz $t9, fileExc
	
	# otworzenie pliku wynikowego:
	la $a0, fileNameOut
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall	
	
	move $t8, $v0 		# deskryptor pliku do $t8
	
	bltz $t8, fileExc
	
	move $a0, $t9
	li $v0, 14
	la $a1, buffer
	li $a2, buffer_len		# wczytanie tylu bajtow, ile ma buffor
	syscall

paddingCheck:
		
	la $s3, buffer
	add $s3, $s3, $s1	# przejscie na poczatek tabeli pikseli(offset)
	
	la $s4, ($s1) # licznik bajtow w buforze
	li $s5, 0 # licznik bajtow w wierszu
	
	li $t3, 4
	mul $s2, $s2, 3		#width*3
	divu $s2, $t3		
	mfhi $s6		# reszta z dzielenia width*3(bity w wierszu)/ 4 do $s4(padding)
	beqz $t7, contrast

histogram:
	li $t1 0 #max blue
	li $t2 0 #max green
	li $t3 0 #max red
	li $t4 255 #min blue
	li $t5 255 #min green
	li $t6 255 #min red
	li $s1, 0
bluemax:
	li $s7, 0 # licznik paddingu
	jal check
	lbu $t0, ($s3)
	addi $s3, $s3, 1	# przejscie o kolejny bajt
	addi $s4, $s4, 1	# zwiekszenie licznika
	addi $s5, $s5, 1	# zwiekszenie licznika
	ble  $t0, $t1, bluemin
	la $t1, ($t0)
	
bluemin:	
	bge   $t0, $t4, greenmax
	la $t4, ($t0)
	
greenmax:
	jal check
	lbu $t0, ($s3)
	addi $s3, $s3, 1	# przejscie o kolejny bajt
	addi $s4, $s4, 1	# zwiekszenie licznika
	addi $s5, $s5, 1	# zwiekszenie licznika
	ble  $t0, $t2, greenmin
	la $t2, ($t0)
	
greenmin:	
	bge   $t0, $t5, redmax
	la $t5, ($t0)
	
redmax:
	jal check
	lbu $t0, ($s3)
	addi $s3, $s3, 1	# przejscie o kolejny bajt
	addi $s4, $s4, 1	# zwiekszenie licznika
	addi $s5, $s5, 1	# zwiekszenie licznika
	ble  $t0, $t3, redmin
	la $t3, ($t0)
	
redmin:	
	bge   $t0, $t6, padHis
	la $t6, ($t0)
	
padHis:
	addi $s1, $s1, 1
	beq $s1, $a3, histogram2	#przerobienie wszystkich pikesli
	beq $s5, $s2, paddingHis		# jesli licznik pikseli w wierszu = width
	j bluemax

check:
	beq $s4, $a2, reloadHis
	jr $ra
	
paddingHis:
	beq $s6, $zero, bluemax
	addi $s7, $s7, 1
	beq $s4, $a2, reloadHis
	li $s5, 0	#reset licznika
	addi $s3, $s3, 1
	addi $s4, $s4, 1
	beq $s7, $s6, bluemax
	j paddingHis
	
reloadHis:	# zaladowanie bufora dalsza czesc obrazka
	subi $s0, $s0, buffer_len
	ble $s0, $zero, histogram2	# rozpatrono wszystkie zmienne
	
	move $a0, $t9			#zaladowanie bufora
	la $a1, buffer
	li $a2, buffer_len
	li $v0, 14
	syscall
	
	la $s3, buffer
	li $s4, 0
	beq $s7, $zero, check	#jesli nie w trakcie paddingu to do petli
	subi $s7, $s7, 1
	j paddingHis		#jesli tak padding
	
histogram2:
	# zamkniecie pliku:
	li $v0, 16
	syscall
	
	# ponowne otworzenie pliku:
	la $a0, fileNameIn
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall	
	
	move $t9, $v0 		# deskryptor pliku do $t9
	
	bltz $t9, fileExc
	
	move $a0, $t9
	li $v0, 14
	la $a1, buffer
	li $a2, buffer_len		# wczytanie tylu bajtow, ile ma buffor
	syscall
	
	
	sub $t1, $t1, $t4	#vmax-vmin
	sub $t2, $t2, $t5
	sub $t3, $t3, $t6
	li $s1, 255
	sll $s1, $s1, 8		# przesuniecie w lewo(operacje sta³oprzecinkowe)
	div $t1, $s1, $t1	#tablica LUT(imax/(vmax-vmin))
	div $t2, $s1, $t2
	div $t3, $s1, $t3
	
	lw $s0, size
	lw $s1, offset			# zapisanie offset do $s1
	la $s3, buffer
	li $s4, 0
	la $s4, ($s1) # licznik bajtow w buforze
	li $s5, 0 # licznik bajtow w wierszu
	add $s3, $s3, $s1
	li $s1, 0
	
	j blue
	
contrast:
	li $s1, 0
	mul $a3, $a3, 3 
	li $t3, 255	# imax
	sll $t3, $t3, 8		# przesuniecie w lewo(operacje sta³oprzecinkowe)
	srl $t6, $t3, 1		# imax/2
	mul $t4, $t6, var	# stala do kontrastu(a*imax/2)
	
loop:	# dla kontrastu
	li $s7, 0 # licznik paddingu
	beq $s4, $a2, reload
	lbu $t0, ($s3)		# wczytanie bajtu piksela
	sll $t0, $t0, 8
	mul $t0, $t0, var	# a*i
	sub $t0, $t0, $t4	# a*(i-imax/2)
	div $t0, $t0, 100	# a/100
	add $t0, $t0, $t6	# a*(i-imax/2)+imax/2
	sle $t2, $t0, -1	# czy nie <0
	srl $t0, $t0, 8
	sge $t1, $t0, 256	# czy nie >255
	beq $t2, 1, inc
	beq $t1, 1, dec
	
set:
	sb $t0, ($s3)		# nadpisanie nowa skladowa
	addi $s1, $s1, 1	# przejscie o kolejny bajt
	addi $s3, $s3, 1	# przejscie o kolejny bajt
	addi $s4, $s4, 1	# zwiekszenie licznika
	addi $s5, $s5, 1	# zwiekszenie licznika
	beq $s1, $a3, reload
	
	# sprawdzamy padding:
	beq $s5, $s2, padding		# jesli licznik pikseli w wierszu = width
	j loop
	
blue:	# dla histogramu
	li $s7, 0 # licznik paddingu
	jal check2
	lbu $t0, ($s3)
	sub $t0, $t0, $t4	# i-vmin
	mul $t0, $t0, $t1	# (imax/(vmax-vmin))*(i-vmin)
	srl $t0, $t0, 8
	sb $t0, ($s3)
	addi $s3, $s3, 1	# przejscie o kolejny bajt
	addi $s4, $s4, 1	# zwiekszenie licznika
	addi $s5, $s5, 1	# zwiekszenie licznika
	
green:
	jal check2
	lbu $t0, ($s3)
	sub $t0, $t0, $t5
	mul $t0, $t0, $t2
	srl $t0, $t0, 8
	sb $t0, ($s3)
	addi $s3, $s3, 1	# przejscie o kolejny bajt
	addi $s4, $s4, 1	# zwiekszenie licznika
	addi $s5, $s5, 1	# zwiekszenie licznika
	
red:
	jal check2
	lbu $t0, ($s3)
	sub $t0, $t0, $t6
	mul $t0, $t0, $t3
	srl $t0, $t0, 8
	sb $t0, ($s3)
	addi $s3, $s3, 1	# przejscie o kolejny bajt
	addi $s4, $s4, 1	# zwiekszenie licznika
	addi $s5, $s5, 1	# zwiekszenie licznika

pad2:
	addi $s1, $s1, 1
	beq $s1, $a3, reload
	beq $s5, $s2, padding		# jesli licznik pikseli w wierszu = width
	j blue

check2:
	beq $s4, $a2, reload
	jr $ra

reload:	# zaladowanie bufora dalsza czesc obrazka
	subi $s0, $s0, buffer_len
	ble $s0, $zero, saveFile	# zapisanie do wyniku obecnego bufora
	move $a0, $t8
	la $a1, buffer
	li $a2, buffer_len
	li $v0, 15
	syscall
	
	move $a0, $t9			#zaladowanie bufora
	la $a1, buffer
	li $a2, buffer_len
	li $v0, 14
	syscall
	
	la $s3, buffer
	li $s4, 0	#licznik wbuforze na 0
	beq $s7, $zero, jump1	#jesli nie w trakcie paddingu to do petli
	subi $s7, $s7, 1
	j padding		#jesli tak padding
	
padding:
	beq $s6, $zero, jump2
	addi $s7, $s7, 1
	beq $s4, $a2, reload
	li $s5, 0	#reset licznika
	addi $s3, $s3, 1
	addi $s4, $s4, 1
	beq $s7, $s6, jump2
	j padding

jump1:
	beqz $t7, loop
	j check
	
jump2:
	beqz $t7, loop
	j blue

saveFile:
	# zapisujemy wynikw pliku 
	addi $s0, $s0, buffer_len
	move $a0, $t8
	la $a1, buffer
	la $a2, ($s0)
	li $v0, 15
	syscall
	
	move $a0, $t8	# zamykamy oba pliki
	li $v0, 16
	syscall
	
	move $a0, $t9
	li $v0, 16
	syscall
	
	j exit
dec:
	li $t0, 255
	j set
	
inc:
	li $t0, 0
	j set
	
fileExc:
	# blad odczytu pliku:
	la $a0, msgFileExc	
	li $v0, 4
	syscall
	
exit:	
	# zamkniecie programu:
	li $v0, 10
	syscall
