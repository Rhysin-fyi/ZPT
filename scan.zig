const handler_interface = @import("handler.zig");

const set_default = handler_interface.interface{
    .name = "default",
    .value = "0",
    .help = "This is a default handler interface.",
};

export fn getNumber() callconv(.C) *const handler_interface.interface {
    return &set_default;
}
