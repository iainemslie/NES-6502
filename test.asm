	.inesprg 1	;Indicates 1x16 KB of program memory
	.ineschr 1	;Indicates 1x8 KB of graphic memory
	.inesmap 0 	;No bank switching
	.inesmir 1	;Background mirroring
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;			      Declarations	    				 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	.rsset $0000  ;;start variables at ram location 0	
;; DECLARE SOME VARIABLES HERE
gamestate  .rs 1	
buttons1   .rs 1  ; player 1 gamepad buttons, one bit per button
buttons2   .rs 1  ; player 2 gamepad buttons, one bit per button
playerspeed .rs 1 ;Movement speed for player1

ULSprite   .rs 1  ; Upper Left Player Sprite
LRSprite   .rs 1  ; Lower Right Player Sprite


;; DECLARE SOME CONSTANTS HERE
STATETITLE     = $00  ; displaying title screen
STATEPLAYING   = $01  ; move paddles/ball, check for collisions
STATEGAMEOVER  = $02  ; displaying game over screen

RIGHTWALL      = $F4  ; when ball reaches one of these, do something
TOPWALL        = $10
BOTTOMWALL     = $E0
LEFTWALL       = $04
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				  RESET/STARTUP						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.bank 0
	.org $C000
RESET:
	SEI			;Disable IRQ interrupts
	CLD			;Disable decimal mode
	LDX #$40
	STX $4017	;Disable APU frame IRQ
	LDX #$FF
	TXS			;Transfer value of X to Stack Pointer
	INX			;X=0 now
	STX $2000	;Disable NMI
	STX $2001	;Disable rendering
	STX $4010	;Disable DMC IRQs
	
	JSR VBlankWait ;Need to add this subroutine back in
	
;Reset RAM to zero	
clrmem:
	LDA #$00
	STA $0000, x
	STA $0100, x
	STA $0300, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x
	LDA #$FE
	STA $0200, x
	INX
	BNE clrmem
	
	JSR VBlankWait
	
;;;;;Transfer Graphics Data from ROM to PPU memory;;;;

;Transfer Palette data from ROM to PPU memory	
LoadPalettes:
	LDA $2002             ; read PPU status to reset the high/low latch
	LDA #$3F
	STA $2006             ; write the high byte of $3F00 address
	LDA #$00
	STA $2006             ; write the low byte of $3F00 address
	LDX #$00              ; start out at 0
LoadPalettesLoop:
	LDA palette, x        ; load data from address (palette + the value in x)
						  ; 1st time through loop it will load palette+0
						  ; 2nd time through loop it will load palette+1
						  ; 3rd time through loop it will load palette+2
						  ; etc
	STA $2007             ; write to PPU
	INX                   ; X = X + 1
	CPX #$20              ; Compare X to hex $10, decimal 16 - copying 16 bytes = 4 sprites
	BNE LoadPalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
						; if compare was equal to 32, keep going down


;Transfer Sprite data from Rom to PPU
LoadSprites:
	LDX #$00              ; start at 0
LoadSpritesLoop:
	LDA sprites, x        ; load data from address (sprites +  x)
	STA $0200, x          ; store into RAM address ($0200 + x)
	INX                   ; X = X + 1
	CPX #$10              ; Compare X to hex $10, decimal 16
	BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
						; if compare was equal to 16, keep going down
              
              
;Transfer Background data from Rom to PPU              
LoadBackground:
	LDA $2002             ; read PPU status to reset the high/low latch
	LDA #$20
	STA $2006             ; write the high byte of $2000 address
	LDA #$00
	STA $2006             ; write the low byte of $2000 address
	LDX #$00              ; start out at 0
LoadBackgroundLoop0:
	LDA background0, x     ; load data from address (background + the value in x)
	STA $2007             ; write to PPU
	INX                   ; X = X + 1
	CPX #$E0              ; 
	BNE LoadBackgroundLoop0  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down
	
	LDX #$00
LoadBackgroundLoop1:
	LDA background1, x     ; load data from address (background + the value in x)
	STA $2007             ; write to PPU
	INX                   ; X = X + 1
	CPX #$E0              ; 
	BNE LoadBackgroundLoop1  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down
						
	LDX #$00
LoadBackgroundLoop2:
	LDA background2, x     ; load data from address (background + the value in x)
	STA $2007             ; write to PPU
	INX                   ; X = X + 1
	CPX #$E0              ; 
	BNE LoadBackgroundLoop2  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down
						
	LDX #$00
LoadBackgroundLoop3:
	LDA background3, x     ; load data from address (background + the value in x)
	STA $2007             ; write to PPU
	INX                   ; X = X + 1
	CPX #$E0              ; 
	BNE LoadBackgroundLoop3  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down
	
	LDX #$00
LoadBackgroundLoop4:
	LDA background4, x     ; load data from address (background + the value in x)
	STA $2007             ; write to PPU
	INX                   ; X = X + 1
	CPX #$20              ; 
	BNE LoadBackgroundLoop4
              
;Transfer Attribute data from Rom to PPU              
LoadAttribute:
	LDA $2002             ; read PPU status to reset the high/low latch
	LDA #$23
	STA $2006             ; write the high byte of $23C0 address
	LDA #$C0
	STA $2006             ; write the low byte of $23C0 address
	LDX #$00              ; start out at 0
LoadAttributeLoop:
	LDA attribute, x      ; load data from address (attribute + the value in x)
	STA $2007             ; write to PPU
	INX                   ; X = X + 1
	CPX #$08              ; Compare X to hex $08, decimal 8 - copying 8 bytes
	BNE LoadAttributeLoop  ; Branch to LoadAttributeLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down
						
						
;Include any initial or starting state behaviour here						

	;;:Set starting game state
	LDA #STATEPLAYING
	STA gamestate

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;              
              
		  
	LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
	STA $2000

	LDA #%00011110   ; enable sprites, enable background, no clipping on left side
	STA $2001

Forever:
	JMP Forever     ;jump back to Forever, infinite loop
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				  NMI Interrupt						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


NMI:
	LDA #$00		;Transfer the sprite data from RAM to PPU
	STA $2003       ; set the low byte (00) of the RAM address
	LDA #$02
	STA $4014       ; set the high byte (02) of the RAM address, start the transfer
	
	;;This is the PPU clean up section, so rendering the next frame starts properly.
	LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
	STA $2000
	LDA #%00011110   ; enable sprites, enable background, no clipping on left side
	STA $2001
	LDA #$00        ;;tell the ppu there is no background scrolling
	STA $2005
	STA $2005
    
	;;;all graphics updates done by here, run game engine
	
	JSR ReadController1  ;;get the current button data for player 1
	;JSR ReadController2  ;;get the current button data for player 2
	
	JSR CheckButtons
	
GameEngine:  
	LDA gamestate
	CMP #STATETITLE
	BEQ EngineTitle    ;;game is displaying title screen

	LDA gamestate
	CMP #STATEGAMEOVER
	BEQ EngineGameOver  ;;game is displaying ending screen

	LDA gamestate
	CMP #STATEPLAYING
	BEQ EnginePlaying   ;;game is playing
GameEngineDone: 

	JSR UpdateSprites  ;;set ball/paddle sprites from positions

	RTI             ; return from interrupt

;;;;;;;;
 
EngineTitle:
  ;;if start button pressed
  ;;  turn screen off
  ;;  load game screen
  ;;  set starting paddle/ball position
  ;;  go to Playing State
  ;;  turn screen on
  JMP GameEngineDone

;;;;;;;;; 
 
EngineGameOver:
  ;;if start button pressed
  ;;  turn screen off
  ;;  load title screen
  ;;  go to Title State
  ;;  turn screen on 
  JMP GameEngineDone
 
;;;;;;;;;;;

EnginePlaying:

	JSR UpdateMissile

	JMP GameEngineDone
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				  Subroutines						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateMissile:
	;Update the position of the missile sprite
	LDA $0213
	CMP #$F4
	BEQ skipupdate
	CMP #$F5
	BEQ skipupdate
	CMP #$F6
	BEQ skipupdate
	CMP #$F7
	BEQ skipupdate
	CMP #$F8
	BEQ skipupdate
	ADC #$04
	STA $0213
returnskipupdate:

	RTS
	
skipupdate:
	LDA #$03
	STA $0211
	JMP returnskipupdate

;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

;!Fix this so that we look at the bit relevant to each button and call function based on that instead of comparing numbers!
	
CheckButtons: ;8 4 2 1
	;If right button is pressed
	;Update X position of all sprites in object
	LDA #$01
	CMP buttons1
	BEQ RightButtonPressed
ReturnR:
	LDA #$02
	CMP buttons1
	BEQ LeftButtonPressed
ReturnL: 
	LDA #$04
	CMP buttons1
	BEQ DownButtonPressed
ReturnD
	LDA #$08
	CMP buttons1
	BEQ UpButtonPressed
ReturnU:
	LDA #$20
	CMP buttons1
	BEQ SelectButtonPressed
ReturnSe:
	LDA #$10
	CMP buttons1
	BEQ StartButtonPressed
ReturnSt:
	LDA #$40
	CMP buttons1
	BEQ BButtonPressed
ReturnB:
	LDA #$80
	CMP buttons1
	BEQ AButtonPressed
ReturnA:
	LDA #$44
	CMP buttons1
	BEQ DownAndBButtonPressed
ReturnDownAndB:
	LDA #$48
	CMP buttons1
	BEQ UpAndBButtonPressed
ReturnUpAndB:


  RTS 
	
;Double jump from the branches above to the Button subroutines
RightButtonPressed:
	JSR RightButton
	JMP ReturnR
	  
LeftButtonPressed: ;Need to flip sprites and swap them
	JSR LeftButton
	JMP ReturnL
	
DownButtonPressed:
	JSR DownButton
	JMP ReturnD
	
UpButtonPressed:
	JSR UpButton 
	JMP ReturnU
	
SelectButtonPressed:
	JSR SelectButton
	JMP ReturnSe
  
StartButtonPressed:
	JSR StartButton
	JMP ReturnSt
	
BButtonPressed:
	JSR BButton
	JMP ReturnB
	
AButtonPressed:
	JSR AButton
	JMP ReturnA
	
DownAndBButtonPressed:
	JSR DBButton
	JMP ReturnDownAndB
	
UpAndBButtonPressed:
	JSR UBButton
	JMP ReturnUpAndB
  
  
;functions  
  
RightButton:  
	JSR UpdateRight	
	RTS
  
  
LeftButton: 
	;Compare the upper left sprite to the left wall and skip updating if it is equal
	LDA $0203
	CMP #$00
	BEQ skipleft
	JSR UpdateLeft	
skipleft:
    RTS
  
DownButton:
	LDA $0208
	CMP #$DE
	BEQ skipdown
	JSR UpdateDown
skipdown:
    RTS
	
UpButton:
	LDA $0200
	CMP #$0E
	BEQ skipup
	JSR UpdateUp
skipup:
    RTS
	
SelectButton:
	RTS
	
StartButton:
	RTS
	
BButton:
	JSR FireMissile
	RTS
	
  RTS
	
AButton:
	RTS
	
DBButton:
	JSR UpdateDown
	JSR FireMissile
  RTS
  
UBButton:
	JSR UpdateUp
	JSR FireMissile
  RTS
  
FireMissile:
	;fire missile ;Sprite $0210-0213
	LDA $0204	;Get the Y position of player sprite top right
	STA $0210
	LDA $0207	;Get the X position of player sprite top right
	SBC #$06
	STA $0213
	LDA #$02	;Set tile to be 02
	STA $0211
	LDA #$01	;Set colour palette
	STA $0212
  RTS
	
UpdateUp:
	;Sprite 1;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $0200       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	SBC #$01        ; A = A + 1
	STA $0200       ; save sprite X position
	;Sprite 2;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $0204       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	SBC #$01        ; A = A + 1
	STA $0204       ; save sprite X position
	;Sprite 3;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $0208       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	SBC #$01        ; A = A + 1
	STA $0208       ; save sprite X position
	;Sprite 4;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $020C       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	SBC #$01        ; A = A + 1
	STA $020C       ; save sprite X position
  RTS

UpdateDown:
	;Sprite 1;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $0200       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	ADC #$02        ; A = A + 1
	STA $0200       ; save sprite X position
	;Sprite 2;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $0204       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	ADC #$02        ; A = A + 1
	STA $0204       ; save sprite X position
	;Sprite 3;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $0208       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	ADC #$02        ; A = A + 1
	STA $0208       ; save sprite X position
	;Sprite 4;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $020C       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	ADC #$02        ; A = A + 1
	STA $020C       ; save sprite X position
  RTS
  
UpdateLeft:
	;Sprite 1;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $0203       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	SBC #$01        ; A = A + 1
	STA $0203       ; save sprite X position
	;Sprite 2;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $0207       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	SBC #$01        ; A = A + 1
	STA $0207       ; save sprite X position
	;Sprite 3;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $020B       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	SBC #$01        ; A = A + 1
	STA $020B       ; save sprite X position
	;Sprite 4;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $020F       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	SBC #$01        ; A = A + 1
	STA $020F       ; save sprite X position
  RTS
  
UpdateRight:
	;Sprite 1;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $0203       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	ADC #$02        ; A = A + 1
	STA $0203       ; save sprite X position
	;Sprite 2;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $0207       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	ADC #$02        ; A = A + 1
	STA $0207       ; save sprite X position 
	;Sprite 3;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $020B       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	ADC #$02        ; A = A + 1
	STA $020B       ; save sprite X position
	;Sprite 4;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $020F       ; load sprite X position
	CLC             ; make sure the carry flag is clear
	ADC #$02        ; A = A + 1
	STA $020F       ; save sprite X position
  RTS
 
ReadController1: ;Set the controller input register into high latch mode enabling reading of controller input
	LDA #$01
	STA $4016
	LDA #$00
	STA $4016
	LDX #$08
ReadController1Loop:
	LDA $4016		   ;Read value from $4016, 1 if pressed 0 if not
	LSR A            ; bit0 -> Carry
	ROL buttons1     ; bit0 <- Carry
	DEX
	BNE ReadController1Loop
	RTS
  
ReadController2:
	LDA #$01
	STA $4016
	LDA #$00
	STA $4016
	LDX #$08
ReadController2Loop:
	LDA $4017
	LSR A            ; bit0 -> Carry
	ROL buttons2     ; bit0 <- Carry
	DEX
	BNE ReadController2Loop
	RTS 
	
VBlankWait:
	BIT $2002
	BPL VBlankWait
	RTS
  
UpdateSprites:
	;LDA bally  ;;update all ball sprite info
	;STA $0200

	;LDA #$64
	;STA $0201

	;LDA #$00
	;STA $0202

	;LDA ballx
	;STA $0203

	;;update paddle sprites
	RTS	
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				  		Data						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
  
  
  .bank 1
  .org $E000
palette:
  .db $3F,$1C,$2B,$39,  $3F,$36,$17,$0F,  $3F,$30,$21,$0F,  $3F,$27,$17,$0F   ;;background palette
  .db $3F,$15,$1C,$3B,  $3F,$02,$38,$3C,  $3F,$1C,$15,$14,  $3F,$02,$38,$3C   ;;sprite palette

sprites: ;Initial sprite settings sprites 0-3 are the player ship
     ;vert tile attr horiz
  .db $60, $00, $00, $00   ;sprite 0
  .db $60, $01, $00, $08   ;sprite 1
  .db $68, $10, $00, $00   ;sprite 2
  .db $68, $11, $00, $08   ;sprite 3


background0:
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 1 ;;NOT VISIBLE
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 2 ;Write score info on this line if wanted
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$84,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$84,$24,$24,$24  ;;row 2
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 2
  .db $24,$24,$24,$24,$84,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky
  
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 5
  .db $24,$24,$24,$84,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 6
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$84,$24  ;;all sky
  
  .db $24,$84,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 7
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky
  
background1:
  .db $24,$24,$24,$24,$24,$86,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 8
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$80,$81,$82,$83,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 9
  .db $24,$24,$24,$84,$24,$24,$24,$24,$24,$24,$90,$91,$92,$93,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 2
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$A0,$A1,$A2,$A3,$24,$24  ;;all sky

  .db $24,$85,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 2
  .db $24,$24,$24,$24,$24,$85,$24,$24,$24,$24,$B0,$B1,$B2,$B3,$24,$24  ;;all sky
  
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 12
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 13
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky
  
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 14
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky
  
background2:
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 15
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 16
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 17
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$84,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 18
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky
  
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$85,$24,$24  ;;row 19
  .db $24,$24,$24,$24,$85,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 20
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky
  
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 21
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky
  
background3:
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 22
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 23
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$84,$24  ;;all sky

  .db $24,$24,$86,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 2
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$85,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$24,$24,$85,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 2
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky
  
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$85,$24,$24,$24  ;;row 2
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 27
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky
  
background4:
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 28
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky	

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 29
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

attribute:
  .db %00000000, %00000000, %01010000, %00010000, %00000000, %00000000, %00000000, %00110000

  ;.db $24,$24,$24,$24, $47,$47,$24,$24 ,$47,$47,$47,$47, $47,$47,$24,$24 ,$24,$24,$24,$24 ,$24,$24,$24,$24, $24,$24,$24,$24, $55,$56,$24,$24  ;;brick bottoms



  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  .bank 2
  .org $0000
  .incbin "mario.chr"   ;includes 8KB graphics file from SMB1	
	
	