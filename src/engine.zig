const std = @import("std");
const zlua = @import("zlua");

const Lua = zlua.Lua;

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

pub fn parseCommand(input: []const u8, stdout: std.fs.File.Writer) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() != .ok) @panic("leak");
    const allocator = gpa.allocator();

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
        .list => listPlugins(stdout, allocator),
        .load => {
            try luaTest();
        },
    };
}

fn showHelp(stdout: std.fs.File.Writer) !void {
    try stdout.print(
        \\Available commands:
        \\    help - show this message
        \\    exit - exit console
        \\    list - show all available plugins
        \\    load <plugin>
    ++ "\n\n", .{});
}

fn listPlugins(stdout: std.fs.File.Writer, allocator: std.mem.Allocator) !void {
    try stdout.print("Available Plugins:\n", .{});
    var dir = try std.fs.cwd().openDir("scripts", .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        try stdout.print("name: {s}\n", .{
            entry.path,
        });
    }
    std.debug.print("\n", .{});
}

pub fn luaTest() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var lua = try Lua.init(allocator);
    defer lua.deinit();
    lua.openLibs();

    try lua.doFile("/home/karma/projects/zig/ZPT/scripts/scan.lua");
}
