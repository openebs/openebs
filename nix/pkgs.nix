let
  sources = import ./sources.nix;
in
import sources.nixpkgs {
  overlays = [ (_: _: { inherit sources; }) (import ./overlay.nix { }) (import sources.rust-overlay) ];
}
