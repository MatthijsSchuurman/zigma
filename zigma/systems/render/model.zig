const std = @import("std");
const ecs = @import("../../ecs.zig");
const rl = @cImport(@cInclude("raylib.h"));

pub const System = struct {
  world: *ecs.World,

  pub fn init(world: *ecs.World) System {
    const self = System{
      .world = world,
    };

    return self;
  }

  pub fn render(self: *System) void {
    var it = self.world.components.model.iterator();

    while(it.next()) |model| {
      rl.DrawModelEx(
        model.value_ptr.*.model,
        rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }, // position
        rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }, // rotation axis
        0.0, // rotation angle
        rl.Vector3{ .x = 1.0, .y = 1.0, .z = 1.0 }, // scale
        rl.Color{ .r = 255, .g = 255, .b = 255, .a = 255 }); // color
    }
  }
};


// Testing
const tst = std.testing;

test "System should render model" {
  // Given
  rl.InitWindow(320, 200, "test");
  defer rl.CloseWindow();

  var world = ecs.World.init(tst.allocator);
  world.initSystems();
  defer world.deinit();

  var system = System.init(&world);

  _ = world.entity("camera").camera_init();
  _ = world.entity("test").model("cube");

  // When
  rl.BeginDrawing();
  world.systems.camera.setup();
  system.render();
  rl.EndDrawing();

  // Then
  try ecs.expectScreenshot("system.render.model");
}
