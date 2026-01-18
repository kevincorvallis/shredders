# MCP Server Setup Guide

I've created the MCP server configuration at `~/.claude/config.json` with two servers:

## 1. PostgreSQL (Supabase) Server
Direct database access to query your Supabase tables.

## 2. Puppeteer Server
Enhanced web scraping with full browser automation.

---

## ⚠️ Action Required: Add Your Supabase Password

### Step 1: Get Your Connection String

1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe/settings/database)
2. Navigate to: **Project Settings** → **Database**
3. Scroll to **Connection String** section
4. Select **Connection pooling** (Session mode)
5. Copy the URI (it will look like):
   ```
   postgresql://postgres.nmkavdrvgjkolreoexfe:[YOUR-PASSWORD]@aws-0-us-west-1.pooler.supabase.com:6543/postgres
   ```

### Step 2: Update Config File

Open `~/.claude/config.json` and replace `[YOUR_SUPABASE_PASSWORD]` with your actual password:

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://postgres.nmkavdrvgjkolreoexfe:YOUR_ACTUAL_PASSWORD@aws-0-us-west-1.pooler.supabase.com:6543/postgres"
      ]
    },
    "puppeteer": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-puppeteer"
      ]
    }
  }
}
```

### Step 3: Restart Claude Code

After updating the config:
```bash
# Exit Claude Code (Ctrl+C or Cmd+C)
# Then restart it
claude-code
```

---

## What You'll Be Able to Do

### With PostgreSQL Server:
- **Query tables directly**: `SELECT * FROM mountain_status ORDER BY scraped_at DESC LIMIT 10`
- **Check data quality**: Count records, find nulls, verify scraper runs
- **Debug issues**: Inspect actual database state
- **Run analytics**: Complex queries across tables

### With Puppeteer Server:
- **Fix scrapers**: I can navigate to resort websites and extract data
- **Test selectors**: Verify CSS selectors work before deploying
- **Handle JavaScript**: Sites that require JS execution
- **Debug scraping**: See what's actually on the page

---

## Testing MCP Servers

Once configured and restarted, try:

**PostgreSQL:**
```
Claude, query the mountain_status table and show me the latest 5 entries
```

**Puppeteer:**
```
Claude, navigate to https://www.mtbaker.us and extract the lifts open count
```

---

## Troubleshooting

If MCP servers don't load:
1. Check `~/.claude/config.json` syntax (valid JSON)
2. Ensure connection string has no typos
3. Verify Supabase password is correct
4. Restart Claude Code completely

You can also check MCP server status:
```
/mcp list
```
