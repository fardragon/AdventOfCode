const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Shape = [9]bool;
const Region = struct {
    width: usize,
    height: usize,
    shapes: std.ArrayList(u64),
};

fn parseShape(input: [3][]const u8) !Shape {
    var shape: Shape = undefined;

    var ix: usize = 0;
    while (ix < 9) : (ix += 1) {
        const line = ix % 3;
        const pos = @divFloor(ix, 3);
        shape[ix] = switch (input[line][pos]) {
            '.' => false,
            '#' => true,
            else => return error.MalformedInput,
        };
    }

    return shape;
}

fn parseRegion(allocator: std.mem.Allocator, line: []const u8) !Region {
    const x_pos = std.mem.indexOfScalar(u8, line, 'x') orelse return error.MalformedInput;
    const colon_pos = std.mem.indexOfScalar(u8, line, ':') orelse return error.MalformedInput;

    const width = try std.fmt.parseInt(usize, line[0..x_pos], 10);
    const height = try std.fmt.parseInt(usize, line[x_pos + 1 .. colon_pos], 10);

    const shapes = try common.parsing.parseNumbers(u64, allocator, line[colon_pos + 2 ..], ' ');

    return .{ .width = width, .height = height, .shapes = shapes };
}

fn parsePuzzle(allocator: std.mem.Allocator, input: []const []const u8) !struct { std.ArrayList(Shape), std.ArrayList(Region) } {
    var shapes: std.ArrayList(Shape) = .empty;
    var regions: std.ArrayList(Region) = .empty;

    errdefer {
        shapes.deinit(allocator);
        for (regions.items) |*region| {
            region.shapes.deinit(allocator);
        }
        regions.deinit(allocator);
    }

    var ix: usize = 0;

    while (ix < input.len) {
        if (input[ix].len == 0) {
            ix += 1;
        } else if (std.mem.count(u8, input[ix], "x") > 0) {
            var region = try parseRegion(allocator, input[ix]);
            errdefer region.shapes.deinit(allocator);
            try regions.append(allocator, region);
            ix += 1;
        } else if (std.mem.count(u8, input[ix], ":") > 0) {
            const shape = try parseShape(input[ix + 1 .. ix + 4][0..3].*);
            try shapes.append(allocator, shape);
            ix += 4;
        } else return error.MalformedInput;
    }

    return .{ shapes, regions };
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var shapes, var regions = try parsePuzzle(allocator, input);
    defer {
        shapes.deinit(allocator);
        for (regions.items) |*region| {
            region.shapes.deinit(allocator);
        }
        regions.deinit(allocator);
    }

    var valid_regions: u64 = 0;

    for (regions.items) |*region| {
        const capacity = @divFloor(region.height, 3) * @divFloor(region.width, 3);
        const total_presents = p: {
            var presents: u64 = 0;
            for (region.shapes.items) |shape_count| {
                presents += shape_count;
            }
            break :p presents;
        };

        if (total_presents <= capacity) {
            valid_regions += 1;
        }
    }

    return valid_regions;
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
}
