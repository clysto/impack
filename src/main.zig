const std = @import("std");
const impack = @import("impack");

pub fn main() !void {
    var args = std.process.args();
    const cmd = args.next();
    const subcmd = args.next();
    if (subcmd == null) {
        std.debug.print("Usage: {s} [encode|decode]\n", .{cmd.?});
        return;
    }
    if (std.mem.eql(u8, subcmd.?, "encode")) {
        const width = args.next();
        const height = args.next();
        var quality = args.next();
        if (width == null or height == null) {
            std.debug.print("Usage: {s} encode <width> <height>\n", .{cmd.?});
            return;
        }
        const w = try std.fmt.parseInt(usize, width.?, 10);
        const h = try std.fmt.parseInt(usize, height.?, 10);
        if (quality == null) {
            quality.? = "best";
        }
        if (std.mem.eql(u8, quality.?, "poor")) {
            return encode(w, h, .poor);
        } else if (std.mem.eql(u8, quality.?, "low")) {
            return encode(w, h, .low);
        } else if (std.mem.eql(u8, quality.?, "medium")) {
            return encode(w, h, .medium);
        } else if (std.mem.eql(u8, quality.?, "high")) {
            return encode(w, h, .high);
        } else if (std.mem.eql(u8, quality.?, "best")) {
            return encode(w, h, .best);
        } else {
            std.debug.print("Usage: {s} encode <width> <height> [poor|low|medium|high|best]\n", .{cmd.?});
            return;
        }
    } else if (std.mem.eql(u8, subcmd.?, "decode")) {
        return decode();
    } else {
        std.debug.print("Usage: {s} [encode|decode]\n", .{cmd.?});
        return;
    }
}

pub fn encode(width: usize, height: usize, comptime quality: impack.Quality) !void {
    const out = std.io.getStdOut();
    const in = std.io.getStdIn();
    var bufOut = std.io.bufferedWriter(out.writer());
    var bufIn = std.io.bufferedReader(in.reader());

    const writer = bufOut.writer();
    const reader = bufIn.reader();
    var blk: [64]u8 = undefined;

    var encoder = impack.ImpackEncoder(quality, @TypeOf(writer)){
        .writer = std.io.bitWriter(.big, writer),
        .width = @intCast(width),
        .height = @intCast(height),
    };
    try encoder.encodeHeader();
    for (0..(@divFloor(width, 8) * @divFloor(height, 8))) |_| {
        _ = try reader.read(&blk);
        try encoder.encodeBlock(&blk);
    }
    try encoder.encodeEnd();
    try bufOut.flush();
}

fn decode() !void {
    const out = std.io.getStdOut();
    const in = std.io.getStdIn();
    var bufOut = std.io.bufferedWriter(out.writer());
    var bufIn = std.io.bufferedReader(in.reader());

    const writer = bufOut.writer();
    const reader = bufIn.reader();

    var blk: [64]u8 = undefined;

    var decoder = impack.ImpackDecoder(@TypeOf(reader)){
        .reader = std.io.bitReader(.big, reader),
    };

    try decoder.decodeHeader();
    for (0..(@divFloor(decoder.width, 8) * @divFloor(decoder.height, 8))) |_| {
        try decoder.decodeBlock(&blk);
        _ = try writer.write(&blk);
    }

    try bufOut.flush();
}
