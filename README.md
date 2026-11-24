# 도서 대여 데이터베이스

Codyssey 미션 「정보를 깔끔하게 정리하는 디지털 서랍장 만들기」의 SQLite 결과물이다. 회원, 도서, 카테고리, 대여 기록을 연결하고 SQL 15개로 검색, 조인, 집계, 수정, 삭제를 확인한다.

[실행 가이드](#실행-가이드) · [동료 평가 확인표](#동료-평가-확인표)

## 실행 가이드

macOS 또는 Linux의 SQLite CLI 3.35 이상에서 실행한다. 저장소를 내려받은 뒤, `README.md`와 `library-database` 폴더가 보이는 위치에서 터미널을 연다. 아래 명령을 같은 터미널에 단계별로 복사해 실행한다.

### 1. 제출 DB 열기

제출된 `library.db`를 읽기 전용으로 연다. 카테고리 10개가 표시되며 첫 행은 소설, 마지막 행은 아동이다.

```sh
cd library-database
sqlite3 --version
sqlite3 -init /dev/null -readonly -header -column library.db \
  'SELECT id, name FROM category ORDER BY id;'
```

### 2. 샘플 DB 만들고 핵심 SQL 실행하기

실행할 때마다 임시 폴더에 새 `practice.db`를 만든다. 스키마 생성, 샘플 입력, 핵심 SQL 실행이 순서대로 이어진다.

```sh
practice_dir="$(mktemp -d)" &&
practice_db="$practice_dir/practice.db" &&
sqlite3 -init /dev/null -batch -bail "$practice_db" < 01_schema.sql &&
sqlite3 -init /dev/null -batch -bail "$practice_db" < 02_sample_data.sql &&
sqlite3 -init /dev/null -batch -bail -echo -header -separator ' | ' -nullvalue NULL \
  "$practice_db" < 03_queries.sql
```

Q01~Q15의 SQL과 결과가 순서대로 나온다. 예를 들어 Q04에는 11월 대여 13건이 표시된다. Q13과 Q14는 반납과 삭제를 실행한 뒤 롤백으로 샘플을 복원한다. Q15는 대여일 인덱스를 만들고 생성 전후의 실행 계획을 보여 준다. [핵심 SQL 실제 출력](library-database/results/01_queries.txt)

### 3. 보너스 SQL 실행하기

B05는 없는 회원 번호로 입력해 오류가 나는지 확인하는 실험이다. `FOREIGN KEY constraint failed`와 종료 코드 `1`이 예상되며, 이후 올바른 번호로 입력하고 롤백까지 진행한다.

```sh
sqlite3 -init /dev/null -batch -echo -header -separator ' | ' -nullvalue NULL \
  "$practice_db" < 04_bonus.sql 2>&1
```

끝부분에 `rows_after_rollback`과 `0`이 나오면 실험까지 끝난 것이다. [보너스 실제 출력](library-database/results/02_bonus.txt)

### 4. DB 무결성 확인하기

```sh
sqlite3 -init /dev/null -batch -bail -readonly "$practice_db" <<'SQL'
PRAGMA foreign_keys = ON;
PRAGMA foreign_keys;
PRAGMA foreign_key_check;
PRAGMA integrity_check;
SQL
```

정상 출력은 `1`과 `ok` 두 줄이다. `1`은 현재 연결에서 외래키 검사가 활성화됐다는 뜻이다. `foreign_key_check`는 위반 행 0개를 반환하고, `ok`는 DB 무결성 검사 통과를 뜻한다.

## 동료 평가 확인표

표의 근거를 열면 해당 SQL과 결과를 확인할 수 있다. 파일을 내려받아 볼 때는 표의 Q 번호나 B 번호를 검색하면 된다.

| 필수 항목 | 확인된 내용 | 근거 |
| --- | --- | --- |
| 실행 환경 | 로컬 SQLite CLI에서 SQL 파일을 실행 | [실행 가이드](#실행-가이드) |
| 스키마와 관계 | 테이블 4개와 PK 4개, 카테고리→도서·회원→대여·도서→대여의 1:N 관계 3개 | [스키마](library-database/01_schema.sql) · [ERD](library-database/erd.png) |
| 제약조건 | PK 중복, `NOT NULL`, `UNIQUE`, FK 및 날짜 `CHECK` 위반 입력을 거부 | [제약조건 검증](library-database/results/03_verification.txt#L6) |
| 테이블당 최소 10행 | 카테고리 10개, 회원 12명, 도서 15권, 대여 32건 | [INSERT SQL](library-database/02_sample_data.sql) · [SQLite DB](library-database/library.db) · [행 수 검증](library-database/results/03_verification.txt#L2) |
| 쿼리별 실행 기록 | 핵심 SQL 15개와 보너스 SQL의 목적, SQL 본문, 실제 출력 | [핵심 실행 기록](library-database/results/01_queries.txt) · [보너스 실행 기록](library-database/results/02_bonus.txt) |
| 최종 무결성 | 외래키 검사 활성화, 위반 0건, DB 무결성 검사 `ok` | [무결성 검증](library-database/results/03_verification.txt#L30) |

실행 환경의 화면 기록 권한이 없어 원본 미션에서 허용한 **실제 실행 결과 텍스트**를 사용했다. 기록은 SQLite CLI 3.43.2의 출력이다.

### 핵심 SQL 15개

| 요구사항 | 확인할 쿼리 | 근거 |
| --- | --- | --- |
| 기본 조회 4개 | Q01~Q04의 검색 조건, 정렬, 행 수 제한 | [SQL](library-database/03_queries.sql#L4) · [실행 결과](library-database/results/01_queries.txt#L4) |
| 조인 4개 | Q05·Q06·Q08의 `INNER JOIN`, Q07의 `LEFT JOIN` | [SQL](library-database/03_queries.sql#L30) · [실행 결과](library-database/results/01_queries.txt#L57) |
| 집계 3개 | Q09~Q11의 `GROUP BY`와 `COUNT`, `SUM`, `AVG` | [SQL](library-database/03_queries.sql#L57) · [실행 결과](library-database/results/01_queries.txt#L150) |
| 서브쿼리 1개 | Q12의 `NOT EXISTS`로 대여 이력이 없는 회원 조회 | [SQL](library-database/03_queries.sql#L85) · [실행 결과](library-database/results/01_queries.txt#L217) |
| 수정·삭제 2개 | Q13과 Q14에서 변경한 행과 롤백으로 복원된 상태 확인 | [SQL](library-database/03_queries.sql#L95) · [실행 결과](library-database/results/01_queries.txt#L230) · [롤백 검증](library-database/results/03_verification.txt#L23) |
| 인덱스 1개 | Q15에서 대여일 범위 조회용 인덱스 생성과 실행 계획 비교 | [SQL과 생성 이유](library-database/03_queries.sql#L113) · [실행 결과](library-database/results/01_queries.txt#L252) |

### 보너스 3개

| 요구사항 | 확인된 내용 | 근거 |
| --- | --- | --- |
| 같은 요구를 JOIN과 서브쿼리로 해결 | B01A의 `JOIN`과 B01B의 `EXISTS` 모두 같은 회원 10명 반환 | [SQL](library-database/04_bonus.sql#L4) · [실행 결과](library-database/results/02_bonus.txt#L4) |
| 외래키 오류와 해결 | B05에서 없는 회원 참조를 거부하고, 등록된 번호로 입력한 뒤 롤백 | [SQL](library-database/04_bonus.sql#L67) · [실행 결과](library-database/results/02_bonus.txt#L117) |
| 핵심 지표 3개 | B02 월별 대여 건수, B03 인기 도서 TOP 10, B04 회원별 연체율 | [SQL](library-database/04_bonus.sql#L24) · [실행 결과](library-database/results/02_bonus.txt#L46) · [리포트](library-database/bonus_report.md#핵심-지표-3개) |

테이블을 나눈 이유와 쿼리별 문법·결과 해석은 학습 가이드에서 볼 수 있다. [학습 가이드](library-database/learning_guide.md)

## 제출 방식

저장소 링크를 공유할 때는 이 README의 확인표에서 SQL과 실행 결과를 바로 열 수 있다. 파일을 한 개로 첨부해야 할 때는 전체 결과물을 묶은 ZIP을 사용할 수 있다. [첨부용 ZIP](library-database.zip)

## AI 활용 범위

사용자가 제공한 미션 명세에 따라 Codex가 스키마, 가상 데이터, SQL, ERD와 문서를 작성하고 SQLite에서 실행과 검증을 수행했다.
