# 🐘 pg_multi_backup_restore_interactive.sh

A fully interactive Bash script for backing up and restoring **multiple PostgreSQL databases**. It supports both **schema+data** and **data-only** restores, and handles common pitfalls like foreign key constraints and sequence mismatches.

---

## 📦 Features

- Backup multiple PostgreSQL databases using `pg_dump`
- Restore into **existing** databases
- Supports **data-only** or full restore
- Truncates tables before restoring data
- Disables foreign key constraints during restore
- Resets sequences automatically to avoid primary key conflicts (optional)

---

## ⚙️ Prerequisites

- Bash (Linux or macOS)
- PostgreSQL client tools: `pg_dump`, `pg_restore`, `psql`
- User with `SUPERUSER` privileges (required for disabling triggers)

---

## 📥 Installation

Clone this repository or copy the script to your machine:

```bash
git clone https://github.com/your-org/postgres-tools.git
cd postgres-tools
chmod +x pg_multi_backup_restore_interactive.sh




