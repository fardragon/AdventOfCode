const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Puzzle = struct {
    grid: std.ArrayList(u8),
    width: usize,
    height: usize,
    start: usize,
    end: usize,

    fn mapToX(self: Puzzle, index: usize) usize {
        return index % self.width;
    }

    fn mapToY(self: Puzzle, index: usize) usize {
        return index / self.width;
    }

    fn mapToIndex(self: Puzzle, x: usize, y: usize) usize {
        return y * self.width + x;
    }

    fn deinit(self: *Puzzle) void {
        self.grid.deinit();
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !Puzzle {
    var result = Puzzle{
        .grid = std.ArrayList(u8).init(allocator),
        .width = input[0].len,
        .height = input.len,
        .start = undefined,
        .end = undefined,
    };
    errdefer result.deinit();

    for (input) |line| {
        try result.grid.appendSlice(line);
    }

    result.start = std.mem.indexOfScalar(u8, result.grid.items[0..result.width], '.').?;
    result.end = std.mem.indexOfScalar(u8, result.grid.items[(result.height - 1) * result.width .. result.grid.items.len], '.').? +
        (result.height - 1) * result.width;

    return result;
}

fn findNeighbours(allocator: std.mem.Allocator, puzzle: *const Puzzle, x: usize, y: usize) !std.ArrayList(usize) {
    var neighbours = std.ArrayList(usize).init(allocator);
    errdefer neighbours.deinit();

    if (x > 0) {
        const new_x = x - 1;
        const new_y = y;
        const new_index = puzzle.mapToIndex(new_x, new_y);
        if (puzzle.grid.items[new_index] != '#') {
            try neighbours.append(new_index);
        }
    }

    if (x < puzzle.width - 1) {
        const new_x = x + 1;
        const new_y = y;
        const new_index = puzzle.mapToIndex(new_x, new_y);
        if (puzzle.grid.items[new_index] != '#') {
            try neighbours.append(new_index);
        }
    }

    if (y > 0) {
        const new_x = x;
        const new_y = y - 1;
        const new_index = puzzle.mapToIndex(new_x, new_y);
        if (puzzle.grid.items[new_index] != '#') {
            try neighbours.append(new_index);
        }
    }

    if (y < puzzle.height - 1) {
        const new_x = x;
        const new_y = y + 1;
        const new_index = puzzle.mapToIndex(new_x, new_y);
        if (puzzle.grid.items[new_index] != '#') {
            try neighbours.append(new_index);
        }
    }

    return neighbours;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var puzzle = try parseInput(allocator, input);
    defer puzzle.deinit();

    const QueueItem = common.Pair(usize, std.AutoArrayHashMap(usize, void));

    var queue = std.ArrayList(QueueItem).init(allocator);
    defer {
        for (queue.items) |*qitem| {
            qitem.second.deinit();
        }
        queue.deinit();
    }

    try queue.append(QueueItem{
        .first = puzzle.start,
        .second = std.AutoArrayHashMap(usize, void).init(allocator),
    });

    var distance: u64 = 0;

    while (queue.items.len > 0) {
        const qitem = queue.orderedRemove(0);
        const position = qitem.first;
        var visited = qitem.second;
        defer visited.deinit();

        if (position == puzzle.end and visited.keys().len > distance) {
            distance = visited.keys().len;
        } else {
            const elem = puzzle.grid.items[position];
            const x = puzzle.mapToX(position);
            const y = puzzle.mapToY(position);

            var new_positions = std.ArrayList(usize).init(allocator);
            defer new_positions.deinit();
            switch (elem) {
                '>' => {
                    const new_x = x + 1;
                    const new_y = y;
                    try new_positions.append(puzzle.mapToIndex(new_x, new_y));
                },
                '<' => {
                    const new_x = x - 1;
                    const new_y = y;
                    try new_positions.append(puzzle.mapToIndex(new_x, new_y));
                },
                '^' => {
                    const new_x = x;
                    const new_y = y - 1;
                    try new_positions.append(puzzle.mapToIndex(new_x, new_y));
                },
                'v' => {
                    const new_x = x;
                    const new_y = y + 1;
                    try new_positions.append(puzzle.mapToIndex(new_x, new_y));
                },
                '.' => {
                    new_positions = try findNeighbours(allocator, &puzzle, x, y);
                },
                else => unreachable,
            }

            for (new_positions.items) |np| {
                if (!visited.contains(np)) {
                    var new_visited = try visited.clone();
                    errdefer new_visited.deinit();
                    try new_visited.put(np, {});
                    try queue.append(QueueItem{
                        .first = np,
                        .second = new_visited,
                    });
                }
            }
        }
    }

    return distance;
}

fn findIntersections(allocator: std.mem.Allocator, puzzle: *const Puzzle) !std.ArrayList(usize) {
    var intersections = std.ArrayList(usize).init(allocator);
    errdefer intersections.deinit();

    for (puzzle.grid.items, 0..) |item, ix| {
        if (item != '#') {
            const neighbours = try findNeighbours(allocator, puzzle, puzzle.mapToX(ix), puzzle.mapToY(ix));
            defer neighbours.deinit();
            if (neighbours.items.len > 2) {
                try intersections.append(ix);
            }
        }
    }

    return intersections;
}

fn calculateDistances(
    allocator: std.mem.Allocator,
    puzzle: *const Puzzle,
    starting_node: usize,
    intersections: []const usize,
) !std.AutoArrayHashMap(usize, usize) {
    var distances = std.AutoArrayHashMap(usize, usize).init(allocator);
    errdefer distances.deinit();

    var visited = std.AutoArrayHashMap(usize, void).init(allocator);
    defer visited.deinit();

    const QueueItem = common.Pair(usize, usize);

    var queue = std.ArrayList(QueueItem).init(allocator);
    defer queue.deinit();

    try queue.append(QueueItem{ .first = starting_node, .second = 0 });

    // std.debug.print("BFS from: {d}\n", .{starting_node});

    while (queue.items.len > 0) {
        const qitem = queue.orderedRemove(0);
        const position = qitem.first;
        const distance = qitem.second;

        // std.debug.print("Pos: {d}, distance: {d}\n", .{ position, distance });

        const is_intersection = if (std.mem.indexOfScalar(usize, intersections, position)) |_| true else false;

        if (is_intersection and position != starting_node) {
            try distances.put(position, distance);
            continue;
        }

        var neighbours = try findNeighbours(allocator, puzzle, puzzle.mapToX(position), puzzle.mapToY(position));
        defer neighbours.deinit();

        for (neighbours.items) |neighbour| {
            if (!visited.contains(neighbour)) {
                try visited.put(neighbour, {});
                try queue.append(QueueItem{ .first = neighbour, .second = distance + 1 });
            }
        }
    }

    return distances;
}

fn intersectionsDFS(
    allocator: std.mem.Allocator,
    graph: *const std.AutoArrayHashMap(usize, std.AutoArrayHashMap(usize, usize)),
    start: usize,
    end: usize,
) !u64 {
    const QueueEntry = struct {
        current_node: usize,
        current_distance: u64,
        visited: std.AutoArrayHashMap(usize, void),
    };

    var queue = std.ArrayList(QueueEntry).init(allocator);
    defer {
        for (queue.items) |*entry| {
            entry.visited.deinit();
        }
        queue.deinit();
    }

    var start_entry = QueueEntry{
        .current_node = start,
        .current_distance = 0,
        .visited = std.AutoArrayHashMap(usize, void).init(allocator),
    };

    try start_entry.visited.put(start, {});
    try queue.append(start_entry);

    var max_distance: u64 = 0;

    while (queue.pop()) |qitem| {
        var visited = qitem.visited;
        defer visited.deinit();

        if (qitem.current_node == end) {
            max_distance = @max(max_distance, qitem.current_distance);
            continue;
        }

        const graph_entry = graph.get(qitem.current_node).?;

        var graph_it = graph_entry.iterator();
        while (graph_it.next()) |entry| {
            const neighbour = entry.key_ptr.*;
            const weight = entry.value_ptr.*;
            if (!visited.contains(neighbour)) {
                const new_distance = qitem.current_distance + weight;

                var new_visited = try visited.clone();
                errdefer new_visited.deinit();
                try new_visited.put(neighbour, {});

                try queue.append(QueueEntry{
                    .current_node = neighbour,
                    .current_distance = new_distance,
                    .visited = new_visited,
                });
            }
        }
    }

    return max_distance;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var puzzle = try parseInput(allocator, input);
    defer puzzle.deinit();

    var nodes = try findIntersections(allocator, &puzzle);
    defer nodes.deinit();

    try nodes.insert(0, puzzle.start);
    try nodes.append(puzzle.end);

    // std.debug.print("Nodes: {any}\n", .{nodes.items});

    var graph = std.AutoArrayHashMap(usize, std.AutoArrayHashMap(usize, usize)).init(allocator);
    defer {
        for (graph.values()) |*value| {
            value.deinit();
        }
        graph.deinit();
    }

    for (nodes.items) |node| {
        var distances = try calculateDistances(allocator, &puzzle, node, nodes.items);
        errdefer distances.deinit();

        // var it = distances.iterator();

        // while (it.next()) |entry| {
        //     std.debug.print("({d}, {d}): {d}, ", .{ puzzle.mapToY(entry.key_ptr.*), puzzle.mapToX(entry.key_ptr.*), entry.value_ptr.* });
        // }
        // std.debug.print("\n", .{});

        try graph.put(node, distances);
    }

    return intersectionsDFS(allocator, &graph, puzzle.start, puzzle.end);
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
        "#.#####################",
        "#.......#########...###",
        "#######.#########.#.###",
        "###.....#.>.>.###.#.###",
        "###v#####.#v#.###.#.###",
        "###.>...#.#.#.....#...#",
        "###v###.#.#.#########.#",
        "###...#.#.#.......#...#",
        "#####.#.#.#######.#.###",
        "#.....#.#.#.......#...#",
        "#.#####.#.#.#########v#",
        "#.#...#...#...###...>.#",
        "#.#.#v#######v###.###v#",
        "#...#.>.#...>.>.#.###.#",
        "#####v#.#.###v#.#.###.#",
        "#.....#...#...#.#.#...#",
        "#.#########.###.#.#.###",
        "#...###...#...#...#.###",
        "###.###.#.###v#####v###",
        "#...#...#.#.>.>.#.>.###",
        "#.###.###.#.###.#.#v###",
        "#.....###...###...#...#",
        "#####################.#",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 94), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "#.#####################",
        "#.......#########...###",
        "#######.#########.#.###",
        "###.....#.>.>.###.#.###",
        "###v#####.#v#.###.#.###",
        "###.>...#.#.#.....#...#",
        "###v###.#.#.#########.#",
        "###...#.#.#.......#...#",
        "#####.#.#.#######.#.###",
        "#.....#.#.#.......#...#",
        "#.#####.#.#.#########v#",
        "#.#...#...#...###...>.#",
        "#.#.#v#######v###.###v#",
        "#...#.>.#...>.>.#.###.#",
        "#####v#.#.###v#.#.###.#",
        "#.....#...#...#.#.#...#",
        "#.#########.###.#.#.###",
        "#...###...#...#...#.###",
        "###.###.#.###v#####v###",
        "#...#...#.#.>.>.#.>.###",
        "#.###.###.#.###.#.#v###",
        "#.....###...###...#...#",
        "#####################.#",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 154), result);
}
