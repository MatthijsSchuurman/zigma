pub const Module = struct {
  pub const Entities = struct {
    pub const FPS = @import("entity.zig");
  };

  pub const Components = struct {
    pub const FPS = @import("component.zig");
  };

  pub const Systems = struct {
    pub const FPS = @import("system.zig");
  };
};
