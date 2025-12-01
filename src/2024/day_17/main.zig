const std = @import("std");
const common = @import("common");
const common_input = common.input;

const OpCode = union(enum) {
    adv,
    bxl,
    bst,
    jnz,
    bxc,
    out,
    bdv,
    cdv,
};

const Instruction = struct {
    opcode: OpCode,
    operand: u8,
};

const RegisterType = u64;
const Registers = struct {
    A: RegisterType,
    B: RegisterType,
    C: RegisterType,
};

fn parseRegister(input: []const u8) !RegisterType {
    if (std.mem.indexOf(u8, input, ": ")) |ix| {
        return try std.fmt.parseInt(RegisterType, input[ix + 2 ..], 10);
    } else return error.MalformedInput;
}

fn parseProgram(allocator: std.mem.Allocator, input: []const u8) !struct { std.ArrayList(Instruction), std.ArrayList(u8) } {
    if (std.mem.indexOf(u8, input, "Program: ")) |_| {
        var instructions = std.ArrayList(Instruction).empty;
        errdefer instructions.deinit(allocator);
        var numbers = try common.parsing.parseNumbers(u8, allocator, input[9..], ',');
        errdefer numbers.deinit(allocator);
        if (numbers.items.len % 2 != 0) return error.MalformedInput;

        var ix: usize = 0;
        while (ix < numbers.items.len) : (ix += 2) {
            const opcode: OpCode = switch (numbers.items[ix]) {
                0 => .adv,
                1 => .bxl,
                2 => .bst,
                3 => .jnz,
                4 => .bxc,
                5 => .out,
                6 => .bdv,
                7 => .cdv,
                else => return error.InvalidOpCode,
            };
            try instructions.append(allocator, Instruction{
                .opcode = opcode,
                .operand = numbers.items[ix + 1],
            });
        }
        return .{ instructions, numbers };
    } else return error.MalformedInput;
}

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !struct { Registers, struct { std.ArrayList(Instruction), std.ArrayList(u8) } } {
    return .{
        Registers{
            .A = try parseRegister(input[0]),
            .B = try parseRegister(input[1]),
            .C = try parseRegister(input[2]),
        },
        try parseProgram(allocator, input[4]),
    };
}

fn getComboOperand(registers: Registers, operand: u8) !RegisterType {
    return switch (operand) {
        0...3 => |op| op,
        4 => registers.A,
        5 => registers.B,
        6 => registers.C,
        else => error.InvalidComboOperand,
    };
}

fn division(registers: Registers, operand: u8) !RegisterType {
    const numerator = registers.A;
    const combo_operand = try getComboOperand(registers, operand);
    const denominator = try std.math.powi(RegisterType, 2, combo_operand);
    return @divTrunc(numerator, denominator);
}

fn runProgram(allocator: std.mem.Allocator, initial_registers: Registers, instructions: []const Instruction) !std.ArrayList(u8) {
    var registers = initial_registers;
    var instruction_pointer: usize = 0;

    var output = std.ArrayList(u8).empty;
    errdefer output.deinit(allocator);

    while (instruction_pointer < instructions.len) {
        const current_instruction = instructions[instruction_pointer];
        switch (current_instruction.opcode) {
            .adv => {
                registers.A = try division(registers, current_instruction.operand);
            },
            .bxl => {
                registers.B = registers.B ^ current_instruction.operand;
            },
            .bst => {
                registers.B = @mod(try getComboOperand(registers, current_instruction.operand), 8);
            },
            .jnz => {
                if (registers.A != 0) {
                    instruction_pointer = current_instruction.operand;
                    continue;
                }
            },
            .bxc => {
                registers.B = registers.B ^ registers.C;
            },
            .out => {
                const operand = try getComboOperand(registers, current_instruction.operand);
                try output.append(allocator, @truncate(@mod(operand, 8)));
            },
            .bdv => {
                registers.B = try division(registers, current_instruction.operand);
            },
            .cdv => {
                registers.C = try division(registers, current_instruction.operand);
            },
        }
        instruction_pointer += 1;
    }

    return output;
}

fn calculateResult(output: []const u8) u64 {
    var result: u64 = 0;

    for (output) |out| {
        result = result * 10 + out;
    }

    return result;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    const registers, const program = try parseInput(allocator, input);
    var instructions, var raw_program = program;
    defer {
        instructions.deinit(allocator);
        raw_program.deinit(allocator);
    }

    var output = try runProgram(allocator, registers, instructions.items);
    defer output.deinit(allocator);

    return calculateResult(output.items);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    const registers, const program = try parseInput(allocator, input);
    var instructions, var raw_program = program;
    defer {
        instructions.deinit(allocator);
        raw_program.deinit(allocator);
    }

    const QueueState = struct {
        offset: u64,
        value: u64,

        fn compare(_: void, a: @This(), b: @This()) std.math.Order {
            return std.math.order(a.value, b.value);
        }
    };
    var queue = std.PriorityQueue(QueueState, void, QueueState.compare).init(allocator, {});
    defer queue.deinit();

    try queue.add(QueueState{
        .offset = raw_program.items.len - 1,
        .value = 0,
    });

    while (queue.items.len > 0) {
        const current_state = queue.remove();
        for (0..8) |current_candidate| {
            const candidate = (current_state.value << 3) + current_candidate;
            var result = try runProgram(
                allocator,
                Registers{
                    .A = candidate,
                    .B = registers.B,
                    .C = registers.C,
                },
                instructions.items,
            );
            defer result.deinit(allocator);

            if (std.mem.eql(u8, result.items, raw_program.items[current_state.offset..])) {
                if (current_state.offset == 0) return candidate;
                try queue.add(QueueState{
                    .offset = current_state.offset - 1,
                    .value = candidate,
                });
            }
        }
    }

    return error.NoSolution;
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
        "Register A: 729",
        "Register B: 0",
        "Register C: 0",
        "",
        "Program: 0,1,5,4,3,0",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 4635635210), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "Register A: 2024",
        "Register B: 0",
        "Register C: 0",
        "",
        "Program: 0,3,5,4,3,0",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 117440), result);
}
