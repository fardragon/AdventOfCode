const std = @import("std");

pub fn readFileInput(allocator: std.mem.Allocator, input_file_path: []const u8) !std.ArrayList([]u8) {
    var file = try std.fs.cwd().openFile(input_file_path, .{ .mode = std.fs.File.OpenMode.read_only });
    defer file.close();

    var buffer: [1024 * 128]u8 = undefined;
    var reader = file.reader(&buffer);

    var result = std.ArrayList([]u8).empty;
    errdefer {
        for (result.items) |item| {
            allocator.free(item);
        }
        result.deinit(allocator);
    }

    while (reader.interface.takeDelimiterExclusive('\n')) |line| {
        const result_line = try allocator.dupe(u8, line);
        errdefer allocator.free(result_line);

        try result.append(allocator, result_line);
    } else |err| {
        switch (err) {
            error.EndOfStream => {},
            else => return err,
        }
    }

    return result;
}
