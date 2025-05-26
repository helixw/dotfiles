{
  description = "Solstice nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager }: let
    configuration = { pkgs, config, ... }: {
      nixpkgs.config.allowUnfree = true;

      # User configuration
      users.users.helixw = {
        home = "/Users/helixw";
        shell = pkgs.zsh;
      };

      # System packages
      environment.systemPackages = [
        pkgs.vim
        pkgs.mkalias
      ];

      # Homebrew configuration
      homebrew = {
        enable = true;
        taps = [
          "nikitabobko/tap"
        ];
        brews = [
          "mas"
          "starship"
          "fontconfig"
          "fastfetch"
          "gnupg"
          "pinentry-mac"
          "node"
          "python"
          "tree"
          "virtualenv"
          "poetry"
          "git-secret"
        ];
        casks = [
          "font-jetbrains-mono-nerd-font"
          "wezterm"
          "raycast"
          "the-unarchiver"
          "sublime-text"
          "appcleaner"
          "arc"
          "1password"
          "ticktick"
          "parsec"
          "aerospace"
          "krisp"
          "discord"
          "obsidian"
          "altserver"
          "microsoft-outlook"
          "shadow"
          "docker"
          "scroll-reverser"
          "zoom"
	  "cursor"
        ];
        masApps = {};
        onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      # Applications management
      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in pkgs.lib.mkForce ''
        echo "Setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read -r src; do
          app_name=$(basename "$src")
          echo "Copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
      '';

      # System preferences
      system.defaults = {
        dock.orientation = "right";
        dock.show-recents = false;
        dock.persistent-apps = [
          "/Applications/1Password.app"
          "/Applications/Microsoft\ Outlook.app"
          "/System/Applications/Messages.app"
          "/Applications/Discord.app"
          "/Applications/WezTerm.app"
          "/Applications/TickTick.app"
          "/Applications/Arc.app"
          "/Applications/Obsidian.app"
          "/Applications/Cursor.app"
          "/Applications/PDF\ Expert.app"
          "/Applications/Parallels\ Desktop.app"
          "/Users/helixw/Parallels/Windows\ 11.pvm/Windows\ 11.app"
          "/Applications/Shadow\ PC.app"
          "/Applications/Parsec.app"
          "/System/Applications/App\ Store.app"
          "/System/Applications/System\ Settings.app"
          "/Applications/AppCleaner.app"
        ];

        trackpad = {
          Clicking = true;
          TrackpadRightClick = true;
        };
        loginwindow.GuestEnabled = false;
        NSGlobalDomain.AppleICUForce24HourTime = true;
        NSGlobalDomain.AppleInterfaceStyle = "Dark";
        NSGlobalDomain.KeyRepeat = 2;

        CustomUserPreferences = {
          "com.apple.symbolichotkeys" = {
            AppleSymbolicHotKeys = {
              "64" = { enabled = false; };
              "65" = { enabled = false; };
            };
          };
        };
      };

      # Apply system settings
      system.activationScripts.postUserActivation.text = ''
        /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      '';

      # Nix configuration
      nix.settings.experimental-features = "nix-command flakes";

      # Enable ZSH
      programs.zsh.enable = true;
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 6;
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in {
    darwinConfigurations."solstice" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "helixw";
            autoMigrate = true;
          };
        }
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users."helixw" = { config, pkgs, ... }: {
              home.stateVersion = "24.11";
              home.homeDirectory = "/Users/helixw";

              home.packages = with pkgs; [
                fontconfig
              ];

              # Create required directories
              home.activation.createDirectories = config.lib.dag.entryAfter [ "writeBoundary" ] ''
                mkdir -p "$HOME/.config/vim"
                mkdir -p "$HOME/.config/cursor"
                mkdir -p "$HOME/.config/parsec"
                mkdir -p "$HOME/.gnupg"
              '';

              # Font configuration
              home.file.".config/fontconfig/fonts.conf".text = ''
                <?xml version="1.0"?>
                <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
                <fontconfig>
                  <!-- Define font directories in order of preference -->
                  <dir>~/Library/Fonts</dir>
                  <dir prefix="xdg">fonts</dir>
                  <dir>/System/Library/Fonts</dir>
                  <dir>/Library/Fonts</dir>
                </fontconfig>
              '';

              # Vim configuration
              home.file.".config/vim/vimrc".text = ''
                " Store viminfo in XDG config directory
                set viminfo='100,n$XDG_CONFIG_HOME/vim/viminfo
                " Enable line numbers
                set number
                " Enable syntax highlighting
                syntax on
              '';

              # WezTerm configuration
              home.file.".config/wezterm/wezterm.lua".text = ''
                local wezterm = require("wezterm")

                config = {
                  -- Automatically reload configuration when changed
                  automatically_reload_config = true,
                  -- Disable tab bar for cleaner interface
                  enable_tab_bar = false,
                  -- Prevent confirmation when closing windows
                  window_close_confirmation = "NeverPrompt",
                  -- Allow window resizing only
                  window_decorations = "RESIZE",
                  -- Set colour scheme
                  color_scheme = 'Gruvbox dark, soft (base16)',
                  -- Configure font with weight
                  font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Bold" }),
                  font_size = 12,
                  -- Set background transparency
                  window_background_opacity = 0.70,
                }

                return config
              '';

              # Starship prompt configuration
              home.file.".config/starship/starship.toml".text = ''
                "$schema" = 'https://starship.rs/config-schema.json'

                format = """
                [](color_orange)\
                $os\
                $username\
                [](bg:color_yellow fg:color_orange)\
                $directory\
                [](fg:color_yellow bg:color_aqua)\
                $git_branch\
                $git_status\
                [](fg:color_aqua bg:color_blue)\
                $c\
                $rust\
                $golang\
                $nodejs\
                $php\
                $java\
                $kotlin\
                $haskell\
                $python\
                [](fg:color_blue bg:color_bg3)\
                $docker_context\
                $conda\
                [](fg:color_bg3 bg:color_bg1)\
                $time\
                [ ](fg:color_bg1)\
                $line_break$character"""

                palette = 'gruvbox_dark'

                [palettes.gruvbox_dark]
                color_fg0 = '#fbf1c7'
                color_bg1 = '#3c3836'
                color_bg3 = '#665c54'
                color_blue = '#458588'
                color_aqua = '#689d6a'
                color_green = '#98971a'
                color_orange = '#d65d0e'
                color_purple = '#b16286'
                color_red = '#cc241d'
                color_yellow = '#d79921'

                [os]
                disabled = false
                style = "bg:color_orange fg:color_fg0"

                [os.symbols]
                Windows = "󰍲"
                Ubuntu = "󰕈"
                SUSE = ""
                Raspbian = "󰐿"
                Mint = "󰣭"
                Macos = "󰀵"
                Manjaro = ""
                Linux = "󰌽"
                Gentoo = "󰣨"
                Fedora = "󰣛"
                Alpine = ""
                Amazon = ""
                Android = ""
                Arch = "󰣇"
                Artix = "󰣇"
                EndeavourOS = ""
                CentOS = ""
                Debian = "󰣚"
                Redhat = "󱄛"
                RedHatEnterprise = "󱄛"
                Pop = ""

                [username]
                show_always = true
                style_user = "bg:color_orange fg:color_fg0"
                style_root = "bg:color_orange fg:color_fg0"
                format = '[ $user ]($style)'

                [directory]
                style = "fg:color_fg0 bg:color_yellow"
                format = "[ $path ]($style)"
                truncation_length = 3
                truncation_symbol = "…/"

                [directory.substitutions]
                "Documents" = "󰈙 "
                "Downloads" = " "
                "Music" = "󰝚 "
                "Pictures" = " "
                "Developer" = "󰲋 "

                [git_branch]
                symbol = ""
                style = "bg:color_aqua"
                format = '[[ $symbol $branch ](fg:color_fg0 bg:color_aqua)]($style)'

                [git_status]
                style = "bg:color_aqua"
                format = '[[($all_status$ahead_behind )](fg:color_fg0 bg:color_aqua)]($style)'

                [nodejs]
                symbol = ""
                style = "bg:color_blue"
                format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

                [c]
                symbol = " "
                style = "bg:color_blue"
                format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

                [rust]
                symbol = ""
                style = "bg:color_blue"
                format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

                [golang]
                symbol = ""
                style = "bg:color_blue"
                format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

                [php]
                symbol = ""
                style = "bg:color_blue"
                format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

                [java]
                symbol = ""
                style = "bg:color_blue"
                format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

                [kotlin]
                symbol = ""
                style = "bg:color_blue"
                format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

                [haskell]
                symbol = ""
                style = "bg:color_blue"
                format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

                [python]
                symbol = ""
                style = "bg:color_blue"
                format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

                [docker_context]
                symbol = ""
                style = "bg:color_bg3"
                format = '[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)'

                [conda]
                style = "bg:color_bg3"
                format = '[[ $symbol( $environment) ](fg:#83a598 bg:color_bg3)]($style)'

                [time]
                disabled = false
                time_format = "%R"
                style = "bg:color_bg1"
                format = '[[  $time ](fg:color_fg0 bg:color_bg1)]($style)'

                [line_break]
                disabled = false

                [character]
                disabled = false
                success_symbol = '[](bold fg:color_green)'
                error_symbol = '[](bold fg:color_red)'
                vimcmd_symbol = '[](bold fg:color_green)'
                vimcmd_replace_one_symbol = '[](bold fg:color_purple)'
                vimcmd_replace_symbol = '[](bold fg:color_purple)'
                vimcmd_visual_symbol = '[](bold fg:color_yellow)'
              '';

              # AeroSpace window manager configuration
              home.file.".config/aerospace/aerospace.toml".text = ''
                # General settings
                after-login-command = []
                after-startup-command = []
                start-at-login = true
                enable-normalization-flatten-containers = true
                enable-normalization-opposite-orientation-for-nested-containers = true
                accordion-padding = 30
                default-root-container-layout = 'tiles'
                default-root-container-orientation = 'auto'
                on-focused-monitor-changed = ['move-mouse monitor-lazy-center']
                automatically-unhide-macos-hidden-apps = false

                # Keyboard mapping
                [key-mapping]
                    preset = 'qwerty'

                # Window gaps
                [gaps]
                    inner.horizontal = 10
                    inner.vertical =   10
                    outer.left =       10
                    outer.bottom =     10
                    outer.top =        10
                    outer.right =      10

                # Main mode key bindings
                [mode.main.binding]
                    # Layout controls
                    alt-slash = 'layout tiles horizontal vertical'
                    alt-comma = 'layout accordion horizontal vertical'
                    
                    # Focus movement
                    alt-h = 'focus left'
                    alt-j = 'focus down'
                    alt-k = 'focus up'
                    alt-l = 'focus right'
                    
                    # Window movement
                    alt-shift-h = 'move left'
                    alt-shift-j = 'move down'
                    alt-shift-k = 'move up'
                    alt-shift-l = 'move right'
                    
                    # Resize controls
                    alt-minus = 'resize smart -50'
                    alt-equal = 'resize smart +50'
                    
                    # Workspace selection
                    alt-1 = 'workspace 1'
                    alt-2 = 'workspace 2'
                    alt-3 = 'workspace 3'
                    alt-4 = 'workspace 4'
                    alt-5 = 'workspace 5'
                    alt-6 = 'workspace 6'
                    alt-7 = 'workspace 7'
                    alt-8 = 'workspace 8'
                    alt-9 = 'workspace 9'
                    alt-a = 'workspace A'
                    alt-b = 'workspace B'
                    alt-c = 'workspace C'
                    alt-d = 'workspace D'
                    alt-e = 'workspace E'
                    alt-f = 'workspace F'
                    alt-g = 'workspace G'
                    alt-i = 'workspace I'
                    alt-m = 'workspace M'
                    alt-n = 'workspace N'
                    alt-o = 'workspace O'
                    alt-p = 'workspace P'
                    alt-q = 'workspace Q'
                    alt-r = 'workspace R'
                    alt-s = 'workspace S'
                    alt-t = 'workspace T'
                    alt-u = 'workspace U'
                    alt-v = 'workspace V'
                    alt-w = 'workspace W'
                    alt-x = 'workspace X'
                    alt-y = 'workspace Y'
                    alt-z = 'workspace Z'
                    
                    # Move window to workspace
                    alt-shift-1 = 'move-node-to-workspace 1'
                    alt-shift-2 = 'move-node-to-workspace 2'
                    alt-shift-3 = 'move-node-to-workspace 3'
                    alt-shift-4 = 'move-node-to-workspace 4'
                    alt-shift-5 = 'move-node-to-workspace 5'
                    alt-shift-6 = 'move-node-to-workspace 6'
                    alt-shift-7 = 'move-node-to-workspace 7'
                    alt-shift-8 = 'move-node-to-workspace 8'
                    alt-shift-9 = 'move-node-to-workspace 9'
                    alt-shift-a = 'move-node-to-workspace A'
                    alt-shift-b = 'move-node-to-workspace B'
                    alt-shift-c = 'move-node-to-workspace C'
                    alt-shift-d = 'move-node-to-workspace D'
                    alt-shift-e = 'move-node-to-workspace E'
                    alt-shift-f = 'move-node-to-workspace F'
                    alt-shift-g = 'move-node-to-workspace G'
                    alt-shift-i = 'move-node-to-workspace I'
                    alt-shift-m = 'move-node-to-workspace M'
                    alt-shift-n = 'move-node-to-workspace N'
                    alt-shift-o = 'move-node-to-workspace O'
                    alt-shift-p = 'move-node-to-workspace P'
                    alt-shift-q = 'move-node-to-workspace Q'
                    alt-shift-r = 'move-node-to-workspace R'
                    alt-shift-s = 'move-node-to-workspace S'
                    alt-shift-t = 'move-node-to-workspace T'
                    alt-shift-u = 'move-node-to-workspace U'
                    alt-shift-v = 'move-node-to-workspace V'
                    alt-shift-w = 'move-node-to-workspace W'
                    alt-shift-x = 'move-node-to-workspace X'
                    alt-shift-y = 'move-node-to-workspace Y'
                    alt-shift-z = 'move-node-to-workspace Z'
                    
                    # Workspace navigation
                    alt-tab = 'workspace-back-and-forth'
                    alt-shift-tab = 'move-workspace-to-monitor --wrap-around next'
                    
                    # Mode switching
                    alt-shift-semicolon = 'mode service'

                # Service mode key bindings
                [mode.service.binding]
                    # Exit service mode
                    esc = ['reload-config', 'mode main']
                    
                    # Layout controls
                    r = ['flatten-workspace-tree', 'mode main']
                    f = ['layout floating tiling', 'mode main']
                    
                    # Window management
                    backspace = ['close-all-windows-but-current', 'mode main']
                    
                    # Join windows
                    alt-shift-h = ['join-with left', 'mode main']
                    alt-shift-j = ['join-with down', 'mode main']
                    alt-shift-k = ['join-with up', 'mode main']
                    alt-shift-l = ['join-with right', 'mode main']
                    
                    # Volume controls
                    down = 'volume down'
                    up = 'volume up'
                    shift-down = ['volume set 0', 'mode main']
              '';

              # Git configuration
              home.file.".config/git/config".text = ''
                [user]
                  name = Shreyas Khan
                  email = shreyas.khan@hotmail.com
                  signingkey = 96B5FFBD136F5A2C21BD6649CD09C64BDFCD678D

                [core]
                  editor = vim
                  autocrlf = input

                [init]
                  defaultBranch = master

                [commit]
                  gpgsign = true

                [credential]
                  helper = cache

                [alias]
                  # Common git command shortcuts
                  st = status
                  co = checkout
                  br = branch
                  ci = commit
                  lg = log --oneline --graph --all
              '';

              # GPG agent configuration
              home.file.".gnupg/gpg-agent.conf".text = ''
                # Use macOS pinentry for password prompts
                pinentry-program /opt/homebrew/bin/pinentry-mac
                # Enable SSH support through GPG
                enable-ssh-support
              '';

              # ZSH configuration
              programs.zsh = {
                enable = true;
                dotDir = ".config/zsh";
                enableCompletion = true;
                autosuggestion.enable = true;
                syntaxHighlighting.enable = true;

                initExtra = ''
                  # Path configuration
                  export PATH="$HOME/bin:$PATH"
                  export XDG_CONFIG_HOME="$HOME/.config"
                  
                  # History settings
                  export HISTFILE="$ZDOTDIR/.zsh_history"
                  export HISTSIZE=10000
                  export SAVEHIST=10000

                  # Useful aliases
                  alias ll="ls -lah"
                  alias dr="darwin-rebuild switch --flake ~/.config/nix#solstice"
                  
                  # Git aliases
                  alias gs="git status"
                  alias ga="git add"
                  alias gc="git commit"
                  alias gp="git push"
                  alias gl="git pull"
                  alias gd="git diff"
                  alias gb="git branch"
                  alias gco="git checkout"
                  alias glog="git log --oneline --graph"
                  alias grb="git rebase"
                  alias grs="git reset"
                  alias gst="git stash"

                  # Font configuration
                  export FONTCONFIG_FILE="$HOME/.config/fontconfig/fonts.conf"
                  
                  # Starship prompt
                  export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
                  eval "$(starship init zsh)"
                
                  # Prefer Homebrew Python over system Python
                  export PATH="/opt/homebrew/opt/python/libexec/bin:$PATH"
                  alias python=python3
                  alias pip=pip3

                  # Vim configuration
                  export VIMINIT='source $XDG_CONFIG_HOME/vim/vimrc'

                  # n8n configuration directory
                  export N8N_USER_FOLDER="$XDG_CONFIG_HOME/n8n"

                  # Enforce recommended file permissions for n8n config
                  export N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
                '';
              };

              # Activation scripts in logical order
              # 1. Configure Cursor application
              home.activation.linkCursorConfig = config.lib.dag.entryAfter [ "createDirectories" ] ''
                # Function to move files to XDG directory and create symlinks
                move_and_link() {
                  local file="$1"
                  local target="$HOME/.config/cursor/$file"

                  if [ -e "$HOME/$file" ]; then
                    if [ ! -L "$HOME/$file" ]; then
                      mv "$HOME/$file" "$target"
                    fi
                    ln -sf "$target" "$HOME/$file"
                  fi
                }
              '';

              # 2. Configure Parsec application
              home.activation.linkParsecConfig = config.lib.dag.entryAfter [ "createDirectories" ] ''
                # Move Parsec configuration to XDG directory
                if [ -d "$HOME/.parsec" ] && [ ! -L "$HOME/.parsec" ]; then
                  mv "$HOME/.parsec" "$HOME/.config/parsec"
                fi

                # Create symlink to XDG directory
                if [ ! -e "$HOME/.parsec" ]; then
                  ln -s "$HOME/.config/parsec" "$HOME/.parsec"
                fi
              '';

              # 3. Set GPG permissions
              home.activation.setGpgPermissions = config.lib.dag.entryAfter [ "writeBoundary" ".gnupg/gpg-agent.conf" ] ''
                # Set proper permissions for GPG directory
                chmod 700 "$HOME/.gnupg"
                find "$HOME/.gnupg" -type f -exec chmod 600 {} \;
              '';

              # 4. Reload GPG agent
              home.activation.reloadGpgAgent = config.lib.dag.entryAfter [ "setGpgPermissions" ] ''
                # Restart GPG agent to apply new configuration
                ${pkgs.gnupg}/bin/gpgconf --kill gpg-agent || true
                ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent || true
              '';

              # 5. Link JetBrains Mono Nerd Font
              home.activation.linkNerdFont = config.lib.dag.entryAfter [ "writeBoundary" ] ''
                # Link JetBrains Mono Nerd Font to user fonts directory
                FONT_SRC="/opt/homebrew/Caskroom/font-jetbrains-mono-nerd-font"
                DEST="$HOME/Library/Fonts"

                if [ -d "$FONT_SRC" ]; then
                  LATEST=$(ls -td "$FONT_SRC"/* | head -n1)
                  find "$LATEST" -iname "*JetBrainsMonoNerdFont*.ttf" -exec ln -sf {} "$DEST" \; 2>/dev/null
                fi

                # Refresh font cache
                export FONTCONFIG_PATH="${pkgs.fontconfig.out}/etc/fonts"
                export FONTCONFIG_FILE="${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
                ${pkgs.fontconfig}/bin/fc-cache -f
              '';
            };
          };
        }
      ];
    };
  };
}
