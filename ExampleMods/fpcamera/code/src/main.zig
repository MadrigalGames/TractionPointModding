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
const trampoline = @import("trampoline");
const meanslib = @import("meanslib");
const fpcamera = @import("fpcamera.zig");

const UseStdDebugAllocator = false; // Use the Zig std lib DebugAllocator?

var heapAllocator = if (UseStdDebugAllocator)
    std.heap.DebugAllocator(.{}){}
else
    basis.memory.HeapAllocator{};

const allocator = if (basis.build_options.buildAsWASM)
    std.heap.wasm_allocator
else
    heapAllocator.allocator();

//----------------------------------------------------

export fn getVersionNumber(versionNumberType: u32) u32 {
    return if (versionNumberType == 0) basis.APIVersionNumber else meanslib.APIVersionNumber;
}

export fn initLibrary() void {
    fpcamera.modController = basis.mod_controller.create(fpcamera.FPCameraModController, allocator);
}

export fn deinitLibrary() void {
    basis.mod_controller.destroy(fpcamera.modController);
    //basis.components.deinitComponentTypes();

    if (UseStdDebugAllocator) {
        const daDeinit = heapAllocator.deinit();
        basis.sassertd(@src(), daDeinit == .ok, "Memory leaks detected.");
    }
}

export fn registerComponentTypes(callback: basis.components.ComponentRegistrationCallback) void {
    _ = callback;
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
