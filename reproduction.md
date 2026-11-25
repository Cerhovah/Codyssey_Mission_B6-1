# 스키마부터 재현하기

VS Code에서 **Terminal → New Terminal**을 선택합니다. `README.md`와 `library-database` 폴더가 함께 있는 저장소 루트에서 아래 명령을 실행하세요. `:memory:`는 SQLite를 닫으면 없어지는 새 연습용 DB입니다.

```sh
sqlite3 -init /dev/null :memory:
```

## 1. 표와 샘플 데이터 만들기

`sqlite>`에서 아래 줄을 순서대로 실행합니다. `01`은 표와 제약조건을 만들고, `02`는 참조할 행부터 샘플 데이터를 채웁니다. `.read`는 지정한 SQL 파일을 읽어 실행합니다. [스키마](library-database/01_schema.sql) · [샘플 데이터](library-database/02_sample_data.sql)

```text
.bail on
.read library-database/01_schema.sql
.tables
.read library-database/02_sample_data.sql
.headers on
.mode column
.nullvalue NULL
```

`.tables`에서 `book`, `category`, `member`, `rental`이 보이면 테이블이 만들어진 것입니다.

## 2. 필수와 보너스 실행하기

같은 `sqlite>`에서 실행합니다. 필수 Q13과 Q14의 변경은 롤백되고, Q15는 이 DB에 대여일 인덱스를 만듭니다. B05에서 외래키 오류가 한 번 표시됩니다. `.bail off`로 오류 뒤의 복구와 롤백까지 실행한 다음, 마지막 결과가 `0`인지 확인합니다.

```text
.read library-database/03_queries.sql
.bail off
.read library-database/04_bonus.sql
```

## 3. 데이터 확인하고 닫기

```sql
SELECT id, returned_on FROM rental WHERE id IN (28, 32) ORDER BY id;
PRAGMA foreign_keys;
PRAGMA foreign_key_check;
PRAGMA integrity_check;
```

대여 28번의 반납일은 `NULL`이고, 32번은 다시 조회됩니다. `foreign_keys`의 값은 `1`입니다. `foreign_key_check` 뒤에 행이 없으면 위반이 0건이고, `integrity_check` 결과는 `ok`입니다. `.quit`으로 SQLite를 닫습니다. [검증 기록](library-database/results/03_verification.txt)

## 안 될 때

| 오류 | 해결 방법 |
| --- | --- |
| `cannot open "01_schema.sql"` | 저장소 루트에서 SQLite를 열었다면 `.read library-database/01_schema.sql`을 입력하세요. `library-database` 폴더에서 열었다면 `.read 01_schema.sql`을 사용합니다. |
| `.read: command not found` | 먼저 통합 터미널에서 `sqlite3 :memory:`를 실행한 뒤 `sqlite>`에서 `.read`와 `.tables`를 입력하세요. |
| `sqlite3: command not found` | 이 Mac의 기본 실행 파일인 `/usr/bin/sqlite3 :memory:`로 실행하세요. |
| `table ... already exists` | `.quit`으로 나온 뒤 새 `:memory:`를 열고 1단계부터 실행하세요. |
| `no such table: book` | 현재 임시 DB에 테이블이 없습니다. 같은 `sqlite>`에서 1단계의 스키마와 샘플 파일을 읽은 뒤 쿼리를 실행하세요. |
| 쿼리 실행 결과가 `0`과 `0\|3\|rented_on`만 나옴 | 테이블만 있고 샘플이 비어 있는 상태입니다. 같은 `sqlite>`에서 `02_sample_data.sql`을 읽고 쿼리를 다시 실행하세요. |
| 줄 끝의 역슬래시에서 `unrecognized token` 발생 | SQLite에 SQL을 붙여 넣을 때 프롬프트와 줄 끝의 역슬래시를 빼고, 마지막 줄을 세미콜론으로 끝내세요. |

SQL 문과 결과를 함께 보려면 `.read`로 쿼리 파일을 읽기 전에 `.echo on`을 입력하세요.

테이블 4개가 만들어지는지만 확인하려면 저장소 루트의 통합 터미널에서 아래 한 줄을 실행하세요. 출력이 표시되면 임시 DB를 닫습니다.

```sh
sqlite3 -init /dev/null -bail :memory: '.read library-database/01_schema.sql' '.tables'
```
