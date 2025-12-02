const std = @import("std");
const common_input = @import("common").input;

const Range = struct {
    left: u64,
    right: u64,
};

fn parseRanges(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Range) {
    if (input.len != 1) {
        return error.MalformedInput;
    }

    var ranges = std.ArrayList(Range).empty;
    errdefer ranges.deinit(allocator);

    var it = std.mem.splitScalar(u8, input[0], ',');

    while (it.next()) |rangeStr| {
        var parts = std.mem.splitScalar(u8, rangeStr, '-');
        const left_str = parts.next() orelse return error.MalformedInput;
        const right_str = parts.next() orelse return error.MalformedInput;
        try ranges.append(allocator, Range{
            .left = try std.fmt.parseInt(u64, left_str, 10),
            .right = try std.fmt.parseInt(u64, right_str, 10),
        });
    }

    return ranges;
}

fn invalidIdPart1(id: u64) !bool {
    const digits: u64 = std.math.log10_int(id) + 1;

    if (@mod(digits, 2) != 0) {
        return false;
    }

    const half_len = digits / 2;
    const base = try std.math.powi(u64, 10, half_len);
    const left_part = @divTrunc(id, base);
    const right_part = @mod(id, base);

    if (left_part == right_part) {
        return true;
    }

    return false;
}

fn invalidIdPart2(buffer: *std.ArrayList(u64), id: u64) !bool {
    const digits: u64 = std.math.log10_int(id) + 1;

    std.debug.assert(buffer.capacity >= @as(usize, digits));

    for (2..digits + 1) |split_size| {
        if (@mod(digits, split_size) != 0) {
            continue;
        }

        defer buffer.clearRetainingCapacity();

        const part_len = @divTrunc(digits, split_size);
        const base = try std.math.powi(u64, 10, part_len);

        var ix: isize = @intCast(split_size - 1);
        while (ix >= 0) : (ix -= 1) {
            const divisor = try std.math.powi(u64, base, @intCast(ix));
            const part = @mod(@divTrunc(id, divisor), base);
            buffer.appendAssumeCapacity(part);
        }

        if (std.mem.allEqual(u64, buffer.items[1..], buffer.items[0])) {
            return true;
        }
    }

    return false;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var score: u64 = 0;

    var ranges = try parseRanges(allocator, input);
    defer ranges.deinit(allocator);

    for (ranges.items) |range| {
        var ix = range.left;
        while (ix <= range.right) : (ix += 1) {
            if (try invalidIdPart1(ix)) {
                score += ix;
            }
        }
    }

    return score;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var score: u64 = 0;

    var ranges = try parseRanges(allocator, input);
    defer ranges.deinit(allocator);

    var buffer: std.ArrayList(u64) = try .initCapacity(allocator, @as(usize, std.math.log10_int(@as(u64, std.math.maxInt(u64))) + 1));
    defer buffer.deinit(allocator);

    for (ranges.items) |range| {
        var ix = range.left;
        while (ix <= range.right) : (ix += 1) {
            if (try invalidIdPart2(&buffer, ix)) {
                score += ix;
            }
        }
    }

    return score;
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
    const test_input = [_][]const u8{"11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124"};

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 1227775554), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{"11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124"};
    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 4174379265), result);
}
