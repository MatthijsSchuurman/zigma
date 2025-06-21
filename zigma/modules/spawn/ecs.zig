pub const Module = struct {
  pub const Entities = struct {
    pub const Spawn = @import("entity.zig");
  };

  pub const Components = struct {
    pub const Spawn = @import("component.zig");
  };

  pub const Systems = struct {
    pub const Spawn = @import("system.zig");
  };
};
