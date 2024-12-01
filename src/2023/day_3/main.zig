const std = @import("std");
const common_input = @import("common").input;

const Schematic = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    schematic: std.ArrayList(u8),
    height: u32,
    width: u32,

    fn init(allocator: std.mem.Allocator, input: []const []const u8) !Self {
        var result = Self{
            .allocator = allocator,
            .schematic = std.ArrayList(u8).init(allocator),
            .height = @intCast(input.len),
            .width = @intCast(input[0].len),
        };

        errdefer result.schematic.deinit();

        try result.schematic.ensureTotalCapacity(@intCast(result.height * result.width));
        for (input) |line| {
            result.schematic.appendSliceAssumeCapacity(line);
        }

        return result;
    }

    fn deinit(self: *const Self) void {
        self.schematic.deinit();
    }

    fn isSymbol(char: u8) bool {
        return char != '.' and !std.ascii.isDigit(char);
    }

    fn isGear(char: u8) bool {
        return char == '*';
    }

    fn checkNeighbours(self: *const Self, x: i64, y: i64, comptime filter_func: fn (char: u8) bool) ?usize {
        const offsets: [3]i8 = .{ -1, 0, 1 };

        for (offsets) |x_off| {
            for (offsets) |y_off| {
                if (x_off == 0 and y_off == 0) continue;
                const new_x = x + x_off;
                const new_y = y + y_off;

                if (new_x < 0 or new_x >= self.width) continue;
                if (new_y < 0 or new_y >= self.height) continue;

                const new_pos: usize = @intCast(new_y * self.width + new_x);

                if (filter_func(self.schematic.items[new_pos])) {
                    return new_pos;
                }
            }
        }

        return null;
    }

    fn getPartsList(self: *const Self, allocator: std.mem.Allocator) !std.ArrayList(u16) {
        var part_adjacent = false;
        var part_number: u16 = 0;

        var result = std.ArrayList(u16).init(allocator);
        errdefer result.deinit();

        for (self.schematic.items, 0..) |symbol, index| {
            const y: i64 = @intCast(index / self.width);
            const x: i64 = @intCast(index % self.width);

            // handle moving to next line
            if (part_number != 0 and x == 0) {
                if (part_adjacent) {
                    try result.append(part_number);
                }
                part_adjacent = false;
                part_number = 0;
            }

            if (std.ascii.isDigit(symbol)) {
                part_number = part_number * 10 + (symbol - '0');
                if (self.checkNeighbours(x, y, isSymbol)) |_| {
                    part_adjacent = true;
                }
            } else if (part_number != 0) {
                if (part_adjacent) {
                    try result.append(part_number);
                }
                part_adjacent = false;
                part_number = 0;
            }
        }

        return result;
    }

    fn getGears(self: *const Self, allocator: std.mem.Allocator) !std.AutoArrayHashMap(usize, std.ArrayList(u16)) {
        var result = std.AutoArrayHashMap(usize, std.ArrayList(u16)).init(allocator);
        errdefer {
            var it = result.iterator();
            while (it.next()) |entry| {
                entry.value_ptr.*.deinit();
            }
            result.deinit();
        }

        var gear_adjacent: ?usize = null;
        var part_number: u16 = 0;

        for (self.schematic.items, 0..) |symbol, index| {
            const y: i64 = @intCast(index / self.width);
            const x: i64 = @intCast(index % self.width);

            // handle moving to next line
            if (part_number != 0 and x == 0) {
                if (gear_adjacent) |gear_pos| {
                    if (result.getPtr(gear_pos)) |gear_list| {
                        try gear_list.append(part_number);
                    } else {
                        try result.put(gear_pos, std.ArrayList(u16).init(allocator));
                        try result.getPtr(gear_pos).?.append(part_number);
                    }
                }
                gear_adjacent = null;
                part_number = 0;
            }

            if (std.ascii.isDigit(symbol)) {
                part_number = part_number * 10 + (symbol - '0');
                if (self.checkNeighbours(x, y, isGear)) |gear_pos| {
                    if (gear_adjacent) |old_gear| {
                        if (old_gear != gear_pos) {
                            unreachable;
                        }
                    } else {
                        gear_adjacent = gear_pos;
                    }
                }
            } else if (part_number != 0) {
                if (gear_adjacent) |gear_pos| {
                    if (result.getPtr(gear_pos)) |gear_list| {
                        try gear_list.append(part_number);
                    } else {
                        try result.put(gear_pos, std.ArrayList(u16).init(allocator));
                        try result.getPtr(gear_pos).?.append(part_number);
                    }
                }
                gear_adjacent = null;
                part_number = 0;
            }
        }

        return result;
    }
};

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    const schematic = try Schematic.init(allocator, input);
    defer schematic.deinit();

    const parts = try schematic.getPartsList(allocator);
    defer parts.deinit();

    var result: u64 = 0;

    for (parts.items) |part| {
        result += part;
    }

    return result;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    const schematic = try Schematic.init(allocator, input);
    defer schematic.deinit();

    var gears = try schematic.getGears(allocator);
    defer {
        var it = gears.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.*.deinit();
        }
        gears.deinit();
    }

    var result: u64 = 0;

    var it = gears.iterator();
    while (it.next()) |gear| {
        if (gear.value_ptr.*.items.len == 2) {
            const gear_ratio = @as(u64, gear.value_ptr.*.items[0]) * gear.value_ptr.*.items[1];
            result += gear_ratio;
        }
    }

    return result;
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
    std.debug.print("Part 2 solution: {d}\n", .{try solvePart2(allocator, input.items)});
}

test "solve part 1 test" {
    const test_input = [_][]const u8{
        "467..114..",
        "...*......",
        "..35..633.",
        "......#...",
        "617*......",
        ".....+.58.",
        "..592.....",
        "......755.",
        "...$.*....",
        ".664.598..",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 4361), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "467..114..",
        "...*......",
        "..35..633.",
        "......#...",
        "617*......",
        ".....+.58.",
        "..592.....",
        "......755.",
        "...$.*....",
        ".664.598..",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 467835), result);
}
