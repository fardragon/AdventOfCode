const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Wires = std.AutoHashMap([3]u8, bool);
const GateType = enum {
    AND,
    OR,
    XOR,
};

const Gate = struct {
    A: [3]u8,
    B: [3]u8,
    type: GateType,
    value: ?bool,
};
const Gates = std.AutoHashMap([3]u8, Gate);

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !struct { Wires, Gates } {
    var wires = Wires.init(allocator);
    errdefer wires.deinit();

    var gates = Gates.init(allocator);
    errdefer gates.deinit();

    var parsing_inputs = true;
    for (input) |line| {
        if (line.len == 0) {
            parsing_inputs = false;
            continue;
        }

        if (parsing_inputs) {
            var it = std.mem.splitSequence(u8, line, ": ");
            const wire = it.next();
            const value = it.next();

            if (wire == null or value == null) return error.InvalidInput;

            const wire_key: [3]u8 = .{ wire.?[0], wire.?[1], wire.?[2] };
            try wires.put(wire_key, value.?[0] == '1');
        } else {
            var it = std.mem.splitScalar(u8, line, ' ');
            var a = it.next();
            const op = it.next();
            var b = it.next();
            _ = it.next();
            const wire = it.next();

            if (a == null or op == null or b == null or wire == null) return error.InvalidInput;

            if (a.?[0] == 'y' and b.?[0] == 'x') {
                const tmp = a.?;
                a = b;
                b = tmp;
            }

            const gate = Gate{
                .A = .{ a.?[0], a.?[1], a.?[2] },
                .B = .{ b.?[0], b.?[1], b.?[2] },
                .type = switch (op.?[0]) {
                    'O' => GateType.OR,
                    'A' => GateType.AND,
                    'X' => GateType.XOR,
                    else => return error.InvalidInput,
                },
                .value = null,
            };

            const wire_key: [3]u8 = .{ wire.?[0], wire.?[1], wire.?[2] };
            try gates.put(wire_key, gate);
        }
    }

    return .{
        wires,
        gates,
    };
}

fn getGateValue(gates: Gates, wires: Wires, gate: *Gate) !bool {
    if (gate.value) |value| {
        return value;
    }

    const a = if (gates.getPtr(gate.A)) |a_gate| try getGateValue(gates, wires, a_gate) else if (wires.get(gate.A)) |value| value else return error.InvalidInput;
    const b = if (gates.getPtr(gate.B)) |b_gate| try getGateValue(gates, wires, b_gate) else if (wires.get(gate.B)) |value| value else return error.InvalidInput;

    const result = switch (gate.type) {
        .AND => a and b,
        .OR => a or b,
        .XOR => a != b,
    };

    gate.*.value = result;
    return result;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var wires, var gates = try parseInput(allocator, input);
    defer wires.deinit();
    defer gates.deinit();

    var bitset = std.StaticBitSet(64).initEmpty();
    for (0..64) |zi| {
        var buf: [3]u8 = undefined;
        _ = try std.fmt.bufPrint(&buf, "z{:0>2}", .{zi});

        if (gates.getPtr(buf)) |gate| {
            const bit_val = try getGateValue(gates, wires, gate);
            bitset.setValue(zi, bit_val);
        } else {
            break;
        }
    }

    var result: u64 = 0;
    var ix: isize = 63;
    while (ix >= 0) : (ix -= 1) {
        result = result << 1;
        if (bitset.isSet(@intCast(ix))) {
            result = result | @as(u64, 1);
        }
    }

    return result;
}

fn gatesEqual(g1: [3]u8, g2: [3]u8) bool {
    return (g1[0] == g2[0]) and (g1[1] == g2[1]) and (g1[2] == g2[2]);
}

fn prepare_result(allocator: std.mem.Allocator, r: common.AutoHashSet([3]u8)) ![]u8 {
    const result_length = (r.count() * 3) + (r.count() - 1);

    var result = try allocator.alloc(u8, result_length);
    errdefer allocator.free(result);

    const nodes = try allocator.alloc([3]u8, r.count());
    defer allocator.free(nodes);

    {
        var it = r.iterator();
        var out_it: usize = 0;
        while (it.next()) |item| {
            @memcpy(&nodes[out_it], item.*[0..3]);
            out_it += 1;
        }

        const lessThanFn = struct {
            fn lessThanFn(_: void, lhs: [3]u8, rhs: [3]u8) bool {
                return std.mem.lessThan(u8, &lhs, &rhs);
            }
        }.lessThanFn;
        std.mem.sort([3]u8, nodes, {}, lessThanFn);
    }

    {
        @memset(result, ',');
        var out_it: usize = 0;
        for (nodes) |item| {
            @memcpy(result[out_it .. out_it + 3], &item);
            out_it += 4;
        }
    }

    return result;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) ![]u8 {
    var wires, var gates = try parseInput(allocator, input);
    defer wires.deinit();
    defer gates.deinit();

    // collect zi gates
    var z_gates = try std.ArrayList([3]u8).initCapacity(allocator, 64);
    defer z_gates.deinit();

    for (0..64) |zi| {
        var buf: [3]u8 = undefined;
        _ = try std.fmt.bufPrint(&buf, "z{:0>2}", .{zi});

        if (gates.contains(buf)) {
            z_gates.appendAssumeCapacity(buf);
        } else {
            break;
        }
    }

    var bad_gates = common.AutoHashSet([3]u8).init(allocator);
    defer bad_gates.deinit();

    //validate z0
    {
        const Z0 = gates.get(z_gates.items[0]).?;

        if (Z0.type != .XOR) {
            try bad_gates.put(z_gates.items[0]);
        } else {
            if (!std.mem.eql(u8, &Z0.A, "x00")) return error.UnknownState;
            if (!std.mem.eql(u8, &Z0.B, "y00")) return error.UnknownState;
        }
    }

    //validate zn
    {
        const ZN = gates.get(z_gates.getLast()).?;

        if (ZN.type != .OR) {
            try bad_gates.put(z_gates.getLast());
        } else {
            if (gates.get(ZN.A).?.type != .AND) return error.UnknownState;
            if (gates.get(ZN.B).?.type != .AND) return error.UnknownState;
        }
    }

    //validate <z1, zn-1> and <c1..cn-1>
    for (1..z_gates.items.len - 1) |ix| {
        var c_name: [3]u8 = undefined;
        _ = try std.fmt.bufPrint(&c_name, "c{:0>2}", .{ix});
        var x_name = c_name;
        x_name[0] = 'x';
        var y_name = c_name;
        y_name[0] = 'y';
        var z_name = c_name;
        z_name[0] = 'z';

        var z_gate = gates.get(z_name).?;
        if (z_gate.type != .XOR) {
            try bad_gates.put(z_name);
            continue;
        }

        var input1 = gates.get(z_gate.A).?;
        var input2 = gates.get(z_gate.B).?;

        if (input1.type == .OR or input2.type == .XOR) {
            std.mem.swap([3]u8, &z_gate.A, &z_gate.B);
            std.mem.swap(Gate, &input1, &input2);
        }

        if (input1.type != .XOR) {
            try bad_gates.put(z_gate.A);
        } else {
            // xor input should be xn and yn
            // the order will always be y,n due to input parsing

            if (!gatesEqual(input1.A, x_name)) {
                try bad_gates.put(input1.A);
            }

            if (!gatesEqual(input1.B, y_name)) {
                try bad_gates.put(input1.B);
            }
        }

        // Ci
        if (input2.type == .AND and ix == 1) {
            // special case for C0
        } else if (input2.type != .OR) {
            try bad_gates.put(z_gate.B);
        } else {
            const l = gates.get(input2.A).?;
            const r = gates.get(input2.B).?;

            if (l.type != .AND) {
                try bad_gates.put(input2.A);
            }

            if (r.type != .AND) {
                try bad_gates.put(input2.B);
            }
        }
    }

    return try prepare_result(allocator, bad_gates);
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
    const part2_solution = try solvePart2(allocator, input.items);
    defer allocator.free(part2_solution);
    std.debug.print("Part 2 solution: {s}\n", .{part2_solution});
}

const test_input = [_][]const u8{
    "x00: 1",
    "x01: 1",
    "x02: 1",
    "y00: 0",
    "y01: 1",
    "y02: 0",
    "",
    "x00 AND y00 -> z00",
    "x01 XOR y01 -> z01",
    "x02 OR y02 -> z02",
};

const test_input_big = [_][]const u8{
    "x00: 1",
    "x01: 0",
    "x02: 1",
    "x03: 1",
    "x04: 0",
    "y00: 1",
    "y01: 1",
    "y02: 1",
    "y03: 1",
    "y04: 1",
    "",
    "ntg XOR fgs -> mjb",
    "y02 OR x01 -> tnw",
    "kwq OR kpj -> z05",
    "x00 OR x03 -> fst",
    "tgd XOR rvg -> z01",
    "vdt OR tnw -> bfw",
    "bfw AND frj -> z10",
    "ffh OR nrd -> bqk",
    "y00 AND y03 -> djm",
    "y03 OR y00 -> psh",
    "bqk OR frj -> z08",
    "tnw OR fst -> frj",
    "gnj AND tgd -> z11",
    "bfw XOR mjb -> z00",
    "x03 OR x00 -> vdt",
    "gnj AND wpb -> z02",
    "x04 AND y00 -> kjc",
    "djm OR pbm -> qhw",
    "nrd AND vdt -> hwm",
    "kjc AND fst -> rvg",
    "y04 OR y02 -> fgs",
    "y01 AND x02 -> pbm",
    "ntg OR kjc -> kwq",
    "psh XOR fgs -> tgd",
    "qhw XOR tgd -> z09",
    "pbm OR djm -> kpj",
    "x03 XOR y03 -> ffh",
    "x00 XOR y04 -> ntg",
    "bfw OR bqk -> z06",
    "nrd XOR fgs -> wpb",
    "frj XOR qhw -> z04",
    "bqk OR frj -> z07",
    "y03 OR x01 -> nrd",
    "hwm AND bqk -> z03",
    "tgd XOR rvg -> z12",
    "tnw OR pbm -> gnj",
};

test "solve part 1a test" {
    const allocator = std.testing.allocator;

    const result = try solvePart1(allocator, &test_input);
    try std.testing.expectEqual(@as(u64, 4), result);
}

test "solve part 1b test" {
    const allocator = std.testing.allocator;

    const result = try solvePart1(allocator, &test_input_big);
    try std.testing.expectEqual(@as(u64, 2024), result);
}

test "solve part 2 test" {}
