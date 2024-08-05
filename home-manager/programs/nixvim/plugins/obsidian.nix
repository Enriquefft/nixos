{ programs.nixvim.plugins.obsidian = { enable = true;

settings = {
  workspaces = [
      {
        name = "Hermes";
        path = "~/Documents/Hermes";
      }
      {
        name = "Arqui";
        path = "~/Documents/Arqui";
      }
    ];
    new_notes_location = "current_dir";
    completion = {
      nvim_cmp = true;
      min_chars = 2;
    };
};
}; }
