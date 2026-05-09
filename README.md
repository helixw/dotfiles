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

## Development

After cloning, enable the in-repo git hooks (enforces [Conventional Commits](https://www.conventionalcommits.org/) on every commit):

```bash
git config core.hooksPath .githooks
```

This is a one-time setup per clone — git does not honour `core.hooksPath` automatically for security reasons.

## Structure

- `flake.nix` - Main system configuration
- `flake.lock` - Dependency lock file
- `.githooks/` - Repo-tracked git hooks (enabled via `core.hooksPath`)

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
