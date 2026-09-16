function loadExternalImage() {
	fname = get_open_filename("Image|*.png", "");
	
	var spr = undefined;
	
	try {
		spr = sprite_add(fname, 0, false, false, 0, 0);
	}
	catch (e) {
	}
	
	if (spr != undefined && sprite_exists(spr)) {
		if (global.__file_custom != undefined && sprite_exists(global.__file_custom)) {
			sprite_delete(global.__file_custom);
		}
		global.__file_custom = spr;
		return true;
	}
	
	return false;
}
