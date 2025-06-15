const zigma = @import("zigma");
const std = @import("std");

pub fn main() void {
  zigma.init(.{.title = "Zigma test", .width = 1920, .height = 1080, .fps = 120});
  defer zigma.deinit();

  // Universe
  var universe = zigma.create();
  defer zigma.destroy(universe);

  _ = universe.entity("soundtrack").music(.{.path = "default/soundtrack.ogg"});
  _ = universe.entity("fps").fps();


  // Cube world
  var cube = zigma.create();
  defer zigma.destroy(cube);

  _ = cube.entity("camera").camera(.{})
  .event(.{.duration = 60, .repeat = 2, .pattern = .PingPong, .motion = .Smooth})
    .position(-5, 0.5, 2);

  _ = cube.entity("background")
  .color(25, 25, 25, 255);

  _ = cube.entity("floor").model(.{.type = "plane"})
  .color(64, 64, 64, 255)
  .scale(10, 0, 10)
  .position(0, -1, 0);

  _ = cube.entity("cube").model(.{.type = "cube"})
  .color(128, 255, 255, 200)
  .edge(.{.width = 10, .color = .{.r = 255, .g = 128, .b = 0, .a = 0}})
  .event(.{.duration = 60, .repeat = 14, .pattern = .PingPong, .motion = .Smooth})
    .rotation(1, 0, 1)
  .event(.{.start = 0, .duration = 120, .repeat = 280, .pattern = .PingPong, .motion = .Smooth})
    .scale(1.3, 1.2, 1.1)
  .event(.{.start = 41.666, .duration = 0.333})
    .edge(.{.width = 10, .color = .{.r = 255, .g = 128, .b = 0, .a = 255}})
  .event(.{.start = 41.7, .duration = 60, .repeat = 70, .pattern = .Forward, .motion = .EaseIn})
    .edge(.{.width = 0, .color = .{.r = 0, .g = 0, .b = 0, .a = 255}});

  _ = cube.entity("zigma balls").text("Zigma")
  .position(-0.7, 0.8, 0)
  .scale(25, 0, 0)
  .rotation(0, 0, 0)
  .color(200, 255, 255, 150)
  .event(.{.end = 25, .repeat = 5, .pattern = .PingPong})
    .scale(15, 0, 0)
  .event(.{.start = 27.6, .duration = 60, .repeat = 140, .motion = .EaseIn })
    .scale(15, 0, 0);


  // Torus world
  var torus = zigma.create();
  defer zigma.destroy(torus);

  _ = torus.entity("camera").camera(.{})
  .event(.{.duration = 60, .repeat = 10, .pattern = .PingPong, .motion = .Smooth})
    .position(-5, 0.5, 2);

  _ = torus.entity("background")
  .color(25, 25, 25, 255);

  _ = torus.entity("floor").model(.{.type = "plane"})
  .color(64, 64, 64, 255)
  .scale(10, 0, 10)
  .position(0, -1, 0);

  _ = torus.entity("torus").model(.{.type = "torus"})
  .color(128, 128, 255, 128)
  .event(.{.duration = 60, .repeat = 15, .pattern = .PingPong, .motion = .Smooth})
    .scale(2, 2, 2)
    .rotation(0.25, 0, 1)
  .event(.{.start = 1, .duration = 10, .repeat = 20})
    .hide();

  _ = torus.entity("torus spawn").model(.{.type = "cube"}).spawn(.{.source_model = "torus"})
  .event(.{.duration = 90, .repeat = 10, .pattern = .PongPing, .motion = .EaseIn})
    .color(128, 255, 255, 200)
    .scale(0.01, 0.01, 0.01)
    .rotation(10, 10, 10);


  // Universe timeline
  _ = universe.entity("world cube").subWorld(cube)
  .event(.{.start = 0, .end= 55.3, .pattern = .Forward, .motion = .Linear});

  _ = universe.entity("world torus").subWorld(torus)
  .event(.{.start = 55.3, .end= 120, .pattern = .Forward, .motion = .Linear});

  while(zigma.render(universe)){}
}
