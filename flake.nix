{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    strongdm-releases = {
      flake = false;
      url = "https://app.uk.strongdm.com/release?software=sdm-cli";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs: let
    releases = import ./releases.nix inputs;
  in
    flake-utils.lib.eachDefaultSystem (system: let
      inherit (nixpkgs.legacyPackages.${system}) callPackage;
      inherit (callPackage ./lib.nix {}) mkPackage;
    in {
      packages = let
        packages' =
          builtins.mapAttrs
          (_: versions:
            builtins.foldl'
            (prev: version: prev // {${builtins.replaceStrings ["."] ["_"] version} = mkPackage versions.${version};})
            {}
            (builtins.attrNames versions))
          releases.${system};
      in
        builtins.foldl'
        (prev: name:
          prev
          // {
            ${name} = let
              value = packages'.${name} or {};

              latest =
                builtins.head
                (builtins.sort
                  (a: b: (builtins.compareVersions a b) > 0)
                  (builtins.attrNames value));
            in
              value // {latest = value.${latest};};
          })
        {}
        (builtins.attrNames packages');

      nixosModules = rec {
        strongdm = import ./module.nix {
          package = self.packages.${system}.sdm-cli.latest;
        };

        default = strongdm;
      };
    });
}
