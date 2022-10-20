{ dream2nix-lib, nix-filter, nodejs }:
# FIXME: pass in the typescript-sdk
# or maybe we use relative paths in package.json?

let
  outputs = (dream2nix-lib.makeOutputs {
    source = nix-filter.lib.filter {
      root = ../..;
      # FIXME: get this working
      include = [ "./decookies/typescript-vm" "./sdks/typescript-sdk" ];
    };

    settings =
      [{ subsystemInfo.nodejs = (builtins.substring 0 2 nodejs.version); }];
  });
in

outputs.packages.cookie-game