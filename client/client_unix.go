// +build linux freebsd solaris openbsd

package client

// DefaultOpenEBSHost defines os specific default if OPENEBS_HOST is unset
const DefaultOpenEBSHost = "unix:///var/run/openebs.sock"
