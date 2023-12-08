const std = @import("std");
const common_input = @import("common").input;

const Node = struct {
    name: [3]u8,
    left_path: [3]u8,
    right_path: [3]u8,
};

const Network = struct {
    instructions: []const u8,
    nodes: std.AutoHashMap([3]u8, Node),
    allocator: std.mem.Allocator,

    fn deinit(self: *Network) void {
        self.allocator.free(self.instructions);
        self.nodes.deinit();
    }
};

fn parseNode(input: []const u8) Node {
    var result = Node{
        .name = undefined,
        .left_path = undefined,
        .right_path = undefined,
    };

    @memcpy(&result.name, input[0..3]);
    @memcpy(&result.left_path, input[7..10]);
    @memcpy(&result.right_path, input[12..15]);

    return result;
}

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !Network {
    var result = Network{
        .instructions = undefined,
        .nodes = std.AutoHashMap([3]u8, Node).init(allocator),
        .allocator = allocator,
    };
    errdefer result.nodes.deinit();

    result.instructions = try allocator.dupe(u8, input[0]);
    errdefer allocator.free(result.instructions);

    for (input[2..]) |line| {
        const node = parseNode(line);
        try result.nodes.put(node.name, node);
    }

    return result;
}

fn streq(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var network = try parseInput(allocator, input);
    defer network.deinit();

    var result: u64 = 0;
    var instruction_pointer: usize = 0;
    var current_node = network.nodes.get(.{ 'A', 'A', 'A' }).?;
    while (true) {
        if (streq(&current_node.name, "ZZZ")) break;

        if (network.instructions[instruction_pointer] == 'L') {
            current_node = network.nodes.get(current_node.left_path).?;
        } else {
            current_node = network.nodes.get(current_node.right_path).?;
        }

        result += 1;
        instruction_pointer = (instruction_pointer + 1) % network.instructions.len;
    }

    return result;
}

fn gcd(a: u64, b: u64) u64 {
    var _a = a;
    var _b = b;

    while (_a != _b) {
        if (_a > _b) {
            _a = _a - _b;
        } else {
            _b = _b - _a;
        }
    }
    return _a;
}

fn lcm(a: u64, b: u64) u64 {
    return (a * b) / gcd(a, b);
}

fn lcm_slice(input: []u64) u64 {
    var res: u64 = 1;
    for (input) |val| {
        res = lcm(res, val);
    }
    return res;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var network = try parseInput(allocator, input);
    defer network.deinit();

    // find nodes ending with 'A'
    var starting_nodes = std.ArrayList([3]u8).init(allocator);
    defer starting_nodes.deinit();

    var names_iterator = network.nodes.keyIterator();
    while (names_iterator.next()) |name| {
        if (name[2] == 'A') {
            try starting_nodes.append(name.*);
        }
    }

    var partial_results = std.ArrayList(u64).init(allocator);
    defer partial_results.deinit();
    for (starting_nodes.items) |starting_node| {
        var result: u64 = 0;
        var instruction_pointer: usize = 0;
        var current_node = network.nodes.get(starting_node).?;
        while (true) {
            if (current_node.name[2] == 'Z') break;

            if (network.instructions[instruction_pointer] == 'L') {
                current_node = network.nodes.get(current_node.left_path).?;
            } else {
                current_node = network.nodes.get(current_node.right_path).?;
            }

            result += 1;
            instruction_pointer = (instruction_pointer + 1) % network.instructions.len;
        }

        try partial_results.append(result);
    }

    return lcm_slice(partial_results.items);
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
        "RL",
        "",
        "AAA = (BBB, CCC)",
        "BBB = (DDD, EEE)",
        "CCC = (ZZZ, GGG)",
        "DDD = (DDD, DDD)",
        "EEE = (EEE, EEE)",
        "GGG = (GGG, GGG)",
        "ZZZ = (ZZZ, ZZZ)",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 2), result);
}

test "solve part 1 test 2" {
    const test_input = [_][]const u8{
        "LLR",
        "",
        "AAA = (BBB, BBB)",
        "BBB = (AAA, ZZZ)",
        "ZZZ = (ZZZ, ZZZ)",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 6), result);
}

test "solve part 2" {
    const test_input = [_][]const u8{
        "LR",
        "",
        "11A = (11B, XXX)",
        "11B = (XXX, 11Z)",
        "11Z = (11B, XXX)",
        "22A = (22B, XXX)",
        "22B = (22C, 22C)",
        "22C = (22Z, 22Z)",
        "22Z = (22B, 22B)",
        "XXX = (XXX, XXX)",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 6), result);
}

test "test gcd" {
    try std.testing.expectEqual(@as(u64, 6), gcd(48, 18));
}

test "test lcm" {
    try std.testing.expectEqual(@as(u64, 12), lcm(4, 6));
}
