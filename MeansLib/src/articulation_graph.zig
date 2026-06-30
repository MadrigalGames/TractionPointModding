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

const PhysicsScenePtr = basis.physics.PhysicsScenePtr;
const PhysicsShapePtr = basis.physics.PhysicsShapePtr;
const PhysicsActorPtr = basis.physics.PhysicsActorPtr;
const PhysicsJointPtr = basis.physics.PhysicsJointPtr;
const PhysicsEnginePtr = basis.physics.PhysicsEnginePtr;
const PhysicsTransform = basis.physics.PhysicsTransform;
const PhysicsMaterialPtr = basis.physics.PhysicsMaterialPtr;

const SceneNodePtr = basis.math.SceneNodePtr;
const Vec2 = basis.math.Vec2;
const Vec3 = basis.math.Vec3;
const Quaternion = basis.math.Quaternion;
const Mat43 = basis.math.Mat43;

//----------------------------------------------------

// The ArticulationGraph ties together a graph of scene nodes with a set of physics actors
// (and their associated joints and collision shapes) and allows moving the physics actors
// around by moving the scene nodes. Each node in the graph should have a corresponding
// value in the enum specified by GraphNode.

// To use an ArticulationGraph, call create() and pass it the context of the owning
// component. After that you need to set up a scene node for each of the elements in the
// enum. Each scene node is to be a child node of [graphRoot] or other nodes in the graph.

// After that you can set up a physics actor and joint for one or more of the scene nodes,
// by calling createPhysicsPart(). The parent physics actor of the root is typically the
// physics actor of the parent object, eg. vehicle.

// The collision shapes are given in the coordinate space of the graph's root node, which is
// typically the same as the local space of the parent object, eg. vehicle.

// Once the collision parts are set up, the individual parts of the graph can be moved around
// by moving scene nodes around, typically in their parent space. After a node's transform
// has been updated, call updateJointDriveGoalPose() to update that node's physics actor.

// Note that on the server, we create a completely new scene graph, while on the client the
// graph is attached to the render scene node (see comment below). Because of this, the server
// scene graph stays at the world origin while the client graph moves around with the object.
// This is typically not an issue since, on the server, the graph is only really used to
// calculate transforms between the root and the leaves, but if necessary, [graphRoot] can be
// moved around manually on the server, enabling us to use it for world-space calculations too.
// On the client, meshes can be attached to the graph's nodes, and they will move around with
// the object.

pub const ArticulationGraphCollisionShape = struct {
    position: Vec3,
    size: Vec3,
    rotation: Vec3, // Euler angles, XYZ order.
};

pub const ArticulationGraphPhysicsPart = struct {
    actor: PhysicsActorPtr = .Null,
    joint: PhysicsJointPtr = .Null,
    inverseJointActorATransform: Mat43 = .Identity,
};

pub fn ArticulationGraph(comptime GraphNode: type, comptime ComponentContext: type) type {
    return struct {
        const Self = @This();

        const GraphSize = std.enums.values(GraphNode).len;

        pub const PhysicsPart = struct {
            actor: PhysicsActorPtr = .Null,
            joint: PhysicsJointPtr = .Null,
            inverseJointActorATransform: Mat43 = .Identity,
        };

        pub const JointUnlock = enum {
            None,
            Linear,
            Angular,
            LinearAndAngular,
        };

        //----------------------------------------------------

        physicsEngine: PhysicsEnginePtr = .Null,
        physicsScene: PhysicsScenePtr = .Null,

        gameObject: basis.game_object.GameObjectPtr = .Null,
        componentCtxt: ComponentContext = undefined,

        // On the server, the articulation graph creates a completely new scene node
        // as the graph root. This can be manually moved around, eg. with the parent
        // object, if needed. On the client, the graph root is the render scene node
        // of the parent object, and is thus moved around with it automatically.
        graphRoot: SceneNodePtr = .Null,

        // These are all the scene nodes in the graph, except for the graph root.
        sceneNodes: [GraphSize]SceneNodePtr = @splat(.Null),

        // Each node in the graph may have a corresponding physics actor and joint.
        physicsParts: [GraphSize]ArticulationGraphPhysicsPart = @splat(.{}),

        // Values used to set up the joints. If you want to override these values,
        // set them before calling createPhysicsPart().
        jointStiffness: f32 = std.math.floatMax(f32),
        jointDamping: f32 = 300.0,
        jointForceLimit: f32 = std.math.floatMax(f32),

        //----------------------------------------------------

        pub fn create(
            self: *Self,
            ctxt: ComponentContext,
        ) void {
            self.physicsEngine = ctxt.getPhysicsEngine();
            self.physicsScene = ctxt.getPrimaryPhysicsScene();
            self.gameObject = ctxt.getGameObject();
            self.componentCtxt = ctxt;

            if (ctxt.onServer()) {
                self.graphRoot = SceneNodePtr.initNew();
            } else {
                // On the client we attach the root node to the render scene node of the transform
                // component, so that we get interpolated transforms in case we want to attach meshes
                // to the graph.
                var renderSceneNode = ctxt.transform.getRenderSceneNode();
                basis.assert(@src(), !renderSceneNode.isNull());
                self.graphRoot = renderSceneNode.createChildNode();
            }
        }

        pub fn createPhysicsPart(
            self: *Self,
            graphNode: GraphNode,
            parentActor: PhysicsActorPtr,
            mass: f32,
            collisionShapes: []const ArticulationGraphCollisionShape,
            physicsMaterial: PhysicsMaterialPtr,
            parentObjectWorldMatrix: Mat43,
            jointUnlock: JointUnlock,
        ) void {
            for (&self.sceneNodes) |sceneNodePtr| {
                basis.assertd(
                    @src(),
                    !sceneNodePtr.isNull(),
                    "One or more scene nodes in the articulation graph is null. The whole graph must be initialized before calling createPhysicsPart().",
                );
            }

            const graphIndex: usize = @intFromEnum(graphNode);
            var part = &self.physicsParts[graphIndex];

            const partToRootMatrix = self.sceneNodes[graphIndex].getLocalToAncestorTransform(self.graphRoot);
            const partToParentNodeMatrix = self.sceneNodes[graphIndex].getLocalToParentTransform();

            const partToWorldMatrix = partToRootMatrix.concatenate(parentObjectWorldMatrix);
            const rootToPartMatrix = partToRootMatrix.inverse();

            basis.assert(@src(), collisionShapes.len <= 8);
            var shapeList: basis.BoundedArray(PhysicsShapePtr, 8) = .{};

            for (collisionShapes) |s| {
                var shapeTransform = PhysicsTransform.Identity;

                const positionInPartLocal = rootToPartMatrix.transformPoint(s.position);
                const rotationInPartLocal = Mat43.fromEulerAnglesXYZ(s.rotation).concatenate(rootToPartMatrix);

                shapeTransform = basis.physics.PhysicsTransform.init(
                    positionInPartLocal,
                    Quaternion.initFromRotationMatrix(rotationInPartLocal),
                );

                const shape = self.physicsEngine.createBox(
                    s.size.x,
                    s.size.y,
                    s.size.z,
                    physicsMaterial,
                    shapeTransform,
                    true,
                );

                shapeList.appendAssumeCapacity(shape);
            }

            part.actor = self.physicsEngine.createRigidBodyDynamic(
                shapeList.slice(),
                mass,
                Vec3.Zero,
                PhysicsTransform.initFromMatrix(partToWorldMatrix),
                false,
                false,
            );

            for (shapeList.slice()) |s| {
                s.release();
            }

            part.actor.associateWithGameObject(self.gameObject);

            self.physicsScene.addActor(part.actor);

            part.inverseJointActorATransform = partToParentNodeMatrix.inverse();

            part.joint = self.physicsEngine.createDof6Joint(
                parentActor,
                PhysicsTransform.initFromMatrix(partToParentNodeMatrix),
                part.actor,
                PhysicsTransform.init(Vec3.Zero, Quaternion.Identity),
            );

            //part.joint.setInvMassScale0(0);
            //part.joint.setInvInertiaScale0(0);

            switch (jointUnlock) {
                .None => {},
                .Linear => self.unlockLinearMovement(graphNode),
                .Angular => self.unlockAngularMovement(graphNode),
                .LinearAndAngular => self.unlockAllMovement(graphNode),
            }

            self.physicsScene.addJoint(part.joint);
        }

        pub fn destroy(self: *Self) void {
            self.destroyPhysicsParts();

            if (self.componentCtxt.onServer()) {
                self.graphRoot.deinit();
            } else {
                var renderSceneNode = self.componentCtxt.transform.getRenderSceneNode();
                std.debug.assert(!renderSceneNode.isNull());
                renderSceneNode.destroyChildNode(self.graphRoot);
            }
            self.graphRoot = .Null;
        }

        // A note on unlocking the joint: Even though a joint is only supposed to rotate around a single
        // axis, sometimes unlocking only that axis causes the system to become unstable, perhaps due to
        // how we drive the joint by setting the goal pose. Because of that, the functions below always
        // unlock ALL linear/angular movement and not just a single axis.

        pub fn unlockLinearMovement(self: *Self, graphNode: GraphNode) void {
            const graphIndex: usize = @intFromEnum(graphNode);
            const part = &self.physicsParts[graphIndex];

            part.joint.setDof6Motion(.AlongX, .Free);
            part.joint.setDof6Motion(.AlongY, .Free);
            part.joint.setDof6Motion(.AlongZ, .Free);

            part.joint.setDof6Drive(.X, self.jointStiffness, self.jointDamping, self.jointForceLimit, true);
            part.joint.setDof6Drive(.Y, self.jointStiffness, self.jointDamping, self.jointForceLimit, true);
            part.joint.setDof6Drive(.Z, self.jointStiffness, self.jointDamping, self.jointForceLimit, true);
        }

        pub fn unlockAngularMovement(self: *Self, graphNode: GraphNode) void {
            const graphIndex: usize = @intFromEnum(graphNode);
            const part = &self.physicsParts[graphIndex];

            part.joint.setDof6Motion(.AroundX, .Free);
            part.joint.setDof6Motion(.AroundY, .Free);
            part.joint.setDof6Motion(.AroundZ, .Free);

            part.joint.setDof6Drive(.Twist, self.jointStiffness, self.jointDamping, self.jointForceLimit, true);
            part.joint.setDof6Drive(.Swing, self.jointStiffness, self.jointDamping, self.jointForceLimit, true);
            part.joint.setDof6Drive(.Slerp, self.jointStiffness, self.jointDamping, self.jointForceLimit, true);
        }

        pub fn unlockAllMovement(self: *Self, graphNode: GraphNode) void {
            self.unlockLinearMovement(graphNode);
            self.unlockAngularMovement(graphNode);
        }

        pub fn updateJointDriveGoalPose(self: *Self, graphNode: GraphNode) void {
            const node = self.sceneNodes[graphNode.idx()];
            const part = &self.physicsParts[graphNode.idx()];

            basis.assert(@src(), !part.joint.isNull());
            const localToParent = node.getLocalToParentTransform();
            const driveGoalMatrix = localToParent.concatenate(part.inverseJointActorATransform);
            part.joint.setDriveGoalPose(PhysicsTransform.initFromMatrix(driveGoalMatrix));
        }

        //----------------------------------------------------

        fn destroyPhysicsParts(self: *Self) void {
            for (&self.physicsParts) |*p| {
                if (!p.joint.isNull()) {
                    self.physicsScene.removeJoint(p.joint);
                    p.joint.releaseAndZero();
                }

                if (!p.actor.isNull()) {
                    self.physicsScene.removeActor(p.actor);
                    p.actor.releaseAndZero();
                }
            }
        }
    };
}
