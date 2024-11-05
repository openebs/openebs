{ allInOne ? true
, incremental ? false
, static ? false
, img_tag ? ""
, tag ? ""
, img_org ? ""
, product_prefix ? ""
, rustFlags ? ""
}:
let
  config = import ./config.nix;
  img_prefix = if product_prefix == "" then config.product_prefix else product_prefix;
in
self: super: {
  sourcer = super.callPackage ./lib/sourcer.nix { };
  paperclip = super.callPackage ./../mayastor/dependencies/control-plane/nix/pkgs/paperclip { };
  channel = import ./lib/rust.nix { pkgs = super.pkgs; };
}
