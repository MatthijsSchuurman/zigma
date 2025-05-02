const zigma = @import("zigma");

pub fn main() !void {
  var world = zigma.init(.{.title = "Zigma demo", .width = 1920, .height = 1080});

  _ = world.entity("zigma balls")
  .position(0.0, 0.0, 0.0);

  if(world.render()){}
  world.deinit();
}
