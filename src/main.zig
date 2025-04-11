const std = @import("std");
const impack = @import("impack");
const pgm = @import("pgm.zig");

pub fn main() !void {
    var args = std.process.args();
    const cmd = args.next();
    const subcmd = args.next();
    if (subcmd == null) {
        std.debug.print("Usage: {s} [encode|decode]\n", .{cmd.?});
        return;
    }
    if (std.mem.eql(u8, subcmd.?, "encode")) {
        const quality = args.next();
        if (quality == null) {
            return encode(.best);
        } else if (std.mem.eql(u8, quality.?, "poor")) {
            return encode(.poor);
        } else if (std.mem.eql(u8, quality.?, "low")) {
            return encode(.low);
        } else if (std.mem.eql(u8, quality.?, "medium")) {
            return encode(.medium);
        } else if (std.mem.eql(u8, quality.?, "high")) {
            return encode(.high);
        } else if (std.mem.eql(u8, quality.?, "best")) {
            return encode(.best);
        } else {
            std.debug.print("Usage: {s} encode [poor|low|medium|high|best]\n", .{cmd.?});
            return;
        }
    } else if (std.mem.eql(u8, subcmd.?, "decode")) {
        return decode();
    } else {
        std.debug.print("Usage: {s} [encode|decode]\n", .{cmd.?});
        return;
    }
}

pub fn encode(comptime quality: impack.Quality) !void {
    const out = std.io.getStdOut();
    const in = std.io.getStdIn();
    var buf_out = std.io.bufferedWriter(out.writer());
    var buf_in = std.io.bufferedReader(in.reader());

    const writer = buf_out.writer();
    const reader = buf_in.reader();
    var blk: [64]u8 = undefined;

    var width: u16 = 0;
    var height: u16 = 0;
    var maxval: u16 = 0;
    var allocator = std.heap.page_allocator;
    const img = try pgm.readPGM(&allocator, reader, &width, &height, &maxval);
    defer allocator.free(img);

    var encoder = impack.ImpackEncoder(quality, @TypeOf(writer)){
        .writer = std.io.bitWriter(.big, writer),
        .width = @intCast(width),
        .height = @intCast(height),
    };
    try encoder.encodeHeader();

    var row: usize = 0;
    while (row < height) {
        var col: usize = 0;
        while (col < width) {
            @memset(&blk, 0);
            for (row..@min(row + 8, height)) |i| {
                for (col..@min(col + 8, width)) |j| {
                    blk[(i - row) * 8 + (j - col)] = img[i * width + j];
                }
            }
            try encoder.encodeBlock(&blk);
            col += 8;
        }
        row += 8;
    }

    try encoder.encodeEnd();
    try buf_out.flush();
}

fn decode() !void {
    const out = std.io.getStdOut();
    const in = std.io.getStdIn();
    var buf_out = std.io.bufferedWriter(out.writer());
    var buf_in = std.io.bufferedReader(in.reader());

    const writer = buf_out.writer();
    const reader = buf_in.reader();

    var blk: [64]u8 = undefined;

    var decoder = impack.ImpackDecoder(@TypeOf(reader)){
        .reader = std.io.bitReader(.big, reader),
    };

    try decoder.decodeHeader();

    var allocator = std.heap.page_allocator;
    var img = try allocator.alloc(u8, @as(usize, decoder.width) * decoder.height);
    defer allocator.free(img);

    var row: usize = 0;
    while (row < decoder.height) {
        var col: usize = 0;
        while (col < decoder.width) {
            try decoder.decodeBlock(&blk);
            for (0..8) |i| {
                for (0..8) |j| {
                    if (row + i < decoder.height and col + j < decoder.width) {
                        img[(row + i) * decoder.width + (col + j)] = blk[i * 8 + j];
                    }
                }
            }
            col += 8;
        }
        row += 8;
    }

    try pgm.writePGM(writer, true, decoder.width, decoder.height, img);
    try buf_out.flush();
}
