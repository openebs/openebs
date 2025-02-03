pub use constants::{DS_CONTROLLER_REVISION_HASH_LABEL_KEY, UMBRELLA_CHART_NAME};
use semver::Version;
pub use upgrade::common::constants::IO_ENGINE_LABEL;
pub const UMBRELLA_CHART_VERSION_LOWERBOUND: Version = Version::new(3, 0, 0);
pub const HELM_STORAGE_DRIVER_ENV: &str = "HELM_DRIVER";
pub const PARTIAL_REBUILD_DISABLE_EXTENTS: (Version, Version) =
    (Version::new(3, 7, 0), Version::new(3, 10, 0));
