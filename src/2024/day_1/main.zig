const std = @import("std");
const common_input = @import("common").input;

fn parseLists(allocator: std.mem.Allocator, input: []const []const u8) !struct { std.ArrayList(i64), std.ArrayList(i64) } {
    var left_list = std.ArrayList(i64).empty;
    var right_list = std.ArrayList(i64).empty;

    errdefer {
        left_list.deinit(allocator);
        right_list.deinit(allocator);
    }

    for (input) |line| {
        const end_of_left = std.mem.indexOf(u8, line, " ").?;
        const start_of_right = std.mem.lastIndexOf(u8, line, " ").?;

        const left = try std.fmt.parseInt(i64, line[0..end_of_left], 10);
        const right = try std.fmt.parseInt(i64, line[start_of_right + 1 ..], 10);

        try left_list.append(allocator, left);
        try right_list.append(allocator, right);
    }

    return .{
        left_list,
        right_list,
    };
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var diff_score: u64 = 0;

    var left_list, var right_list = try parseLists(allocator, input);

    defer {
        left_list.deinit(allocator);
        right_list.deinit(allocator);
    }

    if (left_list.items.len != right_list.items.len) return error.InvalidInputLength;

    std.mem.sort(i64, left_list.items, {}, std.sort.asc(i64));
    std.mem.sort(i64, right_list.items, {}, std.sort.asc(i64));

    for (0..left_list.items.len) |ix| {
        diff_score += @abs(left_list.items[ix] - right_list.items[ix]);
    }

    // std.debug.print("{any}", .{left_list.items});

    return diff_score;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var similarity_score: u64 = 0;

    var left_list, var right_list = try parseLists(allocator, input);

    defer {
        left_list.deinit(allocator);
        right_list.deinit(allocator);
    }

    var histogram = std.AutoArrayHashMap(i64, i64).init(allocator);
    defer {
        histogram.deinit();
    }

    for (right_list.items) |item| {
        const put = try histogram.getOrPut(item);

        if (put.found_existing) {
            put.value_ptr.* += 1;
        } else {
            put.value_ptr.* = 1;
        }
    }

    for (left_list.items) |item| {
        if (histogram.get(item)) |freq| {
            similarity_score += @intCast(item * freq);
        }
    }

    return similarity_score;
}

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    var allocator = gpa.allocator();

    defer _ = gpa.deinit();

    var input = try common_input.readFileInput(allocator, "input.txt");
    defer {
        for (input.items) |item| {
            allocator.free(item);
        }
        input.deinit(allocator);
    }

    std.debug.print("Part 1 solution: {d}\n", .{try solvePart1(allocator, input.items)});
    std.debug.print("Part 2 solution: {d}\n", .{try solvePart2(allocator, input.items)});
}

test "solve part 1 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "3   4",
        "4   3",
        "2   5",
        "1   3",
        "3   9",
        "3   3",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 11), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "3   4",
        "4   3",
        "2   5",
        "1   3",
        "3   9",
        "3   3",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 31), result);
}
