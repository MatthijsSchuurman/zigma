const std = @import("std");
const ecs = @import("ecs.zig");
const rl = ecs.raylib;

pub const Music = struct {
  music: rl.Music,
  pitch: f32 = 1.0,
  playing: bool = false,

  pub fn init(path: [*:0]const u8) Music {
    rl.InitAudioDevice();
    const music = rl.LoadMusicStream(path);
    rl.PlayMusicStream(music);
    return Music{ .music = music };
  }

  pub fn deinit(self: *Music) void {
    rl.UnloadMusicStream(self.music);
    rl.CloseAudioDevice();
  }

  pub fn update(self: *Music) void {
    rl.UpdateMusicStream(self.music);
  }

  pub fn play(self: *Music) void {
    rl.PlayMusicStream(self.music);
    self.playing = true;
  }

  pub fn pause(self: *Music) void {
    rl.PauseMusicStream(self.music);
    self.playing = false;
  }

  pub fn speed(self: *Music, pitch: f32) void {
    self.pitch = pitch;
    rl.SetMusicPitch(self.music, pitch);

    if (self.pitch <= 0.0)
      self.pause()
    else if (!self.playing)
      self.play();
  }

  pub fn seek(self: *Music, seconds: f32) void {
    rl.SeekMusicStream(self.music, seconds * self.pitch);
  }
};
