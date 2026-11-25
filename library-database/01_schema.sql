-- SQLite 전용 PRAGMA. 외래키 검사는 연결마다 켠다.
PRAGMA foreign_keys = ON;

-- PK와 FK는 번호를 일관되게 연결하도록 INTEGER로 둔다.
-- 이름·제목·이메일은 문자열이므로 TEXT로 둔다.
-- 날짜도 TEXT로 저장한다. YYYY-MM-DD는 읽기 쉽고 날짜순으로 정렬된다.

BEGIN;

-- category.id는 이름이 바뀌어도 도서가 같은 카테고리를 참조하게 한다.
CREATE TABLE category (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

-- member.id는 동명이인을 구분하고 대여를 회원 한 명에게 연결한다.
CREATE TABLE member (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    -- SQLite의 date()로 실제 달력 날짜를 YYYY-MM-DD 형식으로 제한한다.
    joined_on TEXT NOT NULL CHECK (
        length(joined_on) = 10 AND date(joined_on, '+0 days') IS joined_on
    )
);

-- book.id는 제목이 같은 도서를 구분하고 대여의 참조 대상으로 쓴다.
CREATE TABLE book (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    category_id INTEGER NOT NULL,
    FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE RESTRICT
);

-- rental.id는 같은 회원이 같은 도서를 다시 빌려도 각 대여를 구분한다.
CREATE TABLE rental (
    id INTEGER PRIMARY KEY,
    member_id INTEGER NOT NULL,
    book_id INTEGER NOT NULL,
    -- SQLite date()로 달력 날짜를 검사한다. 미반납은 returned_on의 NULL로 저장한다.
    rented_on TEXT NOT NULL CHECK (
        length(rented_on) = 10 AND date(rented_on, '+0 days') IS rented_on
    ),
    due_on TEXT NOT NULL CHECK (
        length(due_on) = 10 AND date(due_on, '+0 days') IS due_on
    ),
    returned_on TEXT CHECK (
        returned_on IS NULL OR (
            length(returned_on) = 10 AND date(returned_on, '+0 days') IS returned_on
        )
    ),
    CHECK (due_on >= rented_on),
    CHECK (returned_on IS NULL OR returned_on >= rented_on),
    FOREIGN KEY (member_id) REFERENCES member (id) ON DELETE RESTRICT,
    FOREIGN KEY (book_id) REFERENCES book (id) ON DELETE RESTRICT
);

COMMIT;
