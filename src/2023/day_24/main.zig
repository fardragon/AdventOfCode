const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Vector3D = struct {
    x: i64,
    y: i64,
    z: i64,

    fn init(nums: []const i64) Vector3D {
        return Vector3D{
            .x = nums[0],
            .y = nums[1],
            .z = nums[2],
        };
    }

    fn eq(self: Vector3D, other: Vector3D) bool {
        return self.x == other.x and self.y == other.y and self.z == other.z;
    }
};

const Intersection3D = struct {
    position: Vector3D,
    p: f64,
    q: f64,

    fn eq(self: Intersection3D, other: Intersection3D) bool {
        return self.position.eq(other.position);
    }
};

const Hailstone = struct {
    position: Vector3D,
    velocity: Vector3D,

    fn slope2D(self: Hailstone) f64 {
        const x1: f64 = @floatFromInt(self.position.x);
        const y1: f64 = @floatFromInt(self.position.y);

        const x2: f64 = @floatFromInt(self.position.x + self.velocity.x);
        const y2: f64 = @floatFromInt(self.position.y + self.velocity.y);

        return (y2 - y1) / (x2 - x1);
    }

    fn intercept2D(self: Hailstone) f64 {
        const m = self.slope2D();

        const x: f64 = @floatFromInt(self.position.x);
        const y: f64 = @floatFromInt(self.position.y);

        return y - m * x;
    }

    fn at(self: Hailstone, x: f64) f64 {
        const m = self.slope2D();
        const b = self.intercept2D();
        return m * x + b;
    }

    fn inFutureX(self: Hailstone, x: f64) bool {
        return std.math.sign(x - @as(f64, @floatFromInt(self.position.x))) == @as(f64, @floatFromInt(std.math.sign(self.velocity.x)));
    }

    fn offsetVelocity(self: Hailstone, dx: i64, dy: i64, dz: i64) Hailstone {
        return Hailstone{
            .position = self.position,
            .velocity = Vector3D{
                .x = self.velocity.x - dx,
                .y = self.velocity.y - dy,
                .z = self.velocity.z - dz,
            },
        };
    }
};

fn instersect(first: Hailstone, second: Hailstone) ?f64 {
    const m1 = first.slope2D();
    const m2 = second.slope2D();

    // check parallel
    if (m1 == m2) return null;

    const b1 = first.intercept2D();
    const b2 = second.intercept2D();

    return (b2 - b1) / (m1 - m2);
}

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Hailstone) {
    var result = std.ArrayList(Hailstone).empty;
    errdefer result.deinit(allocator);

    for (input) |line| {
        var it = std.mem.splitAny(u8, line, ", @");

        var nums: [6]i64 = undefined;
        var ix: usize = 0;
        while (it.next()) |str| {
            if (str.len == 0) continue;
            nums[ix] = try std.fmt.parseInt(i64, str, 10);
            ix += 1;
        }

        try result.append(allocator, Hailstone{
            .position = Vector3D.init(nums[0..3]),
            .velocity = Vector3D.init(nums[3..6]),
        });
    }

    return result;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8, test_area_start: f64, test_area_end: f64) !u64 {
    var hailstones = try parseInput(allocator, input);
    defer hailstones.deinit(allocator);

    var result: u64 = 0;

    for (0..hailstones.items.len - 1) |ix1| {
        for (ix1 + 1..hailstones.items.len) |ix2| {
            const stone1 = hailstones.items[ix1];
            const stone2 = hailstones.items[ix2];

            const intersection_x = instersect(stone1, stone2);
            if (intersection_x == null) continue;
            if (intersection_x.? < test_area_start or intersection_x.? > test_area_end) continue;
            if (!stone1.inFutureX(intersection_x.?) or !stone2.inFutureX(intersection_x.?)) continue;
            const intersection_y = stone1.at(intersection_x.?);
            if (intersection_y < test_area_start or intersection_y > test_area_end) continue;

            result += 1;
        }
    }

    return result;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !i64 {
    var hailstones = try parseInput(allocator, input);
    defer hailstones.deinit(allocator);

    const range: i64 = 500;

    var vx = -range;
    while (vx <= range) : (vx += 1) {
        var vy = -range;
        while (vy <= range) : (vy += 1) {
            var vz = -range;
            while (vz <= range) : (vz += 1) {
                if (vx == 0 or vy == 0 or vz == 0) {
                    continue;
                }

                const h1 = hailstones.items[0].offsetVelocity(vx, vy, vz);
                const h2 = hailstones.items[1].offsetVelocity(vx, vy, vz);

                const A = h1.position.x;
                const a = h1.velocity.x;
                const B = h1.position.y;
                const b = h1.velocity.y;

                const C = h2.position.x;
                const c = h2.velocity.x;
                const D = h2.position.y;
                const d = h2.velocity.y;

                if (c == 0 or (a * d) - ((b * c)) == 0) {
                    continue;
                }

                const t = @divTrunc((d * (C - A) - c * (D - B)), ((a * d) - (b * c)));

                const x = h1.position.x + h1.velocity.x * t;
                const y = h1.position.y + h1.velocity.y * t;
                const z = h1.position.z + h1.velocity.z * t;

                var all_match = true;

                for (hailstones.items) |h| {
                    const u = if (h.velocity.x != vx) @divTrunc((x - h.position.x), (h.velocity.x - vx)) else if (h.velocity.y != vy) @divTrunc((y - h.position.y), (h.velocity.y - vy)) else if (h.velocity.z != vz) @divTrunc((z - h.position.z), (h.velocity.z - vz)) else unreachable;

                    if ((x + u * vx != h.position.x + u * h.velocity.x) or (y + u * vy != h.position.y + u * h.velocity.y) or (z + u * vz != h.position.z + u * h.velocity.z)) {
                        all_match = false;
                        break;
                    }
                }

                if (all_match) {
                    return x + y + z;
                }
            }
        }
    }
    unreachable;
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

    std.debug.print("Part 1 solution: {d}\n", .{try solvePart1(
        allocator,
        input.items,
        200000000000000,
        400000000000000,
    )});
    std.debug.print("Part 2 solution: {d}\n", .{try solvePart2(
        allocator,
        input.items,
    )});
}

test "solve part 1 test" {
    const test_input = [_][]const u8{
        "19, 13, 30 @ -2,  1, -2",
        "18, 19, 22 @ -1, -1, -2",
        "20, 25, 34 @ -2, -2, -4",
        "12, 31, 28 @ -1, -2, -1",
        "20, 19, 15 @  1, -5, -3",
    };

    const result = try solvePart1(std.testing.allocator, &test_input, 7, 27);

    try std.testing.expectEqual(@as(u64, 2), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "19, 13, 30 @ -2,  1, -2",
        "18, 19, 22 @ -1, -1, -2",
        "20, 25, 34 @ -2, -2, -4",
        "12, 31, 28 @ -1, -2, -1",
        "20, 19, 15 @  1, -5, -3",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(i64, 47), result);
}
