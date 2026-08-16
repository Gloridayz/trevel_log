# trevel_log

가족이 함께 쓰는 여행 기록/준비 웹앱. 로그인 없이 PIN으로 입장하는 정적 사이트입니다. (`index.html` 단일 파일, 빌드 도구 없음)

## 탭

1. **기록** — 여행 일지 (관리자 PIN만 작성, 조회는 누구나)
2. **위시리스트·숙소** — 한 곳씩 입력 또는 여러 곳 한번에 붙여넣기, 구글맵/장소명으로 자동 채우기 지원
3. **경비** — 통화별 금액 → 원화 환산, 카테고리 소계/총합계
4. **준비물** — 담당자별 체크리스트

## 처음 설정할 때

### 1. Supabase 테이블 만들기

Supabase 프로젝트의 **SQL Editor**에서 `supabase/schema.sql` 내용을 그대로 실행하세요. (`entries` 테이블이 이미 있어도 안전하게 다시 실행 가능합니다.)

### 2. 위시리스트 "자동 채우기" 기능 — Google Places API 연결

이 기능은 `index.html`이 아니라 `/api/place.js`라는 Vercel 서버리스 함수를 통해 동작합니다 (API 키를 브라우저에 노출하지 않기 위함).

1. Google Cloud Console에서 **Places API (New)**를 활성화하고 API 키를 발급받으세요.
2. Vercel 프로젝트의 **Settings → Environment Variables**에 아래 값을 추가하세요.

   | 변수 | 값 |
   | --- | --- |
   | `GOOGLE_PLACES_API_KEY` | 발급받은 Places API 키 |

3. 환경변수를 추가한 뒤에는 Vercel에서 **Redeploy**를 한 번 해줘야 적용됩니다.
4. 위시리스트 탭 → "한 곳씩 입력" → 위치 검색어를 넣고 "✨ 자동 채우기"를 누르면 장소명/특징/사진이 채워집니다. 저장 전에 자유롭게 수정할 수 있습니다.

이 API 키는 `/api/place.js` 안에서만 서버 쪽에서 사용되고, `index.html`에는 절대 들어가지 않습니다.

## 배포 흐름

1. `index.html` (또는 `api/place.js`) 수정
2. 이 저장소에 커밋/푸시
3. Vercel이 자동으로 재배포 (별도 조작 불필요)
