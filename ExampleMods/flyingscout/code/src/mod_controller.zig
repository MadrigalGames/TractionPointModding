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
const basis = @import("basis");
const trampoline = @import("trampoline");

const ModControllerInterface = basis.mod_controller_interface.ModControllerInterface;
const ModControllerContext = basis.mod_controller.ModControllerContext;
const Allocator = std.mem.Allocator;

//----------------------------------------------------

pub const FlyingScoutModController = struct {
    const Self = @This();

    interface: ModControllerInterface,
    context: ModControllerContext,
    allocator: Allocator,

    pub fn init(interface: ModControllerInterface, allocator: Allocator, cppPtr: basis.CppPtr) Self {
        return Self{
            .interface = interface,
            .context = ModControllerContext.init(allocator, cppPtr),
            .allocator = allocator,
        };
    }

    pub fn postInit(_: *Self) !void {}

    pub fn deinit(self: *Self) void {
        self.context.deinit();
    }

    //----------------------------------------------------

    pub fn onAppStartup(self: *Self) !void {
        const libType = basis.library_api.getZigLibraryType();

        if (libType == .NativeDynamicLibrary or libType == .WASMClient) {
            if (self.context.getAppMode() == basis.app.AppMode.AppModeGame) {
                basis.debug_overlay.addDebugSpawnableObjectType("Vehicles/FlyingScout", 2.0);
            }

            const soundBanks = [_]trampoline.timbre_utils.SoundBankData{
                .{
                    .soundBankName = "main",
                    .soundBankResourcePath = "flyingscout_res/main.timbrebank",
                },
            };

            try trampoline.timbre_utils.loadAdditiveProject(
                self.context.getClient(),
                "flyingscout_res/flyingscout.timbre",
                &soundBanks,
            );
        }
    }

    //pub fn beforeAppShutdown(self: *Self) void {}

    //pub fn onServerCreated(self: *Self) !void {}

    //pub fn beforeServerDestroyed(self: *Self) void {}

    //pub fn onClientUpdate(self: *Self, deltaTime: f32) void {}

    //pub fn onClientTick(self: *Self, tickDeltaTime: f32) void {}

    //pub fn onServerTick(self: *Self, tickDeltaTime: f32) void {}

    //pub fn registerAngelScriptTypes(self: *Self, reg: basis.angelscript.TypeRegistration) void {}
};
