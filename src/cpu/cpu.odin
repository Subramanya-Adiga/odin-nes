package cpu

NesCpu :: struct {
	a:       u8,
	x:       u8,
	y:       u8,
	status:  u8,
	pc:      u16,
	stack_p: u16,
	cycles:  u8,
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

@(private)
cpu_state: CpuState


init_cpu :: proc(bus: ^NesBus) -> NesCpu {
	cpu_state.bus = bus
	return {}
}

reset :: proc(cpu: ^NesCpu) {
	cpu_state.op_address = 0xFFFC

	lo := read(cpu_state.bus, cpu_state.op_address)
	hi := read(cpu_state.bus, cpu_state.op_address + 1)

	cpu.pc = cast(u16)(hi << 8) | cast(u16)lo

	cpu.a = 0
	cpu.x = 0
	cpu.y = 0

	cpu.stack_p = 0xFD

	cpu.status = 0 | u8(NesCpuFlags.Unused) | u8(NesCpuFlags.IntruptDisable)

	cpu_state.wait_cycles = 0
	cpu_state.step_cycles = 0
	cpu_state.instruction = {}
	cpu.cycles = 7

}

clock :: proc(cpu: ^NesCpu) {
	if cpu_state.wait_cycles > 0 {
		cpu_state.wait_cycles -= 1
		return
	}

	if cpu_state.bus.irq && get_flag(cpu, .IntruptDisable) == 0 {
		irq(cpu)
	}

	if cpu_state.bus.nmi {
		nmi(cpu)
	}

	cpu_state.step_cycles = 0
	cpu_state.total_cycles = u32(cpu.cycles)

	cpu_state.opcode_bytes[0] = read(cpu_state.bus, cpu.pc)
	cpu_state.instruction = process_opcode(cpu_state.opcode_bytes[0])
	set_flag(cpu, .Unused, true)

	cpu_state.pc = cpu.pc
	cpu.pc += 1
	cpu_state.step_cycles = cpu_state.instruction.clock_count

	clk1 := load_address(cpu)

	cpu_state.num_bytes = cpu.pc - cpu_state.pc

	//clk2:= execute(cpu, cpu_state.instruction.mnemonic)

	cpu_state.step_cycles += clk1 //(&clk2)
	cpu.cycles += cpu_state.step_cycles

	set_flag(cpu, .Unused, true)
	cpu_state.wait_cycles = cpu_state.step_cycles - 1
}

complete :: proc(cpu: ^NesCpu) -> bool {
	return cpu_state.wait_cycles == 0
}

@(private)
irq :: proc(cpu: ^NesCpu) {
	if get_flag(cpu, .IntruptDisable) == 0 {
		stack_push(cpu, u8((cpu.pc >> 8)) & 0x00FF)
		stack_push(cpu, u8(cpu.pc) & 0x00FF)

		set_flag(cpu, .Break, false)
		set_flag(cpu, .Unused, true)
		set_flag(cpu, .IntruptDisable, true)

		cpu_state.op_address = 0xFFFE

		lo := u16(read(cpu_state.bus, cpu_state.op_address))
		hi := u16(read(cpu_state.bus, cpu_state.op_address + 1))

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

	cpu_state.op_address = 0xFFFE

	lo := u16(read(cpu_state.bus, cpu_state.op_address))
	hi := u16(read(cpu_state.bus, cpu_state.op_address + 1))

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
	write(cpu_state.bus, 0x100 + cpu.stack_p, value)
	cpu.stack_p -= 1
}

@(private)
stack_pop :: proc(cpu: ^NesCpu) -> u8 {
	cpu.stack_p += 1
	return read(cpu_state.bus, 0x100 + cpu.stack_p)
}

@(private)
set_nz :: proc(cpu: ^NesCpu, value: u8) {
	set_flag(cpu, .Negative, (value >> 7) != 0)
	set_flag(cpu, .Zero, value == 0)
}

@(private)
branch :: proc(cpu: ^NesCpu, addr: u16) {
	cpu_state.step_cycles += 1
	cpu_state.op_address = cpu.pc + addr
	if cpu_state.op_address & 0xFF00 != cpu.pc & 0xFF00 {
		cpu_state.step_cycles += 1
	}
	cpu.pc = cpu_state.op_address
}

@(private)
load_address :: proc(cpu: ^NesCpu) -> u8 {
	switch (cpu_state.instruction.addressing_mode) {
	case .Immediate:
		{
			cpu_state.opcode_bytes[1] = read(cpu_state.bus, cpu.pc)
			cpu_state.op_address = cpu.pc
			cpu.pc += 1
			return 0
		}
	case .ZeroPage:
		{
			cpu_state.opcode_bytes[1] = read(cpu_state.bus, cpu.pc)
			cpu_state.op_address = u16(cpu_state.opcode_bytes[1])
			cpu.pc += 1
			cpu_state.op_address &= 0x00FF
			return 0
		}
	case .ZeroPageX:
		{
			cpu_state.opcode_bytes[1] = read(cpu_state.bus, cpu.pc)
			cpu_state.op_address = u16(cpu_state.opcode_bytes[1]) + u16(cpu.x)
			cpu.pc += 1
			cpu_state.op_address &= 0x00FF
			return 0
		}
	case .ZeroPageY:
		{
			cpu_state.opcode_bytes[1] = read(cpu_state.bus, cpu.pc)
			cpu_state.op_address = u16(cpu_state.opcode_bytes[1]) + u16(cpu.y)
			cpu.pc += 1
			cpu_state.op_address &= 0x00FF
			return 0
		}
	case .Absolute:
		{
			cpu_state.opcode_bytes[1] = read(cpu_state.bus, cpu.pc)
			cpu_state.opcode_bytes[2] = read(cpu_state.bus, cpu.pc + 1)
			cpu.pc += 2

			cpu_state.op_address =
				u16(cpu_state.opcode_bytes[2] << 8) | u16(cpu_state.opcode_bytes[1])
			return 0
		}
	case .AbsoluteX:
		{
			cpu_state.opcode_bytes[1] = read(cpu_state.bus, cpu.pc)
			cpu_state.opcode_bytes[2] = read(cpu_state.bus, cpu.pc + 1)
			cpu.pc += 2

			cpu_state.op_address =
				u16(cpu_state.opcode_bytes[2] << 8) | u16(cpu_state.opcode_bytes[1]) + u16(cpu.x)

			if cpu_state.op_address & 0xFF00 != u16(cpu_state.opcode_bytes[2] << 8) {
				return 1
			}

			return 0
		}
	case .AbsoluteY:
		{
			cpu_state.opcode_bytes[1] = read(cpu_state.bus, cpu.pc)
			cpu_state.opcode_bytes[2] = read(cpu_state.bus, cpu.pc + 1)
			cpu.pc += 2

			cpu_state.op_address =
				u16(cpu_state.opcode_bytes[2] << 8) | u16(cpu_state.opcode_bytes[1]) + u16(cpu.y)

			if cpu_state.op_address & 0xFF00 != u16(cpu_state.opcode_bytes[2] << 8) {
				return 1
			}
			return 0
		}
	case .Indirect:
		{
			cpu_state.opcode_bytes[1] = read(cpu_state.bus, cpu.pc)
			cpu_state.opcode_bytes[2] = read(cpu_state.bus, cpu.pc + 1)
			cpu.pc += 2

			itrm_data :=
				u16(cpu_state.opcode_bytes[2] << 8) | u16(cpu_state.opcode_bytes[1]) + u16(cpu.y)

			if u16(cpu_state.opcode_bytes[1]) == 0x00FF {
				cpu_state.op_address =
					u16(read(cpu_state.bus, itrm_data & 0xFF00)) << 8 |
					u16(read(cpu_state.bus, itrm_data))
			} else {
				cpu_state.op_address =
					u16(read(cpu_state.bus, itrm_data + 1)) << 8 |
					u16(read(cpu_state.bus, itrm_data))
			}
			return 0
		}
	case .IndirectX:
		{
			cpu_state.opcode_bytes[1] = read(cpu_state.bus, cpu.pc)
			cpu.pc += 1

			lo := u16(read(cpu_state.bus, u16(cpu_state.opcode_bytes[1]) + u16(cpu.x)) & 0x00FF)
			hi := u16(
				read(cpu_state.bus, u16(cpu_state.opcode_bytes[1]) + u16(cpu.x) + 1) & 0x00FF,
			)

			cpu_state.op_address = (hi << 8) | lo
			return 0
		}
	case .IndirectY:
		{
			cpu_state.opcode_bytes[1] = read(cpu_state.bus, cpu.pc)
			cpu.pc += 1

			lo := u16(read(cpu_state.bus, u16(cpu_state.opcode_bytes[1])) & 0x00FF)
			hi := u16(read(cpu_state.bus, u16(cpu_state.opcode_bytes[1]) + 1) & 0x00FF)

			cpu_state.op_address = (hi << 8) | lo

			if u16(cpu_state.opcode_bytes[1]) & 0xFF00 != hi << 8 {
				return 1
			}
			return 0
		}
	case .Relative:
		{
			cpu_state.opcode_bytes[1] = read(cpu_state.bus, cpu.pc)
			cpu.pc += 1
			cpu_state.op_address = u16(cpu_state.opcode_bytes[1])

			if cpu_state.op_address & 0x80 != 0 {
				cpu_state.op_address |= 0xFF00
			}
			return 0
		}
	case .Accumilate, .Implied:
		{return 0}

	}
	return 0
}
