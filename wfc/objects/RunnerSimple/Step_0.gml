if (keyboard_check_pressed(ord("R"))) {
	wave = new wfcWave(plist, w, h);
	exit;
}

if (!wave.finished) {
	repeat(100) {
		if (wave.propagate() != 1) {
			break;
		}
	}
	surf = wave.redrawSurface(surf);
}
