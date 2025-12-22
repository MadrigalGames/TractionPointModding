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

pub fn addModules(
    b: *std.Build,
    libModule: *std.Build.Module,
    buildOptionsModule: *std.Build.Module,
    sdkPath: []const u8,
    meansLibPath: []const u8,
) void {
    const basisModule = b.createModule(.{
        .root_source_file = joinPaths(b, sdkPath, "Basis/zig/src/basis.zig"),
    });

    basisModule.addIncludePath(joinPaths(b, sdkPath, "Basis/include/messages"));

    // This needs to match the name used to @import the build options.
    basisModule.addImport("basis_build_options", buildOptionsModule);

    const trampolineModule = createLibraryModule(b, sdkPath, "Trampoline/zig/src/trampoline.zig", basisModule);
    const goofyModule = createLibraryModule(b, sdkPath, "Goofy/zig/src/goofy.zig", basisModule);
    const timbreModule = createLibraryModule(b, sdkPath, "Timbre/zig/src/timbre.zig", basisModule);
    const nemoModule = createLibraryModule(b, sdkPath, "Nemo/zig/src/nemo.zig", basisModule);
    const merlinModule = createLibraryModule(b, sdkPath, "Merlin/zig/src/merlin.zig", basisModule);
    const vhlModule = createLibraryModule(b, sdkPath, "ZigLibs/VehicleHelperLibrary/src/vhl.zig", basisModule);
    const ghlModule = createLibraryModuleWithImports(b, sdkPath, "ZigLibs/GameHelperLibrary/src/ghl.zig", &.{
        .{ .name = "basis", .module = basisModule },
        .{ .name = "timbre", .module = timbreModule },
    });
    const meanslibModule = createLibraryModuleWithImports(b, meansLibPath, "MeansLib/src/meanslib.zig", &.{
        .{ .name = "basis", .module = basisModule },
        .{ .name = "trampoline", .module = trampolineModule },
        .{ .name = "timbre", .module = timbreModule },
        .{ .name = "ghl", .module = ghlModule },
    });
    //const fuzzModule = createLibraryModule(b, sdkPath, "ZigLibs/Fuzz/src/fuzz.zig", basisModule);

    libModule.addImport("basis", basisModule);
    libModule.addImport("trampoline", trampolineModule);
    libModule.addImport("goofy", goofyModule);
    libModule.addImport("timbre", timbreModule);
    libModule.addImport("nemo", nemoModule);
    libModule.addImport("merlin", merlinModule);
    libModule.addImport("vhl", vhlModule);
    libModule.addImport("ghl", ghlModule);
    libModule.addImport("meanslib", meanslibModule);
    //libModule.addImport("fuzz", fuzzModule);
}

pub fn createModLibrary(
    b: *std.Build,
    buildAsWASM: bool,
    libName: []const u8,
    rootSourceFile: std.Build.LazyPath,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const isRelease = (optimize != .Debug);

    if (isRelease) {
        std.debug.print("Building Release...\n", .{});
    } else {
        std.debug.print("Building Debug...\n", .{});
    }

    if (buildAsWASM) {
        const wasmTarget = b.resolveTargetQuery(.{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding, // Mods shouldn't need anything from WASI, and can thus use freestanding.
            //.cpu_features_add = std.Target.wasm.featureSet(&.{ .atomics, .bulk_memory }), // Needed for WASM threading.
        });

        const module = b.createModule(.{
            .root_source_file = rootSourceFile,
            .target = wasmTarget,
            .optimize = optimize,
        });

        const lib = b.addExecutable(.{
            .name = libName,
            .root_module = module,
            //.single_threaded = false, // The WASM allocator fails with this at the moment.
        });

        lib.entry = .disabled;
        lib.rdynamic = true;

        return lib;
    } else {
        const nativeTarget = b.standardTargetOptions(.{});

        const module = b.createModule(.{
            .root_source_file = rootSourceFile,
            .target = nativeTarget,
            .optimize = optimize,
        });

        return b.addLibrary(.{
            .linkage = .dynamic,
            .name = libName,
            .root_module = module,
        });
    }
}

pub fn createBuildOptionsModule(b: *std.Build, buildAsWASM: bool) *std.Build.Module {
    const buildOptions = b.addOptions();
    buildOptions.step.name = "Basis build options";

    buildOptions.addOption(bool, "buildAsWASM", buildAsWASM);
    buildOptions.addOption(bool, "buildAsMod", true);

    return buildOptions.createModule();
}

//----------------------------------------------------

fn joinPaths(
    b: *std.Build,
    sdkFolderPath: []const u8,
    path: []const u8,
) std.Build.LazyPath {
    // Even though it is called cwd_relative, it can be absolute.
    const sdkPath = std.Build.LazyPath{ .cwd_relative = sdkFolderPath };
    return sdkPath.join(b.allocator, path) catch @panic("OOM");
}

fn createLibraryModule(
    b: *std.Build,
    sdkFolderPath: []const u8,
    path: []const u8,
    basisModule: *std.Build.Module,
) *std.Build.Module {
    return b.createModule(.{
        .root_source_file = joinPaths(b, sdkFolderPath, path),
        .imports = &.{
            .{ .name = "basis", .module = basisModule },
        },
    });
}

fn createLibraryModuleWithImports(
    b: *std.Build,
    sdkFolderPath: []const u8,
    path: []const u8,
    imports: []const std.Build.Module.Import,
) *std.Build.Module {
    return b.createModule(.{
        .root_source_file = joinPaths(b, sdkFolderPath, path),
        .imports = imports,
    });
}
