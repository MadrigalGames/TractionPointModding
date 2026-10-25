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

module flyingscout;
import basis;
import basis::memory;
import meanslib;
import flyingscout::mod_controller;
import flyingscout::components;

HeapAllocator heapAllocator @feat(!WASM);

fn uint getVersionNumber(uint versionNumberType) @export("getVersionNumber")
{
	return (versionNumberType == 0) ? basis::API_VERSION_NUMBER : meanslib::API_VERSION_NUMBER;
}

fn void initLibrary(ComponentRegCallback callback) @export("initLibrary")
{
	// Note! Only pass the mod allocator to flyingscout::global_data. Use flyingscout::g.allocator
	// for the rest. flyingscout::global_data contains the master allocator interface to use.
	$if env::WASM:
		flyingscout::global_data::create(mem);
	$else
		flyingscout::global_data::create(&heapAllocator);
	$endif
	basis::global_data::create(flyingscout::g.allocator);

	flyingscout::modController = basis::mod_controller::create{FlyingScoutModController}(flyingscout::g.allocator);

	flyingscout::components::initComponentTypes(callback);
}

fn void deinitLibrary() @export("deinitLibrary")
{
	basis::mod_controller::destroy{FlyingScoutModController}(flyingscout::modController);
	basis::components::deinitComponentTypes();

	basis::global_data::destroy();
	flyingscout::global_data::destroy();
}
