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

const basis = @import("basis");
const ghl = @import("ghl");

const AppContext = basis.app.AppContext;

const InputType = basis.input.InputType;

const GamepadButton = basis.input.GamepadButton;
const InputSource = basis.input.InputSource;
const KeyCode = basis.input.KeyCode;
const InputMappingFlags = basis.input.InputMappingFlags;
const MouseButtonID = basis.input.MouseButtonID;

pub const HeldButtonTimeThreshold = 0.3; // In seconds.

pub const InputContextID = enum(u8) {
    GeneralInGameControls = basis.input.FirstInputContextID, // 32 (eg. Pause menu toggle)
    DebugInGameControls, // 33
    FreeCameraControls, // 34

    VehicleCameraControls, // 35

    // Interaction areas, switching vehicles, etc...
    WorldInteractionControls, // 36

    ToggleInGameMenuControls, // 37, Toggling in-game menus on/off
    InGameMenuControls, // 38, Interacting with in-game menus when they are active.

    VehicleDrivingControls, // 39
    CharacterControls, // 40

    GripperArmControls, // 41
    CargoCraneControls, // 42
    GravityCraneControls, // 43
    TruckBedControls, // 44

    // Note! GHL adds some contexts starting with basis.input.FirstInputContextID + 100
};

pub const InputID = enum(u16) {
    TogglePauseGame = basis.input.FirstGameInputID,

    ToggleDebugPause,

    FreeCameraYaw,
    FreeCameraPitch,
    FreeCameraElevation,
    FreeCameraForwardBackward,
    FreeCameraStrafe,
    FreeCameraSprint,
    FreeCameraSlow,
    FreeCameraSpeedMultiplier,

    // Driving.
    VehicleAcceleration,
    VehicleBrake,
    VehicleSteering,
    VehicleHandbrake,
    //VehicleReset,
    VehicleGetUnstuck,
    VehicleModState, // Can be used by mods for a "state", (ie. held-down) input.

    // Interaction.
    VehicleInteractPrimary, // Interaction areas
    VehicleInteractSecondary, // Vehicle switching

    // The QuickAction input can be read in multiple input contexts and triggers
    // a vehicle/context specific action, eg. pick up cargo with the gripper truck.
    QuickAction,

    // Vehicle camera.
    VehicleOrbitCameraH,
    VehicleOrbitCameraV,
    ToggleVehicleCameraMode,
    ToggleOrbitCameraSide,

    // Toggle in-game menus
    ShowAvatarRoleScreen,
    ShowRadioMenu,

    // In-game menus
    InGameMenuUp,
    InGameMenuDown,
    InGameMenuSelect,
    InGameMenuBack,

    // Cruise control.
    ToggleCC,
    IncreaseCCTargetSpeed,
    DecreaseCCTargetSpeed,

    // Crane.
    CraneForwardBackward,
    CraneLeftRight,
    CraneUpDown,
    CraneToggleActive,
    CraneExtendCable,
    CraneRetractCable,
    CraneResetPose,

    // Gripper arm.
    GripperArmVertRotateForward,
    GripperArmVertRotateBackward,
    GripperArmHorizMoveForward,
    GripperArmHorizMoveBackward,
    GripperArmOpenFingers,
    GripperArmCloseFingers,
    GripperArmResetPose,

    // Truck bed.
    TruckBedRaise,
    TruckBedLower,
    TruckBedOpenHatches,
    TruckBedCloseHatches,
    TruckBedResetPose,

    // FireWeapon,
    // SwitchWeapon,
    // ForwardBackwardMovement,
    // LeftRightMovement,
    // AimHorizontal,
    // AimVertical,
};

pub fn addInputs(appContext: *AppContext) void {
    ghl.input.addInputs(appContext);

    appContext.addInput(InputID.TogglePauseGame, .Action);

    appContext.addInput(InputID.ToggleDebugPause, .Action);

    appContext.addInput(InputID.FreeCameraYaw, .Range);
    appContext.addInput(InputID.FreeCameraPitch, .Range);
    appContext.addInput(InputID.FreeCameraElevation, .Range);
    appContext.addInput(InputID.FreeCameraForwardBackward, .Range);
    appContext.addInput(InputID.FreeCameraStrafe, .Range);
    appContext.addInput(InputID.FreeCameraSprint, .State);
    appContext.addInput(InputID.FreeCameraSlow, .State);
    appContext.addInput(InputID.FreeCameraSpeedMultiplier, .Range);

    appContext.addInput(InputID.VehicleAcceleration, .Range);
    appContext.addInput(InputID.VehicleBrake, .Range);
    appContext.addInput(InputID.VehicleSteering, .Range);
    appContext.addInput(InputID.VehicleHandbrake, .Range);
    //appContext.addInput(InputID.VehicleReset, .Action);
    appContext.addInput(InputID.VehicleGetUnstuck, .State);
    appContext.addInput(InputID.VehicleModState, .State);

    appContext.addInput(InputID.VehicleInteractPrimary, .Action);
    appContext.addInput(InputID.VehicleInteractSecondary, .Action);

    appContext.addInput(InputID.QuickAction, .State);

    appContext.addInput(InputID.VehicleOrbitCameraH, .Range);
    appContext.addInput(InputID.VehicleOrbitCameraV, .Range);
    appContext.addInput(InputID.ToggleVehicleCameraMode, .Action);
    appContext.addInput(InputID.ToggleOrbitCameraSide, .Action);

    appContext.addInput(InputID.ToggleCC, .Action);
    appContext.addInput(InputID.IncreaseCCTargetSpeed, .Action);
    appContext.addInput(InputID.DecreaseCCTargetSpeed, .Action);

    //appContext.addInput(InputID.ToggleTrailerConnection, .Action);

    appContext.addInput(InputID.ShowAvatarRoleScreen, .State);
    appContext.addInput(InputID.ShowRadioMenu, .Action);

    appContext.addInput(InputID.InGameMenuUp, .Action);
    appContext.addInput(InputID.InGameMenuDown, .Action);
    appContext.addInput(InputID.InGameMenuSelect, .Action);
    appContext.addInput(InputID.InGameMenuBack, .Action);

    appContext.addInput(InputID.CraneForwardBackward, .Range);
    appContext.addInput(InputID.CraneLeftRight, .Range);
    appContext.addInput(InputID.CraneUpDown, .Range);
    appContext.addInput(InputID.CraneToggleActive, .Action);
    appContext.addInput(InputID.CraneExtendCable, .State);
    appContext.addInput(InputID.CraneRetractCable, .State);
    appContext.addInput(InputID.CraneResetPose, .Action);

    appContext.addInput(InputID.GripperArmVertRotateForward, .Range);
    appContext.addInput(InputID.GripperArmVertRotateBackward, .Range);
    appContext.addInput(InputID.GripperArmHorizMoveForward, .State);
    appContext.addInput(InputID.GripperArmHorizMoveBackward, .State);
    appContext.addInput(InputID.GripperArmOpenFingers, .State);
    appContext.addInput(InputID.GripperArmCloseFingers, .State);
    appContext.addInput(InputID.GripperArmResetPose, .Action);

    appContext.addInput(InputID.TruckBedRaise, .Range);
    appContext.addInput(InputID.TruckBedLower, .Range);
    appContext.addInput(InputID.TruckBedOpenHatches, .State);
    appContext.addInput(InputID.TruckBedCloseHatches, .State);
    appContext.addInput(InputID.TruckBedResetPose, .Action);

    // appContext.addInput(InputID.FireWeapon, .State);
    // appContext.addInput(InputID.SwitchWeapon, .Action);
    // appContext.addInput(InputID.ForwardBackwardMovement, .Range);
    // appContext.addInput(InputID.LeftRightMovement, .Range);
    // appContext.addInput(InputID.AimHorizontal, .Range);
    // appContext.addInput(InputID.AimVertical, .Range);

    basis.printf("Input buffer size: {} bytes\n", .{appContext.getInputBufferSize()});
}
