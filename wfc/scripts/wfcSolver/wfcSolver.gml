/// @desc create wave, call propagate() until it returns zero
/// @param {struct.wfcPatternList} _patternList result from wfcReadImage()
/// @param {real} _w width (pixels) canvas size
/// @param {real} _h height (pixels)
/// @param {bool} [_periodic] does it wrap around
function wfcWave(_patternList, _w, _h, _periodic=false) constructor {
	patternList = _patternList;
	w = _w;
	h = _h;
	periodic = _periodic;
	
	size = w * h;
	
	pixels = array_create(size, -1);
	
	time = 0;
	discardedStates = 0;
	
	finished = false;
	failed = false;
	stopwatch = get_timer();
	
	N = patternList.N;
	
	weightCurve = undefined;
	
	static dirStrings = [ "north", "east", "south", "west" ];
	
	static setPixel = function(_ind, _val) {
		pixels[ _ind ] = _val;
	};
	static setPixelXY = function(_x, _y, _val) {
		pixels[ _x + w * _y ] = _val;
		//setPixel(_x + w * _y, _val);
	};
	
	pw = patternList.w;
	ph = patternList.h;
	
	candidates = [ ]; // list of possibilities for each pixel
	q = [ ]; // "queue" on unset candidates
	collisions = [ ]; // list of contention edges
	
	allPossibleStates = array_create_ext(patternList.npatterns, function(i) {
		return i;
	});
	
	var px,py;
	
	static newCandidate = function(ind) {
		return {
			ind,
			x: ind % w,
			y: ind div w,
			possibleStates: wfcArrayAppend( , allPossibleStates),
			set: false,
			state: -1,
			timestamp: -1, // this can be helpful in heuristics for correcting errors
			refetch: false, // rebuild possibilities from neighbours (UNUSED)
		};
	};
	
	static resetCandidate = function(ind) {
		var c = newCandidate(ind);
		
		candidates[ind] = c;
		setPixel(ind, -1);
		
		return c;
	};
	
	static setCandidate = function(ind, patIndex) {
		candidates[ind].set = true;
		candidates[ind].state = patIndex;
		candidates[ind].timestamp = time;
		
		var patarr = patternList.patterns[patIndex].arr;
		setPixel(ind, patarr[0]);
	};
	
	// static verifyCandidate = function(ind) {}
	
	// build initial candidate list and //populate queue
	for (var i = 0; i < size; i++) {
		px = i % w;
		py = i div w;
		
		var c = resetCandidate(i);
	}
	
	// random starting point
	px = irandom_range(0, w-1)
	py = irandom_range(0, h-1);
	
	// start at random corner
	//px = choose(1, w-2);
	//py = choose(1, h-2);
	
	q = [ px + w * py ];
	
	/// iterate one step
	/// @return real 1 if still going, 0 if complete, 2 if failed
	static propagate = function() {
		if (array_length(q) == 0) {
			if (!finished) {
				finished = true;
				
				wfcPrint($"--\ncomplete! ({failed ? "failed" : "succesful"})");
				wfcPrint($"iterations: {time} / {w * h}, {100 * discardedStates / time}% discarded states");
				wfcPrint($"time taken: {(get_timer() - stopwatch) / 1000} ms");
			}
			return 0;
		}
		
		time++;
		
		var n, next;
		var nextind = -1;
		
		// find next candidate to process, with a bit of randomness
		var low = 99999;
		for (var i = 0; i < array_length(q); i++) {
			var qi = q[i];
			n = array_length(candidates[ qi ].possibleStates) + random(0.99);
			if (n < low) {
				low = n;
				next = candidates[ qi ];
				nextind = i;
			}
		}
		
		var ind = next.ind;
		var px = next.x;
		var py = next.y;
		
		n = array_length(next.possibleStates);
		if (n > 0) {// || next.refetch) {
			var pat, patIndex, valid;
			if (n == 1) {
				// there is only one possibility, simply set it
				// as no information will be gained from filtering possibilities of nearby cells
				patIndex = 0;
				pat = next.possibleStates[patIndex];
				valid = true;
				// UNLESS doing so would cause a conflict
				for (var i = 0; i < 4; i++) {
					var neigh = getNeighbour(ind, i);
					if (neigh != undefined && !array_contains(neigh.oppositePossibilities, pat)) {
						valid = false;
						break;
					}
				}
			}
			else {
				// try to "stamp" this cell and check for conflicts
				// tryStamp() automatically updates possible states if it succeeds
				patIndex = wfcCurvedWeightedChoose(patternList.weights, next.possibleStates, weightCurve);
				pat = next.possibleStates[ patIndex ];
				valid = tryStamp(ind, pat);
			}
			
			if (!valid) {
				// remove this state from potential pixels
				array_delete(next.possibleStates, patIndex, 1);
				discardedStates++;
			}
			else {
				// set candidate and remove from queue
				setCandidate(ind, pat);
				array_delete(q, nextind, 1);
				
				// add 4 neighbours to queue
				for (var i = 0; i < 4; i++) {
					var neigh = getNeighbour(ind, i);
					if (neigh != undefined) {
						if (!neigh.nc.set && !array_contains(q, neigh.nind)) {
							array_push(q, neigh.nind);
						}
					}
				}
			}
			
			return 1;
		}
		else {
			if (!failed) {
				failed = true;
			}
			array_resize(q, 0);
			return 2;
			
			// if you wanted to run an algorithm to try to correct
			// contention edges, here is where it would go
		}
		
		
		
		//if (array_length(q) > 0) return 1; // more pixels to propagate
		//if (array_length(collisions) > 0) return 2; // wave has collapsed but there are inconsistencies
		//return 0; // successfully completed
	};
	
	static tryStamp = function(ind, pat) {
		var px = ind % w;
		var py = ind div w;
		
		var stampedPossibilities = array_create(size, undefined);
		stampedPossibilities[ind] = [ pat ];
		
		// get initial 4 neighbours with the possibilities of the pattern given in the input
		var stampQueue = [ ];
		for (var i = 0; i < 4; i++) {
			var neigh = getNeighbour(ind, i, pat);
			
			if (neigh != undefined) {
				stampedPossibilities[neigh.nind] = neigh.adjacentPossibilities;
				array_push(stampQueue, neigh.nind);
			}
		}
		
		// discovery array
		// 0: undiscovered (okay to add to queue)
		// 1: discovered
		// 2: processed
		var disco = array_create(size, 0);
		disco[ind] = 2;
		
		// breadth-first search neighbours
		while (array_length(stampQueue) > 0) {
			var next = array_shift(stampQueue);
			disco[next] = 2;
			
			// finish processing the next cell in the queue
			
			// neighbour possibilities is full array
			if (stampedPossibilities[next] == undefined) { // || candidates[next].set) {
				continue;
			}
			
			// trim states to possibilities of current cell
			// as we search breadth first, this should only happen after closer cells
			// intersection deletes duplicates thus prevents exponential growth
			// TODO: GM manual says array_intersection order not guaranteed?
				// if possibleStates is the first element, it *seems* to be correct
				// for the sake of array_equals()
			stampedPossibilities[next] = array_intersection(candidates[next].possibleStates, stampedPossibilities[next]);
			// invalid configuration
			if (array_length(stampedPossibilities[next]) == 0) {
				return false;
			}
			
			// no need to process neighbours at this position
			// this statement resulted in about a 20x speedup
			if (array_equals(stampedPossibilities[next], candidates[next].possibleStates)) {
				continue;
			}
			
			// how far away are we from the starting point
			// this is the old metric i was using, much slower
			//var r = abs(next - ind);
			//r = r % w + r div w;
			//if (r > _maxRadius) {
				//continue;
			//}
			
			// hello chat welcome to my sudoku solver
			for (var i = 0; i < 4; i++) {
				var neigh = getNeighbour(next, i);
				if (neigh != undefined) {
					var nind = neigh.nind;
					var dir = dirStrings[i];
					if (disco[nind] < 2) {
						// add unvisited neighbours to queue
						if (disco[nind] < 1) {
							disco[nind] = 1;
							array_push(stampQueue, nind);
						}
						
						var union = [ ];
						
						// determine their possible states
						for (var j = 0; j < array_length(stampedPossibilities[next]); j++) {
							var p = stampedPossibilities[next][j];
							var pdir = patternList.patterns[p][$ dir];
							wfcArrayAppend(union, pdir);
						}
						
						// best case calling this here is about 2x slower
						// for a small accuracy gain
						// it is much faster to simply regenerate a wave from scratch on failure,
						// unless it is sufficiently large
						//union = array_unique(union);
						
						if (array_length(union) < patternList.npatterns) { // large speedup, "small" accuracy loss
							if (stampedPossibilities[nind] == undefined) {
								stampedPossibilities[nind] = union;
								//stampedPossibilities[nind] = array_unique(union);
							}
							else {
								stampedPossibilities[nind] = array_intersection(stampedPossibilities[nind], union);
							}
						}
					}
				}
			}
		}
		
		// the stamp succeeded, overwrite possibilities
		for (var i = 0; i < size; i++) {
			if (stampedPossibilities[i] != undefined) {
				candidates[i].possibleStates = stampedPossibilities[i];
			}
		}
		
		return true;
	};
	
	/// 0: NORTH, 1: EAST, 2: SOUTH, 3: WEST
	/// cpat: pretend candidate[ind] has a certain pattern (for getting adjacent possibilities)
	static getNeighbour = function(ind, dir, cpat=undefined) {
		var px = ind % w;
		var py = ind div w;
		var nind = ind;
		var adjacentPossibilities, oppositePossibilities, sgn;
		if (dir == 0 || dir == 2) {
			sgn = sign(dir-1);
			nind += w * sgn;
			py += sgn;
		}
		else if (dir == 1 || dir == 3) {
			sgn = sign(2-dir);
			nind += sgn;
			px += sgn;
		}
		else {
			return undefined;
		}
		
		// wrap around or return undefined if out of bounds
		if (px < 0 || py < 0 || px >= w || py >= h) {
			if (periodic) {
				px = wfcMod(px, w);
				py = wfcMod(py, h);
				nind = px + w * py;
			}
			else {
				return undefined;
			}
		}
		
		var c = candidates[ind];
		var nc = candidates[nind];
		
		cpat ??= c.state;
		
		if (cpat > -1) {
			adjacentPossibilities = patternList.patterns[cpat][$ dirStrings[dir]];
		}
		else {
			adjacentPossibilities = allPossibleStates;
		}
		
		if (nc.set) {
			oppositePossibilities = patternList.patterns[nc.state][$ dirStrings[(dir + 2) % 4]];
		}
		else {
			oppositePossibilities = allPossibleStates;
		}
		
		return {
			nc, nind,
			adjacentPossibilities, oppositePossibilities,
		};
	};
	
	/// is candidate left/above (0,0) or right/below (w-1,h-1) inclusive
	static candidateIsEdge = function(ind) {
		var px = ind % w;
		var py = ind div w;
		return (px <= 0 || px >= w-1 || py <= 0 || py >= h-1);
	};
	
	/// call before drawing, pass in surface or undefined
	/// @return {id.surface} surf or new surface if surf does not exist
	static redrawSurface = function(surf) {
		if (!surface_exists(surf)) {
			surf = surface_create(w, h);
		}
		else if (surface_get_width(surf) != w || surface_get_height(surf) != h) {
			surface_free(surf);
			surf = surface_create(w, h);
		}
		surface_set_target(surf);
		
		draw_clear_alpha(#000000, 0);
		
		for (var i = 0; i < size; i++) {
			if (pixels[i] > -1) {
				// draw_point is different for GMRT and GMS2 VM
				//draw_point_colour(1 + i % w, 1 + i div w, patternList.colours[pixels[i]]);
				draw_sprite_ext(sprPixel, 0, i % w, i div w, 1, 1, 0, patternList.colours[pixels[i]], 1);
			}
		}
		
		surface_reset_target();
		
		return surf;
	};
	
	static getSolutionArray2D = function(result = []) {
		repeat (h) {
			array_push(result, []);
		}
		for (var i = 0; i < size; i++) {
			result[i % w][i div w] = pixels[i];
		}
		return result;
	};
	
	/// @return {array<constant.colour>} copy of the list of colours that correpond to each index
	static getColours = function() {
		return wfcArrayAppend( , patternList.colours);
	};
}

// based on YAL weighted choose
function wfcWeightedChoose(weights, indices) {
	var n = 0;
	var nindices = array_length(indices);
	for (var i = 0; i < nindices; i++) {
		n += weights[ indices[i] ];
	}
	n = random(n);
	for (var i = 0; i < nindices; i++) {
		var next = weights[ indices[i] ];
		n -= next;
		if (n < 0) return i;
	}
	return 0;
}

/// @desc experimental func to choose weights non-linearly
/// @param {array} weights weights array
/// @param {array} indices indices of array to pick from
/// @param {function} [curveFunc] default = func(n) {return n;} // linear
/// @returns {real} chosen index
function wfcCurvedWeightedChoose(weights, indices, curveFunc=undefined) {
	curveFunc ??= __wfc_curve_linear;
	
	var n = 0;
	var nindices = array_length(indices);
	for (var i = 0; i < nindices; i++) {
		n += curveFunc( weights[ indices[i] ] );
	}
	n = random(n);
	for (var i = 0; i < nindices; i++) {
		var next = curveFunc( weights[ indices[i] ] );
		n -= next;
		if (n < 0) return i;
	}
	return 0;
}

/// default weight selection
function __wfc_curve_linear(n) {
	return n;
}

/// choose candidates entirely at random,
/// instead of how often it appears in the source image
function __wfc_curve_constant(n) {
	return 1;
}

function __wfc_curve_logarithmic(n) {
	return log2(n);
}

function __wfc_curve_sqrt(n) {
	return sqrt(n);
}

/// @desc  copy b onto the end of a, returns a
/// @param {array} [a]=[] dest
/// @param {array} b src
/// @return {array} array a
function wfcArrayAppend(a=[], b) {
	gml_pragma("forceinline");
	array_copy(a, array_length(a), b, 0, array_length(b));
	return a;
}

/// @desc modulo that returns correct value for negative numbers
/// @param {real} a numerator
/// @param {real} b demoman
function wfcMod(a,b) {
	return (b+a%b)%b;
}
