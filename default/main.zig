const zigma = @import("zigma");
const std = @import("std");

pub fn main() void {
  zigma.init(.{.title = "Zigma test", .width = 1920, .height = 1080, .fps = 60});
  defer zigma.deinit();

  var universe = zigma.create();
  defer zigma.destroy(universe);

  _ = universe.entity("soundtrack").music(.{.path = "default/soundtrack.ogg"});


  var intro = zigma.create();
  defer zigma.destroy(intro);

  _ = intro.entity("camera").camera(.{})
  .event(.{.duration = 60, .repeat = 2, .pattern = .PingPong, .motion = .Smooth})
    .position(-5, 0.5, 2);

  _ = intro.entity("background")
  .color(25, 25, 25, 255);

  _ = intro.entity("floor").model(.{.type = "plane"})
  .color(64, 64, 64, 255)
  .scale(10, 0, 10)
  .position(0, -1, 0);

  _ = intro.entity("cube").model(.{.type = "cube"})
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

  _ = intro.entity("zigma balls").text("Zigma")
  .position(-0.7, 0.8, 0)
  .scale(25, 0, 0)
  .rotation(0, 0, 0)
  .color(200, 255, 255, 150)
  .event(.{.end = 25, .repeat = 5, .pattern = .PingPong})
    .scale(15, 0, 0)
  .event(.{.start = 27.6, .duration = 60, .repeat = 140, .motion = .EaseIn })
    .scale(15, 0, 0);


  _ = universe.entity("world intro").subWorld(intro)
  .event(.{.start = 0, .end= 60, .pattern = .Forward, .motion = .Linear});

  while(zigma.render(universe)){}
}
