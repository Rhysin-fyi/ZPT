const std = @import("std");
const engine = @import("engine.zig");
const zlua = @import("zlua");

pub const GlobalState = struct {
    allocator: std.mem.Allocator = undefined,
    stdin: std.fs.File.Reader = undefined,
    stdout: std.fs.File.Writer = undefined,
    user_input: std.mem.TokenIterator(u8, std.mem.DelimiterType.sequence) = undefined,
    sub_state: enum { Default, Plugin } = undefined,
    plugin_name: []const u8 = undefined,
};

const FAIL_GRACEFULLY = false;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() != .ok) @panic("leak");

    var ctx = GlobalState{
        .stdout = std.io.getStdOut().writer(),
        .stdin = std.io.getStdIn().reader(),
        .allocator = gpa.allocator(),
        .sub_state = .Default,
    };

    var buf: [1024]u8 = undefined;
    while (true) {
        try ctx.stdout.print("zpt> ", .{});
        const line = try ctx.stdin.readUntilDelimiterOrEof(&buf, '\n') orelse break;
        const input = std.mem.trim(u8, line, " \r\n");

        engine.parseCommand(input, &ctx) catch |err| {
            if (err == engine.EngineError.UserExit) return;
            if (!FAIL_GRACEFULLY) return err else {
                std.debug.print("{!}\n", .{err});
            }
        };
    }
}
