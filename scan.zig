const interface = @import("handler.zig").interface;

export fn getNumber() *const interface {
    var init = interface{
        .name = "getNumber",
        .value = "42",
        .help = "Returns the number 42",
    };

    return &init;
}
