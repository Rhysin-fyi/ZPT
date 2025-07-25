const std = @import("std");
const handler = @import("handler.zig");

var plugin_contex = handler.Context{
    .plugin_name = "Scan",
    .plugin_help = "I'm a scanner, I scan things.",
    .options = @constCast(&default_options),
};

const default_options = [_]handler.Option{
    .{ .key = "RHOST", .value = "127.0.0.1", .help = "Remote host" },
    .{ .key = "LPORT", .value = "4444", .help = "Local port" },
};

export fn getOpts(ctx: *handler.Context) callconv(.C) void {
    ctx.* = plugin_contex;
}

export fn setOpts(ctx: *handler.Context) callconv(.C) void {
    plugin_contex = ctx.*;
}

export fn run(ctx: *handler.Context) callconv(.C) void {
    _ = ctx;
    return;
}
