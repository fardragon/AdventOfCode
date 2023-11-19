const std = @import("std");
const common_input = @import("common").input;

const Elf = struct {
    snacks: u32,

    fn compare(context: void, lhs: Elf, rhs: Elf) bool {
        _ = context;
        return lhs.snacks > rhs.snacks;
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Elf) {
    var result = std.ArrayList(Elf).init(allocator);
    errdefer result.deinit();

    var sum: u32 = 0;
    for (input) |line| {
        if (line.len == 0) {
            try result.append(Elf{ .snacks = sum });
            sum = 0;
            continue;
        }

        sum += try std.fmt.parseInt(u32, line, 10);
    } else {
        try result.append(Elf{ .snacks = sum });
    }

    return result;
}

fn solvePart1(input: []Elf) u32 {
    std.sort.insertion(Elf, input, {}, Elf.compare);
    return input[0].snacks;
}

fn solvePart2(input: []Elf) u32 {
    std.sort.insertion(Elf, input, {}, Elf.compare);
    var result: u32 = 0;
    for (0..3) |ix| {
        result += input[ix].snacks;
    }
    return result;
}

pub fn main() !void {
    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = GPA.allocator();

    defer _ = GPA.deinit();

    const input = try common_input.readFileInput(allocator, "test_input.txt");
    defer {
        for (input.items) |item| {
            allocator.free(item);
        }
        input.deinit();
    }

    var elves = try parseInput(allocator, input.items);
    defer elves.deinit();

    std.debug.print("Part 1 solution: {d}\n", .{solvePart1(elves.items)});
    std.debug.print("Part 2 solution: {d}\n", .{solvePart2(elves.items)});
}

test "parsing test" {
    const test_input = [_][]const u8{ "100", "200", "", "100" };

    const result = try parseInput(std.testing.allocator, &test_input);
    defer result.deinit();

    try std.testing.expect(result.items.len == 2);
    try std.testing.expect(result.items[0].snacks == 300);
    try std.testing.expect(result.items[1].snacks == 100);
}

test "solve part 1 test" {
    var test_input = [_]Elf{ Elf{ .snacks = 100 }, Elf{ .snacks = 300 }, Elf{ .snacks = 800 }, Elf{ .snacks = 50 } };

    const result = solvePart1(&test_input);

    try std.testing.expectEqual(@as(u32, 800), result);
}

test "solve part 2 test" {
    var test_input = [_]Elf{ Elf{ .snacks = 100 }, Elf{ .snacks = 300 }, Elf{ .snacks = 800 }, Elf{ .snacks = 50 }, Elf{ .snacks = 600 } };

    const result = solvePart2(&test_input);

    try std.testing.expectEqual(@as(u32, 1700), result);
}
