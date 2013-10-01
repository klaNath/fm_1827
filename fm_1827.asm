LIST	P=PIC16F1827,R=DEC
INCLUDE	"p16f1827.inc"


__CONFIG _CONFIG1 , _PWRTE_ON & _MCLRE_ON & _WDTE_OFF & _FOSC_INTOSC & _CP_OFF &_CLKOUTEN_OFF & _IESO_OFF & _FCMEN_OFF
__CONFIG _CONFIG2 , _WRT_OFF & _PLLEN_ON & _STVREN_OFF & _LVP_OFF

LOOPCNT		EQU	20H
JOBF		EQU	21H
INTFG		EQU	22H
P_QUAD_0	EQU	23H
P_PHASE_0	EQU	24H
ENV_TIK		EQU	25H
ENV_CNT		EQU	26H
ENV_OUT		EQU	27H
OUTWAV_0	EQU	28H
MODF_0		EQU	29H



MOD_SIG_0	EQU	2DH
KEY_PRV		EQU	2EH
P_QUAD_1	EQU	2FH
P_PHASE_1	EQU	30H
OUTWAV_1	EQU	31H
MODF_1		EQU	32H
MOD_SIG_1	EQU	33H
ROM_PHASE	EQU	34H
ROM_QUAD	EQU	35H
OUTWAV		EQU	36H


KEYPORT		EQU	4
FM_ON		EQU	0
FM_EST		EQU	1

JOBMASK		EQU	B'01010101'
PHASE_ROM_H	EQU	88H
ENV_ROM_H	EQU	89H

        ORG    	00H
RESETV  	GOTO	START

	ORG	04H
INTV		GOTO	IRQ

IRQ     	INCF	INTFG,1
        	MOVLW	B'10100000'
        	MOVWF	INTCON
        	RETFIE

START   	MOVLB   1
        	MOVLW	B'11010000'
        	MOVWF	OPTION_REG
		CLRF    TRISB
		MOVLW	B'00010000'
		MOVWF	TRISA
		MOVLW	B'11110000'
		MOVWF	OSCCON
		MOVLB	3
		CLRF	ANSELA
		CLRF	ANSELB
        	MOVLB   0
        	MOVLW   B'10100000'
		MOVWF	INTCON
		CLRF	PORTB
		CLRF	TMR0
		CLRF	INTFG
		CLRF	JOBF
		CLRF	LOOPCNT
		CALL	INIT_FM
        	GOTO    MAIN

MAIN		CLRW
		CALL	CHKSW
		CALL	SYN_JOB
		BTFSC	JOBF,FM_EST
		CALL	FM
		CALL	CASTWAV
		CALL	SYNCS
		CALL	OUT_R2R
		GOTO	MAIN

CHKSW		BTFSS	LOOPCNT,7
		RETURN
		CLRF	LOOPCNT
		BTFSS	PORTA,KEYPORT
		GOTO	CLRKEY
		BTFSC	KEY_PRV,0
		RETURN
		BSF	JOBF,FM_ON
		BSF	KEY_PRV,0
		RETURN
CLRKEY		BCF	KEY_PRV,0
		RETURN

SYN_JOB		MOVF	JOBF,0
		ANDLW	JOBMASK
		BTFSC	STATUS,Z
		RETURN
		LSLF	WREG,0
		IORWF	JOBF,1
		RETURN

FM		BTFSC	JOBF,FM_ON
		CALL	INIT_FM
		CALL	P0_STEP
		CALL	P1_STEP
		CALL	OPX_WAV
		CALL	STEPENV
		CALL	APLYENV
		CALL	APLYMD0
		;CALL	APLYMD1
		RETURN

INIT_FM		BCF	JOBF,FM_ON
		CLRF	P_QUAD_0
		CLRF	P_PHASE_0
		CLRF	ENV_TIK
		CLRF	ENV_CNT
		CLRF	ENV_OUT
		CLRF	OUTWAV_0
		CLRF	MODF_0
		CLRF	MOD_SIG_0
		CLRF	P_QUAD_1
		CLRF	P_PHASE_1
		CLRF	OUTWAV_1
		CLRF	MODF_1
		CLRF	MOD_SIG_1
		RETURN

P0_STEP		MOVLW	58
		ADDWF	P_PHASE_0,1
		BTFSC	STATUS,C
		INCF	P_QUAD_0,1
		BTFSC	MOD_SIG_0,0
		GOTO	SUB0
ADD0		MOVF	MODF_0,0
		ADDWF	P_PHASE_0,1
		BTFSC	STATUS,C
		INCF	P_QUAD_0,1
		RETURN
SUB0		MOVF	MODF_0,0
		SUBWF	P_PHASE_0,1
		BTFSS	STATUS,C
		DECF	P_QUAD_0,1
		RETURN

P1_STEP		MOVLW	29
		ADDWF	P_PHASE_1,1
		BTFSC	STATUS,C
		INCF	P_QUAD_1,1
		BTFSC	MOD_SIG_0,0
		GOTO	SUB1
ADD1		MOVF	MODF_0,0
		ADDWF	P_PHASE_1,1
		BTFSC	STATUS,C
		INCF	P_QUAD_1,1
		RETURN
SUB1		MOVF	MODF_0,0
		SUBWF	P_PHASE_1,1
		BTFSS	STATUS,C
		DECF	P_QUAD_1,1
		RETURN

OPX_WAV	MOVF	P_PHASE_0,0
		MOVWF	ROM_PHASE
		MOVF	P_QUAD_0,0
		MOVWF	ROM_QUAD
		CALL	ROM2SIN
		MOVF	OUTWAV,0
		MOVWF	OUTWAV_0
		MOVF	P_PHASE_1,0
		MOVWF	ROM_PHASE
		MOVF	P_QUAD_1,0
		MOVWF	ROM_QUAD
		CALL	ROM2SIN
		MOVF	OUTWAV,0
		MOVWF	OUTWAV_1
		RETURN

ROM2SIN	MOVF	ROM_PHASE,0
		BTFSC	ROM_QUAD,0
		COMF	WREG,0
		MOVWF	FSR0L
		MOVLW	PHASE_ROM_H
		MOVWF	FSR0H
		MOVF	INDF0,0
		MOVWF	OUTWAV
		RETURN

STEPENV	INCFSZ	ENV_TIK,1
		RETURN
		INCF	ENV_CNT,1
		MOVF	ENV_CNT,0
		XORLW	36
		BTFSC	STATUS,Z
		BCF	JOBF,FM_EST
		MOVLW	ENV_ROM_H
		MOVWF	FSR1H
		MOVF	ENV_CNT,0
		MOVWF	FSR1L
		MOVF	INDF1,0
		MOVWF	ENV_OUT
		RETURN

APLYENV	MOVF	ENV_OUT,0
		BTFSC	STATUS,Z
		RETURN
LOOPENV		LSRF	OUTWAV_0,1
		DECFSZ	WREG,1
		GOTO	LOOPENV
		RETURN

APLYMD0		MOVF	OUTWAV_0,0
		MOVWF	MODF_0
		LSRF	MODF_0,1
		CLRF	MOD_SIG_0
		BTFSS	P_QUAD_0,1
		RETURN
		BSF	MOD_SIG_0,0
		RETURN

APLYMD1		MOVF	OUTWAV_1,0
		MOVWF	MODF_1
		CLRF	MOD_SIG_1
		BTFSS	P_QUAD_1,1
		RETURN
		BSF	MOD_SIG_1,0
		RETURN

CASTWAV		LSRF	OUTWAV_1,1
		BTFSC	P_QUAD_1,1
		GOTO	CAST_L
CAST_H		BSF	OUTWAV_1,7
		RETURN
CAST_L		COMF	OUTWAV_1,1
		BCF	OUTWAV_1,7
		RETURN

SYNCS		BTFSS	INTFG,0
		GOTO	SYNCS
		INCF	LOOPCNT,1
		CLRF	INTFG
		RETURN

OUT_R2R		MOVF	OUTWAV_1,0
		MOVWF	PORTB
		CLRF	OUTWAV
		CLRF	OUTWAV_0
		CLRF	OUTWAV_1
		RETURN

;ROMs for fm synthesize table
	ORG	800H
	DE	0
	DE	1
	DE	3
	DE	4
	DE	6
	DE	7
	DE	9
	DE	10
	DE	12
	DE	14
	DE	15
	DE	17
	DE	18
	DE	20
	DE	21
	DE	23
	DE	25
	DE	26
	DE	28
	DE	29
	DE	31
	DE	32
	DE	34
	DE	36
	DE	37
	DE	39
	DE	40
	DE	42
	DE	43
	DE	45
	DE	46
	DE	48
	DE	49
	DE	51
	DE	53
	DE	54
	DE	56
	DE	57
	DE	59
	DE	60
	DE	62
	DE	63
	DE	65
	DE	66
	DE	68
	DE	69
	DE	71
	DE	72
	DE	74
	DE	75
	DE	77
	DE	78
	DE	80
	DE	81
	DE	83
	DE	84
	DE	86
	DE	87
	DE	89
	DE	90
	DE	92
	DE	93
	DE	95
	DE	96
	DE	97
	DE	99
	DE	100
	DE	102
	DE	103
	DE	105
	DE	106
	DE	108
	DE	109
	DE	110
	DE	112
	DE	113
	DE	115
	DE	116
	DE	117
	DE	119
	DE	120
	DE	122
	DE	123
	DE	124
	DE	126
	DE	127
	DE	128
	DE	130
	DE	131
	DE	132
	DE	134
	DE	135
	DE	136
	DE	138
	DE	139
	DE	140
	DE	142
	DE	143
	DE	144
	DE	146
	DE	147
	DE	148
	DE	149
	DE	151
	DE	152
	DE	153
	DE	154
	DE	156
	DE	157
	DE	158
	DE	159
	DE	161
	DE	162
	DE	163
	DE	164
	DE	165
	DE	167
	DE	168
	DE	169
	DE	170
	DE	171
	DE	172
	DE	174
	DE	175
	DE	176
	DE	177
	DE	178
	DE	179
	DE	180
	DE	181
	DE	183
	DE	184
	DE	185
	DE	186
	DE	187
	DE	188
	DE	189
	DE	190
	DE	191
	DE	192
	DE	193
	DE	194
	DE	195
	DE	196
	DE	197
	DE	198
	DE	199
	DE	200
	DE	201
	DE	202
	DE	203
	DE	204
	DE	205
	DE	206
	DE	207
	DE	208
	DE	209
	DE	209
	DE	210
	DE	211
	DE	212
	DE	213
	DE	214
	DE	215
	DE	215
	DE	216
	DE	217
	DE	218
	DE	219
	DE	220
	DE	220
	DE	221
	DE	222
	DE	223
	DE	223
	DE	224
	DE	225
	DE	226
	DE	226
	DE	227
	DE	228
	DE	228
	DE	229
	DE	230
	DE	230
	DE	231
	DE	232
	DE	232
	DE	233
	DE	234
	DE	234
	DE	235
	DE	236
	DE	236
	DE	237
	DE	237
	DE	238
	DE	238
	DE	239
	DE	239
	DE	240
	DE	241
	DE	241
	DE	242
	DE	242
	DE	243
	DE	243
	DE	243
	DE	244
	DE	244
	DE	245
	DE	245
	DE	246
	DE	246
	DE	246
	DE	247
	DE	247
	DE	248
	DE	248
	DE	248
	DE	249
	DE	249
	DE	249
	DE	250
	DE	250
	DE	250
	DE	250
	DE	251
	DE	251
	DE	251
	DE	251
	DE	252
	DE	252
	DE	252
	DE	252
	DE	253
	DE	253
	DE	253
	DE	253
	DE	253
	DE	253
	DE	254
	DE	254
	DE	254
	DE	254
	DE	254
	DE	254
	DE	254
	DE	254
	DE	254
	DE	254
	DE	254
	DE	254
	DE	254
	DE	254
	DE	255


	ORG	900H
	DE	8
	DE	7
	DE	6
	DE	5
	DE	4
	DE	3
	DE	3
	DE	3
	DE	3
	DE	3
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	4
	DE	5
	DE	6
	DE	7
	DE	8



	END
