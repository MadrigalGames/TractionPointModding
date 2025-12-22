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
const basis = @import("basis");

//----------------------------------------------------

// Keep this in sync with the characters in Nemo.
pub const CharacterID = enum(u32) {
    Narrator = 0,
    Diego,
    MotherAI,
    Steller,
    Rowan,
};

pub const WorldLocationID = enum(u32) {
    RefineryIntro = 0,
    Refinery_Plane = 1,
    Refinery_LiftStation = 2,
    InvalidID = 0xFFFFFFFF,

    pub fn asInt(self: WorldLocationID) u32 {
        return @intFromEnum(self);
    }
};

//----------------------------------------------------

pub fn getCharacterNemoPath(character: CharacterID) []const u8 {
    return switch (character) {
        .Narrator => "char:/Characters/Narrator",
        .Diego => "char:/Characters/Diego",
        .MotherAI => "char:/Characters/MotherAI",
        .Steller => "char:/Characters/Steller",
        .Rowan => "char:/Characters/Rowan",
    };
}

pub const WorldLocation = struct {
    id: WorldLocationID,
    levelPath: []const u8,
    layersToLoad: []const []const u8,
    spawnPointName: []const u8,
};

pub fn getWorldLocation(id: WorldLocationID) *const WorldLocation {
    // We specifically don't use the id as an index into the locations
    // array, so that the ids remain stable even if the order is messed with.
    for (&WORLD_LOCATIONS) |*wl| {
        if (wl.id == id) {
            return wl;
        }
    }

    basis.fatalErrorWithFormat(@src(), "Could not find a world location with ID: {}.", .{id});
    unreachable;
}

pub fn getWorldLocationByLevelPath(levelPath: []const u8) *const WorldLocation {
    for (&WORLD_LOCATIONS) |*wl| {
        if (basis.string.eql(wl.levelPath, levelPath)) {
            return wl;
        }
    }

    basis.fatalErrorWithFormat(@src(), "Could not find a world location with level path: {s}.", .{levelPath});
    unreachable;
}

//----------------------------------------------------

const WORLD_LOCATIONS = [_]WorldLocation{
    WorldLocation{
        .id = WorldLocationID.RefineryIntro,
        .levelPath = "map_refinery_intro/refinery_intro_blockout.binlevel",
        .layersToLoad = &.{"Intro"},
        .spawnPointName = "",
    },
    WorldLocation{
        .id = WorldLocationID.Refinery_Plane,
        .levelPath = "map_refinery/refinery_blockout.binlevel",
        .layersToLoad = &.{"Mission_Elevator"}, // <-- Demo mission
        .spawnPointName = "",
    },
    WorldLocation{
        .id = WorldLocationID.Refinery_LiftStation,
        .levelPath = "map_refinery/refinery_blockout.binlevel",
        .layersToLoad = &.{},
        .spawnPointName = "",
    },
};
