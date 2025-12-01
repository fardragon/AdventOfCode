const std = @import("std");
const common_input = @import("common").input;

const Block = union(enum) {
    Empty: void,
    File: u64,
};

const CompactBlock = struct {
    kind: Block,
    len: usize,
};

fn countUsedBlocks(blocks: []const Block) usize {
    var used: usize = 0;
    for (blocks) |block| {
        switch (block) {
            .Empty => {},
            .File => {
                used += 1;
            },
        }
    }

    return used;
}

fn findLastNonEmptyBlock(blocks: []const Block) !usize {
    var ix = blocks.len - 1;

    while (ix >= 0) : (ix -= 1) {
        switch (blocks[ix]) {
            .Empty => continue,
            .File => return ix,
        }
    }
    return error.InvalidInput;
}

fn findEmptyBlock(blocks: []const CompactBlock, size: usize) ?usize {
    for (blocks, 0..) |block, ix| {
        switch (block.kind) {
            .File => continue,
            .Empty => {
                if (block.len >= size) return ix;
            },
        }
    }
    return null;
}

fn parseMap(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Block) {
    var result = std.ArrayList(Block).empty;
    errdefer result.deinit(allocator);

    if (input.len != 1) return error.MalformedInput;

    var file_id: u64 = 0;

    var empty = false;

    for (0..input[0].len) |ix| {
        const len = try std.fmt.parseInt(usize, input[0][ix .. ix + 1], 10);

        if (!empty) {
            try result.appendNTimes(allocator, Block{ .File = file_id }, len);
            file_id += 1;
        } else {
            try result.appendNTimes(allocator, Block{ .Empty = {} }, len);
        }

        empty = !empty;
    }

    return result;
}

fn parseCompactMap(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(CompactBlock) {
    var result = std.ArrayList(CompactBlock).empty;
    errdefer result.deinit(allocator);

    if (input.len != 1) return error.MalformedInput;

    var file_id: u64 = 0;
    var empty = false;

    for (0..input[0].len) |ix| {
        const len = try std.fmt.parseInt(usize, input[0][ix .. ix + 1], 10);

        if (!empty) {
            try result.append(
                allocator,
                CompactBlock{
                    .kind = Block{ .File = file_id },
                    .len = len,
                },
            );
            file_id += 1;
        } else {
            try result.append(
                allocator,
                CompactBlock{
                    .kind = Block{ .Empty = {} },
                    .len = len,
                },
            );
        }

        empty = !empty;
    }

    return result;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var map = try parseMap(allocator, input);
    defer map.deinit(allocator);

    const used_blocks = countUsedBlocks(map.items);
    var left_ix: usize = 0;

    while (left_ix < used_blocks) : (left_ix += 1) {
        switch (map.items[left_ix]) {
            .File => continue,
            .Empty => {
                const target = try findLastNonEmptyBlock(map.items);
                const tmp = map.items[left_ix];
                map.items[left_ix] = map.items[target];
                map.items[target] = tmp;
            },
        }
    }

    var checksum: u64 = 0;

    for (map.items[0..used_blocks], 0..) |block, ix| {
        switch (block) {
            .File => |id| {
                checksum += ix * id;
            },
            .Empty => unreachable,
        }
    }

    return checksum;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var map = try parseCompactMap(allocator, input);
    defer map.deinit(allocator);

    var right_ix: usize = map.items.len - 1;

    while (right_ix > 0) : (right_ix -= 1) {
        switch (map.items[right_ix].kind) {
            .Empty => continue,
            .File => |file_id| {
                if (findEmptyBlock(map.items[0..right_ix], map.items[right_ix].len)) |empty_block| {
                    const remaining_empty_blocks = map.items[empty_block].len - map.items[right_ix].len;

                    if (remaining_empty_blocks == 0) {
                        const tmp = map.items[empty_block];
                        map.items[empty_block] = map.items[right_ix];
                        map.items[right_ix] = tmp;
                    } else {
                        map.items[right_ix].kind = Block{ .Empty = {} };
                        map.items[empty_block] = CompactBlock{
                            .kind = Block{ .File = file_id },
                            .len = map.items[right_ix].len,
                        };
                        try map.insert(
                            allocator,
                            empty_block + 1,
                            CompactBlock{
                                .kind = Block{ .Empty = {} },
                                .len = remaining_empty_blocks,
                            },
                        );
                        right_ix += 1;
                    }
                }
            },
        }
    }

    var checksum: u64 = 0;
    var block_index: u64 = 0;

    for (map.items) |compact_block| {
        switch (compact_block.kind) {
            .Empty => {
                block_index += compact_block.len;
            },
            .File => |file_id| {
                for (0..compact_block.len) |_| {
                    checksum += block_index * file_id;
                    block_index += 1;
                }
            },
        }
    }

    return checksum;
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
        "2333133121414131402",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 1928), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "2333133121414131402",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 2858), result);
}
