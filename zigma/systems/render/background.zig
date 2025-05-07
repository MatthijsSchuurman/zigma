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
    const background_entity = self.world.entity("background");
    if (self.world.components.color.get(background_entity.id)) |color| {
      if (color.a == 0) { // No wipe
      } else if (color.a == 255) { // Full wipe
        rl.ClearBackground(rl.Color{.r = color.r, .g = color.g, .b = color.b, .a = color.a});
      } else { // Fade wipe
        rl.DrawRectangle(0, 0, rl.GetScreenWidth(), rl.GetScreenHeight(), rl.Color{.r = color.r, .g = color.g, .b = color.b, .a = color.a});
      }
    }
  }
};
