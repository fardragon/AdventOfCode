const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Point3D = @Vector(3, i64);

fn parseMap(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Point3D) {
    var points: std.ArrayList(Point3D) = try .initCapacity(allocator, input.len);
    errdefer points.deinit(allocator);

    for (input) |line| {
        var it = std.mem.splitScalar(u8, line, ',');
        const x_str = it.next() orelse return error.MalformedInput;
        const y_str = it.next() orelse return error.MalformedInput;
        const z_str = it.next() orelse return error.MalformedInput;
        points.appendAssumeCapacity(.{
            try std.fmt.parseInt(i64, x_str, 10),
            try std.fmt.parseInt(i64, y_str, 10),
            try std.fmt.parseInt(i64, z_str, 10),
        });
        std.debug.assert(it.next() == null);
    }

    return points;
}

const JunctionBox = struct {
    position: Point3D,
    circuit_id: usize,

    fn distanceSquared(lhs: *const JunctionBox, rhs: *const JunctionBox) !usize {
        return @reduce(.Add, @abs(lhs.position - rhs.position) * @abs(lhs.position - rhs.position));
    }
};

const Distance = struct {
    from: usize,
    to: usize,
    distance: usize,

    fn lessThan(_: void, lhs: Distance, rhs: Distance) bool {
        return lhs.distance < rhs.distance;
    }
};

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var points = try parseMap(allocator, input);
    defer points.deinit(allocator);

    var boxes: std.ArrayList(JunctionBox) = try .initCapacity(allocator, points.items.len);
    defer boxes.deinit(allocator);

    for (points.items, 0..) |point, idx| {
        boxes.appendAssumeCapacity(.{
            .circuit_id = idx,
            .position = point,
        });
    }

    var distances: std.ArrayList(Distance) = try .initCapacity(allocator, boxes.items.len * (boxes.items.len - 1) / 2);
    defer distances.deinit(allocator);

    for (0..boxes.items.len) |i| {
        for ((i + 1)..boxes.items.len) |j| {
            distances.appendAssumeCapacity(.{
                .from = i,
                .to = j,
                .distance = try JunctionBox.distanceSquared(&boxes.items[i], &boxes.items[j]),
            });
        }
    }

    std.mem.sort(Distance, distances.items, {}, Distance.lessThan);

    const connections_to_make = if (@import("builtin").is_test) 10 else 1000;

    for (0..connections_to_make) |ix| {
        const current_distance = distances.items[ix];

        const box_a = boxes.items[current_distance.from];
        const box_b = boxes.items[current_distance.to];

        if (box_a.circuit_id == box_b.circuit_id) continue;

        for (boxes.items) |*box| {
            if (box.circuit_id == box_b.circuit_id) {
                box.circuit_id = box_a.circuit_id;
            }
        }
    }

    var circuit_counter = try allocator.alloc(usize, boxes.items.len);
    defer allocator.free(circuit_counter);

    @memset(circuit_counter, 0);

    for (boxes.items) |box| {
        circuit_counter[box.circuit_id] += 1;
    }
    std.mem.sort(usize, circuit_counter, {}, std.sort.desc(usize));

    return circuit_counter[0] * circuit_counter[1] * circuit_counter[2];
}

fn everythingConnected(boxes: []const JunctionBox) bool {
    std.debug.assert(boxes.len >= 2);

    const target_it = boxes[0].circuit_id;
    for (boxes[1..]) |box| {
        if (box.circuit_id != target_it) {
            return false;
        }
    }
    return true;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var points = try parseMap(allocator, input);
    defer points.deinit(allocator);

    var boxes: std.ArrayList(JunctionBox) = try .initCapacity(allocator, points.items.len);
    defer boxes.deinit(allocator);

    for (points.items, 0..) |point, idx| {
        boxes.appendAssumeCapacity(.{
            .circuit_id = idx,
            .position = point,
        });
    }

    var distances: std.ArrayList(Distance) = try .initCapacity(allocator, boxes.items.len * (boxes.items.len - 1) / 2);
    defer distances.deinit(allocator);

    for (0..boxes.items.len) |i| {
        for ((i + 1)..boxes.items.len) |j| {
            distances.appendAssumeCapacity(.{
                .from = i,
                .to = j,
                .distance = try JunctionBox.distanceSquared(&boxes.items[i], &boxes.items[j]),
            });
        }
    }

    std.mem.sort(Distance, distances.items, {}, Distance.lessThan);

    for (distances.items) |current_distance| {
        const box_a = boxes.items[current_distance.from];
        const box_b = boxes.items[current_distance.to];

        if (box_a.circuit_id == box_b.circuit_id) continue;

        for (boxes.items) |*box| {
            if (box.circuit_id == box_b.circuit_id) {
                box.circuit_id = box_a.circuit_id;
            }
        }

        if (everythingConnected(boxes.items)) {
            return @intCast(box_a.position[0] * box_b.position[0]);
        }
    }

    return error.LogicError;
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
        "162,817,812",
        "57,618,57",
        "906,360,560",
        "592,479,940",
        "352,342,300",
        "466,668,158",
        "542,29,236",
        "431,825,988",
        "739,650,466",
        "52,470,668",
        "216,146,977",
        "819,987,18",
        "117,168,530",
        "805,96,715",
        "346,949,466",
        "970,615,88",
        "941,993,340",
        "862,61,35",
        "984,92,344",
        "425,690,689",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 40), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "162,817,812",
        "57,618,57",
        "906,360,560",
        "592,479,940",
        "352,342,300",
        "466,668,158",
        "542,29,236",
        "431,825,988",
        "739,650,466",
        "52,470,668",
        "216,146,977",
        "819,987,18",
        "117,168,530",
        "805,96,715",
        "346,949,466",
        "970,615,88",
        "941,993,340",
        "862,61,35",
        "984,92,344",
        "425,690,689",
    };
    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 25272), result);
}
