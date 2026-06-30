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

const AppContext = basis.app.AppContext;

pub const GameMessageCategory = enum(i32) {
    UI = basis.messaging.FirstGameMessageCategory,
    HUD,
    PlayerControl,
    GameLogic,
    MeansGameFlow,
    ObjectGripping,
};

pub const GameMessage = enum(i32) {
    // UI messages (category: UI).
    UIMainMenuStartSingleplayer = basis.messaging.FirstGameMessage,
    UIMainMenuStartCampaignGame,
    UIMainMenuStartSandboxGame,
    UIMainMenuStartMultiplayer,
    UIMainMenuExit,
    UIBack,
    UIPauseMenuEntered,
    UIPauseMenuResumeGame,
    UIPauseMenuExitGame,
    UIGameOverMenuExitGame,
    UISkipCinematic,

    // HUD messages (category: HUD)
    InitVehicleHud,
    UpdateDriveGauge,
    InitAvatarRoleScreen,
    ShowInteractionPrompt,
    HideInteractionPrompt,
    InitRadioMenuContacts,
    PlayBark,
    UpdateHandbrakeIndicator,
    ShowRadioMarker,
    HideRadioMarker,
    UpdateHUDInputPrompts,
    ConversationShowVoiceLine,
    ConversationShowTGLine,
    ConversationShowChoices,
    ConversationHide,
    ConversationChoiceInput,

    // Player control messages (category: PlayerControl). These are sent by the client
    // and server player controllers to have the player GOs react to input etc. On the server these
    // are used for the avatars of all players. On the client they are used for the local avatar only,
    // and the non-avatar player GOs are updated through PVs.
    PlayerResetVehicle,

    // Game logic messages (category: GameLogic):
    SetVehicleCameraParameters,
    SetVehicleCameraHaulingMode,
    SetCameraModeFreeCamera,
    SetCameraModeVehicle,
    SetFreeCameraTransform,
    DrivingCameraEnabled,
    OrbitCameraEnabled,
    AimingUpdated,
    PlayCameraAnimationFromLevelDataBlock,
    StopCameraAnimation,
    BlendCameraAnimationToVehicle,
    PlayFullscreenAnimation,
    StopFullscreenAnimation,
    EnterConversationCamera,
    ExitConversationCamera,
    ConversationChoiceSelected,

    // Means-specific game flow messages (category: MeansGameFlow)
    EndGameAndTravel,
    EndGameAndReloadSaveGame,

    // Object messages (category: ObjectGripping)
    ObjectGripped,
    DynamicObjectInserted,

    pub fn asInt(self: GameMessage) i32 {
        return @intFromEnum(self);
    }
};

//----------------------------------------------------

pub fn register(context: *AppContext) void {
    // UI
    context.registerMessage(GameMessage.UIMainMenuStartSingleplayer, GameMessageCategory.UI);
    context.registerMessage(GameMessage.UIMainMenuStartCampaignGame, GameMessageCategory.UI);
    context.registerMessage(GameMessage.UIMainMenuStartSandboxGame, GameMessageCategory.UI);
    context.registerMessage(GameMessage.UIMainMenuStartMultiplayer, GameMessageCategory.UI);
    context.registerMessage(GameMessage.UIMainMenuExit, GameMessageCategory.UI);
    context.registerMessage(GameMessage.UIBack, GameMessageCategory.UI);
    context.registerMessage(GameMessage.UIPauseMenuEntered, GameMessageCategory.UI);
    context.registerMessage(GameMessage.UIPauseMenuResumeGame, GameMessageCategory.UI);
    context.registerMessage(GameMessage.UIPauseMenuExitGame, GameMessageCategory.UI);
    context.registerMessage(GameMessage.UIGameOverMenuExitGame, GameMessageCategory.UI);
    context.registerMessage(GameMessage.UISkipCinematic, GameMessageCategory.UI);

    // HUD
    context.registerMessage(GameMessage.InitVehicleHud, GameMessageCategory.HUD);
    context.registerMessage(GameMessage.UpdateDriveGauge, GameMessageCategory.HUD);
    context.registerMessage(GameMessage.InitAvatarRoleScreen, GameMessageCategory.HUD);
    context.registerMessage(GameMessage.ShowInteractionPrompt, GameMessageCategory.HUD);
    context.registerMessage(GameMessage.HideInteractionPrompt, GameMessageCategory.HUD);
    context.registerMessage(GameMessage.InitRadioMenuContacts, GameMessageCategory.HUD);
    context.registerMessage(GameMessage.PlayBark, GameMessageCategory.HUD);
    context.registerMessage(GameMessage.UpdateHandbrakeIndicator, GameMessageCategory.HUD);
    context.registerMessage(GameMessage.ShowRadioMarker, GameMessageCategory.HUD);
    context.registerMessage(GameMessage.HideRadioMarker, GameMessageCategory.HUD);
    context.registerMessage(GameMessage.UpdateHUDInputPrompts, GameMessageCategory.HUD);
    context.registerMessage(GameMessage.ConversationShowVoiceLine, GameMessageCategory.HUD);
    context.registerMessage(GameMessage.ConversationShowTGLine, GameMessageCategory.HUD);
    context.registerMessage(GameMessage.ConversationShowChoices, GameMessageCategory.HUD);
    context.registerMessage(GameMessage.ConversationHide, GameMessageCategory.HUD);
    context.registerMessage(GameMessage.ConversationChoiceInput, GameMessageCategory.HUD);

    // PlayerControl
    context.registerMessage(GameMessage.PlayerResetVehicle, GameMessageCategory.PlayerControl);

    // GameLogic
    context.registerMessage(GameMessage.SetVehicleCameraParameters, GameMessageCategory.GameLogic);
    context.registerMessage(GameMessage.SetVehicleCameraHaulingMode, GameMessageCategory.GameLogic);
    context.registerMessage(GameMessage.SetCameraModeFreeCamera, GameMessageCategory.GameLogic);
    context.registerMessage(GameMessage.SetCameraModeVehicle, GameMessageCategory.GameLogic);
    context.registerMessage(GameMessage.SetFreeCameraTransform, GameMessageCategory.GameLogic);
    context.registerMessage(GameMessage.DrivingCameraEnabled, GameMessageCategory.GameLogic);
    context.registerMessage(GameMessage.OrbitCameraEnabled, GameMessageCategory.GameLogic);
    context.registerMessage(GameMessage.AimingUpdated, GameMessageCategory.GameLogic);
    context.registerMessage(GameMessage.PlayCameraAnimationFromLevelDataBlock, GameMessageCategory.GameLogic);
    context.registerMessage(GameMessage.StopCameraAnimation, GameMessageCategory.GameLogic);
    context.registerMessage(GameMessage.BlendCameraAnimationToVehicle, GameMessageCategory.GameLogic);
    context.registerMessage(GameMessage.PlayFullscreenAnimation, GameMessageCategory.GameLogic);
    context.registerMessage(GameMessage.StopFullscreenAnimation, GameMessageCategory.GameLogic);
    context.registerMessage(GameMessage.EnterConversationCamera, GameMessageCategory.GameLogic);
    context.registerMessage(GameMessage.ExitConversationCamera, GameMessageCategory.GameLogic);
    context.registerMessage(GameMessage.ConversationChoiceSelected, GameMessageCategory.GameLogic);

    // MeansGameFlow
    context.registerMessage(GameMessage.EndGameAndTravel, GameMessageCategory.MeansGameFlow);
    context.registerMessage(GameMessage.EndGameAndReloadSaveGame, GameMessageCategory.MeansGameFlow);

    // ObjectGripping
    context.registerMessage(GameMessage.ObjectGripped, GameMessageCategory.ObjectGripping);
    context.registerMessage(GameMessage.DynamicObjectInserted, GameMessageCategory.ObjectGripping);
}
