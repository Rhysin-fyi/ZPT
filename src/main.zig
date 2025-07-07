const std = @import("std");
const modules = @import("modules.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var buf: [1024]u8 = undefined;

    while (true) {
        try stdout.print("zpt> ", .{});
        const line = try stdin.readUntilDelimiterOrEof(&buf, '\n');

        if (line == null) break;

        const input = std.mem.trim(u8, line.?, " \r\n");

        var parts = std.mem.tokenizeSequence(u8, input, " ");
        const cmd = parts.next() orelse continue;

        if (std.mem.eql(u8, cmd, "exit")) {
            try stdout.print("Exiting...\n", .{});
            break;
        } else if (std.mem.eql(u8, cmd, "help")) {
            try stdout.print("\nAvailable commands:\n", .{});
            try stdout.print("    help - show this message\n", .{});
            try stdout.print("    exit - exit console\n", .{});
            try stdout.print("    list - show all available modules\n", .{});
            try stdout.print("    load <module>\n\n", .{});
        } else if (std.mem.eql(u8, cmd, "load")) {
            const moduleName = parts.next() orelse continue;
            try modules.LoadModules(moduleName, stdout, stdin, buf[0..]);
        } else if (std.mem.eql(u8, cmd, "list")) {
            const ListedMods = modules.GetAllModules();

            for (ListedMods) |mod| {
                try stdout.print("Module: {s} -- {s}\n", .{ mod.name, mod.descrption });
            }
        } else if (cmd.len != 0) {
            try stdout.print("Unknown Command: '{s}'\n", .{cmd});
        }
    }
}
