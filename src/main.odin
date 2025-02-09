package main

import im "../thirdparty/imgui"
import "../thirdparty/imgui/imgui_impl_opengl3"
import "../thirdparty/imgui/imgui_impl_sdl2"
import "core:fmt"
import "core:math/rand"
import "cpu"
import "ppu"
import gl "vendor:OpenGL"
import "vendor:sdl2"

main :: proc() {
	bus: cpu.NesBus = {}
	cpu.load_cartridge(&bus, "nestest.nes")

	nes_cpu := cpu.init_cpu(&bus)
	cpu.reset(&nes_cpu)

	sdl_ctx := init_sdl()
	defer deinit_sdl(&sdl_ctx)

	init_open_gl(&sdl_ctx)

	init_imgui(&sdl_ctx)
	defer deinit_imgui(&sdl_ctx)

	io := im.GetIO()

	disassm := cpu.disassemble(&nes_cpu, 0x0000, 0xFFFF)
	shrink(&disassm)

	draw_surface := sdl2.CreateRGBSurface(0, 256, 240, 24, 0, 0, 0, 0)
	defer sdl2.FreeSurface(draw_surface)
	cycles: i16 = 0
	scanlines: i16 = 0
	frame_complete := false
	pal := ppu.Palette

	tex_id: u32 = create_texture()

	done := false

	for !done {
		event: sdl2.Event
		for sdl2.PollEvent(&event) {
			imgui_impl_sdl2.ProcessEvent(&event)
			if event.type == sdl2.EventType.QUIT {
				done = true
			}
		}

		for !frame_complete {
			rect: sdl2.Rect = {i32(cycles - 1), i32(scanlines), 1, 1}
			sdl2.FillRect(
				draw_surface,
				&rect,
				ppu.color_to_u32(
					draw_surface.format,
					pal[0x30 if rand.uint32() % 2 == 0 else 0x3F],
				),
			)
			cycles += 1
			if cycles >= 341 {
				cycles = 0
				scanlines += 1
				if scanlines >= 261 {
					scanlines = -1
					frame_complete = true
					update_texture(tex_id, draw_surface.w, draw_surface.h, draw_surface.pixels)
				}
			}
		}

		frame_complete = false

		imgui_new_frame()

		im.ShowDemoWindow()
		cpu_display(&nes_cpu, disassm, i32(cap(disassm)))
		im.Begin("OpenGL Texture Test")
		im.Text("Pointer: %X", tex_id)
		im.Text("Size: %d x %d", draw_surface.w, draw_surface.h)
		im.Image(im.TextureID(tex_id), {f32(draw_surface.w * 2), f32(draw_surface.h * 2)})
		im.End()
		imgui_flush_frame(sdl_ctx.window)

	}

}
