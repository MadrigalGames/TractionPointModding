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
const build_utils = @import("build_utils.zig");

// Build the library as a WASM module, as opposed to a native library? Can be overridden with -Dbuild-as-wasm=[bool]
const BuildAsWASM = true;

//----------------------------------------------------
const SdkPath = ""; // Modding SDK path here.
const MeansLibPath = ""; // The path to the folder containing the "MeansLib" root folder.
const LibName = "flyingscout";
const RootSourceFile = "src/main.zig";
const OutputDir = "../build";
//----------------------------------------------------

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const buildAsWASM = b.option(
        bool,
        "build-as-wasm",
        "Whether to build the library as WASM (as opposed to a DLL)",
    ) orelse BuildAsWASM;

    b.exe_dir = OutputDir;

    const lib = build_utils.createModLibrary(
        b,
        buildAsWASM,
        LibName,
        b.path(RootSourceFile),
        optimize,
    );

    const buildOptionsModule = build_utils.createBuildOptionsModule(b, buildAsWASM);

    build_utils.addModules(
        b,
        lib.root_module,
        buildOptionsModule,
        SdkPath,
        MeansLibPath,
    );

    const installArtifact = b.addInstallArtifact(lib, .{
        .dest_dir = .{ .override = .bin },
    });
    b.getInstallStep().dependOn(&installArtifact.step);
}
