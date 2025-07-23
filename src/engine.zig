const std = @import("std");
const File = std.fs.File;
const Interface = @import("plugins/handler.zig").Interface;
const Zigface = @import("plugins/handler.zig").Zigface;

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
            return EngineError.UserExit; // this is def the wrong way to do this
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
    var dba = std.heap.DebugAllocator(.{}){};
    const allocator = dba.allocator();
    const plugin_path = try std.fmt.allocPrint(allocator, "./zig-out/lib/lib{s}.so", .{
        plugin_name,
    });

    try loadDynLib(plugin_path, stdout);
}

pub fn loadDynLib(plugin_path: []const u8, stdout: File.Writer) !void {
    _ = stdout;
    var loaded_lib = try std.DynLib.open(plugin_path);
    defer loaded_lib.close();

    const get_Number = loaded_lib.lookup(*const fn () callconv(.C) *Interface, "getNumber") orelse return EngineError.FunctionNotFound;

    const assign_struct = get_Number(); // Call the function to ensure it is loaded
    std.debug.print(
        "Function 'getNumber' returned a pointer to interface: {s}.\nvalue={s}\nhelp={s}\n",
        .{ std.mem.span(assign_struct.name), std.mem.span(assign_struct.value), std.mem.span(assign_struct.help) },
    );

    const walter_white = assign_struct.ptr;
    walter_white.sayMyName();
    walter_white.happyBirthday();
    walter_white.happyBirthday();
    walter_white.happyBirthday();
}
