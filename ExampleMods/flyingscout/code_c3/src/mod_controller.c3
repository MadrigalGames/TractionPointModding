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

module flyingscout::mod_controller;
import basis;
import basis::app;
import basis::debug_overlay;
import basis::mod_controller;
import basis::mod_controller_interface;
import trampoline::byprod_utils;

struct FlyingScoutModController
{
	ModControllerInterface iface;
	ModControllerContext context;
}

fn void FlyingScoutModController.onAppStartup(&self)
{
	LibraryType libType = basis::getZigLibraryType();

	if (libType == LibraryType.NATIVE_DYNAMIC_LIBRARY || libType == LibraryType.WASM_CLIENT)
	{
		if (self.context.getAppMode() == AppMode.GAME)
		{
			basis::debug_overlay::addDebugSpawnableObjectType("Vehicles/FlyingScout", 2.0);
		}

		SoundBankData[1] soundBanks = {
			{ .soundBankName = "main", .soundBankResourcePath = "flyingscout_res/main.bybank" },
		};

		trampoline::byprod_utils::loadAdditiveProject("flyingscout_res/flyingscout.byprod", soundBanks[..]);
	}
}
