{
  description = "Aurelia nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager }: let
    configuration = { pkgs, config, ... }: {
      # Package configuration
      nixpkgs.config.allowUnfree = true;
      
      # Suppress warnings (if supported)
      warnings = [];

      # User account configuration
      users.users.helixw = {
        home = "/Users/helixw";
        shell = pkgs.zsh;
      };

      # System-wide package installation
      environment.systemPackages = [
        pkgs.vim
        pkgs.mkalias
      ];

      # Homebrew package manager configuration
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
          "git-secret"
          "gh"
          "uv"
          "btop"
          "oven-sh/bun/bun"
          "git-secret"
        ];
        casks = [
          "font-jetbrains-mono-nerd-font"
          "raycast"
          "the-unarchiver"
          "sublime-text"
          "appcleaner"
          "1password"
          "aerospace"
          "docker-desktop"
          "scroll-reverser"
          "zoom"
          "cursor"
          "shottr"
          "the-unarchiver"
          "parsec"
          "ghostty"
          "altserver"
          "webcatalog"
          "ollama-app"
          "google-drive"
          "microsoft-office"
          "notion"
          "chatgpt-atlas"
          "ticktick"
          "iina"
          "transmission"
        ];
        masApps = {};
        onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      # Application symlink management
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

      # macOS system preferences configuration
      system.defaults = {
        # Dock configuration
        dock = {
          orientation = "right";
          show-recents = false;
          persistent-apps = [
            "/Applications/Ghostty.app"
            "/Applications/1Password.app"
            "/Applications/Ticktick.app"
            "/Applications/Microsoft Outlook.app"
            "/Users/helixw/Applications/WebCatalog Apps/Google Chat.app"
            "/Applications/Zoom.us.app"
            "/Applications/ChatGPT Atlas.app"
            "/Applications/Notion.app"
            "/Applications/Cursor.app"
            "/Applications/Microsoft Excel.app"
            "/Applications/Microsoft Word.app"
            "/Applications/Microsoft PowerPoint.app"
            "/Applications/PDF Expert.app"
            "/System/Applications/App Store.app"
            "/System/Applications/System Settings.app"
            "/Applications/AppCleaner.app"
          ];
        };

        # Trackpad configuration
        trackpad = {
          Clicking = true;
          TrackpadRightClick = true;
        };

        # Login window configuration
        loginwindow = {
          GuestEnabled = false;
        };

        # Global domain preferences
        NSGlobalDomain = {
          "AppleICUForce24HourTime" = true;
          "AppleInterfaceStyle" = "Dark";
          "KeyRepeat" = 2;
          "_HIHideMenuBar" = false;
        };
      };

      # Custom user preferences (using activation script to avoid plist warnings)
      system.activationScripts.userDefaults.text = ''
        # Disable spotlight keyboard shortcuts
        /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '{ enabled = 0; }'
        /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 '{ enabled = 0; }'
      '';

      # Set primary user for system-wide activation
      system.primaryUser = "helixw";

      # Nix daemon configuration
      # Disable nix-darwin's Nix management (using Determinate Nix)
      nix.enable = false;

      # Shell configuration
      programs.zsh.enable = true;
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 6;
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in {
    # Darwin system configuration
    darwinConfigurations."aurelia" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          # Homebrew integration configuration
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "helixw";
            autoMigrate = true;
          };
        }
        home-manager.darwinModules.home-manager
        {
          # Home Manager configuration
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users."helixw" = { config, pkgs, ... }: {
              # Home Manager version
              home.stateVersion = "24.11";
              home.homeDirectory = "/Users/helixw";

              # User package installation
              home.packages = with pkgs; [
                fontconfig
              ];

              # Directory creation activation script
              home.activation.createDirectories = config.lib.dag.entryAfter [ "writeBoundary" ] ''
                mkdir -p "$HOME/.config/vim"
                mkdir -p "$HOME/.gnupg"
              '';

              # Configuration file management
              home.file = {
                # Font configuration
                ".config/fontconfig/fonts.conf".text = ''
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

                # Vim editor configuration
                ".config/vim/vimrc".text = ''
                  " Store viminfo in XDG config directory
                  set viminfo='100,n$XDG_CONFIG_HOME/vim/viminfo
                  " Enable line numbers
                  set number
                  " Enable syntax highlighting
                  syntax on
                '';



                # Starship prompt configuration
                ".config/starship/starship.toml".text = ''
                  "$schema" = 'https://starship.rs/config-schema.json'
                  
                  format = """
                  [](red)\
                  $os\
                  $username\
                  [](bg:peach fg:red)\
                  $directory\
                  [](bg:yellow fg:peach)\
                  $git_branch\
                  $git_status\
                  [](fg:yellow bg:green)\
                  $c\
                  $rust\
                  $golang\
                  $nodejs\
                  $php\
                  $java\
                  $kotlin\
                  $haskell\
                  $python\
                  [](fg:green bg:sapphire)\
                  $conda\
                  [](fg:sapphire bg:lavender)\
                  $time\
                  [ ](fg:lavender)\
                  $cmd_duration\
                  $line_break\
                  $character"""

                  palette = 'catppuccin_mocha'

                  [os]
                  disabled = false
                  style = "bg:red fg:crust"

                  [os.symbols]
                  Windows = ""
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
                  CentOS = ""
                  Debian = "󰣚"
                  Redhat = "󱄛"
                  RedHatEnterprise = "󱄛"

                  [username]
                  show_always = true
                  style_user = "bg:red fg:crust"
                  style_root = "bg:red fg:crust"
                  format = '[ $user]($style)'

                  [directory]
                  style = "bg:peach fg:crust"
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
                  style = "bg:yellow"
                  format = '[[ $symbol $branch ](fg:crust bg:yellow)]($style)'

                  [git_status]
                  style = "bg:yellow"
                  format = '[[($all_status$ahead_behind )](fg:crust bg:yellow)]($style)'

                  [nodejs]
                  symbol = ""
                  style = "bg:green"
                  format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

                  [c]
                  symbol = " "
                  style = "bg:green"
                  format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

                  [rust]
                  symbol = ""
                  style = "bg:green"
                  format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

                  [golang]
                  symbol = ""
                  style = "bg:green"
                  format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

                  [php]
                  symbol = ""
                  style = "bg:green"
                  format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

                  [java]
                  symbol = " "
                  style = "bg:green"
                  format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

                  [kotlin]
                  symbol = ""
                  style = "bg:green"
                  format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

                  [haskell]
                  symbol = ""
                  style = "bg:green"
                  format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

                  [python]
                  symbol = ""
                  style = "bg:green"
                  format = '[[ $symbol( $version)(\(#$virtualenv\)) ](fg:crust bg:green)]($style)'

                  [docker_context]
                  symbol = ""
                  style = "bg:sapphire"
                  format = '[[ $symbol( $context) ](fg:crust bg:sapphire)]($style)'

                  [conda]
                  symbol = "  "
                  style = "fg:crust bg:sapphire"
                  format = '[$symbol$environment ]($style)'
                  ignore_base = false

                  [time]
                  disabled = false
                  time_format = "%R"
                  style = "bg:lavender"
                  format = '[[  $time ](fg:crust bg:lavender)]($style)'

                  [line_break]
                  disabled = true

                  [character]
                  disabled = false
                  success_symbol = '[❯](bold fg:green)'
                  error_symbol = '[❯](bold fg:red)'
                  vimcmd_symbol = '[❮](bold fg:green)'
                  vimcmd_replace_one_symbol = '[❮](bold fg:lavender)'
                  vimcmd_replace_symbol = '[❮](bold fg:lavender)'
                  vimcmd_visual_symbol = '[❮](bold fg:yellow)'

                  [cmd_duration]
                  show_milliseconds = true
                  format = " in $duration "
                  style = "bg:lavender"
                  disabled = false
                  show_notifications = true
                  min_time_to_notify = 45000

                  [palettes.catppuccin_mocha]
                  rosewater = "#f5e0dc"
                  flamingo = "#f2cdcd"
                  pink = "#f5c2e7"
                  mauve = "#cba6f7"
                  red = "#f38ba8"
                  maroon = "#eba0ac"
                  peach = "#fab387"
                  yellow = "#f9e2af"
                  green = "#a6e3a1"
                  teal = "#94e2d5"
                  sky = "#89dceb"
                  sapphire = "#74c7ec"
                  blue = "#89b4fa"
                  lavender = "#b4befe"
                  text = "#cdd6f4"
                  subtext1 = "#bac2de"
                  subtext0 = "#a6adc8"
                  overlay2 = "#9399b2"
                  overlay1 = "#7f849c"
                  overlay0 = "#6c7086"
                  surface2 = "#585b70"
                  surface1 = "#45475a"
                  surface0 = "#313244"
                  base = "#1e1e2e"
                  mantle = "#181825"
                  crust = "#11111b"

                  [palettes.catppuccin_frappe]
                  rosewater = "#f2d5cf"
                  flamingo = "#eebebe"
                  pink = "#f4b8e4"
                  mauve = "#ca9ee6"
                  red = "#e78284"
                  maroon = "#ea999c"
                  peach = "#ef9f76"
                  yellow = "#e5c890"
                  green = "#a6d189"
                  teal = "#81c8be"
                  sky = "#99d1db"
                  sapphire = "#85c1dc"
                  blue = "#8caaee"
                  lavender = "#babbf1"
                  text = "#c6d0f5"
                  subtext1 = "#b5bfe2"
                  subtext0 = "#a5adce"
                  overlay2 = "#949cbb"
                  overlay1 = "#838ba7"
                  overlay0 = "#737994"
                  surface2 = "#626880"
                  surface1 = "#51576d"
                  surface0 = "#414559"
                  base = "#303446"
                  mantle = "#292c3c"
                  crust = "#232634"

                  [palettes.catppuccin_latte]
                  rosewater = "#dc8a78"
                  flamingo = "#dd7878"
                  pink = "#ea76cb"
                  mauve = "#8839ef"
                  red = "#d20f39"
                  maroon = "#e64553"
                  peach = "#fe640b"
                  yellow = "#df8e1d"
                  green = "#40a02b"
                  teal = "#179299"
                  sky = "#04a5e5"
                  sapphire = "#209fb5"
                  blue = "#1e66f5"
                  lavender = "#7287fd"
                  text = "#4c4f69"
                  subtext1 = "#5c5f77"
                  subtext0 = "#6c6f85"
                  overlay2 = "#7c7f93"
                  overlay1 = "#8c8fa1"
                  overlay0 = "#9ca0b0"
                  surface2 = "#acb0be"
                  surface1 = "#bcc0cc"
                  surface0 = "#ccd0da"
                  base = "#eff1f5"
                  mantle = "#e6e9ef"
                  crust = "#dce0e8"

                  [palettes.catppuccin_macchiato]
                  rosewater = "#f4dbd6"
                  flamingo = "#f0c6c6"
                  pink = "#f5bde6"
                  mauve = "#c6a0f6"
                  red = "#ed8796"
                  maroon = "#ee99a0"
                  peach = "#f5a97f"
                  yellow = "#eed49f"
                  green = "#a6da95"
                  teal = "#8bd5ca"
                  sky = "#91d7e3"
                  sapphire = "#7dc4e4"
                  blue = "#8aadf4"
                  lavender = "#b7bdf8"
                  text = "#cad3f5"
                  subtext1 = "#b8c0e0"
                  subtext0 = "#a5adcb"
                  overlay2 = "#939ab7"
                  overlay1 = "#8087a2"
                  overlay0 = "#6e738d"
                  surface2 = "#5b6078"
                  surface1 = "#494d64"
                  surface0 = "#363a4f"
                  base = "#24273a"
                  mantle = "#1e2030"
                  crust = "#181926"
                '';

                # AeroSpace window manager configuration
                ".config/aerospace/aerospace.toml".text = ''
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

                # Ghostty terminal configuration
                ".config/ghostty/config".text = ''
                  theme = catppuccin-mocha
                  background-opacity = 0.7
                '';

                # Git version control configuration
                ".config/git/config".text = ''
                  [user]
                    name = Shreyas Khan
                    email = shreyas.khan@hotmail.com
                    signingkey = E79A919126BB4CD44F3B6B727F1E7FA9525A7397

                  [core]
                    editor = vim
                    autocrlf = input

                  [init]
                    defaultBranch = master

                  [commit]
                    gpgsign = true

                  [tag]
                    gpgsign = true

                  [gpg]
                    format = openpgp

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
                ".gnupg/gpg-agent.conf".text = ''
                  # Use macOS pinentry for password prompts
                  pinentry-program /opt/homebrew/bin/pinentry-mac
                  # Enable SSH support through GPG
                  enable-ssh-support
                '';
              };

              # ZSH shell configuration
              programs.zsh = {
                enable = true;
                dotDir = "${config.xdg.configHome}/zsh";
                enableCompletion = true;
                autosuggestion.enable = true;
                syntaxHighlighting.enable = true;

                initContent = ''
                  # Path configuration
                  export PATH="$HOME/bin:$PATH"
                  
                  # XDG Base Directory Specification
                  export XDG_CONFIG_HOME="$HOME/.config"
                  export XDG_DATA_HOME="$HOME/.local/share"
                  export XDG_CACHE_HOME="$HOME/.cache"
                  export XDG_STATE_HOME="$HOME/.local/state"
                  
                  # History settings
                  export HISTFILE="$ZDOTDIR/.zsh_history"
                  export HISTSIZE=10000
                  export SAVEHIST=10000

                  # Useful aliases
                  alias ll="ls -lah"
                  alias dr="sudo darwin-rebuild switch --flake ~/Code/dotfiles#aurelia"
                  
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

              # Application configuration activation scripts
              home.activation = {

                # GPG directory permissions configuration
                setGpgPermissions = config.lib.dag.entryAfter [ "writeBoundary" ".gnupg/gpg-agent.conf" ] ''
                  # Set proper permissions for GPG directory
                  chmod 700 "$HOME/.gnupg"
                  find "$HOME/.gnupg" -type f -exec chmod 600 {} \;
                '';

                # GPG agent reload configuration
                reloadGpgAgent = config.lib.dag.entryAfter [ "setGpgPermissions" ] ''
                  # Restart GPG agent to apply new configuration
                  ${pkgs.gnupg}/bin/gpgconf --kill gpg-agent || true
                  ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent || true
                '';

                # JetBrains Mono Nerd Font installation
                linkNerdFont = config.lib.dag.entryAfter [ "writeBoundary" ] ''
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
          };
        }
      ];
    };
  };
}
