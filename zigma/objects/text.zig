const std = @import("std");
const base = @import("base.zig");
const rl = @cImport(@cInclude("raylib.h"));

pub const Text2D = struct {
  allocator: std.mem.Allocator,
  text: []u8,

  pub fn init(allocator: std.mem.Allocator) *Text2D {
    const object = allocator.create(Text2D) catch unreachable;
    object.allocator = allocator;

    const buffer = allocator.alloc(u8, 1) catch unreachable;
    buffer[0] = 0; //empty 0 terminated string
    object.text = buffer;

    return object;
  }

  pub fn deinit(obj: *const base.Object) void {
    const self: *const Text2D = @ptrCast(@alignCast(obj.custom));
    self.allocator.free(self.text);
    self.allocator.destroy(self);
  }

  pub fn setText(self: *Text2D, text: []const u8) *Text2D {
    self.allocator.free(self.text);

    const buffer = self.allocator.alloc(u8, text.len+1) catch unreachable;
    std.mem.copyForwards(u8, buffer[0..text.len], text);
    buffer[text.len] = 0; //DrawText needs 0 terminated string

    self.text = buffer;
    return self;
  }

  pub fn render(obj: *const base.Object) void {
    const self: *const Text2D = @ptrCast(@alignCast(obj.custom));

    rl.DrawText(self.text.ptr, @intFromFloat(obj.position.x), @intFromFloat( obj.position.y), 10,
      rl.Color{
        .r = obj.colors[0].r,
        .g = obj.colors[0].g,
        .b = obj.colors[0].b,
        .a = obj.colors[0].a,
      });
  }
};
