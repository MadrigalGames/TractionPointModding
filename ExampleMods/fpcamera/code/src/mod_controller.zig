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
const trampoline = @import("trampoline");

const ModControllerInterface = basis.mod_controller_interface.ModControllerInterface;
const ModControllerContext = basis.mod_controller.ModControllerContext;
const Allocator = std.mem.Allocator;

const Message = basis.messaging.Message;
const MessageParametersPtr = basis.messaging.MessageParametersPtr;
const MessageNode = basis.messaging.MessageNode;

const RendererPtr = basis.renderer.RendererPtr;
const RenderScenePtr = basis.renderer.RenderScenePtr;
const CameraPtr = basis.renderer.CameraPtr;

const SceneNodePtr = basis.math.SceneNodePtr;

const GameObjectPtr = basis.game_object.GameObjectPtr;

const Vec3 = basis.math.Vec3;

//----------------------------------------------------

pub const FPCameraModController = struct {
    const Self = @This();

    //----------------------------------------------------

    interface: ModControllerInterface,
    context: ModControllerContext,
    allocator: Allocator,

    messageNode: ?*MessageNode = null,

    active: bool = false,

    avatarGO: GameObjectPtr = .Null,

    renderer: RendererPtr = .Null,
    renderScene: RenderScenePtr = .Null,

    prevCamera: CameraPtr = .Null,

    fpCamera: CameraPtr = .Null,
    fpCameraNode: SceneNodePtr = .Null,

    //----------------------------------------------------

    pub fn init(interface: ModControllerInterface, allocator: Allocator, cppPtr: basis.CppPtr) Self {
        return Self{
            .interface = interface,
            .context = ModControllerContext.init(allocator, cppPtr),
            .allocator = allocator,
        };
    }

    pub fn postInit(_: *Self) !void {}

    pub fn deinit(self: *Self) void {
        if (self.messageNode) |msgNode| {
            msgNode.deinit();
        }
        self.context.deinit();
    }

    //----------------------------------------------------

    pub fn onAppStartup(self: *Self) !void {
        const libType = basis.library_api.getZigLibraryType();

        if (libType == .NativeDynamicLibrary or libType == .WASMClient) {
            const client = self.context.getClient();

            self.renderer = client.getRenderer();
            self.renderScene = self.renderer.getPrimaryScene();

            self.messageNode = client.createMessageNode("FPCameraModController");
            self.messageNode.?.onMessageReceived = .initMethod(self, Self, onMessageReceived);
            self.messageNode.?.subscribeToMessageCategory(basis.engine_messages.MESSAGE_CATEGORY_AVATAR_TRACKING);
            self.messageNode.?.subscribeToMessageCategory(basis.engine_messages.MESSAGE_CATEGORY_GAME_FLOW);
        }
    }

    //pub fn beforeAppShutdown(self: *Self) void {}

    //pub fn onServerCreated(self: *Self) !void {}

    //pub fn beforeServerDestroyed(self: *Self) void {}

    //pub fn onClientUpdate(self: *Self, deltaTime: f32) void {}

    //pub fn onClientTick(self: *Self, tickDeltaTime: f32) void {}

    //pub fn onServerTick(self: *Self, tickDeltaTime: f32) void {}

    //pub fn registerAngelScriptTypes(self: *Self, reg: basis.angelscript.TypeRegistration) void {}

    //----------------------------------------------------

    fn activate(self: *Self, attachmentPos: Vec3) void {
        //basis.printf("***Activate First-Person Camera, attachment pos: [{d:.2}, {d:.2}, {d:.2}]\n", .{ attachmentPos.x, attachmentPos.y, attachmentPos.z });

        self.prevCamera = self.renderer.getMainCamera();
        self.renderer.removeCameraFromQueue(self.prevCamera);

        self.fpCamera = self.renderScene.createCamera();
        self.fpCamera.setPerspective(
            basis.math.Pi * 0.45,
            self.renderer.getAspectRatio(),
            0.1,
            1500.0,
        );

        const renderNode = self.avatarGO.getRenderSceneNode();

        self.fpCameraNode = renderNode.createChildNode();
        self.fpCameraNode.setPosition(attachmentPos);

        self.fpCameraNode.attachCamera(self.fpCamera);

        self.renderer.addCameraToFrontOfQueue(self.fpCamera);

        self.active = true;
    }

    fn deactivate(self: *Self, gameEnded: bool) void {
        //basis.print("***Deactivate First-Person Camera\n");

        self.renderer.removeCameraFromQueue(self.fpCamera);

        if (!gameEnded)
            self.renderer.addCameraToFrontOfQueue(self.prevCamera);

        // Check if the camera is still attached. If not, the avatar object has
        // probably been destroyed. In that case the scene node has also been
        // destroyed, and the camera has been detatched. Just destroy the camera.
        const camStillAttached = self.fpCamera.isAttached();

        if (camStillAttached)
            self.fpCameraNode.detachCamera(self.fpCamera);

        self.renderScene.destroyCamera(self.fpCamera);

        if (camStillAttached)
            self.renderScene.destroySceneNode(self.fpCameraNode);

        self.fpCamera = .Null;
        self.fpCameraNode = .Null;

        self.active = false;
    }

    fn onMessageReceived(self: *Self, message: Message, senderNameHash: basis.string.StringHash, parameters: MessageParametersPtr) void {
        _ = senderNameHash;

        const client = self.context.getClient();

        switch (message) {
            basis.engine_messages.MESSAGE_GAME_ENDED, basis.engine_messages.MESSAGE_BAIL_OUT_TO_SHUTDOWN => {
                if (self.active) {
                    self.deactivate(true);
                }
            },
            basis.engine_messages.MESSAGE_SET_ACTIVE_AVATAR => {
                const avatarObjectNameHash = parameters.getUint();
                const hostID = parameters.getInt();

                if (hostID == client.getHostID()) {
                    if (self.active) {
                        self.deactivate(false);
                    }

                    const gameState = client.getGameState();
                    const avatarGO = gameState.getGameObjectByNameHash(avatarObjectNameHash);

                    if (avatarGO) |go| {
                        self.avatarGO = go;

                        if (getAttachmentPosition(go)) |pos| {
                            self.activate(pos);
                        }
                    }
                }
            },
            basis.engine_messages.MESSAGE_CLEAR_ACTIVE_AVATAR => {
                const hostID = parameters.getInt();

                if (hostID == client.getHostID()) {
                    if (self.active) {
                        self.deactivate(false);
                    }
                }
            },
            else => {},
        }
    }

    fn getAttachmentPosition(go: GameObjectPtr) ?Vec3 {
        const typeName = go.getType();

        if (basis.string.eql(typeName, "Vehicles/Scout") or basis.string.eql(typeName, "Vehicles/FlyingScout")) {
            return Vec3.init(0, 0.73, 0.9);
        } else if (basis.string.eql(typeName, "Vehicles/Mother")) {
            return Vec3.init(0, 5.5, 15.0);
        } else if (basis.string.eql(typeName, "Vehicles/GripperTruck")) {
            return Vec3.init(0, 2.1, 3.6);
        } else {
            return null;
        }
    }
};
