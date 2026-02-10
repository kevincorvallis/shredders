---
globs: "src/app/api/**"
---
- Dual auth: check custom JWT first, fall back to Supabase Bearer token
- Foreign keys use `users.id`, NOT `auth_user_id`
- Use `withCache` for GET endpoints (10min default)
