pub const init = struct {
};

pub const deinit = struct {
};

pub const render = struct {
  pub const background = @import("systems/render/background.zig");
  pub const text = @import("systems/render/text.zig");
};

pub const input = struct {
};

