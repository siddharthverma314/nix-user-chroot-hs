{
  inputs = {
    haskellNix.url = github:input-output-hk/haskell.nix?rev=f279cdef5f74f4262045e83713fb5f80df2ef576;
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-utils.url = github:numtide/flake-utils;
    nix-bundle = {
      url = github:/matthewbauer/nix-bundle;
      inputs.nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    };
  };
  outputs =
    { self
    , haskellNix
    , flake-utils
    , nixpkgs
    , nix-bundle
    , ...
    }:
      flake-utils.lib.eachDefaultSystem (
        system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [
                haskellNix.overlay (final: prev:
                  {
                    nix-user-chroot =
                      final.haskell-nix.project' {
                        src = ./.;
                        compiler-nix-name = "ghc8104";
                      };
                  }
                )
              ];
            };
            flake = pkgs.nix-user-chroot.flake {};
            program = flake.packages."nix-user-chroot:exe:nix-user-chroot";
          in
            {
              defaultPackage = program;
              devShell = pkgs.nix-user-chroot.shellFor {
                tools = {
                  cabal = "latest";
                  hlint = "latest";
                  haskell-language-server = "latest";
                  ghc-prof-flamegraph = "latest";
                  cabal-fmt = "latest";
                  hpack = "latest";
                };
                buildInputs = with pkgs; [
                  rnix-lsp
                  zlib
                  sqlite
                ];
              };
              packages.container = nix-bundle.bundlers.nix-bundle {
                inherit system program;
              };
            }
      );
}
