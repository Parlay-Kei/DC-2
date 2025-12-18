# Supabase Migrations

This directory contains database migrations for the Direct Cuts application.

## Directory Structure

```
supabase/
├── migrations/          # Database migration files
│   └── YYYYMMDDHHMMSS_description.sql
└── README.md           # This file
```

## Migration Naming Convention

Migration files follow the pattern: `YYYYMMDDHHMMSS_description.sql`

- `YYYYMMDD`: Date (Year, Month, Day)
- `HHMMSS`: Time (Hours, Minutes, Seconds) - used for ordering multiple migrations on same day
- `description`: Brief description using snake_case

Example: `20251212000001_add_shop_columns_to_barbers.sql`

## Running Migrations

### Using Supabase CLI

```bash
# Push migrations to remote Supabase project
supabase db push

# Reset local database and apply all migrations
supabase db reset

# Create a new migration
supabase migration new description_of_change
```

### Manual Execution

If you don't have the Supabase CLI, you can run migrations manually:

1. Open the Supabase Dashboard
2. Navigate to SQL Editor
3. Copy and paste the migration SQL
4. Execute the query

## Migration Best Practices

1. **Idempotent**: All migrations use `IF NOT EXISTS` checks to safely re-run
2. **Comments**: Include description and purpose at the top
3. **Rollback**: Document rollback SQL in comments
4. **Testing**: Test migrations on local/staging before production
5. **Sequential**: Migrations run in timestamp order

## Current Migrations

- `20251212000001_add_shop_columns_to_barbers.sql` - Adds shop_name, shop_address, offers_home_service, and travel_fee_per_mile columns to barbers table

## Related Documentation

- [Supabase Migrations Docs](https://supabase.com/docs/guides/cli/local-development#database-migrations)
- [Direct Cuts Database Schema](../README.md)
