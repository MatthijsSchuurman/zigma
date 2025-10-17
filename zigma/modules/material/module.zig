pub const Module = struct {
  pub const Entities = struct {
    pub const Material = @import("entity.zig");
  };

  pub const Components = struct {
    pub const Material = @import("component.zig");
  };
};
