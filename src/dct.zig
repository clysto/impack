const w1: i32 = 2841; // 2048*sqrt(2)*cos(1*pi/16)
const w2: i32 = 2676; // 2048*sqrt(2)*cos(2*pi/16)
const w3: i32 = 2408; // 2048*sqrt(2)*cos(3*pi/16)
const w5: i32 = 1609; // 2048*sqrt(2)*cos(5*pi/16)
const w6: i32 = 1108; // 2048*sqrt(2)*cos(6*pi/16)
const w7: i32 = 565; // 2048*sqrt(2)*cos(7*pi/16)

const w1pw7: i32 = w1 + w7;
const w1mw7: i32 = w1 - w7;
const w2pw6: i32 = w2 + w6;
const w2mw6: i32 = w2 - w6;
const w3pw5: i32 = w3 + w5;
const w3mw5: i32 = w3 - w5;

const r2: i32 = 181; // 256/sqrt(2)

pub fn fdct(src: [*]const i8, dst: [*]i16) void {
    var tmp0: i32 = undefined;
    var tmp1: i32 = undefined;
    var tmp2: i32 = undefined;
    var tmp3: i32 = undefined;
    var tmp4: i32 = undefined;
    var tmp5: i32 = undefined;
    var tmp6: i32 = undefined;
    var tmp7: i32 = undefined;
    var tmp10: i32 = undefined;
    var tmp11: i32 = undefined;
    var tmp12: i32 = undefined;
    var tmp13: i32 = undefined;
    var z1: i32 = undefined;
    var z2: i32 = undefined;
    var z3: i32 = undefined;
    var z4: i32 = undefined;
    var z5: i32 = undefined;
    var z11: i32 = undefined;
    var z13: i32 = undefined;

    var s: [*]const i8 = src;
    var d: [*]i16 = dst;

    // Process rows
    var row: usize = 0;
    while (row < 64) : (row += 8) {
        tmp0 = @as(i32, s[0]) + s[7];
        tmp7 = @as(i32, s[0]) - s[7];
        tmp1 = @as(i32, s[1]) + s[6];
        tmp6 = @as(i32, s[1]) - s[6];
        tmp2 = @as(i32, s[2]) + s[5];
        tmp5 = @as(i32, s[2]) - s[5];
        tmp3 = @as(i32, s[3]) + s[4];
        tmp4 = @as(i32, s[3]) - s[4];

        // even part
        tmp10 = tmp0 + tmp3;
        tmp13 = tmp0 - tmp3;
        tmp11 = tmp1 + tmp2;
        tmp12 = tmp1 - tmp2;

        d[0] = @intCast(tmp10 + tmp11);
        d[4] = @intCast(tmp10 - tmp11);

        z1 = ((tmp12 + tmp13) * 181) >> 8;
        d[2] = @intCast(tmp13 + z1);
        d[6] = @intCast(tmp13 - z1);

        // odd part
        tmp10 = tmp4 + tmp5;
        tmp11 = tmp5 + tmp6;
        tmp12 = tmp6 + tmp7;

        z5 = (tmp10 - tmp12) * 98;
        z2 = (z5 + tmp10 * 139) >> 8;
        z4 = (z5 + tmp12 * 334) >> 8;
        z3 = (tmp11 * 181) >> 8;
        z11 = tmp7 + z3;
        z13 = tmp7 - z3;

        d[5] = @intCast(z13 + z2);
        d[3] = @intCast(z13 - z2);
        d[1] = @intCast(z11 + z4);
        d[7] = @intCast(z11 - z4);

        s += 8;
        d += 8;
    }

    // Process columns
    d = dst;
    var col: usize = 0;
    while (col < 8) : (col += 1) {
        const offset = col;
        tmp0 = @as(i32, d[0 * 8 + offset]) + d[7 * 8 + offset];
        tmp7 = @as(i32, d[0 * 8 + offset]) - d[7 * 8 + offset];
        tmp1 = @as(i32, d[1 * 8 + offset]) + d[6 * 8 + offset];
        tmp6 = @as(i32, d[1 * 8 + offset]) - d[6 * 8 + offset];
        tmp2 = @as(i32, d[2 * 8 + offset]) + d[5 * 8 + offset];
        tmp5 = @as(i32, d[2 * 8 + offset]) - d[5 * 8 + offset];
        tmp3 = @as(i32, d[3 * 8 + offset]) + d[4 * 8 + offset];
        tmp4 = @as(i32, d[3 * 8 + offset]) - d[4 * 8 + offset];

        // even part
        tmp10 = tmp0 + tmp3;
        tmp13 = tmp0 - tmp3;
        tmp11 = tmp1 + tmp2;
        tmp12 = tmp1 - tmp2;

        d[0 * 8 + offset] = @intCast(tmp10 + tmp11);
        d[4 * 8 + offset] = @intCast(tmp10 - tmp11);

        z1 = ((tmp12 + tmp13) * 181) >> 8;
        d[2 * 8 + offset] = @intCast(tmp13 + z1);
        d[6 * 8 + offset] = @intCast(tmp13 - z1);

        // odd part
        tmp10 = tmp4 + tmp5;
        tmp11 = tmp5 + tmp6;
        tmp12 = tmp6 + tmp7;

        z5 = (tmp10 - tmp12) * 98;
        z2 = (z5 + tmp10 * 139) >> 8;
        z4 = (z5 + tmp12 * 334) >> 8;
        z3 = (tmp11 * 181) >> 8;
        z11 = tmp7 + z3;
        z13 = tmp7 - z3;

        d[5 * 8 + offset] = @intCast(z13 + z2);
        d[3 * 8 + offset] = @intCast(z13 - z2);
        d[1 * 8 + offset] = @intCast(z11 + z4);
        d[7 * 8 + offset] = @intCast(z11 - z4);
    }
}

pub fn idct(src: [*]i32) void {
    // Horizontal 1-D IDCT
    var y: usize = 0;
    while (y < 8) : (y += 1) {
        const y8 = y * 8;
        var s: [*]i32 = src + y8;

        if (s[1] == 0 and s[2] == 0 and s[3] == 0 and
            s[4] == 0 and s[5] == 0 and s[6] == 0 and s[7] == 0)
        {
            const dc = s[0] << 3;
            s[0] = dc;
            s[1] = dc;
            s[2] = dc;
            s[3] = dc;
            s[4] = dc;
            s[5] = dc;
            s[6] = dc;
            s[7] = dc;
            continue;
        }

        var x0 = (s[0] << 11) + 128;
        var x1 = s[4] << 11;
        var x2 = s[6];
        var x3 = s[2];
        var x4 = s[1];
        var x5 = s[7];
        var x6 = s[5];
        var x7 = s[3];

        var x8 = w7 * (x4 + x5);
        x4 = x8 + w1mw7 * x4;
        x5 = x8 - w1pw7 * x5;
        x8 = w3 * (x6 + x7);
        x6 = x8 - w3mw5 * x6;
        x7 = x8 - w3pw5 * x7;

        x8 = x0 + x1;
        x0 -= x1;
        x1 = w6 * (x3 + x2);
        x2 = x1 - w2pw6 * x2;
        x3 = x1 + w2mw6 * x3;
        x1 = x4 + x6;
        x4 -= x6;
        x6 = x5 + x7;
        x5 -= x7;

        x7 = x8 + x3;
        x8 -= x3;
        x3 = x0 + x2;
        x0 -= x2;
        x2 = (r2 * (x4 + x5) + 128) >> 8;
        x4 = (r2 * (x4 - x5) + 128) >> 8;

        s[0] = (x7 + x1) >> 8;
        s[1] = (x3 + x2) >> 8;
        s[2] = (x0 + x4) >> 8;
        s[3] = (x8 + x6) >> 8;
        s[4] = (x8 - x6) >> 8;
        s[5] = (x0 - x4) >> 8;
        s[6] = (x3 - x2) >> 8;
        s[7] = (x7 - x1) >> 8;
    }

    // Vertical 1-D IDCT
    var x: usize = 0;
    while (x < 8) : (x += 1) {
        var s: [*]i32 = src + x;

        var y0 = (s[8 * 0] << 8) + 8192;
        var y1 = s[8 * 4] << 8;
        var y2 = s[8 * 6];
        var y3 = s[8 * 2];
        var y4 = s[8 * 1];
        var y5 = s[8 * 7];
        var y6 = s[8 * 5];
        var y7 = s[8 * 3];

        var y8 = w7 * (y4 + y5) + 4;
        y4 = (y8 + w1mw7 * y4) >> 3;
        y5 = (y8 - w1pw7 * y5) >> 3;
        y8 = w3 * (y6 + y7) + 4;
        y6 = (y8 - w3mw5 * y6) >> 3;
        y7 = (y8 - w3pw5 * y7) >> 3;

        y8 = y0 + y1;
        y0 -= y1;
        y1 = w6 * (y3 + y2) + 4;
        y2 = (y1 - w2pw6 * y2) >> 3;
        y3 = (y1 + w2mw6 * y3) >> 3;
        y1 = y4 + y6;
        y4 -= y6;
        y6 = y5 + y7;
        y5 -= y7;

        y7 = y8 + y3;
        y8 -= y3;
        y3 = y0 + y2;
        y0 -= y2;
        y2 = (r2 * (y4 + y5) + 128) >> 8;
        y4 = (r2 * (y4 - y5) + 128) >> 8;

        s[8 * 0] = (y7 + y1) >> 14;
        s[8 * 1] = (y3 + y2) >> 14;
        s[8 * 2] = (y0 + y4) >> 14;
        s[8 * 3] = (y8 + y6) >> 14;
        s[8 * 4] = (y8 - y6) >> 14;
        s[8 * 5] = (y0 - y4) >> 14;
        s[8 * 6] = (y3 - y2) >> 14;
        s[8 * 7] = (y7 - y1) >> 14;
    }
}
