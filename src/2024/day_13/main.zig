const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Machine = struct {
    button_a: struct { isize, isize },
    button_b: struct { isize, isize },
    prize: struct { isize, isize },
};

fn parseButton(input: []const u8, button_name: u8) !struct { isize, isize } {
    var button_prefix = [_]u8{ 'B', 'u', 't', 't', 'o', 'n', ' ', button_name, ':', ' ' };

    if (!std.mem.startsWith(u8, input, &button_prefix)) return error.InvalidInput;
    var it = std.mem.splitSequence(u8, input[9..], ", ");

    const left = it.next();
    const right = it.next();

    if (left == null or right == null) return error.InvalidInput;

    return .{
        try std.fmt.parseInt(isize, left.?[2..], 10),
        try std.fmt.parseInt(isize, right.?[2..], 10),
    };
}

fn parsePrize(input: []const u8) !struct { isize, isize } {
    if (!std.mem.startsWith(u8, input, "Prize: ")) return error.InvalidInput;
    var it = std.mem.splitSequence(u8, input[7..], ", ");

    const left = it.next();
    const right = it.next();

    if (left == null or right == null) return error.InvalidInput;

    return .{
        try std.fmt.parseInt(isize, left.?[2..], 10),
        try std.fmt.parseInt(isize, right.?[2..], 10),
    };
}

fn parseMachines(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Machine) {
    var machines = std.ArrayList(Machine).empty;
    errdefer machines.deinit(allocator);

    var ix: usize = 0;
    while (ix < input.len) {
        try machines.append(
            allocator,
            Machine{
                .button_a = try parseButton(input[ix], 'A'),
                .button_b = try parseButton(input[ix + 1], 'B'),
                .prize = try parsePrize(input[ix + 2]),
            },
        );

        ix += 4;
    }

    return machines;
}

fn solveMachine(machine: Machine) ?struct { isize, isize } {
    const p_x, const p_y = machine.prize;
    const a_x, const a_y = machine.button_a;
    const b_x, const b_y = machine.button_b;

    const det = a_x * b_y - a_y * b_x;
    if (det == 0) return null;

    const A = @divFloor(p_x * b_y - p_y * b_x, det);
    const B = @divFloor(a_x * p_y - a_y * p_x, det);

    if (A * a_x + B * b_x == p_x and A * a_y + B * b_y == p_y) {
        return .{ A, B };
    } else {
        return null;
    }
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var machines = try parseMachines(allocator, input);
    defer machines.deinit(allocator);

    var cost: u64 = 0;

    for (machines.items) |machine| {
        if (solveMachine(machine)) |solution| {
            const A, const B = solution;
            cost += @intCast(3 * A + B);
        }
    }

    return cost;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var machines = try parseMachines(allocator, input);
    defer machines.deinit(allocator);

    var cost: u64 = 0;

    for (machines.items) |machine| {
        const p_x, const p_y = machine.prize;
        if (solveMachine(Machine{
            .button_a = machine.button_a,
            .button_b = machine.button_b,
            .prize = .{ p_x + 10000000000000, p_y + 10000000000000 },
        })) |solution| {
            const A, const B = solution;
            cost += @intCast(3 * A + B);
        }
    }

    return cost;
}

pub fn main() !void {
    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = GPA.allocator();

    defer _ = GPA.deinit();

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

const test_input = [_][]const u8{
    "Button A: X+94, Y+34",
    "Button B: X+22, Y+67",
    "Prize: X=8400, Y=5400",
    "",
    "Button A: X+26, Y+66",
    "Button B: X+67, Y+21",
    "Prize: X=12748, Y=12176",
    "",
    "Button A: X+17, Y+86",
    "Button B: X+84, Y+37",
    "Prize: X=7870, Y=6450",
    "",
    "Button A: X+69, Y+23",
    "Button B: X+27, Y+71",
    "Prize: X=18641, Y=10279",
};

test "solve part 1 test" {
    const allocator = std.testing.allocator;
    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 480), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 875318608908), result);
}
