const std = @import("std");
const dct = @import("dct.zig");

const annscales = [64]i32{
    16384, 22725, 21407, 19266, 16384, 12873, 8867,  4520,
    22725, 31521, 29692, 26722, 22725, 17855, 12299, 6270,
    21407, 29692, 27969, 25172, 21407, 16819, 11585, 5906,
    19266, 26722, 25172, 22654, 19266, 15137, 10426, 5315,
    16384, 22725, 21407, 19266, 16384, 12873, 8867,  4520,
    12873, 17855, 16819, 15137, 12873, 10114, 6967,  3552,
    8867,  12299, 11585, 10426, 8867,  6967,  4799,  2446,
    4520,  6270,  5906,  5315,  4520,  3552,  2446,  1247,
};

const dc_huff_table = [12]u32{
    0x0000, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006,
    0x000e, 0x001e, 0x003e, 0x007e, 0x00fe, 0x01fe,
};

const dc_huff_table_codelen = [12]u8{ 2, 3, 3, 3, 3, 3, 4, 5, 6, 7, 8, 9 };

const ac_huff_table = [16][11]u32{
    .{ 0x000a, 0x0000, 0x0001, 0x0004, 0x000b, 0x001a, 0x0078, 0x00f8, 0x03f6, 0xff82, 0xff83 },
    .{ 0x0000, 0x000c, 0x001b, 0x0079, 0x01f6, 0x07f6, 0xff84, 0xff85, 0xff86, 0xff87, 0xff88 },
    .{ 0x0000, 0x001c, 0x00f9, 0x03f7, 0x0ff4, 0xff89, 0xff8a, 0xff8b, 0xff8c, 0xff8d, 0xff8e },
    .{ 0x0000, 0x003a, 0x01f7, 0x0ff5, 0xff8f, 0xff90, 0xff91, 0xff92, 0xff93, 0xff94, 0xff95 },
    .{ 0x0000, 0x003b, 0x03f8, 0xff96, 0xff97, 0xff98, 0xff99, 0xff9a, 0xff9b, 0xff9c, 0xff9d },
    .{ 0x0000, 0x007a, 0x07f7, 0xff9e, 0xff9f, 0xffa0, 0xffa1, 0xffa2, 0xffa3, 0xffa4, 0xffa5 },
    .{ 0x0000, 0x007b, 0x0ff6, 0xffa6, 0xffa7, 0xffa8, 0xffa9, 0xffaa, 0xffab, 0xffac, 0xffad },
    .{ 0x0000, 0x00fa, 0x0ff7, 0xffae, 0xffaf, 0xffb0, 0xffb1, 0xffb2, 0xffb3, 0xffb4, 0xffb5 },
    .{ 0x0000, 0x01f8, 0x7fc0, 0xffb6, 0xffb7, 0xffb8, 0xffb9, 0xffba, 0xffbb, 0xffbc, 0xffbd },
    .{ 0x0000, 0x01f9, 0xffbe, 0xffbf, 0xffc0, 0xffc1, 0xffc2, 0xffc3, 0xffc4, 0xffc5, 0xffc6 },
    .{ 0x0000, 0x01fa, 0xffc7, 0xffc8, 0xffc9, 0xffca, 0xffcb, 0xffcc, 0xffcd, 0xffce, 0xffcf },
    .{ 0x0000, 0x03f9, 0xffd0, 0xffd1, 0xffd2, 0xffd3, 0xffd4, 0xffd5, 0xffd6, 0xffd7, 0xffd8 },
    .{ 0x0000, 0x03fa, 0xffd9, 0xffda, 0xffdb, 0xffdc, 0xffdd, 0xffde, 0xffdf, 0xffe0, 0xffe1 },
    .{ 0x0000, 0x07f8, 0xffe2, 0xffe3, 0xffe4, 0xffe5, 0xffe6, 0xffe7, 0xffe8, 0xffe9, 0xffea },
    .{ 0x0000, 0xffeb, 0xffec, 0xffed, 0xffee, 0xffef, 0xfff0, 0xfff1, 0xfff2, 0xfff3, 0xfff4 },
    .{ 0x07f9, 0xfff5, 0xfff6, 0xfff7, 0xfff8, 0xfff9, 0xfffa, 0xfffb, 0xfffc, 0xfffd, 0xfffe },
};

const ac_huff_table_codelen = [16][11]u8{
    .{ 4, 2, 2, 3, 4, 5, 7, 8, 10, 16, 16 },        .{ 0, 4, 5, 7, 9, 11, 16, 16, 16, 16, 16 },
    .{ 0, 5, 8, 10, 12, 16, 16, 16, 16, 16, 16 },   .{ 0, 6, 9, 12, 16, 16, 16, 16, 16, 16, 16 },
    .{ 0, 6, 10, 16, 16, 16, 16, 16, 16, 16, 16 },  .{ 0, 7, 11, 16, 16, 16, 16, 16, 16, 16, 16 },
    .{ 0, 7, 12, 16, 16, 16, 16, 16, 16, 16, 16 },  .{ 0, 8, 12, 16, 16, 16, 16, 16, 16, 16, 16 },
    .{ 0, 9, 15, 16, 16, 16, 16, 16, 16, 16, 16 },  .{ 0, 9, 16, 16, 16, 16, 16, 16, 16, 16, 16 },
    .{ 0, 9, 16, 16, 16, 16, 16, 16, 16, 16, 16 },  .{ 0, 10, 16, 16, 16, 16, 16, 16, 16, 16, 16 },
    .{ 0, 10, 16, 16, 16, 16, 16, 16, 16, 16, 16 }, .{ 0, 11, 16, 16, 16, 16, 16, 16, 16, 16, 16 },
    .{ 0, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16 }, .{ 11, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16 },
};

const quant_table = [64]u8{
    16, 11, 10, 16, 24,  40,  51,  61,
    12, 12, 14, 19, 26,  58,  60,  55,
    14, 13, 16, 24, 40,  57,  69,  56,
    14, 17, 22, 29, 51,  87,  80,  62,
    18, 22, 37, 56, 68,  109, 103, 77,
    24, 35, 55, 64, 81,  104, 113, 92,
    49, 64, 78, 87, 103, 121, 120, 101,
    72, 92, 95, 98, 112, 100, 103, 99,
};

const zig_zag_ord = [64]u8{
    0,  1,  8,  16, 9,  2,  3,  10,
    17, 24, 32, 25, 18, 11, 4,  5,
    12, 19, 26, 33, 40, 48, 41, 34,
    27, 20, 13, 6,  7,  14, 21, 28,
    35, 42, 49, 56, 57, 50, 43, 36,
    29, 22, 15, 23, 30, 37, 44, 51,
    58, 59, 52, 45, 38, 31, 39, 46,
    53, 60, 61, 54, 47, 55, 62, 63,
};

pub const Quality = enum {
    low,
    medium,
    high,
    best,
};

pub fn ImpackDecoder(comptime Reader: type) type {
    return struct {
        width: u16 = 0,
        height: u16 = 0,
        reader: std.io.BitReader(.big, Reader),
        quality: Quality = .best,

        pub fn readDCHuffCode(self: *@This()) !u5 {
            var prefix: u32 = 0;
            var prefix_len: usize = 0;
            var n: u16 = undefined;
            for (0..16) |_| {
                prefix <<= 1;
                prefix = prefix | try self.reader.readBits(u32, 1, &n);
                prefix_len += 1;
                for (0.., dc_huff_table, dc_huff_table_codelen) |bits, huff_code, huff_code_len| {
                    if (prefix == huff_code and prefix_len == huff_code_len) {
                        return @intCast(bits);
                    }
                }
            }
            return error.InvalidHuffmanCode;
        }

        pub fn readACHuffCode(self: *@This(), runlength: *usize) !u5 {
            var prefix: u32 = 0;
            var prefix_len: usize = 0;
            var n: u16 = undefined;
            for (0..16) |_| {
                prefix <<= 1;
                prefix = prefix | try self.reader.readBits(u32, 1, &n);
                prefix_len += 1;
                for (0..ac_huff_table.len) |rl| {
                    for (0.., ac_huff_table[rl], ac_huff_table_codelen[rl]) |bits, huff_code, huff_code_len| {
                        if (prefix == huff_code and prefix_len == huff_code_len) {
                            runlength.* = rl;
                            return @intCast(bits);
                        }
                    }
                }
            }
            return error.InvalidHuffmanCode;
        }

        pub fn readInt(self: *@This(), bits: u5) !i32 {
            var n: u16 = undefined;
            const value = try self.reader.readBits(i32, bits, &n);
            if ((value >> @intCast(bits - 1)) == 0) {
                return -(value ^ ((@as(i32, 1) << bits) - 1));
            }
            return value;
        }

        pub fn decodeHeader(self: *@This()) !void {
            var n: u16 = undefined;
            self.width = try self.reader.readBits(u16, 16, &n);
            self.height = try self.reader.readBits(u16, 16, &n);
            const quality_value = try self.reader.readBits(u32, 32, &n);
            if (quality_value > @intFromEnum(Quality.best)) {
                return error.InvalidQuality;
            }
            self.quality = @enumFromInt(quality_value);
        }

        pub fn decodeBlock(self: *@This(), blk: *[64]u8) !void {
            var bits: u5 = undefined;
            var runlength: usize = undefined;
            var value: i32 = undefined;
            var blk_coeff: [64]i32 = undefined;
            @memset(&blk_coeff, 0);
            bits = try self.readDCHuffCode();
            if (bits == 0) {
                value = 0;
            } else {
                value = try self.readInt(bits);
            }
            blk_coeff[0] = value * (quant_table[0] >> @intFromEnum(self.quality));

            var index: usize = 1;
            for (0..64) |_| {
                bits = try self.readACHuffCode(&runlength);
                if (bits == 0) {
                    if (runlength == 0) {
                        break;
                    }
                } else {
                    value = try self.readInt(bits);
                    index += runlength;
                    blk_coeff[zig_zag_ord[index]] = value * (quant_table[zig_zag_ord[index]] >> @intFromEnum(self.quality));
                    index += 1;
                }
            }
            dct.idct(&blk_coeff);
            for (0..64) |i| {
                blk[i] = @intCast(blk_coeff[i] + 128);
            }
        }
    };
}

pub fn ImpackEncoder(comptime quality: Quality, comptime Writer: type) type {
    return struct {
        width: u16,
        height: u16,
        writer: std.io.BitWriter(.big, Writer),
        quant_table: [64]i32 = blk: {
            var tmp: [64]i32 = undefined;
            for (0..64) |i| {
                const v1: f32 = @floatFromInt(quant_table[i] >> @intFromEnum(quality));
                const v2: f32 = @floatFromInt(annscales[i]);
                tmp[i] = @intFromFloat(@round((65536 * 2048) / (v1 * v2)));
            }
            break :blk tmp;
        },

        pub fn encodeHeader(self: *@This()) !void {
            try self.writer.writeBits(self.width, 16);
            try self.writer.writeBits(self.height, 16);
            try self.writer.writeBits(@as(u32, @intFromEnum(quality)), 32);
        }

        pub fn encodeBlock(self: *@This(), blk: *const [64]u8) !void {
            var blk_offset: [64]i8 = undefined;
            var blk_coeff: [64]i16 = undefined;
            var i: usize = 0;
            while (i < 64) : (i += 1) {
                blk_offset[i] = @bitCast(blk[i] ^ 0x80);
            }
            dct.fdct(&blk_offset, &blk_coeff);
            self.quantBlock(&blk_coeff);

            // Encode DC coefficient
            try self.writeDCHuffCode(blk_coeff[0]);
            var runlength: i16 = 0;
            var zero_cnt: i16 = 0;
            var value: i16 = undefined;
            for (zig_zag_ord[1..]) |j| {
                const coeff: i16 = blk_coeff[j];
                if (coeff == 0) {
                    zero_cnt += 1;
                    if (zero_cnt >= 16) {
                        runlength = 15;
                        value = 0;
                        zero_cnt = 0;
                    }
                } else {
                    runlength = zero_cnt;
                    value = coeff;
                    zero_cnt = 0;
                }

                if (zero_cnt == 0) {
                    // Encode AC coefficient
                    try self.writeACHuffCode(@intCast(runlength), value);
                }
            }
            // Write EOB (End of Block)
            try self.writeACHuffCode(0, 0);
        }

        pub fn encodeEnd(self: *@This()) !void {
            try self.writer.flushBits();
        }

        pub fn quantBlock(self: *@This(), blk: *[64]i16) void {
            var i: usize = 0;
            while (i < 64) : (i += 1) {
                const d: i32 = blk[i];
                const q: i32 = 1 << 15;
                if (d < 0) {
                    blk[i] = @intCast(-((-d * self.quant_table[i] + q) >> 16));
                } else {
                    blk[i] = @intCast((d * self.quant_table[i] + q) >> 16);
                }
            }
        }

        pub fn writeDCHuffCode(self: *@This(), value: i16) !void {
            if (value < 0) {
                const bits: u16 = @intCast(32 - std.zig.c_builtins.__builtin_clz(@intCast(-value)));
                try self.writer.writeBits(dc_huff_table[bits], dc_huff_table_codelen[bits]);
                try self.writer.writeBits(~(-value), bits);
            } else {
                const bits: u16 = @intCast(32 - std.zig.c_builtins.__builtin_clz(@intCast(value)));
                try self.writer.writeBits(dc_huff_table[bits], dc_huff_table_codelen[bits]);
                if (value == 0) {
                    return;
                }
                try self.writer.writeBits(value, bits);
            }
        }

        pub fn writeACHuffCode(self: *@This(), runlength: usize, value: i16) !void {
            if (value < 0) {
                const bits: u16 = @intCast(32 - std.zig.c_builtins.__builtin_clz(@intCast(-value)));
                try self.writer.writeBits(ac_huff_table[runlength][bits], ac_huff_table_codelen[runlength][bits]);
                try self.writer.writeBits(~(-value), bits);
            } else {
                const bits: u16 = @intCast(32 - std.zig.c_builtins.__builtin_clz(@intCast(value)));
                try self.writer.writeBits(ac_huff_table[runlength][bits], ac_huff_table_codelen[runlength][bits]);
                if (value == 0) {
                    return;
                }
                try self.writer.writeBits(value, bits);
            }
        }
    };
}

test "test" {
    const allocator = std.heap.page_allocator;
    const buffer_len = 4096;
    const buffer = try allocator.alloc(u8, buffer_len);

    for (buffer) |*byte| {
        byte.* = 0;
    }

    var stream = std.io.fixedBufferStream(buffer);
    const writer = stream.writer();

    var encoder = ImpackEncoder(.best, @TypeOf(writer)){
        .width = 128,
        .height = 128,
        .writer = std.io.bitWriter(.big, writer),
    };

    std.debug.print("Quant table: {any}\n", .{encoder.quant_table});

    const a = [64]u8{
        10, 10, 10, 10, 10, 10, 10, 10,
        10, 10, 10, 10, 10, 10, 10, 10,
        10, 10, 10, 10, 10, 10, 10, 10,
        10, 10, 10, 10, 10, 10, 10, 10,
        20, 20, 20, 20, 20, 20, 20, 20,
        20, 20, 20, 20, 20, 20, 20, 20,
        20, 20, 20, 20, 20, 20, 20, 20,
        20, 20, 20, 20, 20, 20, 20, 30,
    };

    try encoder.encodeBlock(&a);
    try encoder.writer.flushBits();

    stream.reset();
    const reader = stream.reader();
    var decoder = ImpackDecoder(@TypeOf(reader)){
        .width = 128,
        .height = 128,
        .reader = std.io.bitReader(.big, reader),
    };
    var test_decode: [64]u8 = undefined;
    try decoder.decodeBlock(&test_decode);
}
