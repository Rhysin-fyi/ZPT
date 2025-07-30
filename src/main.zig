const std = @import("std");
const engine = @import("engine.zig");
const zlua = @import("zlua");

pub const GlobalState = struct {
    allocator: std.mem.Allocator = undefined,
    stdin: std.fs.File.Reader = undefined,
    stdout: std.fs.File.Writer = undefined,
    user_input: std.mem.TokenIterator(u8, std.mem.DelimiterType.sequence) = undefined,
    sub_state: enum { Default, Plugin, Exit } = undefined,
    plugin_name: []const u8 = undefined,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() != .ok) @panic("leak");

    var ctx = GlobalState{
        .stdout = std.io.getStdOut().writer(),
        .stdin = std.io.getStdIn().reader(),
        .allocator = gpa.allocator(),
        .sub_state = .Default,
    };

    while (true) {
        const zpt_str: []const u8 = if (ctx.sub_state == .Plugin) try std.fmt.allocPrint(
            ctx.allocator,
            "zpt/{s}/> ",
            .{ctx.plugin_name},
        ) else "zpt> ";

        try ctx.stdout.print("{s}", .{zpt_str});
        var buf: [1024]u8 = undefined;
        const line = try ctx.stdin.readUntilDelimiterOrEof(&buf, '\n') orelse break;
        const input = std.mem.trim(u8, line, " \r\n");
        ctx.user_input = std.mem.tokenizeSequence(u8, input, " ");

        switch (ctx.sub_state) {
            .Default => {
                try engine.parseCommandDefault(&ctx);
            },
            .Plugin => {
                try engine.parseCommandPlugin(&ctx);
            },
            .Exit => {
                try ctx.stdout.print("Bye!", .{});
                return;
            },
        }
    }
}
