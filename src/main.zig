const std = @import("std");
const engine = @import("engine.zig");
const zlua = @import("zlua");
const cmd_parser = @import("cmd_parser.zig");

pub const GlobalState = struct {
    allocator: std.mem.Allocator = undefined,
    stdin: std.fs.File.Reader = undefined,
    stdout: std.fs.File.Writer = undefined,
    cmd_parser: cmd_parser.CommandParser = undefined,
    sub_state: enum { Default, Plugin, Exit } = .Default,
    plugin_name: ?[]const u8 = null,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() != .ok) @panic("leak");
    const allocator = gpa.allocator();
    var ctx = try allocator.create(GlobalState);
    defer allocator.destroy(ctx);

    ctx.* = .{
        .stdout = std.io.getStdOut().writer(),
        .stdin = std.io.getStdIn().reader(),
        .allocator = allocator,
        .sub_state = .Default,
    };

    ctx.cmd_parser = cmd_parser.CommandParser.init(
        allocator,
        std.io.getStdIn().reader(),
    );
    defer ctx.cmd_parser.deinit();

    var buf: [1024]u8 = undefined;
    while (ctx.sub_state != .Exit) {
        @memset(&buf, 0);
        if (ctx.plugin_name) |plugin| {
            try ctx.stdout.print("zpt/{s}/>", .{plugin});
        } else {
            try ctx.stdout.print("zpt> ", .{});
        }

        switch (ctx.sub_state) {
            .Default => {
                try engine.parseCommandDefault(ctx);
            },
            .Plugin => {
                try engine.parseCommandPlugin(ctx);
            },
            .Exit => {
                try ctx.stdout.print("bye!\n", .{});
                exit();
            },
        }
    }
    try ctx.stdout.print("bye!\n", .{});
}

pub fn exit() void {
    std.process.cleanExit();
}
