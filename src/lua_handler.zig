const std = @import("std");
const zlua = @import("zlua");
const main = @import("main.zig");

const Lua = zlua.Lua;
const LuaState = zlua.LuaState;

var current_lua: ?*Lua = null;

pub const LuaHandlerError = error{
    InvalidPlugin,
    NoSetKey,
    NoSetVal,
};

const PluginCmds = enum {
    get,
    set,
    help,
    run,
    quit,
};

fn showHelpPlugin(stdout: std.fs.File.Writer, plugin_name: []const u8) !void {
    try stdout.print(
        \\Available commands for {s}:
        \\    help - show this message
        \\    quit - return to main REPL
        \\    run  - BROKEN
        \\    get  - see lua options
        \\    set <LUA_OPT> <VALUE> 
    ++ "\n\n", .{plugin_name});
}

pub fn handlePlugin(ctx: *main.GlobalState) !void {
    const lua = current_lua.?;

    const plugin_cmd = std.meta.stringToEnum(
        PluginCmds,
        ctx.user_input.next() orelse "help",
    ) orelse PluginCmds.help;

    try switch (plugin_cmd) {
        .get => _ = try getOptions(lua),
        .set => { //this is prob too dense, need to rewrite or put more logic in the setter function
            if (ctx.user_input.next()) |k| {
                if (ctx.user_input.next()) |val| {
                    const key = try std.fmt.allocPrintZ(ctx.allocator, "{s}", .{k});
                    try ctx.stdout.print("SETTING {s} = {s}\n", .{ key, val });
                    _ = try setOption(lua, key, val);
                } else return LuaHandlerError.NoSetVal;
            } else return LuaHandlerError.NoSetKey;
        },
        .help => showHelpPlugin(ctx.stdout, ctx.plugin_name),
        .run => unreachable, //TODO implement
        .quit => cleanupPlugin(ctx, lua),
    };
}

// called from main repl: load <plugin>
pub fn initPlugin(ctx: *main.GlobalState) !void {
    ctx.plugin_name = ctx.user_input.peek() orelse return LuaHandlerError.InvalidPlugin;
    ctx.sub_state = .Plugin;

    const plugin_path = try std.fmt.allocPrintZ(
        ctx.allocator,
        "./scripts/{s}.zpt",
        .{ctx.plugin_name},
    );
    try ctx.stdout.print("Loading {s}\n\n", .{ctx.plugin_name});
    defer ctx.allocator.free(plugin_path);

    var lua: *Lua = undefined;
    if (current_lua) |_lua| {
        lua = _lua;
    } else {
        current_lua = try Lua.init(ctx.allocator);
        lua = current_lua.?;
    }

    lua.openLibs();
    lua.doFile(plugin_path) catch |e| {
        const err_msg = lua.toString(-1) catch "<non-string error>";
        try ctx.stdout.print("Lua error: {s}\n", .{err_msg});
        lua.pop(1); // remove error message from stack
        return e;
    };
    try showHelpPlugin(ctx.stdout, ctx.plugin_name);
}

fn cleanupPlugin(ctx: *main.GlobalState, lua: *Lua) void {
    lua.deinit();
    current_lua = null;
    ctx.sub_state = .Default;
}

fn setOption(lua: *Lua, key: [:0]const u8, val: []const u8) !void {
    _ = try lua.getGlobal("options");
    if (!lua.isTable(-1)) {
        std.debug.print("Error: options is not a table\n", .{});
        lua.pop(1);
        return;
    }

    _ = lua.pushString(val);
    lua.setField(-2, key);
    // _ = val;
    // _ = key;
    lua.pop(1);
}

fn getOptions(lua: *Lua) !void {
    _ = try lua.getGlobal("options");
    if (!lua.isTable(-1)) {
        _ = lua.pushString("Expected a table as argument");
        _ = lua.raiseError();
        return 0;
    }

    lua.pushNil();
    std.debug.print("Printing options...\n\n", .{});
    while (lua.next(1)) {
        const key = lua.toString(-2) catch "<non-string key>";
        const val = if (lua.isString(-1))
            lua.toString(-1) catch "<invalid>"
        else
            "<non-string/non-number>";

        std.debug.print("Option: {s} = {s}\n", .{ key, val });

        lua.pop(1);
    }
}
