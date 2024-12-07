const std = @import("std");

pub fn parseNumbers(T: type, allocator: std.mem.Allocator, input: []const u8, delimiter: u8) !std.ArrayList(T) {
    var result = std.ArrayList(T).init(allocator);
    errdefer result.deinit();

    var split = std.mem.splitScalar(u8, input, delimiter);

    while (split.next()) |number| {
        try result.append(try std.fmt.parseInt(T, number, 10));
    }

    return result;
}
