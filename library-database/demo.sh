#!/bin/sh
set -eu

case "${1-}" in
    core) sql_file=03_queries.sql ;;
    bonus) sql_file=04_bonus.sql ;;
    *)
        printf '사용법  sh library-database/demo.sh core 또는 bonus\n' >&2
        exit 2
        ;;
esac

if ! command -v sqlite3 >/dev/null 2>&1; then
    printf 'VS Code 터미널에서 sqlite3를 실행할 수 있어야 합니다.\n' >&2
    exit 127
fi

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
scratch_dir=$(mktemp -d "${TMPDIR:-/tmp}/library-demo.XXXXXXXX")
trap 'rm -rf -- "$scratch_dir"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# SQLite가 원본을 읽기 전용으로 열어 일관된 스냅샷을 만든다.
(
    cd "$scratch_dir"
    sqlite3 -init /dev/null -batch -bail -readonly "$project_dir/library.db" '.backup demo.db'
)

database="$scratch_dir/demo.db"
input="$scratch_dir/demo.sql"
# 쿼리 제목을 결과 위에 표시한다. 원본 SQL은 그대로 실행한다.
awk '
    /^-- \[(Q[0-9][0-9]|B[0-9][0-9][AB]?)\]/ {
        title = substr($0, 4)
        gsub(/"/, "\\\"", title)
        print ".print"
        print ".print \"" title "\""
    }
    { print }
' "$project_dir/$sql_file" > "$input"

if [ "$sql_file" = 03_queries.sql ]; then
    # 제출 DB에 이미 있는 인덱스를 복사본에서 제거해 Q15의 생성을 시연한다.
    sqlite3 -init /dev/null -batch -bail "$database" 'DROP INDEX IF EXISTS idx_rental_rented_on;'
    sqlite3 -init /dev/null -batch -bail -header -separator ' | ' -nullvalue NULL "$database" < "$input"

    printf '\n[롤백 후 대여 28·32번]\n'
    sqlite3 -init /dev/null -batch -bail -header -separator ' | ' -nullvalue NULL "$database" \
        'SELECT id, returned_on FROM rental WHERE id IN (28, 32) ORDER BY id;'
else
    # B05가 의도한 오류 한 건만 정상 시연으로 처리한다.
    status=0
    sqlite3 -init /dev/null -batch -header -separator ' | ' -nullvalue NULL "$database" \
        < "$input" 2> "$scratch_dir/bonus-errors.txt" || status=$?
    if [ "$status" -ne 1 ] || ! awk '
        NR == 1 && /(^|: )(stepping, )?FOREIGN KEY constraint failed( \(19\))?$/ { expected = 1 }
        END { exit !(NR == 1 && expected) }
    ' "$scratch_dir/bonus-errors.txt"; then
        cat "$scratch_dir/bonus-errors.txt" >&2
        printf '\n보너스 실행에서 예상한 B05 외래키 오류 한 건을 확인하지 못했습니다.\n' >&2
        exit 1
    fi
    printf '\n[B05에서 의도한 외래키 오류]\n'
    cat "$scratch_dir/bonus-errors.txt"
fi

printf '\n시연 완료. 원본 library.db는 읽기 전용으로 열었습니다.\n'
