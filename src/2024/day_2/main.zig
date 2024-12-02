const std = @import("std");
const common_input = @import("common").input;

fn parseReport(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(i64) {
    var result = std.ArrayList(i64).init(allocator);

    errdefer result.deinit();

    var split = std.mem.splitScalar(u8, input, ' ');

    while (split.next()) |number| {
        try result.append(try std.fmt.parseInt(i64, number, 10));
    }

    return result;
}

fn parseReports(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(std.ArrayList(i64)) {
    var reports = std.ArrayList(std.ArrayList(i64)).init(allocator);

    errdefer {
        for (reports.items) |report| {
            report.deinit();
        }
        reports.deinit();
    }

    for (input) |line| {
        try reports.append(try parseReport(allocator, line));
    }

    return reports;
}

fn validateReport(report: std.ArrayList(i64)) !bool {
    if (report.items.len < 2) {
        return error.InvalidInput;
    }

    const increasing = report.items[1] > report.items[0];

    for (0..report.items.len - 1) |ix| {
        if (report.items[ix + 1] == report.items[ix]) return false;

        const local_increasing = report.items[ix + 1] > report.items[ix];
        if (increasing != local_increasing) return false;

        if (@abs(report.items[ix + 1] - report.items[ix]) > 3) return false;
    }

    return true;
}

fn validateReportWithDampening(report: std.ArrayList(i64)) !bool {
    if (try validateReport(report)) {
        return true;
    }

    for (0..report.items.len) |ix| {
        var dampened_report = try report.clone();
        defer dampened_report.deinit();
        _ = dampened_report.orderedRemove(ix);

        if (try validateReport(dampened_report)) {
            return true;
        }
    }

    return false;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    const reports = try parseReports(allocator, input);
    defer {
        for (reports.items) |report| {
            report.deinit();
        }
        reports.deinit();
    }

    var valid_reports: u64 = 0;

    for (reports.items) |report| {
        if (try validateReport(report)) {
            valid_reports += 1;
        }
    }

    return valid_reports;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    const reports = try parseReports(allocator, input);
    defer {
        for (reports.items) |report| {
            report.deinit();
        }
        reports.deinit();
    }

    var valid_reports: u64 = 0;

    for (reports.items) |report| {
        if (try validateReportWithDampening(report)) {
            valid_reports += 1;
        }
    }

    return valid_reports;
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
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "7 6 4 2 1",
        "1 2 7 8 9",
        "9 7 6 2 1",
        "1 3 2 4 5",
        "8 6 4 4 1",
        "1 3 6 7 9",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 2), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "7 6 4 2 1",
        "1 2 7 8 9",
        "9 7 6 2 1",
        "1 3 2 4 5",
        "8 6 4 4 1",
        "1 3 6 7 9",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 4), result);
}
