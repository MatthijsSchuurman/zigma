const raylib = @cImport(@cInclude("raylib.h"));
const base = @import("base.zig");

pub const Text2D = struct {
  text: [*c]const u8,

  pub fn render(obj: *const base.Object) void {
    const self: *const Text2D = @ptrCast(@alignCast(obj.custom));

    raylib.DrawText(self.text, @intFromFloat(obj.position.x), @intFromFloat( obj.position.y), 10,
      raylib.Color{
        .r = obj.colors[0].r,
        .g = obj.colors[0].g,
        .b = obj.colors[0].b,
        .a = obj.colors[0].a,
      });
  }
};
