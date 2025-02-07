{ pkgs ? import (import ../nix/sources.nix).nixpkgs {
    overlays = [ (_: _: { inherit (import ../nix/sources.nix); }) (import ../nix/overlay.nix { }) ];
  }
}:
pkgs.mkShell {
  name = "helm-scripts-shell";
  buildInputs = with pkgs; [
    coreutils
    git
    helm-docs
    kubernetes-helm-wrapped
    semver-tool
    yq-go
    jq
  ];
}
