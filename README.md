# dotfiles

Personal system configuration for macOS using nix-darwin.

## Overview

This repository contains the nix-darwin configuration for the `aurelia` system. It manages system packages, Homebrew dependencies, macOS defaults, and home-manager configuration.

## Requirements

- macOS (Apple Silicon)
- Nix package manager with flakes enabled
- nix-darwin

## Usage

Initial installation:

```bash
sudo nix run nix-darwin -- switch --flake ~/Code/dotfiles#aurelia
```

Subsequent updates:

```bash
sudo darwin-rebuild switch --flake ~/Code/dotfiles#aurelia
```

Or use the configured alias:

```bash
dr
```

## Structure

- `flake.nix` - Main system configuration
- `flake.lock` - Dependency lock file

## Configuration Includes

- System packages via Nix
- Homebrew packages, casks, and taps
- macOS system defaults
- Shell configuration (zsh with starship prompt)
- Terminal emulator (Ghostty)
- Window manager (AeroSpace)
- GPG and Git configuration
- Font management

## Licence

MIT
