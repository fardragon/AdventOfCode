const std = @import("std");
const common = @import("common");
const common_input = common.input;
const String = common.String;

const Towel = struct {
    const MaxTowelSize: usize = 16;

    data: [Towel.MaxTowelSize]u8,
    len: u8,

    fn init(patterns: []const u8) !Towel {
        if (patterns.len > Towel.MaxTowelSize) return error.TowelTooLong;

        var result = Towel{
            .data = undefined,
            .len = @truncate(patterns.len),
        };

        std.mem.copyForwards(u8, &result.data, patterns);
        return result;
    }

    fn towel(self: *const Towel) []const u8 {
        return self.data[0..self.len];
    }
};

fn parseTowels(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Towel) {
    var towels = std.ArrayList(Towel).empty;
    errdefer towels.deinit(allocator);

    var ix = std.mem.splitSequence(u8, input, ", ");

    while (ix.next()) |towel_str| {
        try towels.append(allocator, try Towel.init(towel_str));
    }

    return towels;
}

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !struct { std.ArrayList(Towel), std.ArrayList(String) } {
    var towels = try parseTowels(allocator, input[0]);
    errdefer towels.deinit(allocator);

    var designs = std.ArrayList(String).empty;
    errdefer {
        for (designs.items) |design| design.deinit();
        designs.deinit(allocator);
    }

    for (input[2..]) |design| {
        const d = try String.init(allocator, design);
        errdefer d.deinit();
        try designs.append(allocator, d);
    }

    return .{
        towels,
        designs,
    };
}

fn isDesignPossible(cache: *std.StringHashMap(u64), design: []const u8, towels: []const Towel) !u64 {
    if (design.len == 0) return 1;

    if (cache.get(design)) |cached_result| {
        return cached_result;
    }

    var possibilities: u64 = 0;
    for (towels) |towel| {
        if (std.mem.startsWith(u8, design, towel.towel())) {
            possibilities += try isDesignPossible(cache, design[towel.towel().len..], towels);
        }
    }

    try cache.put(design, possibilities);
    return possibilities;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var towels, var designs = try parseInput(allocator, input);
    defer {
        towels.deinit(allocator);

        for (designs.items) |design| design.deinit();
        designs.deinit(allocator);
    }

    var designCache = std.StringHashMap(u64).init(allocator);
    defer designCache.deinit();

    var result: u64 = 0;
    for (designs.items) |design| {
        const possibilities = try isDesignPossible(&designCache, design.str, towels.items);
        if (possibilities > 0) {
            result += 1;
        }
    }

    return result;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var towels, var designs = try parseInput(allocator, input);
    defer {
        towels.deinit(allocator);

        for (designs.items) |design| design.deinit();
        designs.deinit(allocator);
    }

    var designCache = std.StringHashMap(u64).init(allocator);
    defer designCache.deinit();

    var result: u64 = 0;
    for (designs.items) |design| {
        result += try isDesignPossible(&designCache, design.str, towels.items);
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

const test_input = [_][]const u8{
    "r, wr, b, g, bwu, rb, gb, br",
    "",
    "brwrr",
    "bggr",
    "gbbr",
    "rrbgbr",
    "ubwu",
    "bwurrg",
    "brgr",
    "bbrgwb",
};

test "solve part 1 test" {
    const allocator = std.testing.allocator;

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 6), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 16), result);
}
