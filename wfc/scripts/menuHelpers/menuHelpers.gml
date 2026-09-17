function spawnMenuButtons(x0, y0, list, w=256, h=32, gap=2, menuDepth=0, xsgn=undefined, ysgn=undefined) {
	var nlist = array_length(list);
	var totalHeight = h * nlist + gap * (nlist-1);
	
	xsgn ??= (x0 < room_width/2) ? 1 : -1;
	//ysgn ??= (y0 + totalHeight < room_height) ? 1 : -1;
	ysgn = 1;
	
	if (y0 + totalHeight > room_height) {
		y0 += (room_height - (y0+totalHeight));
	}
	
	var xx = x0 + min(xsgn, 0) * w;
	var yy = y0 + min(ysgn, 0) * h;
	
	xx += xsgn * gap;
	//yy += ysgn * gap;
	
	for (var i = 0; i < nlist; i++) {
		var next = list[i];
		
		instance_create_layer(xx, yy, "Buttons", ContextButton, {
			text: next[$ "text"],
			xsgn,
			ysgn,
			onClick: next[$ "onClick"],
			childMenu: next[$ "childMenu"],
			width: w,
			height: h,
			menuDepth,
			butIndex: i,
		});
		yy += ysgn * (h + gap);
	}
}

function spawnRightClickMenu(N, periodicIn, periodicOut) {
	instance_destroy(ContextButton);
	
	var dat = [ ];
	var cm = [ ]; // child menu data
	
	// change N
	for (var i = 2; i <= 5; i++) {
		array_push(cm, {
			text: $"{i}",
			onClick: function() {
				var val = real(self[$ "text"]);
				with (Runner) {
					var ii = testIndex;
					
					tests[ii].N = val;
					testIndex = -1;
					beginTest(ii);
				}
			},
		});
	}
	array_push(dat, {
		text: $"N: {N} ->",
		childMenu: cm,
	});
	
	// toggle periodic input
	array_push(dat, {
		text: $"toggle periodic input",
		onClick: function() {
			with (Runner) {
				var ii = testIndex;
				tests[ii].periodicInput = !periodicInput;
				testIndex = -1;
				beginTest(ii);
			}
		},
	});
	
	// toggle periodic output
	
	array_push(dat, {
		text: $"toggle periodic output",
		onClick: function() {
			with (Runner) {
				var ii = testIndex;
				tests[ii].periodicOutput = !periodicOutput;
				testIndex = -1;
				beginTest(ii);
			}
		},
	});
	
	// set weight curve
	
	cm = [ ];
	var desc;
	with (Runner) {
		desc = curveDescriptions;
	}
	var funcs = [ __wfc_curve_linear, __wfc_curve_constant, __wfc_curve_logarithmic, __wfc_curve_sqrt ];
	//var keys = ds_map_keys_to_array(desc);
	for (var i = 0; i < array_length(funcs); i++) {
		var str = desc[? funcs[i]];
		if (funcs[i] != undefined) {
			array_push(cm, {
				text: $"{str}",
				butIndex: i,
				mkey: funcs[i],
				mdesc: str,
				onClick: function() {
					var val = self[$ "mkey"];
					with (Runner) {
						var ii = testIndex;
						tests[ii].curve = val;
						testIndex = -1;
						beginTest(ii);
					}
				},
			});
		}
	}
	
	array_push(dat, {
		text: "weight curve ->",
		childMenu: cm,
	});
	
	// set output dimensions
	
	cm = [ ];
	var sizes = [ 32, 48, 96, 160 ];
	for (var i = 0; i < array_length(sizes); i++) {
		var next = sizes[i];
		array_push(cm, {
			size: next,
			text: $"{next}x{next}",
			butIndex: i,
			onClick: function() {
				var val = self[$ "size"];
				with (Runner) {
					var ii = testIndex;
					w = val;
					h = val;
					testIndex = -1;
					beginTest(ii);
				}
			},
		});
	}
	
	array_push(dat, {
		text: "output size ->",
		childMenu: cm,
	});
	
	// symmetries
	
	var flags = [ 0, 1, 2, 3, 4, 7 ];
	var names = [ "none", "mirror X", "mirror Y", "mirror X+Y", "rotation", "all" ];
	
	cm = [ ];
	for (var i = 0; i < array_length(flags); i++) {
		array_push(cm, {
			flag: flags[i],
			text: names[i],
			onClick: function() {
				var val = self[$ "flag"];
				with (Runner) {
					var ii = testIndex;
					generateSymmetries = val;
					testIndex = -1;
					beginTest(ii);
				}
			},
		});
	}
	
	array_push(dat, {
		text: "symmetries ->",
		childMenu: cm,
	});
	
	spawnMenuButtons(mouse_x, mouse_y, dat);
}
