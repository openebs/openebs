use semver::Version;

pub use constants::{DS_CONTROLLER_REVISION_HASH_LABEL_KEY, UMBRELLA_CHART_NAME};

pub use upgrade::common::constants::IO_ENGINE_LABEL;
/// The oldest supported helm chart version.
pub const UMBRELLA_CHART_VERSION_LOWERBOUND: Version = Version::new(3, 0, 0);
/// The env variable name used by Helm to specify the storage medium for helm release data.
pub const HELM_STORAGE_DRIVER_ENV: &str = "HELM_DRIVER";
/// The versions from which upgrade to a newer release requires that partial rebuild be disabled.
pub const PARTIAL_REBUILD_DISABLE_EXTENTS: (Version, Version) =
    (Version::new(3, 7, 0), Version::new(3, 10, 0));
/// The size of the data payload for paginated network API responses.
pub const HTTP_DATA_PAGE_SIZE: usize = 500;
/// Version instance for release 4.0.0.
pub const FOUR_DOT_O: Version = Version::new(4, 0, 0);
