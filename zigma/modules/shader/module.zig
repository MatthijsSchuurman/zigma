pub const Module = struct {
  pub const Entities = struct {
    pub const Shader = @import("entity.zig");
  };

  pub const Components = struct {
    pub const Shader = @import("component.zig");
  };

  pub const Systems = struct {
    pub const Shader = @import("system.zig");
  };
};
