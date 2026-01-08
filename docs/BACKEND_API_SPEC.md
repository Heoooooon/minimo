# 우물(Oomool) 백엔드 API 명세서

> **현재 상태**: Mock 모드 (백엔드 미연동)
> **최종 업데이트**: 2025-01-08

---

## 개요

이 문서는 우물 앱의 백엔드 API 명세를 정리한 것입니다.
현재 앱은 Mock Repository를 사용하여 로컬 메모리에서 동작합니다.
실제 백엔드 개발 시 이 명세를 참고하세요.

### 기술 스택 (권장)
- **PocketBase** (현재 코드 기준) 또는 REST API
- 인증: JWT 또는 PocketBase 내장 인증

---

## 1. 어항 (Aquariums)

### Collection: `aquariums`

#### 1.1 스키마

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `id` | string | auto | PocketBase 자동 생성 ID |
| `name` | string | ✅ | 어항 이름 |
| `type` | string | ✅ | 어항 유형: `freshwater`, `saltwater` |
| `setting_date` | datetime | ✅ | 어항 세팅 일자 |
| `dimensions` | string | ✅ | 어항 치수 (예: "60x30x36") |
| `filter_type` | string | - | 여과기 종류: `hang_on`, `canister`, `sponge`, `internal`, `sump`, `none` |
| `substrate` | string | - | 바닥재 |
| `product_name` | string | - | 제품명 |
| `lighting` | string | - | 조명 종류: `led`, `fluorescent`, `metal_halide`, `none` |
| `heater` | boolean | - | 히터 유무 |
| `purpose` | string | - | 사육 목적: `general`, `breeding`, `aquascape`, `neglect`, `fry` |
| `notes` | string | - | 비고 (최대 300자) |
| `photo` | file | - | 대표 사진 |
| `created` | datetime | auto | 생성 시각 |
| `updated` | datetime | auto | 수정 시각 |

#### 1.2 API 엔드포인트

```
GET    /api/collections/aquariums/records      # 목록 조회
GET    /api/collections/aquariums/records/:id  # 단일 조회
POST   /api/collections/aquariums/records      # 생성
PATCH  /api/collections/aquariums/records/:id  # 수정
DELETE /api/collections/aquariums/records/:id  # 삭제
```

#### 1.3 요청/응답 예시

**생성 요청 (POST)**
```json
{
  "name": "호동이네",
  "type": "freshwater",
  "setting_date": "2024-01-15T00:00:00.000Z",
  "dimensions": "60x30x36",
  "filter_type": "hang_on",
  "substrate": "소일",
  "lighting": "led",
  "heater": true,
  "purpose": "general",
  "notes": "구피, 네온테트라 합사 중"
}
```

**응답**
```json
{
  "id": "abc123xyz",
  "name": "호동이네",
  "type": "freshwater",
  "setting_date": "2024-01-15T00:00:00.000Z",
  "dimensions": "60x30x36",
  "filter_type": "hang_on",
  "substrate": "소일",
  "lighting": "led",
  "heater": true,
  "purpose": "general",
  "notes": "구피, 네온테트라 합사 중",
  "photo": "",
  "created": "2025-01-08T10:00:00.000Z",
  "updated": "2025-01-08T10:00:00.000Z"
}
```

---

## 2. 기록 (Records)

### Collection: `records`

#### 2.1 스키마

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `id` | string | auto | PocketBase 자동 생성 ID |
| `aquarium` | relation | - | 연결된 어항 ID (aquariums) |
| `date` | datetime | ✅ | 기록 날짜 |
| `tags` | json (array) | ✅ | 태그 배열 |
| `content` | text | ✅ | 기록 내용 |
| `is_public` | boolean | ✅ | 공개 여부 (커뮤니티 노출) |
| `created` | datetime | auto | 생성 시각 |
| `updated` | datetime | auto | 수정 시각 |

#### 2.2 태그 종류

| 값 | 라벨 |
|----|------|
| `water_change` | 물갈이 |
| `cleaning` | 청소 |
| `feeding` | 먹이주기 |
| `water_test` | 수질검사 |
| `fish_added` | 물고기 추가 |
| `medication` | 치료/약품 |
| `maintenance` | 장비 관리 |

#### 2.3 API 엔드포인트

```
GET    /api/collections/records/records      # 목록 조회
POST   /api/collections/records/records      # 생성
DELETE /api/collections/records/records/:id  # 삭제
```

#### 2.4 요청/응답 예시

**생성 요청 (POST)**
```json
{
  "aquarium": "abc123xyz",
  "date": "2025-01-08T00:00:00.000Z",
  "tags": ["water_change", "cleaning"],
  "content": "주간 물갈이 30% 진행. 유리면 이끼 제거함.",
  "is_public": true
}
```

---

## 3. 질문 (Questions) - 커뮤니티

### Collection: `questions`

#### 3.1 스키마

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `id` | string | auto | PocketBase 자동 생성 ID |
| `title` | string | ✅ | 질문 제목 |
| `content` | text | ✅ | 질문 내용 |
| `category` | string | ✅ | 카테고리 |
| `attached_records` | relation[] | - | 첨부된 기록 ID 배열 (records) |
| `view_count` | number | - | 조회수 (기본값: 0) |
| `comment_count` | number | - | 댓글수 (기본값: 0) |
| `created` | datetime | auto | 생성 시각 |
| `updated` | datetime | auto | 수정 시각 |

#### 3.2 카테고리 (예시)

| 값 | 라벨 |
|----|------|
| `beginner` | 초보자 질문 |
| `maintenance` | 관리/유지 |
| `species` | 어종 관련 |
| `equipment` | 장비 |
| `disease` | 질병 |

#### 3.3 API 엔드포인트

```
GET    /api/collections/questions/records      # 목록 조회 (expand: attached_records)
POST   /api/collections/questions/records      # 생성
```

#### 3.4 요청/응답 예시

**목록 조회 (GET)**
```
GET /api/collections/questions/records?expand=attached_records&sort=-created
```

**생성 요청 (POST)**
```json
{
  "title": "구피 물갈이 주기 질문",
  "content": "60큐브에 구피 20마리 키우고 있는데 물갈이 주기를 어떻게 잡아야 할까요?",
  "category": "beginner",
  "attached_records": ["record_id_1", "record_id_2"]
}
```

---

## 4. 일정 (Schedules)

### Collection: `schedules`

#### 4.1 스키마

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `id` | string | auto | PocketBase 자동 생성 ID |
| `aquarium_id` | relation | - | 연결된 어항 ID |
| `aquarium_name` | string | ✅ | 어항 이름 (조회 편의용) |
| `date` | datetime | ✅ | 일정 날짜 |
| `time` | string | ✅ | 시간 (예: "08:00") |
| `title` | string | ✅ | 일정 제목 |
| `is_completed` | boolean | ✅ | 완료 여부 |
| `created` | datetime | auto | 생성 시각 |
| `updated` | datetime | auto | 수정 시각 |

#### 4.2 API 엔드포인트

```
GET   /api/collections/schedules/records           # 목록 조회
POST  /api/collections/schedules/records           # 생성
PATCH /api/collections/schedules/records/:id       # 완료 상태 토글
```

---

## 5. 추가 구현 필요 사항

### 5.1 인증 (미구현)
- [ ] 회원가입 (이메일/소셜 로그인)
- [ ] 로그인/로그아웃
- [ ] 토큰 갱신
- [ ] 비밀번호 재설정

### 5.2 사용자 (미구현)
- [ ] `users` 컬렉션
- [ ] 프로필 관리
- [ ] 사용자별 어항/기록 필터링

### 5.3 댓글 (미구현)
- [ ] `comments` 컬렉션
- [ ] 질문에 대한 댓글 CRUD

### 5.4 알림 (미구현)
- [ ] `notifications` 컬렉션
- [ ] 푸시 알림 연동

### 5.5 파일 업로드
- [ ] 이미지 리사이징
- [ ] 썸네일 생성
- [ ] 파일 용량 제한

---

## 6. Mock → 실제 백엔드 전환 방법

### 6.1 Repository 변경

각 ViewModel에서 Mock Repository를 실제 Repository로 교체:

```dart
// 현재 (Mock)
final AquariumRepository _repository = MockAquariumRepository.instance;

// 변경 후 (실제 백엔드)
final AquariumRepository _repository = PocketBaseAquariumRepository.instance;
```

### 6.2 main.dart에서 PocketBase 초기화 복원

```dart
// 현재 (Mock 모드)
// Mock 모드: PocketBase 초기화 생략

// 변경 후
await PocketBaseService.instance.initialize();
```

### 6.3 환경 변수로 모드 전환 (권장)

```dart
const bool useMockData = bool.fromEnvironment('USE_MOCK', defaultValue: true);

final AquariumRepository _repository = useMockData
    ? MockAquariumRepository.instance
    : PocketBaseAquariumRepository.instance;
```

---

## 7. PocketBase 설정 참고

### 7.1 로컬 실행
```bash
./pocketbase serve
# Admin UI: http://127.0.0.1:8090/_/
```

### 7.2 컬렉션 생성
PocketBase Admin UI에서 위 스키마에 맞게 컬렉션 생성

### 7.3 API Rules (권장)
- `aquariums`: 로그인 사용자만 CRUD
- `records`: 로그인 사용자만 CRUD, 본인 기록만 수정/삭제
- `questions`: 누구나 조회, 로그인 사용자만 생성

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2025-01-08 | 최초 작성, Mock 모드 전환 |
