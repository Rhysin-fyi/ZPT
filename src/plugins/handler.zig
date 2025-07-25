const std = @import("std");

//might need a is_required field?
pub const Option = struct {
    key: []const u8,
    value: []const u8,
    help: []const u8,
};

pub const Context = struct {
    plugin_name: []const u8,
    plugin_help: []const u8,
    options: []Option,
};
