const c = @cImport({
    @cInclude("quantum.h");
    @cInclude("rgb_matrix.h");
});

export fn rgb_matrix_indicators_user() bool {
    const layer = c.get_highest_layer(c.layer_state);
    switch (layer) {
        1 => { // Symbols — blue
            var i: u8 = 0;
            while (i < c.RGB_MATRIX_LED_COUNT) : (i += 1) {
                c.rgb_matrix_set_color(i, 0x00, 0x10, 0x40);
            }
        },
        2 => { // Nav — green
            var i: u8 = 0;
            while (i < c.RGB_MATRIX_LED_COUNT) : (i += 1) {
                c.rgb_matrix_set_color(i, 0x00, 0x30, 0x10);
            }
        },
        3 => { // Gaming — red
            var i: u8 = 0;
            while (i < c.RGB_MATRIX_LED_COUNT) : (i += 1) {
                c.rgb_matrix_set_color(i, 0x40, 0x00, 0x00);
            }
        },
        else => {},
    }
    return false;
}
