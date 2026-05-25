{ ... }:

{
  programs.zellij = {
    enable = true;

    settings = {
      default_mode = "normal";
      mouse_mode = true;
      pane_frames = true;
      scroll_buffer_size = 10000;
      simplified_ui = true;
    };
  };
}
