{ lib, pkgs, sources, openebs, incremental, channel }:
let
  src = openebs.project-builder.src;
  version = openebs.version;
  GIT_VERSION_LONG = openebs.gitVersions.long;
  GIT_VERSION = openebs.gitVersions.tag_or_long;
  singleStep = !incremental;
  preBuildOpenApi = ''
    # don't run during the dependency build phase
    if [ ! -f build.rs ]; then
      patchShebangs ./mayastor/dependencies/control-plane/scripts/rust/
      ./mayastor/dependencies/control-plane/scripts/rust/generate-openapi-bindings.sh --skip-git-diff
    fi
  '';
  buildKubectlOpenebs = { target, release, addBuildOptions ? [ ] }:
    let
      platformDeps = channel.rustPlatformDeps { inherit target sources; };
      rustBuildOpts = channel.rustBuilderOpts { rustPlatformDeps = platformDeps; } // {
        buildOptions = [ "-p" "kubectl-openebs" ] ++ addBuildOptions;
        addPreBuild = preBuildOpenApi;
      };
      name = "kubectl-openebs";
    in
    channel.rustPackageBuilder {
      inherit name release src version singleStep GIT_VERSION_LONG GIT_VERSION rustBuildOpts;
    };

  os-components = { release ? false, windows ? null, linux ? null, darwin ? null }: {
    recurseForDerivations = true;
    ${if windows != null then "windows-gnu" else null } = {
      kubectl-openebs = buildKubectlOpenebs {
        inherit release;
        target = windows;
        addBuildOptions = [ "--no-default-features" "--features" "tls" ];
      };
    };
    ${if linux != null then "linux-musl" else null } = {
      kubectl-openebs = buildKubectlOpenebs {
        inherit release;
        target = linux;
      };
    };
    ${if darwin != null then "apple-darwin" else null } = {
      kubectl-openebs = buildKubectlOpenebs {
        inherit release;
        target = darwin;
      };
    };
  };
  os-targets = { release ? false }: {
    aarch64 = os-components {
      inherit release;
      linux = "aarch64-multiplatform-musl";
      darwin = "aarch64-darwin";
    };
    x86_64 = os-components {
      inherit release;
      windows = "mingwW64";
      linux = "musl64";
      darwin = "x86_64-darwin";
    };
  };

  components = { release ? false }: os-targets { inherit release; } // (os-targets { inherit release; })."${pkgs.hostPlatform.qemuArch}";
in
{
  inherit version;

  release = components { release = true; };
  debug = components { release = false; };
}
