if (overlayOpen) {
	var root = layer_get_flexpanel_node("UILayer_1");
	root = flexpanel_node_get_child(root, 0);
	var butN = flexpanel_node_get_child(root, "butN");
	var butPeriodicIn = flexpanel_node_get_child(root, "butPeriodicIn");
	var butPeriodicOut = flexpanel_node_get_child(root, "butPeriodicOut");
	
	var buttons = [ butN, butPeriodicIn, butPeriodicOut ];
	
	for (var i = 0; i < array_length(buttons); i++) {
		var but = flexpanel_node_get_struct(buttons[i]);
		var alpha = 0.5;
		if (nodeHover(but)) {
			alpha = 1;
			
		}
		draw_sprite_ext(sprPixel, 0, but.left, but.top, but.right-but.left, but.bottom-but.top, 0, c_white, alpha);
	}
}
