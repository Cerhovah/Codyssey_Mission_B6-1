"""도서 대여 미션을 임시 SQLite DB에서 한 단계씩 시연한다."""

from contextlib import closing
import json
from pathlib import Path
import re
import sqlite3
import sys

PROJECT = Path(__file__).resolve().parent
RENTAL_STATE = """SELECT id, returned_on FROM rental WHERE id IN (28, 32) ORDER BY id;
SELECT COUNT(*) AS rental_count FROM rental;"""
MEMBER_STATE = "SELECT id, name, email, joined_on FROM member WHERE id = 13;"


def read_sql(filename):
    return (PROJECT / filename).read_text(encoding="utf-8")


def statements(script):
    pending = ""
    for line in script.splitlines():
        if not line.strip() or line.lstrip().startswith("--"):
            continue
        pending += line + "\n"
        if sqlite3.complete_statement(pending):
            yield pending.strip()
            pending = ""
    if pending:
        raise ValueError("세미콜론으로 끝나지 않은 SQL이 있습니다.")


def execute(db, script, expect_fk_error=False):
    """실제 SQL과 그 결과를 같은 화면에 표시한다."""
    blocks = []
    fk_error_seen = False
    for sql in statements(script):
        blocks.append(sql)
        try:
            result = db.execute(sql)
        except sqlite3.IntegrityError as error:
            if not expect_fk_error or fk_error_seen or str(error) != "FOREIGN KEY constraint failed":
                raise
            fk_error_seen = True
            blocks.append(f"의도한 외래키 오류  ·  {error}")
            continue

        if result.description is not None:
            rows = result.fetchall()
            blocks.append("")
            blocks.append(" | ".join(column[0] for column in result.description))
            blocks.extend(" | ".join("NULL" if value is None else str(value) for value in row) for row in rows)
            if not rows:
                blocks.append("(0행)")
        blocks.append("")
    if expect_fk_error and not fk_error_seen:
        raise ValueError("B05에서 예상한 외래키 오류가 발생하지 않았습니다.")
    return "\n".join(blocks).strip()


def query_groups(db, filename):
    # 기존 SQL의 [Q01], [B01A] 같은 주석을 단계 제목으로 사용한다.
    preamble, *groups = re.split(r"(?m)^-- (\[(?:Q\d{2}|B\d{2}[AB]?)\][^\n]*)\n", read_sql(filename))
    execute(db, preamble)
    yield from zip(groups[::2], groups[1::2])


def demo_steps():
    # 트랜잭션을 직접 열고 닫을 수 있도록 하고, 제출 DB 파일은 열지 않는다.
    with closing(sqlite3.connect(":memory:", isolation_level=None)) as db:
        db.executescript(read_sql("01_schema.sql"))
        yield (
            "테이블 4개 생성",
            "임시 DB에 스키마를 실행해 도서·카테고리·회원·대여 테이블을 만들었습니다.",
            "01_schema.sql\n\n" + execute(db, "SELECT name AS table_name FROM sqlite_schema WHERE type = 'table' ORDER BY name;"),
        )

        db.executescript(read_sql("02_sample_data.sql"))
        yield (
            "샘플 데이터 입력",
            "모든 테이블에 샘플이 10행 이상 있습니다.",
            "02_sample_data.sql\n\n" + execute(db, """
SELECT '회원' AS type, COUNT(*) AS count FROM member
UNION ALL SELECT '도서', COUNT(*) FROM book
UNION ALL SELECT '분류', COUNT(*) FROM category
UNION ALL SELECT '대여', COUNT(*) FROM rental;
"""),
        )
        for table, caption in (("member", "회원 목록"), ("book", "도서 목록")):
            yield (caption, "샘플 데이터가 들어간 상태를 확인합니다.", execute(db, f"SELECT * FROM {table} ORDER BY id;"))

        notes = {
            "[Q05]": "회원·도서 번호를 JOIN으로 이름·제목에 연결하고, 반납일이 NULL인 대여만 고릅니다.",
            "[Q09]": "연결(LEFT JOIN) → 묶기(GROUP BY) → 세기(COUNT) → 정렬(ORDER BY). 김하늘은 5건이고 신나연은 0건입니다.",
            "[Q13]": "28번 대여의 반납일이 NULL에서 2026-11-24로 바뀝니다.",
            "[Q14]": "32번 대여를 삭제하면 대상은 0행, 전체 대여는 31건이 됩니다.",
        }
        for title, sql in query_groups(db, "03_queries.sql"):
            tag = title.split()[0]
            if tag == "[Q13]":
                yield ("반납·삭제 전", "28번은 미반납이고, 전체 대여 기록은 32건입니다.", execute(db, RENTAL_STATE))
            if tag == "[Q14]":
                delete, rollback, rest = sql.partition("ROLLBACK;")
                if not rollback or rest.strip():
                    raise ValueError("Q14의 마지막 ROLLBACK을 찾지 못했습니다.")
                yield (title, notes[tag], execute(db, delete + "\nSELECT COUNT(*) AS rental_count FROM rental;"))
                yield ("반납·삭제 복원", "ROLLBACK 후 28번의 반납일이 NULL로 돌아오고, 32번도 다시 조회됩니다.",
                       execute(db, rollback + "\n" + RENTAL_STATE))
            else:
                yield (title, notes.get(tag, ""), execute(db, sql))

        for title, sql in query_groups(db, "04_bonus.sql"):
            is_b05 = title.startswith("[B05]")
            hint = "없는 회원 번호를 거부한 뒤, 올바른 번호로 입력하고 롤백합니다." if is_b05 else ""
            yield (title, hint, execute(db, sql, expect_fk_error=is_b05))

        crud = (
            ("회원 추가", "13번 회원 홍길동을 등록합니다.", """
BEGIN;
INSERT INTO member (id, name, email, joined_on)
VALUES (13, '홍길동', 'hong13@example.com', '2026-11-25');
"""),
            ("회원 조회", "13번 회원을 조건으로 찾아봅니다.", ""),
            ("회원 수정", "13번 회원의 이름을 김철수로 바꿉니다.", "UPDATE member SET name = '김철수' WHERE id = 13;"),
            ("회원 삭제", "13번 회원을 지운 뒤 조회하면 0행입니다.", "DELETE FROM member WHERE id = 13;"),
            ("회원 실험 복원", "실험을 끝내고 원래 상태로 되돌립니다.", "ROLLBACK;"),
        )
        for title, hint, sql in crud:
            yield (title, hint, execute(db, sql + "\n" + MEMBER_STATE))

        yield (
            "최종 무결성 검사",
            "외래키 활성화 1, 외래키 위반 0행, 구조 검사 ok입니다.",
            execute(db, "PRAGMA foreign_keys;\nPRAGMA foreign_key_check;\nPRAGMA integrity_check;"),
        )


def worker():
    """창에서 다음 단계를 요청할 때만 SQL을 실행한다."""
    with closing(demo_steps()) as demo:
        for _ in sys.stdin:
            try:
                title, hint, output = next(demo)
                response = {"title": title, "hint": hint, "output": output}
            except StopIteration:
                response = {"done": True}
            except (OSError, sqlite3.Error, ValueError) as error:
                response = {"error": str(error)}

            print(json.dumps(response), flush=True)
            if "title" not in response:
                break


if __name__ == "__main__":
    worker()
