const std = @import("std");

fn readNumber(reader: anytype) !u16 {
    var number: u16 = 0;
    var c: u8 = 0;
    while (true) {
        c = try reader.readByte();
        if (c >= '0' and c <= '9') {
            break;
        }
    }
    number = c - '0';
    while (true) {
        c = reader.readByte() catch {
            break;
        };
        if (c < '0' or c > '9') {
            break;
        }
        number = number * 10 + (c - '0');
    }
    return number;
}

pub fn readPGM(allocator: *std.mem.Allocator, reader: anytype, width: *u16, height: *u16, maxval: *u16) ![]u8 {
    var header: [2]u8 = undefined;
    var raw: bool = undefined;
    _ = try reader.readAll(&header);
    if (std.mem.eql(u8, &header, "P2")) {
        raw = false;
    } else if (std.mem.eql(u8, &header, "P5")) {
        raw = true;
    } else {
        return error.InvalidHeader;
    }

    width.* = try readNumber(reader);
    height.* = try readNumber(reader);
    maxval.* = try readNumber(reader);

    if (maxval.* > 255) {
        return error.InvalidMaxval;
    }

    const image_size: usize = @as(usize, width.*) * height.*;
    const image_data = try allocator.alloc(u8, image_size);

    if (raw) {
        _ = try reader.readAll(image_data);
    } else {
        var i: usize = 0;
        while (i < image_size) {
            image_data[i] = @truncate(try readNumber(reader));
            i += 1;
        }
    }

    return image_data;
}

pub fn writePGM(writer: anytype, raw: bool, width: u16, height: u16, image_data: []const u8) !void {
    if (raw) {
        try writer.print("P5\n{d} {d}\n255\n", .{ width, height });
        try writer.writeAll(image_data);
    } else {
        try writer.print("P2\n{d} {d}\n255\n", .{ width, height });
        var x: usize = 0;
        var y: usize = 0;
        while (x < height) {
            while (y < width) {
                try writer.print("{d} ", .{image_data[x * width + y]});
                y += 1;
            }
            try writer.print("\n", .{});
            y = 0;
            x += 1;
        }
    }
}
