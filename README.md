# 도서 대여 데이터베이스

도서관에서 누가 어떤 책을 언제 빌렸는지 저장하고 찾아보는 Codyssey 실습입니다.

**이 프로젝트의 코드는 이름이 `.sql`로 끝나는 파일 네 개입니다.** SQL은 정보를 저장하거나 꺼내는 명령을 적는 언어입니다. **SQLite**는 그 명령을 실행하는 프로그램이고, `library.db`는 정보가 저장된 **데이터베이스(DB)** 파일입니다. 지금 보고 있는 README는 코드와 결과를 읽는 설명서입니다.

[그림으로 보는 구조](#그림으로-보는-구조) · [코드와 결과 파일](#코드와-결과-파일) · [실행 가이드](#실행-가이드) · [동료 평가 확인표](#동료-평가-확인표)

## 그림으로 보는 구조

![대여 1번의 회원 번호로 김하늘을, 도서 번호로 바다의 우체국을, 도서의 분류 번호로 소설을 찾는 그림](library-database/loan-example.png)

**표(테이블)**는 엑셀 표처럼 기록을 가로줄과 세로칸으로 정리한 목록입니다. 가로 한 줄인 **행**은 회원 한 명이나 대여 한 건을 뜻합니다. 세로 한 줄인 **열**에는 이름이나 대여일처럼 한 종류의 값이 모입니다.

그림에서 대여 1번에는 회원 번호와 도서 번호가 들어 있습니다. 대여 표(`rental`)의 회원 번호 칸(`member_id`)이 1이면, 회원 표(`member`)의 1번 행에서 이름 **김하늘**을 찾습니다. 자기 표에서 행을 구별하는 번호가 **기본키(PK)**이고, 다른 표의 행을 가리키는 번호가 **외래키(FK)**입니다. SQL에서 이 번호로 여러 표의 정보를 함께 가져오는 동작을 **조인(JOIN)**이라고 부릅니다.

회원과 책 정보를 각각 한 곳에 두면 책을 빌릴 때마다 이름과 제목을 다시 적을 필요가 없습니다. 한 회원 번호를 여러 대여 기록이 가리킬 수 있는데, 이를 **1:N(일대다)** 관계라고 합니다. 전체 구조는 각 표의 열까지 표시한 관계도에서 볼 수 있습니다. [전체 관계도](library-database/erd.png)

## 코드와 결과 파일

| 파일 | 쉽게 말하면 |
| --- | --- |
| [01_schema.sql](library-database/01_schema.sql) | 회원, 도서, 분류, 대여를 적을 빈 표와 입력 규칙을 만드는 코드입니다. 표와 규칙의 설계를 **스키마**라고 합니다. |
| [02_sample_data.sql](library-database/02_sample_data.sql) | 김하늘 같은 가상의 회원과 도서, 대여 기록을 표에 넣는 코드입니다. |
| [03_queries.sql](library-database/03_queries.sql) | 검색, 표 연결, 건수 계산, 반납 처리와 삭제 등을 확인하는 명령 15개가 들어 있습니다. |
| [04_bonus.sql](library-database/04_bonus.sql) | 같은 질문을 두 방법으로 풀고, 대여 통계를 내고, 잘못된 번호를 넣으면 어떻게 되는지 확인하는 코드입니다. |
| [library.db](library-database/library.db) | 샘플 데이터가 들어 있는 실제 SQLite 파일입니다. |
| [핵심 출력](library-database/results/01_queries.txt) · [보너스 출력](library-database/results/02_bonus.txt) | 코드를 실행했을 때 터미널에 표시된 명령과 결과를 저장한 글 파일입니다. |

## 실행 가이드

**터미널**은 글자로 명령을 실행하는 창입니다. 프로젝트를 내려받은 뒤, `README.md`와 `library-database` 폴더가 함께 보이는 위치에서 시작합니다. 아래 명령은 macOS 또는 Linux의 SQLite 3.35 이상을 기준으로 합니다.

macOS에서는 터미널 창에 `cd `를 끝의 공백까지 입력하고, Finder에서 해당 폴더를 창에 끌어온 뒤 Enter를 누르면 그 폴더로 이동합니다. 아래 코드 상자를 위에서부터 한 개씩 복사해 같은 터미널에 붙여넣고 실행합니다.

### 1. 이미 만들어 둔 DB 열기

`sqlite3` 명령으로 실행합니다. 버전 정보 아래에 제출된 `library.db`의 분류 10개가 번호순으로 표시됩니다. 첫 행은 소설이고 마지막 행은 아동입니다.

```sh
cd library-database
sqlite3 --version
sqlite3 -init /dev/null -readonly -header -column library.db \
  'SELECT id, name FROM category ORDER BY id;'
```

작은따옴표 안이 SQLite에 전달하는 SQL입니다. `SELECT id, name`은 번호와 이름을 가져오라는 뜻입니다. `FROM category`는 읽을 표, `ORDER BY id`는 번호순 정렬을 뜻합니다.

### 2. 실습용 DB를 만들고 코드 실행하기

매번 임시 폴더에 실습 파일 `practice.db`를 만듭니다. `01`이 표를 만들고, `02`가 예시 데이터를 넣고, `03`이 핵심 명령을 하나씩 실행합니다.

```sh
practice_dir="$(mktemp -d)" &&
practice_db="$practice_dir/practice.db" &&
sqlite3 -init /dev/null -batch -bail "$practice_db" < 01_schema.sql &&
sqlite3 -init /dev/null -batch -bail "$practice_db" < 02_sample_data.sql &&
sqlite3 -init /dev/null -batch -bail -echo -header -separator ' | ' -nullvalue NULL \
  "$practice_db" < 03_queries.sql
```

결과에는 명령마다 Q01~Q15 번호가 붙습니다. 예를 들어 Q04에는 11월 대여 13건이 나옵니다. Q13과 Q14는 반납 처리와 삭제를 해 본 뒤 원래 상태로 되돌립니다. SQL에서 이 되돌리기를 `ROLLBACK`이라고 합니다. [핵심 SQL 실제 출력](library-database/results/01_queries.txt)

### 3. 보너스 SQL 실행하기

앞 단계에서 만든 실습 파일로 보너스 코드를 실행합니다. 마지막 B05는 등록되지 않은 회원 번호로 대여를 넣어 보는 실험입니다. `FOREIGN KEY constraint failed`가 표시되면 SQLite가 연결 규칙을 지켰다는 뜻입니다. 이 실험이 포함되어 종료 코드 `1`이 나옵니다.

```sh
sqlite3 -init /dev/null -batch -echo -header -separator ' | ' -nullvalue NULL \
  "$practice_db" < 04_bonus.sql 2>&1
```

등록된 회원 번호로 다시 넣어 본 뒤 실험을 되돌립니다. 맨 끝에 `rows_after_rollback`과 `0`이 나오면 실험용 대여 기록이 0건이라는 뜻입니다. [보너스 실제 출력](library-database/results/02_bonus.txt)

### 4. 데이터가 규칙대로 연결됐는지 확인하기

```sh
sqlite3 -init /dev/null -batch -bail -readonly "$practice_db" <<'SQL'
PRAGMA foreign_keys = ON;
PRAGMA foreign_keys;
PRAGMA foreign_key_check;
PRAGMA integrity_check;
SQL
```

`1`과 `ok`가 두 줄로 나오면 정상입니다. `1`은 외래키 검사가 켜졌다는 뜻이고, 그 다음에 위반 행이 표시되지 않으면 잘못 연결된 행이 0건입니다. `ok`는 SQLite 파일 자체의 검사도 통과했다는 뜻입니다.

## 동료 평가 확인표

Codyssey 미션 「정보를 깔끔하게 정리하는 디지털 서랍장 만들기」의 항목별 코드와 결과를 표에서 확인할 수 있습니다. 내려받은 글 파일에서는 Q 또는 B 번호를 검색하면 됩니다.

| 필수 항목 | 확인된 내용 | 근거 |
| --- | --- | --- |
| 실행 환경 | 로컬 SQLite CLI에서 SQL 파일을 실행 | [실행 가이드](#실행-가이드) |
| 스키마와 관계 | 테이블 4개와 PK 4개, 카테고리→도서·회원→대여·도서→대여의 1:N 관계 3개 | [스키마](library-database/01_schema.sql) · [ERD](library-database/erd.png) |
| 제약조건 | PK 중복, `NOT NULL`, `UNIQUE`, FK 및 날짜 `CHECK` 위반 입력을 거부 | [제약조건 검증](library-database/results/03_verification.txt#L6) |
| 테이블당 최소 10행 | 카테고리 10개, 회원 12명, 도서 15권, 대여 32건 | [INSERT SQL](library-database/02_sample_data.sql) · [SQLite DB](library-database/library.db) · [행 수 검증](library-database/results/03_verification.txt#L2) |
| 쿼리별 실행 기록 | 핵심 SQL 15개와 보너스 SQL의 목적, SQL 본문, 실제 출력 | [핵심 실행 기록](library-database/results/01_queries.txt) · [보너스 실행 기록](library-database/results/02_bonus.txt) |
| 최종 무결성 | 외래키 검사 활성화, 위반 0건, DB 무결성 검사 `ok` | [무결성 검증](library-database/results/03_verification.txt#L30) |

실행 환경의 화면 기록 권한이 없어 원본 미션에서 허용한 **실제 실행 결과 텍스트**를 사용했습니다. 기록은 SQLite CLI 3.43.2의 출력입니다.

<details>
<summary>핵심 SQL 15개와 보너스 3개의 근거 펼치기</summary>


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

</details>

핵심 명령 15개를 하나씩 읽어 보고 싶다면 학습 가이드에서 실제 코드와 결과를 나란히 볼 수 있습니다. [학습 가이드](library-database/learning_guide.md)

## 제출 방식

저장소를 공유하면 동료가 이 README에서 실행 방법과 평가 근거를 바로 볼 수 있습니다. 파일 한 개로 첨부해야 할 때는 전체 결과물을 묶은 ZIP을 사용할 수 있습니다. [첨부용 ZIP](library-database.zip)

## AI 활용 범위

사용자가 제공한 미션 명세에 따라 Codex가 스키마, 가상 데이터, SQL, 관계도와 문서를 작성하고 SQLite에서 실행과 검증을 수행했습니다.
