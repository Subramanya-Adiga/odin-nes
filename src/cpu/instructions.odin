package cpu

AddressingMode :: enum {
	Accumilate,
	Implied,
	Immediate,
	ZeroPage,
	ZeroPageX,
	ZeroPageY,
	Absolute,
	AbsoluteX,
	AbsoluteY,
	Indirect,
	IndirectX,
	IndirectY,
	Relative,
}

Mnemonic :: enum {
	Nop,
	Adc,
	And,
	Asl,
	Bcc,
	Bcs,
	Beq,
	Bit,
	Bmi,
	Bne,
	Bpl,
	Brk,
	Bvc,
	Bvs,
	Clc,
	Cld,
	Cli,
	Clv,
	Cmp,
	Cpx,
	Cpy,
	Dec,
	Dex,
	Dey,
	Eor,
	Inc,
	Inx,
	Iny,
	Jmp,
	Jsr,
	Lda,
	Ldx,
	Ldy,
	Lsr,
	Ora,
	Pha,
	Php,
	Pla,
	Plp,
	Rol,
	Ror,
	Rti,
	Rts,
	Sbc,
	Sec,
	Sed,
	Sei,
	Sta,
	Stx,
	Sty,
	Tax,
	Tay,
	Tsx,
	Txa,
	Txs,
	Tya,
	//Illegal
	Lax,
	Sax,
	Dcp,
	Isb,
	Slo,
	Rla,
	Sre,
	Rra,
}

Instruction :: struct {
	name:            string,
	mnemonic:        Mnemonic,
	addressing_mode: AddressingMode,
	clock_count:     u8,
}

process_opcode :: proc(opcode: u8) -> Instruction {
	switch (opcode) {
	case 0x69:
		return {"Adc", .Adc, .Immediate, 2}
	case 0x65:
		return {"Adc", .Adc, .ZeroPage, 3}
	case 0x75:
		return {"Adc", .Adc, .ZeroPageX, 4}
	case 0x6D:
		return {"Adc", .Adc, .Absolute, 4}
	case 0x7D:
		return {"Adc", .Adc, .AbsoluteX, 4}
	case 0x79:
		return {"Adc", .Adc, .AbsoluteY, 4}
	case 0x61:
		return {"Adc", .Adc, .IndirectX, 6}
	case 0x71:
		return {"Adc", .Adc, .IndirectY, 5}
	//And
	case 0x29:
		return {"And", .And, .Immediate, 2}
	case 0x25:
		return {"And", .And, .ZeroPage, 3}
	case 0x35:
		return {"And", .And, .ZeroPageX, 4}
	case 0x2D:
		return {"And", .And, .Absolute, 4}
	case 0x3D:
		return {"And", .And, .AbsoluteX, 4}
	case 0x39:
		return {"And", .And, .AbsoluteY, 4}
	case 0x21:
		return {"And", .And, .IndirectX, 6}
	case 0x31:
		return {"And", .And, .IndirectY, 5}
	//ASl
	case 0x0A:
		return {"Asl", .Asl, .Accumilate, 2}
	case 0x06:
		return {"Asl", .Asl, .ZeroPage, 5}
	case 0x16:
		return {"Asl", .Asl, .ZeroPageX, 6}
	case 0x0E:
		return {"Asl", .Asl, .Absolute, 6}
	case 0x1E:
		return {"Asl", .Asl, .AbsoluteX, 7}
	//BCC
	case 0x90:
		return {"Bcc", .Bcc, .Relative, 2}
	//Bcs
	case 0xB0:
		return {"Bcs", .Bcs, .Relative, 2}
	//Beq
	case 0xF0:
		return {"Beq", .Beq, .Relative, 2}
	//Bit
	case 0x24:
		return {"Bit", .Bit, .ZeroPage, 3}
	case 0x2C:
		return {"Bit", .Bit, .Absolute, 4}
	//Bmi
	case 0x30:
		return {"Bmi", .Bmi, .Relative, 2}
	//Bne
	case 0xD0:
		return {"Bne", .Bne, .Relative, 2}
	//Bpl
	case 0x10:
		return {"Bpl", .Bpl, .Relative, 2}
	//Brk
	case 0x00:
		return {"Brk", .Brk, .Implied, 7}
	//Bvc
	case 0x50:
		return {"Bvc", .Bvc, .Relative, 2}
	//Bvs
	case 0x70:
		return {"Bvs", .Bvs, .Relative, 2}
	//Clc
	case 0x18:
		return {"Clc", .Clc, .Implied, 2}
	//Cld
	case 0xD8:
		return {"Cld", .Cld, .Implied, 2}
	//Cli
	case 0x58:
		return {"Cli", .Cli, .Implied, 2}
	//Clv
	case 0xB8:
		return {"Clv", .Clv, .Implied, 2}
	//Cmp
	case 0xC9:
		return {"Cmp", .Cmp, .Immediate, 2}
	case 0xC5:
		return {"Cmp", .Cmp, .ZeroPage, 3}
	case 0xD5:
		return {"Cmp", .Cmp, .ZeroPageX, 4}
	case 0xCD:
		return {"Cmp", .Cmp, .Absolute, 4}
	case 0xDD:
		return {"Cmp", .Cmp, .AbsoluteX, 4}
	case 0xD9:
		return {"Cmp", .Cmp, .AbsoluteY, 4}
	case 0xC1:
		return {"Cmp", .Cmp, .IndirectX, 6}
	case 0xD1:
		return {"Cmp", .Cmp, .IndirectY, 5}
	//Cpx
	case 0xE0:
		return {"Cpx", .Cpx, .Immediate, 2}
	case 0xE4:
		return {"Cpx", .Cpx, .ZeroPage, 3}
	case 0xEC:
		return {"Cpx", .Cpx, .Absolute, 4}
	//Cpy
	case 0xC0:
		return {"Cpy", .Cpy, .Immediate, 2}
	case 0xC4:
		return {"Cpy", .Cpy, .ZeroPage, 3}
	case 0xCC:
		return {"Cpy", .Cpy, .Absolute, 4}
	//Dec
	case 0xC6:
		return {"Dec", .Dec, .ZeroPage, 5}
	case 0xD6:
		return {"Dec", .Dec, .ZeroPageX, 6}
	case 0xCE:
		return {"Dec", .Dec, .Absolute, 6}
	case 0xDE:
		return {"Dec", .Dec, .AbsoluteX, 7}
	//Dex
	case 0xCA:
		return {"Dex", .Dex, .Implied, 2}
	//Dey
	case 0x88:
		return {"Dey", .Dey, .Implied, 2}
	//Eor
	case 0x49:
		return {"Eor", .Eor, .Immediate, 2}
	case 0x45:
		return {"Eor", .Eor, .ZeroPage, 3}
	case 0x55:
		return {"Eor", .Eor, .ZeroPageX, 4}
	case 0x4D:
		return {"Eor", .Eor, .Absolute, 4}
	case 0x5D:
		return {"Eor", .Eor, .AbsoluteX, 4}
	case 0x59:
		return {"Eor", .Eor, .AbsoluteY, 4}
	case 0x41:
		return {"Eor", .Eor, .IndirectX, 6}
	case 0x51:
		return {"Eor", .Eor, .IndirectY, 5}
	//Inc
	case 0xE6:
		return {"Inc", .Inc, .ZeroPage, 5}
	case 0xF6:
		return {"Inc", .Inc, .ZeroPageX, 6}
	case 0xEE:
		return {"Inc", .Inc, .Absolute, 6}
	case 0xFE:
		return {"Inc", .Inc, .AbsoluteX, 7}
	//Inx
	case 0xE8:
		return {"Inx", .Inx, .Implied, 2}
	//Iny
	case 0xC8:
		return {"Iny", .Iny, .Implied, 2}
	//Jmp
	case 0x4C:
		return {"Jmp", .Jmp, .Absolute, 3}
	case 0x6C:
		return {"Jmp", .Jmp, .Indirect, 5}
	//Jsr
	case 0x20:
		return {"Jsr", .Jsr, .Absolute, 6}
	//Lda
	case 0xA9:
		return {"Lda", .Lda, .Immediate, 2}
	case 0xA5:
		return {"Lda", .Lda, .ZeroPage, 3}
	case 0xB5:
		return {"Lda", .Lda, .ZeroPageX, 4}
	case 0xAD:
		return {"Lda", .Lda, .Absolute, 4}
	case 0xBD:
		return {"Lda", .Lda, .AbsoluteX, 4}
	case 0xB9:
		return {"Lda", .Lda, .AbsoluteY, 4}
	case 0xA1:
		return {"Lda", .Lda, .IndirectX, 6}
	case 0xB1:
		return {"Lda", .Lda, .IndirectY, 5}
	//Ldx
	case 0xA2:
		return {"Ldx", .Ldx, .Immediate, 2}
	case 0xA6:
		return {"Ldx", .Ldx, .ZeroPage, 3}
	case 0xB6:
		return {"Ldx", .Ldx, .ZeroPageY, 4}
	case 0xAE:
		return {"Ldx", .Ldx, .Absolute, 4}
	case 0xBE:
		return {"Ldx", .Ldx, .AbsoluteY, 4}
	//Ldy
	case 0xA0:
		return {"Ldy", .Ldy, .Immediate, 2}
	case 0xA4:
		return {"Ldy", .Ldy, .ZeroPage, 3}
	case 0xB4:
		return {"Ldy", .Ldy, .ZeroPageX, 4}
	case 0xAC:
		return {"Ldy", .Ldy, .Absolute, 4}
	case 0xBC:
		return {"Ldy", .Ldy, .AbsoluteX, 4}
	//Lsr
	case 0x4A:
		return {"Lsr", .Lsr, .Accumilate, 2}
	case 0x46:
		return {"Lsr", .Lsr, .ZeroPage, 5}
	case 0x56:
		return {"Lsr", .Lsr, .ZeroPageX, 6}
	case 0x4E:
		return {"Lsr", .Lsr, .Absolute, 6}
	case 0x5E:
		return {"Lsr", .Lsr, .AbsoluteX, 7}
	//Ora
	case 0x09:
		return {"Ora", .Ora, .Immediate, 2}
	case 0x05:
		return {"Ora", .Ora, .ZeroPage, 3}
	case 0x15:
		return {"Ora", .Ora, .ZeroPageX, 4}
	case 0x0D:
		return {"Ora", .Ora, .Absolute, 4}
	case 0x1D:
		return {"Ora", .Ora, .AbsoluteX, 4}
	case 0x19:
		return {"Ora", .Ora, .AbsoluteY, 4}
	case 0x01:
		return {"Ora", .Ora, .IndirectX, 6}
	case 0x11:
		return {"Ora", .Ora, .IndirectY, 5}
	//Nop
	case 0xEA:
		return {"Nop", .Nop, .Implied, 2}
	//Pha
	case 0x48:
		return {"Pha", .Pha, .Implied, 3}
	//Php
	case 0x08:
		return {"Php", .Php, .Implied, 3}
	//Pla
	case 0x68:
		return {"Pla", .Pla, .Implied, 4}
	//Plp
	case 0x28:
		return {"Plp", .Plp, .Implied, 4}
	//Rol
	case 0x2A:
		return {"Rol", .Rol, .Accumilate, 2}
	case 0x26:
		return {"Rol", .Rol, .ZeroPage, 5}
	case 0x36:
		return {"Rol", .Rol, .ZeroPageX, 6}
	case 0x2E:
		return {"Rol", .Rol, .Absolute, 6}
	case 0x3E:
		return {"Rol", .Rol, .AbsoluteX, 7}
	//Ror
	case 0x6A:
		return {"Ror", .Ror, .Accumilate, 2}
	case 0x66:
		return {"Ror", .Ror, .ZeroPage, 5}
	case 0x76:
		return {"Ror", .Ror, .ZeroPageX, 6}
	case 0x6E:
		return {"Ror", .Ror, .Absolute, 6}
	case 0x7E:
		return {"Ror", .Ror, .AbsoluteX, 7}
	//Rti
	case 0x40:
		return {"Rti", .Rti, .Implied, 6}
	//Rts
	case 0x60:
		return {"Rts", .Rts, .Implied, 6}
	//Sbc
	case 0xE9:
		return {"Sbc", .Sbc, .Immediate, 2}
	case 0xE5:
		return {"Sbc", .Sbc, .ZeroPage, 3}
	case 0xF5:
		return {"Sbc", .Sbc, .ZeroPageX, 4}
	case 0xED:
		return {"Sbc", .Sbc, .Absolute, 4}
	case 0xFD:
		return {"Sbc", .Sbc, .AbsoluteX, 4}
	case 0xF9:
		return {"Sbc", .Sbc, .AbsoluteY, 4}
	case 0xE1:
		return {"Sbc", .Sbc, .IndirectX, 6}
	case 0xF1:
		return {"Sbc", .Sbc, .IndirectY, 5}
	//Sec
	case 0x38:
		return {"Sec", .Sec, .Implied, 2}
	//Sed
	case 0xF8:
		return {"Sed", .Sed, .Implied, 2}
	//Sei
	case 0x78:
		return {"Sei", .Sei, .Implied, 2}
	//Sta
	case 0x85:
		return {"Sta", .Sta, .ZeroPage, 3}
	case 0x95:
		return {"Sta", .Sta, .ZeroPageX, 4}
	case 0x8D:
		return {"Sta", .Sta, .Absolute, 4}
	case 0x9D:
		return {"Sta", .Sta, .AbsoluteX, 5}
	case 0x99:
		return {"Sta", .Sta, .AbsoluteY, 5}
	case 0x81:
		return {"Sta", .Sta, .IndirectX, 6}
	case 0x91:
		return {"Sta", .Sta, .IndirectY, 6}
	//Stx
	case 0x86:
		return {"Stx", .Stx, .ZeroPage, 3}
	case 0x96:
		return {"Stx", .Stx, .ZeroPageY, 4}
	case 0x8E:
		return {"Stx", .Stx, .Absolute, 4}
	//Sty
	case 0x84:
		return {"Sty", .Sty, .ZeroPage, 3}
	case 0x94:
		return {"Sty", .Sty, .ZeroPageX, 4}
	case 0x8C:
		return {"Sty", .Sty, .Absolute, 4}
	//Tax
	case 0xAA:
		return {"Tax", .Tax, .Implied, 2}
	//Tay
	case 0xA8:
		return {"Tay", .Tay, .Implied, 2}
	//Tsx
	case 0xBA:
		return {"Tsx", .Tsx, .Implied, 2}
	//Txa
	case 0x8A:
		return {"Txa", .Txa, .Implied, 2}
	//Txs
	case 0x9A:
		return {"Txs", .Txs, .Implied, 2}
	//Tya
	case 0x98:
		return {"Tya", .Tya, .Implied, 2}
	//Illegal Instructions
	//Nop
	case 0x04:
		return {"*Nop", .Nop, .ZeroPage, 3}
	case 0x0C:
		return {"*Nop", .Nop, .Absolute, 4}
	case 0x14:
		return {"*Nop", .Nop, .ZeroPageX, 4}
	case 0x1A:
		return {"*Nop", .Nop, .Implied, 2}
	case 0x1C:
		return {"*Nop", .Nop, .AbsoluteX, 4}
	case 0x34:
		return {"*Nop", .Nop, .ZeroPageX, 4}
	case 0x3A:
		return {"*Nop", .Nop, .Implied, 2}
	case 0x3C:
		return {"*Nop", .Nop, .AbsoluteX, 4}
	case 0x44:
		return {"*Nop", .Nop, .ZeroPage, 3}
	case 0x54:
		return {"*Nop", .Nop, .ZeroPageX, 4}
	case 0x5A:
		return {"*Nop", .Nop, .Implied, 2}
	case 0x5C:
		return {"*Nop", .Nop, .AbsoluteX, 4}
	case 0x64:
		return {"*Nop", .Nop, .ZeroPage, 3}
	case 0x74:
		return {"*Nop", .Nop, .ZeroPageX, 4}
	case 0x7A:
		return {"*Nop", .Nop, .Implied, 2}
	case 0x7C:
		return {"*Nop", .Nop, .AbsoluteX, 4}
	case 0x80:
		return {"*Nop", .Nop, .Immediate, 2}
	case 0x82:
		return {"*Nop", .Nop, .Immediate, 2}
	case 0x89:
		return {"*Nop", .Nop, .Immediate, 2}
	case 0xC2:
		return {"*Nop", .Nop, .Immediate, 3}
	case 0xD4:
		return {"*Nop", .Nop, .ZeroPageX, 4}
	case 0xDA:
		return {"*Nop", .Nop, .Implied, 2}
	case 0xDC:
		return {"*Nop", .Nop, .AbsoluteX, 4}
	case 0xE2:
		return {"*Nop", .Nop, .Immediate, 2}
	case 0xF4:
		return {"*Nop", .Nop, .ZeroPageX, 4}
	case 0xFA:
		return {"*Nop", .Nop, .Implied, 2}
	case 0xFC:
		return {"*Nop", .Nop, .AbsoluteX, 4}
	//Lax
	case 0xA3:
		return {"*LAX", .Lax, .IndirectX, 6}
	case 0xA7:
		return {"*LAX", .Lax, .ZeroPage, 3}
	case 0xAB:
		return {"*LAX", .Lax, .Immediate, 2}
	case 0xAF:
		return {"*LAX", .Lax, .Absolute, 4}
	case 0xB3:
		return {"*LAX", .Lax, .IndirectY, 5}
	case 0xB7:
		return {"*LAX", .Lax, .ZeroPageY, 4}
	case 0xBF:
		return {"*LAX", .Lax, .AbsoluteY, 4}
	//Sax
	case 0x83:
		return {"*Sax", .Sax, .IndirectX, 6}
	case 0x87:
		return {"*Sax", .Sax, .ZeroPage, 3}
	case 0x8F:
		return {"*Sax", .Sax, .Absolute, 4}
	case 0x97:
		return {"*Sax", .Sax, .ZeroPageY, 4}
	//Sbc
	case 0xEB:
		return {"*Sbc", .Sbc, .Immediate, 2}
	//DCP
	case 0xC3:
		return {"*Dcp", .Dcp, .IndirectX, 8}
	case 0xC7:
		return {"*Dcp", .Dcp, .ZeroPage, 5}
	case 0xCF:
		return {"*Dcp", .Dcp, .Absolute, 6}
	case 0xD3:
		return {"*Dcp", .Dcp, .IndirectY, 8}
	case 0xD7:
		return {"*Dcp", .Dcp, .ZeroPageX, 6}
	case 0xDB:
		return {"*Dcp", .Dcp, .AbsoluteY, 7}
	case 0xDF:
		return {"*Dcp", .Dcp, .AbsoluteX, 7}
	//Isc
	case 0xE3:
		return {"*ISB", .Isb, .IndirectX, 8}
	case 0xE7:
		return {"*ISB", .Isb, .ZeroPage, 5}
	case 0xEF:
		return {"*ISB", .Isb, .Absolute, 6}
	case 0xF3:
		return {"*ISB", .Isb, .IndirectY, 8}
	case 0xF7:
		return {"*ISB", .Isb, .ZeroPageX, 6}
	case 0xFB:
		return {"*ISB", .Isb, .AbsoluteY, 7}
	case 0xFF:
		return {"*ISB", .Isb, .AbsoluteX, 7}
	//Slo
	case 0x03:
		return {"*Slo", .Slo, .IndirectX, 8}
	case 0x07:
		return {"*Slo", .Slo, .ZeroPage, 5}
	case 0x0F:
		return {"*Slo", .Slo, .Absolute, 6}
	case 0x13:
		return {"*Slo", .Slo, .IndirectY, 8}
	case 0x17:
		return {"*Slo", .Slo, .ZeroPageX, 6}
	case 0x1B:
		return {"*Slo", .Slo, .AbsoluteY, 7}
	case 0x1F:
		return {"*Slo", .Slo, .AbsoluteX, 7}
	//Rla
	case 0x23:
		return {"*Rla", .Rla, .IndirectX, 8}
	case 0x27:
		return {"*Rla", .Rla, .ZeroPage, 5}
	case 0x2F:
		return {"*Rla", .Rla, .Absolute, 6}
	case 0x33:
		return {"*Rla", .Rla, .IndirectY, 8}
	case 0x37:
		return {"*Rla", .Rla, .ZeroPageX, 6}
	case 0x3B:
		return {"*Rla", .Rla, .AbsoluteY, 7}
	case 0x3F:
		return {"*Rla", .Rla, .AbsoluteX, 7}
	//Sre
	case 0x43:
		return {"*Sre", .Sre, .IndirectX, 8}
	case 0x47:
		return {"*Sre", .Sre, .ZeroPage, 5}
	case 0x4F:
		return {"*Sre", .Sre, .Absolute, 6}
	case 0x53:
		return {"*Sre", .Sre, .IndirectY, 8}
	case 0x57:
		return {"*Sre", .Sre, .ZeroPageX, 6}
	case 0x5B:
		return {"*Sre", .Sre, .AbsoluteY, 7}
	case 0x5F:
		return {"*Sre", .Sre, .AbsoluteX, 7}
	//Rra
	case 0x63:
		return {"*Rra", .Rra, .IndirectX, 8}
	case 0x67:
		return {"*Rra", .Rra, .ZeroPage, 5}
	case 0x6F:
		return {"*Rra", .Rra, .Absolute, 6}
	case 0x73:
		return {"*Rra", .Rra, .IndirectY, 8}
	case 0x77:
		return {"*Rra", .Rra, .ZeroPageX, 6}
	case 0x7B:
		return {"*Rra", .Rra, .AbsoluteY, 7}
	case 0x7F:
		return {"*Rra", .Rra, .AbsoluteX, 7}
	case:
		return {"Nop", .Nop, .Implied, 2}
	}
	return {}
}
