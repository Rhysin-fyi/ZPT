const Interface = @import("handler.zig").Interface;

const set_default = Interface{
    .name = "NAME",
    .value = "42",
    .help = "This is a default handler interface.",
};

export fn getNumber() callconv(.C) *Interface {
    return @constCast(&set_default);
}
