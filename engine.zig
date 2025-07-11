const std = @import("std");
const std_dyn = @import("std").DynLib;


pub fn loadDynLib(modname: []const u8) !void {
    var loaded_lib = try std_dyn.open(modname);
    defer loaded_lib.close();
}

fn loadHandler(moduleName: []const u8) !void {
    try loadDynLib(moduleName);
}

pub fn parseCommand(input: []const u8, stdout: anytype) !void {
    var parts = std.mem.tokenizeSequence(u8, input, " ");
    const cmd = parts.next() orelse "(no command)";

    if (std.mem.eql(u8, cmd, "exit")) {
        try stdout.print("Exiting...\n", .{});
    } else if (std.mem.eql(u8, cmd, "help")) {
        try stdout.print("\nAvailable commands:\n", .{});
        try stdout.print("    help - show this message\n", .{});
        try stdout.print("    exit - exit console\n", .{});
        try stdout.print("    list - show all available modules\n", .{});
        try stdout.print("    load <module>\n\n", .{});
    } else if (std.mem.eql(u8, cmd, "load")) {
        const moduleName = parts.next() orelse "(no module name)";
        try loadHandler(moduleName);
    }
}
