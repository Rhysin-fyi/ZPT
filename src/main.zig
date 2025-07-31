const std = @import("std");
const engine = @import("engine.zig");
const zlua = @import("zlua");

pub const GlobalState = struct {
    allocator: std.mem.Allocator = undefined,
    stdin: std.fs.File.Reader = undefined,
    stdout: std.fs.File.Writer = undefined,
    user_input: std.mem.TokenIterator(u8, std.mem.DelimiterType.sequence) = undefined,
    sub_state: enum { Default, Plugin, Exit } = .Default,
    plugin_name: ?[]const u8 = null,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() != .ok) @panic("leak");
    const allocator = gpa.allocator();
    var ctx = try allocator.create(GlobalState);

    ctx.* = .{
        .stdout = std.io.getStdOut().writer(),
        .stdin = std.io.getStdIn().reader(),
        .allocator = allocator,
        .sub_state = .Default,
    };

    var buf: [1024]u8 = undefined;
    while (ctx.sub_state != .Exit) {
        //TESTING (it doesnt work)
        @memset(&buf, 0);
        if (ctx.plugin_name) |plugin| {
            try ctx.stdout.print("zpt/{s}/>", .{plugin});
        } else {
            try ctx.stdout.print("zpt> ", .{});
        }

        const line = try ctx.stdin.readUntilDelimiterOrEof(&buf, '\n') orelse break;
        const input = std.mem.trim(u8, line, "\r\n");
        ctx.user_input = std.mem.tokenizeSequence(u8, input, " ");

        switch (ctx.sub_state) {
            .Default => {
                try engine.parseCommandDefault(ctx);
            },
            .Plugin => {
                std.debug.print("ENTER SET {s}\n", .{ctx.plugin_name orelse "null"});
                try engine.parseCommandPlugin(ctx);
                std.debug.print("BACK FROM SET {s}\n", .{ctx.plugin_name orelse "null"});
            },
            .Exit => break,
        }
    }
    try ctx.stdout.print("bye!\n", .{});
}
