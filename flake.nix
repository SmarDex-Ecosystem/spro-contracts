{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    foundry = {
      url = "github:shazow/foundry.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    solc = {
      url = "github:hellwolf/solc.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    medusa.url= "github:crytic/medusa";
  };

  outputs = { self, nixpkgs, flake-utils, foundry, solc, medusa }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ foundry.overlay solc.overlay ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            foundry-bin
            just
            lcov
            lintspec
            nodejs_20
            slither-analyzer
            solc_0_8_26
            (solc.mkDefault pkgs solc_0_8_26)
            trufflehog
            typescript
            uv
          ] ++ [ medusa.packages.${system}.medusa ];

          shellHook = ''
            set -a; source .env; set +a
            npm i
            # forge soldeer install # too slow for now
          '';
        };
      });
}
