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

module flyingscout::thruster_flame;
import basis;

const float TIME_BETWEEN_FLAME_UPDATES @local = 0.1f;
const sz FLAME_COUNT = 3;

struct ThrusterFlame
{
	RendererPtr renderer;
	RenderScenePtr renderScene;

	MaterialPtr material;

	MeshPtr[FLAME_COUNT] meshes;
	MeshInstancePtr[FLAME_COUNT] meshInstances;

	SceneNodePtr parentSceneNode;
	Vec3 localBasePosition;
	SceneNodePtr flameSceneNode;

	Prng rng;
	float timeUntilNextFlameUpdate;
	sz visibleFlameIndex;
}

//----------------------------------------------------

fn void ThrusterFlame.init(&self, RendererPtr renderer, SceneNodePtr parentSceneNode, Vec3 localPosition)
{
	self.rng = basis::math::initNewPrng();

	self.renderer = renderer;
	self.renderScene = renderer.getPrimaryScene();
	self.parentSceneNode = parentSceneNode;
	self.localBasePosition = localPosition;

	self.flameSceneNode = self.parentSceneNode.createChildNode();
	self.flameSceneNode.setPosition(self.localBasePosition);

	// Load the material.

	MaterialResourcePtr materialRes = resource_manager::acquireResource{MaterialResourcePtr}("game/materials/thruster_flame.binmaterial");
	self.material = materialRes.getSharedMaterial();
	materialRes.release();

	// Load the meshes.

	String[FLAME_COUNT] meshResourcePaths = {
		"flyingscout_res/thruster_flame1.binmesh",
		"flyingscout_res/thruster_flame2.binmesh",
		"flyingscout_res/thruster_flame3.binmesh",
	};

	foreach (i, path : meshResourcePaths)
	{
		MeshResourcePtr meshRes = resource_manager::acquireResource{MeshResourcePtr}(path);
		self.meshes[i] = meshRes.getSharedMesh();
		meshRes.release();
	}

	// Create the mesh instances.

	MaterialPtr[1] materials = { self.material };
	for (sz i = 0; i < FLAME_COUNT; ++i)
	{
		self.meshInstances[i] = self.renderScene.createDynamicMeshInstance(self.meshes[i], materials[..]);
		self.flameSceneNode.attachMeshInstance(self.meshInstances[i]);
	}

	self.timeUntilNextFlameUpdate = TIME_BETWEEN_FLAME_UPDATES;
	self.visibleFlameIndex = 0;
	self.updateFlameVisibility();
}

fn void ThrusterFlame.deinit(&self)
{
	self.flameSceneNode.detachAll();
	for (sz i = 0; i < FLAME_COUNT; ++i)
	{
		self.renderScene.destroyMeshInstance(self.meshInstances[i]);
		self.meshes[i].releaseAndZero();
	}
	self.material.releaseAndZero();

	self.parentSceneNode.destroyChildNode(self.flameSceneNode);
	self.flameSceneNode = {};
}

fn void ThrusterFlame.update(&self, float deltaTime, float thrust)
{
	float localYOffset = basis::math::remapFloat(thrust, 0.0f, 1.0f, 0.3f, -0.15f);
	Vec3 offset = { 0.0f, localYOffset, 0.0f };
	self.flameSceneNode.setPosition(self.localBasePosition + offset);

	self.timeUntilNextFlameUpdate -= deltaTime;

	// When it is time to update the flame we switch the mesh to the next in the list, and rotate the mesh randomly around its local Y axis.
	if (self.timeUntilNextFlameUpdate <= 0.0f)
	{
		self.timeUntilNextFlameUpdate = TIME_BETWEEN_FLAME_UPDATES;
		self.visibleFlameIndex = (self.visibleFlameIndex + 1) % FLAME_COUNT;
		self.updateFlameVisibility();

		Quaternion orientation = quaternion::initRotationY(basis::math::getRandomFloat(&self.rng, 0.0f, basis::math::TWO_PI));
		self.flameSceneNode.setOrientation(orientation);
	}
}

//----------------------------------------------------

fn void ThrusterFlame.updateFlameVisibility(&self)
{
	for (sz i = 0; i < FLAME_COUNT; ++i)
	{
		self.meshInstances[i].setVisible(i == self.visibleFlameIndex);
	}
}
