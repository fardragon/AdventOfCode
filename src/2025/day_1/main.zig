const std = @import("std");
const common_input = @import("common").input;

const Rotation = union(enum) {
    Left: i16,
    Right: i16,
};

fn parseRotations(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Rotation) {
    var rotations = std.ArrayList(Rotation).empty;

    errdefer rotations.deinit(allocator);

    for (input) |line| {
        const count = try std.fmt.parseInt(i16, line[1..], 10);

        if (line[0] == 'L') {
            try rotations.append(allocator, .{ .Left = count });
        } else if (line[0] == 'R') {
            try rotations.append(allocator, .{ .Right = count });
        } else {
            return error.MalformedInput;
        }
    }

    return rotations;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var score: u64 = 0;
    var dial: i16 = 50;

    var rotations = try parseRotations(allocator, input);
    defer rotations.deinit(allocator);

    for (rotations.items) |rotation| {
        if (dial == 0) {
            score += 1;
        }

        dial = dial +
            switch (rotation) {
                .Left => |count| -count,
                .Right => |count| count,
            };

        dial = @mod(dial, 100);
    }

    return score;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var score: u64 = 0;
    var dial: i16 = 50;

    var rotations = try parseRotations(allocator, input);
    defer rotations.deinit(allocator);

    for (rotations.items) |rotation| {
        const new_dial = dial +
            switch (rotation) {
                .Left => |count| -count,
                .Right => |count| count,
            };

        if (new_dial == 0) {
            score += 1;
        } else {
            score += @intCast(@abs(@divTrunc(new_dial, 100)));
            if ((new_dial < 0 and dial > 0) or (dial < 0 and new_dial > 0)) {
                score += 1;
            }
        }

        dial = @mod(new_dial, 100);
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
        "L68",
        "L30",
        "R48",
        "L5",
        "R60",
        "L55",
        "L1",
        "L99",
        "R14",
        "L82",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 3), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "L68",
        "L30",
        "R48",
        "L5",
        "R60",
        "L55",
        "L1",
        "L99",
        "R14",
        "L82",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 6), result);
}
