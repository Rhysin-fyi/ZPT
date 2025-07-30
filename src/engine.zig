const std = @import("std");
const zlua = @import("zlua");
const main = @import("main.zig");
const lua_handler = @import("lua_handler.zig");

const Lua = zlua.Lua;
const LuaState = zlua.LuaState;

var current_lua: ?*Lua = null;

pub const EngineError = error{
    FunctionNotFound,
    InvalidCommand,
};

pub const DefaultCmds = enum {
    help,
    exit,
    list,
    load,
};

pub fn parseCommandDefault(ctx: *main.GlobalState) !void {
    const default_cmd = std.meta.stringToEnum(
        DefaultCmds,
        ctx.user_input.next() orelse
            "help",
    ) orelse DefaultCmds.help;

    try switch (default_cmd) {
        .help => showHelpDefault(ctx.stdout),
        .exit => ctx.sub_state = .Exit,
        .list => try listPluginsDefault(ctx.stdout, ctx.allocator),
        .load => try lua_handler.initPlugin(ctx),
    };
}

fn showHelpDefault(stdout: std.fs.File.Writer) !void {
    try stdout.print(
        \\Available commands:
        \\    help - show this message
        \\    exit - exit console
        \\    list - show all available plugins
        \\    load <plugin>
    ++ "\n\n", .{});
}

fn listPluginsDefault(stdout: std.fs.File.Writer, allocator: std.mem.Allocator) !void {
    try stdout.print("Available Plugins:\n", .{});
    var dir = try std.fs.cwd().openDir("scripts", .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        try stdout.print("name: {s}\n", .{entry.path});
    }
    try stdout.print("\n", .{});
}

pub fn parseCommandPlugin(ctx: *main.GlobalState) !void {
    lua_handler.handlePlugin(ctx) catch |e| {
        std.debug.print("{any}", .{e});
    };
}
