const std = @import("std");

pub fn readFileInput(allocator: std.mem.Allocator, input_file_path: []const u8) !std.ArrayList([]u8) {
    var file = try std.fs.cwd().openFile(input_file_path, .{ .mode = std.fs.File.OpenMode.read_only });
    defer file.close();

    var buffer: [1024]u8 = undefined;
    var reader = std.io.bufferedReader(file.reader());

    var result = std.ArrayList([]u8).init(allocator);
    errdefer {
        for (result.items) |item| {
            allocator.free(item);
        }
        result.deinit();
    }

    while (try reader.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var result_line = try allocator.dupe(u8, line);
        errdefer allocator.free(result_line);

        try result.append(result_line);
    }

    return result;
}
