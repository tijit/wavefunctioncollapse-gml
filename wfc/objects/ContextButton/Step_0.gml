if (onClick != undefined) {
	if (hover && mouse_check_button_pressed(mb_left)) {
		onClick();
		
		instance_destroy(ContextButton);
		exit;
	}
}

if (childMenu != undefined && !childrenActive && hover) {
	var destroylist = [];
	with (ContextButton) {
		childrenActive = false;
		if (menuDepth > other.menuDepth) {
			array_push(destroylist, id);
		}
	}
	array_foreach(destroylist, function(e, i) {
		instance_destroy(e);
	});
	
	childrenActive = true;
	spawnMenuButtons(x + max(xsgn, 0) * width, y, childMenu, width, height, , menuDepth+1, xsgn, );
}
