# It would be cool to produce OCI images instead of docker images to
# avoid dependency on docker tool chain. Though the maturity of OCI
# builder in nixpkgs is questionable which is why we postpone this step.

{ pkgs, dockerTools, lib, openebs, busybox, gnupg, kubernetes-helm-wrapped, semver-tool, yq-go, runCommand, sourcer, img_tag ? "", img_org ? "" }:
let
  repo-org = if img_org != "" then img_org else "${builtins.readFile (pkgs.runCommand "repo_org" {
    buildInputs = with pkgs; [ git ];
   } ''
    export GIT_DIR="${sourcer.git-src}/.git"
    cp ${sourcer.repo-org}/git-org-name.sh .
    patchShebangs ./git-org-name.sh
    ./git-org-name.sh ${sourcer.git-src} --case lower --remote origin > $out
  '')}";
  helm_chart = sourcer.whitelistSource ../../.. [ "charts" "scripts/helm" "mayastor/scripts/utils" ];
  image_suffix = { "release" = ""; "debug" = "-debug"; "coverage" = "-coverage"; };
  tag = if img_tag != "" then img_tag else openebs.version;
  build-openebs-image = { pname, buildType, package, extraCommands ? '''', copyToRoot ? [ ], config ? { } }:
    dockerTools.buildImage {
      inherit extraCommands tag;
      created = "now";
      name = "${repo-org}/openebs-${pname}${image_suffix.${buildType}}";
      copyToRoot = [ package ] ++ copyToRoot;
      config = {
        Entrypoint = [ package.binary ];
      } // config;
    };
  tagged_helm_chart = runCommand "tagged_helm_chart"
    {
      nativeBuildInputs = [ kubernetes-helm-wrapped helm_chart semver-tool yq-go ];
    } ''
        mkdir -p build && cp -drf ${helm_chart}/* build

        chmod -R +w build/mayastor/scripts/utils
        chmod -R +w build/charts
        chmod -R +w build/scripts/helm
        patchShebangs build/scripts/helm/update-chart-version.sh
        patchShebangs build/mayastor/scripts/utils/log.sh
        patchShebangs build/mayastor/scripts/utils/yaml.sh

        if [ -L build/chart/kubectl-openebs ]; then
          rm build/chart/kubectl-openebs
        fi

        # if tag is not semver just keep whatever is checked-in
        # todo: handle this properly?
        # Script doesn't need to be used with main branch `--alias-tag <main-branch-style-tag>`.
        # The repo chart is already prepared.

        # TODO: Requires a script like publish-chart-yaml.sh
    #    if [[ "$(semver validate ${tag})" == "valid" ]] &&
    #      [[ ! ${tag} =~ ^(v?[0-9]+\.[0-9]+\.[0-9]+-0-(main|release)-unstable(-[0-9]+){6}-0)$ ]]; then
    #      CHART_FILE=build/charts/Chart.yaml build/scripts/helm/update-chart-version.sh --app-version ${tag} --chart-version ${tag} --localpv-provisioner-version 4.2.0 --zfs-localpv-version 2.7.1 --lvm-localpv-version 1.6.2 --mayastor-version 2.8.0
    #    fi

        chmod -w build/charts
        chmod -w build/charts/*.yaml

        mkdir -p $out && cp -drf --preserve=mode build/charts $out/chart
  '';
  build-upgrade-image = { buildType, name }:
    build-openebs-image rec{
      inherit buildType;
      package = openebs.${buildType}.upgrade.${name};
      copyToRoot = [ kubernetes-helm-wrapped busybox tagged_helm_chart yq-go ];
      pname = package.pname;
      config = {
        Env = [ "CHART_DIR=/chart" ];
      };
    };

in
let
  build-upgrade-images = { buildType }: {
    job = build-upgrade-image {
      inherit buildType;
      name = "job";
    };
  };
in
let
  build-images = { buildType }: {
    upgrade = build-upgrade-images { inherit buildType; } // {
      recurseForDerivations = true;
    };
  };
in
{
  release = build-images { buildType = "release"; };
  debug = build-images { buildType = "debug"; };
}
