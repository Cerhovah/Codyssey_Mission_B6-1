# 동료 평가표

Codyssey 미션 「정보를 깔끔하게 정리하는 디지털 서랍장 만들기」의 필수·보너스 항목을 코드와 실제 실행 결과에서 확인할 수 있습니다. VS Code에서 시연할 때는 [README](README.md)의 전체 시연 Task를 실행하고, 출력에서 Q 또는 B 번호를 찾으세요.

## 필수 요구사항

| 요구사항 | 확인할 결과 | 근거 |
| --- | --- | --- |
| 실행 환경 | 로컬 SQLite CLI에서 필수·보너스 SQL을 각각 한 줄로 실행합니다. | [시연 방법](README.md#vs-code에서-전체-시연) · [처음부터 재현](reproduction.md) |
| 테이블 4개와 PK 4개 | 카테고리·회원·도서·대여에 각각 기본키가 있습니다. | [스키마와 PK 주석](library-database/01_schema.sql) · [관계도](library-database/erd.png) |
| 외래키와 관계 | 카테고리 → 도서, 회원 → 대여, 도서 → 대여의 1:N 관계 3개입니다. | [대여 한 건으로 보는 구조](library-database/learning_guide.md#대여-한-건이-네-테이블과-연결되는-방법) · [FK 검사](library-database/results/03_verification.txt#L33) |
| 제약조건 | PK 중복, 필수 값 누락, UNIQUE 중복, FK와 날짜 CHECK 위반을 거부합니다. | [제약조건 검사](library-database/results/03_verification.txt#L6) |
| 테이블당 최소 10행 | 카테고리 10행, 회원 12행, 도서 15행, 대여 32행입니다. | [샘플 SQL](library-database/02_sample_data.sql) · [제출 DB](library-database/library.db) · [행 수](library-database/results/03_verification.txt#L2) |
| 실행 증빙 | Q01~Q15 및 B01A~B05의 SQL과 실제 출력 텍스트, 터미널 출력 캡처 이미지 7장이 있습니다. | [필수 텍스트](library-database/results/01_queries.txt) · [보너스 텍스트](library-database/results/02_bonus.txt) · [캡처](library-database/results/screenshots/README.md) |
| 무결성 | 외래키 활성화 값은 1, 외래키 위반은 0행, 구조 검사 결과는 `ok`입니다. 새 DB와 제출용 DB의 스키마·인덱스·데이터가 일치합니다. | [제출 DB 대조와 무결성](library-database/results/03_verification.txt#L31) |

## 필수 SQL 15개

| 번호 | 유형 | 확인할 결과 |
| --- | --- | --- |
| Q01 | 기본 조회 | 소설 도서 3권을 제목순으로 조회합니다. |
| Q02 | 기본 조회 | 제목에 ‘바다’가 들어간 책 2권을 찾습니다. |
| Q03 | 기본 조회 | 가장 최근에 가입한 회원 5명을 표시합니다. |
| Q04 | 기본 조회 | 2026년 11월에 시작한 대여 13건을 날짜순으로 표시합니다. |
| Q05 | INNER JOIN | 미반납 대여 5건의 회원 이름과 도서 제목을 읽습니다. |
| Q06 | INNER JOIN | 도서 15권과 카테고리 이름을 표시합니다. |
| Q07 | LEFT JOIN | 34행을 읽습니다. 대여가 없는 신나연과 조하진의 대여 열은 `NULL`입니다. |
| Q08 | INNER JOIN | 기한 뒤에 반납한 대여 8건과 도서 제목을 표시합니다. |
| Q09 | GROUP BY + COUNT | 12명의 대여 건수를 셉니다. 김하늘 5건, 신나연·조하진 0건입니다. |
| Q10 | GROUP BY + SUM | 반납을 마친 대여의 경과 일수를 도서별로 더합니다. 도서 1번은 30일입니다. |
| Q11 | GROUP BY + AVG | 도서별 평균 경과 일수를 구합니다. 도서 1번은 7.5일입니다. |
| Q12 | 서브쿼리 | `NOT EXISTS`로 대여 이력이 없는 2명을 찾습니다. |
| Q13 | UPDATE | 대여 28번의 반납일을 2026-11-24로 바꾼 뒤 조회합니다. |
| Q14 | DELETE | 대여 32번 삭제 뒤 0행을 표시합니다. 롤백 후 28번의 반납일과 32번 행이 복원됩니다. |
| Q15 | 인덱스 | `rented_on`에 인덱스를 만들고 해당 열을 확인합니다. 새 DB에서 Q04의 실행 계획이 인덱스 검색으로 바뀝니다. |

각 번호의 주석 아래에 해당 SQL과 결과가 있습니다. 시연에서는 복사본에서 기존 인덱스를 먼저 제거하므로 Q15가 실제로 인덱스를 생성합니다. [SQL](library-database/03_queries.sql) · [출력](library-database/results/01_queries.txt) · [롤백 및 실행 계획](library-database/results/03_verification.txt#L23)

## 보너스 3개

| 요구사항 | 확인할 결과 | 근거 |
| --- | --- | --- |
| 같은 질문을 두 방법으로 풀기 | B01A의 JOIN과 B01B의 EXISTS가 같은 11월 대여 회원 10명을 반환합니다. | [SQL](library-database/04_bonus.sql#L4) · [출력](library-database/results/02_bonus.txt#L4) |
| 외래키 오류와 복구 | B05에서 등록되지 않은 회원 9999번으로 입력하면 실패합니다. 등록된 1번으로 고쳐 성공한 뒤 롤백하면 실험 행이 0개입니다. | [SQL](library-database/04_bonus.sql#L45) · [출력](library-database/results/02_bonus.txt#L84) |
| 지표 3개 | B02 월별 대여 건수 9·10·13건, B03 인기 도서 상위 10권, B04 2026-11-24 기준 미반납 연체 2건입니다. | [SQL](library-database/04_bonus.sql#L24) · [출력](library-database/results/02_bonus.txt#L46) · [보너스 리포트](library-database/bonus_report.md#핵심-지표-3개) |

## 설계를 설명할 때 찾을 곳

| 질문 | 읽을 곳 |
| --- | --- |
| 표를 나눈 이유, 1NF, PK·FK와 도서 대여 예시, 엑셀 대비 무결성 | [대여 한 건으로 보는 구조](library-database/learning_guide.md#대여-한-건이-네-테이블과-연결되는-방법) |
| 번호·이름·날짜 타입과 입력 규칙을 선택한 이유 | [스키마 헤더와 열 주석](library-database/01_schema.sql) |
| INNER JOIN과 LEFT JOIN의 차이 | [Q07 예시](library-database/learning_guide.md#q07-대여하지-않은-회원까지-표시하기) |
| Q09의 단계별 풀이와 NULL 처리 | [연결 → 묶기 → 세기 → 정렬](library-database/learning_guide.md#q09-회원별-대여-건수) |
| SUM·AVG 해석과 인덱스 이점·비용 | [Q10~Q15 해설](library-database/learning_guide.md#q10-도서별-누적-대여-일수) |
| 잘못된 입력이 거절된 원인과 다시 입력하는 방법 | [외래키 오류와 복구](library-database/bonus_report.md#외래키-오류와-복구) |

사용자가 제공한 미션 명세에 따라 Codex가 스키마, 가상 데이터, SQL, 관계도와 문서를 작성하고 SQLite에서 실행과 검증을 수행했습니다.
