{ pkgs }:
let
  lib = pkgs.lib;
in
rec {
  makeRustTarget = platform: pkgs.rust.toRustTargetSpec platform;
  rust_default = { override ? { } }: rec {
    nightly_pkg = pkgs.rust-bin.nightly."2024-10-30";
    stable_pkg = pkgs.rust-bin.stable."1.82.0";

    nightly = nightly_pkg.default.override (override);
    stable = stable_pkg.default.override (override);

    nightly_src = nightly_pkg.rust-src;
    release_src = stable_pkg.rust-src;
  };
  default = rust_default { };
  default_src = rust_default {
    override = { extensions = [ "rust-src" ]; };
  };
  static-arch = { target }: rust_default {
    override = { targets = [ "${target}" ]; };
  };

  rustPlatformDeps = { target, sources }: rec {
    naersk_package = channel: pkgs.callPackage sources.naersk {
      rustc = channel.stable;
      cargo = channel.stable;
    };
    os = platform: builtins.replaceStrings [ "${platform.qemuArch}-" ] [ "" ] platform.system;
    hostPlatform = "${pkgs.rust.toRustTargetSpec pkgs.pkgsStatic.hostPlatform}";
    targetPlatform = "${pkgs.rust.toRustTargetSpec pkgs.pkgsCross."${target}".hostPlatform}";
    pkgsTarget = if hostPlatform == targetPlatform then pkgs.pkgsStatic else pkgs.pkgsCross."${target}";
    pkgsTargetNative = if hostPlatform == targetPlatform then pkgs else if hostOs == targetOs then
      import sources.nixpkgs
        {
          config = { };
          overlays = [ ];
          system = "${pkgsTarget.system}";
        } else pkgs.pkgsCross."${target}";
    hostOs = os pkgs.hostPlatform;
    targetOs = os pkgs.pkgsCross."${target}".hostPlatform;
    naersk = naersk_package (static-arch {
      target = targetPlatform;
    });
    targetUpper = lib.toUpper (
      builtins.replaceStrings [ "-" ] [ "_" ] targetPlatform
    );
    check_assert =
      if (targetOs == "darwin") then
        if hostOs == "darwin" && hostPlatform != targetPlatform
        # maybe can be achieved used unstable-pkgs until the fixes drop on the stable channel/release.
        then lib.asserts.assertMsg (false) "Cross-compiling on darwin not supported yet"
        else lib.asserts.assertMsg (pkgs.hostPlatform.isDarwin) "${targetOs} binaries can only be built on darwin (ie not ${hostOs})"
      else lib.asserts.assertMsg (pkgs.hostPlatform.isLinux) "${targetOs} binaries can only be built on linux (ie not ${hostOs})";
  };
  rustBuilderOpts = { rustPlatformDeps }: rustPlatformDeps // {
    preBuild = lib.optionalString (rustPlatformDeps.pkgsTarget.hostPlatform.isWindows) ''
      export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS="-C link-args=''$(echo $NIX_LDFLAGS | tr ' ' '\n' | grep -- '^-L' | tr '\n' ' ')"
      export NIX_LDFLAGS=
      export NIX_LDFLAGS_FOR_BUILD=
    '';
    addPreBuild = "";
    nativeBuildInputs = with pkgs;
      [ pkg-config protobuf paperclip which git ] ++
        [ rustPlatformDeps.pkgsTarget.stdenv.cc ] ++
        lib.optional (rustPlatformDeps.pkgsTarget.hostPlatform.isDarwin)
          [
            (rustPlatformDeps.pkgsTarget.libiconv.override {
              enableStatic = true;
              enableShared = false;
            })
          ];
    addNativeBuildInputs = [ ];
    buildInputs = if (rustPlatformDeps.pkgsTarget.hostPlatform.isWindows) then with rustPlatformDeps.pkgsTargetNative.windows; [ mingw_w64_pthreads pthreads ] else [ ];
  };
  rustPackageBuilder = { rustBuildOpts, name, src, release, version, singleStep, GIT_VERSION, GIT_VERSION_LONG }: rustBuildOpts.naersk.buildPackage {
    inherit name release src version singleStep GIT_VERSION_LONG GIT_VERSION;

    preBuild = rustBuildOpts.preBuild + rustBuildOpts.addPreBuild;
    cargoBuildOptions = attrs: attrs ++ rustBuildOpts.buildOptions;
    nativeBuildInputs = rustBuildOpts.nativeBuildInputs ++ rustBuildOpts.addNativeBuildInputs;
    buildInputs = rustBuildOpts.buildInputs;

    doCheck = false;
    check_assert = rustBuildOpts.check_assert;
    usePureFromTOML = true;
    CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
    CARGO_BUILD_TARGET = rustBuildOpts.targetPlatform;
    "CARGO_TARGET_${rustBuildOpts.targetUpper}_LINKER" = with rustBuildOpts.pkgsTarget.stdenv;
      if (rustBuildOpts.check_assert) then "${cc}/bin/${cc.targetPrefix}cc" else null;
    #${if pkgs.hostPlatform.isDarwin then "LIBCLANG_PATH" else null} = "${rustBuildOpts.pkgsTarget.llvmPackages.libclang.lib}/lib";
  };
}
