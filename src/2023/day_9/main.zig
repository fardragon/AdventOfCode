const std = @import("std");
const common_input = @import("common").input;

const Report = std.ArrayList(i64);

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Report) {
    var result = std.ArrayList(Report).init(allocator);
    errdefer {
        for (result.items) |report| {
            report.deinit();
        }
        result.deinit();
    }

    for (input) |line| {
        var it = std.mem.splitScalar(u8, line, ' ');

        var report = Report.init(allocator);
        errdefer {
            report.deinit();
        }
        while (it.next()) |n| {
            const num = try std.fmt.parseInt(i64, n, 10);
            try report.append(num);
        }

        try result.append(report);
    }

    return result;
}

fn extendReport(allocator: std.mem.Allocator, report: Report) !i64 {
    var extensions = std.ArrayList(Report).init(allocator);
    defer {
        for (extensions.items) |r| {
            r.deinit();
        }
        extensions.deinit();
    }

    try extensions.append(try report.clone());

    // extend
    while (true) {
        var new_extenstion = Report.init(allocator);
        errdefer new_extenstion.deinit();

        const last_extension = extensions.getLast();
        var all_zeroes = true;
        for (1..last_extension.items.len) |ix| {
            const new_val = last_extension.items[ix] - last_extension.items[ix - 1];
            try new_extenstion.append(new_val);

            if (new_val != 0) all_zeroes = false;
        }

        try extensions.append(new_extenstion);

        if (all_zeroes) break;
    }

    //extrapolate
    try extensions.items[extensions.items.len - 1].append(0);
    for (2..extensions.items.len + 1) |offset| {
        const target_ix = extensions.items.len - offset;
        const source_ix = extensions.items.len - offset + 1;

        const new_val = extensions.items[target_ix].getLast() + extensions.items[source_ix].getLast();

        try extensions.items[target_ix].append(new_val);
    }

    return extensions.items[0].getLast();
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !i64 {
    var reports = try parseInput(allocator, input);
    defer {
        for (reports.items) |report| {
            report.deinit();
        }
        reports.deinit();
    }
    var result: i64 = 0;

    for (reports.items) |report| {
        result += try extendReport(allocator, report);
    }

    return result;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !i64 {
    var reports = try parseInput(allocator, input);
    defer {
        for (reports.items) |report| {
            report.deinit();
        }
        reports.deinit();
    }
    var result: i64 = 0;

    for (reports.items) |report| {
        var reversed_report = Report.init(allocator);
        defer reversed_report.deinit();

        var ix: usize = report.items.len;
        while (ix > 0) {
            ix -= 1;

            try reversed_report.append(report.items[ix]);
        }

        result += try extendReport(allocator, reversed_report);
    }

    return result;
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
        "0 3 6 9 12 15",
        "1 3 6 10 15 21",
        "10 13 16 21 30 45",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(i64, 114), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "0 3 6 9 12 15",
        "1 3 6 10 15 21",
        "10 13 16 21 30 45",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(i64, 2), result);
}
