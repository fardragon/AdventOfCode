const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Field = enum {
    Empty,
    Byte,
};

const Grid = common.grid.Grid(Field);
const Byte = common.Pair(isize, isize);

fn getEmptyGrid(allocator: std.mem.Allocator, width: usize, height: usize) !Grid {
    var data = try Grid.Container.initCapacity(allocator, width * height);
    errdefer data.deinit();

    data.appendNTimesAssumeCapacity(Field.Empty, width * height);

    return Grid{
        .data = data,
        .height = height,
        .width = width,
    };
}

fn parseBytes(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Byte) {
    var bytes = try std.ArrayList(Byte).initCapacity(allocator, input.len);
    errdefer bytes.deinit();

    for (input) |line| {
        var split = std.mem.splitScalar(u8, line, ',');
        const left = split.next();
        const right = split.next();
        if (left == null or right == null) return error.MalformedInput;

        bytes.appendAssumeCapacity(Byte{
            .first = try std.fmt.parseInt(isize, left.?, 10),
            .second = try std.fmt.parseInt(isize, right.?, 10),
        });
    }

    return bytes;
}

const QueueItem = struct { distance: u64, position: isize };
fn queueCompareFn(_: void, a: QueueItem, b: QueueItem) std.math.Order {
    return std.math.order(a.distance, b.distance);
}

fn calculateDistances(allocator: std.mem.Allocator, map: Grid, start_position: isize) !std.AutoHashMap(isize, u64) {
    var distances = std.AutoHashMap(isize, u64).init(allocator);
    errdefer distances.deinit();

    var queue = std.PriorityQueue(QueueItem, void, queueCompareFn).init(allocator, {});
    defer queue.deinit();

    try distances.put(start_position, 0);
    try queue.add(.{
        .distance = 0,
        .position = start_position,
    });

    while (queue.items.len > 0) {
        const current = queue.remove();
        if (distances.get(current.position)) |cached_distance| {
            if (cached_distance < current.distance) continue;
        }
        //try moving
        const current_x, const current_y = try map.mapToXY(current.position);

        for (common.Direction.all()) |direction| {
            const dir_x, const dir_y = direction.toOffset();
            const next_x, const next_y = .{ current_x + dir_x, current_y + dir_y };
            if (map.get(next_x, next_y)) |next_field| {
                if (next_field == Field.Empty) {
                    const next_position = try map.mapToIndex(next_x, next_y);
                    const cache_result = try distances.getOrPut(next_position);

                    if (!cache_result.found_existing or (cache_result.found_existing and cache_result.value_ptr.* > current.distance + 1)) {
                        cache_result.value_ptr.* = current.distance + 1;
                        try queue.add(.{
                            .distance = current.distance + 1,
                            .position = next_position,
                        });
                    }
                }
            }
        }
    }

    return distances;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8, width: usize, height: usize, bytes_num: usize) !u64 {
    var map = try getEmptyGrid(allocator, width, height);
    defer map.data.deinit();

    const bytes = try parseBytes(allocator, input);
    defer bytes.deinit();

    for (bytes.items[0..bytes_num]) |byte| {
        try map.set(byte.first, byte.second, Field.Byte);
    }

    var distances = try calculateDistances(allocator, map, 0);
    defer distances.deinit();

    return distances.get(@as(isize, @intCast(width * height)) - 1) orelse error.NoSolution;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8, width: usize, height: usize, bytes_num: usize) !u64 {
    var map = try getEmptyGrid(allocator, width, height);
    defer map.data.deinit();

    const bytes = try parseBytes(allocator, input);
    defer bytes.deinit();

    for (bytes.items[0..bytes_num]) |byte| {
        try map.set(byte.first, byte.second, Field.Byte);
    }

    for (bytes.items[bytes_num..]) |new_byte| {
        try map.set(new_byte.first, new_byte.second, Field.Byte);

        var distances = try calculateDistances(allocator, map, 0);
        defer distances.deinit();

        if (!distances.contains(@as(isize, @intCast(width * height)) - 1)) {
            return @intCast(new_byte.first * 1000 + new_byte.second);
        }
    }

    return error.NoSolution;
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

    std.debug.print("Part 1 solution: {d}\n", .{try solvePart1(allocator, input.items, 71, 71, 1024)});
    std.debug.print("Part 2 solution: {d}\n", .{try solvePart2(allocator, input.items, 71, 71, 1024)});
}

test "solve part 1 test" {
    const allocator = std.testing.allocator;

    const test_input = [_][]const u8{
        "5,4",
        "4,2",
        "4,5",
        "3,0",
        "2,1",
        "6,3",
        "2,4",
        "1,5",
        "0,6",
        "3,3",
        "2,6",
        "5,1",
        "1,2",
        "5,5",
        "2,5",
        "6,5",
        "1,4",
        "0,4",
        "6,4",
        "1,1",
        "6,1",
        "1,0",
        "0,5",
        "1,6",
        "2,0",
    };
    const result = try solvePart1(allocator, &test_input, 7, 7, 12);

    try std.testing.expectEqual(@as(u64, 22), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;

    const test_input = [_][]const u8{
        "5,4",
        "4,2",
        "4,5",
        "3,0",
        "2,1",
        "6,3",
        "2,4",
        "1,5",
        "0,6",
        "3,3",
        "2,6",
        "5,1",
        "1,2",
        "5,5",
        "2,5",
        "6,5",
        "1,4",
        "0,4",
        "6,4",
        "1,1",
        "6,1",
        "1,0",
        "0,5",
        "1,6",
        "2,0",
    };
    const result = try solvePart2(allocator, &test_input, 7, 7, 12);

    try std.testing.expectEqual(@as(u64, 6001), result);
}
