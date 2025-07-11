const std = @import("std");
const handler = @import("engine.zig");

pub const Option = struct {
    name: []const u8,
    value: []const u8,
    help: []const u8,
};

pub const Plugin = struct {
    name: []const u8,
    help: []const u8,
    get_options: fn (self: *Plugin) []const Option,
    set_option: fn (self: *Plugin, key: []const u8, val: []const u8) bool,
    run: fn (self: *Plugin) void,
};

var opts = [_]handler.Option{
    .{ .name = "rhost", .value = "127.0.0.1", .help = "Target host" },
    .{ .name = "rport", .value = "80", .help = "Target port" },
};

fn get_options(self: *handler.Plugin) []const handler.Option {
    _ = self;
    return &opts;
}

fn set_option(self: *handler.Plugin, key: []const u8, val: []const u8) bool {
    _ = self;
    for (opts) |*opt| {
        if (std.mem.eql(u8, opt.name, key)) {
            opt.value = val;
            return true;
        }
    }
    return false;
}

fn run(self: *handler.Plugin) void {
    _ = self;
    std.debug.print("Running scan on {s}:{s}\n", .{ opts[0].value, opts[1].value });
}

var plugin_instance = handler.Plugin{
    .name = "scan",
    .help = "Simple port scanner",
    .get_options = get_options,
    .set_option = set_option,
    .run = run,
};

// Exported init function for engine to load
export fn init() *handler.Plugin {
    return &plugin_instance;
}
