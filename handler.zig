const std_dyn = @import("std").DynLib;

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

pub fn loadDynLib(modname: []const u8) !void {
    var loaded_lib = try std_dyn.open(modname);
    defer loaded_lib.close();
}
