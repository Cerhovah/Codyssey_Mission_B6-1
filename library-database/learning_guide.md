# 도서 대여 SQL 학습 가이드

아래 설명은 [스키마](01_schema.sql), [핵심 SQL](03_queries.sql), [실제 실행 결과](results/01_queries.txt)의 번호와 연결된다.

## 어디부터 읽으면 될까

표를 만드는 `CREATE TABLE`과 예시를 넣는 `INSERT`를 먼저 살펴본다. 조회에서는 `SELECT`로 열을 고르고 `WHERE`로 행을 고르는 것부터 읽는다. 번호로 표를 연결하는 `JOIN`, 같은 종류끼리 묶는 `GROUP BY`로 넘어가면 된다.

`BEGIN`은 변경을 한 묶음으로 시작하고 `ROLLBACK`은 그 묶음을 실행 전 상태로 되돌린다. `PRAGMA`는 SQLite 설정을 바꾸거나 상태를 확인하는 명령이고, 날짜의 `CHECK`는 잘못된 값의 저장을 막는 조건이다. 처음에는 각각의 역할을 알아두면 된다. `.read`는 SQLite 명령줄에서 파일의 SQL을 실행하는 기능이다. [실행 방법](README.md#실행-가이드)

## 대여 한 건이 네 테이블과 연결되는 방법

엑셀에서도 시트를 나누고 숫자로 다른 시트의 행을 찾아올 수 있다. 관계형 데이터베이스는 테이블 사이의 참조와 입력 규칙을 스키마에 선언하고, 데이터를 저장할 때 그 규칙을 검사한다. 이 프로젝트에서 등록되지 않은 회원 번호를 사용하면 SQLite가 대여 입력을 거부한다.

| 테이블 | 한 행이 뜻하는 것 | 다른 테이블과의 관계 |
| --- | --- | --- |
| `member` | 이름, 이메일, 가입일을 가진 회원 한 명 | 회원 한 명에게 대여 기록이 여러 건 생길 수 있다. |
| `category` | 소설, 과학 등의 카테고리 하나 | 카테고리 하나에 도서가 여러 권 속할 수 있다. |
| `book` | 제목, 저자, 카테고리를 가진 도서 한 권 | 도서 한 권에 시점이 다른 대여 기록이 쌓인다. |
| `rental` | 누가 어떤 책을 언제 빌리고 반납했는지 나타내는 대여 한 건 | 회원 한 명과 도서 한 권을 참조한다. |

예를 들어 대여 1번의 `member_id = 1`은 김하늘 회원을, `book_id = 1`은 《바다의 우체국》을 가리킨다. 도서의 `category_id = 1`을 따라가면 소설이라는 분류를 찾을 수 있다. 대여가 생길 때마다 이름이나 책 제목을 복사할 필요가 없고, 이름을 바꾸면 이후 조회에도 회원 테이블의 수정된 값이 표시된다. [ERD 보기](erd.png)

**PK(기본키)**는 테이블에서 행 하나를 식별한다. 네 테이블에 각각 `id INTEGER PRIMARY KEY`가 있다. **FK(외래키)**는 다른 테이블의 행을 가리킨다. `rental.member_id`는 `member.id`를 참조하므로 김하늘의 대여 1번과 6번은 같은 회원을 가리킨다. 이 **1:N 관계**에서 회원 한 명은 대여가 0건이거나 여러 건일 수 있고, 대여 한 건은 회원 한 명에 속한다.

**제약조건**은 저장할 수 있는 값의 규칙이다. `NOT NULL`은 회원 이름과 같은 필수 값을, `UNIQUE`는 회원 이메일과 같은 값의 고유성을 보장한다. `CHECK`는 날짜를 `YYYY-MM-DD` 텍스트로 제한하고 반납기한이나 반납일이 대여일보다 빠르면 저장을 막는다. `returned_on`의 `NULL`은 아직 반납일이 없다는 뜻이다. SQLite에서 연결을 열 때 `PRAGMA foreign_keys = ON`을 실행하면 외래키를 검사한다. 이런 규칙을 지켜 데이터가 서로 모순되지 않는 상태를 **데이터 무결성**이라고 한다.

## SQL로 행을 다루는 네 가지 방법

| 동작 | SQL | 제출물에서 볼 수 있는 예 |
| --- | --- | --- |
| 생성(Create) | `INSERT` | `02_sample_data.sql`이 카테고리, 회원, 도서, 대여를 순서대로 입력한다. |
| 조회(Read) | `SELECT` | Q01이 소설 카테고리의 도서 번호, 제목, 저자를 읽는다. |
| 수정(Update) | `UPDATE` | Q13이 대여 28번에 반납일을 기록한다. |
| 삭제(Delete) | `DELETE` | Q14가 대여 32번을 삭제한다. |

`CREATE TABLE`은 비어 있는 테이블의 구조를 만들고, `INSERT`는 그 구조에 행을 넣는다. 샘플 데이터에서 부모가 먼저 등록되어야 도서와 대여가 외래키로 참조할 행을 찾을 수 있다.

## 핵심 쿼리 15개 읽기

### Q01 소설 도서 목록

`SELECT id AS book_id, title, author`는 표시할 세 열을 고르고 `AS`로 결과 열 이름을 정한다. `WHERE category_id = 1`로 범위를 좁히고 `ORDER BY title, id`로 정렬한다. 첫 행은 《골목 끝 책방》이고 소설 도서가 모두 3권 나왔다.

### Q02 제목 검색

`WHERE title LIKE '%바다%'`에서 양쪽의 `%`는 앞뒤에 글자가 0개 이상 올 수 있다는 뜻이다. 《바다의 우체국》과 《바다를 따라 걷는 길》 두 권이 도서 번호순으로 나왔다.

### Q03 최근 가입 회원

`ORDER BY joined_on DESC, id DESC`는 가입일이 최신인 순서, 같은 날이면 번호가 큰 순서로 정렬한다. `LIMIT 5`로 앞의 다섯 행만 가져온다. 조하진과 신나연은 2026-11-10에 가입했고, 번호가 12인 조하진이 첫 행이다.

### Q04 11월 대여

`rented_on >= '2026-11-01'`과 `rented_on < '2026-12-01'`을 `AND`로 묶어 11월에 시작한 대여를 고른다. 고정된 `YYYY-MM-DD` 텍스트는 날짜순과 문자열 정렬 순서가 같다. 대여 20~32번 13건이 날짜순으로 나왔다.

### Q05 미반납 대여에 회원명과 책 제목 붙이기

```sql
SELECT member.name, book.title
FROM rental
INNER JOIN member ON member.id = rental.member_id
INNER JOIN book ON book.id = rental.book_id
WHERE rental.returned_on IS NULL
ORDER BY rental.due_on, rental.id;
```

`FROM rental`에서 대여 표를 읽는다. 첫 `ON`은 회원 번호를 맞춰 이름을 가져오고, 둘째 `ON`은 도서 번호를 맞춰 제목을 가져온다. 반납일이 비어 있는 대여만 고른 결과는 5건이다. 첫 행의 이름과 제목은 정유진과 《한 페이지의 산책》이다.

### Q06 도서별 카테고리 이름

`book AS b`와 `category AS c`는 같은 SQL 문 안에서 표 이름을 짧게 부르는 방법이다. `ON c.id = b.category_id`로 도서의 카테고리 번호를 맞춘다. 도서 15권이 모두 조회됐고 《바다의 우체국》의 카테고리는 소설로 표시됐다.

### Q07 대여하지 않은 회원까지 표시하기

`LEFT JOIN rental AS r ON r.member_id = m.id`는 왼쪽 테이블인 `member`를 기준으로 결과를 만든다. 김하늘은 대여가 5건이라 다섯 행에 나오고, 신나연과 조하진은 각각 한 행에 나오되 `rental_id`와 `rented_on`이 `NULL`이다. `INNER JOIN`은 조인 조건을 만족하는 양쪽 행을 반환한다. `LEFT JOIN`은 왼쪽의 모든 행을 반환하고 오른쪽에 짝이 없을 때 그쪽 열을 `NULL`로 채운다.

### Q08 마감 뒤에 반납한 도서

`INNER JOIN book`으로 도서 제목을 얻은 뒤 `WHERE r.returned_on > r.due_on`을 적용한다. 기한이 지나 반납한 대여 8건이 나왔다. 2번 대여는 기한이 9월 9일이었고 9월 11일에 반납됐다. 미반납 행의 `returned_on`을 날짜와 비교한 결과는 `NULL`이고, `WHERE`는 비교 결과가 참인 행만 고른다.

### Q09 회원별 대여 건수

```sql
SELECT m.id AS member_id, m.name, COUNT(r.id) AS rental_count
FROM member AS m
LEFT JOIN rental AS r ON r.member_id = m.id
GROUP BY m.id, m.name
ORDER BY rental_count DESC, m.id;
```

`GROUP BY`는 조인 결과를 회원별 묶음으로 만든다. `COUNT(r.id)`는 각 묶음에서 대여 번호가 있는 행을 세므로 김하늘은 5건이고 신나연과 조하진은 각각 0건이다. `COUNT(*)`는 대여 정보가 `NULL`인 행도 한 행으로 센다.

### Q10 도서별 누적 대여 일수

```sql
SELECT book_id, SUM(julianday(returned_on) - julianday(rented_on)) AS total_days
FROM rental
WHERE returned_on IS NOT NULL
GROUP BY book_id
ORDER BY total_days DESC, book_id;
```

반납일이 있는 대여를 `GROUP BY book_id`로 책마다 묶는다. `julianday()`는 뺄셈에 쓸 수 있도록 날짜를 숫자로 바꿔 준다. `SUM`은 같은 책의 날짜 차이를 더한다. 도서 1번 《바다의 우체국》의 반납된 대여 네 건은 4일, 11일, 6일, 9일이어서 합계가 `30.0`일이다.

### Q11 도서별 평균 대여 일수

Q10과 같이 반납한 대여를 책마다 묶는다. `AVG`는 한 묶음의 값을 더해서 그 묶음의 대여 건수로 나눈다. 도서 1번의 평균은 30일을 4건으로 나눈 `7.5`일이다.

### Q12 대여 이력이 없는 회원

`WHERE NOT EXISTS (...)` 안의 `WHERE r.member_id = m.id`는 바깥 쿼리의 현재 회원 번호를 사용한다. 내부 `SELECT 1`은 조건을 만족하는 행이 있는지만 확인한다. 한 건도 찾지 못한 회원은 신나연과 조하진 두 명이다.

### Q13 대여 반납 처리

`UPDATE rental SET returned_on = '2026-11-24'`로 반납일을 기록한다. `WHERE id = 28`이 바꿀 행을 고른다. 다음 `SELECT id, returned_on`에서 대여 28번의 바뀐 반납일 `2026-11-24`를 읽는다.

### Q14 대여 기록 삭제

`DELETE FROM rental WHERE id = 32`는 대여 32번을 삭제한다. 같은 번호의 행을 `COUNT(*)`로 세면 `remaining_rows`가 `0`이다. Q13과 Q14는 `BEGIN`으로 묶어서 실행하고 마지막 `ROLLBACK`에서 두 변경을 되돌린다.

### Q15 대여일 인덱스

`CREATE INDEX IF NOT EXISTS idx_rental_rented_on ON rental (rented_on)`은 대여일로 기록을 찾는 데 쓰이는 검색용 목록을 만든다. Q04처럼 날짜 범위를 조회할 때 쓰이는 열이다. 뒤의 SQLite 확인 명령 `PRAGMA index_info`를 실행하면 결과의 `name` 열에 `rented_on`이 나온다.

## 보너스에서 확인한 내용

- **JOIN과 서브쿼리**로 11월에 대여한 회원을 구하자 둘 다 10명이 나왔다. JOIN 결과의 중복 회원은 `DISTINCT`로 줄였고, `EXISTS`는 대여가 있는 회원을 조건으로 골랐다.
- **외래키 실험**에서는 회원 9999번을 참조한 대여가 거부됐다. 이미 등록된 회원 1번을 참조하자 입력이 성공했다.
- **미니 리포트**는 월별 대여 건수, 인기 도서 10권, 반납기한이 지난 미반납 대여 건수를 센다. 11월 대여는 13건이다. 2026-11-24 기준 미반납 연체는 24번과 28번 두 건이다. [보너스 리포트](bonus_report.md)

## 백엔드와 ORM에서 같은 관계 읽기

백엔드는 화면에 회원별 대여 수나 미반납 도서를 보여 줄 때 Q09나 Q05처럼 데이터를 조회할 수 있다. ORM에서 대여 객체가 회원 객체를 참조하더라도 DB에서는 `rental.member_id`가 `member.id`를 가리킨다. 코드로 관계를 정의한 뒤 생성된 SQL을 보면 어느 키로 조인하는지, 대여 기록이 없는 회원까지 결과에 들어가는지 확인할 수 있다.
