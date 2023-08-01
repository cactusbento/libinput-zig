const std = @import("std");
pub const c = @cImport({
    @cInclude("libinput.h");
    @cInclude("libudev.h");
});

pub const event = @import("libinput_events.zig");
const libinput = @This();

/// Holds user defined backend specific information.
pub const Backend = union(enum) {
    path: struct {
        /// usually `"/dev/input/event#"`.
        paths: []const []const u8,
        devices: []std.ArrayList(*c.struct_libinput_device),
    },
    udev: struct {
        /// udev instance from udev_new().
        ///
        /// If null, init will create an instance.
        udev: ?*c.struct_udev = null,

        /// List of seat names to be added.
        ///
        /// Must be supplied by the user.
        seats: []const []const u8,
    },
};

/// The interface used to init libinput.
/// Already contains a set of default functions.
pub var interface: c.libinput_interface = .{
    .open_restricted = open_restricted,
    .close_restricted = close_restricted,
};

/// Will contain all backend specific code
backend: Backend,

/// Main libinput struct
li: *c.struct_libinput,

/// Runs `libinput_#BACKEND_create_context` and the associated devices/seat functions.
///
/// Udev:
///     If the user does not supply their own udev instance (typically created by udev_new()),
///     init will create one for them.
pub fn init(backend: Backend, user_data: ?*anyopaque) !libinput {
    switch (backend) {
        .path => {
            return error.TODOImplementPathBackend;
        },
        .udev => {
            if (backend.udev.seats.len < 1) return error.NoSeatsProvided;

            var retVal = libinput{
                .backend = backend,
                .li = undefined,
            };

            if (retVal.backend.udev.udev == null) {
                retVal.backend.udev.udev = c.udev_new() orelse return error.FailedToInitUdev;
            }

            retVal.li = c.libinput_udev_create_context(
                &interface,
                user_data,
                retVal.backend.udev.udev,
            ) orelse return error.FailedToInitUdevContext;

            for (retVal.backend.udev.seats) |seat_name| {
                if (c.libinput_udev_assign_seat(retVal.li, seat_name.ptr) < 0) return error.FailedToAssignSeat;
            }

            return retVal;
        },
    }
}

/// Must be ran to avoid leaks and residual devices.
pub fn deinit(self: *libinput) void {
    _ = c.libinput_unref(self.li);

    switch (self.backend) {
        // TODO: Implement Path Backend
        .path => unreachable,
        .udev => {
            if (self.backend.udev.udev != null) {
                _ = c.udev_unref(self.backend.udev.udev);
            }
        },
    }
}

/// Main event dispatch function.
///
/// Reads events of the file descriptors and processes them internally.
pub fn dispatch(self: *libinput) !void {
    if (c.libinput_dispatch(self.li) != 0) return error.FailedDispatch;
}

pub const GetSetEnum = enum { fd, event, user_data, log_priority };

/// Retrieve data from libinput.
///
/// Runs `libinput_get_#ENUM-NAME-HERE()`
///
/// Target must be know at comptime.
pub fn get(self: *libinput, comptime target: GetSetEnum) switch (target) {
    .fd => c_int,
    .event => ?event,
    .user_data => ?*anyopaque,
    .log_priority => c_int,
} {
    return switch (target) {
        .fd => c.libinput_get_fd(self.li),
        .event => blk: {
            const e = c.libinput_get_event(self.li);
            break :blk if (e) |ev|
                event{ .ev = ev }
            else
                null;
        },
        .user_data => c.libinput_get_user_data(self.li),
        .log_priority => c.libinput_log_get_priority(self.li),
    };
}

pub fn @"suspend"(self: *libinput) void {
    c.libinput_suspend(self.li);
}

pub fn @"resume"(self: *libinput) !void {
    if (c.libinput_resume(self.li) != 0) return error.FailedToResume;
}

// =========================================================================
//                              Default Functions
// =========================================================================
//
// Default functions for the libinput interface.
fn open_restricted(path: [*c]const u8, flags: c_int, user_data: ?*anyopaque) callconv(.C) i32 {
    _ = user_data;
    const fd = std.os.openZ(path, @intCast(flags), 0x333) catch unreachable;
    return fd;
}

fn close_restricted(fd: c_int, user_data: ?*anyopaque) callconv(.C) void {
    _ = user_data;
    std.os.close(@intCast(fd));
}
