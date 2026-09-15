/// @desc read a sprite asset and generate a PatternList
/// @param {asset.gmsprite} spriteIndex sprite to use as input, does not support transparency
/// @param {bool} [periodic] do pixels wrap around
/// @param {real} [N] NxN pattern size (usually 3x3) used to determine adjacency
/// @returns {struct.wfcPatternList} creates a pattern list which processes the NxN patterns
function wfcReadImage(spriteIndex, periodic=false, N=3) {
	static surf = undefined;
	static buff = buffer_create(128, buffer_grow, 1);
	static map = ds_map_create();
	static grid = ds_grid_create(16, 16);
	
	var stopwatch = get_timer();
	
	var w = sprite_get_width(spriteIndex);
	var h = sprite_get_height(spriteIndex);
	
	// draw sprite onto surface
	if (surface_exists(surf)) {
		surface_free(surf);
	}
	
	surface_depth_disable(true);
	surf = surface_create(w, h, surface_rgba8unorm);
	
	surface_set_target(surf);
	
	draw_clear(c_black);
	draw_sprite(spriteIndex, 0, 0, 0);
	
	surface_reset_target();
	
	// read pixels from surface buffer
	buffer_resize(buff, w * h * 4);
	
	buffer_get_surface(buff, surf, 0);
	
	buffer_seek(buff, buffer_seek_start, 0);
	
	ds_map_clear(map);
	
	var colours = [ ];
	
	ds_grid_resize(grid, w, h);
	ds_grid_clear(grid, -1);
	
	for (var j = 0; j < h; j++) {
		for (var i = 0; i < w; i++) {
			var cr = buffer_read(buff, buffer_u8);
			var cg = buffer_read(buff, buffer_u8);
			var cb = buffer_read(buff, buffer_u8);
			var ca = buffer_read(buff, buffer_u8);
			
			var col = make_color_rgb(cr, cg, cb);
			
			var ind = map[? col];
			if (ind == undefined) {
				ind = ds_map_size(map);
				map[? col] = ind;
				colours[ind] = col;
			}
			
			grid[# i, j] = ind;
		}
	}
	
	wfcPrintGrid(grid);
	
	// build list of NxN patterns
	
	var plist = new wfcPatternList(grid, colours, N, periodic);
	
	surface_free(surf); surf = undefined;
	
	//return wfcCollapse(plist, 64, 64);
	
	wfcPrint($"input image processing: {(get_timer() - stopwatch) / 1000} ms");
	
	return plist;
}

/// @desc Pattern List struct class.
/// Intended to be called from wfcReadImage()
/// @param {id.dsgrid} grid 
/// @param {array<constant.colour>} _colours 
/// @param {real} _N 
/// @param {bool} _periodic 
function wfcPatternList(grid, _colours, _N, _periodic) constructor {
	w = ds_grid_width(grid);
	h = ds_grid_height(grid);
	
	N = _N;
	colours = _colours;
	periodic = _periodic;
	
	/* pattern:
	{
		arr[] (pattern values)
		index
		north[]
		east[]
		south[]
		west[]
	}
	*/
	patterns = [ ];
	gridIndices = [ ];
	weights = [ ];
	
	stamps = [ ];
	precomputeStamps = false;
	
	repeat(w) array_push(gridIndices, [ ]);
	
	var NN = N * N;
	var w2 = periodic ? w : w-N+1;
	var h2 = periodic ? h : h-N+1;
	
	// build *unique* pattern list
	// give more commonly occurring patterns higher weight
	for (var i = 0; i < w2; i++) {
		for (var j = 0; j < h2; j++) {
			var next = [];
			for (var k = 0; k < NN; k++) {
				var xx = ((k%N)+i) % w;
				var yy = ((k div N)+j) % h;
				
				array_push(next, grid[# xx,yy]);
			}
			
			// if next is unique, add to list of patterns
			var ind = 0, match = false;
			for (ind = 0; ind < array_length(patterns); ind++) {
				var p2 = patterns[ind].arr;
				if (array_equals(next, p2)) {
					match = true;
					weights[ind]++;
					break;
				}
			}
			
			if (!match) {
				ind = array_length(patterns);
				array_push(patterns, {
					arr: next,
					index: ind,
					north: [],
					east: [],
					south: [],
					west: [],
				});
				weights[ind] = 1;
			}
			
			// assign pattern index to (i,j)
			gridIndices[i][j] = ind;
		}
	}
	wfcPrint($"pattern indices:");
	wfcPrintArray2(gridIndices);
	
	// example adjacency satisfy criteria (for N = 3: 3x3 patterns)
	// 0 1 2 3 4 5 == 3 4 5 6 7 8 (N0 == S1)
	// 0 3 6 1 4 7 == 1 4 7 2 5 8 (W0 == E1)
	
	// index i is positioned at (i % N, i div N)
	// position (x,y) correponds to index [ x + Ny ]
	
	npatterns = array_length(patterns);
	
	// there are "better" ways to do this loop
	// but this is simple and avoids duplicates without additional statements
	for (var i = 0; i < npatterns; i++) {
		var p0 = patterns[i];
		for (var j = 0; j < npatterns; j++) {
			var p1 = patterns[j];
			
			//var mn = true, me = true, ms = true, mw = true;
			var matchEast = true, matchSouth = true;
			
			// compare:
			// 		right-most 	(N-1)x(N) pixel of pattern p0, to
			// 		left-most	(N-1)x(N) pixel of pattern p1
			// 		if all equal p1 can be placed east of p0,
			// and
			// 		bottom 		(N)x(N-1) pixel of pattern p0, to
			// 		top 		(N)x(N-1) pixel of pattern p1
			// 		if all equal p1 can be placed south of p0
			
			for (var k = 0; k < NN; k++) {
				var px0 = k % N; var py0 = k div N;
				if (matchEast && px0 < N-1) {
					var px1 = px0+1;
					var k2 = px1 + N*py0;
					if (p0.arr[k2] != p1.arr[k]) {
						matchEast = false;
					}
				}
				if (matchSouth && py0 < N-1) {
					var py1 = py0+1;
					var k2 = px0 + N*py1;
					if (p0.arr[k2] != p1.arr[k]) {
						matchSouth = false;
					}
				}
			}
			
			if (matchSouth) {
				array_push(p0.south, p1.index);
				array_push(p1.north, p0.index);
			}
			if (matchEast) {
				array_push(p0.east, p1.index);
				array_push(p1.west, p0.index);
			}
		}
	}
	
	wfcPrint($"patterns: \n{string_replace_all(string(patterns), "\},\{", "\}\n\{")}");
	
	//static buildStamps = function(_radius=2) {
		//for (var i = 0; i < array_length(patterns); i++) {
			//stamps[i] = new wfcStamp(self, i, _radius);
		//}
	//};
	
	//if (precomputeStamps) {
		//buildStamps(max(w,h)+1);
	//}
	//buildStamps(max(w,h) div 2 + 1);
	//buildStamps(3);
}


// UNUSED
// pre-computing stamps for complex patterns is far too expensive,
// and generates more information than u need
/// @deprecated 
function wfcStamp(_patternList, _patInd, _radius=2) constructor {
	patternList = _patternList;
	patInd = _patInd;
	radius = _radius;
	
	w = 1 + 2 * _radius;
	h = 1 + 2 * _radius;
	size = w * h;
	
	static dirStrings = [ "north", "east", "south", "west" ];
	
	x = radius; y = radius;
	midInd = x + y * w;
	
	mat = [];
	
	repeat(size) array_push(mat, []);
	
	mat[midInd] = [ patInd ];
	
	static getNeighbour = function(ind, dir) {
		var nind = ind;
		var dirstr = dirStrings[dir];
		if (dir == 0 || dir == 2) {
			nind += w * sign(dir-1);
		}
		else if (dir == 1 || dir == 3) {
			nind += sign(2-dir);
		}
		
		if (nind < 0 || nind >= size) return undefined;
		
		var adjacent = [];
		if (mat[ind] != undefined) {
			for (var i = 0; i < array_length(mat[ind]); i++) {
				var next = patternList.patterns[ mat[ind][i] ];
				adjacent = array_union(adjacent, next[$ dirstr]);
			}
		}
		else {
			return undefined;
		}
		
		return {
			nind, adjacent,
		};
	};
	
	// use array_union to join possibility states
	var disco = array_create(size, 0);
	
	var q = [ midInd ];
	disco[ midInd ] = 2;
	while (array_length(q) > 0) {
		var next = array_shift(q);
		disco[ next ] = 2;
		
		if (mat[next] != undefined) {
			for (var i = 0; i < 4; i++) {
				var neigh = getNeighbour(next, i);
				if (neigh != undefined) {
					// if this neighbour hasnt been processed yet
					var nind = neigh.nind;
					if (disco[nind] < 2) {
						// add to queue on first discovery
						if (disco[nind] == 0) {
							disco[nind] = 1;
							array_push(q, nind);
						}
						//if (is_array(mat[neigh.nind])) {
						if (mat[nind] != undefined) {
							// array is new fresh one
							if (array_length(mat[nind]) == 0) {
								mat[nind] = neigh.adjacent;
							}
							// array is interesection(??) of other neighbours
							else {
								var len0 = array_length(mat[nind]);
								mat[nind] = array_intersection(mat[nind], neigh.adjacent);
								//mat[nind] = array_union(mat[nind], neigh.adjacent);
								//if (len0 != array_length(mat[nind])) {
									//wfcPrint($"corner intersect made a change! {len0} -> {array_length(mat[nind])}");
								//}
							}
							
							//if (array_contains(mat[nind], patInd)) {
								//mat[nind] = undefined;
							//}
							// make a null value if is full pattern list
							//if (array_length(mat[nind]) >= array_length(patternList.patterns)) {
								//wfcPrint($"stamp {patInd} {next} is full");
								//mat[nind] = undefined;
							//}
						}
					}
				}
				else {
					
				}
			}
		}
		
	}
	
	for (var i = 0; i < size; i++) {
		if (mat[i] != undefined && array_length(mat[i]) == 0) {
			mat[i] = undefined;
		}
	}
	
	wfcPrint($"mat {patInd}:");
	wfcPrintArray2(mat);
}

