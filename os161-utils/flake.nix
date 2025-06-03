{
  description = "A Nix shell for os161-utils";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};

    os161Utils = pkgs.stdenv.mkDerivation {
      pname = "os161-utils";
      version = "2.0.8-4";

      src = pkgs.fetchurl {
        url = "http://www.cse.unsw.edu.au/~cs3231/os161-files/os161-utils_2.0.8-4.deb";
        sha256 = "0blnhzkj1m5k3d5x615gqr32vsdz2zfw4484phf5r4jmkf4f9hik";
      };

      nativeBuildInputs = [pkgs.dpkg pkgs.autoPatchelfHook];

      buildInputs = with pkgs; [
        glibc
        ncurses
        libmpc
        mpfr
        gmp
      ];

      unpackPhase = ''
        mkdir -p $out
        dpkg-deb -x "$src" "$out"
      '';

      installPhase = ''
        find $out/usr/local/bin -type f -exec chmod +x {} +
      '';

      dontStrip = true;
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [os161Utils];
      shellHook = ''
        # Creates temp dir for OS161 utils so all required files are
        # in their required relative place
        export OS161_TEMP_DIR=$(mktemp -d)
        # Cleans the temp dir on exit
        trap "rm -rf $OS161_TEMP_DIR" EXIT
        mkdir -p "$OS161_TEMP_DIR/usr/local/bin"
        # Adds utils to PATH
        ln -s ${os161Utils}/usr/local/bin/* "$OS161_TEMP_DIR/usr/local/bin/"
        export PATH="$OS161_TEMP_DIR/usr/local/bin:$PATH"
      '';
    };
  };
}
