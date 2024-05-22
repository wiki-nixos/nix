{
  lib,
  pkgs,
  ...
}: let
  convco_path = lib.getExe pkgs.convco;
  git_path = lib.getExe pkgs.git;
in {
  just-flake = {
    features = {
      base = {
        enable = true;
        justfile = ''
          set dotenv-load
          set export
          set shell := ["${lib.getExe pkgs.nushell}", "-c"]

          log := "warn"
          export JUST_LOG := log
        '';
      };
      convco = {
        enable = true;
        justfile = ''
          # Generate a CHANGELOG.md based on recent Conventional Commits
          changelog:
            ${convco_path} changelog -p ""

          new_version := "$(${convco_path} version --bump)"
        '';
      };
      formatting = {
        enable = false;
        justfile = ''
        '';
      };
      git = {
        enable = true;
        justfile = ''
          #Prepares a new release for github
          @gh-release:
            ${git_path} tag -d "v{{new_version}}" || echo "tag not found, creating"
            ${git_path} tag --sign -a "v{{new_version}} -m "auto generated by the justfile for v$(${convco_path} version)"
            ${git_path} push origin "v{{new_version}}"
            ${lib.getExe pkgs.gh} release create "v$(${convco_path} version)" --target "$(${git_path} rev-parse HEAD)" --title "NixOS Configuration v$(${convco_path} version)"
        '';
      };
      just = {
        enable = true;
        justfile = ''
          # Edit The Justfile
          edit:
            ${lib.getExe pkgs.helix} {{justfile()}}
        '';
      };
      nixos = {
        enable = true;
        justfile = ''
          # Safely activate the current flake's NixOS output that matches the current hostname
          [confirm, linux, no-quiet]
          activate mode="switch" target="":
            ${lib.getExe pkgs.nixos-rebuild} --use-remote-sudo --flake .#{{target}} {{mode}}

          # Safely activate a nix-darwin output that matches the current hostname
          [confirm, macos, no-quiet]
          activate mode="switch" target="":
            darwin-rebuild {{mode}} --verbose --print-build-logs --show-trace --flake .#{{target}}

          # Show some common NixOS health statuses
          health:
            ${lib.getExe pkgs.nix-health}

          # Update and commit lock file
          update:
            ${lib.getExe pkgs.nix} flake update --commit-lock-file
        '';
      };
      versions = {
        enable = true;
        justfile = ''
          # Print out versions of relevant tools
          @versions:
            ${lib.getExe pkgs.nix} --version
            ${lib.getExe pkgs.colmena} --version
            ${lib.getExe pkgs.sops} --version
        '';
      };
    };
  };
}
