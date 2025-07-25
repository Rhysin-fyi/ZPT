const std = @import("std");

pub const Info = extern struct {
    name: [*:0]const u8,
    value: [*:0]const u8,
    help: [*:0]const u8,
    Plugin: *Plugin,
};

//write this like an allocator with a config struct passed in

pub const Plugin = struct {
    name: []const u8,
    opts: []Option,

    pub fn init(name: []const u8, options: []Option) Plugin {
        return Plugin{
            .name = name,
            .opts = options,
        };
    }

    pub const Option = struct {
        key: []const u8,
        value: []const u8,
        help: []const u8,
    };

    pub fn getOptions() void {
        std.debug.print("getting options...\n", .{});
    }
    pub fn setOptions() void {
        std.debug.print("setting options x to value y...\n", .{});
    }
    pub fn run() void {
        std.debug.print("run Forest, run!", .{});
    }
};
