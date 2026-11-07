#!/bin/sh
# Tests check_migrations.sh on small generated repos, one per migration tool. No AI, no database.
# Each case lists text the output must contain (+) and must not contain (-).
set -eu
here=$(cd "$(dirname "$0")" && pwd)
script=$here/../../skills/migration-guard/scripts/check_migrations.sh
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fails=0

# Usage: start <name> <folder> <existing-file>; then write new files; then finish.
start() {
  repo=$work/$1; mkdir -p "$repo/$2"; cd "$repo"
  git init -q -b main
  echo "x" > "$2/$3"
  git add -A; git -c user.name=t -c user.email=t@x commit -qm base
  git checkout -qb feature
  name=$1; shift 3
}
finish() {
  git add -A; git -c user.name=t -c user.email=t@x commit -qm change
  out=$(sh "$script" main 2>&1 || true)
  for want in "$@"; do
    case $want in
      +*) case $out in *"${want#+}"*) ;; *) echo "FAIL $name: missing '${want#+}'"; fails=$((fails + 1)) ;; esac ;;
      -*) case $out in *"${want#-}"*) echo "FAIL $name: unexpected '${want#-}'"; fails=$((fails + 1)) ;; esac ;;
    esac
  done
  echo "ran $name"
}

start golang migrations 000001_init.up.sql
echo "ALTER TABLE t ADD COLUMN a int NOT NULL;" > migrations/000001_other.up.sql
echo "SELECT 1;" > migrations/000002_new.up.sql
finish "+Number" "+000001_other" "+no .down.sql" "+ADD COLUMN a int NOT NULL"

start django app/migrations 0001_initial.py
cat > app/migrations/0002_x.py <<'PY'
operations = [
    migrations.AddField(
        model_name="user",
        name="required_one",
        field=models.CharField(max_length=9),
    ),
    migrations.AddField(
        model_name="user",
        name="nullable_one",
        field=models.CharField(max_length=9, null=True),
    ),
    migrations.AddField(model_name="user", name="with_default", field=models.IntegerField(default=0)),
    migrations.RunPython(forward),
    migrations.RunPython(forward, migrations.RunPython.noop),
    migrations.RunSQL("UPDATE x"),
    migrations.RemoveField(model_name="user", name="old"),
]
PY
finish "+required_one" "-nullable_one" "-with_default" "+RunPython with no reverse_code" "+RunSQL with no reverse_sql" "+RemoveField"

start alembic alembic/versions a1b2c3_init.py
cat > alembic/versions/d4e5f6_x.py <<'PY'
def upgrade():
    op.add_column("user", sa.Column("req", sa.String(), nullable=False))
    op.add_column("user", sa.Column("opt", sa.String(), nullable=False, server_default="x"))
    op.drop_column("user", "old")
PY
finish '+"req"' '-"opt"' "+drop_column"

start rails db/migrate 20260101000000_init.rb
cat > db/migrate/20260102000000_x.rb <<'RB'
class X < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :req, :string, null: false
    add_column :users, :opt, :string, null: false, default: "x"
    remove_column :users, :old
  end
end
RB
finish "+:req" "-:opt" "+remove_column"

start laravel database/migrations 2026_01_01_000000_init.php
cat > database/migrations/2026_01_02_000000_x.php <<'PHP'
<?php
Schema::table('users', function ($t) { $t->dropColumn('old'); });
PHP
git add -A
finish "+dropColumn"

start clean migrations 000001_init.up.sql
echo "x" > migrations/000001_init.down.sql
echo "ALTER TABLE t ADD COLUMN a int;" > migrations/000002_ok.up.sql
echo "ALTER TABLE t DROP COLUMN a;" > migrations/000002_ok.down.sql
finish "-Number" "-Pair" "-Order"

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
