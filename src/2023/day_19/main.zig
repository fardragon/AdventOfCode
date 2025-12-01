const std = @import("std");
const common = @import("common");
const common_input = common.input;
const String = common.String;

const Operation = enum {
    GT,
    LT,
};

const Rule = struct {
    variable: u8,
    op: Operation,
    value: u64,
    target: String,

    fn deinit(self: *Rule) void {
        self.target.deinit();
    }
};

const Instruction = struct {
    rules: std.ArrayList(Rule),
    default: String,

    fn deinit(self: *Instruction, allocator: std.mem.Allocator) void {
        for (self.rules.items) |*rule| {
            rule.deinit();
        }
        self.rules.deinit(allocator);
        self.default.deinit();
    }
};

const Part = struct {
    ratings: [4]u64,

    fn rating(self: Part) u64 {
        var result: u64 = 0;
        for (self.ratings) |r| {
            result += r;
        }
        return result;
    }
};

const PartRange = struct {
    ranges: [4][2]u64,

    fn combinations(self: PartRange) u64 {
        var result: u64 = 1;
        for (self.ranges) |r| {
            result *= (r[1] - r[0] + 1);
        }
        return result;
    }
};

const Puzzle = struct {
    instructions: std.StringHashMap(Instruction),
    parts: std.ArrayList(Part),
};

fn parseInstruction(allocator: std.mem.Allocator, instruction_str: []const u8) !Instruction {
    var result = Instruction{
        .rules = std.ArrayList(Rule).empty,
        .default = undefined,
    };
    errdefer result.deinit(allocator);

    var it = std.mem.splitScalar(u8, instruction_str, ',');

    while (it.next()) |part| {
        const colon = std.mem.indexOfScalar(u8, part, ':');

        if (colon) |col| {
            var rule = Rule{
                .variable = switch (part[0]) {
                    'x' => 0,
                    'm' => 1,
                    'a' => 2,
                    's' => 3,
                    else => unreachable,
                },
                .op = switch (part[1]) {
                    '>' => .GT,
                    '<' => .LT,
                    else => unreachable,
                },
                .value = try std.fmt.parseInt(u64, part[2..col], 10),
                .target = try String.init(allocator, part[col + 1 .. part.len]),
            };

            errdefer rule.deinit();
            try result.rules.append(allocator, rule);
        } else {
            result.default = try String.init(allocator, part);
        }
    }

    return result;
}

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !Puzzle {
    var instructions = std.StringHashMap(Instruction).init(allocator);
    errdefer {
        var it = instructions.valueIterator();
        while (it.next()) |ins| {
            ins.deinit(allocator);
        }
        instructions.deinit();
    }

    var sep: usize = 0;
    for (input, 0..) |line, ix| {
        if (line.len == 0) {
            sep = ix;
            break;
        }

        // find opening brace
        const lbrace = std.mem.indexOfScalar(u8, line, '{').?;
        const instruction_name = line[0..lbrace];

        var ins = try parseInstruction(allocator, line[lbrace + 1 .. line.len - 1]);
        errdefer ins.deinit(allocator);

        try instructions.put(instruction_name, ins);
    }

    var parts = std.ArrayList(Part).empty;
    errdefer parts.deinit(allocator);

    if (sep == 0) return error.InvalidInput;

    for (input[sep + 1 .. input.len]) |line| {
        var it = std.mem.splitScalar(u8, line[1 .. line.len - 1], ',');

        var res_part = Part{
            .ratings = undefined,
        };

        while (it.next()) |part| {
            switch (part[0]) {
                'x' => {
                    res_part.ratings[0] = try std.fmt.parseInt(u64, part[2..part.len], 10);
                },
                'm' => {
                    res_part.ratings[1] = try std.fmt.parseInt(u64, part[2..part.len], 10);
                },
                'a' => {
                    res_part.ratings[2] = try std.fmt.parseInt(u64, part[2..part.len], 10);
                },
                's' => {
                    res_part.ratings[3] = try std.fmt.parseInt(u64, part[2..part.len], 10);
                },
                else => unreachable,
            }
        }
        try parts.append(allocator, res_part);
    }

    return Puzzle{
        .instructions = instructions,
        .parts = parts,
    };
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var puzzle = try parseInput(allocator, input);
    defer {
        var it = puzzle.instructions.valueIterator();
        while (it.next()) |ins| {
            ins.deinit(allocator);
        }
        puzzle.instructions.deinit();
        puzzle.parts.deinit(allocator);
    }

    var accepted_parts = std.ArrayList(Part).empty;
    defer accepted_parts.deinit(allocator);

    for (puzzle.parts.items) |part| {
        var current_instruction = puzzle.instructions.getPtr("in").?;

        outer: while (true) {
            for (current_instruction.*.rules.items) |rule| {
                const val = part.ratings[rule.variable];

                const matches = switch (rule.op) {
                    .GT => val > rule.value,
                    .LT => val < rule.value,
                };
                if (matches) {
                    if (std.mem.eql(u8, rule.target.str, "A")) {
                        try accepted_parts.append(allocator, part);
                        break :outer;
                    } else if (std.mem.eql(u8, rule.target.str, "R")) {
                        break :outer;
                    } else {
                        current_instruction = puzzle.instructions.getPtr(rule.target.str).?;
                        continue :outer;
                    }
                }
            }
            if (std.mem.eql(u8, current_instruction.*.default.str, "A")) {
                try accepted_parts.append(allocator, part);
                break;
            } else if (std.mem.eql(u8, current_instruction.*.default.str, "R")) {
                break;
            } else {
                current_instruction = puzzle.instructions.getPtr(current_instruction.*.default.str).?;
            }
        }
    }

    var result: u64 = 0;

    for (accepted_parts.items) |part| {
        result += part.rating();
    }

    return result;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var puzzle = try parseInput(allocator, input);
    defer {
        var it = puzzle.instructions.valueIterator();
        while (it.next()) |ins| {
            ins.deinit(allocator);
        }
        puzzle.instructions.deinit();
        puzzle.parts.deinit(allocator);
    }

    var accepted_ranges = std.ArrayList(PartRange).empty;
    defer accepted_ranges.deinit(allocator);

    const QueueElement = common.Pair(PartRange, []const u8);
    var queue = std.ArrayList(QueueElement).empty;
    defer queue.deinit(allocator);

    try queue.append(allocator, QueueElement{
        .first = PartRange{
            .ranges = .{
                .{ 1, 4000 },
                .{ 1, 4000 },
                .{ 1, 4000 },
                .{ 1, 4000 },
            },
        },
        .second = "in",
    });

    while (queue.pop()) |elem| {
        var current_range = elem.first;
        const current_instruction_str = elem.second;

        if (std.mem.eql(u8, current_instruction_str, "A")) {
            try accepted_ranges.append(allocator, current_range);
            continue;
        } else if (std.mem.eql(u8, current_instruction_str, "R")) {
            continue;
        }

        const current_instruction = puzzle.instructions.getPtr(current_instruction_str).?;

        outer: for (current_instruction.rules.items) |current_rule| {
            const variable_range = current_range.ranges[current_rule.variable];

            const cutoff = current_rule.value;
            const target_instruction = current_rule.target.str;

            switch (current_rule.op) {
                .LT => {
                    if (variable_range[1] < cutoff) {
                        try queue.append(
                            allocator,
                            QueueElement{
                                .first = current_range,
                                .second = target_instruction,
                            },
                        );
                        break :outer;
                    }

                    if ((variable_range[0] < cutoff) and (cutoff <= variable_range[1])) {
                        var new_range = current_range;
                        new_range.ranges[current_rule.variable] = .{
                            variable_range[0],
                            cutoff - 1,
                        };

                        try queue.append(
                            allocator,
                            QueueElement{
                                .first = new_range,
                                .second = target_instruction,
                            },
                        );

                        current_range.ranges[current_rule.variable] = .{
                            cutoff,
                            variable_range[1],
                        };
                    }
                },

                .GT => {
                    if (variable_range[0] > cutoff) {
                        try queue.append(
                            allocator,
                            QueueElement{
                                .first = current_range,
                                .second = target_instruction,
                            },
                        );
                        break :outer;
                    }

                    if ((variable_range[0] <= cutoff) and (cutoff < variable_range[1])) {
                        var new_range = current_range;
                        new_range.ranges[current_rule.variable] = .{
                            cutoff + 1,
                            variable_range[1],
                        };

                        try queue.append(
                            allocator,
                            QueueElement{
                                .first = new_range,
                                .second = target_instruction,
                            },
                        );

                        current_range.ranges[current_rule.variable] = .{
                            variable_range[0],
                            cutoff,
                        };
                    }
                },
            }
        }
        try queue.append(
            allocator,
            QueueElement{
                .first = current_range,
                .second = current_instruction.*.default.str,
            },
        );
    }

    var result: u64 = 0;
    for (accepted_ranges.items) |range| {
        result += range.combinations();
    }

    return result;
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
    const test_input = [_][]const u8{
        "px{a<2006:qkq,m>2090:A,rfg}",
        "pv{a>1716:R,A}",
        "lnx{m>1548:A,A}",
        "rfg{s<537:gd,x>2440:R,A}",
        "qs{s>3448:A,lnx}",
        "qkq{x<1416:A,crn}",
        "crn{x>2662:A,R}",
        "in{s<1351:px,qqz}",
        "qqz{s>2770:qs,m<1801:hdj,R}",
        "gd{a>3333:R,R}",
        "hdj{m>838:A,pv}",
        "",
        "{x=787,m=2655,a=1222,s=2876}",
        "{x=1679,m=44,a=2067,s=496}",
        "{x=2036,m=264,a=79,s=2244}",
        "{x=2461,m=1339,a=466,s=291}",
        "{x=2127,m=1623,a=2188,s=1013}",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 19114), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "px{a<2006:qkq,m>2090:A,rfg}",
        "pv{a>1716:R,A}",
        "lnx{m>1548:A,A}",
        "rfg{s<537:gd,x>2440:R,A}",
        "qs{s>3448:A,lnx}",
        "qkq{x<1416:A,crn}",
        "crn{x>2662:A,R}",
        "in{s<1351:px,qqz}",
        "qqz{s>2770:qs,m<1801:hdj,R}",
        "gd{a>3333:R,R}",
        "hdj{m>838:A,pv}",
        "",
        "{x=787,m=2655,a=1222,s=2876}",
        "{x=1679,m=44,a=2067,s=496}",
        "{x=2036,m=264,a=79,s=2244}",
        "{x=2461,m=1339,a=466,s=291}",
        "{x=2127,m=1623,a=2188,s=1013}",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 167409079868000), result);
}
