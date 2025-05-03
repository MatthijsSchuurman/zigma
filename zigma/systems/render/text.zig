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

const rl = @cImport(@cInclude("raylib.h"));
const ecs = @import("../../ecs.zig");

pub fn run(world: *ecs.World) void {
  var it = world.components.text.iterator();
  const screen_width: f32 = @floatFromInt(rl.GetScreenWidth());
  const screen_height: f32 = @floatFromInt(rl.GetScreenHeight());

  while (it.next()) |entry| {
    const id = entry.key_ptr.*;
    const text = entry.value_ptr.*;

    const position = world.components.position.get(id) orelse ecs.Components.Position.Data{.x = 0, .y = 0, .z = 0};
    const scale = world.components.scale.get(id) orelse ecs.Components.Scale.Data{.x = 2, .y = 1, .z = 1};
    const color = world.components.color.get(id) orelse ecs.Components.Color.Data{.r = 255, .g = 255, .b = 255, .a = 255};

    const height: f32 = 10 * scale.x;
    const width: f32 = @floatFromInt(rl.MeasureText(@ptrCast(text), @intFromFloat(height)));

    const x = (position.x * 0.5 + 0.5) * screen_width;
    const y = (position.y * 0.5 + 0.5) * screen_height;

    rl.DrawText(
      @ptrCast(text),
      @intFromFloat(x - (width / 2)),
      @intFromFloat(y - (height / 2)),
      @intFromFloat(height),
      rl.Color{
        .r = color.r,
        .g = color.g,
        .b = color.b,
        .a = color.a,
      }
    );
  }
}
