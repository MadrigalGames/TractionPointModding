// Copyright 2018-2025 Madrigal Ltd.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
// 
// 3. Neither the name of the copyright holder nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
// 
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

// NOTE! This build file is here solely to help zls find the source files
// of the used packages, eg. basis. You shouldn't build this library on its own.

// Where to find the Basis SDK files. The path is relative to the build file (ie. this file).
const BasisSDKRootFolder = "../../";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .name = "MeansLib",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/meanslib.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    addModules(b, lib.root_module);

    b.installArtifact(lib);
}

fn createLibraryModule(b: *std.Build, path: []const u8, basisModule: *std.Build.Module) *std.Build.Module {
    return b.createModule(.{
        .root_source_file = b.path(path),
        .imports = &.{
            .{ .name = "basis", .module = basisModule },
        },
    });
}

fn createLibraryModuleWithImports(b: *std.Build, path: []const u8, imports: []const std.Build.Module.Import) *std.Build.Module {
    return b.createModule(.{
        .root_source_file = b.path(path),
        .imports = imports,
    });
}

fn addModules(
    b: *std.Build,
    libModule: *std.Build.Module,
) void {
    const basisModule = b.createModule(.{ .root_source_file = b.path(BasisSDKRootFolder ++ "Basis/zig/src/basis.zig") });
    //basisModule.addIncludePath(b.path(BasisSDKRootFolder ++ "Basis/include/messages")); // No longer used since we hand-convert the engine messages now.

    const trampolineModule = createLibraryModule(b, BasisSDKRootFolder ++ "Trampoline/zig/src/trampoline.zig", basisModule);
    const timbreModule = createLibraryModule(b, BasisSDKRootFolder ++ "Timbre/zig/src/timbre.zig", basisModule);
    const ghlModule = createLibraryModuleWithImports(b, BasisSDKRootFolder ++ "ZigLibs/GameHelperLibrary/src/ghl.zig", &.{
        .{ .name = "basis", .module = basisModule },
        .{ .name = "timbre", .module = timbreModule },
    });
    //const goofyModule = createLibraryModule(b, BasisSDKRootFolder ++ "Goofy/zig/src/goofy.zig", basisModule);
    //const nemoModule = createLibraryModule(b, BasisSDKRootFolder ++ "Nemo/zig/src/nemo.zig", basisModule);
    //const merlinModule = createLibraryModule(b, BasisSDKRootFolder ++ "Merlin/zig/src/merlin.zig", basisModule);
    //const vhlModule = createLibraryModule(b, BasisSDKRootFolder ++ "ZigLibs/VehicleHelperLibrary/src/vhl.zig", basisModule);
    //const fuzzModule = createLibraryModule(b, BasisSDKRootFolder ++ "ZigLibs/Fuzz/src/fuzz.zig", basisModule);

    libModule.addImport("basis", basisModule);
    libModule.addImport("trampoline", trampolineModule);
    libModule.addImport("timbre", timbreModule);
    libModule.addImport("ghl", ghlModule);
    //libModule.addImport("goofy", goofyModule);
    //libModule.addImport("nemo", nemoModule);
    //libModule.addImport("merlin", merlinModule);
    //libModule.addImport("vhl", vhlModule);
    //libModule.addImport("fuzz", fuzzModule);
}
