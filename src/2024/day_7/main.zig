const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Equation = struct {
    target: u64,
    numbers: std.ArrayList(u64),
};

fn parseEquations(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Equation) {
    var equations = std.ArrayList(Equation).empty;
    errdefer {
        for (equations.items) |*eq| {
            eq.numbers.deinit(allocator);
        }
        equations.deinit(allocator);
    }

    var target: ?u64 = null;

    for (input) |line| {
        var target_split = std.mem.splitScalar(u8, line, ':');

        target = try std.fmt.parseInt(u64, target_split.next().?, 10);
        var numbers = try common.parsing.parseNumbers(u64, allocator, target_split.next().?[1..], ' ');
        errdefer numbers.deinit(allocator);

        try equations.append(
            allocator,
            Equation{
                .target = target.?,
                .numbers = numbers,
            },
        );
    }

    return equations;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var equations = try parseEquations(allocator, input);
    defer {
        for (equations.items) |*eq| {
            eq.numbers.deinit(allocator);
        }
        equations.deinit(allocator);
    }

    var solution: u64 = 0;

    for (equations.items) |equation| {
        const operators_count = equation.numbers.items.len - 1;
        const possibilities = try std.math.powi(u64, 2, operators_count);

        for (0..possibilities) |possibility| {
            var total: u64 = equation.numbers.items[0];

            for (0..operators_count) |ix| {
                const operator = (possibility >> @as(u6, @intCast(ix)) & 1) == 1;
                switch (operator) {
                    true => {
                        total += equation.numbers.items[ix + 1];
                    },
                    false => {
                        total *= equation.numbers.items[ix + 1];
                    },
                }
            }

            if (total == equation.target) {
                solution += total;
                break;
            }
        }
    }

    return solution;
}

fn getTernarySymbol(digit: usize, position: usize) !usize {
    return @mod(digit / try std.math.powi(usize, 3, position), 3);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var equations = try parseEquations(allocator, input);
    defer {
        for (equations.items) |*eq| {
            eq.numbers.deinit(allocator);
        }
        equations.deinit(allocator);
    }

    var solution: u64 = 0;

    for (equations.items) |equation| {
        const operators_count = equation.numbers.items.len - 1;
        const possibilities = try std.math.powi(u64, 3, operators_count);

        for (0..possibilities) |possibility| {
            var total: u64 = equation.numbers.items[0];

            for (0..operators_count) |ix| {
                const operator = try getTernarySymbol(possibility, ix);
                const b = equation.numbers.items[ix + 1];
                switch (operator) {
                    0 => {
                        total += b;
                    },
                    1 => {
                        total *= b;
                    },
                    2 => {
                        const b_digits = if (b == 0) 1 else std.math.log10(b) + 1;
                        total = total * try std.math.powi(u64, 10, b_digits) + b;
                    },
                    else => unreachable,
                }
            }

            if (total == equation.target) {
                solution += total;
                break;
            }
        }
    }

    return solution;
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

const test_input = [_][]const u8{
    "190: 10 19",
    "3267: 81 40 27",
    "83: 17 5",
    "156: 15 6",
    "7290: 6 8 6 15",
    "161011: 16 10 13",
    "192: 17 8 14",
    "21037: 9 7 18 13",
    "292: 11 6 16 20",
};

test "solve part 1 test" {
    const allocator = std.testing.allocator;
    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 3749), result);
}

test "test getTernarySymbol" {
    try std.testing.expectEqual(getTernarySymbol(14, 0), 2);
    try std.testing.expectEqual(getTernarySymbol(14, 1), 1);
    try std.testing.expectEqual(getTernarySymbol(14, 2), 1);
    try std.testing.expectEqual(getTernarySymbol(0, 0), 0);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 11387), result);
}
