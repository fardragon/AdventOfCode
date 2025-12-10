const std = @import("std");
const common = @import("common");
const common_input = common.input;

const BitSetSize = @bitSizeOf(u16);
const Machine = struct {
    target_lights: std.bit_set.IntegerBitSet(BitSetSize),
    buttons: std.ArrayList(std.bit_set.IntegerBitSet(BitSetSize)),
    joltages: std.ArrayList(u16),

    fn deinit(self: *Machine, allocator: std.mem.Allocator) void {
        self.buttons.deinit(allocator);
        self.joltages.deinit(allocator);
    }
};

fn parseMachine(allocator: std.mem.Allocator, input: []const u8) !Machine {
    // std.debug.print("Parsing machine: {s}\n", .{input});

    const l_bracket, const r_bracket = brackets: {
        const l = std.mem.indexOfScalar(u8, input, '[') orelse return error.MalformedInput;
        const r = std.mem.indexOfScalar(u8, input, ']') orelse return error.MalformedInput;

        break :brackets .{ l, r };
    };

    const l_brace, const r_brace = braces: {
        const l = std.mem.indexOfScalar(u8, input, '{') orelse return error.MalformedInput;
        const r = std.mem.indexOfScalar(u8, input, '}') orelse return error.MalformedInput;

        break :braces .{ l, r };
    };

    const lights_count = r_bracket - l_bracket - 1;
    var target_lights: std.bit_set.IntegerBitSet(BitSetSize) = .initEmpty();

    for (0..lights_count) |ix| {
        switch (input[l_bracket + 1 + ix]) {
            '.' => target_lights.unset(ix),
            '#' => target_lights.set(ix),
            else => return error.MalformedInput,
        }
    }

    // std.debug.print("Parsed lights: {any}\n", .{target_lights});

    var joltages = try common.parsing.parseNumbers(u16, allocator, input[l_brace + 1 .. r_brace], ',');
    errdefer joltages.deinit(allocator);

    const buttons_count = std.mem.count(u8, input, "(");
    var buttons: std.ArrayList(std.bit_set.IntegerBitSet(BitSetSize)) = try .initCapacity(allocator, buttons_count);
    errdefer buttons.deinit(allocator);

    var it_l = std.mem.indexOfScalar(u8, input, '(') orelse return error.MalformedInput;

    for (0..buttons_count) |ix| {
        const it_r = std.mem.indexOfScalarPos(u8, input, it_l, ')') orelse return error.MalformedInput;
        // std.debug.print("Parsing button: {d} to {d}\n", .{ it_l, it_r });
        // [.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
        // 0123456789ab

        buttons.appendAssumeCapacity(.initEmpty());

        var button_numbers = try common.parsing.parseNumbers(u8, allocator, input[it_l + 1 .. it_r], ',');
        defer button_numbers.deinit(allocator);

        for (button_numbers.items) |button| {
            buttons.items[ix].set(button);
        }

        it_l = it_r + 2;
    }

    return .{
        .target_lights = target_lights,
        .buttons = buttons,
        .joltages = joltages,
    };
}

fn parseMachines(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Machine) {
    var machines: std.ArrayList(Machine) = try .initCapacity(allocator, input.len);
    errdefer {
        for (machines.items) |*machine| {
            machine.deinit(allocator);
        }
        machines.deinit(allocator);
    }

    for (input) |line| {
        machines.appendAssumeCapacity(try parseMachine(allocator, line));
    }

    return machines;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var machines = try parseMachines(allocator, input);
    defer {
        for (machines.items) |*machine| {
            machine.deinit(allocator);
        }
        machines.deinit(allocator);
    }

    var score: u64 = 0;

    for (machines.items) |machine| {
        const buttons_count = machine.buttons.items.len;

        var tmp_lights: @TypeOf(machine.target_lights) = .initEmpty();

        std.debug.assert(buttons_count < 16);
        var solution: std.bit_set.IntegerBitSet(16) = .initEmpty();

        const combinations = try std.math.powi(usize, 2, buttons_count);

        var machine_solution: ?u64 = null;
        for (0..combinations) |combination| {
            tmp_lights.mask = 0;

            solution.mask = @truncate(combination);
            for (0..buttons_count) |ix| {
                if (solution.isSet(ix)) {
                    tmp_lights.toggleSet(machine.buttons.items[ix]);
                }
            }

            if (tmp_lights.eql(machine.target_lights)) {
                if (machine_solution == null or solution.count() < machine_solution.?) {
                    machine_solution = solution.count();
                }
            }
        }

        score += machine_solution orelse return error.LogicError;
    }

    return score;
}

fn indexOfMinNonZero(comptime T: type, slice: []const T) ?usize {
    std.debug.assert(slice.len > 0);
    var best: ?T = null;
    var index: ?usize = null;
    for (slice, 0..) |item, i| {
        if (item == 0) continue;
        if (best == null or item < best.?) {
            best = item;
            index = i;
        }
    }
    return index;
}

fn reorderButtons(allocator: std.mem.Allocator, machine: *Machine) !void {
    var newButtons: std.ArrayList(std.bit_set.IntegerBitSet(BitSetSize)) = try .initCapacity(allocator, machine.buttons.items.len);
    errdefer newButtons.deinit(allocator);

    const counter = try allocator.alloc(usize, machine.joltages.items.len);
    defer allocator.free(counter);

    while (machine.buttons.items.len > 0) {
        @memset(counter, 0);
        for (machine.buttons.items) |button| {
            for (0..machine.joltages.items.len) |ix| {
                if (button.isSet(ix)) {
                    counter[ix] += 1;
                }
            }
        }

        // Find joltage affected by least buttons
        const joltage_ix = indexOfMinNonZero(usize, counter) orelse return error.LogicError;
        var next_button: ?std.bit_set.IntegerBitSet(BitSetSize) = null;
        var next_button_ix: usize = 0;
        for (machine.buttons.items, 0..) |button, ix| {
            if (button.isSet(joltage_ix)) {
                if (next_button == null or button.count() > next_button.?.count()) {
                    next_button = button;
                    next_button_ix = ix;
                }
            }
        }

        if (next_button == null) return error.LogicError;

        const swap = machine.buttons.orderedRemove(next_button_ix);
        newButtons.appendAssumeCapacity(swap);
    }

    machine.buttons.deinit(allocator);
    machine.buttons = newButtons;
}

fn calculateButtonsPerJoltage(allocator: std.mem.Allocator, machine: *const Machine) !std.ArrayList(std.ArrayList(u16)) {
    var result: std.ArrayList(std.ArrayList(u16)) = try .initCapacity(allocator, machine.buttons.items.len + 1);
    errdefer {
        for (result.items) |*counter| {
            counter.deinit(allocator);
        }
        result.deinit(allocator);
    }

    for (0..machine.buttons.items.len + 1) |_| {
        var tmp: std.ArrayList(u16) = try .initCapacity(allocator, machine.joltages.items.len);
        errdefer tmp.deinit(allocator);

        tmp.appendNTimesAssumeCapacity(0, machine.joltages.items.len);
        result.appendAssumeCapacity(tmp);
    }

    var ix = machine.buttons.items.len - 1;

    while (true) : (ix -= 1) {
        for (0..machine.joltages.items.len) |joltage_ix| {
            result.items[ix].items[joltage_ix] += result.items[ix + 1].items[joltage_ix];

            if (machine.buttons.items[ix].isSet(joltage_ix)) {
                result.items[ix].items[joltage_ix] += 1;
            }
        }

        if (ix == 0) break;
    }

    return result;
}

fn solvePart2Inner(allocator: std.mem.Allocator, machine: *const Machine, buttons_remaining: *const std.ArrayList(std.ArrayList(u16)), current_solution: *u16, target_left: []const u16, button_ix: u16, current_presses: u16) !void {
    if (current_presses > current_solution.*) return;
    if (current_presses + std.mem.max(u16, target_left) >= current_solution.*) return;

    if (button_ix == machine.buttons.items.len) {
        if (std.mem.allEqual(u16, target_left, 0)) {
            current_solution.* = current_presses;
        }
        return;
    }

    var min: u16 = 0;
    var max: u16 = std.math.maxInt(u16);

    const button = machine.buttons.items[button_ix];

    var it = button.iterator(.{});

    while (it.next()) |ix| {
        max = @min(max, target_left[ix]);
        if (buttons_remaining.items[button_ix].items[ix] == 1) {
            min = @max(min, target_left[ix]);
        }
    }

    if (min > max) return;

    const new_target = try allocator.alloc(u16, target_left.len);
    defer allocator.free(new_target);

    for (min..max + 1) |presses| {
        @memcpy(new_target, target_left);

        it = button.iterator(.{});
        while (it.next()) |ix| {
            new_target[ix] -= @intCast(presses);
        }

        try solvePart2Inner(allocator, machine, buttons_remaining, current_solution, new_target, button_ix + 1, current_presses + @as(u16, @truncate(presses)));
    }
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var machines = try parseMachines(allocator, input);
    defer {
        for (machines.items) |*machine| {
            machine.deinit(allocator);
        }
        machines.deinit(allocator);
    }

    var score: u64 = 0;

    for (machines.items) |*machine| {
        try reorderButtons(allocator, machine);
        var remainingButtonsPerJoltage = try calculateButtonsPerJoltage(allocator, machine);
        defer {
            for (remainingButtonsPerJoltage.items) |*counter| {
                counter.deinit(allocator);
            }
            remainingButtonsPerJoltage.deinit(allocator);
        }

        var solution: u16 = std.math.maxInt(u16);
        try solvePart2Inner(allocator, machine, &remainingButtonsPerJoltage, &solution, machine.joltages.items, 0, 0);

        score += solution;
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
        "[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}",
        "[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}",
        "[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 7), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}",
        "[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}",
        "[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 33), result);
}
