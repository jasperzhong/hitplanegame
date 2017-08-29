;	puts(str) 
PUTS MACRO STRING
	PUSH AX
	PUSH DX
	LEA DX, STRING
	MOV AH, 09h
	INT 21h
	POP DX
	POP AX
ENDM

_STACK SEGMENT
	DB  7FFEh DUP(0)
TOS DW 0
_STACK ENDS

_DATA SEGMENT
DIFFICULTY  DW  ?  ;  10-EASY 5-MIDDLE 2-HARD 0-VERY HARD
POS_X DW 0A0h    ;horizontal position
POS_Y DW 0A0h	;vectical position
MISSILE    DW 512 DUP('$$')
MISSILESNUM DW 0 ;Missiles' number
ENEMY      DW 512 DUP('$$')
ENEMYNUM   DW 0
PLANEMAP DW  1,1,3,3,3,3,3,3,7,14,16,14,6,2,2,6,6 
N1		 EQU  ($-PLANEMAP)/2
MISSILEMAP DW 1,1,3,3,3
N2		 EQU  ($-MISSILEMAP)/2
ENEMYMAP  DW 3,3,1,1
N3       EQU  ($-ENEMYMAP)/2
TIMER    DW  0
MAX     DW 30
SCORE   DW 0
HIGHEST DW 0

MAINMENU DB  '-------------Welcome-------------',0Dh,0Ah
		 DB  'How to play',0Dh,0Ah
		 DB  'Move: left up right down',0Dh,0Ah
		 DB  'Shoot: space key',0Dh,0Ah
		 DB  'Score: Hit(+2), Escape(-5), Collide(Game over)',0Dh,0Ah
		 DB  'Now you can press Enter to start!',0Dh,0Ah
		 DB  'Or press ESC to quit(also in the game)',0Dh,0Ah
		 DB  '-----1652817 Zhong yuchen--------',0Dh,0Ah,'$'
		 
CHOOSEMENU	DB  '         1.Easy',0Dh,0Ah
		 DB  '         2.Middle',0Dh,0Ah
		 DB  '         3.Hard',0Dh,0Ah
		 DB  '         4.Very hard',0Dh,0Ah
		 DB  '         please choose:',0Dh,0Ah,'$'
		 
		 
GAMEOVER DB  'Your highest score:',0Dh,0Ah
		 DB  0Dh,0Ah
		 DB  '--------------GAME OVER---------------',0Dh,0Ah
		 DB  0Dh,0Ah
		 DB  '$'
_DATA ENDS


_TEXT SEGMENT 
ASSUME CS:_TEXT, DS:_DATA, SS:_STACK

Start:
	   MOV AX, _DATA
	   MOV DS, AX
	   CLI
	   MOV AX, _STACK
	   MOV SS, AX
	   MOV SP, Offset TOS
	   STI
	   
	   CALL init
	   
	   MOV AH, 00h
	   MOV AL, 04h
	   INT 10h
	   MOV CX, N1
	   PUSH CX
	   MOV SI, Offset PLANEMAP
	   PUSH SI
	   MOV CX, 0001h
	   PUSH CX
	   PUSH POS_Y
	   PUSH POS_X
	   CALL drawCraft
	   ADD SP, 10
Again:	   
	   MOV AH,01h
	   INT 16h
Next:  
	   JZ  Process
	   MOV AH, 00h
 	   INT 16h
	   CMP AL, 27
	   JZ EndMain
	   CMP AL, ' '
	   JZ Shoot
	   PUSH AX
	   PUSH POS_Y
	   PUSH POS_X
	   CALL movePlane
	   ADD SP, 6
	   JMP Again
Shoot: 
	   PUSH POS_Y
	   PUSH POS_X
	   CALL fireMissile
	   ADD SP, 4
	   JMP Again
Process:
	   PUSH SCORE
	   CALL showScoreByDemical
	   ADD SP, 2
	   CALL checkCollision
	   INC TIMER
	   MOV DX, DIFFICULTY
	   CMP TIMER, DX
	   JBE  Loc1 
	   CALL dropEnemy  
	   MOV DX, MAX
	   SUB DX, TIMER
	   MOV TIMER, 0
	   CMP ENEMYNUM, DX
	   JA  Loc1
	   CALL generateEnemy
Loc1:
	   CMP MISSILESNUM, 0
	   JZ Again
	   CALL riseMissile
	   JMP Again

	   
EndMain:
	   MOV AX, 4C00h
	   INT 21h
	   
	   
Comment/***********
	  function:   init
	  parameters: void
	  return:     void	  
	  description:Show the menu before game starts.
**********/
init     PROC NEAR
		MOV AX, 0003h
		INT 10h
		PUTS MAINMENU
Redo2:		
		MOV AH,01h
		INT 21h
		CMP AL, 27
		JZ  ESCT
		CMP AL, 0Dh	
		JNZ Redo2
		
		MOV AX, 0003h
		INT 10h
		PUTS CHOOSEMENU
Redo:		
		MOV AH,01h
		INT 21h
		SUB AL, '0'
		CMP AL, 1
		JZ IF_1
		CMP AL, 2
		JZ IF_2
		CMP AL, 3
		JZ IF_3
		CMP AL, 4
		JZ IF_4
		JMP Redo
IF_1:	MOV DIFFICULTY, 5
		JMP IFEND
IF_2:	MOV DIFFICULTY, 3
		JMP IFEND
IF_3:	MOV DIFFICULTY, 1
		JMP IFEND
IF_4:	MOV DIFFICULTY, 0
		JMP IFEND
ESCT:   MOV AX, 4C00h
	    INT 21h
IFEND:  

		RET
init     ENDP

Comment/***********
	  function:   draw a horizontal line
	  parameters: horizontal position
	              vertical position
	  			  length of the line
	  			  color
	  return:     void
	  description:draw some points horizontally.
	  			  color '0001h' represents drawing a line while
	  			  color '0000h' which is black means erase the line.
**********/
drawALine PROC NEAR 
       PUSH BP
       MOV BP, SP
       PUSH AX
       PUSH CX
       PUSH DX
       PUSH SI
       	
       MOV AH, 0Ch
       MOV CX, [BP+4]
       MOV DX, [BP+6]
       MOV SI, [BP+8]
       MOV AL, Byte Ptr [BP+10]
drawALineLoop:
	   INT 10h
	   INC CX
	   DEC SI
	   JNZ drawALineLoop
       
       POP SI
       POP DX
       POP CX
       POP AX
       MOV SP, BP
       POP BP
       RET
drawALine ENDP   


Comment/***********
	  function:   draw a plane or a missile 
	  parameters: horizontal position
	              vertical position
	              color
	              type (plane or missile or enemy)
	              map length  
	  return:     void
	  description:call "drawALine" function repeatedly.
**********/
drawCraft PROC NEAR
	    
	    PUSH BP
	    MOV BP, SP
	    SUB SP, 8
	    
	    PUSH AX
	    PUSH DX
	    PUSH SI
	    PUSH DI
	    MOV DI, 0
	    
	    MOV AX, [BP+12]
	    MOV [BP-8],AX
	    MOV SI, [BP+10]
	    MOV AX, [BP+8]
	    MOV [BP-6], AX
	    MOV AX, [BP+6]
	    MOV [BP-4], AX
	    MOV AX, [BP+4]
	    MOV [BP-2], AX
drawCraftLoop:
		PUSH Word Ptr [BP-6]
	    MOV DX, Word Ptr [SI]
	    PUSH DX	    
	    PUSH Word Ptr [BP-4]
	    MOV AX, [BP-2]
	    SHR DX, 1
	    SUB AX, DX
	    PUSH AX
	    CALL drawALine
	    ADD SP, 8
	    ADD Word Ptr [BP-4], 1
	    ADD SI, 2
	    INC DI
	    CMP DI, [BP-8]
	    JB  drawCraftLoop
	    
	    POP DI
	    POP SI
	    POP DX
	    POP AX    
	    MOV SP, BP
	    POP BP
		RET
drawCraft ENDP

Comment/***********
	  function:   move a plane 
	  parameters: original horizontal position
	              original vertical position
	  			  direction(left-a up-w right-d bottom-s)
	  return:     rectify POS_X, POS_Y
	  description:destory the original and then create a new one	  			  
**********/
movePlane  PROC NEAR
		 PUSH BP
		 MOV BP, SP
		 
		 PUSH AX
		 PUSH BX
		 PUSH CX
		 
		 MOV AX,N1
		 PUSH AX
		 MOV AX, Offset PLANEMAP
		 PUSH AX
		 MOV AX, 0000h
		 PUSH AX  ;black color
		 MOV AX, [BP+6]
		 PUSH AX
		 MOV AX, [BP+4]
		 PUSH AX
		 CALL drawCraft
		 ADD SP, 10
		 
		 MOV CX, CS:MoveItems
		 MOV AH, Byte Ptr [BP+9]
		 MOV BX, Offset MoveCase
movePlaneLoop1:		 
		 CMP AH, Byte Ptr CS:[BX]
		 JE  ToCase
		 ADD BX, 4
		 LOOP movePlaneLoop1
		 
ToCase:	 JMP Word Ptr CS: [BX+2]
MoveItems DW 4
MoveCase DW 75,Case1,72,Case2,77,Case3,80,Case4, 0, Default
Default: JMP EndSwitch
Case1:   SUB POS_X, 5
		 JMP EndSwitch
Case2:	 SUB POS_Y, 5
		 JMP EndSwitch
Case3:	 ADD POS_X, 5
		 JMP EndSwitch
Case4:   ADD POS_Y, 5
	
EndSwitch:
;draw a new plan in new position
		 MOV CX, N1
		 PUSH CX
		 MOV CX, Offset PLANEMAP
		 PUSH CX
		 MOV CX, 0001h
		 PUSH CX
	     PUSH POS_Y
	     PUSH POS_X
	     CALL drawCraft
		 ADD SP, 10
EndMovePlane:

		 POP CX
		 POP BX
		 POP AX
		 MOV SP, BP 
		 POP BP
		 RET
movePlane ENDP

Comment/***********
	  function:   delay
	  parameters: void
	  return:     void	  
**********/
delay PROC NEAR
          PUSH CX
          MOV CX, 0
delayLoop:INC CX
          CMP CX, 6000
          JB delayLoop
          POP CX
          RET
delay ENDP

Comment/***********
	  function:   
	  parameters: horizontal position
	              vertical position
	  return:     rectify 'MISSILE' and 'MISSILESNUM'
	  description:When press the space key, this program will put 
	              the  position into the 'MISSILE' array.
	              Then call 'drawMissile' to display it. 	  
**********/
fireMissile  PROC NEAR	
		  PUSH BP
	      MOV BP, SP
	      
	      PUSH CX
	      PUSH DX
	      PUSH SI
	      PUSH DI
	      
	      MOV CX, [BP+4]
	      MOV DX, [BP+6]
	      SUB DX, 5
		  MOV SI, Offset MISSILE
fireMissileLoop:
		  CMP Word Ptr [SI], '$$'
		  JZ  fireMissileIf
		  ADD SI, 4
		  JMP fireMissileLoop
fireMissileIf:
          MOV [SI], CX
          MOV [SI+2], DX
          
          MOV DI, N2
          PUSH DI
          MOV DI, Offset MISSILEMAP
          PUSH DI
          MOV DI, 0003h
          PUSH DI
          PUSH DX
          PUSH CX
          CALL drawCraft
          ADD SP, 10
		  
		  INC MISSILESNUM
		  POP DI
	      POP SI
	      POP DX
	      POP CX
	      MOV SP, BP
	      POP BP
	      RET
fireMissile  ENDP


Comment/***********
	  function:   rise all the existing missiles 
	  parameters: void
	  return:     rectify MISSILE and MISSILESNUM
	  description:When there is no input event, this program will
	  			  rise all the existing missiles which stored in 
	  			  the 'MISSILE' array unless there is no missile.
**********/
riseMissile PROC NEAR
		  PUSH BP
		  MOV BP, SP
		  
		  PUSH SI
		  PUSH CX
		  PUSH DX
			    
		  MOV SI, Offset MISSILE
		  MOV CX, 256
riseMissileLoop:		  
		  CMP Word Ptr [SI], '$$'
		  JZ  riseMissileIf
		  
		  MOV DX, N2
		  PUSH DX
		  MOV DX, Offset MISSILEMAP
		  PUSH DX 
		  MOV DX, 0000h
		  PUSH DX
		  MOV DX, Word Ptr [SI+2]
		  PUSH DX
		  MOV DX, Word Ptr [SI]
		  PUSH DX
		  CALL drawCraft
		  ADD SP, 10
		  
		  SUB Word Ptr [SI+2],2
		  JLE riseMissileIf2
		  
		  MOV DX, N2
		  PUSH DX
		  MOV DX, Offset MISSILEMAP
		  PUSH DX 
		  MOV DX, 0003h
		  PUSH DX
		  MOV DX, Word Ptr [SI+2]
		  PUSH DX
		  MOV DX, Word Ptr [SI]
		  PUSH DX
		  CALL drawCraft
		  ADD SP, 10
		  
		  JMP riseMissileIf
riseMissileIf2:
		  MOV Word Ptr [SI], '$$'
		  MOV Word Ptr [SI+2], '$$'
		  DEC MISSILESNUM	  
riseMissileIf:	
		  ADD SI, 4 
		  LOOP riseMissileLoop
		  
		  POP DX
		  POP CX
		  POP SI
		  POP AX	
		    
		  MOV SP, BP
		  POP BP
		  RET
riseMissile ENDP

Comment/***********
	  function:   generate a random number
	  parameters: void
	  return:     bx   the random number
	  description:use system clock 			  
**********/
randByBX PROC NEAR
		  PUSH AX
		  PUSH CX
		  PUSH DX
		  MOV AH, 0
		  INT 1Ah
		  MOV AX, DX
		  TEST AX, 000000001b
		  JZ ODD
		  SHR AX, 1
		  JMP LOC2
ODD: 	  SHL AX, 1
LOC2:	  XOR AX, 01011111b
		  SUB AX, 3214
		  XOR AX, 10111100b
		  ADD AX, 30124
		  MOV CX, 250
		  MOV DX, 0
		  DIV CX
		  ADD DX, 50
		  MOV BX, DX
		  POP DX
		  POP CX
     	  POP AX
     	  RET 
randByBX ENDP

Comment/***********
	  function:   generate some enemies regularly 
	  parameters: void
	  return:     rectify 'ENEMY' and 'ENEMYNUM'
	  description:Call 'randByBX' to determine the horizontal position
	  			  of new enemy and then call 'drawCraft' to draw it.		  
**********/
generateEnemy PROC NEAR
		  PUSH BP
		  MOV BP, SP
		  PUSH BX
		  PUSH SI
		  
		  MOV BX, N3
		  PUSH BX
		  MOV BX, Offset ENEMYMAP
		  PUSH BX
		  MOV BX, 0002h
		  PUSH BX
		  MOV BX, 00h
		  PUSH BX	  
		  CALL randByBX
		  PUSH BX
		  CALL drawCraft
		  ADD SP,10
		  
		  MOV SI, Offset ENEMY
generateEnemyLoop:
		  CMP Word Ptr [SI], '$$'
		  JZ  generateEnemyIF
		  ADD SI, 2
		  JMP generateEnemyLoop
generateEnemyIF:
  		  MOV Word Ptr[SI], BX
  		  MOV Word Ptr[SI+2], 00h
  		  
  		  INC ENEMYNUM
		  POP SI
		  POP BX
		  MOV SP, BP
		  POP BP 
		  RET
generateEnemy ENDP

Comment/***********
	  function:   drop all existing enemies 
	  parameters: void
	  return:     rectify ENEMY and ENEMYNUM
	  description:decline the vertical position.
**********/
dropEnemy PROC NEAR 
		  PUSH BP
		  MOV BP, SP
		  
		  PUSH SI
		  PUSH CX
		  PUSH DX
			    
		  MOV SI, Offset ENEMY
		  MOV CX, 256
dropEnemyLoop:		  
		  CMP Word Ptr [SI], '$$'
		  JZ  dropEnemyIf
		  
		  MOV DX, N3
		  PUSH DX
		  MOV DX, Offset ENEMYMAP
		  PUSH DX 
		  MOV DX, 0000h
		  PUSH DX
		  MOV DX, Word Ptr [SI+2]
		  PUSH DX
		  MOV DX, Word Ptr [SI]
		  PUSH DX
		  CALL drawCraft
		  ADD SP, 10
		  
		  
		  INC Word Ptr [SI+2]
		  CMP Word Ptr [SI+2], 200
		  JAE dropEnemyIf2
		  
		  MOV DX, N3
		  PUSH DX
		  MOV DX, Offset ENEMYMAP
		  PUSH DX 
		  MOV DX, 0002h
		  PUSH DX
		  MOV DX, Word Ptr [SI+2]
		  PUSH DX
		  MOV DX, Word Ptr [SI]
		  PUSH DX
		  CALL drawCraft
		  ADD SP, 10
		  
		  JMP dropEnemyIf
dropEnemyIf2:
		  SUB SCORE, 5
		  MOV Word Ptr [SI], '$$'
		  MOV Word Ptr [SI+2], '$$'
		  DEC ENEMYNUM	  
dropEnemyIf:	
		  ADD SI, 4 
		  LOOP dropEnemyLoop
		  
		  POP DX
		  POP CX
		  POP SI
		  POP AX	
		    
		  MOV SP, BP
		  POP BP
		  RET
dropEnemy ENDP

Comment/***********
	  function:   check if there is any collision
	  parameters: void
	  return:     void
	  description:check vertical pos and horizontal pos, if both are 
	              equel, delete one of them.
**********/
checkCollision PROC NEAR	
		  PUSH BP
		  MOV BP, SP	

		  PUSH AX
		  PUSH BX
		  PUSH CX
		  PUSH DX
		  PUSH SI
		  PUSH DI
		  
		  MOV SI, Offset ENEMY
		  MOV DI, Offset MISSILE
		  MOV AX, 0
		  MOV BX, 0
checkCollisionLoop1:
		  CMP Word Ptr [SI], '$$'
		  JZ  checkCollisionIf
		  
		  MOV CX, POS_X
		  SUB CX, Word Ptr[SI]
		  JGE checkCollisionLoc1
		  NEG CX
checkCollisionLoc1:
		  CMP CX, 8
		  JA checkCollisionLoop2
		 	
		  MOV DX, POS_Y
		  SUB DX, Word Ptr[SI+2]
		  JGE checkCollisionLoc2
		  NEG DX
checkCollisionLoc2:
		  CMP DX, 1
		  JA checkCollisionLoop2
		  
		  ;game over
		  
		  JMP GAMEEND
	checkCollisionLoop2:	  
		  CMP Word Ptr [DI], '$$'
		  JZ  checkCollisionIf3
		  
		  MOV CX, Word Ptr[SI]
		  SUB CX, Word Ptr[DI]
		  JGE checkCollisionLoc3
		  NEG CX
	checkCollisionLoc3:
		  CMP CX, 5
		  JA checkCollisionIf3
		  
		  MOV DX, Word Ptr[SI+2]
		  SUB DX, Word Ptr[DI+2]
		  JGE checkCollisionLoc4
		  NEG DX
	checkCollisionLoc4:
		  CMP DX, 5
		  JA checkCollisionIf3
		  
		  JMP deleteEnemy
	checkCollisionIf3:	  
		  INC BX
		  ADD DI, 4
		  CMP BX, 256
		  JB  checkCollisionLoop2
	
checkCollisionIf:
		  ADD SI, 4
		  MOV BX, 0
		  INC AX
		  CMP AX, 256
		  MOV DI, Offset MISSILE
		  JB checkCollisionLoop1 
		  JMP checkCollisionEnd
		  
deleteEnemy:		  
		  MOV DX, N3
		  PUSH DX
		  MOV DX, Offset ENEMYMAP
		  PUSH DX 
		  MOV DX, 0000h
		  PUSH DX
		  MOV DX, Word Ptr [SI+2]
		  PUSH DX
		  MOV DX, Word Ptr [SI]
		  PUSH DX
		  CALL drawCraft
		  ADD SP, 10
		  MOV Word Ptr [SI], '$$'
		  MOV Word Ptr [SI+2], '$$'
		  DEC ENEMYNUM
		  ADD SCORE, 2
		  MOV DX, SCORE
		  CMP DX, HIGHEST
		  JL checkCollisionIf3
		  MOV HIGHEST, DX
		  JMP checkCollisionIf3

GAMEEND:
		  MOV AX, 0003h
		  INT 10h
		  CALL delay
		  PUTS GAMEOVER
		  PUSH HIGHEST
		  CALL showScoreByDemical
		  ADD SP, 2
		  MOV AX, 4C00h
		  INT 21h  
		  
checkCollisionEnd:
		    
		  POP DI
		  POP SI 
		  POP DX
		  POP CX
		  POP BX
		  POP AX
		  MOV SP, BP	
		  POP BP	
		  RET
checkCollision ENDP

Comment/***********
	  function:   show player's score
	  parameters: score
	  return:     void
**********/
showScoreByDemical PROC NEAR
		  PUSH BP
		  MOV BP,SP
		  SUB SP,2
		  PUSH AX
		  PUSH BX
		  PUSH CX
		  PUSH DX
		  
		  MOV Byte Ptr [BP-2],5
		  MOV AX, [BP+4]
		  MOV CX, 0
		  MOV BX, 10
		  OR AX, AX
		  JNS showRep1
		  NEG AX
		  PUSH AX
		  
		  MOV DH, 1
		  MOV DL, [BP-2]
		  ADD Byte Ptr [BP-2],1
		  MOV AH, 02h
		  INT 10h
		  MOV AH, 0Ah
		  MOV AL, '-'
		  MOV CX, 1
		  INT 10h
		  POP AX
		  MOV CX,0
showRep1: MOV DX, 0
		  DIV BX
		  ADD DX, '0'
		  PUSH DX
		  INC CX
		  OR AX, AX
		  JNZ showRep1  
showRep2: POP DX
		  MOV AL, DL
		  MOV DH, 1
		  MOV DL, [BP-2]
		  ADD Byte Ptr [BP-2],1
		  MOV AH, 02h
		  INT 10h 
		  MOV AH, 0Ah
		  PUSH CX
		  MOV CX, 1
		  INT 10h
		  POP CX
	      LOOP showRep2
	      
	      POP DX
	      POP CX
	      POP BX
	      POP AX
	      MOV SP,BP
	      POP BP
		  RET
showScoreByDemical ENDP
_TEXT ENDS
	  END Start