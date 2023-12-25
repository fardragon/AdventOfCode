const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Node = struct {
    name: []const u8,
    connections: std.ArrayList([]const u8),

    fn deinit(self: *Node) void {
        self.connections.deinit();
    }
};

const Graph = std.StringArrayHashMap(Node);

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !Graph {
    var result = Graph.init(allocator);
    errdefer {
        for (result.values()) |*node| {
            node.deinit();
        }
        result.deinit();
    }

    for (input) |line| {
        const node_name = line[0..3];
        var node_connections = std.ArrayList([]const u8).init(allocator);
        errdefer node_connections.deinit();

        var it = std.mem.splitScalar(u8, line[5..line.len], ' ');
        while (it.next()) |connection| {
            try node_connections.append(connection);

            var reverse = try result.getOrPut(connection);
            if (reverse.found_existing) {
                try reverse.value_ptr.connections.append(node_name);
            } else {
                reverse.value_ptr.name = connection;
                reverse.value_ptr.connections = std.ArrayList([]const u8).init(allocator);
                try reverse.value_ptr.connections.append(node_name);
            }
        }

        var entry = try result.getOrPut(node_name);

        if (entry.found_existing) {
            try entry.value_ptr.*.connections.appendSlice(node_connections.items);
            node_connections.deinit();
        } else {
            entry.value_ptr.* = Node{
                .name = node_name,
                .connections = node_connections,
            };
        }
    }

    return result;
}

fn findLinks(allocator: std.mem.Allocator, graph: *const Graph, cluster: *const std.StringArrayHashMap(void)) !std.StringArrayHashMap(void) {
    var links = std.StringArrayHashMap(void).init(allocator);
    errdefer links.deinit();

    for (cluster.keys()) |node| {
        for (graph.get(node).?.connections.items) |to| {
            if (!cluster.contains(to)) {
                try links.put(to, {});
            }
        }
    }

    return links;
}

fn growCluster(
    allocator: std.mem.Allocator,
    graph: *const Graph,
    cluster: *const std.StringArrayHashMap(void),
    links: *const std.StringArrayHashMap(void),
    seen: *std.StringArrayHashMap(void),
    result: *u64,
) !void {
    if (links.keys().len == 0) return;
    if (links.keys().len == 3) {
        for (cluster.keys()) |node| {
            try seen.put(node, {});
        }

        result.* *= cluster.keys().len;
        return;
    }

    for (links.keys()) |node| {
        if (seen.contains(node)) continue;

        var cluster2 = try cluster.clone();
        defer cluster2.deinit();

        try cluster2.put(node, {});

        var size: usize = 0;

        while (size < cluster2.keys().len) {
            size = cluster2.keys().len;

            for (graph.keys()) |node_int| {
                if (cluster2.contains(node_int)) continue;

                var links_counter: u64 = 0;
                for (graph.get(node_int).?.connections.items) |node2| {
                    if (cluster2.contains(node2)) links_counter += 1;
                }

                if (links_counter > 1) {
                    try cluster2.put(node_int, {});
                }
            }
        }

        var links2 = try findLinks(allocator, graph, &cluster2);
        defer links2.deinit();
        try growCluster(allocator, graph, &cluster2, &links2, seen, result);
    }
}

fn makeCluster(
    allocator: std.mem.Allocator,
    graph: *const Graph,
    starting_node: []const u8,
    seen: *std.StringArrayHashMap(void),
    result: *u64,
) !void {
    var cluster = std.StringArrayHashMap(void).init(allocator);
    defer cluster.deinit();

    try cluster.put(starting_node, {});
    for (graph.get(starting_node).?.connections.items) |node| {
        try cluster.put(node, {});
    }

    var links = try findLinks(allocator, graph, &cluster);
    defer links.deinit();

    try growCluster(allocator, graph, &cluster, &links, seen, result);
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var graph = try parseInput(allocator, input);
    defer {
        for (graph.values()) |*node| {
            node.deinit();
        }
        graph.deinit();
    }

    var result: u64 = 1;
    var seen = std.StringArrayHashMap(void).init(allocator);
    defer seen.deinit();

    for (graph.values()) |node| {
        if (seen.contains(node.name)) continue;
        try makeCluster(allocator, &graph, node.name, &seen, &result);
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
}

test "solve part 1 test" {
    const test_input = [_][]const u8{
        "jqt: rhn xhk nvd",
        "rsh: frs pzl lsr",
        "xhk: hfx",
        "cmg: qnr nvd lhk bvb",
        "rhn: xhk bvb hfx",
        "bvb: xhk hfx",
        "pzl: lsr hfx nvd",
        "qnr: nvd",
        "ntq: jqt hfx bvb xhk",
        "nvd: lhk",
        "lsr: lhk",
        "rzs: qnr cmg lsr rsh",
        "frs: qnr lhk lsr",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 54), result);
}
