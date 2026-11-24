-- SQLite 전용 PRAGMA. 외래키 검사는 연결마다 켠다.
PRAGMA foreign_keys = ON;

BEGIN;

CREATE TABLE category (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE member (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    -- SQLite의 date()로 실제 달력 날짜를 YYYY-MM-DD 형식으로 제한한다.
    joined_on TEXT NOT NULL CHECK (
        length(joined_on) = 10 AND date(joined_on, '+0 days') IS joined_on
    )
);

CREATE TABLE book (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    category_id INTEGER NOT NULL,
    FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE RESTRICT
);

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
