var h = hover;
hover = (instance_position(mouse_x, mouse_y, id) == id);
if (hover && !h) {
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
}
