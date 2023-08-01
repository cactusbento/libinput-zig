const std = @import("std");
const libinput = @import("libinput");
const c = libinput.c;

pub fn main() !void {
    var li = try libinput.init(.{
        .udev = .{
            .seats = &[_][]const u8{
                "seat0",
            },
        },
    }, null);
    defer li.deinit();

    while (true) {
        try li.dispatch();

        if (li.get(.event)) |*event| {
            defer event.destroy();
            if (event.kind() == .keyboard_key) {
                const ev = event.get_event();
                if (ev.keyboard.key == 57) std.debug.print("Spacebar Event: {s}\n", .{
                    if (ev.keyboard.state == .pressed) "Pressed" else "Released",
                });
            }
        }
    }
}
