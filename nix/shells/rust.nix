# The pinned rust toolchain only, eg: to update the Cargo.lock
{ pkgs ? import ../pkgs.nix, rust-profile ? "stable" }:
let
  channel = import ../../mayastor/nix/lib/rust.nix { inherit pkgs; };
  rust = channel.default_src.${rust-profile};
in
pkgs.mkShellNoCC {
  name = "rust-shell";
  buildInputs = [ rust ];
  passthru = { inherit rust; };
  # the toolchain's propagated cc setup hook sets these
  shellHook = ''
    unset CC
    unset AR
  '';
}
