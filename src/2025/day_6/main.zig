const std = @import("std");
const common_input = @import("common").input;

const Operation = enum {
    Add,
    Multiply,
};

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !struct { std.ArrayList(std.ArrayList(u64)), std.ArrayList(Operation) } {
    var operands: std.ArrayList(std.ArrayList(u64)) = try .initCapacity(allocator, input.len - 1);
    errdefer {
        for (operands.items) |*item| {
            item.deinit(allocator);
        }
        operands.deinit(allocator);
    }

    var operations: std.ArrayList(Operation) = .empty;
    errdefer operations.deinit(allocator);

    {
        for (input[input.len - 1]) |c| {
            switch (c) {
                ' ' => {},
                '+' => try operations.append(allocator, .Add),
                '*' => try operations.append(allocator, .Multiply),
                else => return error.MalformedInput,
            }
        }
    }

    for (input[0 .. input.len - 1]) |line| {
        var tmp: std.ArrayList(u64) = .empty;
        errdefer tmp.deinit(allocator);

        var it = std.mem.tokenizeScalar(u8, line, ' ');

        while (it.next()) |token| {
            const number = try std.fmt.parseInt(u64, token, 10);
            try tmp.append(allocator, number);
        }

        operands.appendAssumeCapacity(tmp);
    }

    // Validate input
    for (operands.items) |*item| {
        if (item.items.len != operations.items.len) {
            return error.MalformedInput;
        }
    }

    return .{ operands, operations };
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var score: u64 = 0;
    score = 0;

    var operands, var operations = try parseInput(allocator, input);
    defer {
        for (operands.items) |*item| {
            item.deinit(allocator);
        }
        operands.deinit(allocator);
        operations.deinit(allocator);
    }

    const problems = operations.items.len;

    for (0..problems) |ix| {
        const operation = operations.items[ix];
        var result: u64 = if (operation == .Add) 0 else 1;

        for (0..operands.items.len) |op_ix| {
            const operand = operands.items[op_ix].items[ix];
            result = switch (operation) {
                .Add => result + operand,
                .Multiply => result * operand,
            };
        }

        score += result;
    }

    return score;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var score: u64 = 0;
    score = 0;

    // Validate input
    for (input[1..]) |line| {
        if (line.len != input[0].len) {
            return error.MalformedInput;
        }
    }

    var ix = input[0].len - 1;
    var numbersBuffer: std.ArrayList(u64) = .empty;
    defer numbersBuffer.deinit(allocator);

    while (true) {
        //build number
        var number: u64 = 0;
        for (input[0 .. input.len - 1]) |line| {
            const c = line[ix];
            switch (c) {
                ' ' => if (number != 0) break else {},
                '0'...'9' => {
                    number = number * 10 + @as(u64, c - '0');
                },
                else => return error.MalformedInput,
            }
        }

        try numbersBuffer.append(allocator, number);

        // check operation
        const op_char = input[input.len - 1][ix];
        switch (op_char) {
            ' ' => {},
            '+' => {
                var sum: u64 = 0;
                for (numbersBuffer.items) |num| {
                    sum += num;
                }
                score += sum;
                numbersBuffer.clearRetainingCapacity();
            },
            '*' => {
                var product: u64 = 1;
                for (numbersBuffer.items) |num| {
                    product *= num;
                }
                score += product;
                numbersBuffer.clearRetainingCapacity();
            },
            else => return error.MalformedInput,
        }

        if (ix == 0) {
            if (numbersBuffer.items.len != 0) {
                return error.MalformedInput;
            } else {
                break;
            }
        } else {
            if (numbersBuffer.items.len == 0) {
                // skip separating column
                ix -= 2;
            } else {
                ix -= 1;
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
    const test_input = [_][]const u8{
        "123 328  51 64 ",
        " 45 64  387 23 ",
        "  6 98  215 314",
        "*   +   *   +  ",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 4277556), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "123 328  51 64 ",
        " 45 64  387 23 ",
        "  6 98  215 314",
        "*   +   *   +  ",
    };
    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 3263827), result);
}
