const std = @import("std");
const Interface = @import("handler.zig").Interface;
const Zigface = @import("handler.zig").Zigface;

var set_default = Interface{
    .name = "NAME",
    .value = "42",
    .help = "This is a default handler interface.",
    .ptr = &Heisenberg,
};

var Heisenberg = Zigface{
    .name = "Heisenberg",
    .age = 42,
};

export fn getNumber() callconv(.C) *Interface {
    return @constCast(&set_default);
}
export fn setNumber() callconv(.C) *Interface {
    set_default.name = "default";
    return @constCast(&set_default);
}

fn hello() void {
    std.debug.print("helloo from the LIBRARYYYYYY!", .{});
}
