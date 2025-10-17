pub const Module = struct {
  pub const Entities = struct {
    pub const SubWorld = @import("entity.zig");
  };

  pub const Components = struct {
    pub const SubWorld = @import("component.zig");
  };

  pub const Systems = struct {
    pub const SubWorld = @import("system.zig");
  };
};
