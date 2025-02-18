{ makeRustPlatform
, pkg-config
, protobuf
, sources
, channel
, pkgs
, clang
, llvmPackages
, openssl
, git
, gitVersions
, paperclip
, which
, utillinux
, sourcer
  # with allInOne set to true all components are built as part of the same "cargo build" derivation
  # this allows for a quicker build of all components but slower single components
  # with allInOne set to false each component gets its own "cargo build" derivation allowing for faster
  # individual builds but making the build of all components at once slower
, allInOne ? true
  # EXPERIMENTAL incremental allows for faster incremental builds as the build dependencies are cached
  # it might make the initial build slightly slower as it's done in two steps
  # for this we use naersk which is not as fully fledged as the builtin rustPlatform so it should only be used
  # for development and not for CI
, incremental ? false
, static ? false
, rustFlags
}:
let
  stable_channel = {
    rustc = channel.default.stable;
    cargo = channel.default.stable;
  };
  static-target = pkgs.rust.toRustTargetSpec pkgs.pkgsStatic.hostPlatform;
  static-channel = channel.rust_default {
    override = { targets = [ "${static-target}" ]; };
  };
  rustPlatform =
    if static then
      pkgs.pkgsStatic.makeRustPlatform
        {
          rustc = static-channel.stable;
          cargo = static-channel.stable;
        } else
      makeRustPlatform {
        rustc = stable_channel.rustc;
        cargo = stable_channel.cargo;
      };
  naersk = pkgs.callPackage sources.naersk {
    rustc = stable_channel.rustc;
    cargo = stable_channel.cargo;
  };
  PROTOC = "${protobuf}/bin/protoc";
  PROTOC_INCLUDE = "${protobuf}/include";
  version = gitVersions.version;
  src_list = [
    "Cargo.lock"
    "Cargo.toml"
    "plugin"
    "mayastor/dependencies/control-plane/openapi/Cargo.toml"
    "mayastor/dependencies/control-plane/openapi/build.rs"
    "mayastor/dependencies/control-plane/openapi/src/lib.rs"
    "mayastor/dependencies/control-plane/openapi/templates"
    "mayastor/dependencies/control-plane/control-plane/plugin"
    "mayastor/dependencies/control-plane/control-plane/rest/openapi-specs"
    "mayastor/dependencies/control-plane/scripts/rust/generate-openapi-bindings.sh"
    "mayastor/dependencies/control-plane/scripts/rust/branch_ancestor.sh"
    "mayastor/dependencies/control-plane/common"
    "mayastor/dependencies/control-plane/utils/dependencies/apis/events"
    "mayastor/dependencies/control-plane/utils/dependencies/apis/csi"
    "mayastor/dependencies/control-plane/utils/dependencies/apis/io-engine"
    "mayastor/dependencies/control-plane/utils/dependencies/.git"
    "mayastor/dependencies/control-plane/utils/dependencies/prost-extend"
    "mayastor/dependencies/control-plane/utils/dependencies/event-publisher"
    "mayastor/dependencies/control-plane/utils/dependencies/git-version-macro"
    "mayastor/dependencies/control-plane/utils/dependencies/tracing-filter"
    "mayastor/dependencies/control-plane/utils/dependencies/version-info"
    "mayastor/dependencies/control-plane/utils/utils-lib"
    "mayastor/dependencies/control-plane/utils/hyper-body"
    "mayastor/dependencies/control-plane/utils/shutdown"
    "mayastor/dependencies/control-plane/utils/platform"
    "mayastor/dependencies/control-plane/utils/pstor"
    "mayastor/dependencies/control-plane/rpc"
    "mayastor/dependencies/control-plane/k8s/forward"
    "mayastor/dependencies/control-plane/k8s/proxy"
    "mayastor/k8s"
    "mayastor/console-logger"
    "mayastor/constants"
    "mayastor/dependencies/control-plane/k8s/operators"
  ];
  src = sourcer.whitelistSource ../../../. src_list;
  static_ssl = (pkgs.pkgsStatic.openssl.override {
    static = true;
  });
  hostTarget = pkgs.rust.toRustTargetSpec pkgs.hostPlatform;
  buildProps = rec {
    name = "extensions-${version}";
    inherit version src;
    GIT_VERSION_LONG = "${gitVersions.long}";
    GIT_VERSION = "${gitVersions.tag_or_long}";

    nativeBuildInputs = [ clang pkg-config git paperclip which protobuf ];
    buildInputs = [ llvmPackages.libclang openssl utillinux ];
    doCheck = false;
  };
  release_build = { "release" = true; "debug" = false; };
  flags =
    if builtins.stringLength rustFlags > 0
    then builtins.split " " rustFlags
    else if static
    then [ "-C" "target-feature=+crt-static" ]
    else [ ];
in
let
  build_with_naersk = { buildType, cargoBuildFlags }:
    naersk.buildPackage (buildProps // {
      release = release_build.${buildType};
      cargoBuildOptions = attrs: attrs ++ cargoBuildFlags;
      preBuild = ''
        # don't run during the dependency build phase
        if [ ! -f build.rs ]; then
          patchShebangs .mayastor/dependencies/control-plane/scripts/rust/
          .mayastor/dependencies/control-plane/scripts/rust/generate-openapi-bindings.sh --skip-git-diff
        fi
      '';
      doCheck = false;
      usePureFromTOML = true;
    });
  build_with_default = { buildType, cargoBuildFlags }:
    rustPlatform.buildRustPackage (buildProps // {
      inherit buildType cargoBuildFlags;
      preBuild = ''
        patchShebangs .mayastor/dependencies/control-plane/scripts/rust/
      '' + pkgs.lib.optionalString (static) ''
        # the rust builder from nixpkgks does not parse target and just uses the host target...
        export NIX_CC_WRAPPER_TARGET_HOST_${builtins.replaceStrings [ "-" ] [ "_" ] hostTarget}=
        export OPENSSL_STATIC=1
        export OPENSSL_LIB_DIR=${static_ssl.out}/lib
        export OPENSSL_INCLUDE_DIR=${static_ssl.dev}/include
      '';
      ${if flags == [ ] then null else "RUSTFLAGS"} = flags;
      cargoLock = {
        lockFile = ./Cargo.lock;
      };
    });
  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
  };
  builder =
    if static then build_with_default
    else if incremental then build_with_naersk else build_with_default;
  buildAllInOne = if static then false else allInOne;
in
{
  inherit PROTOC PROTOC_INCLUDE version src cargoDeps;

  build = { buildType, cargoBuildFlags ? [ ] }:
    if buildAllInOne then
      builder { inherit buildType; cargoBuildFlags = [ "-p kubectl-openebs" ]; }
    else
      builder { inherit buildType cargoBuildFlags; };
}
