---
globs: "**/*.swift"
---
- Use `@MainActor` for ViewModels and Services that touch UI
- `APIClient` is an `actor` — always `await` from @MainActor contexts
- Prefer `async let` for parallel requests
- Never force unwrap — use `guard let` or nil coalescing
