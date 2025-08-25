const std = @import("std");
const common_input = @import("common").input;

const ResultRange = struct {
    start: u64,
    length: u64,
};

const Range = struct {
    destination: u64,
    source: u64,
    length: u64,

    fn contains(self: Range, value: u64) bool {
        const start = self.source;
        const end = start + self.length - 1;

        return value >= start and value <= end;
    }

    fn map(self: Range, value: u64) u64 {
        const offset = value - self.source;
        return self.destination + offset;
    }
};

const Map = struct {
    ranges: std.ArrayList(Range),

    fn deinit(self: *Map, allocator: std.mem.Allocator) void {
        self.ranges.deinit(allocator);
    }
};

const Almanac = struct {
    seeds: std.ArrayList(u64),
    maps: std.ArrayList(Map),

    fn deinit(self: *Almanac, allocator: std.mem.Allocator) void {
        self.seeds.deinit(allocator);

        for (self.maps.items) |*map| {
            map.deinit(allocator);
        }
        self.maps.deinit(allocator);
    }
};

fn parseRange(input: []const u8) !Range {
    var range_split = std.mem.splitScalar(u8, input, ' ');

    const destination = try std.fmt.parseInt(u64, range_split.first(), 10);
    const source = try std.fmt.parseInt(u64, range_split.next().?, 10);
    const length = try std.fmt.parseInt(u64, range_split.next().?, 10);
    return Range{
        .destination = destination,
        .source = source,
        .length = length,
    };
}

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !Almanac {

    // skip "seeds: "
    var seeds = std.ArrayList(u64).empty;
    errdefer seeds.deinit(allocator);
    const seeds_line = input[0][7..];
    var seeds_split = std.mem.splitScalar(u8, seeds_line, ' ');

    while (seeds_split.next()) |seed_str| {
        const seed = try std.fmt.parseInt(u64, seed_str, 10);
        try seeds.append(allocator, seed);
    }

    //skip empty line
    if (input[1].len != 0) unreachable;

    var maps = std.ArrayList(Map).empty;
    errdefer maps.deinit(allocator);

    var current_map: ?Map = null;
    errdefer {
        if (current_map) |*cr| {
            cr.deinit(allocator);
        }
    }

    for (input[2..]) |line| {
        if (line.len == 0) {
            // end of map
            if (current_map) |cr| {
                try maps.append(allocator, cr);
                current_map = null;
            } else {
                unreachable;
            }
        } else if (!std.ascii.isDigit(line[0])) {
            // new map
            if (current_map) |_| {
                unreachable;
            } else {
                current_map = Map{
                    .ranges = std.ArrayList(Range).empty,
                };
            }
        } else {
            //add range to map
            if (current_map) |*cr| {
                try cr.ranges.append(allocator, try parseRange(line));
            } else {
                unreachable;
            }
        }
    }

    // add last map
    if (current_map) |cr| {
        try maps.append(allocator, cr);
    } else {
        unreachable;
    }

    return Almanac{
        .seeds = seeds,
        .maps = maps,
    };
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var almanac = try parseInput(allocator, input);
    defer almanac.deinit(allocator);

    var result: u64 = std.math.maxInt(u64);

    for (almanac.seeds.items) |seed| {
        var current = seed;
        map_loop: for (almanac.maps.items) |map| {
            for (map.ranges.items) |range| {
                if (range.contains(current)) {
                    current = range.map(current);
                    continue :map_loop;
                }
            }
        }
        result = @min(result, current);
    }

    return result;
}

fn processRangeThroughhMap(allocator: std.mem.Allocator, map: Map, range: ResultRange) !std.ArrayList(ResultRange) {
    var unmapped_ranges = std.ArrayList(ResultRange).empty;
    defer unmapped_ranges.deinit(allocator);
    try unmapped_ranges.append(allocator, range);

    var mapped_ranges = std.ArrayList(ResultRange).empty;
    errdefer mapped_ranges.deinit(allocator);

    while (unmapped_ranges.items.len > 0) {
        const unmapped_range = unmapped_ranges.pop().?;
        var matched_something = false;

        map_loop: for (map.ranges.items) |mapping_range| {
            if (mapping_range.contains(unmapped_range.start)) {
                matched_something = true;
                const unmapped_end = unmapped_range.start + unmapped_range.length;
                const mapping_end = mapping_range.source + mapping_range.length;

                const overlap_start = @max(unmapped_range.start, mapping_range.source);
                const overlap_end = @min(unmapped_end, mapping_end);

                const overlap_length = overlap_end - overlap_start;
                const overlap_offset = unmapped_range.start - mapping_range.source;

                if (overlap_start == unmapped_range.start) {
                    // "left overlap"
                    try mapped_ranges.append(allocator, ResultRange{
                        .start = mapping_range.destination + overlap_offset,
                        .length = overlap_length,
                    });
                    if (unmapped_range.length - overlap_length > 0) {
                        try unmapped_ranges.append(allocator, ResultRange{
                            .start = unmapped_range.start + overlap_length,
                            .length = unmapped_range.length - overlap_length,
                        });
                    }

                    break :map_loop;
                } else {
                    // "right" && "middle" overlap, hopefuly this is not needed
                    unreachable;
                }
            }
        }
        if (!matched_something) {
            try mapped_ranges.append(allocator, unmapped_range);
        }
    }

    return mapped_ranges;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var almanac = try parseInput(allocator, input);
    defer almanac.deinit(allocator);

    //construct input ranges
    var result_ranges = std.ArrayList(ResultRange).empty;
    defer result_ranges.deinit(allocator);

    {
        var i: usize = 0;
        while (i < almanac.seeds.items.len) : (i += 2) {
            try result_ranges.append(allocator, ResultRange{
                .start = almanac.seeds.items[i],
                .length = almanac.seeds.items[i + 1],
            });
        }
    }

    for (almanac.maps.items) |map| {
        var new_ranges = std.ArrayList(ResultRange).empty;
        errdefer new_ranges.deinit(allocator);

        for (result_ranges.items) |range| {
            var new_ranges_partial = try processRangeThroughhMap(allocator, map, range);
            defer new_ranges_partial.deinit(allocator);
            for (new_ranges_partial.items) |nr| {
                try new_ranges.append(allocator, nr);
            }
        }

        result_ranges.deinit(allocator);
        result_ranges = new_ranges;
    }

    var result: u64 = std.math.maxInt(u64);

    for (result_ranges.items) |range| {
        result = @min(result, range.start);
    }

    return result;
}

pub fn main() !void {
    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = GPA.allocator();

    defer _ = GPA.deinit();

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
    const test_input = [_][]const u8{
        "seeds: 79 14 55 13",
        "",
        "seed-to-soil map:",
        "50 98 2",
        "52 50 48",
        "",
        "soil-to-fertilizer map:",
        "0 15 37",
        "37 52 2",
        "39 0 15",
        "",
        "fertilizer-to-water map:",
        "49 53 8",
        "0 11 42",
        "42 0 7",
        "57 7 4",
        "",
        "water-to-light map:",
        "88 18 7",
        "18 25 70",
        "",
        "light-to-temperature map:",
        "45 77 23",
        "81 45 19",
        "68 64 13",
        "",
        "temperature-to-humidity map:",
        "0 69 1",
        "1 0 69",
        "",
        "humidity-to-location map:",
        "60 56 37",
        "56 93 4",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 35), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "seeds: 79 14 55 13",
        "",
        "seed-to-soil map:",
        "50 98 2",
        "52 50 48",
        "",
        "soil-to-fertilizer map:",
        "0 15 37",
        "37 52 2",
        "39 0 15",
        "",
        "fertilizer-to-water map:",
        "49 53 8",
        "0 11 42",
        "42 0 7",
        "57 7 4",
        "",
        "water-to-light map:",
        "88 18 7",
        "18 25 70",
        "",
        "light-to-temperature map:",
        "45 77 23",
        "81 45 19",
        "68 64 13",
        "",
        "temperature-to-humidity map:",
        "0 69 1",
        "1 0 69",
        "",
        "humidity-to-location map:",
        "60 56 37",
        "56 93 4",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 46), result);
}
