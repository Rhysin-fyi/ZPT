const std = @import("std");
const engine = @import("engine.zig");
const zlua = @import("zlua");

const FAIL_GRACEFULLY = false;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var buf: [1024]u8 = undefined;

    while (true) {
        try stdout.print("zpt> ", .{});
        const line = try stdin.readUntilDelimiterOrEof(&buf, '\n') orelse break;
        const input = std.mem.trim(u8, line, " \r\n");

        engine.parseCommand(input, stdout) catch |err| {
            if (err == engine.EngineError.UserExit) return;
            if (!FAIL_GRACEFULLY) return err else {
                std.debug.print("{!}\n", .{err});
            }
        };
    }
}
