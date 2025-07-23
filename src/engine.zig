const std = @import("std");
const File = std.fs.File;
const Interface = @import("plugins/handler.zig").Interface;

pub const EngineError = error{
    UserExit,
    FunctionNotFound,
    InvalidCommand,
};

pub const Cmds = enum {
    help,
    exit,
    list,
    load,
};

pub fn parseCommand(input: []const u8, stdout: File.Writer) !void {
    var parts = std.mem.tokenizeSequence(u8, input, " ");

    const cmd = std.meta.stringToEnum(
        Cmds,
        parts.next() orelse "help",
    ) orelse Cmds.help;

    try switch (cmd) {
        .help => showHelp(stdout),
        .exit => {
            try stdout.print("Exiting...\n", .{});
            // this is def the wrong way to do this
            return EngineError.UserExit;
        },
        .list => listPlugins(stdout),
        .load => {
            const plugin_name = parts.next() orelse "(no plugin name)";
            try loadHandler(plugin_name, stdout);
        },
    };
}

fn showHelp(stdout: File.Writer) !void {
    try stdout.print(
        \\Available commands:
        \\    help - show this message
        \\    exit - exit console
        \\    list - show all available plugins
        \\    load <plugin>
    ++ "\n\n", .{});
}

fn listPlugins(stdout: File.Writer) !void {
    try stdout.print("Available Plugins:\n\n", .{});
}

fn loadHandler(plugin_name: []const u8, stdout: File.Writer) !void {
    //TODO: add string handling so path "./zig-out/lib/lib*.so" doesn't need to be typed out
    try loadDynLib(plugin_name, stdout);
}

pub fn loadDynLib(plugin_path: []const u8, stdout: File.Writer) !void {
    _ = stdout;
    var loaded_lib = try std.DynLib.open(plugin_path);
    defer loaded_lib.close();
    std.debug.print("plugin '{s}' loaded successfully.\n", .{plugin_path});

    const get_Number = loaded_lib.lookup(*const fn () callconv(.C) *Interface, "getNumber") orelse return EngineError.FunctionNotFound;
    std.debug.print("Function 'getNumber' imported successfully.\n", .{});

    const assign_struct = get_Number(); // Call the function to ensure it is loaded
    std.debug.print(
        "Function 'getNumber' returned a pointer to interface: {s}.\nvalue={s}\nhelp={s}\n",
        .{ std.mem.span(assign_struct.name), std.mem.span(assign_struct.value), std.mem.span(assign_struct.help) },
    );
}
