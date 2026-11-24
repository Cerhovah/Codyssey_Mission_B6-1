# 도서 대여 데이터베이스

Codyssey 미션 「정보를 깔끔하게 정리하는 디지털 서랍장 만들기」의 SQLite 결과물이다. 가상의 회원, 도서, 카테고리, 대여 기록을 저장하고 조회부터 조인, 집계, 수정, 삭제까지 SQL로 확인한다.

처음 읽을 때는 [학습 가이드](learning_guide.md)에서 1번 대여 기록이 어떤 테이블과 연결되는지 살펴본 뒤 [핵심 SQL 실행 결과](results/01_queries.txt)를 보면 된다.

## 실행 방법

SQLite CLI 3.35 이상을 사용한다. 아래 명령은 macOS와 Linux 기준이다. 실행 결과는 macOS의 SQLite CLI 3.43.2에서 저장했고, 제약조건과 쿼리 결과는 Python의 `sqlite3`(SQLite 3.51.3)로도 검증했다. 제공된 DB는 읽기 전용 모드로 열어 볼 수 있다.

```sh
cd library-database
sqlite3 -readonly -header -column library.db 'SELECT id, name FROM category ORDER BY id;'
```

다음 순서로 실행하면 새 `practice.db`에 스키마와 샘플 데이터를 만들고 Q01~Q15의 결과를 확인할 수 있다. `practice.db`가 이미 있으면 새 파일명을 사용한다.

```sh
sqlite3 -init /dev/null -batch -bail practice.db < 01_schema.sql
sqlite3 -init /dev/null -batch -bail practice.db < 02_sample_data.sql
sqlite3 -init /dev/null -batch -bail -echo -header -separator ' | ' -nullvalue NULL practice.db < 03_queries.sql
```

Q13과 Q14는 각각 28번 대여의 반납과 32번 대여의 삭제를 실제로 수행한 뒤 `ROLLBACK`으로 샘플 데이터를 복원한다. Q15가 만드는 대여일 인덱스는 DB에 저장된다. 제공된 `library.db`에는 인덱스가 이미 있으므로 생성 전후의 차이를 보려면 위와 같이 새 DB에서 실행한다.

```sh
sqlite3 -init /dev/null -batch -echo -header -separator ' | ' -nullvalue NULL practice.db < 04_bonus.sql 2>&1
```

보너스 B05에서는 의도한 `FOREIGN KEY constraint failed` 오류로 CLI가 종료 코드 `1`을 반환한다. 오류 뒤에 유효한 회원 번호로 입력을 다시 시도하고 실험 데이터를 롤백할 수 있도록 이 명령은 CLI의 기본 오류 처리 동작을 사용한다.

## 파일 구성

| 파일 | 역할 |
| --- | --- |
| [01_schema.sql](01_schema.sql) | 테이블 4개, 기본키, 외래키, 제약조건 |
| [02_sample_data.sql](02_sample_data.sql) | 부모 테이블부터 순서대로 등록하는 가상 데이터 |
| [03_queries.sql](03_queries.sql) | 목적을 주석으로 표시한 핵심 SQL 15개 |
| [04_bonus.sql](04_bonus.sql) | JOIN과 서브쿼리 비교, 지표 3개, 외래키 오류와 복구 실험 |
| [library.db](library.db) | 샘플 데이터와 대여일 인덱스가 들어 있는 SQLite 파일 |
| [erd.png](erd.png) | 테이블과 PK·FK·1:N 관계를 표시한 ERD |
| [results/](results/) | 핵심 SQL과 보너스의 실제 CLI 출력 및 검증 기록 |
| [bonus_report.md](bonus_report.md) | 보너스 실험 결과와 지표 해석 |
| [learning_guide.md](learning_guide.md) | 초보자를 위한 스키마 및 쿼리 해설 |

## 요구사항과 검증 결과

| 항목 | 완료 내용 |
| --- | --- |
| 스키마 | `category` → `book`, `member` → `rental`, `book` → `rental`의 1:N 관계 3개 |
| 제약조건 | 테이블 4개의 PK, FK 3개, `NOT NULL`, `UNIQUE`, 날짜 형식과 순서에 대한 `CHECK` 검증 |
| 샘플 데이터 | 카테고리 10개, 회원 12명, 도서 15권, 대여 32건 |
| 핵심 SQL | 기본 조회 4개, 조인 4개(`INNER JOIN` 사용 쿼리 3개와 `LEFT JOIN` 사용 쿼리 1개), 집계 3개, 서브쿼리 1개, UPDATE·DELETE 2개, 인덱스 1개 |
| 보너스 | JOIN과 EXISTS 결과 일치, 실제 FK 오류 및 올바른 입력 확인, 핵심 지표 3개 산출 |
| 제출 자료 | SQL, DB, ERD와 쿼리별 실행 로그를 ZIP에 포함 |

각 SQL 파일은 연결에 `PRAGMA foreign_keys = ON`을 적용한다. 검증 연결에서 외래키 활성화 값은 `1`이었고, `PRAGMA foreign_key_check`는 위반 행 0개, `PRAGMA integrity_check`는 `ok`를 반환했다. 테이블별 행 수와 UPDATE·DELETE 롤백, 인덱스 사용도 확인했다. [검증 기록](results/03_verification.txt)

실행 환경에 화면 녹화 권한이 없어 Q01~Q15와 보너스 결과는 SQLite CLI의 실제 텍스트 출력으로 저장했다.

## AI 활용 범위

사용자가 제공한 원본 미션과 실행 지시에 따라 Codex가 데이터 모델과 가상 샘플을 설계하고 SQL, ERD, 리포트, 학습 문서를 작성했다. SQLite에서 SQL을 실행해 결과를 저장하고 제약조건과 조회 결과를 검증했다.
