// const std = @import("std");
// const rl = @cImport(@cInclude("raylib.h"));
//
// const Object = @import("object.zig").Object;
//
// pub const Text2D = struct {
//   object: Object,
//   allocator: std.mem.Allocator,
//
//   text: []u8,
//
//   pub fn init(allocator: std.mem.Allocator) *Text2D {
//     const custom = allocator.create(Text2D) catch unreachable;
//     custom.allocator = allocator;
//
//     const buffer = allocator.alloc(u8, 1) catch unreachable;
//     buffer[0] = 0; //empty 0 terminated string
//     custom.text = buffer;
//
//     _ = custom.object.init(custom);
//     return custom;
//   }
//
//   pub fn deinit(object: *const Object) void {
//     const self: *const Text2D = @fieldParentPtr("object", object);
//
//     self.allocator.free(self.text);
//     self.allocator.destroy(self);
//   }
//
//   pub fn setText(self: *Text2D, text: []const u8) *Text2D {
//     self.allocator.free(self.text);
//
//     const buffer = self.allocator.alloc(u8, text.len+1) catch unreachable;
//     std.mem.copyForwards(u8, buffer[0..text.len], text);
//     buffer[text.len] = 0; //DrawText needs 0 terminated string
//
//     self.text = buffer;
//     return self;
//   }
//
//   pub fn render(object: *const Object) void {
//     const self: *const Text2D = @fieldParentPtr("object", object);
//
//     rl.DrawText(self.text.ptr, @intFromFloat(object.position.x), @intFromFloat(object.position.y), 10,
//       rl.Color{
//         .r = object.colors[0].r,
//         .g = object.colors[0].g,
//         .b = object.colors[0].b,
//         .a = object.colors[0].a,
//       });
//   }
// };
