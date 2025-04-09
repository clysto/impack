const std = @import("std");
const impack = @import("root.zig");

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
        if (width == null or height == null) {
            std.debug.print("Usage: {s} encode <width> <height>\n", .{cmd.?});
            return;
        }
        const w = try std.fmt.parseInt(usize, width.?, 10);
        const h = try std.fmt.parseInt(usize, height.?, 10);
        return encode(w, h);
    } else if (std.mem.eql(u8, subcmd.?, "decode")) {
        return decode();
    } else {
        std.debug.print("Usage: {s} [encode|decode]\n", .{cmd.?});
        return;
    }
}

pub fn encode(width: usize, height: usize) !void {
    const writer = std.io.getStdOut().writer();
    const reader = std.io.getStdIn().reader();
    var blk: [64]u8 = undefined;

    var encoder = impack.ImpackEncoder(.high, @TypeOf(writer)){
        .width = @intCast(width),
        .height = @intCast(height),
        .writer = std.io.bitWriter(.big, writer),
    };

    try encoder.encodeHeader();
    for (0..(@divFloor(width, 8) * @divFloor(height, 8))) |_| {
        _ = try reader.read(&blk);
        try encoder.encodeBlock(&blk);
    }
    try encoder.encodeEnd();
}

fn decode() !void {
    const writer = std.io.getStdOut().writer();
    const reader = std.io.getStdIn().reader();
    var blk: [64]u8 = undefined;

    var decoder = impack.ImpackDecoder(@TypeOf(reader)){
        .reader = std.io.bitReader(.big, reader),
    };

    try decoder.decodeHeader();
    for (0..(@divFloor(decoder.width, 8) * @divFloor(decoder.height, 8))) |_| {
        try decoder.decodeBlock(&blk);
        _ = try writer.write(&blk);
    }
}
