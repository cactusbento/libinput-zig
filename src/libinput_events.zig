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
    /// Timestamp of the event.
    time: u32,
    /// Timestamp of the event in microseconds.
    time_us: u64,
    /// Keycode of the key pressed/released in this event.
    key: u32,
    /// Key state that triggered this event.
    state: KeyState,

    /// Defines possible states for a keypress.
    pub const KeyState = enum(u32) {
        pressed = c.LIBINPUT_KEY_STATE_PRESSED,
        released = c.LIBINPUT_KEY_STATE_RELEASED,
    };
};

pub const PointerEvent = struct {
    /// Timestamp of the event.
    time: u32,
    /// Timestamp of the event in microseconds.
    time_us: u64,
    /// Code of the button pressed/released in this event.
    ///
    /// Requires `.pointer_button`, else `0`
    button: u32,
    /// Button state that triggered this event.
    ///
    /// Requires `.pointer_button`, else `0`
    state: ButtonState,
    /// Change in position between last and current event.
    ///
    /// Requires `.pointer_motion`, else `{0, 0}`
    dxdy: Vec2,
    /// Unaccelerated change in position between last and current event.
    ///
    /// Requires `.pointer_motion`, else `{0, 0}`
    dxdy_unaccelerated: Vec2,
    /// The current absolute coordinate of the pointer event, in mm from the top left corner of the device.
    ///
    /// Requires `.pointer_motion_absolute`, else `{0, 0}`
    xy_absolute: Vec2,

    /// Defines a container for X and Y results
    pub const Vec2 = struct { x: f64, y: f64 };

    /// Defines possible states for a button.
    pub const ButtonState = enum(u32) {
        pressed = c.LIBINPUT_BUTTON_STATE_PRESSED,
        released = c.LIBINPUT_BUTTON_STATE_RELEASED,
    };
};

pub const EventUnion = union(enum) {
    not_implemented,
    keyboard: KeyboardEvent,
    pointer: PointerEvent,
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
        .pointer_motion, .pointer_motion_absolute, .pointer_button => blk: {
            const event = c.libinput_event_get_pointer_event(self.ev);
            break :blk EventUnion{
                .pointer = .{
                    .time = c.libinput_event_pointer_get_time(event),
                    .time_us = c.libinput_event_pointer_get_time_usec(event),
                    .button = c.libinput_event_pointer_get_button(event),
                    .state = @enumFromInt(c.libinput_event_pointer_get_button_state(event)),
                    .dxdy = .{
                        .x = c.libinput_event_pointer_get_dx(event),
                        .y = c.libinput_event_pointer_get_dy(event),
                    },
                    .dxdy_unaccelerated = .{
                        .x = c.libinput_event_pointer_get_dx_unaccelerated(event),
                        .y = c.libinput_event_pointer_get_dy_unaccelerated(event),
                    },
                    .xy_absolute = .{
                        .x = c.libinput_event_pointer_get_absolute_x(event),
                        .y = c.libinput_event_pointer_get_absolute_y(event),
                    },
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
