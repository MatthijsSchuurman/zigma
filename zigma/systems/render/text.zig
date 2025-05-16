const std = @import("std");
const ecs = @import("../../ecs.zig");
const rl = ecs.raylib;

pub const System = struct {
  world: *ecs.World,

  pub fn init(world: *ecs.World) System {
    return System{
      .world = world,
    };
  }

  pub fn render(self: *System) void {
    const font = rl. GetFontDefault();
    const font_spacing: f32 = 5.0;

    var it = self.world.components.text.iterator();
    const screen_width: f32 = @floatFromInt(rl.GetScreenWidth());
    const screen_height: f32 = @floatFromInt(rl.GetScreenHeight());

    while (it.next()) |entry| {
      const id = entry.key_ptr.*;
      const text = entry.value_ptr.*;

      const position = self.world.components.position.get(id) orelse unreachable; // Defined in text component
      const rotation = self.world.components.rotation.get(id) orelse unreachable;
      const scale = self.world.components.scale.get(id) orelse unreachable;
      const color = self.world.components.color.get(id) orelse unreachable;

      const font_height: f32 = 10 * scale.x;
      const width: f32 = rl.MeasureTextEx(font, @ptrCast(text.text), font_height, font_spacing).x;

      const x = (position.x * 0.5 + 0.5) * screen_width;
      const y = (position.y * 0.5 + 0.5) * screen_height;

      rl.DrawTextPro(
        font,
        @ptrCast(text.text),

        rl.Vector2{.x = x, .y = y}, // Position
        rl.Vector2{.x = (width / 2), .y = (font_height / 2)}, // Pivot point in middle, affects position, scale & rotation
        360*rotation.z, // Rotation in round (not degrees)

        font_height,
        font_spacing,

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


// Testing
const tst = std.testing;

test "System should render text" {
  // Given
  rl.InitWindow(320, 200, "test");
  defer rl.CloseWindow();

  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  var system = System.init(&world);

  _ = world.entity("test").text("test").scale(10, 1, 1);

  // When
  rl.BeginDrawing();
  system.render();
  rl.EndDrawing();

  // Then
  try ecs.expectScreenshot("system.render.text");
}
