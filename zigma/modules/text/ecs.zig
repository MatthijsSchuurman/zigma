pub const Module = struct {
  pub const Entities = struct {
    pub const Text = @import("entity.zig");
  };

  pub const Components = struct {
    pub const Text = @import("component.zig");
  };

  pub const Systems = struct {
    pub const Text = @import("system.zig");
  };
};
