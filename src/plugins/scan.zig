const std = @import("std");
const handler = @import("handler.zig");
const Info = handler.Info;
const Option = handler.Plugin.Option;

var set_default = Info{
    .name = "NAME",
    .value = "42",
    .help = "This is a default handler interface.",
    .Plugin = &scan,
};

const options = [_]Option{
    .{ .key = "RHOST", .value = "127.0.0.1", .help = "Remote host" },
    .{ .key = "LPORT", .value = "4444", .help = "Local port" },
};
const options_slice: []const Option = &options;

var scan = handler.Plugin.init("scan", @constCast(options_slice));

// fn getOptions() []Option {
//     return &options;
// }

export fn getInfo() callconv(.C) *Info {
    set_default.name = "default";
    return @constCast(&set_default);
}
