pub const Module = struct {
  pub const Entities = struct {
    pub const Camera = @import("entity.zig");
  };

  pub const Components = struct {
    pub const Camera = @import("component.zig");
  };

  pub const Systems = struct {
    pub const Camera = @import("system.zig");
  };
};
