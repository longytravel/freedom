//! Freedom backtest engine core.
//!
//! Empty stub. First functional code lands with the initial data-ingest spec.

/// Placeholder so `cargo test` has something to run and CI stays green.
#[must_use]
pub fn version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn version_is_defined() {
        assert!(!version().is_empty());
    }
}
