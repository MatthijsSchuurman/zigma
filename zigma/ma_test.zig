const std = @import("std");
const tst = @import("std").testing;
const zigma = @import("ma.zig");

test "Zigma should init world" {
  // Given
  const config = .{
    .title = "test",
    .width = 320,
    .height = 200,
  };

  // When
  const world = zigma.init(config);

  // Then

  // Clean
  zigma.deinit(world);
}
