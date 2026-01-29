# Minimo (우물) 세션 기록

## 최종 업데이트: 2025-01-24

---

## 완료된 작업

### 1. 커뮤니티 기능 고도화 ✅
- 태그 필터링 UI 연결
- PostData에 tags 필드 추가
- 서비스/ViewModel 테스트 작성 (57개 테스트)
- Info 레벨 lint 정리 (41개 → 16개)
- 검색 화면 (`/search`)
- 알림 화면 (`/notifications`)
- 궁금해요 기능 (`CuriousService`)
- 더보기 화면 (`/more-list`)

### 2. 패키지명 변경 ✅
- `com.oomool.oomool` → `com.cmore.oomool`
- Android: `build.gradle.kts`, Kotlin 디렉토리
- iOS: `project.pbxproj`

### 3. Firebase FCM + PocketBase 알림 시스템 ✅

#### Flutter 클라이언트
| 파일 | 설명 |
|------|------|
| `lib/data/services/fcm_service.dart` | FCM 토큰 관리, 푸시 수신 처리 |
| `lib/data/services/pb_notification_service.dart` | PocketBase 알림 CRUD |
| `lib/domain/models/notification_data.dart` | 알림 데이터 모델 |
| `lib/presentation/screens/community/notification_screen.dart` | PocketBase 연동 알림 화면 |
| `lib/main.dart` | FcmService 초기화 추가 |
| `pubspec.yaml` | firebase_core, firebase_messaging 추가 |

#### Android 설정
| 파일 | 변경 |
|------|------|
| `android/settings.gradle.kts` | Google Services 플러그인 추가 |
| `android/app/build.gradle.kts` | Google Services 플러그인 적용 |
| `android/app/google-services.json` | Firebase 설정 (사용자 추가) |
| `android/app/src/main/kotlin/com/cmore/oomool/MainActivity.kt` | 패키지 경로 변경 |

#### iOS 설정
| 파일 | 변경 |
|------|------|
| `ios/Runner/AppDelegate.swift` | Firebase 초기화, APNs 등록, MessagingDelegate |
| `ios/Runner/GoogleService-Info.plist` | Firebase 설정 (사용자 추가) |

#### PocketBase 백엔드
| 파일 | 설명 |
|------|------|
| `backend/pb_migrations/1767700041_add_fcm_token_to_users.js` | users에 fcm_token 필드 추가 |
| `backend/pb_migrations/1767700042_created_notifications.js` | notifications 컬렉션 생성 |
| `backend/pb_hooks/notifications.pb.js` | 알림 자동 생성 + FCM 푸시 전송 |

---

## 배포 상태

- **Flutter 앱**: 빌드 성공 (`flutter build apk --debug`)
- **PocketBase**: Fly.io 배포 완료 (`minimo-pocketbase.fly.dev`, started 상태)

---

## 다음 세션을 위한 TODO

### 필수
1. **FCM 서버 키 설정**
   ```bash
   fly secrets set FCM_SERVER_KEY="YOUR_FCM_SERVER_KEY" -a minimo-pocketbase
   ```
   - Firebase Console → 프로젝트 설정 → Cloud Messaging → 서버 키

### 선택
- iOS 실제 기기 테스트 (APNs 인증서 필요)
- 알림 클릭 시 해당 화면으로 딥링크 구현 강화
- 알림 배지 카운트 표시

---

## 빌드/테스트 명령어

```bash
cd /Users/gwon-yeheon/CMORE/minimo

# 분석
flutter analyze lib/

# 테스트
flutter test

# 빌드
flutter build apk --debug
flutter build ios --debug

# 백엔드 배포
cd backend && fly deploy
```

---

## 프로젝트 컨벤션

- **서비스**: 싱글톤 패턴 (`Service._()`, `static Service get instance`)
- **로그**: `AppLogger.data('Message')` 또는 `AppLogger.data('Error', isError: true)`
- **ViewModel**: `BaseViewModel` 또는 `CachingViewModel` 상속
- **마이그레이션**: `/// <reference path="../pb_data/types.d.ts" />` 헤더 필수

---

## notifications 컬렉션 스키마

| 필드 | 타입 | 설명 |
|------|------|------|
| user | relation (users) | 알림 수신자 |
| type | select | like, comment, follow, answer, mention, system |
| title | text | 알림 제목 |
| message | text | 알림 내용 |
| target_id | text | 대상 레코드 ID |
| target_type | select | post, question, user, comment, answer |
| is_read | bool | 읽음 여부 |
| actor | relation (users) | 알림 발생시킨 사용자 |

---

## 주요 라우트

| 경로 | 화면 |
|------|------|
| `/search` | SearchScreen |
| `/notifications` | NotificationScreen |
| `/more-list` | MoreListScreen |
| `/post-detail` | PostDetailScreen |
| `/question-detail` | QuestionDetailScreen |
