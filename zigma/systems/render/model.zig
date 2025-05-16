const std = @import("std");
const ecs = @import("../../ecs.zig");
const rl = @cImport(@cInclude("raylib.h"));

pub const System = struct {
  world: *ecs.World,
  model_cache: std.AutoHashMap(ecs.EntityID, rl.Model),

  pub fn init(world: *ecs.World) System {
    var self = System{
      .world = world,
      .model_cache = undefined,
    };

    self.model_cache = std.AutoHashMap(ecs.EntityID, rl.Model).init(world.allocator);
    return self;
  }

  pub fn deinit(self: *System) void {
    var it = self.model_cache.iterator();

    while (it.next()) |entry|
      rl.UnloadModel(entry.value_ptr.*);

    self.model_cache.deinit();
  }

  pub fn update(self: *System) void {
    var it = self.world.components.mesh.iterator();

    while(it.next()) |mesh| {
      if (self.model_cache.get(mesh.key_ptr.*)) |_| continue; // Already cached

      const model = rl.LoadModelFromMesh(mesh.value_ptr.*.mesh);
      self.model_cache.put(mesh.key_ptr.*, model) catch @panic("Failed to store model cache");
    }
  }

  pub fn render(self: *System) void {
    var it = self.model_cache.iterator();

    while(it.next()) |model| {
      rl.DrawModelEx(
        model.value_ptr.*,
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

test "System should update model cache" {
  // Given
  rl.InitWindow(320, 200, "test");
  defer rl.CloseWindow();

  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  var system = System.init(&world);
  defer system.deinit();

  _ = world.entity("test").mesh("cube");

  // When
  system.update();

  // Then
  try tst.expectEqual(1, system.model_cache.count());
}
