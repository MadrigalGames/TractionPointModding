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

const RendererPtr = basis.renderer.RendererPtr;
const RenderScenePtr = basis.renderer.RenderScenePtr;
const MeshPtr = basis.renderer.MeshPtr;
const MaterialPtr = basis.renderer.MaterialPtr;
const MeshInstancePtr = basis.renderer.MeshInstancePtr;

const Vec3 = basis.math.Vec3;
const Quaternion = basis.math.Quaternion;
const SceneNodePtr = basis.math.SceneNodePtr;

const resource_manager = basis.resources.resource_manager;
const MeshResourcePtr = basis.resources.MeshResourcePtr;
const MaterialResourcePtr = basis.resources.MaterialResourcePtr;

const GameObjectPtr = basis.game_object.GameObjectPtr;

pub const ThrusterFlame = struct {
    const Self = @This();

    const TimeBetweenFlameUpdates = 0.1;

    renderer: RendererPtr = .Null,
    renderScene: RenderScenePtr = .Null,

    material: MaterialPtr = .Null,

    meshes: [3]MeshPtr = [_]MeshPtr{.Null} ** 3,
    meshInstances: [3]MeshInstancePtr = [_]MeshInstancePtr{.Null} ** 3,

    parentSceneNode: SceneNodePtr = .Null,
    localBasePosition: Vec3 = .Zero,
    flameSceneNode: SceneNodePtr = .Null,

    rng: basis.math.Prng = undefined,
    timeUntilNextFlameUpdate: f32 = 0.0,
    visibleFlameIndex: usize = 0,

    //----------------------------------------------------

    pub fn init(self: *Self, renderer: RendererPtr, parentSceneNode: SceneNodePtr, localPosition: Vec3) void {
        self.rng = basis.math.initNewPrng();

        self.renderer = renderer;
        self.renderScene = renderer.getPrimaryScene();
        self.parentSceneNode = parentSceneNode;
        self.localBasePosition = localPosition;

        self.flameSceneNode = self.parentSceneNode.createChildNode();
        self.flameSceneNode.setPosition(self.localBasePosition);

        // Load the material.

        const materialRes = resource_manager.acquireResourceOrError(
            MaterialResourcePtr,
            "game/materials/thruster_flame.binmaterial",
        );
        self.material = materialRes.getSharedMaterial();
        materialRes.release();

        // Load the meshes.

        const meshResourcePaths = [_][]const u8{
            "flyingscout_res/thruster_flame1.binmesh",
            "flyingscout_res/thruster_flame2.binmesh",
            "flyingscout_res/thruster_flame3.binmesh",
        };

        for (0..3) |i| {
            const meshRes = resource_manager.acquireResourceOrError(
                MeshResourcePtr,
                meshResourcePaths[i],
            );
            self.meshes[i] = meshRes.getSharedMesh();
            meshRes.release();
        }

        // Create the mesh instances.

        const m = [_]MaterialPtr{self.material};
        for (0..3) |i| {
            self.meshInstances[i] = self.renderScene.createDynamicMeshInstance(self.meshes[i], &m);
            self.flameSceneNode.attachMeshInstance(self.meshInstances[i]);
        }

        self.timeUntilNextFlameUpdate = TimeBetweenFlameUpdates;
        self.visibleFlameIndex = 0;
        self.updateFlameVisibility();
    }

    pub fn deinit(self: *Self) void {
        self.flameSceneNode.detachAll();
        for (0..3) |i| {
            self.renderScene.destroyMeshInstance(self.meshInstances[i]);
            self.meshes[i].releaseAndZero();
        }
        self.material.releaseAndZero();

        self.parentSceneNode.destroyChildNode(self.flameSceneNode);
        self.flameSceneNode = .Null;
    }

    pub fn update(self: *Self, deltaTime: f32, thrust: f32) void {
        const localYOffset = basis.math.remapFloat(thrust, 0.0, 1.0, 0.3, -0.15);
        const localPos = self.localBasePosition.add(Vec3.init(0, localYOffset, 0));
        self.flameSceneNode.setPosition(localPos);

        self.timeUntilNextFlameUpdate -= deltaTime;

        // When it is time to update the flame we switch the mesh to the next in the list, and rotate the mesh randomly around its local Y axis.
        if (self.timeUntilNextFlameUpdate <= 0.0) {
            self.timeUntilNextFlameUpdate = TimeBetweenFlameUpdates;
            self.visibleFlameIndex = (self.visibleFlameIndex + 1) % 3;
            self.updateFlameVisibility();

            const ori = Quaternion.initRotationY(basis.math.getRandomFloat(self.rng.random(), 0.0, std.math.tau));
            self.flameSceneNode.setOrientation(ori);
        }
    }

    //----------------------------------------------------

    fn updateFlameVisibility(self: *Self) void {
        for (0..3) |i| {
            self.meshInstances[i].setVisible(i == self.visibleFlameIndex);
        }
    }
};
