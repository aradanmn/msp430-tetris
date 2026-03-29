/Users/scott/ti/msp430-gcc/bin/msp430-elf-objdump -d ex1.elf

ex1.elf:     file format elf32-msp430


Disassembly of section .text:

0000c000 <_start>:
    c000:	31 40 00 04 	mov	#1024,	r1	;#0x0400
    c004:	b2 40 80 5a 	mov	#23168,	&0x0120	;#0x5a80
    c008:	20 01 
    c00a:	c2 43 56 00 	mov.b	#0,	&0x0056	;r3 As==00
    c00e:	d2 42 ff 10 	mov.b	&0x10ff,&0x0057	;0x10ff
    c012:	57 00 
    c014:	d2 42 fe 10 	mov.b	&0x10fe,&0x0056	;0x10fe
    c018:	56 00 
    c01a:	f2 d0 41 00 	bis.b	#65,	&0x0022	;#0x0041
    c01e:	22 00 
    c020:	f2 c0 41 00 	bic.b	#65,	&0x0021	;#0x0041
    c024:	21 00 

0000c026 <main_loop>:
    c026:	b0 12 34 c0 	call	#-16332	;#0xc034
    c02a:	b0 12 4c c0 	call	#-16308	;#0xc04c
    c02e:	b0 12 6a c0 	call	#-16278	;#0xc06a
    c032:	f9 3f       	jmp	$-12     	;abs 0xc026

0000c034 <state_zero>:
    c034:	58 43       	mov.b	#1,	r8	;r3 As==01
    c036:	3c 40 c8 00 	mov	#200,	r12	;#0x00c8
    c03a:	34 40 c8 00 	mov	#200,	r4	;#0x00c8
    c03e:	b0 12 78 c0 	call	#-16264	;#0xc078
    c042:	b0 12 78 c0 	call	#-16264	;#0xc078
    c046:	b0 12 78 c0 	call	#-16264	;#0xc078
    c04a:	30 41       	ret			

0000c04c <state_one>:
    c04c:	78 40 40 00 	mov.b	#64,	r8	;#0x0040
    c050:	3c 40 64 00 	mov	#100,	r12	;#0x0064
    c054:	34 40 64 00 	mov	#100,	r4	;#0x0064
    c058:	b0 12 78 c0 	call	#-16264	;#0xc078
    c05c:	b0 12 78 c0 	call	#-16264	;#0xc078
    c060:	b0 12 78 c0 	call	#-16264	;#0xc078
    c064:	b0 12 78 c0 	call	#-16264	;#0xc078
    c068:	30 41       	ret			

0000c06a <state_two>:
    c06a:	3c 40 f4 01 	mov	#500,	r12	;#0x01f4
    c06e:	34 40 f4 01 	mov	#500,	r4	;#0x01f4
    c072:	b0 12 8c c0 	call	#-16244	;#0xc08c
    c076:	30 41       	ret			

0000c078 <flash_led>:
    c078:	c2 d8 21 00 	bis.b	r8,	&0x0021	;
    c07c:	b0 12 8c c0 	call	#-16244	;#0xc08c
    c080:	0c 44       	mov	r4,	r12	;
    c082:	c2 c8 21 00 	bic.b	r8,	&0x0021	;
    c086:	b0 12 8c c0 	call	#-16244	;#0xc08c
    c08a:	30 41       	ret			

0000c08c <delay_ms>:
    c08c:	3d 40 4d 01 	mov	#333,	r13	;#0x014d

0000c090 <.Ldms_inner>:
    c090:	1d 83       	dec	r13		;
    c092:	fe 23       	jnz	$-2      	;abs 0xc090
    c094:	1c 83       	dec	r12		;
    c096:	fa 23       	jnz	$-10     	;abs 0xc08c
    c098:	30 41       	ret			

Disassembly of section .vectors:

0000ffe0 <.vectors>:
	...
    fffc:	00 00       	interrupt service routine at 0x0000
    fffe:	00 c0       	interrupt service routine at 0xc000
