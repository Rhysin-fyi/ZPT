const std = @import("std");
const engine = @import("engine.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var buf: [1024]u8 = undefined;

    while (true) {
        try stdout.print("zpt> ", .{});
        const line = try stdin.readUntilDelimiterOrEof(&buf, '\n') orelse break;
        const input = std.mem.trim(u8, line, " \r\n");
//        if (std.mem.eql(u8,input,"exit")) break else continue;
        try engine.parseCommand(input, stdout);
    }
}
