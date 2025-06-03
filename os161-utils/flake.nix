{
  description = "A Nix shell for os161-utils";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
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
        echo "Creating a temporary FHS environment for os161-utils..."

        export OS161_TEMP_DIR=$(mktemp -d)
        trap "rm -rf $OS161_TEMP_DIR" EXIT

        # Create the top-level /usr/local structure
        mkdir -p "$OS161_TEMP_DIR/usr/local"

        # Symlink EVERYTHING from the package's usr/local into our fake one
        ln -s ${os161Utils}/usr/local/* "$OS161_TEMP_DIR/usr/local/"

        # Add the bin directory to the PATH
        export PATH="$OS161_TEMP_DIR/usr/local/bin:$PATH"

        # ⭐️ ADD THIS LINE: Tell bmake where to find its system files.
        export MAKESYSPATH="$OS161_TEMP_DIR/usr/local/share/mk"

        echo "Done. The os161 toolchain is now available."
        echo ""
      '';
    };
  };
}
