const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Robot = struct {
    position: struct { isize, isize },
    velocity: struct { isize, isize },
};

fn parseVector(input: []const u8) !struct { isize, isize } {
    var it = std.mem.splitScalar(u8, input, ',');

    const x = it.next();
    const y = it.next();

    if (x == null or y == null) return error.InvalidInput;

    return .{
        try std.fmt.parseInt(isize, x.?, 10),
        try std.fmt.parseInt(isize, y.?, 10),
    };
}

fn parseRobot(input: []const u8) !Robot {
    var it = std.mem.splitScalar(u8, input, ' ');

    const position_vec = it.next();
    const velocity_vec = it.next();

    if (position_vec == null or velocity_vec == null) return error.InvalidInput;

    return Robot{
        .position = try parseVector(position_vec.?[2..]),
        .velocity = try parseVector(velocity_vec.?[2..]),
    };
}

fn parseRobots(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Robot) {
    var robots = std.ArrayList(Robot).init(allocator);
    errdefer robots.deinit();

    for (input) |line| {
        try robots.append(try parseRobot(line));
    }
    return robots;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8, width: isize, height: isize) !u64 {
    const robots = try parseRobots(allocator, input);
    defer robots.deinit();

    const seconds = 100;

    var quadrants: [4]u64 = .{ 0, 0, 0, 0 };

    for (robots.items) |robot| {
        const initial_x, const initial_y = robot.position;
        const velocity_x, const velocity_y = robot.velocity;

        const final_x = @mod(initial_x + velocity_x * seconds, width);
        const final_y = @mod(initial_y + velocity_y * seconds, height);

        const top = final_y < @divFloor(height, 2);
        const bottom = final_y > @divFloor(height, 2);

        const left = final_x < @divFloor(width, 2);
        const right = final_x > @divFloor(width, 2);

        if (top and left) quadrants[0] += 1;
        if (top and right) quadrants[1] += 1;
        if (bottom and right) quadrants[2] += 1;
        if (bottom and left) quadrants[3] += 1;
    }

    return quadrants[0] * quadrants[1] * quadrants[2] * quadrants[3];
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8, width: isize, height: isize) !u64 {
    const robots = try parseRobots(allocator, input);
    defer robots.deinit();

    var grid: []u8 = try allocator.alloc(u8, @intCast(width * height));
    defer allocator.free(grid);

    var seconds: u64 = 0;

    while (true) {
        @memset(grid, ' ');

        for (robots.items) |robot| {
            const initial_x, const initial_y = robot.position;
            const velocity_x, const velocity_y = robot.velocity;

            const final_x = @mod(initial_x + velocity_x * @as(isize, @intCast(seconds)), width);
            const final_y = @mod(initial_y + velocity_y * @as(isize, @intCast(seconds)), height);

            grid[@intCast(final_y * width + final_x)] = '*';
        }

        std.debug.print("\n\r________________________ SECONDS: {d}\n\r", .{seconds});
        for (0..@intCast(height)) |y| {
            for (0..@intCast(width)) |x| {
                const char = grid[y * @as(usize, @intCast(width)) + x];
                std.debug.print("{c}", .{char});
            }
            std.debug.print("\n\r", .{});
        }

        var buf: [10]u8 = undefined;
        if (try std.io.getStdIn().reader().readUntilDelimiterOrEof(buf[0..], '\n')) |user_input| {
            if (std.mem.eql(u8, user_input, "s")) {
                break;
            } else if (std.mem.eql(u8, user_input, "h")) {
                seconds += 99;
            } else if (std.mem.eql(u8, user_input, "t")) {
                seconds += 999;
            } else if (std.mem.eql(u8, user_input, "b")) {
                seconds -= 2;
            }
        }
        seconds += 1;
    }

    return seconds;
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

    std.debug.print("Part 1 solution: {d}\n", .{try solvePart1(allocator, input.items, 101, 103)});
    std.debug.print("Part 2 solution: {d}\n", .{try solvePart2(allocator, input.items, 101, 103)});
}

const test_input = [_][]const u8{
    "p=0,4 v=3,-3",
    "p=6,3 v=-1,-3",
    "p=10,3 v=-1,2",
    "p=2,0 v=2,-1",
    "p=0,0 v=1,3",
    "p=3,0 v=-2,-2",
    "p=7,6 v=-1,-3",
    "p=3,0 v=-1,-2",
    "p=9,3 v=2,3",
    "p=7,3 v=-1,2",
    "p=2,4 v=2,-3",
    "p=9,5 v=-3,-3",
};

test "solve part 1 test" {
    const allocator = std.testing.allocator;
    const result = try solvePart1(allocator, &test_input, 11, 7);

    try std.testing.expectEqual(@as(u64, 12), result);
}

test "solve part 2 test" {
    std.debug.print("WTF\n\r", .{});
}
