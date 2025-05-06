const rl = @cImport(@cInclude("raylib.h"));
const ecs = @import("../../ecs.zig");

pub const System = struct {
  world: *ecs.World,

  pub fn init(world: *ecs.World) System {
    return System{
      .world = world,
    };
  }

  pub fn update(self: *System) void {
    var it = self.world.components.text.iterator();
    const screen_width: f32 = @floatFromInt(rl.GetScreenWidth());
    const screen_height: f32 = @floatFromInt(rl.GetScreenHeight());

    while (it.next()) |entry| {
      const id = entry.key_ptr.*;
      const text = entry.value_ptr.*;

      const position = self.world.components.position.get(id) orelse ecs.Components.Position.Component{.x = 0, .y = 0, .z = 0};
      const size = self.world.components.size.get(id) orelse ecs.Components.Size.Component{.x = 2, .y = 1, .z = 1};
      const color = self.world.components.color.get(id) orelse ecs.Components.Color.Component{.r = 255, .g = 255, .b = 255, .a = 255};

      const height: f32 = 10 * size.x;
      const width: f32 = @floatFromInt(rl.MeasureText(@ptrCast(text.text), @intFromFloat(height)));

      const x = (position.x * 0.5 + 0.5) * screen_width;
      const y = (position.y * 0.5 + 0.5) * screen_height;

      rl.DrawText(
        @ptrCast(text.text),
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
};
