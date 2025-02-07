{ pkgs ? import (import ../../nix/sources.nix).nixpkgs {
    overlays = [ (_: _: { inherit (import ../../nix/sources.nix); }) (import ../../nix/overlay.nix { }) ];
  }
}:
let
  inPureNixShell = builtins.getEnv "IN_NIX_SHELL" == "pure";
in
pkgs.mkShell {
  name = "k8s-cluster-shell";
  buildInputs = with pkgs; [
    kubernetes-helm-wrapped
    kubectl
    kind
    jq
    nvme-cli
  ] ++ pkgs.lib.optional (inPureNixShell) [
    kmod
    procps
    docker
    util-linux
    sudo
  ];

  SUDO = "sudo";
  shellHook = ''
    if [ "${toString inPureNixShell}" == "1" ] && [ -f /run/wrappers/bin/sudo ]; then
      export SUDO=/run/wrappers/bin/sudo
    fi
  '';
}
