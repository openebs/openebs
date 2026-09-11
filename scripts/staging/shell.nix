{ pkgs ? import (import ../../nix/sources.nix).nixpkgs {
    overlays = [ (_: _: { inherit (import ../../nix/sources.nix); }) (import ../../nix/overlay.nix { }) ];
  }
}:
pkgs.mkShellNoCC {
  name = "staging-shell";
  buildInputs = with pkgs; [
    oras
    crane
    yq-go
    jq
    # Used to verify the signature and SBOM attestation of the mirrored images.
    cosign
  ] ++ pkgs.lib.optional (builtins.getEnv "IN_NIX_SHELL" == "pure" && pkgs.system != "aarch64-darwin") [
    docker
    git
    curl
    nix
    kubernetes-helm-wrapped
    cacert
  ];
}
