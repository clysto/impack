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
        const quality = args.next();
        if (width == null or height == null) {
            std.debug.print("Usage: {s} encode <width> <height>\n", .{cmd.?});
            return;
        }
        var q = impack.Quality.best;
        if (quality != null) {
            if (std.mem.eql(u8, quality.?, "low")) {
                q = impack.Quality.low;
            } else if (std.mem.eql(u8, quality.?, "medium")) {
                q = impack.Quality.medium;
            } else if (std.mem.eql(u8, quality.?, "high")) {
                q = impack.Quality.high;
            } else if (std.mem.eql(u8, quality.?, "best")) {
                q = impack.Quality.best;
            } else {
                std.debug.print("Usage: {s} encode <width> <height> [low|medium|high|best]\n", .{cmd.?});
                return;
            }
        }
        const w = try std.fmt.parseInt(usize, width.?, 10);
        const h = try std.fmt.parseInt(usize, height.?, 10);
        return encode(w, h, q);
    } else if (std.mem.eql(u8, subcmd.?, "decode")) {
        return decode();
    } else {
        std.debug.print("Usage: {s} [encode|decode]\n", .{cmd.?});
        return;
    }
}

pub fn encode(width: usize, height: usize, quality: impack.Quality) !void {
    const writer = std.io.getStdOut().writer();
    const reader = std.io.getStdIn().reader();
    var blk: [64]u8 = undefined;

    switch (quality) {
        .best => {
            var encoder = impack.ImpackEncoder(.best, @TypeOf(writer)){
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
        },
        .high => {
            var encoder = impack.ImpackEncoder(.high, @TypeOf(writer)){
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
        },
        .medium => {
            var encoder = impack.ImpackEncoder(.medium, @TypeOf(writer)){
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
        },
        .low => {
            var encoder = impack.ImpackEncoder(.low, @TypeOf(writer)){
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
        },
    }
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
