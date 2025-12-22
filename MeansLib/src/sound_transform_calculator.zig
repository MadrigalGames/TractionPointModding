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
const meanslib = @import("meanslib.zig");
const timbre = @import("timbre");

const Vec3 = basis.math.Vec3;

pub fn SoundTransformCalculator(comptime Context: type) type {
    return struct {
        const Self = @This();

        // We need to clamp the velocity to some reasonable max
        // value since the doppler effect can get really out of hand
        // otherwise, which can even lead to crashes inside SoLoud.
        const MAX_VELOCITY = 50.0; // 180 Km/h.
        //----------------------------------------------------

        position: Vec3 = Vec3.Zero,
        velocity: Vec3 = Vec3.Zero,

        // The lerp factor determines how much smoothing is applied
        // to the velocity. At 0 the velocity never changes, at 1
        // it changes rapidly. At values in between, it smoothly
        // blends between the previous velocity and the current one.
        lerpFactor: f32 = 0.5,

        //----------------------------------------------------

        // pub fn init() Self {
        //     return Self{};
        // }

        pub fn reset(self: *Self, position: Vec3) void {
            self.position = position;
            self.velocity = Vec3.Zero;
        }

        // Call this during update() or tick() (but not both)
        // to calculate the position and velocity values.
        pub fn updateOrTick(
            self: *Self,
            context: Context,
            deltaTime: f32,
            comptime calledFromTick: bool,
        ) void {
            const pos = if (calledFromTick)
                context.transform.getPosition()
            else
                context.transform.getRenderSceneNode().getPosition();

            const movementDelta = self.position.sub(pos);
            self.position = pos;
            var newVelocity = movementDelta.multiplyFloat(1.0 / deltaTime);

            if (newVelocity.squaredLength() > MAX_VELOCITY * MAX_VELOCITY) {
                newVelocity.normalize();
                newVelocity = newVelocity.multiplyFloat(MAX_VELOCITY);
            }

            self.velocity = Vec3.lerp(self.lerpFactor, self.velocity, newVelocity);
        }

        pub fn applyToSFX(self: *const Self, sfx: *meanslib.sound_effect.SoundEffect) void {
            sfx.set3DParameters(self.position, self.velocity);
        }

        pub fn applyToEvent(self: *const Self, eventInstance: timbre.EventInstancePtr) void {
            eventInstance.set3DParameters(self.position, self.velocity);
        }
    };
}
