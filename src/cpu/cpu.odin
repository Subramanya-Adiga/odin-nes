package cpu

import "core:fmt"
import "core:io"
import "core:strings"

Dissassembly :: struct {
	pc:          u32,
	instruction: cstring,
}

NesCpu :: struct {
	a:          u8,
	x:          u8,
	y:          u8,
	status:     u8,
	stack_p:    u8,
	cycles:     u32,
	pc:         u16,
	_cpu_state: CpuState,
}

NesCpuFlags :: enum {
	Carry          = (1 << 0),
	Zero           = (1 << 1),
	IntruptDisable = (1 << 2),
	Decimal        = (1 << 3),
	Break          = (1 << 4),
	Unused         = (1 << 5),
	Overflow       = (1 << 6),
	Negative       = (1 << 7),
}

@(private)
CpuState :: struct {
	instruction:  Instruction,
	bus:          ^NesBus,
	pc:           u16,
	op_address:   u16,
	num_bytes:    u16,
	opcode_bytes: [3]u8,
	total_cycles: u32,
	wait_cycles:  u8,
	step_cycles:  u8,
}

init_cpu :: proc(bus: ^NesBus) -> NesCpu {

	fmt.set_user_formatters(new(map[typeid]fmt.User_Formatter))

	err := fmt.register_user_formatter(type_info_of(NesCpu).id, cpu_formatter)
	assert(err == .None)

	state := CpuState {
		bus = bus,
	}
	return {_cpu_state = state}
}

reset :: proc(cpu: ^NesCpu) {
	cpu._cpu_state.op_address = 0xFFFC

	lo := u16(read(cpu._cpu_state.bus, cpu._cpu_state.op_address))
	hi := u16(read(cpu._cpu_state.bus, cpu._cpu_state.op_address + 1))

	cpu.pc = (hi << 8) | lo

	cpu.a = 0
	cpu.x = 0
	cpu.y = 0

	cpu.stack_p = 0xFD

	cpu.status = 0 | u8(NesCpuFlags.Unused) | u8(NesCpuFlags.IntruptDisable)

	cpu._cpu_state.wait_cycles = 0
	cpu._cpu_state.step_cycles = 0
	cpu._cpu_state.instruction = {}
	cpu.cycles = 7

}

clock :: proc(cpu: ^NesCpu) {

	if cpu._cpu_state.wait_cycles > 0 {
		cpu._cpu_state.wait_cycles -= 1
		return
	}

	if cpu._cpu_state.bus.irq && get_flag(cpu, .IntruptDisable) == 0 {
		cpu._cpu_state.bus.irq = false
		irq(cpu)
	}

	if cpu._cpu_state.bus.nmi {
		cpu._cpu_state.bus.nmi = false
		nmi(cpu)
	}

	cpu._cpu_state.step_cycles = 0
	cpu._cpu_state.total_cycles = u32(cpu.cycles)

	cpu._cpu_state.opcode_bytes[0] = read(cpu._cpu_state.bus, cpu.pc)
	cpu._cpu_state.instruction = process_opcode(cpu._cpu_state.opcode_bytes[0])

	set_flag(cpu, .Unused, true)

	cpu._cpu_state.pc = cpu.pc
	cpu.pc += 1
	cpu._cpu_state.step_cycles = cpu._cpu_state.instruction.clock_count

	clk1 := load_address(cpu)

	cpu._cpu_state.num_bytes = cpu.pc - cpu._cpu_state.pc

	clk2 := execute(cpu, cpu._cpu_state.instruction.mnemonic)

	cpu._cpu_state.step_cycles += (clk1 & clk2)
	cpu.cycles += u32(cpu._cpu_state.step_cycles)

	set_flag(cpu, .Unused, true)
	cpu._cpu_state.wait_cycles = cpu._cpu_state.step_cycles - 1
}

complete :: proc(cpu: ^NesCpu) -> bool {
	return cpu._cpu_state.wait_cycles == 0
}

disassemble :: proc(
	cpu: ^NesCpu,
	addr_start: u16,
	addr_end: u16,
	allocator := context.allocator,
) -> [dynamic]Dissassembly {
	cap := addr_end - addr_start
	ret := make([dynamic]Dissassembly, cap, allocator)

	addr := u32(addr_start)
	line_addr: u16 = 0

	for addr <= u32(addr_end) {
		line_addr = u16(addr)

		op := process_opcode(read(cpu._cpu_state.bus, u16(addr)))
		addr += 1

		op_str := fmt.aprintf("{:4X} : {:s}", addr - 1, op.name)
		defer delete(op_str)
		switch op.addressing_mode {
		case .Accumilate:
			{
				str := fmt.aprint("{{ACC}}")
				defer delete(str)
				op_str = strings.join({op_str, str}, " ")
			}
		case .Implied:
			{
				str := fmt.aprint("{{IMP}}")
				defer delete(str)
				op_str = strings.join({op_str, str}, " ")
			}
		case .Immediate:
			{
				val := read(cpu._cpu_state.bus, u16(addr))
				addr += 1
				str := fmt.aprintf("#$ {:2X} {{IMM}}", val)
				defer delete(str)
				op_str = strings.join({op_str, str}, " ")
			}
		case .ZeroPage:
			{
				val := read(cpu._cpu_state.bus, u16(addr))
				addr += 1
				str := fmt.aprintf("#$ {:2X} {{ZP0}}", val)
				defer delete(str)
				op_str = strings.join({op_str, str}, " ")
			}
		case .ZeroPageX:
			{
				val := read(cpu._cpu_state.bus, u16(addr))
				addr += 1
				str := fmt.aprintf("#$ {:2X} , X {{ZPX}}", val)
				defer delete(str)
				op_str = strings.join({op_str, str}, " ")
			}
		case .ZeroPageY:
			{
				val := read(cpu._cpu_state.bus, u16(addr))
				addr += 1
				str := fmt.aprintf("#$ {:2X} , Y {{ZPY}}", val)
				defer delete(str)
				op_str = strings.join({op_str, str}, " ")
			}
		case .Absolute:
			{
				lo := read(cpu._cpu_state.bus, u16(addr))
				hi := read(cpu._cpu_state.bus, u16(addr + 1))
				addr += 2
				str := fmt.aprintf("$ {:2X} {{ABS}}", (hi << 8) | lo)
				defer delete(str)
				op_str = strings.join({op_str, str}, " ")
			}
		case .AbsoluteX:
			{lo := read(cpu._cpu_state.bus, u16(addr))
				hi := read(cpu._cpu_state.bus, u16(addr + 1))
				addr += 2
				str := fmt.aprintf("$ {:2X} , X {{ABS}}", (hi << 8) | lo)
				defer delete(str)
				op_str = strings.join({op_str, str}, " ")}
		case .AbsoluteY:
			{
				lo := read(cpu._cpu_state.bus, u16(addr))
				hi := read(cpu._cpu_state.bus, u16(addr + 1))
				addr += 2
				str := fmt.aprintf("$ {:2X} , Y {{ABS}}", (hi << 8) | lo)
				defer delete(str)
				op_str = strings.join({op_str, str}, " ")
			}
		case .Indirect:
			{
				lo := read(cpu._cpu_state.bus, u16(addr))
				hi := read(cpu._cpu_state.bus, u16(addr + 1))
				addr += 2
				str := fmt.aprintf("$({:2X}) {{IND}}", (hi << 8) | lo)
				defer delete(str)
				op_str = strings.join({op_str, str}, " ")
			}
		case .IndirectX:
			{
				lo := read(cpu._cpu_state.bus, u16(addr))
				hi := read(cpu._cpu_state.bus, u16(addr + 1))
				addr += 1
				str := fmt.aprintf("$({:2X} , X) {{IZX}}", (hi << 8) | lo)
				defer delete(str)
				op_str = strings.join({op_str, str}, " ")
			}
		case .IndirectY:
			{
				lo := read(cpu._cpu_state.bus, u16(addr))
				hi := read(cpu._cpu_state.bus, u16(addr + 1))
				addr += 1
				str := fmt.aprintf("$({:2X} , Y) {{IND}}", (hi << 8) | lo)
				defer delete(str)
				op_str = strings.join({op_str, str}, " ")
			}
		case .Relative:
			{
				val := read(cpu._cpu_state.bus, u16(addr))
				addr += 1
				str := fmt.aprintf("${:2X} [${:2X}] {{REL}}", val, addr + u32(val))
				defer delete(str)
				op_str = strings.join({op_str, str}, " ")
			}
		}
		append(
			&ret,
			Dissassembly{pc = u32(line_addr), instruction = strings.clone_to_cstring(op_str)},
		)
	}

	return ret
}

@(private)
irq :: proc(cpu: ^NesCpu) {
	if get_flag(cpu, .IntruptDisable) == 0 {
		stack_push(cpu, u8((cpu.pc >> 8)) & 0x00FF)
		stack_push(cpu, u8(cpu.pc) & 0x00FF)

		set_flag(cpu, .Break, false)
		set_flag(cpu, .Unused, true)
		set_flag(cpu, .IntruptDisable, true)

		cpu._cpu_state.op_address = 0xFFFE

		lo := u16(read(cpu._cpu_state.bus, cpu._cpu_state.op_address))
		hi := u16(read(cpu._cpu_state.bus, cpu._cpu_state.op_address + 1))

		cpu.pc = (hi << 8) | lo

		cpu.cycles = 7

	}
}

@(private)
nmi :: proc(cpu: ^NesCpu) {
	stack_push(cpu, u8((cpu.pc >> 8)) & 0x00FF)
	stack_push(cpu, u8(cpu.pc) & 0x00FF)

	set_flag(cpu, NesCpuFlags.Break, false)
	set_flag(cpu, NesCpuFlags.Unused, true)
	set_flag(cpu, NesCpuFlags.IntruptDisable, true)

	cpu._cpu_state.op_address = 0xFFFA

	lo := u16(read(cpu._cpu_state.bus, cpu._cpu_state.op_address))
	hi := u16(read(cpu._cpu_state.bus, cpu._cpu_state.op_address + 1))

	cpu.pc = (hi << 8) | lo

	cpu.cycles = 8

}

@(private)
get_flag :: proc(cpu: ^NesCpu, flag: NesCpuFlags) -> u8 {
	return 1 if (cpu.status & u8(flag) > 0) else 0
}

@(private)
set_flag :: proc(cpu: ^NesCpu, flag: NesCpuFlags, cond: bool) {
	if cond {
		cpu.status |= u8(flag)
	} else {
		cpu.status &= ~u8(flag)
	}
}

@(private)
stack_push :: proc(cpu: ^NesCpu, value: u8) {
	write(cpu._cpu_state.bus, 0x100 + u16(cpu.stack_p), value)
	cpu.stack_p -= 1
}

@(private)
stack_pop :: proc(cpu: ^NesCpu) -> u8 {
	cpu.stack_p += 1
	return read(cpu._cpu_state.bus, 0x100 + u16(cpu.stack_p))
}

@(private)
set_nz :: proc(cpu: ^NesCpu, value: u8) {
	set_flag(cpu, .Negative, (value >> 7) != 0)
	set_flag(cpu, .Zero, value == 0)
}

@(private)
branch :: proc(cpu: ^NesCpu, addr: u16) {
	cpu._cpu_state.step_cycles += 1
	cpu._cpu_state.op_address = cpu.pc + addr
	if (cpu._cpu_state.op_address & 0xFF00) != (cpu.pc & 0xFF00) {
		cpu._cpu_state.step_cycles += 1
	}
	cpu.pc = cpu._cpu_state.op_address
}

@(private)
load_address :: proc(cpu: ^NesCpu) -> u8 {
	switch (cpu._cpu_state.instruction.addressing_mode) {
	case .Immediate:
		{
			cpu._cpu_state.opcode_bytes[1] = read(cpu._cpu_state.bus, cpu.pc)
			cpu._cpu_state.op_address = cpu.pc
			cpu.pc += 1
			return 0
		}
	case .ZeroPage:
		{
			cpu._cpu_state.opcode_bytes[1] = read(cpu._cpu_state.bus, cpu.pc)
			cpu._cpu_state.op_address = u16(cpu._cpu_state.opcode_bytes[1])
			cpu.pc += 1
			cpu._cpu_state.op_address &= 0x00FF
			return 0
		}
	case .ZeroPageX:
		{
			cpu._cpu_state.opcode_bytes[1] = read(cpu._cpu_state.bus, cpu.pc)
			cpu._cpu_state.op_address = u16(cpu._cpu_state.opcode_bytes[1]) + u16(cpu.x)
			cpu.pc += 1
			cpu._cpu_state.op_address &= 0x00FF
			return 0
		}
	case .ZeroPageY:
		{
			cpu._cpu_state.opcode_bytes[1] = read(cpu._cpu_state.bus, cpu.pc)
			cpu._cpu_state.op_address = u16(cpu._cpu_state.opcode_bytes[1]) + u16(cpu.y)
			cpu.pc += 1
			cpu._cpu_state.op_address &= 0x00FF
			return 0
		}
	case .Absolute:
		{
			cpu._cpu_state.opcode_bytes[1] = read(cpu._cpu_state.bus, cpu.pc)
			cpu._cpu_state.opcode_bytes[2] = read(cpu._cpu_state.bus, cpu.pc + 1)
			cpu.pc += 2

			lo := u16(cpu._cpu_state.opcode_bytes[1])
			hi := u16(cpu._cpu_state.opcode_bytes[2])

			cpu._cpu_state.op_address = (hi << 8) | lo
			return 0
		}
	case .AbsoluteX:
		{
			cpu._cpu_state.opcode_bytes[1] = read(cpu._cpu_state.bus, cpu.pc)
			cpu._cpu_state.opcode_bytes[2] = read(cpu._cpu_state.bus, cpu.pc + 1)
			cpu.pc += 2

			lo := u16(cpu._cpu_state.opcode_bytes[1])
			hi := u16(cpu._cpu_state.opcode_bytes[2])

			cpu._cpu_state.op_address = ((hi << 8) | lo) + u16(cpu.x)

			if cpu._cpu_state.op_address & 0xFF00 != (hi << 8) {
				return 1
			}

			return 0
		}
	case .AbsoluteY:
		{
			cpu._cpu_state.opcode_bytes[1] = read(cpu._cpu_state.bus, cpu.pc)
			cpu._cpu_state.opcode_bytes[2] = read(cpu._cpu_state.bus, cpu.pc + 1)
			cpu.pc += 2

			lo := u16(cpu._cpu_state.opcode_bytes[1])
			hi := u16(cpu._cpu_state.opcode_bytes[2])

			cpu._cpu_state.op_address = ((hi << 8) | lo) + u16(cpu.y)

			if cpu._cpu_state.op_address & 0xFF00 != (hi << 8) {
				return 1
			}
			return 0
		}
	case .Indirect:
		{
			cpu._cpu_state.opcode_bytes[1] = read(cpu._cpu_state.bus, cpu.pc)
			cpu._cpu_state.opcode_bytes[2] = read(cpu._cpu_state.bus, cpu.pc + 1)
			cpu.pc += 2

			lo := u16(cpu._cpu_state.opcode_bytes[1])
			hi := u16(cpu._cpu_state.opcode_bytes[2])

			itrm_data := ((hi << 8) | lo) + u16(cpu.y)

			if lo == 0x00FF {
				cpu._cpu_state.op_address =
					u16(read(cpu._cpu_state.bus, itrm_data & 0xFF00)) << 8 |
					u16(read(cpu._cpu_state.bus, itrm_data))
			} else {
				cpu._cpu_state.op_address =
					u16(read(cpu._cpu_state.bus, itrm_data + 1)) << 8 |
					u16(read(cpu._cpu_state.bus, itrm_data))
			}
			return 0
		}
	case .IndirectX:
		{
			cpu._cpu_state.opcode_bytes[1] = read(cpu._cpu_state.bus, cpu.pc)
			data := u16(cpu._cpu_state.opcode_bytes[1])
			cpu.pc += 1

			lo := u16(read(cpu._cpu_state.bus, u16(data + u16(cpu.x)) & 0x00FF))
			hi := u16(read(cpu._cpu_state.bus, u16(data + u16(cpu.x) + 1) & 0x00FF))

			cpu._cpu_state.op_address = (hi << 8) | lo
			return 0
		}
	case .IndirectY:
		{
			cpu._cpu_state.opcode_bytes[1] = read(cpu._cpu_state.bus, cpu.pc)
			data := u16(cpu._cpu_state.opcode_bytes[1])
			cpu.pc += 1

			lo := u16(read(cpu._cpu_state.bus, data & 0x00FF))
			hi := u16(read(cpu._cpu_state.bus, (data + 1) & 0x00FF))

			cpu._cpu_state.op_address = ((hi << 8) | lo) + u16(cpu.y)

			if (cpu._cpu_state.op_address & 0xFF00) != (hi << 8) {
				return 1
			}
			return 0
		}
	case .Relative:
		{
			cpu._cpu_state.opcode_bytes[1] = read(cpu._cpu_state.bus, cpu.pc)
			cpu.pc += 1
			cpu._cpu_state.op_address = u16(cpu._cpu_state.opcode_bytes[1])

			if cpu._cpu_state.op_address & 0x80 != 0 {
				cpu._cpu_state.op_address |= 0xFF00
			}
			return 0
		}
	case .Accumilate, .Implied:
		{return 0}

	}
	return 0
}

@(private)
execute :: proc(cpu: ^NesCpu, mnemonic: Mnemonic) -> u8 {
	switch (mnemonic) {
	case .Nop:
		{
			switch (cpu._cpu_state.opcode_bytes[0]) {
			case 0x1C, 0x3C, 0x5C, 0x7C, 0xDC, 0xFC:
				return 1
			case:
				return 0
			}
		}
	case .Adc:
		{
			add_op := read(cpu._cpu_state.bus, cpu._cpu_state.op_address)

			res := u16(cpu.a) + u16(add_op) + u16(get_flag(cpu, .Carry))
			set_flag(cpu, .Carry, res > 255)
			set_flag(cpu, .Zero, (res & 0x00FF) == 0)

			cond := (~(cpu.a ~ add_op) & (cpu.a ~ u8(res))) & 0x0080
			set_flag(cpu, .Overflow, cond != 0)
			set_flag(cpu, .Negative, (res & 0x80) != 0)
			cpu.a = u8(res & 0x00FF)
			return 1
		}
	case .And:
		{
			cpu.a = cpu.a & read(cpu._cpu_state.bus, cpu._cpu_state.op_address)
			set_nz(cpu, cpu.a)
			return 1
		}
	case .Asl:
		{
			if cpu._cpu_state.instruction.addressing_mode == .Accumilate {
				set_flag(cpu, .Carry, (cpu.a >> 7) != 0)
				cpu.a <<= 1
				set_nz(cpu, cpu.a)
			} else {
				op := read(cpu._cpu_state.bus, cpu._cpu_state.op_address)
				res := op << 1
				write(cpu._cpu_state.bus, cpu._cpu_state.op_address, res)
				set_flag(cpu, .Carry, (op >> 7) != 0)
				set_nz(cpu, res)
			}
			return 0
		}
	case .Bcc:
		{
			if get_flag(cpu, .Carry) == 0 {
				branch(cpu, cpu._cpu_state.op_address)
			}
			return 0
		}
	case .Bcs:
		{
			if get_flag(cpu, .Carry) == 1 {
				branch(cpu, cpu._cpu_state.op_address)
			}
			return 0
		}
	case .Beq:
		{
			if get_flag(cpu, .Zero) == 1 {
				branch(cpu, cpu._cpu_state.op_address)
			}
			return 0
		}
	case .Bit:
		{
			op := read(cpu._cpu_state.bus, cpu._cpu_state.op_address)
			set_flag(cpu, .Zero, (cpu.a & op) == 0)
			set_flag(cpu, .Negative, (op & (1 << 7)) != 0)
			set_flag(cpu, .Overflow, (op & (1 << 6)) != 0)
			return 0
		}
	case .Bmi:
		{
			if get_flag(cpu, .Negative) == 1 {
				branch(cpu, cpu._cpu_state.op_address)
			}
			return 0
		}
	case .Bne:
		{
			if get_flag(cpu, .Zero) == 0 {
				branch(cpu, cpu._cpu_state.op_address)
			}
			return 0
		}
	case .Bpl:
		{
			if get_flag(cpu, .Negative) == 0 {
				branch(cpu, cpu._cpu_state.op_address)
			}
			return 0
		}
	case .Brk:
		{
			cpu.pc += 1
			set_flag(cpu, .IntruptDisable, true)
			stack_push(cpu, u8(cpu.pc >> 8) & 0x00FF)
			stack_push(cpu, u8(cpu.pc & 0x00FF))

			set_flag(cpu, .Break, true)
			stack_push(cpu, cpu.status)
			set_flag(cpu, .Break, false)

			cpu.pc = u16(read(cpu._cpu_state.bus, 0xFFFE)) | u16(read(cpu._cpu_state.bus, 0xFFFF))
			return 0

		}
	case .Bvc:
		{
			if get_flag(cpu, .Overflow) == 0 {
				branch(cpu, cpu._cpu_state.op_address)
			}
			return 0
		}
	case .Bvs:
		{
			if get_flag(cpu, .Overflow) == 1 {
				branch(cpu, cpu._cpu_state.op_address)
			}
			return 0
		}
	case .Clc:
		{
			set_flag(cpu, .Carry, false)
			return 0
		}
	case .Cld:
		{
			set_flag(cpu, .Decimal, false)
			return 0
		}
	case .Cli:
		{
			set_flag(cpu, .IntruptDisable, false)
			return 0
		}
	case .Clv:
		{
			set_flag(cpu, .Overflow, false)
			return 0
		}
	case .Cmp:
		{
			tmp := read(cpu._cpu_state.bus, cpu._cpu_state.op_address)
			res := cpu.a - tmp
			set_flag(cpu, .Carry, cpu.a >= tmp)
			set_nz(cpu, res)
			return 1
		}
	case .Cpx:
		{
			tmp := read(cpu._cpu_state.bus, cpu._cpu_state.op_address)
			res := cpu.x - tmp
			set_flag(cpu, .Carry, cpu.x >= tmp)
			set_nz(cpu, res)
			return 0
		}
	case .Cpy:
		{
			tmp := read(cpu._cpu_state.bus, cpu._cpu_state.op_address)
			res := cpu.y - tmp
			set_flag(cpu, .Carry, cpu.y >= tmp)
			set_nz(cpu, res)
			return 0
		}
	case .Dec:
		{
			tmp := read(cpu._cpu_state.bus, cpu._cpu_state.op_address) - 1
			write(cpu._cpu_state.bus, cpu._cpu_state.op_address, tmp)
			set_nz(cpu, tmp)
			return 0
		}
	case .Dex:
		{
			cpu.x -= 1
			set_nz(cpu, cpu.x)
			return 0
		}
	case .Dey:
		{
			cpu.y -= 1
			set_nz(cpu, cpu.y)
			return 0
		}
	case .Eor:
		{
			cpu.a = cpu.a ~ read(cpu._cpu_state.bus, cpu._cpu_state.op_address)
			set_nz(cpu, cpu.a)
			return 1
		}
	case .Inc:
		{
			tmp := read(cpu._cpu_state.bus, cpu._cpu_state.op_address) + 1
			write(cpu._cpu_state.bus, cpu._cpu_state.op_address, tmp)
			set_nz(cpu, tmp)
			return 0
		}
	case .Inx:
		{
			cpu.x += 1
			set_nz(cpu, cpu.x)
			return 0
		}
	case .Iny:
		{
			cpu.y += 1
			set_nz(cpu, cpu.y)
			return 0
		}
	case .Jmp:
		{
			cpu.pc = cpu._cpu_state.op_address
			return 0
		}
	case .Jsr:
		{
			cpu.pc -= 1
			stack_push(cpu, u8(cpu.pc >> 8) & 0x00FF)
			stack_push(cpu, u8(cpu.pc & 0x00FF))
			cpu.pc = cpu._cpu_state.op_address
			return 0
		}
	case .Lda:
		{
			cpu.a = read(cpu._cpu_state.bus, cpu._cpu_state.op_address)
			set_nz(cpu, cpu.a)
			return 1
		}
	case .Ldx:
		{
			cpu.x = read(cpu._cpu_state.bus, cpu._cpu_state.op_address)
			set_nz(cpu, cpu.x)
			return 1
		}
	case .Ldy:
		{
			cpu.y = read(cpu._cpu_state.bus, cpu._cpu_state.op_address)
			set_nz(cpu, cpu.y)
			return 1
		}
	case .Lsr:
		{
			if cpu._cpu_state.instruction.addressing_mode == .Accumilate {
				set_flag(cpu, .Carry, (cpu.a & 0x0001) != 0)
				cpu.a >>= 1
				set_nz(cpu, cpu.a)
			} else {
				op := read(cpu._cpu_state.bus, cpu._cpu_state.op_address)
				res := op >> 1
				write(cpu._cpu_state.bus, cpu._cpu_state.op_address, res)
				set_flag(cpu, .Carry, (op & 0x0001) != 0)
				set_nz(cpu, res)
			}
			return 0
		}
	case .Ora:
		{
			cpu.a |= read(cpu._cpu_state.bus, cpu._cpu_state.op_address)
			set_nz(cpu, cpu.a)
			return 1
		}
	case .Pha:
		{
			stack_push(cpu, cpu.a)
			return 0
		}
	case .Php:
		{
			stack_push(cpu, cpu.status | u8(NesCpuFlags.Break) | u8(NesCpuFlags.Unused))
			set_flag(cpu, .Break, false)
			set_flag(cpu, .Unused, false)
			return 0
		}
	case .Pla:
		{
			cpu.a = stack_pop(cpu)
			set_nz(cpu, cpu.a)
			return 0
		}
	case .Plp:
		{
			cpu.status = stack_pop(cpu)
			set_flag(cpu, .Break, false)
			set_flag(cpu, .Unused, true)
			return 0
		}
	case .Rol:
		{
			if cpu._cpu_state.instruction.addressing_mode == .Accumilate {
				res := cpu.a << 1 | get_flag(cpu, .Carry)
				set_flag(cpu, .Carry, (cpu.a >> 7) != 0)
				cpu.a = res
				set_nz(cpu, cpu.a)
			} else {
				op := read(cpu._cpu_state.bus, cpu._cpu_state.op_address)
				res := op << 1 | get_flag(cpu, .Carry)
				write(cpu._cpu_state.bus, cpu._cpu_state.op_address, res)
				set_flag(cpu, .Carry, (op >> 7) != 0)
				set_nz(cpu, res)
			}
			return 0
		}
	case .Ror:
		{
			if cpu._cpu_state.instruction.addressing_mode == .Accumilate {
				op := cpu.a
				cpu.a = op >> 1 | (get_flag(cpu, .Carry) << 7)
				set_flag(cpu, .Carry, (op & 0x01) != 0)
				set_nz(cpu, cpu.a)
			} else {
				op := read(cpu._cpu_state.bus, cpu._cpu_state.op_address)
				res := (op >> 1) | (get_flag(cpu, .Carry) << 7)
				write(cpu._cpu_state.bus, cpu._cpu_state.op_address, res)
				set_flag(cpu, .Carry, (op & 0x01) != 0)
				set_nz(cpu, res)
			}
			return 0
		}
	case .Rti:
		{
			cpu.status = stack_pop(cpu)
			cpu.status &= ~u8(NesCpuFlags.Break)
			cpu.status &= ~u8(NesCpuFlags.Unused)

			cpu.pc = u16(stack_pop(cpu))
			cpu.pc |= u16(stack_pop(cpu)) << 8
			return 0
		}
	case .Rts:
		{
			cpu.pc = u16(stack_pop(cpu))
			cpu.pc |= u16(stack_pop(cpu)) << 8
			cpu.pc += 1
			return 0
		}
	case .Sbc:
		{
			sub_op := read(cpu._cpu_state.bus, cpu._cpu_state.op_address)
			val := u16(sub_op) ~ 0x00FF

			op := u16(cpu.a) + val + u16(get_flag(cpu, .Carry))

			set_flag(cpu, .Carry, (op & 0xFF00) != 0)
			set_flag(cpu, .Zero, (op & 0x00FF) == 0)
			set_flag(cpu, .Overflow, ((op ~ u16(cpu.a)) & (op ~ val) & 0x0080) != 0)
			set_flag(cpu, .Negative, (op & 0x0080) != 0)
			cpu.a = u8(op & 0x00FF)

			return 1
		}
	case .Sec:
		{
			set_flag(cpu, .Carry, true)
			return 0
		}
	case .Sed:
		{
			set_flag(cpu, .Decimal, true)
			return 0
		}
	case .Sei:
		{
			set_flag(cpu, .IntruptDisable, true)
			return 0
		}
	case .Sta:
		{
			write(cpu._cpu_state.bus, cpu._cpu_state.op_address, cpu.a)
			return 0
		}
	case .Stx:
		{
			write(cpu._cpu_state.bus, cpu._cpu_state.op_address, cpu.x)
			return 0
		}
	case .Sty:
		{
			write(cpu._cpu_state.bus, cpu._cpu_state.op_address, cpu.y)
			return 0
		}
	case .Tax:
		{
			cpu.x = cpu.a
			set_nz(cpu, cpu.x)
			return 0
		}
	case .Tay:
		{
			cpu.y = cpu.a
			set_nz(cpu, cpu.y)
			return 0
		}
	case .Tsx:
		{
			cpu.x = cpu.stack_p
			set_nz(cpu, cpu.x)
			return 0
		}
	case .Txa:
		{
			cpu.a = cpu.x
			set_nz(cpu, cpu.a)
			return 0
		}
	case .Txs:
		{
			cpu.stack_p = cpu.x
			return 0
		}
	case .Tya:
		{
			cpu.a = cpu.y
			set_nz(cpu, cpu.a)
			return 0
		}
	//Illegal
	case .Lax:
		{
			if cpu._cpu_state.instruction.addressing_mode == .Immediate {
				execute(cpu, .Lda)
				execute(cpu, .Tax)
			} else {
				execute(cpu, .Lda)
				execute(cpu, .Ldx)
			}
			set_nz(cpu, cpu.a | cpu.x)
			if cpu._cpu_state.instruction.addressing_mode == .AbsoluteY ||
			   cpu._cpu_state.instruction.addressing_mode == .IndirectY {
				return 1
			}
			return 0
		}
	case .Sax:
		{
			write(cpu._cpu_state.bus, cpu._cpu_state.op_address, cpu.a & cpu.x)
			return 0
		}
	case .Dcp:
		{
			execute(cpu, .Dec)
			execute(cpu, .Cmp)
			return 0
		}
	case .Isb:
		{
			execute(cpu, .Inc)
			execute(cpu, .Sbc)
			return 0
		}
	case .Slo:
		{
			execute(cpu, .Asl)
			execute(cpu, .Ora)
			return 0
		}
	case .Rla:
		{
			execute(cpu, .Rol)
			execute(cpu, .And)
			return 0
		}
	case .Sre:
		{
			execute(cpu, .Lsr)
			execute(cpu, .Eor)
			return 0
		}
	case .Rra:
		{
			execute(cpu, .Ror)
			execute(cpu, .Adc)
			return 0
		}
	}
	return 0
}

@(private)
cpu_formatter :: proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool {
	cpu := cast(^NesCpu)arg.data
	switch verb {
	case 'v':
		{

			fmt.wprintf(fi.writer, "{:4X}  ", cpu._cpu_state.pc)

			for idx in 0 ..= 3 {
				if idx < int(cpu._cpu_state.num_bytes) {
					fmt.wprintf(fi.writer, "{:2X} ", cpu._cpu_state.opcode_bytes[idx])
				} else {
					fmt.wprint(fi.writer, "   ")
				}
			}

			fmt.wprintf(fi.writer, " {:s} ", cpu._cpu_state.instruction.name)

			switch cpu._cpu_state.instruction.addressing_mode {
			case .Accumilate:
				{
					fmt.wprintf(fi.writer, "A{:27s}", " ")
				}
			case .Implied:
				{
					fmt.wprintf(fi.writer, "{:28s}", " ")
				}
			case .Immediate:
				{
					fmt.wprintf(
						fi.writer,
						"#${:2X}{:24s}",
						read(cpu._cpu_state.bus, cpu._cpu_state.op_address),
						" ",
					)
				}
			case .ZeroPage:
				{
					fmt.wprintf(
						fi.writer,
						"${:2X} = {:2X}{:20s}",
						cpu._cpu_state.op_address,
						read(cpu._cpu_state.bus, u16(cpu._cpu_state.opcode_bytes[1])),
						" ",
					)
				}
			case .ZeroPageX:
				{
					fmt.wprintf(
						fi.writer,
						"${:2X},X @ {:2X} = {:2X}{:13s}",
						cpu._cpu_state.op_address - u16(cpu.x),
						cpu._cpu_state.op_address,
						read(cpu._cpu_state.bus, cpu._cpu_state.op_address + u16(cpu.x)),
						" ",
					)
				}
			case .ZeroPageY:
				{
					fmt.wprintf(
						fi.writer,
						"${:2X},Y @ {:2X} = {:2X}{:13s}",
						cpu._cpu_state.op_address - u16(cpu.y),
						cpu._cpu_state.op_address,
						read(cpu._cpu_state.bus, cpu._cpu_state.op_address + u16(cpu.y)),
						" ",
					)
				}
			case .Absolute:
				{
					if cpu._cpu_state.instruction.mnemonic == .Jsr ||
					   cpu._cpu_state.instruction.mnemonic == .Jmp {
						fmt.wprintf(fi.writer, "${:4X}{:23s}", cpu._cpu_state.op_address, " ")
					} else {
						fmt.wprintf(
							fi.writer,
							"${:4X} = {:2X}{:18s}",
							cpu._cpu_state.op_address,
							read(cpu._cpu_state.bus, cpu._cpu_state.op_address),
							" ",
						)
					}
				}
			case .AbsoluteX:
				{
					fmt.wprintf(
						fi.writer,
						"${:4X},X @ {:4X} = {:2X}{:9s}",
						cpu._cpu_state.op_address - u16(cpu.x),
						cpu._cpu_state.op_address,
						read(cpu._cpu_state.bus, cpu._cpu_state.op_address - u16(cpu.x)),
						" ",
					)
				}
			case .AbsoluteY:
				{
					fmt.wprintf(
						fi.writer,
						"${:4X},Y @ {:4X} = {:2X}{:9s}",
						cpu._cpu_state.op_address - u16(cpu.y),
						cpu._cpu_state.op_address,
						read(cpu._cpu_state.bus, cpu._cpu_state.op_address - u16(cpu.y)),
						" ",
					)
				}
			case .Indirect:
				{
					lo := u16(cpu._cpu_state.opcode_bytes[1])
					hi := u16(cpu._cpu_state.opcode_bytes[2])
					fmt.wprintf(
						fi.writer,
						"(${:4X}) = {:4X}{:14s}",
						(hi << 8) | lo,
						cpu._cpu_state.op_address,
						" ",
					)
				}
			case .IndirectX:
				{
					fmt.wprintf(
						fi.writer,
						"(${:2X},X) @ {:2X} = {:4X} = {:2X}    ",
						cpu._cpu_state.opcode_bytes[1],
						cpu._cpu_state.opcode_bytes[1] + cpu.x,
						cpu._cpu_state.op_address,
						read(cpu._cpu_state.bus, cpu._cpu_state.op_address + u16(cpu.x)),
					)
				}
			case .IndirectY:
				{
					fmt.wprintf(
						fi.writer,
						"(${:2X}),Y = {:4X} @ {:4X} = {:2X}  ",
						cpu._cpu_state.opcode_bytes[1],
						cpu._cpu_state.op_address - u16(cpu.y),
						cpu._cpu_state.op_address,
						read(cpu._cpu_state.bus, cpu._cpu_state.op_address - u16(cpu.y)),
					)
				}
			case .Relative:
				{
					val := read(cpu._cpu_state.bus, cpu._cpu_state.pc + 1)
					addr := cpu._cpu_state.pc + 2
					fmt.wprintf(fi.writer, "${:4X}{:23s}", addr + u16(val), " ")
				}
			}

			fmt.wprintf(
				fi.writer,
				"A:{:02X} X:{:02X} Y:{:02X} P:{:02X} SP:{:02X} PPU:{:d},{:d} CYC:{:d}",
				cpu.a,
				cpu.x,
				cpu.y,
				cpu.status,
				cpu.stack_p,
				0,
				0,
				cpu._cpu_state.total_cycles,
			)
		}
	case:
		return false
	}
	return true
}
