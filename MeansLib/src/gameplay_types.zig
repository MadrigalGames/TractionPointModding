// Copyright 2018-2026 Madrigal Ltd.
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
    Generic,
    Mother,
};

pub const AvatarRoleType = enum(i32) {
    Inactive = 0,
    Driver = 1,
    CargoCrane = 2,
    GravityCrane = 3,
    GripperArm = 4,
    TruckBed,
};

//----------------------------------------------------

pub const InteractableState = enum(u32) {
    Active = 0, // Active and can be interacted with.
    Inactive, // Visible but cannot be interacted with.
    Hidden, // Hidden.
};

// Identifies which of the two interaction slots an interaction occupies.
// An Interactable may enable one or both. Primary and Secondary map to
// the primary/secondary interaction input buttons and the two HUD prompt slots.
pub const InteractableType = enum(u32) {
    Primary = 0,
    Secondary,
};

// Identifies a code-defined availability rule for an interaction.
pub const InteractionPredicateID = enum(u32) {
    None = 0,
    VehicleSwitchable,
    ConversationStartable,
};

// The two stages of an interaction marker. Throughout the interaction code "stage 1" refers
// to Discovery and "stage 2" to Actionable.

// Discovery (stage 1) shows from far away. It is a marker only, ie. there is no HUD prompt
// and the interaction cannot be performed at this range yet.

// Actionable (stage 2) shows up close on the single selected target once every interaction
// condition is met (in range, slow enough, predicate passes).
pub const MarkerStage = enum(u32) {
    Discovery = 0, // Stage 1.
    Actionable, // Stage 2.
};

//----------------------------------------------------
