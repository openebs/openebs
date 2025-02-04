{ stdenv, git, lib, pkgs, allInOne, incremental, static, sourcer, tag ? "", rustFlags }:
let
  versionDrv = import ../../lib/version.nix { inherit sourcer lib stdenv git tag; };
  version = builtins.readFile "${versionDrv}";
  gitVersions = {
    "version" = version;
    "long" = builtins.readFile "${versionDrv.long}";
    "tag_or_long" = builtins.readFile "${versionDrv.tag_or_long}";
  };
  project-builder =
    pkgs.callPackage ../openebs/cargo-project.nix {
      inherit sourcer gitVersions allInOne incremental static rustFlags;
    };
  installer = { pname, src, suffix ? "" }:
    stdenv.mkDerivation rec {
      inherit pname src;
      name = "${pname}-${version}";
      binary = "${pname}${suffix}";
      installPhase = ''
        mkdir -p $out/bin
        cp $src/bin/${pname} $out/bin/${binary}
      '';
    };

  components = { buildType, builder }: rec {
    kubectl-openebs = rec {
      recurseForDerivations = true;
      plugin_builder = { buildType, builder, cargoBuildFlags ? [ "-p kubectl-openebs" ] }: builder.build { inherit buildType cargoBuildFlags; };
      plugin_installer = { pname, src }: installer { inherit pname src; };
      plugin = plugin_installer {
        src =
          if allInOne then
            plugin_builder { inherit buildType builder; cargoBuildFlags = [ "-p kubectl-openebs" ]; }
          else
            plugin_builder { inherit buildType builder; cargoBuildFlags = [ "--bin kubectl-openebs" ]; };
        pname = "kubectl-openebs";
      };
    };
  };
in
{
  PROTOC = project-builder.PROTOC;
  PROTOC_INCLUDE = project-builder.PROTOC_INCLUDE;
  inherit version gitVersions project-builder;

  release = components { builder = project-builder; buildType = "release"; };
  debug = components { builder = project-builder; buildType = "debug"; };
}
