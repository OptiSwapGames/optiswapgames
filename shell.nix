{ pkgs ? import <nixpkgs> { } }:

with pkgs;

mkShell rec {
  
  buildInputs = [
    pkg-config
    nodejs
  ];
  
  nativeBuildInputs = [];
  
  LD_LIBRARY_PATH = lib.makeLibraryPath (buildInputs);

  shellHook = ''
  '';
}
