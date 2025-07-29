const std = @import("std");
const zlua = @import("zlua");
const main = @import("main.zig");

const Lua = zlua.Lua;
const LuaState = zlua.LuaState;

const current_lua: ?*Lua = null;

const FAIL_GRACEFULLY = false;

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
}

fn loadPlugin(ctx: *main.GlobalState) !void {
    const plugin_path = try std.fmt.allocPrintZ(
        ctx.allocator,
        "./scripts/{s}.zpt",
        .{ctx.plugin_name},
    );
    try ctx.stdout.print("Loading {s}\n\n", .{ctx.plugin_name});
    defer ctx.allocator.free(plugin_path);

    const lua = current_lua orelse try Lua.init(ctx.allocator);

    lua.openLibs();

    try lua.doFile(plugin_path);

    var buf: [1024]u8 = undefined;
    while (true) {
        try ctx.stdout.print("zpt/{s}/> ", .{ctx.plugin_name});
        const line = try ctx.stdin.readUntilDelimiterOrEof(&buf, '\n') orelse break;

        const input = std.mem.trim(u8, line, " \r\n");

        var tokenizer = std.mem.tokenizeSequence(u8, input, " ");
        const token_opt = tokenizer.next();

        if (token_opt) |token| {
            if (std.mem.eql(u8, token, "set")) {
                const key = tokenizer.next() orelse {
                    try ctx.stdout.print("Missing key for set\n", .{});
                    continue;
                };

                const val = tokenizer.next() orelse {
                    try ctx.stdout.print("Missing value for set\n", .{});
                    continue;
                };

                try ctx.stdout.print("SETTING {s} = {s}\n", .{ key, val });
                _ = try setOption(lua, key, val);
            } else if (std.mem.eql(u8, token, "get")) {
                // Further handling...
                _ = try getOptions(lua);
            } else if (std.mem.eql(u8, token, "quit")) {
                try ctx.stdout.print("Bye!\n", .{});
                break;
            } else {
                try ctx.stdout.print("Unknown command: {s}\n", .{token});
            }
        }
    }
}

// fn cleanupPlugin(ctx: *main.GlobalState, lua: *Lua) !void {}

fn setOption(lua: *Lua, key: []const u8, val: []const u8) !void {
    _ = try lua.getGlobal("options");
    if (!lua.isTable(-1)) {
        std.debug.print("Error: options is not a table\n", .{});
        lua.pop(1);
        return;
    }

    //try lua.pushString(val);
    //try lua.setField(-2, key);
    _ = val;
    _ = key;
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
        else if (lua.isNumber(-1))
            std.fmt.allocPrintZ(std.heap.page_allocator, "{d}", .{lua.toNumber(-1) catch 0}) catch "<num>"
        else
            "<non-string/non-number>";

        std.debug.print("Option: {s} = {s}\n", .{ key, val });

        lua.pop(1);
    }
}
