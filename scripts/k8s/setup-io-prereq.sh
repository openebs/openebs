#!/usr/bin/env bash

set -e

HUGE_PAGES=2048
HUGE_PAGES_OVERRIDE=
SETUP_ZFS=
SETUP_LVM=
SETUP_MAYASTOR=
DRY_RUN=
SUDO=${SUDO:-"sudo"}
SYSCTL="sysctl"
MODPROBE="modprobe"
APTGET="apt-get"
LSMOD="lsmod"
UPDATED=0
INSTALLED_KMODS=
DISTRO=

help() {
  cat <<EOF
Usage: $(basename "$0") [COMMAND] [OPTIONS]

Options:
  -h, --help                            Display this text.
  --hugepages         <num>             Add <num> 2MiB hugepages.
  --zfs                                 Install ZFS utilities.
  --lvm                                 Install LVM utilities and load required modules.
  --mayastor                            Setup pre-requisites, install and load required modules.

Examples:
  $(basename "$0") --mayastor --hugepages 2048 --zfs
EOF
}

echo_stderr() {
  echo -e "${1}" >&2
}

die() {
  local _return="${2:-1}"
  echo_stderr "$1"
  exit "${_return}"
}

setup_hugepages() {
  $SUDO $SYSCTL -w vm.nr_hugepages="$1"
}

nvme_ana_check() {
  cat /sys/module/nvme_core/parameters/multipath
}

distro() {
  if [ -z "$DISTRO" ]; then
    DISTRO=$(cat /etc/os-release | awk -F= '/^NAME=/ {print $2}' | tr -d '"')
  fi
  echo "$DISTRO"
}

install_kernel_modules_nsup() {
  die "Installing extra kernel modules is not supported for $1"
}

update_apt() {
  if [ "$UPDATED" -eq 0 ]; then
    $SUDO $APTGET update
    UPDATED=1
  fi
}
apt_install() {
  update_apt
  if $SUDO $APTGET install -y $@; then
    echo "Successfully installed $@"
  else
    die "Failed to install $@"
  fi
}

kmod_loaded() {
  local mod="${1//-/_}"
  # either builtin or as a module
  [ -d "/sys/module/$mod" ] || $LSMOD | grep -q "$mod"
}

install_kernel_modules() {
  if [ "$INSTALLED_KMODS" = "yes" ]; then
    return 0;
  fi

  case "$(distro)" in
    Ubuntu)
      apt_install linux-modules-extra-$(uname -r)
      INSTALLED_KMODS="yes"
      ;;
    NixOS | *)
      install_kernel_modules_nsup "$(distro)"
      ;;
  esac
}
modprobe_kmod() {
  $SUDO $MODPROBE $@
}

load_kernel_module() {
  if kmod_loaded $1; then
    echo "$1 kernel module already installed"
    return 0;
  fi

  if ! modprobe_kmod $1 -q; then
    # perhaps we're missing the modules?
    install_kernel_modules
    # now we can give it another go as our module may be available
    if ! modprobe_kmod $1; then
      die "Failed to load $1 kernel module!"
    fi
  fi

  echo "$1 kernel module installed"
}

install_zfs() {
  if ! command -v zfs &>/dev/null; then
    DISTRO="$(distro)"
    case "$DISTRO" in
      Ubuntu)
        apt_install zfsutils-linux
        ;;
      NixOS | *)
        die "Installation of zfsutils-linux not supported for $DISTRO"
        ;;
    esac
  else
    echo "ZFS utilities are already installed"
  fi
}

install_lvm() {
  if ! command -v lvm &>/dev/null; then
    DISTRO="$(distro)"
    case "$DISTRO" in
      Ubuntu)
        apt_install lvm2
        ;;
      NixOS | *)
        die "Installation of lvm2 not supported for $DISTRO"
        ;;
    esac
  else
    echo "LVM utilities are already installed"
  fi
}

load_lvm_modules() {
  # Load LVM snapshot and thin provisioning modules
  load_kernel_module dm-snapshot
  load_kernel_module dm-thin-pool
}

setup_mayastor() {
  load_kernel_module nvme-tcp
  if [ "$(nvme_ana_check)" != "Y" ]; then
    echo_stderr "NVMe multipath support is NOT enabled!"
  else
    echo "NVMe multipath support IS enabled"
  fi

  if [ -n "$HUGE_PAGES" ]; then
    pages=$($SYSCTL -b vm.nr_hugepages)

    if [ "$HUGE_PAGES" -gt "$pages" ]; then
      setup_hugepages "$HUGE_PAGES"
    else
      if [ "$HUGE_PAGES" -lt "$pages" ] && [ -n "$HUGE_PAGES_OVERRIDE" ]; then
        echo "Overriding hugepages from $pages to $HUGE_PAGES, as requested"
        setup_hugepages "$HUGE_PAGES"
      else
        echo "Current hugepages ($pages) are sufficient"
      fi
    fi
  fi
}

while [ "$#" -gt 0 ]; do
  case $1 in
    -h|--help)
      help
      exit 0
      ;;
    --hugepages)
      SETUP_MAYASTOR="y"
      shift
      test $# -lt 1 && die "Missing hugepage number"
      HUGE_PAGES=$1
      shift
      ;;
    --hugepages-override)
      SETUP_MAYASTOR="y"
      shift
      test $# -lt 1 && die "Missing hugepage number"
      HUGE_PAGES_OVERRIDE="y"
      HUGE_PAGES=$1
      shift
      ;;
    --mayastor)
      SETUP_MAYASTOR="y"
      shift
      ;;
    --zfs)
      SETUP_ZFS="y"
      shift
      ;;
    --lvm)
      SETUP_LVM="y"
      shift
      ;;
    --dry-run)
      if [ -z "$DRY_RUN" ]; then
        DRY_RUN="--dry-run"
        SUDO="echo $SUDO"
      fi
      shift
      ;;
    *)
      die "Unknown argument $1!"
      ;;
  esac
done

if [ -n "$SETUP_MAYASTOR" ]; then
  setup_mayastor
fi

if [ -n "$SETUP_ZFS" ]; then
  install_zfs
fi

if [ -n "$SETUP_LVM" ]; then
  install_lvm
  load_lvm_modules
fi
