const rl = @cImport(@cInclude("raylib.h"));
const ecs = @import("../../ecs.zig");

pub fn run(world: *ecs.World) void {
  var it = world.components.text.iterator();
  const screen_width: f32 = @floatFromInt(rl.GetScreenWidth());
  const screen_height: f32 = @floatFromInt(rl.GetScreenHeight());

  while (it.next()) |entry| {
    const id = entry.key_ptr.*;
    const text = entry.value_ptr.*;

    const position = world.components.position.get(id) orelse &ecs.Components.Position.Data{.x = 0, .y = 0, .z = 0};
    const size = world.components.size.get(id) orelse &ecs.Components.Size.Data{.x = 2, .y = 1, .z = 1};
    const color = world.components.color.get(id) orelse &ecs.Components.Color.Data{.r = 255, .g = 255, .b = 255, .a = 255};

    const height: f32 = 10 * size.x;
    const width: f32 = @floatFromInt(rl.MeasureText(@ptrCast(text.*), @intFromFloat(height)));

    const x = (position.x * 0.5 + 0.5) * screen_width;
    const y = (position.y * 0.5 + 0.5) * screen_height;

    rl.DrawText(
      @ptrCast(text.*),
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
