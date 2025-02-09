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
	nes: Emulator = {}
	load_cartridge(&nes, "nestest.nes")
	init(&nes)
	reset(&nes)
	defer deinit(&nes)


	sdl_ctx := init_sdl()
	defer deinit_sdl(&sdl_ctx)

	init_open_gl(&sdl_ctx)

	init_imgui(&sdl_ctx)
	defer deinit_imgui(&sdl_ctx)

	io := im.GetIO()

	disassm := cpu.disassemble(&nes.cpu, 0x0000, 0xFFFF)
	shrink(&disassm)

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

		for !nes.ppu.frame_complete {
			clock(&nes)
		}
		nes.ppu.frame_complete = false
		update_texture(tex_id, nes.ppu.screen.w, nes.ppu.screen.h, nes.ppu.screen.pixels)

		imgui_new_frame()

		im.ShowDemoWindow()
		cpu_display(&nes.cpu, disassm, i32(cap(disassm)))
		im.Begin("OpenGL Texture Test")
		im.Text("Pointer: %X", tex_id)
		im.Text("Size: %d x %d", nes.ppu.screen.w, nes.ppu.screen.h)
		im.Image(im.TextureID(tex_id), {f32(nes.ppu.screen.w * 2), f32(nes.ppu.screen.h * 2)})
		im.End()
		imgui_flush_frame(sdl_ctx.window)

	}

}
