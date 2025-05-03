const std = @import("std");
const zigma = @import("zigma");

pub fn main() !void {
  var world = zigma.init(.{.title = "Zigma demo", .width = 1920, .height = 1080});

  _ = world.entity("zigma balls")
  .text("Zigma Balls!!!")
  .position(0, 0, 0)
  .scale(20, 1, 1)
  .color(100, 255, 255, 150);

  for (1..10) |c| {
    const name = try std.fmt.allocPrint(world.allocator, "balls {}", .{ c });
    var pos: f32 = @floatFromInt(c);
    pos /= 10;

    _ = world.entity(name)
    .text("Zigma Balls!!!")
    .position(-1+pos, -1+pos, 0)
    .scale(@floatFromInt(c), 1, 1)
    .color(100, @intCast(c*25), @intCast(c*25), 150);
  }

  while(zigma.render(&world)){}

  world.deinit();
}
