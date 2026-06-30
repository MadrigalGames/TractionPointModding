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

const std = @import("std");
const basis = @import("basis");
const timbre = @import("timbre");

const EventDescriptionPtr = timbre.EventDescriptionPtr;
const EventInstancePtr = timbre.EventInstancePtr;

const Vec3 = basis.math.Vec3;

pub const SoundEffect = struct {
    const Self = @This();
    const MaxParamIndexCount = 8;
    const InvalidParamIndex: u32 = 0xFFFFFFFF;

    //----------------------------------------------------

    eventDesc: EventDescriptionPtr = .Null,
    eventInstance: EventInstancePtr = .Null,

    paramIndices: [MaxParamIndexCount]u32 = @splat(InvalidParamIndex),

    //----------------------------------------------------

    pub fn init(self: *Self, eventPath: []const u8) void {
        self.releaseInstance();
        self.eventDesc = timbre.sound_manager.getEventDesc(eventPath);
    }

    pub fn initWithParameterMappings(
        self: *Self,
        eventPath: []const u8,
        parameterMappings: anytype,
    ) void {
        self.init(eventPath);

        inline for (parameterMappings) |mapping| {
            // The first field is assumed to be an enum value with an integer representation
            // and the second field is assumed to be the parameter name.
            const paramIndexInList: usize = @intFromEnum(mapping.@"0");
            const paramName: []const u8 = mapping.@"1";
            const paramIndex = self.eventDesc.getParameterIndex(paramName);

            if (paramIndex == InvalidParamIndex) {
                basis.debug_overlay.debugWarning(
                    "Could not find Timbre event param \"{s}\" in event \"{s}\".",
                    .{ paramName, eventPath },
                );
            }

            self.paramIndices[paramIndexInList] = paramIndex;
        }
    }

    pub fn instantiate(self: *Self, autoPause: bool) EventInstancePtr {
        if (self.eventDesc.isNull()) {
            return EventInstancePtr.Null;
        }
        self.eventInstance = self.eventDesc.createInstance(autoPause);
        return self.eventInstance;
    }

    pub fn instantiate3D(self: *Self, autoPause: bool, position: Vec3, linearVelocity: Vec3) EventInstancePtr {
        if (self.eventDesc.isNull()) {
            return EventInstancePtr.Null;
        }
        self.eventInstance = self.eventDesc.createInstance(autoPause);
        self.eventInstance.set3DParameters(position, linearVelocity);
        return self.eventInstance;
    }

    pub fn deinit(self: *Self) void {
        self.releaseInstance();
    }

    //----------------------------------------------------

    pub fn start(self: *Self) void {
        if (!self.eventInstance.isNull()) {
            self.eventInstance.start();
        }
    }

    pub fn pause(self: *Self) void {
        if (!self.eventInstance.isNull()) {
            self.eventInstance.pause();
        }
    }

    pub fn stop(self: *Self) void {
        if (!self.eventInstance.isNull()) {
            self.eventInstance.stop();
        }
    }

    pub fn set3DParameters(self: *Self, position: Vec3, linearVelocity: Vec3) void {
        if (self.eventInstance.isNull()) {
            return;
        }

        self.eventInstance.set3DParameters(position, linearVelocity);
    }

    pub fn setParameter(self: *Self, parameterID: anytype, value: f32) void {
        if (self.eventInstance.isNull()) {
            return;
        }

        // The ID is assumed to be an enum value with an integer representation.
        const paramIndexInList: usize = @intFromEnum(parameterID);
        const paramIndex = self.paramIndices[paramIndexInList];

        if (paramIndex == InvalidParamIndex) {
            return;
        }

        self.eventInstance.setParameterByIndex(paramIndex, value);
    }

    pub fn setParameterByIndex(self: *const Self, index: u32, value: f32) void {
        if (self.eventInstance.isNull()) {
            return;
        }

        self.eventInstance.setParameterByIndex(index, value);
    }

    pub fn getState(self: *const Self) timbre.PlaybackState {
        if (self.eventInstance.isNull()) {
            return .Stopped;
        }
        return self.eventInstance.getState();
    }

    pub fn hasDesc(self: *const Self) bool {
        return !self.eventDesc.isNull();
    }

    pub fn isInstantiated(self: *const Self) bool {
        return !self.eventInstance.isNull();
    }

    //----------------------------------------------------

    fn releaseInstance(self: *Self) void {
        if (!self.eventInstance.isNull()) {
            self.eventInstance.stop();
            self.eventInstance.releaseAndZero();
        }
    }
};
