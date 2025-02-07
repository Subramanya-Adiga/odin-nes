package main

import im "../thirdparty/imgui"
import "../thirdparty/imgui/imgui_impl_opengl3"
import "../thirdparty/imgui/imgui_impl_sdl2"
import "core:math"
import "cpu"

COLOR_RED :: im.Vec4{0.880, 0.0176, 0.0176, 255.0}
COLOR_GREEN :: im.Vec4{0.0195, 0.650, 0.0826, 255.0}

cpu_display :: proc(dis_cpu: ^cpu.NesCpu, info: [dynamic]cpu.Dissassembly, length: i32) {
	im.Begin("Cpu", nil)

	im.Text("Status Flags: ")
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.Negative) != 0 else COLOR_RED,
		"N",
	)
	im.SameLine()
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.Overflow) != 0 else COLOR_RED,
		"V",
	)
	im.SameLine()
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.Unused) != 0 else COLOR_RED,
		"-",
	)
	im.SameLine()
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.Break) != 0 else COLOR_RED,
		"B",
	)
	im.SameLine()
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.Decimal) != 0 else COLOR_RED,
		"D",
	)
	im.SameLine()
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.IntruptDisable) != 0 else COLOR_RED,
		"I",
	)
	im.SameLine()
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.Zero) != 0 else COLOR_RED,
		"Z",
	)
	im.SameLine()
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.Carry) != 0 else COLOR_RED,
		"C",
	)

	im.Spacing()
	im.Text("PC: %X", dis_cpu.pc)
	im.Text("A: $%X [%d]", dis_cpu.a, dis_cpu.a)
	im.Text("X: $%X [%d]", dis_cpu.x, dis_cpu.x)
	im.Text("Y: $%X [%d]", dis_cpu.y, dis_cpu.y)
	im.Text("Stack Pointer: $%X", dis_cpu.stack_p)

	im.Spacing()
	if im.BeginListBox(
		"##Disassembly",
		im.Vec2{-math.F32_MIN, 24 * im.GetTextLineHeightWithSpacing()},
	) {
		for i in 0 ..< length {
			selected: bool = (info[i].pc == u32(dis_cpu.pc))
			flags: im.SelectableFlags = {.Highlight} if selected else {.NoAutoClosePopups}
			if info[i].instruction != nil {
				if im.Selectable(info[i].instruction, selected, flags) {
				}
			}
			if selected {
				im.SetItemDefaultFocus()
			}
		}
		im.EndListBox()
	}
	im.End()
}
