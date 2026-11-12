{
  description = "Development environment for the IaC Reveal.js presentation host";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              actionlint
              ansible
              ansible-lint
              curl
              docker-client
              docker-compose
              gnumake
              nodejs_22
              openssh
              shellcheck
              yamllint
            ];

            shellHook = ''
              echo "IaC presentation environment"
              echo "Run 'make help' to see the available commands."
            '';
          };
        });
    };
}
