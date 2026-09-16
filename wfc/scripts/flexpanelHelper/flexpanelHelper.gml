// is mouse over
function nodeHover(node) {
	return point_in_rectangle(display_mouse_get_x(), display_mouse_get_y(), node.left, node.top, node.right, node.bottom);
}
