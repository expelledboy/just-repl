{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            just
            bash
            jq
            fzf
            (bats.withLibraries (libexec: with libexec; [
              bats-support
              bats-assert
            ]))
          ];
        };
      }
    );
}
