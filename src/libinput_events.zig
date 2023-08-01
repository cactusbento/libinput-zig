const std = @import("std");
const c = @import("libinput_core.zig").c;

const Event = @This();

/// Base Event Type
ev: *c.struct_libinput_event,

/// Destroy the event, freeing all associated resources.
///
/// Must be called to avoid leaks.
pub fn destroy(self: Event) void {
    c.libinput_event_destroy(self.ev);
}

pub const KeyboardEvent = struct {
    /// Timestamp of this keyboard event.
    time: u32,
    /// Timestamp of this keyboard event in microseconds.
    time_us: u64,
    /// Keycode of the key pressed/released.
    key: u32,
    /// Whether the key was pressed or released in this event.
    state: KeyState,

    /// Defines possible states for a keypress.
    pub const KeyState = enum(u32) {
        pressed = c.LIBINPUT_KEY_STATE_PRESSED,
        released = c.LIBINPUT_KEY_STATE_RELEASED,
    };
};

pub const EventUnion = union(enum) {
    not_implemented,
    keyboard: KeyboardEvent,
};

pub fn get_event(self: Event) EventUnion {
    return switch (self.kind()) {
        .keyboard_key => blk: {
            const event = c.libinput_event_get_keyboard_event(self.ev);
            break :blk EventUnion{
                .keyboard = .{
                    .time = c.libinput_event_keyboard_get_time(event),
                    .time_us = c.libinput_event_keyboard_get_time_usec(event),
                    .key = c.libinput_event_keyboard_get_key(event),
                    .state = if (c.libinput_event_keyboard_get_key_state(event) == c.LIBINPUT_KEY_STATE_PRESSED)
                        .pressed
                    else
                        .released,
                },
            };
        },
        // TODO: Implement the rest
        else => .{ .not_implemented = {} },
    };
}

pub const Kind = enum {
    /// For when the wrapper does not implement a specific event.
    not_implemented,

    /// This is not a real event type, and is only used to tell the user that no new event is available in the queue.
    ///
    /// See libinput_next_event_type().
    none,

    /// Signals that a device has been added to the context.
    ///
    /// The device will not be read until the next time the user calls libinput_dispatch() and data is available.
    ///
    /// This allows setting up initial device configuration before any events are created.
    device_added,
    /// Signals that a device has been removed.
    ///
    /// No more events from the associated device will be in the queue or be queued after this event.
    device_removed,

    // Keyboard events
    keyboard_key,

    // Mouse
    pointer_motion,
    pointer_motion_absolute,
    pointer_button,
    /// A scroll event from a wheel.
    pointer_scroll_wheel,
    /// A scroll event caused by the movement of one or more fingers on a device.
    pointer_scroll_finger,
    /// A scroll event from a continuous scroll source, e.g. button scrolling.
    pointer_scroll_continuous,
};

pub fn kind(self: Event) Kind {
    return switch (c.libinput_event_get_type(self.ev)) {
        c.LIBINPUT_EVENT_NONE => .none,
        c.LIBINPUT_EVENT_DEVICE_ADDED => .device_added,
        c.LIBINPUT_EVENT_DEVICE_REMOVED => .device_removed,
        c.LIBINPUT_EVENT_KEYBOARD_KEY => .keyboard_key,
        c.LIBINPUT_EVENT_POINTER_MOTION => .pointer_motion,
        c.LIBINPUT_EVENT_POINTER_MOTION_ABSOLUTE => .pointer_motion_absolute,
        c.LIBINPUT_EVENT_POINTER_BUTTON => .pointer_button,
        c.LIBINPUT_EVENT_POINTER_SCROLL_WHEEL => .pointer_scroll_wheel,
        c.LIBINPUT_EVENT_POINTER_SCROLL_FINGER => .pointer_scroll_finger,
        c.LIBINPUT_EVENT_POINTER_SCROLL_CONTINUOUS => .pointer_scroll_continuous,
        else => .not_implemented,
    };
}
