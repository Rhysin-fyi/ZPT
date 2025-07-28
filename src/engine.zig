const std = @import("std");
const zlua = @import("zlua");

const Lua = zlua.Lua;
const LuaState = zlua.LuaState;

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
            try luaTest(allocator);
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

fn luaTest(allocator: std.mem.Allocator) !void {
    var lua = try Lua.init(allocator);
    defer lua.deinit();
    lua.openLibs();

    lua.pushFunction(&testLua);
    lua.setGlobal("testLua");

    try lua.doFile("./scripts/scan.zpt");
    // const option1
    // const option2
    const option1 = try getGlobalInt(lua, "option1");
    std.debug.print("option1 from lua: {d}\n", .{option1});
}

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
