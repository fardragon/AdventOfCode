const std = @import("std");

pub fn buildDay(b: *std.Build, target: *const std.Build.ResolvedTarget, optimize_options: *const std.builtin.Mode, all_tests_step: *std.Build.Step, comptime name: []const u8) void {
    const path = "src/" ++ name ++ "/main.zig";

    const common_module = b.createModule(.{
        .root_source_file = b.path("src/common/common.zig"),
        // .dependencies = &.{},
    });

    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path(path),
        .target = target.*,
        .optimize = optimize_options.*,
    });
    exe.root_module.addImport("common", common_module);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    run_cmd.cwd = b.path("src/" ++ name);

    const run_step = b.step("run_" ++ name, "Run " ++ name);
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = b.path(path),
        .target = target.*,
        .optimize = optimize_options.*,
    });
    unit_tests.root_module.addImport("common", common_module);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    run_unit_tests.cwd = b.path("src/" ++ name);

    const test_step = b.step("test_" ++ name, "Run " ++ name ++ " unit tests");
    test_step.dependOn(&run_unit_tests.step);
    all_tests_step.dependOn(&run_unit_tests.step);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const run_all_tests_step = b.step("test_all", "Run all tests");

    buildDay(b, &target, &optimize, run_all_tests_step, "day_test");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_1");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_2");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_3");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_4");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_5");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_6");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_7");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_8");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_9");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_10");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_11");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_12");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_13");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_14");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_15");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_16");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_17");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_18");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_19");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_20");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_21");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_22");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_23");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_24");
    buildDay(b, &target, &optimize, run_all_tests_step, "day_25");
}
