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

const basis = @import("basis");

pub const APIVersionNumber = 2;

//----------------------------------------------------

pub const main_lib_call_id = @import("main_lib_call_id.zig");
pub const constants = @import("constants.zig");
pub const input = @import("input.zig");
pub const world = @import("world.zig");
pub const gameplay_types = @import("gameplay_types.zig");
pub const game_messages = @import("game_messages.zig");
pub const articulation_graph = @import("articulation_graph.zig");
pub const tag_flags = @import("tag_flags.zig");
pub const ui_constants = @import("ui_constants.zig");
pub const sound_effect = @import("sound_effect.zig");
pub const sound_transform_calculator = @import("sound_transform_calculator.zig");
pub const game_script_messages = @import("game_script_messages.zig");

//----------------------------------------------------

pub const SoundEffect = sound_effect.SoundEffect;
pub const SoundTransformCalculator = sound_transform_calculator.SoundTransformCalculator;
