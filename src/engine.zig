const std = @import("std");
const zlua = @import("zlua");
const main = @import("main.zig");

const Lua = zlua.Lua;
const LuaState = zlua.LuaState;

const current_lua: ?*Lua = null;

pub const EngineError = error{
    UserExit,
    FunctionNotFound,
    InvalidCommand,
    InvalidPlugin,
};

pub const Cmds = enum {
    help,
    exit,
    list,
    load,
};

pub fn parseCommand(input: []const u8, ctx: *main.GlobalState) !void {
    ctx.user_input = std.mem.tokenizeSequence(u8, input, " ");

    const cmd = std.meta.stringToEnum(
        Cmds,
        ctx.user_input.next() orelse "help",
    ) orelse Cmds.help;

    try switch (cmd) {
        .help => showHelp(ctx.stdout),
        .exit => {
            try ctx.stdout.print("Exiting...\n", .{});
            return EngineError.UserExit; // this is def the wrong way to do this
        },
        .list => listPlugins(ctx.stdout, ctx.allocator),
        .load => {
            try handlePlugin(ctx);
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
    try stdout.print("\n", .{});
}

fn handlePlugin(ctx: *main.GlobalState) !void {
    if (ctx.sub_state == .Default) {
        ctx.plugin_name = ctx.user_input.next() orelse return EngineError.InvalidPlugin;
        ctx.sub_state = .Plugin;
        try loadPlugin(ctx);
    }
    std.debug.print("you're in the plugin handler for \"{s}\" plugin\n", .{ctx.plugin_name});
}

fn loadPlugin(ctx: *main.GlobalState) !void {
    const plugin_path = try std.fmt.allocPrintZ(
        ctx.allocator,
        "./scripts/{s}.zpt",
        .{ctx.plugin_name},
    );
    defer ctx.allocator.free(plugin_path);

    const lua = current_lua orelse try Lua.init(ctx.allocator);
    //defer lua.deinit();   handle this in plugin cleanup

    lua.openLibs();
    lua.pushFunction(&testLua);
    lua.setGlobal("testLua");

    try lua.doFile(plugin_path);
    // const option1
    // const option2
    const option1 = try getGlobalInt(lua, "option1");
    std.debug.print("option1 from lua: {d}\n", .{option1});
}

// fn cleanupPlugin(ctx: *main.GlobalState, lua: *Lua) !void {}

export fn testLua(lua: ?*LuaState) callconv(.c) c_int {
    _ = lua;
    std.debug.print("I am a function called from Lua\n", .{});
    return 0;
}

fn getGlobalInt(lua: *Lua, var_name: [:0]const u8) !zlua.Integer {
    _ = try lua.getGlobal(var_name);
    const result = try lua.toInteger(-1);
    lua.pop(1);
    return result;
}
