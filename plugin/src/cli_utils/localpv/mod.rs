pub mod hostpath;
pub mod lvm;
pub mod zfs;

use byte_unit::Byte;

/// Converts bytes into human-readable capacity unit.
pub(crate) fn adjust_bytes(bytes: u128) -> String {
    let byte = Byte::from(bytes);
    let adjusted_byte = byte.get_appropriate_unit(true);
    format!("{adjusted_byte:.2}")
}
