draw_set_font(fButton);

var col = hover ? #aaaaaa : #555555;

draw_sprite_ext(sprPixel, 0, x, y, image_xscale, image_yscale, 0, col, 1);

draw_set_colour(c_black);

draw_text(x+4, y+4, text);

draw_set_colour(c_white);
