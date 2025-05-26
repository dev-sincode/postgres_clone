#!/bin/bash

# === Prompt user for input ===

read -rp "Enter PostgreSQL host [localhost]: " PGHOST
PGHOST=${PGHOST:-localhost}

read -rp "Enter PostgreSQL port [5432]: " PGPORT
PGPORT=${PGPORT:-5432}

read -rp "Enter PostgreSQL user [postgres]: " PGUSER
PGUSER=${PGUSER:-postgres}

#read -rp "Enter backup directory [./pg_backups]: " BACKUP_DIR
BACKUP_DIR=${BACKUP_DIR:-./Users/dhavalsingh/Desktop/postgres_backup_restore
}

read -rp "Enter comma-separated list of source databases (e.g. db1,db2): " DB_CSV
IFS=',' read -ra DB_LIST <<< "$DB_CSV"

read -rp "Do you want to (b)ackup or (r)estore? [b/r]: " ACTION

# === Functions ===

backup_dbs() {
    mkdir -p "$BACKUP_DIR"
    echo "📦 Starting backup..."
    for DB in "${DB_LIST[@]}"; do
        echo "Backing up: $DB"
        pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -Fc -f "${BACKUP_DIR}/${DB}.dump" "$DB"
        if [ $? -ne 0 ]; then
            echo "❌ Backup failed for $DB"
        else
            echo "✅ Backup completed for $DB"
        fi
    done
}

truncate_tables() {
    local DB=$1
    echo "⚠️ Truncating all user tables in $DB..."

    psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DB" -v ON_ERROR_STOP=1 <<EOF
DO \$\$
DECLARE
    stmt text;
BEGIN
    EXECUTE 'SET session_replication_role = replica';

    SELECT INTO stmt
        string_agg(format('TRUNCATE TABLE %I.%I RESTART IDENTITY CASCADE', schemaname, tablename), '; ')
    FROM pg_tables
    WHERE schemaname NOT IN ('pg_catalog', 'information_schema');

    IF stmt IS NOT NULL THEN
        EXECUTE stmt;
    END IF;

    EXECUTE 'SET session_replication_role = origin';
END\$\$;
EOF

    if [ $? -ne 0 ]; then
        echo "❌ Truncate failed for $DB"
        exit 1
    else
        echo "✅ All user tables truncated for $DB"
    fi
}

restore_dbs() {
    echo "🔁 Starting full restore (schema + data)..."

    for SRC_DB in "${DB_LIST[@]}"; do
        read -rp "Enter target database name to restore $SRC_DB into: " TARGET_DB

        pg_restore -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$TARGET_DB" "${BACKUP_DIR}/${SRC_DB}.dump"
        if [ $? -ne 0 ]; then
            echo "❌ Restore failed for $TARGET_DB"
        else
            echo "✅ Restore completed for $TARGET_DB"
        fi
    done
}

restore_dbs_data_only() {
    echo "🔁 Starting data-only restore..."

    for SRC_DB in "${DB_LIST[@]}"; do
        read -rp "Enter target database name to restore $SRC_DB's data into: " TARGET_DB

        truncate_tables "$TARGET_DB"

        pg_restore -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" --data-only --disable-triggers -d "$TARGET_DB" "${BACKUP_DIR}/${SRC_DB}.dump"
        if [ $? -ne 0 ]; then
            echo "❌ Restore failed for $TARGET_DB"
        else
            echo "✅ Restore completed for $TARGET_DB"
        fi
    done
}

# === Run action ===

if [[ "$ACTION" == "b" ]]; then
    backup_dbs
elif [[ "$ACTION" == "r" ]]; then
    read -rp "Restore (f)ull (schema + data) or (d)ata-only? [f/d]: " RESTORE_TYPE
    if [[ "$RESTORE_TYPE" == "f" ]]; then
        restore_dbs
    elif [[ "$RESTORE_TYPE" == "d" ]]; then
        restore_dbs_data_only
    else
        echo "❌ Invalid restore type. Use 'f' for full or 'd' for data-only."
        exit 1
    fi
else
    echo "❌ Invalid action. Use 'b' for backup or 'r' for restore."
    exit 1
fi
