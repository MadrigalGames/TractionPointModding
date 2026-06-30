const std = @import("std");
const basis = @import("basis");
const nemo = @import("nemo");

//----------------------------------------------------

pub const LibraryGlobalData = struct {
    // In order for the allocator to survive a code hot-reload, we need to make
    // sure the VTable for the allocator stays in one place, ie. in the _allocatorVTable
    // field below. You should never use it directly, but rather use the allocator field
    // which points to the nailed-down _allocatorVTable.
    _allocatorVTable: std.mem.Allocator.VTable,

    // Global allocator and IO interface. Only use these for global-data purposes!
    // If it is possible to pass an allocator/io to a function, prefer that.
    allocator: std.mem.Allocator,

    io: std.Io,

    //----------------------------------------------------

    // TODO: Add mod-specific global data here.
};

pub fn create(comptime ModType: type, allocator: std.mem.Allocator, io: std.Io) void {
    ModType.g = allocator.create(LibraryGlobalData) catch @panic("OOM");
    ModType.g.* = LibraryGlobalData{
        // Assign, by value, the contents of the given allocator VTable to _allocatorVTable.
        ._allocatorVTable = allocator.vtable.*,
        // Initialize the allocator interface using the pointer of the given
        // allocator, and the VTable pointer with address of the VTable found
        // in the global data (and is thus guaranteed to stay in place.)
        .allocator = std.mem.Allocator{
            .ptr = allocator.ptr,
            .vtable = &ModType.g._allocatorVTable,
        },
        .io = io,
    };
}

pub fn destroy(comptime ModType: type) void {
    ModType.g.allocator.destroy(ModType.g);
}
