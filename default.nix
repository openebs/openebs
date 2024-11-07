{ system ? null
, allInOne ? true
, incremental ? false
, static ? false
, img_tag ? ""
, tag ? ""
, img_org ? ""
, product_prefix ? ""
, rustFlags ? ""
}:
let
  sources = import ./nix/sources.nix;
  hostSystem = (import sources.nixpkgs { }).hostPlatform.system;
  pkgs = import sources.nixpkgs {
    overlays = [ (_: _: { inherit sources; }) (import ./nix/overlay.nix { inherit allInOne incremental static img_tag tag img_org product_prefix rustFlags; }) (import sources.rust-overlay) ];
    system = if system != null then system else hostSystem;
  };
in
pkgs
