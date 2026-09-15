var drawScale = min(room_width div w, room_height div h);

if (!surface_exists(surf)) {
	surf = wave.redrawSurface(surf);
}

draw_surface_ext(surf, 0, 0, drawScale, drawScale, 0, c_white, 1);
