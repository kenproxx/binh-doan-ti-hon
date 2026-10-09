# Báo cáo kiểm thử — bản thử nghiệm 0.1.0

## Quyết định nghiệm thu

Đã có toàn bộ vòng chơi và 30 ải. **Chưa đạt nghiệm thu Android hoàn chỉnh**: chưa cài/chơi trên thiết bị Android, chưa đo FPS, nhịp trận chưa ổn định 3–5 phút. Không gọi bản này là bản phát hành production.

Godot 4.4.1 stable, GDScript, Compatibility. Mã sản phẩm cuối đã được export lại vào APK; các test và tài liệu bổ sung sau đó không thay đổi mã trong APK.

## Kiểm thử tự động

Lần chạy cuối: Python dữ liệu **2/2**; Godot **audio, profile, battle, UI, acceptance** đều exit 0 và không có FAIL/ERROR trong log cuối. Acceptance thắng **30/30** từ hồ sơ mới, dùng tối đa bốn loại quân thực sự đã mở, tài nguyên/cooldown thật và nâng cấp mua bằng tiền kiếm được. Test chiến dịch không sửa HP hoặc tài nguyên. Các test đơn vị dùng fixture để cô lập timeout/lỗi lưu được ghi riêng trong code.

| Tiêu chí | Bằng chứng | Kết quả |
|---|---|---|
| 30 ải có dữ liệu, mục tiêu và đường qua cầu | Data, battle và 30 trận acceptance | Đạt với seed/chiến thuật đã thử |
| Hướng dẫn người mới ở ải 1–4 | Control và battlefield signal; deploy/command/skill/capture thật mới lưu hoàn thành | Đạt tự động |
| Chọn tối đa 4 loại mở khóa và một kỹ năng | UI kiểm tra khóa, giới hạn, prepare/start | Đạt |
| Triển khai, tìm đường, lệnh và kỹ năng | API thật, nước/đá/vùng cấm bị từ chối | Đạt |
| AI dùng cùng luật tài nguyên/cooldown/cap | AI đi qua cùng API deploy; hai phe đều thu nhập 8/s | Đạt |
| Thắng, thua, hết giờ, hòa, hai căn cứ cùng chết | Fixture battle và trận kết thúc thật | Đạt |
| Thắng mở ải/quân, thưởng đúng một lần | Settlement, reload, token kiểm tra sau mỗi trận | Đạt |
| Chơi lại, tạm dừng, tiếp tục, thoát | Real Control signals và notification lifecycle | Đạt logic |
| Nâng cấp trừ tiền và thay đổi stat trong trận | Profile, GameDB và Battle so sánh stat | Đạt |
| Lưu, phục hồi lỗi và phiên bản tương lai | Checksum/shape/version, backup/reload | Đạt ở mức file/API |
| Không nhân đôi thưởng đầu khi chơi lại | Token và giới hạn thưởng replay ba lần | Đạt |
| Lưu thất bại rồi thử lại không mất/nhân thưởng | Rollback, RetrySaveButton, nhận 188 vàng đúng một lần | Đạt |
| Nhạc/SFX/rung và chế độ 30 FPS | Toggle, music loop, Engine.max_fps | Đạt logic; chưa nghe/rung trên máy thật |
| Bốn thẻ quân không tràn viewport | Cạnh global rect so với viewport thật sau layout | Đạt |

Các lỗi đã sửa: cache sai kết quả khi lưu thất bại; cue kỹ năng thành cue triển khai; setting FPS chưa áp dụng ngay; mô tả hold nói một trạm trong khi luật cần hai; thẻ quân và Pause tràn màn hình; locale mặc định English; nhạc không loop; thông báo lỗi lưu cũ còn hiển thị sau giao dịch thành công. Có regression test tương ứng.

## Render và thao tác

Đã render mười màn hình thật ở 480×854 bằng Xvfb TCP và Mesa llvmpipe, kiểm tra ảnh rồi sửa bố cục. Chuẩn bị có nút Start/Back cố định ngoài vùng cuộn; Pause 48×48; bốn thẻ quân hiển thị ba dòng gọn. Các ảnh dùng fixture cho bố cục, không dùng chứng minh thắng trận; 30 acceptance riêng dùng giao chiến thật.

Control signal tests là kiểm thử tự động, không phải cảm ứng Android. Không suy ra FPS điện thoại từ renderer desktop. Smoke bằng chuột thật qua xdotool/X11 đã PASS: Tiếp tục ải1 → nút Vào trận cố định → chạm triển khai → nút kỹ năng/chạm mục tiêu → Pause. GDScript xác nhận đang ở battle, đúng một quân triển khai, skill có cooldown và paused=true. Đây là mouse input desktop, chưa phải touch Android.

## APK Android cuối

- File: `binh-doan-ti-hon-debug.apk`, **54,754,789 bytes**, debug signed.
- Package `com.binhdoantihon.game`; minSDK 21, targetSDK 34; portrait; ARM64 và x86_64.
- `apksigner` v1/v2/v3 và ZIP integrity đều pass.
- Không yêu cầu permission; bốn JSON dữ liệu đầy đủ; build/tools/tests/docs không nằm trong APK.
- So sánh CRC compiled main/profile với APK trước xác nhận các sửa cuối đã được đóng gói.

SHA256:
```text
17e69de88bbf68138c61bd585275242cf8e515306385f847c686a34feb794af2
```

**Chưa xác minh cài và mở APK trên Android.** Host không có KVM. Đã cài SDK và tạo AVD 34 riêng; software CPU emulator bị treo QEMU rồi segfault trước boot. Không có điện thoại USB trong môi trường. Điều này không chứng minh APK lỗi, cũng không được coi là cài đặt pass.

Có preset APK debug và AAB release, script build cùng hướng dẫn ký. Thử AAB bằng khóa tạm bên ngoài repo dừng ở Gradle 8.2: Java download báo `Network is unreachable`. Chưa tạo AAB và chưa gửi Google Play. API 34 được ghim theo Godot 4.4; trước gửi cửa hàng phải kiểm tra target API hiện hành và nâng toolchain phù hợp.

## Hạn chế còn lại

- Chiến thuật tự động nhanh thắng trong **32.7–186.8 giây**, trung vị **95.05 giây**; **29/30** dưới 180 giây. Chưa đáp ứng ổn định 3–5 phút. Bốn ải hướng dẫn ngắn; các ải chiếm điểm còn nhanh. Time limit 180/240/300 là giới hạn, không phải thời lượng thực đã đạt.
- Người chơi mô phỏng dùng bom tối ưu và mua nâng cấp hợp lý; chưa đại diện người mới. Không chứng minh mọi đội hình/seed đều cân bằng.
- Pixel art và âm thanh nguyên bản ở mức đơn giản; chưa đạt mức hoàn thiện thương mại. AI chưa được playtest rộng về chọn tuyến.
- Giới hạn tổng 96 quân, AStarGrid và timer cập nhật đường; target/neighbor vẫn O(n²) với cap. Chưa profiling nhiệt, memory hoặc FPS trên điện thoại. 60 FPS là mục tiêu; chế độ thấp cap 30.
- Một số lần test battle dài từng báo retained AudioStreamPlaybackWAV khi shutdown; lần chạy cuối sạch. Chưa kết luận về steady-state memory, cần soak test thiết bị.
- Back/background đã kiểm tra notification logic; safe area đã có code. Tai thỏ, tỉ lệ khác, multitouch và Android process kill chưa kiểm chứng.
- `strings.json` có vi/en và fallback, các khóa UI chính đã dùng; mô tả chi tiết còn tiếng Việt. Bản bàn giao mặc định Việt, chưa có gói English đầy đủ.

## Bước tiếp theo

1. Cài APK trên Android ARM64 thật, chạy checklist nghiệm thu; lưu model máy, OS, logcat và số liệu FPS.
2. Playtest rồi cân bằng AI, phòng thủ và nhiệm vụ chiếm điểm để đạt 3–5 phút, giữ quyết định về tuyến và đội hình.
3. Profiling target/path/effects, soak memory, kiểm tra cảm ứng, Back và tai thỏ.
4. Export AAB trên máy có mạng Gradle/Maven và khóa ký của chủ game; Google Play internal testing trước production.
