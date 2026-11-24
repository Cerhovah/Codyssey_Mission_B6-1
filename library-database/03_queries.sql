-- SQLite 전용 PRAGMA. 아래 UPDATE와 DELETE를 실행하는 연결에도 적용한다.
PRAGMA foreign_keys = ON;

-- [Q01] 기본 조회. 소설 카테고리의 도서를 제목순으로 조회한다.
SELECT id AS book_id, title, author
FROM book
WHERE category_id = 1
ORDER BY title, id;

-- [Q02] 기본 조회. 제목에 '바다'가 들어간 도서를 검색한다.
SELECT id AS book_id, title
FROM book
WHERE title LIKE '%바다%'
ORDER BY id;

-- [Q03] 기본 조회. 최근 가입 회원 다섯 명을 확인한다.
-- LIMIT은 SQLite에서 지원하는 행 수 제한 문법이다.
SELECT id AS member_id, name, joined_on
FROM member
ORDER BY joined_on DESC, id DESC
LIMIT 5;

-- [Q04] 기본 조회. 2026년 11월에 시작한 대여를 날짜순으로 조회한다.
SELECT id AS rental_id, rented_on
FROM rental
WHERE rented_on >= '2026-11-01'
  AND rented_on < '2026-12-01'
ORDER BY rented_on, id;

-- [Q05] 조인. 미반납 대여의 회원명, 도서명, 반납기한을 확인한다.
SELECT r.id AS rental_id, m.name AS member_name, b.title, r.due_on
FROM rental AS r
INNER JOIN member AS m ON m.id = r.member_id
INNER JOIN book AS b ON b.id = r.book_id
WHERE r.returned_on IS NULL
ORDER BY r.due_on, r.id;

-- [Q06] 조인. 도서 목록에 각 도서가 속한 카테고리 이름을 표시한다.
SELECT b.id AS book_id, b.title, c.name AS category_name
FROM book AS b
INNER JOIN category AS c ON c.id = b.category_id
ORDER BY c.id, b.id;

-- [Q07] 조인. 대여 이력이 없는 회원을 포함해 회원별 대여 기록을 조회한다.
SELECT m.id AS member_id, m.name, r.id AS rental_id, r.rented_on
FROM member AS m
LEFT JOIN rental AS r ON r.member_id = m.id
ORDER BY m.id, r.rented_on, r.id;

-- [Q08] 조인. 기한 뒤에 반납된 대여와 해당 도서 제목을 확인한다.
SELECT r.id AS rental_id, b.title, r.due_on, r.returned_on
FROM rental AS r
INNER JOIN book AS b ON b.id = r.book_id
WHERE r.returned_on > r.due_on
ORDER BY r.returned_on, r.id;

-- [Q09] 집계. 대여 이력이 없는 회원을 포함해 회원별 대여 건수를 센다.
SELECT m.id AS member_id, m.name, COUNT(r.id) AS rental_count
FROM member AS m
LEFT JOIN rental AS r ON r.member_id = m.id
GROUP BY m.id, m.name
ORDER BY rental_count DESC, m.id;

-- [Q10] 집계. 반납한 대여의 경과 일수를 도서별로 합산한다.
-- SQLite의 julianday()로 두 날짜 사이의 일수 차이를 구한다.
SELECT b.id AS book_id, b.title,
       SUM(CAST(julianday(r.returned_on) - julianday(r.rented_on) AS INTEGER)) AS total_days
FROM book AS b
INNER JOIN rental AS r ON r.book_id = b.id
WHERE r.returned_on IS NOT NULL
GROUP BY b.id, b.title
ORDER BY total_days DESC, b.id;

-- [Q11] 집계. 카테고리별로 반납한 대여의 평균 경과 일수를 계산한다.
-- SQLite의 julianday()로 일수 차이를 계산하고 소수점 한 자리까지 표시한다.
SELECT c.id AS category_id, c.name AS category_name,
       ROUND(AVG(julianday(r.returned_on) - julianday(r.rented_on)), 1) AS average_days
FROM category AS c
INNER JOIN book AS b ON b.category_id = c.id
INNER JOIN rental AS r ON r.book_id = b.id
WHERE r.returned_on IS NOT NULL
GROUP BY c.id, c.name
ORDER BY average_days DESC, c.id;

-- [Q12] 서브쿼리. 대여 기록이 한 건도 없는 회원을 찾는다.
SELECT m.id AS member_id, m.name
FROM member AS m
WHERE NOT EXISTS (
    SELECT 1
    FROM rental AS r
    WHERE r.member_id = m.id
)
ORDER BY m.id;

-- [Q13] 수정. 미반납 상태인 28번 대여를 2026년 11월 24일에 반납 처리한다.
-- SQLite 3.35 이상의 RETURNING으로 변경된 행을 확인한다.
BEGIN;

UPDATE rental
SET returned_on = '2026-11-24'
WHERE id = 28 AND returned_on IS NULL
RETURNING id AS rental_id, returned_on;

-- [Q14] 삭제. 32번 대여 기록의 삭제를 시연하고 삭제된 행을 확인한다.
-- SQLite 3.35 이상의 RETURNING으로 삭제한 행의 값을 확인한다.
DELETE FROM rental
WHERE id = 32
RETURNING id AS rental_id, member_id, book_id;

-- 수정과 삭제를 확인한 뒤 샘플 데이터로 되돌린다.
ROLLBACK;

-- [Q15] 인덱스. 대여일 인덱스를 만들고 Q04의 실행 계획을 전후로 확인한다.
-- rented_on 인덱스는 날짜 범위에 해당하는 행을 찾고 날짜순으로 읽는 데 쓰인다.
-- SQLite의 EXPLAIN QUERY PLAN으로 실행 계획을 표시한다.
EXPLAIN QUERY PLAN
SELECT id AS rental_id, rented_on
FROM rental
WHERE rented_on >= '2026-11-01'
  AND rented_on < '2026-12-01'
ORDER BY rented_on, id;

CREATE INDEX IF NOT EXISTS idx_rental_rented_on ON rental (rented_on);

EXPLAIN QUERY PLAN
SELECT id AS rental_id, rented_on
FROM rental
WHERE rented_on >= '2026-11-01'
  AND rented_on < '2026-12-01'
ORDER BY rented_on, id;
