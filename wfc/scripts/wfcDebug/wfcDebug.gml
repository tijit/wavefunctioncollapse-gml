#macro WFC_DEBUG_OUTPUT (true)

/// @desc print a string to output if WFC_DEBUG_OUTPUT is true
/// @param {string} str its a string
function wfcPrint(str) {
	if (WFC_DEBUG_OUTPUT) {
		show_debug_message(str);
	}
}

// print 2D array
function wfcPrintArray2(arr) {
	if (WFC_DEBUG_OUTPUT) {
		var str = string(arr);
		// TODO: format numbers to line up
		str = string_replace_all(str, "[ [ ", "[ ");
		str = string_replace_all(str, " ] ]", " ]");
		str = string_replace_all(str, " ],", " ]\n");
		str = string_replace_all(str, "undefined,", "undefined,\n");
		
		wfcPrint(str);
	}
}

// print ds_grid
function wfcPrintGrid(g) {
	if (WFC_DEBUG_OUTPUT) {
		var w = ds_grid_width(g);
		var h = ds_grid_height(g);
		
		var str = "";
		for (var i = 0; i < w; i++) {
			for (var j = 0; j < h; j++) {
				str += $"{g[# i,j]} ";
			}
			str += "\n";
		}
		
		wfcPrint(str);
	}
}
