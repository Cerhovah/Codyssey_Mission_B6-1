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
-- SQLite의 substr()로 YYYY-MM-DD에서 앞 일곱 글자인 YYYY-MM을 가져온다.
SELECT substr(rented_on, 1, 7) AS rental_month, COUNT(*) AS rental_count
FROM rental
GROUP BY substr(rented_on, 1, 7)
ORDER BY rental_month;

-- [B03] 미니 리포트. 대여 건수가 많은 도서 열 권을 찾는다.
-- 동률이면 도서 번호순으로 정렬하고 SQLite의 LIMIT으로 열 행만 가져온다.
SELECT book_id, COUNT(*) AS rental_count
FROM rental
GROUP BY book_id
ORDER BY rental_count DESC, book_id
LIMIT 10;

-- [B04] 미니 리포트. 기준일 2026-11-24에 반납기한이 지난 미반납 대여를 센다.
SELECT COUNT(*) AS overdue_count
FROM rental
WHERE returned_on IS NULL
  AND due_on < '2026-11-24';

-- [B05] 무결성 실험. 없는 회원 번호를 참조하면 SQLite가 아래 INSERT를 거부한다.
-- SQLite CLI는 예상된 오류 다음 줄도 실행하도록 기본값 .bail off를 사용한다.
BEGIN;

INSERT INTO rental (id, member_id, book_id, rented_on, due_on)
VALUES (999, 9999, 11, '2026-11-24', '2026-12-01');

SELECT COUNT(*) AS rows_after_failed_insert
FROM rental
WHERE id = 999;

-- 실제 등록된 1번 회원으로 바꿔 입력한 뒤 SELECT로 확인한다.
INSERT INTO rental (id, member_id, book_id, rented_on, due_on)
VALUES (999, 1, 11, '2026-11-24', '2026-12-01');

SELECT id, member_id, book_id
FROM rental
WHERE id = 999;

ROLLBACK;

SELECT COUNT(*) AS rows_after_rollback
FROM rental
WHERE id = 999;
