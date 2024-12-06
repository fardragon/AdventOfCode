const std = @import("std");
const common = @import("common");
const common_input = common.input;
const Rule = common.Pair(u8, u8);

fn parseRules(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Rule) {
    var rules = std.ArrayList(Rule).init(allocator);
    errdefer rules.deinit();

    for (input) |line| {
        const sep = std.mem.indexOfScalar(u8, line, '|');
        if (sep == null) return error.MalformedInput;

        try rules.append(Rule{
            .first = try std.fmt.parseInt(u8, line[0..sep.?], 10),
            .second = try std.fmt.parseInt(u8, line[sep.? + 1 ..], 10),
        });
    }

    return rules;
}

fn parseUpdates(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(std.ArrayList(u8)) {
    var updates = std.ArrayList(std.ArrayList(u8)).init(allocator);
    errdefer {
        for (updates.items) |update| {
            update.deinit();
        }
        updates.deinit();
    }

    for (input) |line| {
        var update = try common.parsing.parseNumbers(u8, allocator, line, ',');
        errdefer update.deinit();
        try updates.append(update);
    }

    return updates;
}

fn validateUpdate(allocator: std.mem.Allocator, update: []const u8, rules: []const Rule) !bool {
    var update_map = std.AutoHashMap(u8, usize).init(allocator);
    defer update_map.deinit();

    for (update, 0..) |page_num, ix| {
        try update_map.put(page_num, ix);
    }

    for (rules) |rule| {
        const left_ix = update_map.get(rule.first);
        const right_ix = update_map.get(rule.second);

        if (left_ix != null and right_ix != null and left_ix.? > right_ix.?) return false;
    }

    return true;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var sep: ?usize = null;
    for (input, 0..) |line, ix| {
        if (line.len == 0) sep = ix;
    }
    if (sep == null) return error.MalformedInput;

    const rules = try parseRules(allocator, input[0..sep.?]);
    defer rules.deinit();

    const updates = try parseUpdates(allocator, input[sep.? + 1 ..]);
    defer {
        for (updates.items) |update| {
            update.deinit();
        }
        updates.deinit();
    }

    var sum: u64 = 0;
    for (updates.items) |update| {
        if (try validateUpdate(allocator, update.items, rules.items)) {
            sum += update.items[update.items.len / 2];
        }
    }

    return sum;
}

fn fixUpdate(update: []u8, rules: []const Rule) void {
    const RuleOrder = struct {
        fn lessThan(_rules: []const Rule, lhs: u8, rhs: u8) bool {
            for (_rules) |rule| {
                if (rule.first == lhs and rule.second == rhs) return true;
            }
            return false;
        }
    };

    std.mem.sort(u8, update, rules, RuleOrder.lessThan);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var sep: ?usize = null;
    for (input, 0..) |line, ix| {
        if (line.len == 0) sep = ix;
    }
    if (sep == null) return error.MalformedInput;

    const rules = try parseRules(allocator, input[0..sep.?]);
    defer rules.deinit();

    const updates = try parseUpdates(allocator, input[sep.? + 1 ..]);
    defer {
        for (updates.items) |update| {
            update.deinit();
        }
        updates.deinit();
    }

    var sum: u64 = 0;
    for (updates.items) |update| {
        if (!(try validateUpdate(allocator, update.items, rules.items))) {
            fixUpdate(update.items, rules.items);
            sum += update.items[update.items.len / 2];
        }
    }

    return sum;
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

const test_input = [_][]const u8{
    "47|53",
    "97|13",
    "97|61",
    "97|47",
    "75|29",
    "61|13",
    "75|53",
    "29|13",
    "97|29",
    "53|29",
    "61|53",
    "97|53",
    "61|29",
    "47|13",
    "75|47",
    "97|75",
    "47|61",
    "75|61",
    "47|29",
    "75|13",
    "53|13",
    "",
    "75,47,61,53,29",
    "97,61,53,29,13",
    "75,29,13",
    "75,97,47,61,53",
    "61,13,29",
    "97,13,75,29,47",
};

test "solve part 1 test" {
    const allocator = std.testing.allocator;
    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 143), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 123), result);
}
