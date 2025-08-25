const std = @import("std");
const common = @import("common");
const common_input = common.input;
const String = common.String;

const Spring = struct {
    pattern: common.String,
    numbers: std.ArrayList(u8),

    fn deinit(self: *Spring) void {
        self.pattern.deinit();
        self.numbers.deinit();
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(String) {
    var result = std.ArrayList(String).empty;

    errdefer {
        for (result.items) |*string| {
            string.deinit();
        }
        result.deinit(allocator);
    }

    if (input.len != 1) @panic("Invalid input");

    var it = std.mem.splitScalar(u8, input[0], ',');

    while (it.next()) |part| {
        var str = try String.init(allocator, part);
        errdefer str.deinit();

        try result.append(allocator, str);
    }

    return result;
}

fn applyHASH(str: []const u8) u8 {
    var current_value: u64 = 0;
    for (str) |char| {
        current_value += char;
        current_value *= 17;
        current_value %= 256;
    }

    return @truncate(current_value);
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var strings = try parseInput(allocator, input);
    defer {
        for (strings.items) |*string| {
            string.deinit();
        }
        strings.deinit(allocator);
    }

    var result: u64 = 0;
    for (strings.items) |str| {
        result += applyHASH(str.str);
    }

    return result;
}

const Action = union(enum) {
    remove: void,
    add: u8,
};

const Instruction = struct {
    box: u8,
    label: []u8,
    action: Action,
};

fn parseInstruction(allocator: std.mem.Allocator, str: []const u8) !Instruction {
    if (str[str.len - 1] == '-') {
        //remove instruction
        const label = try allocator.dupe(u8, str[0 .. str.len - 1]);
        errdefer allocator.free(label);

        return Instruction{ .box = applyHASH(label), .label = label, .action = Action{
            .remove = {},
        } };
    } else {
        var it = std.mem.splitScalar(u8, str, '=');

        const label = try allocator.dupe(u8, it.first());
        errdefer allocator.free(label);

        const lens = try std.fmt.parseInt(u8, it.next().?, 10);

        return Instruction{
            .box = applyHASH(label),
            .label = label,
            .action = Action{ .add = lens },
        };
    }
}

const Box = struct {
    const BoxEntry = struct {
        label: []u8,
        lens: u8,
    };

    entries: std.ArrayList(BoxEntry),
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) Box {
        return Box{
            .entries = std.ArrayList(BoxEntry).empty,
            .allocator = allocator,
        };
    }

    fn deinit(self: *Box, allocator: std.mem.Allocator) void {
        for (self.entries.items) |entry| {
            self.allocator.free(entry.label);
        }
        self.entries.deinit(allocator);
    }

    fn addLens(self: *Box, allocator: std.mem.Allocator, label: []const u8, lens: u8) !void {
        var replaced_existing = false;
        for (self.entries.items) |*entry| {
            if (std.mem.eql(u8, entry.*.label, label)) {
                replaced_existing = true;
                entry.lens = lens;
                break;
            }
        }

        if (!replaced_existing) {
            try self.entries.append(
                allocator,
                BoxEntry{
                    .label = try self.allocator.dupe(u8, label),
                    .lens = lens,
                },
            );
        }
    }

    fn removeLens(self: *Box, label: []const u8) void {
        var index_to_remove: ?usize = null;
        for (self.entries.items, 0..) |entry, ix| {
            if (std.mem.eql(u8, entry.label, label)) {
                index_to_remove = ix;
                break;
            }
        }

        if (index_to_remove) |ix| {
            self.allocator.free(self.entries.items[ix].label);
            for (ix..self.entries.items.len - 1) |current_ix| {
                self.entries.items[current_ix] = self.entries.items[current_ix + 1];
            }
            _ = self.entries.pop();
        }
    }

    fn calculatePower(self: Box) u64 {
        var power: u64 = 0;

        for (self.entries.items, 1..) |entry, pos| {
            power += (entry.lens * pos);
        }

        return power;
    }
};

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var strings = try parseInput(allocator, input);
    defer {
        for (strings.items) |*string| {
            string.deinit();
        }
        strings.deinit(allocator);
    }

    var boxes: [256]Box = undefined;
    for (&boxes) |*box| {
        box.* = Box.init(allocator);
    }

    defer {
        for (&boxes) |*box| box.deinit(allocator);
    }

    for (strings.items) |str| {
        const instruction = try parseInstruction(allocator, str.str);
        defer allocator.free(instruction.label);

        switch (instruction.action) {
            Action.add => |lens| {
                try boxes[instruction.box].addLens(allocator, instruction.label, lens);
            },
            Action.remove => boxes[instruction.box].removeLens(instruction.label),
        }
    }

    var result: u64 = 0;
    for (boxes, 1..) |box, pos| {
        result += (box.calculatePower() * pos);
    }

    return result;
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

test "solve part 1 test" {
    const test_input = [_][]const u8{
        "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 1320), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 145), result);
}
