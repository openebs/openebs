{ pkgs ? import (import ../../nix/sources.nix).nixpkgs {
    overlays = [ (_: _: { inherit (import ../../nix/sources.nix); }) (import ../../nix/overlay.nix { }) ];
  }
}:
pkgs.mkShell {
  name = "staging-shell";
  buildInputs = with pkgs; [
    oras
    crane
    yq-go
    jq
  ];
}
