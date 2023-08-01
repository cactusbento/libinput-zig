# libinput-zig

A libinput wrapper library for zig.

It packs a bunch of functions into various structs to make the resulting library more "ziggy".

# Usage 

Add the package url to `build.zig.zon` and link libc, libinput, and libudev.
```zig
pub fn build(b: *std.Build) void {
    // ...
    exe.linkLibC();
    exe.linkSystemLibrary("libinput");
    exe.linkSystemLibrary("libudev");

    exe.addModule("libinput", libinput);
    // ...
}

```
Of course, you'll need both libinput and libudev installed on your system to build.
