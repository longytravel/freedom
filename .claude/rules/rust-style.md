---
paths: ["core/**/*.rs"]
---

# Rust style rules

## Hard rules
- `cargo fmt` and `cargo clippy --all-targets -- -D warnings` must pass before commit.
- No `unsafe` without a `// SAFETY:` comment explaining the invariant.
- No `.unwrap()` or `.expect()` outside of tests and `main()`. Use `?` and proper error types.
- Public items have `///` doc comments.

## Soft preferences
- `thiserror` for library error types; `anyhow` only in binaries.
- Prefer `&[T]` and `&str` in function arguments over owned types when the function doesn't need ownership.
- No `mod.rs` files — use `mod_name.rs` + `mod_name/` folder.
