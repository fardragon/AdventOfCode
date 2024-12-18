const std = @import("std");
const common = @import("common");
const common_input = common.input;
const Direction = common.Direction;

const Field = enum {
    Empty,
    Wall,
    Box,
};

const WideField = enum {
    Empty,
    Wall,
    BoxLeft,
    BoxRight,
};

const Grid = common.grid.Grid(Field);
const WideGrid = common.grid.Grid(WideField);

fn Warehouse(GridType: type) type {
    return struct {
        map: GridType,
        robot: isize,
        instructions: std.ArrayList(Direction),

        const Self = @This();
        fn deinit(self: Self) void {
            self.map.data.deinit();
            self.instructions.deinit();
        }
    };
}

fn parseWarehouse(allocator: std.mem.Allocator, input: []const []const u8) !Warehouse(Grid) {
    const expected_width = input[0].len;

    var data = Grid.Container.init(allocator);
    errdefer data.deinit();

    var instructions = std.ArrayList(Direction).init(allocator);
    errdefer instructions.deinit();

    var robot: ?isize = null;
    var height: ?usize = null;

    var parsing_map = true;

    for (input, 0..) |line, ix| {
        if (line.len == 0) {
            parsing_map = false;
            height = ix;
            continue;
        }

        if (parsing_map) {
            if (line.len != expected_width) return error.MalformedInput;

            for (line) |char| {
                switch (char) {
                    '.' => try data.append(Field.Empty),
                    '#' => try data.append(Field.Wall),
                    'O' => try data.append(Field.Box),
                    '@' => {
                        try data.append(Field.Empty);
                        robot = @intCast(data.items.len - 1);
                    },
                    else => return error.MalformedInput,
                }
            }
        } else {
            for (line) |char| {
                switch (char) {
                    '^' => try instructions.append(Direction.Up),
                    'v' => try instructions.append(Direction.Down),
                    '<' => try instructions.append(Direction.Left),
                    '>' => try instructions.append(Direction.Right),
                    else => return error.MalformedInput,
                }
            }
        }
    }

    return Warehouse(Grid){
        .map = Grid{
            .data = data,
            .height = height.?,
            .width = expected_width,
        },
        .robot = robot.?,
        .instructions = instructions,
    };
}

fn parseWideWarehouse(allocator: std.mem.Allocator, input: []const []const u8) !Warehouse(WideGrid) {
    const expected_width = input[0].len;

    var data = WideGrid.Container.init(allocator);
    errdefer data.deinit();

    var instructions = std.ArrayList(Direction).init(allocator);
    errdefer instructions.deinit();

    var robot: ?isize = null;
    var height: ?usize = null;

    var parsing_map = true;

    for (input, 0..) |line, ix| {
        if (line.len == 0) {
            height = ix;
            parsing_map = false;
            continue;
        }

        if (parsing_map) {
            if (line.len != expected_width) return error.MalformedInput;

            for (line) |char| {
                switch (char) {
                    '.' => try data.appendNTimes(WideField.Empty, 2),
                    '#' => try data.appendNTimes(WideField.Wall, 2),
                    'O' => {
                        try data.append(WideField.BoxLeft);
                        try data.append(WideField.BoxRight);
                    },
                    '@' => {
                        try data.appendNTimes(WideField.Empty, 2);
                        robot = @intCast(data.items.len - 2);
                    },
                    else => return error.MalformedInput,
                }
            }
        } else {
            for (line) |char| {
                switch (char) {
                    '^' => try instructions.append(Direction.Up),
                    'v' => try instructions.append(Direction.Down),
                    '<' => try instructions.append(Direction.Left),
                    '>' => try instructions.append(Direction.Right),
                    else => return error.MalformedInput,
                }
            }
        }
    }

    return Warehouse(WideGrid){
        .map = WideGrid{
            .data = data,
            .height = height.?,
            .width = expected_width * 2,
        },
        .robot = robot.?,
        .instructions = instructions,
    };
}

fn findEmptyFieldInDirection(grid: Grid, start_x: isize, start_y: isize, dir_x: isize, dir_y: isize) ?struct { isize, isize } {
    var cur_x = start_x;
    var cur_y = start_y;

    while (true) {
        switch (grid.get(cur_x, cur_y).?) {
            Field.Empty => {
                return .{ cur_x, cur_y };
            },
            Field.Wall => {
                return null;
            },
            Field.Box => {
                cur_x += dir_x;
                cur_y += dir_y;
            },
        }
    }
    unreachable;
}

fn findEmptyWideFieldInHorizontalDirection(grid: WideGrid, start_x: isize, start_y: isize, dir_x: isize) ?struct { isize, isize } {
    var cur_x = start_x;
    const cur_y = start_y;

    while (true) {
        switch (grid.get(cur_x, cur_y).?) {
            WideField.Empty => {
                return .{ cur_x, cur_y };
            },
            WideField.Wall => {
                return null;
            },
            WideField.BoxLeft, WideField.BoxRight => {
                cur_x += dir_x;
            },
        }
    }

    unreachable;
}

fn findEmptyWideFieldsInVerticalDirection(allocator: std.mem.Allocator, grid: WideGrid, start_x: isize, start_y: isize, dir_y: isize) !?std.ArrayList(common.AutoHashSet(isize)) {
    var cur_y = start_y;

    var boxes_to_move = std.ArrayList(common.AutoHashSet(isize)).init(allocator);
    errdefer {
        for (boxes_to_move.items) |*level| level.deinit();
        boxes_to_move.deinit();
    }

    // level 0
    try boxes_to_move.append(common.AutoHashSet(isize).init(allocator));
    try boxes_to_move.items[0].put(start_x);

    switch (grid.get(start_x, cur_y).?) {
        WideField.BoxLeft => try boxes_to_move.items[0].put(start_x + 1),
        WideField.BoxRight => try boxes_to_move.items[0].put(start_x - 1),
        else => unreachable,
    }

    while (true) {
        cur_y += dir_y;
        try boxes_to_move.append(common.AutoHashSet(isize).init(allocator));
        var it = boxes_to_move.items[boxes_to_move.items.len - 2].iterator();

        while (it.next()) |field_x| {
            switch (grid.get(field_x.*, cur_y).?) {
                WideField.Wall => {
                    for (boxes_to_move.items) |*level| level.deinit();
                    boxes_to_move.deinit();
                    return null;
                },
                WideField.Empty => {},
                WideField.BoxLeft => {
                    try boxes_to_move.items[boxes_to_move.items.len - 1].put(field_x.*);
                    try boxes_to_move.items[boxes_to_move.items.len - 1].put(field_x.* + 1);
                },
                WideField.BoxRight => {
                    try boxes_to_move.items[boxes_to_move.items.len - 1].put(field_x.*);
                    try boxes_to_move.items[boxes_to_move.items.len - 1].put(field_x.* - 1);
                },
            }
        }

        if (boxes_to_move.getLast().count() == 0) {
            _ = boxes_to_move.pop();
            return boxes_to_move;
        }
    }

    unreachable;
}

fn calculate_gps(T: type, grid: common.grid.Grid(T), box_field: T) !u64 {
    var gps_sum: u64 = 0;
    for (grid.data.items, 0..) |field, ix| {
        if (field == box_field) {
            const x, const y = try grid.mapToXY(@intCast(ix));

            gps_sum += (@as(u64, @intCast(y)) * 100 + @as(u64, @intCast(x)));
        }
    }

    return gps_sum;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var warehouse = try parseWarehouse(allocator, input);
    defer warehouse.deinit();

    var robot_x, var robot_y = try warehouse.map.mapToXY(warehouse.robot);

    for (warehouse.instructions.items) |instruction| {
        const off_x, const off_y = instruction.toOffset();
        const new_x = robot_x + off_x;
        const new_y = robot_y + off_y;

        switch (warehouse.map.get(new_x, new_y).?) {
            Field.Empty => {
                robot_x, robot_y = .{ new_x, new_y };
            },
            Field.Wall => {},
            Field.Box => {
                if (findEmptyFieldInDirection(warehouse.map, new_x, new_y, off_x, off_y)) |empty_spot| {
                    const empty_x, const empty_y = empty_spot;

                    robot_x, robot_y = .{ new_x, new_y };
                    try warehouse.map.set(new_x, new_y, Field.Empty);
                    try warehouse.map.set(empty_x, empty_y, Field.Box);
                }
            },
        }
    }

    return calculate_gps(Field, warehouse.map, Field.Box);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var warehouse = try parseWideWarehouse(allocator, input);
    defer warehouse.deinit();

    var robot_x, var robot_y = try warehouse.map.mapToXY(warehouse.robot);

    for (warehouse.instructions.items) |instruction| {
        const off_x, const off_y = instruction.toOffset();
        const new_x = robot_x + off_x;
        const new_y = robot_y + off_y;

        switch (warehouse.map.get(new_x, new_y).?) {
            WideField.Empty => {
                robot_x, robot_y = .{ new_x, new_y };
            },
            WideField.Wall => {},
            WideField.BoxLeft, WideField.BoxRight => {
                switch (instruction) {
                    Direction.Left, Direction.Right => {
                        if (findEmptyWideFieldInHorizontalDirection(warehouse.map, new_x, new_y, off_x)) |empty_field| {
                            var empty_x, const empty_y = empty_field;

                            var box_left = instruction == Direction.Left;

                            while (empty_x != new_x) : (empty_x -= off_x) {
                                const box = if (box_left) WideField.BoxLeft else WideField.BoxRight;
                                box_left = !box_left;
                                try warehouse.map.set(empty_x, empty_y, box);
                            }
                            try warehouse.map.set(empty_x, empty_y, WideField.Empty);
                            robot_x, robot_y = .{ new_x, new_y };
                        }
                    },

                    Direction.Up, Direction.Down => {
                        var m_boxes_to_move = try findEmptyWideFieldsInVerticalDirection(allocator, warehouse.map, new_x, new_y, off_y);
                        if (m_boxes_to_move) |*boxes_to_move| {
                            defer {
                                for (boxes_to_move.items) |*level| level.deinit();
                                boxes_to_move.deinit();
                            }

                            while (boxes_to_move.items.len > 0) {
                                var it = boxes_to_move.getLast().iterator();

                                while (it.next()) |box_to_move| {
                                    const source_y = @as(isize, @intCast(boxes_to_move.items.len - 1));
                                    const target_y = @as(isize, @intCast(boxes_to_move.items.len));

                                    const box_part = warehouse.map.get(box_to_move.*, new_y + (source_y * off_y)).?;
                                    try warehouse.map.set(box_to_move.*, new_y + (target_y * off_y), box_part);
                                    try warehouse.map.set(box_to_move.*, new_y + (source_y * off_y), WideField.Empty);
                                }
                                boxes_to_move.items[boxes_to_move.items.len - 1].deinit();
                                _ = boxes_to_move.pop();
                            }
                            robot_x, robot_y = .{ new_x, new_y };
                        }
                    },
                }
            },
        }
    }

    return calculate_gps(WideField, warehouse.map, WideField.BoxLeft);
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

const test_input_small = [_][]const u8{
    "########",
    "#..O.O.#",
    "##@.O..#",
    "#...O..#",
    "#.#.O..#",
    "#...O..#",
    "#......#",
    "########",
    "",
    "<^^>>>vv<v>>v<<",
};

const test_input_large = [_][]const u8{
    "##########",
    "#..O..O.O#",
    "#......O.#",
    "#.OO..O.O#",
    "#..O@..O.#",
    "#O#..O...#",
    "#O..O..O.#",
    "#.OO.O.OO#",
    "#....O...#",
    "##########",
    "",
    "<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^",
    "vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v",
    "><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<",
    "<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^",
    "^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><",
    "^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^",
    ">^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^",
    "<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>",
    "^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>",
    "v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^",
};

test "solve part 1a test" {
    const allocator = std.testing.allocator;
    const result = try solvePart1(allocator, &test_input_small);

    try std.testing.expectEqual(@as(u64, 2028), result);
}

test "solve part 1b test" {
    const allocator = std.testing.allocator;
    const result = try solvePart1(allocator, &test_input_large);

    try std.testing.expectEqual(@as(u64, 10092), result);
}

test "solve part 2a test" {
    const allocator = std.testing.allocator;
    const result = try solvePart2(allocator, &test_input_small);

    try std.testing.expectEqual(@as(u64, 1751), result);
}

test "solve part 2b test" {
    const allocator = std.testing.allocator;
    const result = try solvePart2(allocator, &test_input_large);

    try std.testing.expectEqual(@as(u64, 9021), result);
}
