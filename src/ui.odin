package main

import im "../thirdparty/imgui"
import "../thirdparty/imgui/imgui_impl_opengl3"
import "../thirdparty/imgui/imgui_impl_sdl2"
import "core:math"
import "cpu"

COLOR_RED :: im.Vec4{0.880, 0.0176, 0.0176, 255.0}
COLOR_GREEN :: im.Vec4{0.0195, 0.650, 0.0826, 255.0}

cpu_display :: proc(dis_cpu: ^cpu.NesCpu, info: [dynamic]cstring, length: i32) {
	im.Begin("Cpu", nil)

	im.Text("Status Flags: ")
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.Negative) != 0 else COLOR_RED,
		"N",
	)
	im.SameLine()
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.Negative) != 0 else COLOR_RED,
		"V",
	)
	im.SameLine()
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.Negative) != 0 else COLOR_RED,
		"-",
	)
	im.SameLine()
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.Negative) != 0 else COLOR_RED,
		"B",
	)
	im.SameLine()
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.Negative) != 0 else COLOR_RED,
		"D",
	)
	im.SameLine()
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.Negative) != 0 else COLOR_RED,
		"I",
	)
	im.SameLine()
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.Negative) != 0 else COLOR_RED,
		"Z",
	)
	im.SameLine()
	im.TextColored(
		COLOR_GREEN if dis_cpu.status & u8(cpu.NesCpuFlags.Negative) != 0 else COLOR_RED,
		"C",
	)

	im.Spacing()
	im.Text("PC: %x", dis_cpu.pc)
	im.Text("A: $%x [%d]", dis_cpu.a)
	im.Text("X: $%x [%d]", dis_cpu.x)
	im.Text("Y: $%x [%d]", dis_cpu.y)
	im.Text("Stack Pointer: $%x", dis_cpu.stack_p)

	pc_tmp: i32 = 0
	im.Spacing()
	if im.BeginListBox(
		"##Disassembly",
		im.Vec2{-math.F32_MIN, 24 * im.GetTextLineHeightWithSpacing()},
	) {
		for i in 0 ..< length {
			if info[i] != nil {
				selected: bool = (pc_tmp == i)
				flags: im.SelectableFlags
				if pc_tmp == i {flags = {.Highlight}} else {flags = {.NoAutoClosePopups}}

				if im.Selectable(info[i], selected, flags) {
					pc_tmp = i
				}
				if selected {
					im.SetItemDefaultFocus()
				}
			}
		}
		im.EndListBox()
	}
	im.End()
}
