{
  description = "speedata Publisher: database publishing software";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;
        version = lib.head (
          builtins.match ".*publisher_version=([^\n]*).*" (builtins.readFile ./version)
        );
        luahbtex = pkgs.texlivePackages.luahbtex;
        platform = pkgs.stdenv.hostPlatform;
        goos = if platform.isDarwin then "darwin" else platform.parsed.kernel.name;
        goarch = platform.go.GOARCH or (if platform.isAarch64 then "arm64" else "amd64");
      in
      {
        packages = rec {
          default = speedata-publisher;
          speedata-publisher = pkgs.buildGoModule {
            pname = "speedata-publisher";
            inherit version;

            src = self;
            modRoot = "src/go";
            vendorHash = "sha256-ZEc8sG3cGsffZ+ctH9Yf8QcnZXS28zOOp++itsE9eQ4=";

            buildInputs = [ pkgs.lua5_3 ];

            # `sphelper distcustom` does the whole build: sp (compiled with
            # dest=custom, so libdir/srcdir point at the final store paths),
            # libsplib.so and luaglue.so, plus the share/sw directory layout.
            # LUATEX_BIN is left unset: instead of shipping the prebuilt
            # sdluatex we symlink luahbtex from TeX Live, which sp falls
            # back to (and drives via --ini --lua=sdini.lua).
            buildPhase = ''
              runHook preBuild

              root=$(cd ../.. && pwd)

              go build -o sphelper-bin speedatapublisher/sphelper/sphelper

              export SP_BUILDDIR_BIN=$out/bin SP_DESTDIR_BIN=$out/bin
              export SP_BUILDDIR_SHARE=$out/share SP_DESTDIR_SHARE=$out/share
              export SP_BUILDDIR_SW=$out/sw SP_DESTDIR_SW=$out/sw
              export CGO_CFLAGS="-I${pkgs.lua5_3}/include"
              ${lib.optionalString platform.isDarwin ''export CGO_LDFLAGS="-undefined dynamic_lookup"''}
              ${lib.optionalString (!platform.isDarwin) ''export CC_${goarch}_${goos}=$CC''}

              ./sphelper-bin --basedir "$root" distcustom ${goos}/${goarch}

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              for f in libsplib.so luaglue.so; do
                test -f "$out/share/lib/$f" || { echo "$f missing in $out/share/lib" >&2; exit 1; }
              done
              ln -s ${luahbtex}/bin/luahbtex $out/bin/luahbtex
              runHook postInstall
            '';

            doCheck = false;

            meta = {
              description = "Database publishing software with XML layout descriptions";
              homepage = "https://www.speedata.de/";
              license = lib.licenses.agpl3Only;
              mainProgram = "sp";
            };
          };
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/sp";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ self.packages.${system}.default ];
        };
      }
    );
}
