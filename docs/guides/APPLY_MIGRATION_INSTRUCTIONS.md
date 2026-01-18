# How to Apply the Database Migration

The database migration needs to be applied manually through the Supabase Dashboard. Follow these steps:

## Steps to Apply Migration

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe
   - Click on "SQL Editor" in the left sidebar

2. **Create New Query**
   - Click the "New query" button (or it may already be on a new query page)

3. **Copy Migration SQL**
   - Open the file: `migrations/001_token_blacklist_and_audit_logs.sql`
   - Select all content (Cmd+A)
   - Copy (Cmd+C)

4. **Paste into SQL Editor**
   - Click in the SQL editor area in Supabase
   - Paste the migration SQL (Cmd+V)

5. **Run the Migration**
   - Click the green "Run" button (bottom right of editor)
   - Wait for execution to complete

6. **Verify Success**
   - You should see "Success. No rows returned" or similar message
   - Check the Results tab to confirm no errors

## What This Migration Creates

✅ **token_blacklist** table
- Stores revoked JWT tokens
- Prevents token reuse after logout
- Auto-cleanup function included

✅ **audit_logs** table
- Tracks all authentication events
- Logs IP addresses, user agents
- Success/failure tracking

✅ **Indexes** for fast queries
- JTI lookups
- User-based queries
- Time-based searches

✅ **Row Level Security (RLS) policies**
- Users can only see their own audit logs
- Service role has full access

✅ **Permissions**
- Authenticated users can insert/read
- Service role has full control

## After Migration

Once the migration is applied successfully, Sprint 1 will be complete!

You can verify the tables exist by running:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('token_blacklist', 'audit_logs');
```

Expected result:
```
 table_name
---------------
 token_blacklist
 audit_logs
```

## Troubleshooting

**If you get a "table already exists" error:**
- This is OK! It means the migration was already applied
- You can verify the tables exist using the query above

**If you get a "permission denied" error:**
- Make sure you're logged in to Supabase
- Ensure you have admin access to this project

**If you get a "users table not found" error:**
- The migration references the `users` table
- Make sure your users table exists first
- If you're using a different table name, update the migration SQL

## Need Help?

The full migration file is located at:
`/Users/kevin/Downloads/shredders/migrations/001_token_blacklist_and_audit_logs.sql`
