pub const Module = struct {
  pub const Entities = struct {
    pub const Edge = @import("entity.zig");
  };

  pub const Components = struct {
    pub const Edge = @import("component.zig");
  };

  pub const Systems = struct {
    pub const Edge = @import("system.zig");
  };
};
