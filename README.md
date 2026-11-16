# 구구단 없는 곱셈 연습 (Flutter)

자기 숫자와 오른쪽 이웃만 보고 답을 한 자리씩 적는 기본 곱셈 연습 앱입니다.
곱하는 수 11, 12, 6, 7, 5, 9, 8, 4, 3, 2를 지원합니다.

## 파일

| 파일 | 내용 |
| --- | --- |
| `lib/trachtenberg.dart` | 계산 로직과 규칙 문구 (화면과 무관한 순수 Dart) |
| `lib/main.dart` | 화면: 규칙 카드, 풀이 보기, 연습하기 |
| `test/trachtenberg_test.dart` | 로직을 실제 곱셈 결과와 대조하는 테스트 |
| `test/widget_test.dart` | 앱이 열리는지 확인하는 테스트 |

## 준비 (한 번만)

이 폴더에는 `android/`, `ios/` 폴더가 없습니다. 폴더 안에서 아래 명령으로 만듭니다.
`lib/`, `test/`, `pubspec.yaml`은 그대로 유지됩니다.

```
flutter create --platforms=android,ios --org com.example --project-name neighbor_multiply .
flutter pub get
flutter test
```

`com.example`은 본인 조직 이름으로 바꾸세요.

## 안드로이드 폰에 설치

1. 폰에서 개발자 옵션과 USB 디버깅을 켜고 PC에 연결합니다.
2. `flutter devices`로 폰이 보이는지 확인합니다.
3. `flutter run --release`로 바로 설치해 실행합니다.

APK 파일로 옮겨 설치하려면:

```
flutter build apk --release
```

결과물은 `build/app/outputs/flutter-apk/app-release.apk`에 생깁니다.

## 앱 이름 바꾸기

- 안드로이드: `android/app/src/main/AndroidManifest.xml`의 `android:label`
- iOS: `ios/Runner/Info.plist`의 `CFBundleDisplayName`

## iOS

Mac과 Xcode가 필요합니다. `open ios/Runner.xcworkspace`로 열어 서명 팀을 지정한 뒤
`flutter run --release`로 설치합니다.
