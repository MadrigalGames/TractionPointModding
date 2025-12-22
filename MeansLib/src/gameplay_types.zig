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

const trampoline = @import("trampoline");
const meanslib = @import("../src/meanslib.zig");

//----------------------------------------------------

pub const GameModeType = enum(u32) {
    None = 0,
    Campaign,
    Sandbox,
};

pub fn getGameMode(client: bool) GameModeType {
    const callID: u64 = @intFromEnum(meanslib.main_lib_call_id.MainLibCallID.GetGameModeType);
    const param: u64 = if (client) 0 else 1;
    const ret = trampoline.bindings.api.MainLib_callU64(callID, param);
    return @enumFromInt(ret);
}

pub fn getGameModeByContext(context: anytype) GameModeType {
    const callID: u64 = @intFromEnum(meanslib.main_lib_call_id.MainLibCallID.GetGameModeType);
    const param: u64 = if (context.onClient()) 0 else 1;
    const ret = trampoline.bindings.api.MainLib_callU64(callID, param);
    return @enumFromInt(ret);
}

//----------------------------------------------------

pub const MeansVehicleType = enum(u32) {
    Scout,
    Gripper,
    Mother,
    GripperTruck,
    Generic, // Any other vehicle.
};

pub const AvatarRoleType = enum(i32) {
    Inactive = 0,
    Driver = 1,
    CargoCrane = 2,
    GravityCrane = 3,
    GripperArm = 4,
    TruckBed,
};

pub fn getAvatarRoleDisplayName(role: AvatarRoleType) []const u8 {
    // TODO: Localize these.
    return switch (role) {
        .Inactive => "Inactive",
        .Driver => "Driver",
        .CargoCrane => "Cargo Crane",
        .GravityCrane => "Gravity Crane",
        .GripperArm => "Gripper Arm",
        .TruckBed => "Truck Bed",
    };
}

//----------------------------------------------------

pub const InteractionAreaState = enum(u32) {
    Active = 0, // This area is active and can be interacted with.
    Inactive, // This area is inactive. It can still be seen but cannot be interacted with.CurvePath3D
    Hidden, // This area is hidden, and completely unusable.
};

pub const InteractionType = enum(u32) {
    InteractionArea = 0,
    SwitchVehicle,
};

//----------------------------------------------------
