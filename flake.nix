{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    inputs@{ ... }:
    let
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
      };

      NanoKVM-USB-browser =
        {
          stdenv,
          nodejs,
          pnpm,
        }:

        # This derivation just produces essentially what's in the upstream
        # browser release zip. Could just as well fetch and unpack that, but
        # the scenario was "what if upstream goes away" so we'd like to be able
        # to build our own version
        stdenv.mkDerivation (finalAttrs: {
          pname = "NanoKVM-USB-browser";
          version = inputs.self.rev;

          src = ./browser;

          nativeBuildInputs = [
            nodejs
            pnpm.configHook
          ];

          pnpmDeps = pnpm.fetchDeps {
            inherit (finalAttrs) pname version src;
            fetcherVersion = 2;
            # This needs to be updated manually when the source changes, set it
            # to pkgs.lib.fakeHash to compute the new one.
            hash = "sha256-bFY6121bnhfxhkfgXxL1T+9rsqDTWbaRlG0qDVcA878=";
          };
          buildPhase = ''
            runHook preBuild

            pnpm build

            runHook postBuild
          '';
          installPhase = ''
            runHook preInstall

            cp -r dist $out

            runHook postInstall
          '';
        });

      drv = pkgs.callPackage NanoKVM-USB-browser { };

      runner = pkgs.writeShellApplication {
        name = "run-NanoKVM";
        runtimeInputs = [ pkgs.nodePackages.http-server ];
        text = ''
          http-server -p 8080 -a localhost ${drv}
        '';
      };
    in
    {
      packages.x86_64-linux.default = drv;
      apps.x86_64-linux.default = {
        type = "app";
        program = pkgs.lib.getExe runner;
      };
    };
}
