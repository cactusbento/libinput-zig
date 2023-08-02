const std = @import("std");
const libinput = @import("libinput_core.zig");
const c = libinput.c;

pub fn main() !void {
    var li = try libinput.init(.{ .udev = .{} }, null);
    defer li.deinit();

    while (true) {
        try li.dispatch();

        if (li.get(.event)) |*event| {
            defer event.destroy();
            if (event.kind() == .keyboard_key) {
                const ev = event.get_event();
                std.debug.print("KeyPressed: {d}\n", .{
                    ev.keyboard.key,
                });
            }
        }
    }
}
