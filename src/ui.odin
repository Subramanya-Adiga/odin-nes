package main

import im "../thirdparty/imgui"
import "../thirdparty/imgui/imgui_impl_opengl3"
import "../thirdparty/imgui/imgui_impl_sdl2"
import "core:math"
import "cpu"
import "ppu"
import "vendor:sdl2"

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

draw_pattern_images_and_palette :: proc(
	running_ppu: ^ppu.PPU,
	palette_id: u8,
	texture_id: [2]u32,
	palette_surface: ^sdl2.Surface,
	palette_tex_id: u32,
) {
	im.Begin("Pattern Data")

	pat_surf1 := ppu.get_pattern_table(running_ppu, 0, palette_id)
	pat_surf2 := ppu.get_pattern_table(running_ppu, 1, palette_id)

	update_texture(texture_id[0], pat_surf1.w, pat_surf1.h, pat_surf1.pixels)
	update_texture(texture_id[1], pat_surf2.w, pat_surf2.h, pat_surf2.pixels)

	im.Image(im.TextureID(texture_id[0]), {f32(256), f32(256)})
	im.Image(im.TextureID(texture_id[1]), {f32(256), f32(256)})


	for pal in 0 ..< 4 {
		for selection in 0 ..< 4 {
			rect: sdl2.Rect = {8 + i32(selection * 28), 2 + i32(pal * 32), 28, 28}
			sdl2.FillRect(
				palette_surface,
				&rect,
				ppu.color_to_u32(
					palette_surface.format,
					ppu.get_color_from_palette(running_ppu, u8(pal), u8(selection)),
				),
			)
		}
	}

	update_texture(palette_tex_id, 128, 128, palette_surface.pixels)
	im.Image(im.TextureID(palette_tex_id), {f32(128), f32(128)})
	im.SameLine()
	im.Image(im.TextureID(palette_tex_id), {f32(128), f32(128)})

	im.End()
}
