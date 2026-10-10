# Android: build, cài đặt và ký phát hành

Dự án dùng **Godot 4.4.1 stable**, **OpenJDK 17**, Android SDK **Platform 34 / Build Tools 34.0.0**, và template export đúng phiên bản. Hai preset đã có trong `export_presets.cfg`:

| Preset | Định dạng | Kiến trúc | Mục đích |
| --- | --- | --- | --- |
| Android Debug | APK, template có sẵn | arm64-v8a + x86_64 | Cài thử trên điện thoại ARM64 hoặc emulator x86_64 |
| Android Release AAB | AAB, Gradle | arm64-v8a + x86_64 | Bản phát hành ký bằng khóa của chủ ứng dụng |

Package: `com.binhdoantihon.game`; versionName `0.1.0`, versionCode `1`. Màn hình portrait (480 × 854, scale theo canvas). Preset không yêu cầu Internet hoặc access_network_state; nội dung và lưu tiến trình hoạt động ngoại tuyến.

## 1. Chuẩn bị

Cài Godot 4.4.1, JDK 17, `curl`, `unzip`, `python3`. Script sau tải bộ công cụ Android Linux x86_64 và các template Android chính thức. Xem giấy phép Android SDK trước khi chạy: script chấp nhận giấy phép để cài SDK.

```bash
export GODOT_BIN=/path/to/Godot_v4.4.1-stable_linux.x86_64
export JAVA_HOME=/path/to/jdk-17
export ANDROID_HOME="$HOME/Android/Sdk"
./tools/install_android_tools.sh
```

Nếu đã có SDK, chỉ cần đặt `ANDROID_HOME` tới thư mục đó. Template mặc định ở `$HOME/.local/share/godot/export_templates/4.4.1.stable` (hoặc dưới `XDG_DATA_HOME` nếu đã đặt biến này). APK dùng template có sẵn, không cần Gradle. AAB dùng Gradle wrapper trong template; lần đầu cần mạng để tải Gradle và các thư viện Maven. NDK/CMake chỉ cần khi biên dịch plugin native; không cần để đóng gói template có sẵn.

## 2. Build APK debug

```bash
./tools/build_android.sh debug
```

Kết quả: `build/binh-doan-ti-hon-debug.apk`. Script chạy import, export, kiểm tra chữ ký bằng `apksigner`, in manifest bằng `aapt`. Đây là chữ ký debug, không dùng đưa lên cửa hàng. Script tạo editor settings riêng trong `build/`, để cấu hình SDK/JDK không ảnh hưởng editor cá nhân.

Cài trên thiết bị đã bật USB debugging:

```bash
"$ANDROID_HOME/platform-tools/adb" devices
"$ANDROID_HOME/platform-tools/adb" install -r build/binh-doan-ti-hon-debug.apk
"$ANDROID_HOME/platform-tools/adb" shell am start -n com.binhdoantihon.game/com.godot.game.GodotApp
```

Nếu bản cài cũ ký bằng khóa khác, Android từ chối cập nhật. Gỡ bản cũ sẽ xóa tiến trình lưu trên thiết bị; sao lưu trước nếu cần. Kiểm tra debug APK:

```bash
"$ANDROID_HOME/build-tools/34.0.0/apksigner" verify --verbose build/binh-doan-ti-hon-debug.apk
"$ANDROID_HOME/build-tools/34.0.0/aapt" dump badging build/binh-doan-ti-hon-debug.apk
"$ANDROID_HOME/build-tools/34.0.0/aapt" dump permissions build/binh-doan-ti-hon-debug.apk
```

## 3. Build AAB phát hành

Khóa ký là tài sản của chủ ứng dụng. Tạo ngoài repository, giữ bản sao an toàn; không commit khóa hoặc mật khẩu:

```bash
keytool -genkeypair -keystore "$HOME/binh-upload.keystore" \
  -alias binh-upload -keyalg RSA -keysize 2048 -validity 10000
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$HOME/binh-upload.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=binh-upload
read -rsp 'Mật khẩu khóa: ' GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
printf '\n'
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
./tools/build_android.sh release
unset GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
```

Mật khẩu keystore và key phải giống nhau với Godot 4.4.1. Script dừng ngay nếu chưa có biến ký phát hành; mật khẩu không được ghi vào preset. Kết quả: `build/binh-doan-ti-hon-release.aab`. Kiểm tra chữ ký AAB bằng `jarsigner -verify`; AAB không thể cài trực tiếp bằng `adb install`. Dùng Google Play internal testing hoặc `bundletool` để tạo APK từ AAB.

Preset API34 được ghim theo toolchain Godot 4.4. Trước khi gửi Google Play, kiểm tra yêu cầu target API hiện hành, nâng Godot/template/SDK phù hợp và tăng `version/code`. Cấu hình này không tuyên bố đã đáp ứng mọi yêu cầu cửa hàng ở thời điểm gửi.

## 4. Emulator tùy chọn

```bash
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
  'emulator' 'system-images;android-34;google_apis;x86_64'
printf 'no\n' | "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" create avd \
  -n binh-api34 -k 'system-images;android-34;google_apis;x86_64' --device pixel_2
"$ANDROID_HOME/emulator/emulator" -avd binh-api34
```

Nếu host không có `/dev/kvm`, có thể thử `-accel off -gpu swiftshader_indirect -no-window -no-audio`, nhưng chậm đáng kể. Kiểm thử emulator không thay thế kiểm thử touch, âm thanh, hiệu năng và vòng đời trên điện thoại thật.

## Nguồn chính thức

- [Godot 4.4: Exporting for Android](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_android.html)
- [Godot 4.4: Gradle builds](https://docs.godotengine.org/en/4.4/tutorials/export/android_gradle_build.html)
- [Android: App signing](https://developer.android.com/studio/publish/app-signing)

## Kết quả xác minh trong môi trường xây dựng

- Đã export APK debug bằng template Godot 4.4.1 và xác minh chữ ký APK v1/v2/v3 bằng `apksigner`.
- Đã kiểm tra manifest bằng `aapt`: package đúng, portrait, có ARM64 và x86_64, không yêu cầu quyền Internet.
- Đã thử export AAB với khóa kiểm thử tạm thời ngoài repository. Gradle wrapper không tải được Gradle 8.2 do Java báo `Network is unreachable`; **chưa tạo AAB phát hành**. Script/preset ký phát hành sẵn sàng để chạy ở máy có mạng Gradle/Maven và khóa của chủ ứng dụng.
- Đã cài Android Emulator/API34 x86_64 và thử khởi động CPU/software (host không có KVM). Lần thử trên AVD riêng `binh_final` đã tránh khóa nhưng QEMU CPU/main-loop bị treo rồi emulator segfault trước khi Android boot; lần thử local này không boot để cài/chạy APK; CI có KVM đã kiểm tra riêng ở phần dưới. **Chưa kiểm thử trên điện thoại thật.**

## CI và bản0.2.0

Workflow `.github/workflows/android.yml` chạy bộ7suite, export debugAPK, dùng giả lậpx86_64/API34 có KVM và lưu artifact APK/log/screenshot14ngày. Script `tools/android_smoke.py` giới hạn thiết bị `emulator-*`, dùng viewport480×854, chạm toggle nhạc và đọc profile checksum để xác minh UI/lưu/lifecycle. Smoke menu/cài đặt/lifecycle và thao tác triển khai đầu tiên trong battle; chưa kiểm thử chiến thắng và battle Android toàn trình.

Bản0.2.0 versionCode2. Thử AAB mới với khóa validation tạm vẫn dừng ở downloadGradle8.2 `Network is unreachable`, kể cả cấu hình proxyJava. Không có AAB mới và không thể coi CI chưa chạy là pass.

## Chữ ký debug và chuyển từ0.1.0

Đã đối chiếu chứng thư APK được bàn giao:0.1.0 có SHA256 chứng thư `89fb0e577fa621010b16cda755c23205a816fbea1bdac7ba70ae148f38c3dc71`;0.2.0 có `7b039bf506b96f5a41cda263e10a39c7f86e9355330de4a17d881c5dce7d47e2`. Khóa debug cũ không còn trong môi trường. **Không cài đè0.2.0 lên0.1.0. Không gỡ bản cũ trước khi sao lưu tiến độ.** Nếu chưa cài0.1.0 thì cài mới bình thường.

Với bản debug và thiết bị có ADB, sao lưu hồ sơ trước khi đổi APK:
```bash
adb exec-out run-as com.binhdoantihon.game cat files/profile.json > profile-before-upgrade.json
```
Kiểm tra file JSON có `payload` và `checksum`, giữ file an toàn. Sau khi đã sao lưu, người dùng có thể gỡ bản cũ rồi cài0.2.0. Mở một lần, đóng ứng dụng và khôi phục:
```bash
adb push profile-before-upgrade.json /data/local/tmp/bdth-profile.json
adb shell am force-stop com.binhdoantihon.game
adb shell run-as com.binhdoantihon.game cp /data/local/tmp/bdth-profile.json files/profile.json
adb shell run-as com.binhdoantihon.game cp files/profile.json files/profile.backup.json
```
Đây là hướng dẫn chuyển dữ liệu debug; chưa chạy trên điện thoại thật. Không có thao tác tự động gỡ ứng dụng.

Khóa debug0.2.0 đã giữ lại riêng với tên `binh-doan-ti-hon-beta-debug.keystore` để các bản beta tiếp theo dùng cùng chứng thư; không đưa private key vào GitHub. Khi build bản beta cập nhật, đặt đủ ba biến Godot:
```bash
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH=/absolute/path/binh-doan-ti-hon-beta-debug.keystore
export GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android
bash tools/build_android.sh debug
```
Khóa này chỉ dành cho thử nghiệm, không dùng phát hành. APK từ CI tự tạo khóa debug riêng nên không coi artifactCI là bản cập nhật cài đè APK được bàn giao. Bản phát hành phải dùng khóa của chủ game đã lưu ổn định.

Kết quả thực tế: [CI38016747465](https://github.com/kenproxx/binh-doan-ti-hon/actions/runs/38016747465) SUCCESS: cài/mở APK, chạm thay music đã lưu, Home/quay lại, Back, vào battle/triển khai quân, ghi tutorial deploy, force-stop/relaunch giữ hồ sơ. Dùng SwANGLE (legacy SwiftShader gây lỗi shader trong lần trước). Chưa chơi trận thắng, hướng dẫn1–4 hoặc30ải toàn trình trên Android; chưa kiểm thử điện thoại thật/FPS. Xem docs/testing.md để đọc phạm vi và lịch sử lỗi fixture.

Ảnh battle xác nhận một quân và cooldown Mưa bom30s→29s. Chưa xác nhận overlayPause/resume trong battle: screenshotBack chụp ngay không hiện overlay và test chỉ kiểm tra process. Cần nghiệm thu riêng, không suy ra pause/resume từ kết quả smoke.
