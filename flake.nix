{
  description = "Shared primitives for gluebox and unibox.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    crane.url = "github:ipetkov/crane";
  };

  outputs = { self, nixpkgs, crane, ... }:
    let
      forAllSystems = f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (system: f {
        inherit system;
        pkgs = import nixpkgs { inherit system; };
      });

      coreFor = pkgs:
        let
          craneLib = crane.mkLib pkgs;

          src = pkgs.lib.cleanSourceWith {
            src = ./.;
            filter = path: type:
              let baseName = baseNameOf path;
              in !(
                (builtins.match ".*\\.jj.*" path != null) ||
                (builtins.match ".*\\.github.*" path != null) ||
                (builtins.match ".*/target/.*" path != null) ||
                (builtins.match ".*\\.md$" path != null) ||
                baseName == "flake.nix" ||
                baseName == "flake.lock" ||
                baseName == ".gitignore" ||
                baseName == "result"
              ) || craneLib.filterCargoSources path type;
          };

          commonArgs = {
            inherit src;
            strictDeps = true;
            doCheck = false;
            CARGO_INCREMENTAL = "0";
            nativeBuildInputs = with pkgs; [ pkg-config ];
          };

          cargoArtifacts = craneLib.buildDepsOnly commonArgs;
        in
        {
          package = craneLib.buildPackage (commonArgs // {
            inherit cargoArtifacts;
            meta.description = "Shared primitives for gluebox and unibox.";
          });

          nextest = craneLib.cargoNextest (commonArgs // {
            inherit cargoArtifacts;
            cargoNextestExtraArgs = "--profile ci";
          });

          clippy = craneLib.cargoClippy (commonArgs // {
            inherit cargoArtifacts;
            cargoClippyExtraArgs = "--all-targets -- --deny warnings";
          });

          fmt = craneLib.cargoFmt {
            inherit src;
          };
        };
    in
    {
      packages = forAllSystems ({ system, pkgs }: {
        gluebox-core = (coreFor pkgs).package;
        default = self.packages.${system}.gluebox-core;
      });

      checks = forAllSystems ({ system, pkgs }:
        let core = coreFor pkgs; in {
          nextest = core.nextest;
          clippy = core.clippy;
          fmt = core.fmt;
        });

      devShells = forAllSystems ({ system, pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            rustc cargo clippy rustfmt rust-analyzer pkg-config
            cargo-nextest
          ];
        };
      });
    };
}
