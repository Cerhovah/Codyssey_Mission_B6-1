-- SQLite 전용 PRAGMA. 마지막 외래키 실험에 필요하다.
PRAGMA foreign_keys = ON;

-- [B01A] JOIN으로 2026년 11월에 대여한 회원을 한 번씩 조회한다.
SELECT DISTINCT m.id AS member_id, m.name
FROM member AS m
INNER JOIN rental AS r ON r.member_id = m.id
WHERE r.rented_on >= '2026-11-01'
  AND r.rented_on < '2026-12-01'
ORDER BY m.id;

-- [B01B] EXISTS 서브쿼리로 같은 회원 목록을 조회한다.
SELECT m.id AS member_id, m.name
FROM member AS m
WHERE EXISTS (
    SELECT 1
    FROM rental AS r
    WHERE r.member_id = m.id
      AND r.rented_on >= '2026-11-01'
      AND r.rented_on < '2026-12-01'
)
ORDER BY m.id;

-- [B02] 미니 리포트. 대여 시작일을 기준으로 월별 대여 건수를 센다.
-- SQLite의 strftime()으로 YYYY-MM 형식의 연월을 구한다.
SELECT strftime('%Y-%m', rented_on) AS rental_month, COUNT(*) AS rental_count
FROM rental
GROUP BY strftime('%Y-%m', rented_on)
ORDER BY rental_month;

-- [B03] 미니 리포트. 대여 건수가 많은 도서 열 권을 찾는다.
-- 동률이면 도서 번호순으로 정렬하고 SQLite의 LIMIT으로 열 행만 가져온다.
SELECT b.id AS book_id, b.title, COUNT(*) AS rental_count
FROM book AS b
INNER JOIN rental AS r ON r.book_id = b.id
GROUP BY b.id, b.title
ORDER BY rental_count DESC, b.id
LIMIT 10;

-- [B04] 미니 리포트. 기준일 2026-11-24의 회원별 연체율을 계산한다.
-- 평가 대상은 기준일까지 반납됐거나 반납기한이 지난 대여다.
WITH reference_date AS (
    SELECT '2026-11-24' AS as_of
),
assessed_rental AS (
    SELECT r.member_id,
           CASE
               WHEN r.due_on < d.as_of
                    AND (r.returned_on IS NULL OR r.returned_on > r.due_on)
               THEN 1
               ELSE 0
           END AS is_late
    FROM rental AS r
    CROSS JOIN reference_date AS d
    WHERE r.rented_on <= d.as_of
      AND (r.returned_on <= d.as_of OR r.due_on < d.as_of)
)
SELECT m.id AS member_id, m.name,
       COUNT(a.member_id) AS assessed_count,
       COALESCE(SUM(a.is_late), 0) AS late_count,
       ROUND(100.0 * SUM(a.is_late) / NULLIF(COUNT(a.member_id), 0), 1) AS late_rate_pct
FROM member AS m
LEFT JOIN assessed_rental AS a ON a.member_id = m.id
GROUP BY m.id, m.name
ORDER BY late_rate_pct DESC, m.id;

-- [B05] 무결성 실험. 없는 회원 번호를 참조하면 SQLite가 아래 INSERT를 거부한다.
-- SQLite CLI는 예상된 오류 이후에도 계속 실행하도록 -bail 없이 사용한다.
BEGIN;

INSERT INTO rental (id, member_id, book_id, rented_on, due_on)
VALUES (999, 9999, 11, '2026-11-24', '2026-12-01');

SELECT COUNT(*) AS rows_after_failed_insert
FROM rental
WHERE id = 999;

-- 실제 등록된 1번 회원으로 바꾸면 입력할 수 있다. SQLite 3.35+ RETURNING.
INSERT INTO rental (id, member_id, book_id, rented_on, due_on)
VALUES (999, 1, 11, '2026-11-24', '2026-12-01')
RETURNING id AS rental_id, member_id, book_id;

ROLLBACK;

SELECT COUNT(*) AS rows_after_rollback
FROM rental
WHERE id = 999;
