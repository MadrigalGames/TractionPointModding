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
const meanslib = @import("meanslib");

const AvatarTrackingComponent = basis.component_contexts.AvatarTrackingComponent;

const PropagatedValue = basis.network.PropagatedValue;
const PropagatedValueHandle = basis.network.PropagatedValueHandle;

const Vec3 = basis.math.Vec3;

const ThrusterFlame = @import("../thruster_flame.zig").ThrusterFlame;

//----------------------------------------------------

pub const ScoutJetPackComponent = struct {
    const Self = @This();
    pub const RegistrationName = "flyingscout.ScoutJetPackComponent";
    pub const UpdateOrder = 50;

    const LeftThrusterLocalPos = Vec3.init(-1.8, 1.0, 0.0);
    const RightThrusterLocalPos = Vec3.init(1.8, 1.0, 0.0);

    const ThrustEpsilon = 0.01;

    const ThrustChangeSpeed = 0.03;

    const MainThrustPower = 10000.0;
    const CorrectionThrustPower = 1000.0;

    //----------------------------------------------------

    context: AvatarTrackingComponent,

    thrust: PropagatedValueHandle(f32),

    renderer: basis.renderer.RendererPtr = .Null,

    physicsActor: basis.physics.PhysicsActorPtr = .Null,

    leftThrusterFlame: ThrusterFlame = .{},
    rightThrusterFlame: ThrusterFlame = .{},

    sfxThruster: meanslib.SoundEffect = .{},

    sfxTransformCalculator: meanslib.SoundTransformCalculator(AvatarTrackingComponent) = .{},

    //----------------------------------------------------

    pub fn init(context: AvatarTrackingComponent) !Self {
        return Self{
            .context = context,
            .thrust = PropagatedValue(f32).init(
                context,
                "thrust",
                true,
                false,
                0.0,
            ),
        };
    }

    //----------------------------------------------------

    // pub fn create(self: *Self) !void {}

    pub fn onObjectCreated(self: *Self) !void {
        if (!self.context.inEditor()) {
            self.physicsActor = self.context.transform.getPhysicsActor();

            if (self.context.onClient()) {
                self.renderer = self.context.getRenderer();

                // The visuals are offset a little bit from the position we apply
                // the physical force. Thus the subtractions below.
                self.leftThrusterFlame.init(
                    self.renderer,
                    self.context.transform.getRenderSceneNode(),
                    LeftThrusterLocalPos.sub(Vec3.init(-0.02, 0.8, 0.3)),
                );
                self.rightThrusterFlame.init(
                    self.renderer,
                    self.context.transform.getRenderSceneNode(),
                    RightThrusterLocalPos.sub(Vec3.init(0.02, 0.8, 0.3)),
                );

                self.sfxThruster.init("event:/[flyingscout]/Sounds/Thruster");

                const pos = self.context.transform.getPosition();

                const sfxInstance = self.sfxThruster.instantiate3D(true, pos, .Zero);

                // TODO: Should we do a fade-in here?
                sfxInstance.start();

                self.sfxTransformCalculator.reset(pos);
            }
        }
    }

    pub fn destroy(self: *Self) !void {
        self.thrust.deinit();

        if (self.context.onClient()) {
            self.leftThrusterFlame.deinit();
            self.rightThrusterFlame.deinit();

            self.sfxThruster.deinit();
        }
    }

    pub fn update(self: *Self, deltaTime: f32) !void {
        if (self.context.onClient() and !self.context.inEditor()) {
            const thrust = self.thrust.get();
            if (thrust > ThrustEpsilon and self.context.isClientLocalAvatar()) {
                const w: i32 = @intCast(self.renderer.getWindowWidth());
                const h: i32 = @intCast(self.renderer.getWindowHeight());

                var buf: [128]u8 = undefined;
                const text = try std.fmt.bufPrint(&buf, "Thrust: {d:.2}", .{thrust});

                basis.debug_draw.drawStringXY(text, @divFloor(w, 2), h - 100, basis.Color.White, .Center);
            }

            self.leftThrusterFlame.update(deltaTime, thrust);
            self.rightThrusterFlame.update(deltaTime, thrust);

            self.sfxTransformCalculator.updateOrTick(self.context, deltaTime, false);
            self.sfxTransformCalculator.applyToSFX(&self.sfxThruster);

            // Only one param in the event, so just use index 0 without any lookup.
            self.sfxThruster.setParameterByIndex(0, thrust);
        }
    }

    pub fn preTick(self: *Self, tickDeltaTime: f32) !void {
        _ = tickDeltaTime;

        if (self.context.onServer()) {
            const thrustInput = self.context.getInputState(meanslib.input.InputID.VehicleModState);

            const prevThrust = self.thrust.get();
            var thrust = prevThrust;

            if (thrustInput) {
                thrust += ThrustChangeSpeed;
            } else {
                thrust -= ThrustChangeSpeed;
            }

            thrust = std.math.clamp(thrust, 0.0, 1.0);

            if (!basis.math.floatsAlmostEqual(thrust, prevThrust)) {
                // Update the PV only if the value has changed to avoid spamming the network.
                self.thrust.set(thrust);
            }

            if (thrust > ThrustEpsilon) {
                const worldMatrix = self.context.transform.getWorldMatrix();
                const rightDir = worldMatrix.getX();
                const thrustDir = worldMatrix.getY();
                const forwardDir = worldMatrix.getZ();

                // Apply main engine thrust.

                const leftEnginePosWorld = worldMatrix.transformPoint(LeftThrusterLocalPos);
                const rightEnginePosWorld = worldMatrix.transformPoint(RightThrusterLocalPos);

                {
                    const mainForce = thrustDir.multiplyFloat(thrust * MainThrustPower);

                    self.physicsActor.addForce(mainForce, leftEnginePosWorld, false);
                    self.physicsActor.addForce(mainForce, rightEnginePosWorld, false);
                }

                // Apply thrust at the front/back/left/right of the vehicle to keep it upright.

                if (rightDir.y < 0.0) {
                    // Apply force on the right.

                    const forceAmount = rightDir.dot(Vec3.init(0.0, -1.0, 0.0));
                    const force = thrustDir.multiplyFloat(forceAmount * CorrectionThrustPower);
                    const pos = worldMatrix.transformPoint(Vec3.init(1.8, 0, 0));

                    self.physicsActor.addForce(force, pos, false);
                } else {
                    // Apply force on the left.

                    const forceAmount = rightDir.dot(Vec3.init(0.0, 1.0, 0.0));
                    const force = thrustDir.multiplyFloat(forceAmount * CorrectionThrustPower);
                    const pos = worldMatrix.transformPoint(Vec3.init(-1.8, 0, 0));

                    self.physicsActor.addForce(force, pos, false);
                }

                if (forwardDir.y < 0.0) {
                    // Apply force on the front.

                    const forceAmount = forwardDir.dot(Vec3.init(0.0, -1.0, 0.0));
                    const force = thrustDir.multiplyFloat(forceAmount * CorrectionThrustPower);
                    const pos = worldMatrix.transformPoint(Vec3.init(0, 0, 1.9));

                    self.physicsActor.addForce(force, pos, false);
                } else {
                    // Apply force on the back.

                    const forceAmount = forwardDir.dot(Vec3.init(0.0, 1.0, 0.0));
                    const force = thrustDir.multiplyFloat(forceAmount * CorrectionThrustPower);
                    const pos = worldMatrix.transformPoint(Vec3.init(0, 0, -1.9));

                    self.physicsActor.addForce(force, pos, false);
                }
            }
        }
    }
};
