const std = @import("std");
const handler_interface = @import("handler.zig");

pub fn loadDynLib(modname: []const u8, stdout: anytype) !void {
    var loaded_lib = try std.DynLib.open(modname);

    defer loaded_lib.close();

    try stdout.print("Module '{s}' loaded successfully.\n", .{modname});
    const get_Number = loaded_lib.lookup(*const fn () callconv(.C) *const handler_interface.interface, "getNumber") orelse return error.ModuleFunctionNotFound;

    try stdout.print("Function 'getNumber' imported successfully.\n", .{});
    const assign_struct = get_Number(); // Call the function to ensure it is loaded
    try stdout.print("Function 'getNumber' returned a pointer to interface. {s}\n", .{std.mem.span(assign_struct.name)});
}

fn loadHandler(moduleName: []const u8, stdout: anytype) !void {
    try loadDynLib(moduleName, stdout);
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
        try loadHandler(moduleName, stdout);
    }
}
