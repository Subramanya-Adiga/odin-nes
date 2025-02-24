package main

import im "../vendor/imgui"
import "../vendor/imgui/imgui_impl_opengl3"
import "../vendor/imgui/imgui_impl_sdl2"
import "controller"
import "core:fmt"
import "core:math/rand"
import "cpu"
import "ppu"
import gl "vendor:OpenGL"
import sdl "vendor:sdl2"

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

	pal_surface := sdl.CreateRGBSurface(0, 128, 128, 24, 0, 0, 0, 0)
	defer sdl.FreeSurface(pal_surface)

	done := false

	for !done {
		event: sdl.Event
		for sdl.PollEvent(&event) {
			imgui_impl_sdl2.ProcessEvent(&event)
			#partial switch (event.type) {
			case sdl.EventType.QUIT:
				{
					done = true
				}
			case sdl.EventType.KEYDOWN, sdl.EventType.KEYUP:
				{
					if event.key.keysym.scancode == sdl.Scancode.P {
						if event.key.state == sdl.PRESSED {
							selected_pal += 1
							selected_pal &= 0x07
						}
					}
					if event.key.keysym.scancode == sdl.Scancode.R {
						if event.key.state == sdl.PRESSED {
							reset(&nes)
						}
					}
					if event.key.keysym.scancode == sdl.Scancode.S {
						controller_one_status.start = event.key.state
					}
					if event.key.keysym.scancode == sdl.Scancode.E {
						controller_one_status.select = event.key.state
					}
					if event.key.keysym.scancode == sdl.Scancode.Z {
						controller_one_status.a = event.key.state
					}
					if event.key.keysym.scancode == sdl.Scancode.X {
						controller_one_status.b = event.key.state
					}
					if event.key.keysym.scancode == sdl.Scancode.LEFT {
						controller_one_status.left = event.key.state
					}
					if event.key.keysym.scancode == sdl.Scancode.RIGHT {
						controller_one_status.right = event.key.state
					}
					if event.key.keysym.scancode == sdl.Scancode.UP {
						controller_one_status.up = event.key.state
					}
					if event.key.keysym.scancode == sdl.Scancode.DOWN {
						controller_one_status.down = event.key.state
					}
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
