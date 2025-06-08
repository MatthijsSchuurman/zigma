const zigma = @import("zigma");
const std = @import("std");

pub fn main() void {
  zigma.init(.{.title = "Zigma test", .width = 1920, .height = 1080, .fps = 60});
  defer zigma.deinit();

  var world = zigma.create();
  defer zigma.destroy(world);

  _ = world.entity("soundtrack").music(.{.path = "default/soundtrack.ogg"});

  _ = world.entity("camera").camera(.{})
  .event(.{.duration = 60, .repeat = 2, .pattern = .PingPong, .motion = .Smooth})
    .position(-5, 0.5, 2);

  _ = world.entity("background")
  .color(25, 25, 25, 255);

  _ = world.entity("floor").model(.{.type = "plane"})
  .color(64, 64, 64, 255)
  .scale(10, 0, 10)
  .position(0, -1, 0);

  _ = world.entity("cube").model(.{.type = "cube"})
  .color(128, 255, 255, 200)
  .event(.{.duration = 60, .repeat = 14, .pattern = .PingPong, .motion = .Smooth})
    .rotation(1, 0, 1);

  _ = world.entity("cube2").model(.{.type = "torus"})
  .position(0, 1, 0)
  .color(128, 255, 255, 200)
  .event(.{.duration = 60, .repeat = 14, .pattern = .PingPong, .motion = .Smooth})
    .rotation(1, 0, 1);

  _ = world.entity("zigma balls").text("Zigma")
  .position(-0.7, 0.8, 0)
  .scale(25, 0, 0)
  .rotation(0, 0, 0)
  .color(200, 255, 255, 150)
  .event(.{.end = 25, .repeat = 5, .pattern = .PingPong})
    .scale(15, 0, 0)
  .event(.{.start = 27.6, .duration = 60, .repeat = 140, .motion = .EaseIn })
    .scale(15, 0, 0);


  while(zigma.render(world)){}
}
