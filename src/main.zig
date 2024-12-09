const std = @import("std");
const libinput = @import("libinput_core.zig");
const c = libinput.c;

pub fn main() !void {
    var li = try libinput.init(.{ .udev = .{} }, null);
    defer li.deinit();

    while (true) {
        try li.dispatch();

        if (li.get(.event)) |*event| {
            const ev: *const libinput.Event = event;
            defer ev.destroy();
            switch (ev.kind()) {
                .keyboard_key => {
                    const ev_union = ev.get_event();
                    std.debug.print("KeyPressed: {d}\n", .{
                        ev_union.keyboard.key,
                    });
                },
                else => {},
            }
        }
    }
}
