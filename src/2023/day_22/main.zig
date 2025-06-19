const std = @import("std");
const common = @import("common");
const common_input = common.input;
const String = common.String;

const Brick = struct {
    x1: usize,
    y1: usize,
    z1: usize,
    x2: usize,
    y2: usize,
    z2: usize,

    fn init(coordinates: [6]usize) Brick {
        const t = @typeInfo(Brick);
        var self: Brick = undefined;
        inline for (t.@"struct".fields, 0..) |field, ix| {
            @field(self, field.name) = coordinates[ix];
        }
        return self;
    }

    fn sortByZ1(_: void, lhs: Brick, rhs: Brick) bool {
        return lhs.z1 < rhs.z1;
    }
};

const Position2D = struct {
    x: usize,
    y: usize,
};

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Brick) {
    var bricks = std.ArrayList(Brick).init(allocator);
    errdefer {
        bricks.deinit();
    }

    for (input) |line| {
        var it = std.mem.splitAny(u8, line, ",~");

        var ix: usize = 0;
        var nums: [6]usize = undefined;
        while (it.next()) |num| {
            nums[ix] = try std.fmt.parseInt(usize, num, 10);
            ix += 1;
        }

        try bricks.append(Brick.init(nums));
    }

    return bricks;
}

fn crash(allocator: std.mem.Allocator, children_map: std.AutoArrayHashMap(usize, std.AutoArrayHashMap(usize, void)), brick_index: usize) !u64 {
    var deps = std.AutoArrayHashMap(usize, usize).init(allocator);
    defer deps.deinit();

    for (children_map.values()) |children| {
        for (children.keys()) |c| {
            const entry = try deps.getOrPut(c);

            if (entry.found_existing) {
                entry.value_ptr.* += 1;
            } else {
                entry.value_ptr.* = 1;
            }
        }
    }

    var result: u64 = 0;

    var queue = std.ArrayList(usize).init(allocator);
    defer queue.deinit();

    try queue.append(brick_index);

    while (queue.pop()) |ix| {
        result += 1;
        if (children_map.get(ix)) |children| {
            for (children.keys()) |c| {
                const entry = deps.getPtr(c).?;
                entry.* -= 1;
                if (entry.* == 0) {
                    try queue.append(c);
                }
            }
        }
    }

    return result - 1;
}

fn solve(allocator: std.mem.Allocator, input: []const []const u8) !common.Pair(u64, u64) {
    var bricks = try parseInput(allocator, input);
    defer {
        bricks.deinit();
    }

    std.sort.heap(Brick, bricks.items, {}, Brick.sortByZ1);

    const ZCacheElement = common.Pair(usize, usize);
    var highestZ = std.AutoArrayHashMap(Position2D, ZCacheElement).init(allocator);
    defer highestZ.deinit();

    const ground = std.math.maxInt(usize);

    var children_map = std.AutoArrayHashMap(usize, std.AutoArrayHashMap(usize, void)).init(allocator);
    var parents_map = std.AutoArrayHashMap(usize, std.AutoArrayHashMap(usize, void)).init(allocator);

    defer {
        for (children_map.values()) |*val| {
            val.deinit();
        }
        children_map.deinit();

        for (parents_map.values()) |*val| {
            val.deinit();
        }
        parents_map.deinit();
    }

    for (bricks.items, 0..) |brick, ix| {
        var newZ: usize = 0;
        for (@min(brick.x1, brick.x2)..@max(brick.x1, brick.x2) + 1) |x| {
            for (@min(brick.y1, brick.y2)..@max(brick.y1, brick.y2) + 1) |y| {
                const pos = Position2D{ .x = x, .y = y };
                if (highestZ.get(pos)) |entry| {
                    newZ = @max(newZ, entry.first);
                }
            }
        }
        const height = brick.z2 - brick.z1 + 1;

        for (@min(brick.x1, brick.x2)..@max(brick.x1, brick.x2) + 1) |x| {
            for (@min(brick.y1, brick.y2)..@max(brick.y1, brick.y2) + 1) |y| {
                const pos = Position2D{ .x = x, .y = y };

                if (highestZ.get(pos)) |old| {
                    if ((old.first) == newZ) {
                        const c_entry = try children_map.getOrPut(old.second);
                        if (!c_entry.found_existing) c_entry.value_ptr.* = std.AutoArrayHashMap(usize, void).init(allocator);
                        try c_entry.value_ptr.*.put(ix, {});

                        const p_entry = try parents_map.getOrPut(ix);
                        if (!p_entry.found_existing) p_entry.value_ptr.* = std.AutoArrayHashMap(usize, void).init(allocator);
                        try p_entry.value_ptr.*.put(old.second, {});
                    }
                } else if (brick.z1 == 1) {
                    const c_entry = try children_map.getOrPut(ground);
                    if (!c_entry.found_existing) c_entry.value_ptr.* = std.AutoArrayHashMap(usize, void).init(allocator);
                    try c_entry.value_ptr.*.put(ix, {});
                }

                try highestZ.put(pos, ZCacheElement{
                    .first = newZ + height,
                    .second = ix,
                });
            }
        }
    }

    var unsafeBricks = std.AutoArrayHashMap(usize, void).init(allocator);
    defer unsafeBricks.deinit();

    var it = parents_map.iterator();
    while (it.next()) |entry| {
        // std.debug.print("{any}:{any}\n", .{ entry.key_ptr.*, entry.value_ptr.*.keys() });
        if (entry.value_ptr.*.keys().len == 1) {
            const unsafe_brick = entry.value_ptr.*.keys()[0];
            // std.debug.print("Unsafe brick:{d}\n", .{unsafe_brick});
            try unsafeBricks.put(unsafe_brick, {});
        }
    }

    var part2_result: u64 = 0;

    for (unsafeBricks.keys()) |unsafe_brick| {
        part2_result += try crash(allocator, children_map, unsafe_brick);
    }

    return common.Pair(u64, u64){
        .first = bricks.items.len - unsafeBricks.keys().len,
        .second = part2_result,
    };
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    return (try solve(allocator, input)).first;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    return (try solve(allocator, input)).second;
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
        "1,1,8~1,1,9",
        "1,0,1~1,2,1",
        "0,0,2~2,0,2",
        "0,2,3~2,2,3",
        "0,0,4~0,2,4",
        "2,0,5~2,2,5",
        "0,1,6~2,1,6",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 5), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "1,1,8~1,1,9",
        "1,0,1~1,2,1",
        "0,0,2~2,0,2",
        "0,2,3~2,2,3",
        "0,0,4~0,2,4",
        "2,0,5~2,2,5",
        "0,1,6~2,1,6",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 7), result);
}
