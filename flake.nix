{
  description = "i18n-node-enhanced: Enterprise-grade internationalization for Node.js";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        # Rust toolchain for WASM
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32-unknown-unknown" ];
        };

        # Node.js version
        nodejs = pkgs.nodejs_20;

        # Build inputs
        buildInputs = with pkgs; [
          nodejs
          nodePackages.npm
          git
          just

          # WASM tools
          rustToolchain
          wasm-pack
          wasm-bindgen-cli

          # Deno
          deno

          # Optional: ReScript
          # nodePackages.rescript

          # Development tools
          nodePackages.eslint
          nodePackages.prettier

          # Security
          gnupg
        ];

      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          inherit buildInputs;

          shellHook = ''
            echo "🌍 i18n-node-enhanced development environment"
            echo ""
            echo "Node.js: $(node --version)"
            echo "npm: $(npm --version)"
            echo "Rust: $(rustc --version)"
            echo "Deno: $(deno --version | head -1)"
            echo "Just: $(just --version)"
            echo ""
            echo "Available commands:"
            echo "  just install    - Install dependencies"
            echo "  just test       - Run tests"
            echo "  just build-all  - Build all components"
            echo "  just rsr-check  - Check RSR compliance"
            echo ""
            echo "Type 'just' to see all available commands"
          '';

          # Environment variables
          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
          WASM_TARGET = "wasm32-unknown-unknown";
        };

        # Package
        packages.default = pkgs.buildNpmPackage {
          pname = "i18n-node-enhanced";
          version = (builtins.fromJSON (builtins.readFile ./package.json)).version;

          src = ./.;

          npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # Update with actual hash

          buildPhase = ''
            runHook preBuild

            # Build WASM if directory exists
            if [ -d "wasm" ]; then
              cd wasm
              cargo build --release --target wasm32-unknown-unknown
              wasm-pack build --target nodejs --out-dir pkg
              cd ..
            fi

            # Build ReScript if directory exists
            if [ -d "bindings/rescript" ]; then
              cd bindings/rescript
              npm install
              npx rescript build
              cd ../..
            fi

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib/node_modules/i18n
            cp -r . $out/lib/node_modules/i18n/

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Lightweight translation module with dynamic JSON storage";
            homepage = "https://github.com/mashpie/i18n-node";
            license = licenses.mit;
            maintainers = [ ];
            platforms = platforms.all;
          };
        };

        # Apps
        apps = {
          # Run tests
          test = {
            type = "app";
            program = "${pkgs.writeShellScript "test" ''
              ${nodejs}/bin/npm test
            ''}";
          };

          # Run RSR compliance check
          rsr-check = {
            type = "app";
            program = "${pkgs.writeShellScript "rsr-check" ''
              ${just}/bin/just rsr-check
            ''}";
          };

          # Run Express example
          example-express = {
            type = "app";
            program = "${pkgs.writeShellScript "example-express" ''
              ${just}/bin/just example-express
            ''}";
          };
        };

        # Checks (run with 'nix flake check')
        checks = {
          # Run tests
          tests = pkgs.runCommand "i18n-tests" {
            buildInputs = [ nodejs ];
          } ''
            cd ${self}
            npm install
            npm test
            touch $out
          '';

          # Check formatting
          formatting = pkgs.runCommand "i18n-formatting" {
            buildInputs = [ nodejs pkgs.nodePackages.prettier ];
          } ''
            cd ${self}
            prettier --check "**/*.{js,json,md}" || exit 1
            touch $out
          '';

          # Check linting
          linting = pkgs.runCommand "i18n-linting" {
            buildInputs = [ nodejs pkgs.nodePackages.eslint ];
          } ''
            cd ${self}
            npm install
            npx eslint i18n.js index.js test/ || exit 1
            touch $out
          '';

          # RSR compliance
          rsr-compliance = pkgs.runCommand "i18n-rsr" {
            buildInputs = [ just ];
          } ''
            cd ${self}
            just rsr-check || exit 1
            touch $out
          '';
        };

        # Formatter (run with 'nix fmt')
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
