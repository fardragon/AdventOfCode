const std = @import("std");
const common_input = @import("common").input;

const Range = struct {
    left: u64,
    right: u64,

    fn contains(self: *const Range, value: u64) bool {
        return value >= self.left and value <= self.right;
    }

    fn canMerge(lhs: *const Range, rhs: *const Range) bool {
        return lhs.right + 1 >= rhs.left;
    }

    fn count(self: *const Range) u64 {
        return (self.right - self.left) + 1;
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !struct { std.ArrayList(Range), std.ArrayList(u64) } {
    var ranges: std.ArrayList(Range) = .empty;
    errdefer ranges.deinit(allocator);

    var ids: std.ArrayList(u64) = .empty;
    errdefer ids.deinit(allocator);

    var parsing_ranges = true;
    for (input) |line| {
        if (line.len == 0) {
            parsing_ranges = false;
            continue;
        }

        if (parsing_ranges) {
            var parts = std.mem.splitScalar(u8, line, '-');
            const left_str = parts.next() orelse return error.MalformedInput;
            const right_str = parts.next() orelse return error.MalformedInput;
            try ranges.append(allocator, Range{
                .left = try std.fmt.parseInt(u64, left_str, 10),
                .right = try std.fmt.parseInt(u64, right_str, 10),
            });
        } else {
            const id = try std.fmt.parseInt(u64, line, 10);
            try ids.append(allocator, id);
        }
    }

    return .{ ranges, ids };
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var score: u64 = 0;

    var ranges, var ids = try parseInput(allocator, input);

    defer ranges.deinit(allocator);
    defer ids.deinit(allocator);

    for (ids.items) |id| {
        for (ranges.items) |range| {
            if (range.contains(id)) {
                score += 1;
                break;
            }
        }
    }

    return score;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var ranges, var ids = try parseInput(allocator, input);

    defer ranges.deinit(allocator);
    defer ids.deinit(allocator);

    const lambda = struct {
        pub fn lessThanFn(_: void, a: Range, b: Range) bool {
            return a.left < b.left;
        }
    }.lessThanFn;

    std.mem.sort(Range, ranges.items, {}, lambda);

    var ix: usize = 0;
    while (ix < ranges.items.len - 1) {
        const current = &ranges.items[ix];
        const next = &ranges.items[ix + 1];
        if (Range.canMerge(current, next)) {
            current.*.right = @max(current.right, next.right);
            _ = ranges.orderedRemove(ix + 1);
        } else {
            ix += 1;
        }
    }

    var score: u64 = 0;
    for (ranges.items) |range| {
        score += range.count();
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
    const test_input = [_][]const u8{
        "3-5",
        "10-14",
        "16-20",
        "12-18",
        "",
        "1",
        "5",
        "8",
        "11",
        "17",
        "32",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 3), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "3-5",
        "10-14",
        "16-20",
        "12-18",
        "",
        "1",
        "5",
        "8",
        "11",
        "17",
        "32",
    };
    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 14), result);
}
