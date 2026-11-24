# 도서 대여 데이터베이스

Codyssey 미션 「정보를 깔끔하게 정리하는 디지털 서랍장 만들기」의 SQLite 결과물이다. 회원, 도서, 카테고리, 대여 기록을 연결하고 SQL 15개로 검색, 조인, 집계, 수정, 삭제를 확인한다. [제출용 ZIP](library-database.zip)

## 실행 가이드

macOS 또는 Linux 터미널에서 SQLite CLI 3.35 이상을 사용한다. 저장소를 내려받은 폴더에서 1단계를 시작하고, 같은 터미널에서 명령을 순서대로 실행한다.

### 1. 제출 DB 열기

제출된 `library.db`를 읽기 전용으로 열고 카테고리 10개를 조회한다.

```sh
cd library-database
sqlite3 --version
sqlite3 -init /dev/null -readonly -header -column library.db \
  'SELECT id, name FROM category ORDER BY id;'
```

### 2. 샘플 DB 만들고 핵심 SQL 실행하기

새 `practice.db`에 테이블을 만들고 샘플을 입력한다. 같은 이름의 파일이 이미 있으면 이후 명령에서 새 파일명을 사용한다.

```sh
sqlite3 -init /dev/null -batch -bail practice.db < 01_schema.sql &&
sqlite3 -init /dev/null -batch -bail practice.db < 02_sample_data.sql &&
sqlite3 -init /dev/null -batch -bail -echo -header -separator ' | ' -nullvalue NULL \
  practice.db < 03_queries.sql
```

터미널에 Q01~Q15의 SQL과 결과가 순서대로 나온다. Q13의 반납 처리와 Q14의 삭제는 실행 후 롤백한다. Q15에서는 대여일 인덱스를 만들고 11월 대여 조회의 실행 계획이 어떻게 바뀌는지 확인한다.

### 3. 보너스 SQL 실행하기

```sh
sqlite3 -init /dev/null -batch -echo -header -separator ' | ' -nullvalue NULL \
  practice.db < 04_bonus.sql 2>&1
```

11월에 대여한 회원을 두 방식으로 조회하고, 월별 대여 건수·인기 도서 TOP 10·회원별 연체율을 확인한다. 마지막 B05의 `FOREIGN KEY constraint failed`와 종료 코드 `1`은 예정된 결과다. CLI는 오류 이후에도 등록된 회원 번호로 입력을 재시도하고 실험을 롤백한다.

### 4. DB 무결성 확인하기

```sh
sqlite3 -init /dev/null -batch -bail -readonly practice.db <<'SQL'
PRAGMA foreign_keys = ON;
PRAGMA foreign_keys;
PRAGMA foreign_key_check;
PRAGMA integrity_check;
SQL
```

출력에 보이는 `1`은 외래키 검사가 켜졌다는 뜻이고, `ok`는 DB 무결성 검사 통과를 뜻한다. `foreign_key_check`의 결과는 위반 행 0개다.

## 제출물과 실행 기록

카테고리 10개, 회원 12명, 도서 15권, 대여 32건으로 세 가지 1:N 관계와 핵심 SQL을 검증했다.

| 파일 | 내용 |
| --- | --- |
| [스키마](library-database/01_schema.sql) · [ERD](library-database/erd.png) | 테이블 4개, 키와 제약조건, 관계도 |
| [샘플 데이터](library-database/02_sample_data.sql) · [SQLite DB](library-database/library.db) | 가상 데이터의 입력 SQL과 실행 가능한 DB |
| [핵심 SQL](library-database/03_queries.sql) · [실행 결과](library-database/results/01_queries.txt) | Q01~Q15와 실제 SQLite CLI 출력 |
| [보너스 SQL](library-database/04_bonus.sql) · [실행 결과](library-database/results/02_bonus.txt) · [리포트](library-database/bonus_report.md) | JOIN·서브쿼리 비교, 지표 3개, 외래키 오류와 복구 |
| [검증 기록](library-database/results/03_verification.txt) | 행 수, 제약조건, 수정·삭제, 쿼리 결과 검증 |

## AI 활용 범위

Codex가 미션 명세에 따라 스키마, 가상 데이터, SQL과 문서를 작성하고 SQLite에서 실행과 검증을 수행했다.
