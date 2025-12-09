const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Point = @Vector(2, i64);
const Line = struct { Point, Point };

fn parsePoints(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Point) {
    var points: std.ArrayList(Point) = try .initCapacity(allocator, input.len);
    errdefer points.deinit(allocator);

    for (input) |line| {
        var it = std.mem.splitScalar(u8, line, ',');
        const x_str = it.next() orelse return error.MalformedInput;
        const y_str = it.next() orelse return error.MalformedInput;
        points.appendAssumeCapacity(.{
            try std.fmt.parseInt(i64, x_str, 10),
            try std.fmt.parseInt(i64, y_str, 10),
        });
        std.debug.assert(it.next() == null);
    }

    return points;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var points = try parsePoints(allocator, input);
    defer points.deinit(allocator);

    var result: u64 = 0;

    for (0..points.items.len) |i| {
        for (0..points.items.len) |j| {
            if (i == j) continue;

            const dimensions = @abs(points.items[i] - points.items[j]) + @as(@Vector(2, u64), @splat(1));
            const area = @reduce(.Mul, dimensions);
            if (area > result) {
                result = area;
            }
        }
    }

    return result;
}

fn buildEdges(allocator: std.mem.Allocator, points: []const Point) !std.ArrayList(Line) {
    var lines: std.ArrayList(Line) = try .initCapacity(allocator, points.len);
    errdefer lines.deinit(allocator);

    for (0..points.len - 1) |ix| {
        lines.appendAssumeCapacity(.{ points[ix], points[ix + 1] });
    }

    lines.appendAssumeCapacity(.{ points[points.len - 1], points[0] });
    return lines;
}

fn buildPerimeter(allocator: std.mem.Allocator, points: []const Point) !common.AutoHashSet(Point) {
    var edges = try buildEdges(allocator, points);
    defer edges.deinit(allocator);

    var perimeter = common.AutoHashSet(Point).init(allocator);
    errdefer perimeter.deinit();

    for (edges.items) |line| {
        const x1, const y1 = line[0];
        const x2, const y2 = line[1];

        if (x1 == x2) {
            var y = @min(y1, y2);
            const to = @max(y1, y2);
            while (y <= to) : (y += 1) {
                try perimeter.put(.{ x1, y });
            }
        } else if (y1 == y2) {
            var x = @min(x1, x2);
            const to = @max(x1, x2);
            while (x <= to) : (x += 1) {
                try perimeter.put(.{ x, y1 });
            }
        } else unreachable;
    }

    return perimeter;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var points = try parsePoints(allocator, input);
    defer points.deinit(allocator);

    var perimeter = try buildPerimeter(allocator, points.items);
    defer perimeter.deinit();

    const PotentialSolution = struct {
        p1: Point,
        p2: Point,
        area: u64,
        fn compare(_: void, a: @This(), b: @This()) std.math.Order {
            return std.math.order(a.area, b.area).invert();
        }
    };

    var solutions: std.PriorityQueue(PotentialSolution, void, PotentialSolution.compare) = .init(allocator, {});
    defer solutions.deinit();

    for (0..points.items.len) |i| {
        for (0..points.items.len) |j| {
            if (i == j) continue;

            const p1 = points.items[i];
            const p2 = points.items[j];

            const dimensions = @abs(p1 - p2) + @as(@Vector(2, u64), @splat(1));
            const area = @reduce(.Mul, dimensions);
            try solutions.add(.{ .p1 = p1, .p2 = p2, .area = area });
        }
    }

    outer_loop: while (solutions.removeOrNull()) |solution| {
        const p1 = solution.p1;
        const p2 = solution.p2;

        const left = @min(p1[0], p2[0]);
        const right = @max(p1[0], p2[0]);

        const top = @min(p1[1], p2[1]);
        const bottom = @max(p1[1], p2[1]);

        var perimeter_it = perimeter.iterator();
        while (perimeter_it.next()) |point| {
            const x, const y = point.*;

            const c1 = x > left;
            const c2 = x < right;

            const c3 = y > top;
            const c4 = y < bottom;
            if (c1 and c2 and c3 and c4) {
                continue :outer_loop;
            }
        }

        return solution.area;
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
        "7,1",
        "11,1",
        "11,7",
        "9,7",
        "9,5",
        "2,5",
        "2,3",
        "7,3",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 50), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "7,1",
        "11,1",
        "11,7",
        "9,7",
        "9,5",
        "2,5",
        "2,3",
        "7,3",
    };
    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 24), result);
}
