package main

import im "../thirdparty/imgui"
import "../thirdparty/imgui/imgui_impl_opengl3"
import "../thirdparty/imgui/imgui_impl_sdl2"
import "controller"
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

	controller_one_status: controller.Buttons


	sdl_ctx := init_sdl()
	defer deinit_sdl(&sdl_ctx)

	init_open_gl(&sdl_ctx)

	init_imgui(&sdl_ctx)
	defer deinit_imgui(&sdl_ctx)

	io := im.GetIO()

	disassm := cpu.disassemble(&nes.cpu, 0x0000, 0xFFFF)
	shrink(&disassm)

	tex_id: u32 = create_texture()
	pat_tex1: u32 = create_texture()
	pat_tex2: u32 = create_texture()
	pal_tex: u32 = create_texture()

	selected_pal: u8 = 0

	pal_surface := sdl2.CreateRGBSurface(0, 128, 128, 24, 0, 0, 0, 0)
	defer sdl2.FreeSurface(pal_surface)

	done := false

	for !done {
		event: sdl2.Event
		for sdl2.PollEvent(&event) {
			imgui_impl_sdl2.ProcessEvent(&event)
			if event.type == sdl2.EventType.QUIT {
				done = true
			}
			if event.type == sdl2.EventType.KEYDOWN {
				if event.key.keysym.sym == sdl2.Keycode.p {
					selected_pal += 1
					selected_pal &= 0x07
				}
			}
			if event.type == sdl2.EventType.KEYDOWN {
				if event.key.keysym.sym == sdl2.Keycode.DOWN {
					controller_one_status.down = 1
				}
			}
		}
		set_controller_one_status(&nes, controller_one_status)

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

		draw_pattern_images_and_palette(
			&nes.ppu,
			selected_pal,
			{pat_tex1, pat_tex2},
			pal_surface,
			pal_tex,
		)

		imgui_flush_frame(sdl_ctx.window)

	}

}
