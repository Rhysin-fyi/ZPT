const std = @import("std");
const interface = @import("handler.zig").interface;

pub fn loadDynLib(modname: []const u8, stdout: anytype) !void {
    var loaded_lib = try std.DynLib.open(modname);

    defer loaded_lib.close();

    try stdout.print("Module '{s}' loaded successfully.\n", .{modname});
    const get_Number = loaded_lib.lookup(*const fn () interface, "getNumber") orelse return error.ModuleFunctionNotFound;
    try stdout.print("Function '{s}' imported successfully.\n", .{modname});

    const get_struct = get_Number();
    _ = get_struct; // Use the struct to avoid unused variable warning
    //try stdout.print("Function 'getNumber' found in module '{s}'.\n", .{get_struct.name}); // try stdout.print("Function 'getNumber' found in module '{d}'.\n", .{get_Number()});
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
