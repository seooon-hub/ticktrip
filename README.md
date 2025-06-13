# 🎯 TICKTRIP - 여행 관리 플랫폼

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-3.5.4-blue?style=for-the-badge&logo=flutter" alt="Flutter Version">
  <img src="https://img.shields.io/badge/Dart-3.5.4-blue?style=for-the-badge&logo=dart" alt="Dart Version">
  <img src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Storage-orange?style=for-the-badge&logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-green?style=for-the-badge" alt="Platform">
</div>

## 📱 프로젝트 소개

**TICKTRIP**은 여행자들을 위한 종합적인 여행 관리 모바일 애플리케이션입니다. Flutter로 개발된 크로스 플랫폼 앱으로, 여행 계획부터 지출 관리, 리뷰 작성까지 여행의 전 과정을 효율적으로 관리할 수 있습니다.

### ✨ 주요 특징
- 🗓️ **직관적인 일정 관리** - 시각적 캘린더로 여행 일정을 한눈에
- 💰 **실시간 환율 연동** - 한국수출입은행 API를 통한 정확한 환율 정보
- ✅ **체크리스트 시스템** - 여행 전 준비물을 체계적으로 관리
- 📝 **리뷰 공유 플랫폼** - 여행 후기를 작성하고 공유
- 🆘 **비상연락처 서비스** - 국가별 비상연락처 정보 제공
- 🔒 **오프라인 지원** - 네트워크 없이도 기본 기능 사용 가능

## 🚀 주요 기능

### 🔐 사용자 인증
- Firebase Authentication 기반 로그인/회원가입
- Google OAuth 소셜 로그인 지원
- 오프라인 로그인 기능 (로컬 암호화 저장)
- 비밀번호 찾기 기능

### 📅 여행 일정 관리
- Table Calendar를 활용한 시각적 일정 관리
- 일정 추가/수정/삭제 기능
- 색상별 일정 분류 및 상세 메모
- 날짜별 일정 조회 및 관리

### 💸 지출 관리
- 실시간 환율 API 연동 (한국수출입은행)
- 다국가 통화 지원 (USD, JPY, EUR 등)
- KRW ↔ 외화 자동 환산
- 날짜별 지출 내역 관리 및 통계

### ✅ 체크리스트 관리
- 여행 전 준비물 체크리스트
- 날짜별 체크리스트 생성 및 관리
- 체크박스 기반 진행 상황 추적
- 로컬 저장으로 오프라인 사용 가능

### 📝 리뷰 시스템
- 여행 후기 작성 및 공유
- 제목, 내용, 이미지 첨부 기능
- 닉네임/제목 기반 검색 기능
- Firebase Firestore 기반 실시간 데이터 동기화

### 🆘 비상연락처 서비스
- 국가별 비상연락처 정보 제공
- 공공데이터포털 API 연동
- 국가 국기 이미지 표시
- 오프라인 환경 대비 캡처 안내

## 🛠 기술 스택

### Frontend
- **Flutter 3.5.4** - 크로스 플랫폼 모바일 개발
- **Dart** - 프로그래밍 언어
- **Material Design** - UI/UX 디자인 시스템

### Backend & Database
- **Firebase Authentication** - 사용자 인증
- **Cloud Firestore** - NoSQL 데이터베이스
- **Firebase Storage** - 파일 저장소
- **Firebase App Check** - 앱 보안

### 외부 API 연동
- **한국수출입은행 환율 API** - 실시간 환율 정보
- **공공데이터포털 비상연락처 API** - 국가별 연락처 정보

### 로컬 저장소 & 보안
- **SharedPreferences** - 간단한 데이터 저장
- **LocalStorage** - AES 암호화된 파일 저장 시스템
- **Path Provider** - 파일 시스템 접근

## 📁 프로젝트 구조

```
ticktrip/
├── lib/
│   ├── screens/           # 화면 UI 컴포넌트
│   │   ├── login.dart     # 로그인 화면
│   │   ├── signup.dart    # 회원가입 화면
│   │   ├── main_page.dart # 메인 대시보드
│   │   ├── calendar.dart  # 캘린더 화면
│   │   ├── expense.dart   # 지출 관리
│   │   ├── checklist.dart # 체크리스트
│   │   ├── review.dart    # 리뷰 목록
│   │   └── ...
│   ├── services/          # 비즈니스 로직
│   │   └── local_storage.dart # 로컬 저장소 관리
│   ├── models/            # 데이터 모델
│   │   └── post.dart      # 게시물 모델
│   ├── providers/         # 상태 관리
│   │   └── auth_provider.dart
│   └── main.dart          # 앱 진입점
├── assets/                # 리소스 파일
│   └── images/           # 이미지 에셋
├── android/              # Android 플랫폼 설정
├── ios/                  # iOS 플랫폼 설정
└── pubspec.yaml          # 의존성 관리
```

## 🚀 설치 및 실행

### 1. Flutter 환경 설정
```bash
flutter doctor
```

### 2. 프로젝트 클론
```bash
git clone https://github.com/your-username/ticktrip.git
cd ticktrip
```

### 3. 의존성 설치
```bash
flutter pub get
```

### 4. Firebase 설정
1. [Firebase Console](https://console.firebase.google.com/)에서 새 프로젝트 생성
2. Android/iOS 앱 등록
3. `google-services.json` (Android) 및 `GoogleService-Info.plist` (iOS) 다운로드
4. 각각 `android/app/` 및 `ios/Runner/` 폴더에 배치

### 5. ⚠️ API 키 설정 (중요!)
프로젝트를 실행하기 전에 다음 API 키들을 **반드시** 본인의 키로 변경해야 합니다:

#### 환율 API 키 설정
**파일**: `lib/screens/expense.dart`
```dart
// 현재 하드코딩된 키를 본인의 키로 변경
String authKey = 'wGOD6vK3y6CUrPf9AHz5ZbwWAJ2yHuC5'; // ⚠️ 이 키를 변경하세요!
```

**발급 방법**:
1. [한국수출입은행 API](https://www.koreaexim.go.kr/site/main/index001) 접속
2. 회원가입 후 API 키 발급
3. 위 코드의 `authKey` 값을 본인의 키로 교체

#### 비상연락처 API 키 설정
**파일**: `lib/screens/emergencycontactspage.dart`
```dart
// 현재 하드코딩된 키를 본인의 키로 변경
final String apiKey = "iIMYvrawp6wVusc2zNGvUumDfoEldY6BWgft9eGYVvM7okEeabkqDpCvlUHYxnjBuUlUFVQAfYYccvmZjnXsjQ=="; // ⚠️ 이 키를 변경하세요!
```

**발급 방법**:
1. [공공데이터포털](https://www.data.go.kr/) 접속
2. "해외여행자 안전정보" API 검색
3. API 키 발급 신청
4. 위 코드의 `apiKey` 값을 본인의 키로 교체

### 6. 앱 실행
```bash
flutter run
```

## 📱 지원 플랫폼

- **Android** (API 21 이상)
- **iOS** (iOS 11.0 이상)
- **Web** (Flutter Web 지원)

## 🔧 주요 특징

### 오프라인 지원
- 로컬 암호화 저장소로 오프라인 환경에서도 기본 기능 사용 가능
- 네트워크 연결 상태에 따른 적응적 기능 제공

### 다국가 지원
- 한국어/영어 다국어 지원
- 다양한 통화 및 환율 정보 제공
- 국가별 비상연락처 서비스

### 보안 강화
- AES 암호화를 통한 로컬 데이터 보호
- Firebase App Check를 통한 앱 무결성 검증
- SSL 인증서 검증 우회 설정

### 사용자 경험
- 직관적인 Material Design UI
- 실시간 데이터 동기화
- 검색 및 필터링 기능
- 반응형 레이아웃


## 📄 라이선스

이 프로젝트는 개인 학습 및 포트폴리오 목적으로 개발되었습니다.

---
