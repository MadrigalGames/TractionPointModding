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

module flyingscout::components;
import basis;
import meanslib;
import byprod;
import flyingscout::thruster_flame;

//----------------------------------------------------

const Vec3 LEFT_THRUSTER_LOCAL_POS @local = { -1.8f, 1.0f, 0.0f };
const Vec3 RIGHT_THRUSTER_LOCAL_POS @local = { 1.8f, 1.0f, 0.0f };

const float THRUST_EPSILON @local = 0.01f;
const float THRUST_CHANGE_SPEED @local = 0.03f;

const float MAIN_THRUST_POWER @local = 10000.0f;
const float CORRECTION_THRUST_POWER @local = 1000.0f;

struct ScoutJetPackComponent @Component("flyingscout.ScoutJetPackComponent")
{
	AvatarTrackingComponent context;
	PropagatedValue{float} thrust;

	RendererPtr renderer;
	PhysicsActorPtr physicsActor;

	ThrusterFlame leftThrusterFlame;
	ThrusterFlame rightThrusterFlame;

	SoundEffect sfxThruster;
	SoundTransformCalculator sfxTransformCalculator;
}

//----------------------------------------------------

fn void ScoutJetPackComponent.init(&self, AvatarTrackingComponent context)
{
	self.context = context;
	self.thrust.init(&self.context, "thrust", true, false, 0.0f);
	self.sfxTransformCalculator.init();
}

fn void ScoutJetPackComponent.onObjectCreated(&self)
{
	if (self.context.inEditor()) return;

	self.physicsActor = self.context.transform.getPhysicsActor();

	if (self.context.onClient())
	{
		self.renderer = self.context.getRenderer();

		// The visuals are offset a little bit from the position we apply
		// the physical force. Thus the subtractions below.
		Vec3 leftVisualOffset = { -0.02f, 0.8f, 0.3f };
		Vec3 rightVisualOffset = { 0.02f, 0.8f, 0.3f };

		self.leftThrusterFlame.init(self.renderer, self.context.transform.getRenderSceneNode(), LEFT_THRUSTER_LOCAL_POS - leftVisualOffset);
		self.rightThrusterFlame.init(self.renderer, self.context.transform.getRenderSceneNode(), RIGHT_THRUSTER_LOCAL_POS - rightVisualOffset);

		self.sfxThruster.init("event:/[flyingscout]/Sounds/Thruster");

		Vec3 pos = self.context.transform.getPosition();

		EventInstancePtr sfxInstance = self.sfxThruster.instantiate3D(true, pos, vec3::ZERO);

		sfxInstance.start();

		self.sfxTransformCalculator.reset(pos);
	}
}

fn void ScoutJetPackComponent.destroy(&self)
{
	self.thrust.deinit();

	// The flames and the sound only exist when onObjectCreated() got the renderer.
	if (!self.renderer.isNull())
	{
		self.leftThrusterFlame.deinit();
		self.rightThrusterFlame.deinit();

		self.sfxThruster.deinit();
	}
}

fn void ScoutJetPackComponent.update(&self, float deltaTime)
{
	if (!self.context.onClient() || self.context.inEditor()) return;

	float thrust = self.thrust.get();
	if (thrust > THRUST_EPSILON && self.context.isClientLocalAvatar())
	{
		int w = (int)self.renderer.getWindowWidth();
		int h = (int)self.renderer.getWindowHeight();

		char[128] buffer;
		String text = string::bformat(buffer[..], "Thrust: %.2f", thrust);

		basis::debug_draw::drawStringXY(text, w / 2, h - 100, color::WHITE, TextPivot.CENTER);
	}

	self.leftThrusterFlame.update(deltaTime, thrust);
	self.rightThrusterFlame.update(deltaTime, thrust);

	self.sfxTransformCalculator.updateOrTick(&self.context, deltaTime, false);
	self.sfxTransformCalculator.applyToSFX(&self.sfxThruster);

	// Only one param in the event, so just use index 0 without any lookup.
	self.sfxThruster.setParameterByIndex(0, thrust);
}

fn void ScoutJetPackComponent.preTick(&self, float tickDeltaTime)
{
	if (!self.context.onServer()) return;

	bool thrustInput = self.context.getInputState(InputID.VEHICLE_MOD_STATE);

	float prevThrust = self.thrust.get();
	float thrust = prevThrust;

	if (thrustInput)
	{
		thrust += THRUST_CHANGE_SPEED;
	}
	else
	{
		thrust -= THRUST_CHANGE_SPEED;
	}

	thrust = basis::math::clamp(thrust, 0.0f, 1.0f);

	if (!basis::math::floatsAlmostEqual(thrust, prevThrust))
	{
		// Update the PV only if the value has changed to avoid spamming the network.
		self.thrust.set(thrust);
	}

	if (thrust <= THRUST_EPSILON) return;

	Mat43 worldMatrix = self.context.transform.getWorldMatrix();
	Vec3 rightDir = worldMatrix.getX();
	Vec3 thrustDir = worldMatrix.getY();
	Vec3 forwardDir = worldMatrix.getZ();

	// Apply main engine thrust.

	Vec3 leftEnginePosWorld = worldMatrix.transformPoint(LEFT_THRUSTER_LOCAL_POS);
	Vec3 rightEnginePosWorld = worldMatrix.transformPoint(RIGHT_THRUSTER_LOCAL_POS);

	Vec3 mainForce = thrustDir * (thrust * MAIN_THRUST_POWER);

	self.physicsActor.addForce(mainForce, leftEnginePosWorld, false);
	self.physicsActor.addForce(mainForce, rightEnginePosWorld, false);

	// Apply thrust at the front/back/left/right of the vehicle to keep it upright.

	if (rightDir.y < 0.0f)
	{
		// Apply force on the right.
		Vec3 down = { 0.0f, -1.0f, 0.0f };
		Vec3 localPos = { 1.8f, 0.0f, 0.0f };
		Vec3 force = thrustDir * (rightDir.dot(down) * CORRECTION_THRUST_POWER);
		self.physicsActor.addForce(force, worldMatrix.transformPoint(localPos), false);
	}
	else
	{
		// Apply force on the left.
		Vec3 up = { 0.0f, 1.0f, 0.0f };
		Vec3 localPos = { -1.8f, 0.0f, 0.0f };
		Vec3 force = thrustDir * (rightDir.dot(up) * CORRECTION_THRUST_POWER);
		self.physicsActor.addForce(force, worldMatrix.transformPoint(localPos), false);
	}

	if (forwardDir.y < 0.0f)
	{
		// Apply force on the front.
		Vec3 down = { 0.0f, -1.0f, 0.0f };
		Vec3 localPos = { 0.0f, 0.0f, 1.9f };
		Vec3 force = thrustDir * (forwardDir.dot(down) * CORRECTION_THRUST_POWER);
		self.physicsActor.addForce(force, worldMatrix.transformPoint(localPos), false);
	}
	else
	{
		// Apply force on the back.
		Vec3 up = { 0.0f, 1.0f, 0.0f };
		Vec3 localPos = { 0.0f, 0.0f, -1.9f };
		Vec3 force = thrustDir * (forwardDir.dot(up) * CORRECTION_THRUST_POWER);
		self.physicsActor.addForce(force, worldMatrix.transformPoint(localPos), false);
	}
}
