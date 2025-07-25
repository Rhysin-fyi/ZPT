const std = @import("std");
const File = std.fs.File;
const handler = @import("plugins/handler.zig");

pub const EngineError = error{
    UserExit,
    FunctionNotFound,
    InvalidCommand,
};

const getOptsFn = *const fn (*handler.Context) callconv(.C) void;
const setOptsFn = *const fn (*handler.Context) callconv(.C) void;
const runFn = *const fn (*handler.Context) callconv(.C) void;

pub const Plugin = struct {
    lib: std.DynLib,
    path: []const u8,
    get_opts_fn: getOptsFn,
    set_opts_fn: setOptsFn,
    run_fn: runFn,
};

pub fn parseCommand(input: []const u8, stdout: File.Writer) !void {
    var parts = std.mem.tokenizeSequence(u8, input, " ");

    const Cmds = enum {
        help,
        exit,
        list,
        load,
    };

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
    _ = stdout;
    //TODO: move this up the stack so it doesn't pop on the func stack every call
    var dba = std.heap.DebugAllocator(.{}){};
    const allocator = dba.allocator();

    const ctx = try allocator.create(handler.Context);
    //defer allocator.destroy(ctx);
    ctx.* = .{
        .plugin_name = undefined,
        .plugin_help = undefined,
        .options = undefined,
    };

    const loaded_plugin = try loadDynLib(plugin_name, allocator);

    //testing
    loaded_plugin.get_opts_fn(ctx);
    std.debug.print("BEFORE SET OPTS:\nname = {s}\nhelp = {s}\n\n", .{ ctx.plugin_name, ctx.plugin_help });
    ctx.* = .{
        .plugin_name = "CHANGED",
        .plugin_help = "We're so fucking back",
        .options = ctx.options,
    };
    loaded_plugin.set_opts_fn(ctx);
    loaded_plugin.get_opts_fn(ctx);
    std.debug.print("AFTER SET OPTS:\nname = {s}\nhelp = {s}\n", .{ ctx.plugin_name, ctx.plugin_help });
}

pub fn loadDynLib(plugin_name: []const u8, allocator: std.mem.Allocator) !Plugin {
    //TODO: change this to final plugin location (or make dynamic)
    const plugin_path = try std.fmt.allocPrint(allocator, "./zig-out/lib/lib{s}.so", .{
        plugin_name,
    });

    var lib = try std.DynLib.open(plugin_path);
    const get_opts_fn = lib.lookup(getOptsFn, "getOpts") orelse {
        return EngineError.FunctionNotFound;
    };
    const set_opts_fn = lib.lookup(setOptsFn, "setOpts") orelse {
        return EngineError.FunctionNotFound;
    };
    const run_fn = lib.lookup(runFn, "run") orelse {
        return EngineError.FunctionNotFound;
    };

    return .{
        .lib = lib,
        .path = plugin_name,
        .get_opts_fn = get_opts_fn,
        .set_opts_fn = set_opts_fn,
        .run_fn = run_fn,
    };
}
