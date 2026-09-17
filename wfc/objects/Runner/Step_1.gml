if (!instance_exists(ContextButton)) {
	if (mouse_check_button_pressed(mb_left) || mouse_check_button_pressed(mb_right)) {
		spawnRightClickMenu(N, plist.periodic, wave.periodic);
		io_clear();
		exit;
	}
}
