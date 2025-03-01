package main

import im "../vendor/imgui"
import "../vendor/imgui/imgui_impl_opengl3"
import "../vendor/imgui/imgui_impl_sdl2"
import "core:math"
import "cpu"
import "ppu"
import sdl "vendor:sdl2"

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
	palette_surface: ^sdl.Surface,
	palette_tex_id: u32,
) {
	im.Begin("Pattern Data")

	pat_surf1 := ppu.get_pattern_table(running_ppu, 0, palette_id)
	pat_surf2 := ppu.get_pattern_table(running_ppu, 1, palette_id)

	update_textureRGB(texture_id[0], pat_surf1)
	update_textureRGB(texture_id[1], pat_surf2)

	im.Image(im.TextureID(texture_id[0]), {f32(256), f32(256)})
	im.Image(im.TextureID(texture_id[1]), {f32(256), f32(256)})

	pal_width := 58
	pal_height := 22
	padding := 8
	offset := 12

	sdl.FillRect(palette_surface, nil, 0x000000)

	selection_rect: sdl.Rect = {
		i32(offset - 2),
		i32(offset - 2) + (i32(pal_height + padding) * i32(palette_id)),
		i32(pal_width * 4) + 4,
		i32(pal_height + 4),
	}
	sdl.FillRect(palette_surface, &selection_rect, 0xffffff)

	for pal in 0 ..< 8 {
		for col in 0 ..< 4 {
			rect: sdl.Rect = {
				i32(offset) + (i32(col) * i32(pal_width)),
				i32(offset) + (i32(pal) * (i32(pal_height) + i32(padding))),
				i32(pal_width),
				i32(pal_height),
			}
			sdl.FillRect(
				palette_surface,
				&rect,
				ppu.color_to_u32(
					palette_surface.format,
					ppu.get_color_from_palette(running_ppu, u8(pal), u8(col)),
				),
			)
		}
	}

	update_textureRGB(palette_tex_id, palette_surface)
	im.Image(im.TextureID(palette_tex_id), {f32(256), f32(256)})
	im.End()
}
