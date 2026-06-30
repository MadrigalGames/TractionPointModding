// Copyright 2018-2025 Madrigal Ltd.

// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.

// 2. Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.

// 3. Neither the name of the copyright holder nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
// CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

const std = @import("std");
const builtin = @import("builtin");
const basis = @import("basis");
const goofy = @import("goofy");
const timbre = @import("timbre");
const nemo = @import("nemo");
const merlin = @import("merlin");
const vhl = @import("vhl");
const ghl = @import("ghl");
//const fuzz = @import("fuzz");
const trampoline = @import("trampoline");
const meanslib = @import("meanslib");

// Change according to the mod.
const mod = @import("flyingscout.zig");
const ModCtrl = mod.FlyingScoutModController;

//----------------------------------------------------

// Allocator:

const UseStdDebugAllocator = false; // Use the Zig std lib DebugAllocator?

const HeapAllocator = if (UseStdDebugAllocator)
    std.heap.DebugAllocator(.{})
else
    basis.memory.HeapAllocator;

var heapAllocator = HeapAllocator{};

const modAllocator = if (basis.build_options.buildAsWASM)
    std.heap.wasm_allocator
else
    heapAllocator.allocator();

//----------------------------------------------------

// IO implementation:

const IoImplementation = if (basis.build_options.buildAsWASM)
    basis.null_io.NullIo
else
    std.Io.Threaded;

var ioImplementation: IoImplementation = undefined;

fn initIO() std.Io {
    if (basis.build_options.buildAsWASM) {
        ioImplementation = IoImplementation{};
        return ioImplementation.io();
    } else {
        // We can use "modAllocator" here (rather than "mod.g.allocator") as long
        // as the IO implementation is recreated on every hot-reload operation.
        ioImplementation = .init(modAllocator, .{ .environ = .empty });

        // ioBasic() basic leaves out networking functionality on Windows. We probably
        // don't need that though, as all networking is handled in C/C++.
        return ioImplementation.ioBasic();
    }
}

fn deinitIO() void {
    ioImplementation.deinit();
}

//----------------------------------------------------

export fn getVersionNumber(versionNumberType: u32) u32 {
    return if (versionNumberType == 0) basis.APIVersionNumber else meanslib.APIVersionNumber;
}

export fn initLibrary(callback: basis.components.ComponentRegistrationCallback) void {
    const io = initIO();

    // Note! Only pass modAllocator to mod.global_data. Use mod.g.allocator
    // for the rest. mod.global_data contains the master allocator interface to use.
    mod.global_data.create(mod, modAllocator, io);
    basis.global_data.create(mod.g.allocator, mod.g.io);
    goofy.global_data.create(mod.g.allocator, mod.g.io);
    //vhl.global_data.create(mod.g.allocator, mod.g.io); // VHL doesn't build with WASM yet...

    mod.modController = basis.mod_controller.create(ModCtrl, mod.g.allocator, mod.g.io);

    basis.components.initComponentTypes(
        &mod.components.list,
        mod.g.allocator,
        mod.g.io,
        callback,
    );
}

export fn deinitLibrary() void {
    basis.mod_controller.destroy(mod.modController);
    basis.components.deinitComponentTypes();

    //vhl.global_data.destroy(); // VHL doesn't build with WASM yet...
    goofy.global_data.destroy();
    basis.global_data.destroy();
    mod.global_data.destroy(mod);

    deinitIO();

    if (UseStdDebugAllocator) {
        const daDeinit = heapAllocator.deinit();
        basis.sassertd(@src(), daDeinit == .ok, "Memory leaks detected.");
    }
}

//----------------------------------------------------

comptime {
    // This makes sure that all functions marked "export" are exported even if the library isn't used yet.
    _ = goofy;
    _ = timbre;
    _ = nemo;
    _ = merlin;
    _ = trampoline;
}
