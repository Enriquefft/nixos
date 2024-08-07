{
  programs.nixvim = {

    plugins = {

      # Rust Development
      rustaceanvim = {
        enable = true;

      };

      lsp = {
        enable = true;

        keymaps = {
          silent = true;
          diagnostic = {
            # Navigate in diagnostics
            "<leader>k" = "goto_prev";
            "<leader>j" = "goto_next";
            "<leader>t" = "open_float";
          };

          lspBuf = {
            gd = "definition";
            gD = "references";
            gt = "type_definition";
            gi = "implementation";
            K = "hover";
            "<leader>la" = "code_action";
            "<leader>ra" = "rename";
          };
        };

        servers = {

          # NIX
          nil-ls.enable = true;

          # C/C++ Language Servers
          clangd = {
            enable = true; # Provides features for C/C++ development using LLVM
            settings.capabilities = { offsetEncoding = "utf-16"; };

          };

          # Docker Development
          dockerls.enable =
            true; # Supports Dockerfile syntax highlighting and validation

          # Dart/Flutter Development
          dartls.enable =
            true; # Language server for Dart, supporting Flutter development

          # Template Engines
          templ.enable = true; # Generic template engine language server

          # LaTeX Typesetting System
          texlab.enable = true; # Comprehensive LaTeX support

          # Lua Development
          lua-ls.enable = true; # Language server for Lua

          # Go Development
          gopls.enable = true; # Official Go language server

          # Gleam (Erlang-based language)
          # gleam.enable = true; # Language server for Gleam

          # HTML/XHTML/XML Development
          html.enable = true; # Basic HTML support
          htmx.enable = true; # Enhances HTML with AJAX and WebSockets
          emmet-ls.enable = true; # Emmet support for faster HTML/CSS coding
          # CSS Styling
          cssls.enable = true; # Language server for CSS

          # Build Systems
          cmake.enable = true; # Support for CMake build system
          # Bash script language server
          bashls = {
            enable = true;

            # TODO: Disable for .env files

          };

          # JavaScript/TypeScript Development
          tsserver.enable = true; # TypeScript/JavaScript language server
          tailwindcss.enable = true; # Tailwind CSS IntelliSense
          eslint.enable = true; # ESLint integration for linting JS/TS code

          # Svelte/Volar/Prism
          # svelte.enable = true;       # Svelte language support
          # volar.enable = true;        # Vue.js language support
          # prismals.enable = true;     # Prism (syntax highlighting) language server

          # Markdown Development
          marksman.enable = true; # Markdown language server

          # SQL Database Languages
          sqls.enable = true; # SQL language server

          # Infrastructure as Code
          # terraformls.enable = true; # Terraform language server

          # Zig Development
          zls.enable = true; # Zig programming language server

          # YAML/JSON Development
          yamlls.enable = true; # YAML language server
          taplo.enable = true; # TOML language server
          jsonls.enable = true; # JSON language server

          # VHDL Hardware Description Language
          vhdl-ls.enable = true; # VHDL language server

          # Typo Checking
          typos-lsp.enable = true; # Los false-positive typo checking
          ltex = {
            enable = true; # Strict grammar and spell checking
            settings = {
              # enable = true;

              language = "en-US";
              # language = "es";
              # configurationTarget = { dictionary = "user"; };

            };
          };

          # Python Development
          ruff.enable = true; # Linting
          pyright.enable = true; # LSP

        };
      };
    };
  };
}
