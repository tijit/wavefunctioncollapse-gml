draw_set_font(fButton);

var col = hover ? #000000 : #aaaaaa;

draw_sprite_ext(sprPixel, 0, x, y, image_xscale, image_yscale, 0, col, 1);

col = hover ? #ffffff : 000000;
draw_set_colour(col);

draw_text(x+4, y+4, text);

draw_set_colour(c_white);
