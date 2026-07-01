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

// Group names:

pub const MenuUIGroupName = "ui_menu";
pub const LoadingScreenUIGroupName = "ui_loading";
pub const IngameUIGroupName = "ui_ingame";

// Goofy view names and script paths:

pub const MenuBackgroundViewName = "MenuBackground";
pub const MenuBackgroundViewScriptPath = "game/ui/scripts/menu_background_view.as";

pub const MainMenuViewName = "MainMenu";
pub const MainMenuViewScriptPath = "game/ui/scripts/main_menu_view.as";

pub const CampaignMenuViewName = "CampaignMenu";
pub const CampaignMenuViewScriptPath = "game/ui/scripts/campaign_menu_view.as";

pub const SandboxMenuViewName = "CampaignMenu";
pub const SandboxMenuViewScriptPath = "game/ui/scripts/sandbox_menu_view.as";

pub const OptionsMenuViewName = "OptionsMenu";
pub const OptionsMenuViewScriptPath = "game/ui/scripts/options_menu_view.as";

pub const GameOptionsMenuViewName = "GameOptionsMenu";
pub const GameOptionsMenuViewScriptPath = "game/ui/scripts/game_options_menu_view.as";

pub const DisplayOptionsMenuViewName = "DisplayOptionsMenu";
pub const DisplayOptionsMenuViewScriptPath = "game/ui/scripts/display_options_menu_view.as";

pub const GraphicsOptionsMenuViewName = "GraphicsOptionsMenu";
pub const GraphicsOptionsMenuViewScriptPath = "game/ui/scripts/graphics_options_menu_view.as";

pub const AudioOptionsMenuViewName = "AudioOptionsMenu";
pub const AudioOptionsMenuViewScriptPath = "game/ui/scripts/audio_options_menu_view.as";

pub const ControlOptionsMenuViewName = "ControlOptionsMenu";
pub const ControlOptionsMenuViewScriptPath = "game/ui/scripts/control_options_menu_view.as";

pub const KeyBindingsMenuViewName = "KeyBindingsMenu";
pub const KeyBindingsMenuViewScriptPath = "game/ui/scripts/key_bindings_menu_view.as";

pub const GamepadLayoutMenuViewName = "GamepadLayoutMenu";
pub const GamepadLayoutMenuViewScriptPath = "game/ui/scripts/gamepad_layout_menu_view.as";

pub const LoadingScreenViewName = "LoadingScreen";
pub const LoadingScreenViewScriptPath = "game/ui/scripts/loading_screen_view.as";

pub const PauseMenuViewName = "PauseMenu";
pub const PauseMenuViewScriptPath = "game/ui/scripts/pause_menu_view.as";

pub const HUDViewName = "HUD";
pub const HUDViewScriptPath = "game/ui/scripts/hud_view.as";

pub const GameOverMenuViewName = "GameOverMenu";
pub const GameOverMenuViewScriptPath = "game/ui/scripts/game_over_menu_view.as";

// Dialog view script paths (see dialog_cache.zig):

pub const ButtonlessDialogScriptPath = "game/ui/scripts/dialog/buttonless.as";
pub const OneButtonDialogScriptPath = "game/ui/scripts/dialog/one_button.as";
pub const TwoButtonDialogScriptPath = "game/ui/scripts/dialog/two_buttons.as";
pub const TwoButtonDialogWithTimeoutScriptPath = "game/ui/scripts/dialog/two_buttons_with_timeout.as";

// Goofy actions:

pub const Actions = struct {
    pub const MainMenuCampaign = "MainMenu/Campaign";
    pub const MainMenuSandbox = "MainMenu/Sandbox";
    pub const MainMenuStartMultiplayer = "MainMenu/StartMultiplayer";
    pub const MainMenuOptions = "MainMenu/Options";
    pub const MainMenuExitGame = "MainMenu/ExitGame";

    pub const PauseMenuResumeGame = "PauseMenu/ResumeGame";
    pub const PauseMenuLoadGame = "PauseMenu/LoadGame";
    pub const PauseMenuExitGame = "PauseMenu/ExitGame";

    pub const GameOverMenuLoadGame = "GameOverMenu/LoadGame";
    pub const GameOverMenuExitGame = "GameOverMenu/ExitGame";
};

// Goofy properties.

pub const Properties = struct {
    pub const HUDAvatarRoleSelectionScreenVisible = "HUD/AvatarRoleSelectionScreenVisible";
    pub const HUDAvatarRoleSelectionScreenIndex = "HUD/AvatarRoleSelectionScreenIndex";

    pub const HUDCommRadioMenuVisible = "HUD/RadioMenuVisible";
    pub const HUDCommRadioMenuState = "HUD/CommRadioMenuState";
    pub const HUDRadioMenuSelectedIndex = "HUD/HUDRadioMenuSelectedIndex";
    pub const HUDRadioMenuSelectedContactIndex = "HUD/HUDRadioMenuSelectedContactIndex";

    pub const MinigameHUDTimeLabelVisible = "HUD/TimeLabelVisible";
    pub const MinigameHUDTimeLabelText = "HUD/TimeLabelText";
    pub const MinigameHUDGoLabelVisible = "HUD/GoLabelVisible";
    pub const MinigameHUDFinishedLabelVisible = "HUD/FinishedLabelVisible";

    pub const HUDUnstuckifierVisible = "HUD/UnstuckifierVisible";
    pub const HUDUnstuckifierState = "HUD/UnstuckifierState";
    pub const HUDUnstuckifierProgress = "HUD/UnstuckifierProgress";

    pub const InGameCampaignActive = "InGame/CampaignActive";

    pub const InGameConversationActive = "InGame/ConversationActive";

    pub const Positions = struct {
        pub const CampaignMenuHeaderPart1 = "UIPos/CampaignMenuHeaderPart1";
        pub const CampaignMenuHeaderPart2 = "UIPos/CampaignMenuHeaderPart2";

        pub const OptionsMenuHeader = "UIPos/OptionsMenuHeader";

        pub const SandboxMenuHeader = "UIPos/SandboxMenuHeader";

        pub const GameOptionsMenuHeaderPart1 = "UIPos/GameOptionsMenuHeaderPart1";
        pub const GameOptionsMenuHeaderPart2 = "UIPos/GameOptionsMenuHeaderPart2";

        pub const DisplayOptionsMenuHeaderPart1 = "UIPos/DisplayOptionsMenuHeaderPart1";
        pub const DisplayOptionsMenuHeaderPart2 = "UIPos/DisplayOptionsMenuHeaderPart2";

        pub const GraphicsOptionsMenuHeaderPart1 = "UIPos/GraphicsOptionsMenuHeaderPart1";
        pub const GraphicsOptionsMenuHeaderPart2 = "UIPos/GraphicsOptionsMenuHeaderPart2";

        pub const AudioOptionsMenuHeaderPart1 = "UIPos/AudioOptionsMenuHeaderPart1";
        pub const AudioOptionsMenuHeaderPart2 = "UIPos/AudioOptionsMenuHeaderPart2";

        pub const ControlOptionsMenuHeaderPart1 = "UIPos/ControlOptionsMenuHeaderPart1";
        pub const ControlOptionsMenuHeaderPart2 = "UIPos/ControlOptionsMenuHeaderPart2";

        pub const KeyBindingsMenuHeaderPart1 = "UIPos/KeyBindingsMenuHeaderPart1";
        pub const KeyBindingsMenuHeaderPart2 = "UIPos/KeyBindingsMenuHeaderPart2";

        pub const GamepadLayoutMenuHeaderPart1 = "UIPos/GamepadLayoutMenuHeaderPart1";
        pub const GamepadLayoutMenuHeaderPart2 = "UIPos/GamepadLayoutMenuHeaderPart2";

        pub const PauseMenuHeader = "UIPos/PauseMenuHeader";
    };
};

// Goofy fonts:

pub const UIFontStandardName = "standard";
pub const UIFontStandardFilePath = "game/ui/fonts/xolonium-bold-tp.ttf";

pub const UIFontLogoName = "logo";
pub const UIFontLogoFilePath = "game/ui/fonts/daggersquare_tp.ttf";

// Animation resource file paths:

pub const UIAnimationLoading = "game/ui/animations/loading_animation_constant.binsvganim";
pub const UIHUDRadioPingAnimationPath = "game/ui/animations/radio_ping.binsvganim";
pub const UIHUDRadioMsgAckAnimationPath = "game/ui/animations/radio_msg_ack.binsvganim";

// Skins:

pub const UIMenuSkin = "menu";

// Colors:

pub const UIColorHUDTurqoise = basis.Color.initRGBA(132, 198, 203, 255);
pub const UIColorHUDWhite = basis.Color.initRGBA(255, 255, 255, 180);

// Conversation interaction:

// Localization key name for the "start conversation" interaction prompt. Resolved to a
// LocalizationKey at runtime via means.localization.getLocalizationKeyByName.
pub const ConversationInteractionPromptLocKey = "TEXT_UI_TALK_PROMPT";

// HUD interaction-marker icons. Stage 1 is the far "you can interact here" discovery
// icon, stage 2 is shown on the selected target.
pub const ConversationMarkerStage1IconPath = "game/ui/hud/speech_bubble_icon.binsvg";
pub const ConversationMarkerStage2IconPath = "game/ui/hud/speech_bubble_icon.binsvg";
pub const SwitchVehicleMarkerIconPath = "game/ui/hud/switch_vehicle_marker.binsvg";

// Enums:

pub const CommRadioMenuState = enum(i8) {
    SelectContact = 0,
    SelectMessage,

    pub fn asInt(self: CommRadioMenuState) i8 {
        return @intFromEnum(self);
    }
};

pub const HudRadioMarkerType = enum(i32) {
    CallPing = 0,
    MsgAck,

    pub fn asInt(self: HudRadioMarkerType) i32 {
        return @intFromEnum(self);
    }
};
