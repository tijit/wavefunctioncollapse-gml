draw_set_colour(c_white);
draw_set_font(fDebug);
var tw,th,tscale=2;

#region draw solution

var drawScale = min(room_width div w, room_height div h);

if (!surface_exists(surf)) {
	surf = wave.redrawSurface(surf);
}

draw_surface_ext(surf, 0, 0, drawScale, drawScale, 0, c_white, 1);

#endregion

#region if enabled, draw number of possibilities for each cell

if (drawPossibilityCount) {
	for (var i = 0; i < wave.size; i++) {
		var px = (i % wave.w) * drawScale;
		var py = (i div wave.w) * drawScale;
		
		var next = array_length(wave.candidates[i].possibleStates);
		if (next < min(100, possibilityCount) && !wave.candidates[i].set) { // && next != 1) {
			draw_text(px, py, $"{next}");
		}
	}
}

#endregion

#region draw input sprite

var sscale = min(sw * drawScale, room_width - w * drawScale, sw * 8) / sw;
sscale = floor(sscale);
// assumes top-left sprite origin
draw_sprite_ext(sprite, 0, room_width - sw * sscale, 0, sscale, sscale, 0, c_white, 1);

draw_set_halign(fa_right);
draw_set_valign(fa_top);

var patString = $"N={N}\npatterns: {possibilityCount}";
patString += $"\n{plist.periodic ? "" : "a"}periodic input\n{wave.periodic ? "" : "a"}periodic output";
patString += $"\nweight curve: {curveDescriptions[? curve]}";
tw = string_width(patString) + 8;
th = string_height(patString) + 8;
tw *= tscale; th *= tscale;
draw_sprite_ext(sprPixel, 0, room_width-tw, sh * sscale + 4, tw, th, 0, c_black, 0.75);
draw_text_transformed(room_width-4, sh * sscale + 8, patString, tscale, tscale, 0);

#endregion

#region tutorial text

draw_set_halign(fa_right);
draw_set_valign(fa_bottom);

tw = string_width(tutorialText) + 8;
th = string_height(tutorialText) + 8;
tw *= tscale; th *= tscale;
draw_sprite_ext(sprPixel, 0, room_width-tw, room_height-th, tw, th, 0, c_black, 0.75);
draw_text_transformed(room_width-4, room_height-4, tutorialText, tscale, tscale, 0);

#endregion

draw_set_halign(fa_left);
draw_set_valign(fa_top);
