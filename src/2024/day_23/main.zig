const std = @import("std");
const common = @import("common");
const common_input = common.input;
const String = common.String;
const Graph = std.StringArrayHashMap(common.StringHashSet);

const Triplet = struct {
    a: [2]u8,
    b: [2]u8,
    c: [2]u8,
};

fn graphInsert(graph: *Graph, a: []const u8, b: []const u8) !void {
    const put_result = try graph.getOrPut(a);
    if (put_result.found_existing) {
        try put_result.value_ptr.*.put(b);
    } else {
        var set = common.StringHashSet.init(graph.allocator);
        errdefer set.deinit();
        try set.put(b);
        put_result.value_ptr.* = set;
    }
}

fn parseGraph(allocator: std.mem.Allocator, input: []const []const u8) !Graph {
    var graph = Graph.init(allocator);
    errdefer {
        for (graph.values()) |*set| {
            set.deinit();
        }
        graph.deinit();
    }

    for (input) |line| {
        var it = std.mem.splitScalar(u8, line, '-');

        const left = it.next();
        const right = it.next();

        if (left == null or right == null) return error.InvalidInput;
        try graphInsert(&graph, left.?, right.?);
        try graphInsert(&graph, right.?, left.?);
    }

    return graph;
}

fn countTriplet(triplets: *std.AutoHashMap(Triplet, void), a: []const u8, b: []const u8, c: []const u8) !void {
    var arr: [3][2]u8 = undefined;

    @memcpy(&arr[0], a[0..2]);
    @memcpy(&arr[1], b[0..2]);
    @memcpy(&arr[2], c[0..2]);

    const lessThanFn = struct {
        fn lessThanFn(_: void, lhs: [2]u8, rhs: [2]u8) bool {
            return std.mem.lessThan(u8, &lhs, &rhs);
        }
    }.lessThanFn;

    std.mem.sort([2]u8, &arr, {}, lessThanFn);

    var key: Triplet = undefined;
    @memcpy(&key.a, &arr[0]);
    @memcpy(&key.b, &arr[1]);
    @memcpy(&key.c, &arr[2]);

    try triplets.put(key, {});
}

fn intersect(allocator: std.mem.Allocator, a: common.StringHashSet, b: common.StringHashSet) !common.StringHashSet {
    var result = common.StringHashSet.init(allocator);
    errdefer result.deinit();

    var it = a.iterator();
    while (it.next()) |item| {
        if (b.contains(item.*)) {
            try result.put(item.*);
        }
    }

    return result;
}

fn prepare_result(allocator: std.mem.Allocator, r: common.StringHashSet) ![]u8 {
    const result_length = (r.count() * 2) + (r.count() - 1);

    var result = try allocator.alloc(u8, result_length);
    errdefer allocator.free(result);

    const nodes = try allocator.alloc([2]u8, r.count());
    defer allocator.free(nodes);

    {
        var it = r.iterator();
        var out_it: usize = 0;
        while (it.next()) |item| {
            @memcpy(&nodes[out_it], item.*[0..2]);
            out_it += 1;
        }

        const lessThanFn = struct {
            fn lessThanFn(_: void, lhs: [2]u8, rhs: [2]u8) bool {
                return std.mem.lessThan(u8, &lhs, &rhs);
            }
        }.lessThanFn;
        std.mem.sort([2]u8, nodes, {}, lessThanFn);
    }

    {
        @memset(result, ',');
        var out_it: usize = 0;
        for (nodes) |item| {
            result[out_it] = item[0];
            result[out_it + 1] = item[1];
            out_it += 3;
        }
    }

    return result;
}

fn bron_kerbosch(allocator: std.mem.Allocator, graph: Graph, r: common.StringHashSet, p: common.StringHashSet, x: *common.StringHashSet) !?[]u8 {
    if (p.count() == 0 and x.count() == 0) {
        return try prepare_result(allocator, r);
    }

    var result: ?[]u8 = null;

    var p_copy = try p.clone();
    defer p_copy.deinit();

    var p_iter = p.iterator();
    while (p_iter.next()) |vertex| {
        var r_new = try r.clone();
        defer r_new.deinit();
        try r_new.put(vertex.*);

        var p_new = try intersect(allocator, p_copy, graph.get(vertex.*).?);
        defer p_new.deinit();

        var x_new = try intersect(allocator, x.*, graph.get(vertex.*).?);
        defer x_new.deinit();

        if (try bron_kerbosch(allocator, graph, r_new, p_new, &x_new)) |tmp_result| {
            if (result == null) {
                result = tmp_result;
            } else {
                if (tmp_result.len > result.?.len) {
                    allocator.free(result.?);
                    result = tmp_result;
                } else {
                    allocator.free(tmp_result);
                }
            }
        }

        _ = p_copy.remove(vertex.*);
        try x.put(vertex.*);
    }

    return result;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var graph = try parseGraph(allocator, input);
    defer {
        for (graph.values()) |*set| {
            set.deinit();
        }
        graph.deinit();
    }

    var triplets: std.AutoHashMap(Triplet, void) = std.AutoHashMap(Triplet, void).init(allocator);
    defer triplets.deinit();

    var it1 = graph.iterator();

    while (it1.next()) |n1| {
        var it2 = graph.iterator();
        while (it2.next()) |n2| {
            if (n1.key_ptr == n2.key_ptr) continue;
            var it3 = graph.iterator();
            while (it3.next()) |n3| {
                if (n1.key_ptr == n3.key_ptr or n2.key_ptr == n3.key_ptr) continue;

                if (n1.value_ptr.contains(n2.key_ptr.*) and n2.value_ptr.contains(n3.key_ptr.*) and n3.value_ptr.contains(n1.key_ptr.*)) {
                    if (n1.key_ptr.*[0] == 't' or n2.key_ptr.*[0] == 't' or n3.key_ptr.*[0] == 't') {
                        try countTriplet(&triplets, n1.key_ptr.*, n2.key_ptr.*, n3.key_ptr.*);
                    }
                }
            }
        }
    }

    return triplets.count();
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) ![]u8 {
    var graph = try parseGraph(allocator, input);
    defer {
        for (graph.values()) |*set| {
            set.deinit();
        }
        graph.deinit();
    }

    var r = common.StringHashSet.init(allocator);
    defer r.deinit();

    var p = common.StringHashSet.init(allocator);
    defer p.deinit();
    for (graph.keys()) |key| {
        try p.put(key);
    }

    var x = common.StringHashSet.init(allocator);
    defer x.deinit();

    return (try bron_kerbosch(allocator, graph, r, p, &x)).?;
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
    const part2_result = try solvePart2(allocator, input.items);
    defer allocator.free(part2_result);
    std.debug.print("Part 2 solution: {s}\n", .{part2_result});
}

const test_input = [_][]const u8{
    "kh-tc",
    "qp-kh",
    "de-cg",
    "ka-co",
    "yn-aq",
    "qp-ub",
    "cg-tb",
    "vc-aq",
    "tb-ka",
    "wh-tc",
    "yn-cg",
    "kh-ub",
    "ta-co",
    "de-co",
    "tc-td",
    "tb-wq",
    "wh-td",
    "ta-ka",
    "td-qp",
    "aq-cg",
    "wq-ub",
    "ub-vc",
    "de-ta",
    "wq-aq",
    "wq-vc",
    "wh-yn",
    "ka-de",
    "kh-ta",
    "co-tc",
    "wh-qp",
    "tb-vc",
    "td-yn",
};

test "solve part 1 test" {
    const allocator = std.testing.allocator;

    const result = try solvePart1(allocator, &test_input);
    try std.testing.expectEqual(@as(u64, 7), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;

    const result = try solvePart2(allocator, &test_input);
    defer allocator.free(result);
    try std.testing.expectEqualStrings("co,de,ka,ta", result);
}
