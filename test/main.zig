const zigma = @import("zigma");

pub fn main() void {
  zigma.init(.{.title = "Zigma test", .width = 1920, .height = 1080});
  defer zigma.deinit();

  var world = zigma.create();
  defer zigma.destroy(world);

  _ = world.entity("camera").camera(.{})
  .event(.{.start = 0, .duration = 60, .repeat = 10, .pattern = .PingPong, .motion = .Smooth})
    .position(-5, 0.5, 2);

  _ = world.entity("background")
  .color(25, 25, 25, 255);

  _ = world.entity("floor").model(.{.type = "plane"})
  .color(64, 64, 64, 255)
  .scale(10, 0, 10);

  _ = world.entity("cube").model(.{.type = "cube"})
  .color(128, 128, 255, 128)
  .position(0, 0.5, 0);


  while(zigma.render(world)){}
}
