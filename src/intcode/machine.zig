const std = @import("std");

pub const T = i64;

const ParameterMode = enum(u8) {
    Position = 0,
    Immediate = 1,
};

fn OpCodeBase(comptime parameters: usize) type {
    return struct {
        parameters: usize,
        modes: [parameters]ParameterMode,

        fn init(val: T) @This() {
            var res: @This() = undefined;
            var modes = @divTrunc(val, 100);

            res.parameters = parameters;
            for (0..parameters) |ix| {
                res.modes[ix] = @enumFromInt(@mod(modes, 10));
                modes = @divTrunc(modes, 10);
            }

            return res;
        }

        fn getParameter(self: @This(), position: usize, ip: usize, memory: []const T) !T {
            return switch (self.modes[position]) {
                .Position => memory[@intCast(memory[ip + position + 1])],
                .Immediate => memory[ip + position + 1],
            };
        }

        fn getIndex(self: @This(), position: usize, ip: usize, memory: []const T) !usize {
            const idx = switch (self.modes[position]) {
                .Position => memory[ip + position + 1],
                .Immediate => return error.ImmediateIndex,
            };
            if (idx < 0) return error.NegativeIndex;
            return @intCast(idx);
        }
    };
}

const OpCode = union(enum) {
    Add: OpCodeBase(3),
    Multiply: OpCodeBase(3),
    Halt: OpCodeBase(0),
    Input: OpCodeBase(1),
    Output: OpCodeBase(1),
    JumpTrue: OpCodeBase(2),
    JumpFalse: OpCodeBase(2),
    LessThan: OpCodeBase(3),
    Equals: OpCodeBase(3),

    fn parse(val: T) !OpCode {
        return switch (@mod(val, 100)) {
            1 => OpCode{ .Add = .init(val) },
            2 => OpCode{ .Multiply = .init(val) },
            3 => OpCode{ .Input = .init(val) },
            4 => OpCode{ .Output = .init(val) },
            5 => OpCode{ .JumpTrue = .init(val) },
            6 => OpCode{ .JumpFalse = .init(val) },
            7 => OpCode{ .LessThan = .init(val) },
            8 => OpCode{ .Equals = .init(val) },
            99 => OpCode{ .Halt = .init(val) },
            else => return error.UnknownOpcode,
        };
    }
};

pub fn runProgram(allocator: std.mem.Allocator, memory: []T, input: ?[]const T) !std.ArrayList(T) {
    var ip: usize = 0;
    var output = std.ArrayList(T).empty;
    errdefer output.deinit(allocator);
    var remaining_input = if (input != null) input.? else &.{};

    prog: while (true) {
        const op = try OpCode.parse(memory[ip]);

        switch (op) {
            .Add, .Multiply => |opb| {
                const a = try opb.getParameter(0, ip, memory);
                const b = try opb.getParameter(1, ip, memory);
                const dest = try opb.getIndex(2, ip, memory);
                if (op == .Add) {
                    memory[dest] = a + b;
                } else if (op == .Multiply) {
                    memory[dest] = a * b;
                } else unreachable;
                ip += 4;
            },
            .Input => |opb| {
                const dest = try opb.getIndex(0, ip, memory);
                if (dest < 0) return error.NegativeIndex;
                if (remaining_input.len == 0) {
                    return error.MissingInput;
                }
                memory[@intCast(dest)] = remaining_input[0];
                remaining_input = remaining_input[1..];
                ip += 2;
            },
            .Output => |opb| {
                const out = try opb.getParameter(0, ip, memory);
                try output.append(allocator, out);
                ip += 2;
            },
            .JumpTrue, .JumpFalse => |opb| {
                const arg = try opb.getParameter(0, ip, memory);
                const target = try opb.getParameter(1, ip, memory);
                if ((op == .JumpTrue and arg != 0) or (op == .JumpFalse and arg == 0)) {
                    ip = @intCast(target);
                } else {
                    ip += 3;
                }
            },
            .LessThan, .Equals => |opb| {
                const a = try opb.getParameter(0, ip, memory);
                const b = try opb.getParameter(1, ip, memory);
                const dest = try opb.getIndex(2, ip, memory);
                if (op == .Equals) {
                    memory[dest] = if (a == b) 1 else 0;
                } else if (op == .LessThan) {
                    memory[dest] = if (a < b) 1 else 0;
                } else unreachable;
                ip += 4;
            },
            .Halt => |_| break :prog,
        }
    }

    return output;
}

pub fn parseMemory(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(T) {
    var result = std.ArrayList(T).empty;
    errdefer result.deinit(allocator);

    var it = std.mem.splitScalar(u8, input, ',');

    while (it.next()) |val| {
        try result.append(allocator, try std.fmt.parseInt(T, val, 10));
    }

    return result;
}

test "test add & multiply" {
    {
        var memory = [_]T{ 1, 9, 10, 3, 2, 3, 11, 0, 99, 30, 40, 50 };
        const expected = [_]T{ 3500, 9, 10, 70, 2, 3, 11, 0, 99, 30, 40, 50 };
        _ = try runProgram(std.testing.allocator, &memory, null);

        try std.testing.expectEqual(expected, memory);
    }

    {
        var memory = [_]T{ 1, 0, 0, 0, 99 };
        const expected = [_]T{ 2, 0, 0, 0, 99 };
        _ = try runProgram(std.testing.allocator, &memory, null);

        try std.testing.expectEqual(expected, memory);
    }
    {
        var memory = [_]T{ 2, 3, 0, 3, 99 };
        const expected = [_]T{ 2, 3, 0, 6, 99 };
        _ = try runProgram(std.testing.allocator, &memory, null);

        try std.testing.expectEqual(expected, memory);
    }
    {
        var memory = [_]T{ 2, 4, 4, 5, 99, 0 };
        const expected = [_]T{ 2, 4, 4, 5, 99, 9801 };
        _ = try runProgram(std.testing.allocator, &memory, null);

        try std.testing.expectEqual(expected, memory);
    }
    {
        var memory = [_]T{ 1, 1, 1, 4, 99, 5, 6, 0, 99 };
        const expected = [_]T{ 30, 1, 1, 4, 2, 5, 6, 0, 99 };
        _ = try runProgram(std.testing.allocator, &memory, null);

        try std.testing.expectEqual(expected, memory);
    }
}

fn runSingleValueTest(memory: []const T, input_value: T, expected_output: T) !void {
    const input = [_]T{input_value};

    const mut_memory = try std.testing.allocator.dupe(T, memory);
    defer std.testing.allocator.free(mut_memory);

    var output = try runProgram(std.testing.allocator, mut_memory, &input);
    defer output.deinit(std.testing.allocator);

    return std.testing.expectEqualSlices(T, &.{expected_output}, output.items);
}

test "test input & output" {
    var program = [_]T{ 3, 0, 4, 0, 99 };
    try runSingleValueTest(&program, 2137, 2137);
}

test "test comparison" {
    // Equals position mode
    // O = 1 if I == 8 else O = 0
    {
        var program = [_]T{ 3, 9, 8, 9, 10, 9, 4, 9, 99, -1, 8 };
        try runSingleValueTest(&program, 8, 1);
        try runSingleValueTest(&program, 7, 0);
        try runSingleValueTest(&program, 9, 0);
    }

    // Less than position mode
    // O = 1 if I < 8 else O = 0
    {
        var program = [_]T{ 3, 9, 7, 9, 10, 9, 4, 9, 99, -1, 8 };
        try runSingleValueTest(&program, 8, 0);
        try runSingleValueTest(&program, 7, 1);
        try runSingleValueTest(&program, 0, 1);
    }

    // Equals immediate mode
    // O = 1 if I == 8 else O = 0
    {
        var program = [_]T{ 3, 3, 1108, -1, 8, 3, 4, 3, 99 };
        try runSingleValueTest(&program, 8, 1);
        try runSingleValueTest(&program, 7, 0);
        try runSingleValueTest(&program, 9, 0);
    }

    // Less than immediate mode
    // O = 1 if I < 8 else O = 0
    {
        var program = [_]T{ 3, 3, 1107, -1, 8, 3, 4, 3, 99 };
        try runSingleValueTest(&program, 8, 0);
        try runSingleValueTest(&program, 7, 1);
        try runSingleValueTest(&program, 0, 1);
    }
}

test "test jumps" {
    // Position mode
    // O = 0 if I == 0 | O = 1 if I != 0
    {
        var program = [_]T{ 3, 12, 6, 12, 15, 1, 13, 14, 13, 4, 13, 99, -1, 0, 1, 9 };
        try runSingleValueTest(&program, 0, 0);
        try runSingleValueTest(&program, 1, 1);
        try runSingleValueTest(&program, 2137, 1);
    }

    // Immediate mode
    // O = 0 if I == 0 | O = 1 if I != 0
    {
        var program = [_]T{ 3, 3, 1105, -1, 9, 1101, 0, 0, 12, 4, 12, 99, 1 };
        try runSingleValueTest(&program, 0, 0);
        try runSingleValueTest(&program, 1, 1);
        try runSingleValueTest(&program, 2137, 1);
    }
}

test "misc tests" {
    // O = 999 if I < 8 && O = 1000 if I == 8 && O = 1001 if I > 8
    {
        var program = [_]T{ 3, 21, 1008, 21, 8, 20, 1005, 20, 22, 107, 8, 21, 20, 1006, 20, 31, 1106, 0, 36, 98, 0, 0, 1002, 21, 125, 20, 4, 20, 1105, 1, 46, 104, 999, 1105, 1, 46, 1101, 1000, 1, 20, 4, 20, 1105, 1, 46, 98, 99 };
        try runSingleValueTest(&program, 0, 999);
        try runSingleValueTest(&program, 8, 1000);
        try runSingleValueTest(&program, 9, 1001);
    }
}
