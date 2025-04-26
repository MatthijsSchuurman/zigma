pub const engine = @import("lib/engine.zig");
pub const timeline = @import("lib/timeline.zig");

pub const base = @import("objects/base.zig");
pub const objects = struct {
  pub const text = @import("objects/text.zig");
};

pub const effects = struct {
  pub const background = @import("effects/background.zig");
};
