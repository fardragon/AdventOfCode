const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Direction = enum {
    up,
    down,
    left,
    right,
};

const Position = common.Pair(i64, i64);

const Instruction = struct {
    dir: Direction,
    steps: u64,
    color: [6]u8,
};

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Instruction) {
    var result = std.ArrayList(Instruction).init(allocator);
    errdefer result.deinit();

    for (input) |line| {
        var current = Instruction{
            .dir = undefined,
            .steps = undefined,
            .color = undefined,
        };

        var it = std.mem.splitScalar(u8, line, ' ');

        //direction
        var dir_str = it.first();
        if (dir_str.len != 1) {
            @panic("Invalid input!");
        }

        current.dir = switch (dir_str[0]) {
            'R' => .right,
            'L' => .left,
            'U' => .up,
            'D' => .down,
            else => unreachable,
        };

        current.steps = try std.fmt.parseInt(u8, it.next().?, 10);

        var color_str = it.next().?;
        @memcpy(&current.color, color_str[2 .. color_str.len - 1]);

        try result.append(current);
    }

    return result;
}

fn perimeter(points: []const Position) u64 {
    return points.len - 1;
}

fn area(points: []const Position) u64 {
    var s1: i128 = 0;
    var s2: i128 = 0;

    for (0..points.len - 1) |ix| {
        s1 += (points[ix].first * points[ix + 1].second);
        s2 += (points[ix + 1].first * points[ix].second);
    }

    const result_area = std.math.absCast(s1 - s2) / 2;
    const perim = perimeter(points);
    return @truncate(result_area - perim / 2 + 1);
}

fn solve(allocator: std.mem.Allocator, instructions: []const Instruction) !u64 {
    var points = std.ArrayList(Position).init(allocator);
    defer points.deinit();

    var position = Position{ .first = 0, .second = 0 };
    try points.append(position);

    for (instructions) |instruction| {
        for (0..instruction.steps) |_| {
            switch (instruction.dir) {
                .right => {
                    position.first += 1;
                },
                .left => {
                    position.first -= 1;
                },
                .up => {
                    position.second -= 1;
                },
                .down => {
                    position.second += 1;
                },
            }
            try points.append(position);
        }
    }

    return area(points.items) + perimeter(points.items);
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var instructions = try parseInput(allocator, input);
    defer instructions.deinit();

    return solve(allocator, instructions.items);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var instructions = try parseInput(allocator, input);
    defer instructions.deinit();

    //fix instructions

    for (instructions.items) |*instruction| {
        instruction.*.steps = try std.fmt.parseInt(u64, instruction.color[0..5], 16);
        instruction.*.dir = switch (instruction.color[5]) {
            '0' => .right,
            '1' => .down,
            '2' => .left,
            '3' => .up,
            else => unreachable,
        };
    }

    return solve(allocator, instructions.items);
}

pub fn main() !void {
    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = GPA.allocator();

    defer _ = GPA.deinit();

    const input = try common_input.readFileInput(allocator, "input.txt");
    defer {
        for (input.items) |item| {
            allocator.free(item);
        }
        input.deinit();
    }

    std.debug.print("Part 1 solution: {d}\n", .{try solvePart1(allocator, input.items)});
    std.debug.print("Part 2 solution: {d}\n", .{try solvePart2(allocator, input.items)});
}

test "solve part 1 test" {
    const test_input = [_][]const u8{
        "R 6 (#70c710)",
        "D 5 (#0dc571)",
        "L 2 (#5713f0)",
        "D 2 (#d2c081)",
        "R 2 (#59c680)",
        "D 2 (#411b91)",
        "L 5 (#8ceee2)",
        "U 2 (#caa173)",
        "L 1 (#1b58a2)",
        "U 2 (#caa171)",
        "R 2 (#7807d2)",
        "U 3 (#a77fa3)",
        "L 2 (#015232)",
        "U 2 (#7a21e3)",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 62), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "R 6 (#70c710)",
        "D 5 (#0dc571)",
        "L 2 (#5713f0)",
        "D 2 (#d2c081)",
        "R 2 (#59c680)",
        "D 2 (#411b91)",
        "L 5 (#8ceee2)",
        "U 2 (#caa173)",
        "L 1 (#1b58a2)",
        "U 2 (#caa171)",
        "R 2 (#7807d2)",
        "U 3 (#a77fa3)",
        "L 2 (#015232)",
        "U 2 (#7a21e3)",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 952408144115), result);
}
