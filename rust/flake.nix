{
  description = "Rust Stable Dev Shell";

  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-23.11";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rust = with pkgs; rust-bin.nightly.latest.default.override {
          extensions = [ "rust-src" ];
          targets = [
            # Web
            "wasm32-unknown-emscripten"
          ]
          # Windows
          ++ (lib.optional stdenv.isx86_64 "x86_64-pc-windows-msvc");
        };
        rustPlatform = pkgs.makeRustPlatform {
          cargo = rust;
          rustc = rust;
        };
        cargo-xwin = (pkgs.cargo-xwin.override {
          inherit rustPlatform;
        }).overrideAttrs (old: rec {
          version = "0.17.3";
          src = pkgs.fetchFromGitHub {
            owner = "rust-cross";
            repo = "cargo-xwin";
            rev = "v${version}";
            hash = "sha256-Lpcofb4yz1pR6dNJEnpkkCFdYjgt0qMzVP55kgKqjFA=";
          };
          cargoDeps = old.cargoDeps.overrideAttrs (pkgs.lib.const {
            inherit src;
            name = "${old.pname}-${version}-vendor.tar.gz";
            outputHash = "sha256-xVG1nET020rfMIjhIcCtNr9ZCj8SgQAvXePjyKSPjUs=";
          });
        });
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            rust
            pkgs.emscripten
          ] ++ (pkgs.lib.optional pkgs.stdenv.isx86_64 [
            # Windows
            cargo-xwin
          ]);
          EM_CACHE = "em-cache";
        };
      }
    );
}
