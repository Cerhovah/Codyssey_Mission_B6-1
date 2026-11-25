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

-- [Q05] 조인. 아직 반납하지 않은 책과 빌린 회원 이름을 함께 조회한다.
SELECT member.name, book.title
FROM rental
INNER JOIN member ON member.id = rental.member_id
INNER JOIN book ON book.id = rental.book_id
WHERE rental.returned_on IS NULL
ORDER BY rental.due_on, rental.id;

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
-- 1. 회원마다 연결된 대여를 붙인다. 대여가 없으면 대여 열이 NULL인 행을 남긴다.
-- 2. 회원 번호와 이름이 같은 행을 한 묶음으로 모은다.
-- 3. 각 묶음의 대여 번호를 센다. COUNT(r.id)는 NULL을 건너뛰므로 대여가 없으면 0이다.
-- 4. 건수가 많은 순으로, 동률이면 회원 번호순으로 정렬한다.
SELECT m.id AS member_id, m.name, COUNT(r.id) AS rental_count
FROM member AS m
LEFT JOIN rental AS r ON r.member_id = m.id
GROUP BY m.id, m.name
ORDER BY rental_count DESC, m.id;

-- [Q10] 집계. 반납한 대여의 경과 일수를 도서별로 합산한다.
-- SQLite의 julianday()로 두 날짜 사이의 일수 차이를 구한다.
-- 반납일이 NULL인 대여를 집계에서 빼고, 당일 반납은 경과 0일로 더한다.
SELECT book_id, SUM(julianday(returned_on) - julianday(rented_on)) AS total_days
FROM rental
WHERE returned_on IS NOT NULL
GROUP BY book_id
ORDER BY total_days DESC, book_id;

-- [Q11] 집계. 반납한 대여의 경과 일수를 도서별로 평균 낸다.
-- Q10과 같은 날짜 차이를 쓴다. 도서별 분모는 반납이 완료된 건수다.
SELECT book_id, AVG(julianday(returned_on) - julianday(rented_on)) AS average_days
FROM rental
WHERE returned_on IS NOT NULL
GROUP BY book_id
ORDER BY average_days DESC, book_id;

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
-- BEGIN과 Q14 뒤의 ROLLBACK으로 두 실습을 함께 되돌린다.
BEGIN;

UPDATE rental
SET returned_on = '2026-11-24'
WHERE id = 28;

SELECT id, returned_on
FROM rental
WHERE id = 28;

-- [Q14] 삭제. 32번 대여 기록을 삭제하고 해당 번호가 남아 있는지 센다.
DELETE FROM rental
WHERE id = 32;

SELECT COUNT(*) AS remaining_rows
FROM rental
WHERE id = 32;

-- 수정과 삭제를 확인한 뒤 샘플 데이터로 되돌린다.
ROLLBACK;

-- [Q15] 인덱스. 대여일 인덱스를 만들고 적용한 열을 확인한다.
-- 좁은 날짜 범위의 행을 찾거나 날짜순으로 읽을 때 도움이 된다.
-- 인덱스에도 기록을 보관하므로 저장 공간이 들고, 삽입·삭제·대여일 수정 때 유지 비용이 생긴다.
CREATE INDEX IF NOT EXISTS idx_rental_rented_on ON rental (rented_on);

-- SQLite 전용 PRAGMA로 인덱스에 포함된 열을 확인한다.
PRAGMA index_info(idx_rental_rented_on);
