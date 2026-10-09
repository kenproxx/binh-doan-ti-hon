# Kế hoạch triển khai Binh Đoàn Tí Hon

Goal: toàn bộ vòng lặp Android offline, tham khảo video.
Architecture: mô phỏng RefCounted độc lập UI, dữ liệu JSON và autoload hồ sơ/âm thanh.
Tech: Godot 4.4.1 GDScript, OpenJDK17. Spec: design.md.

1. Trận chơi được: map_grid.gd + battle_sim.gd; test trước triển khai (deploy sai vị trí/thiếu tiền/cooldown; đường qua cầu; thắng/thua/timeouts). Chạy Godot headless. API design.md là hợp đồng.
2. Luồng menu: main.gd + battlefield.gd + Profile; kiểm tra chọn ải/đội hình/UI/camera/pause/result; test reward token duplicate, save reload, upgrade.
3. Nội dung: units.json/stages.json/upgrades.json/strings.json; test 30 ải khác cấu hình, liên thông căn cứ, quân hợp lệ, tiêu chí sao và unlock.
4. Hình ảnh/âm thanh: vẽ pixel gốc có animation trạng thái, hiệu ứng + nhạc WAV tổng hợp; Credits; kiểm tra scene headless và ảnh chụp UI khi renderer có sẵn.
5. Android: export_presets.cfg, build script debug APK + release AAB hướng dẫn ký; kiểm tra export/signature/install/lifecycle khi có SDK/emulator. Báo cáo thiết bị thật tách riêng.

Review focus: bản lưu lỗi/future version; reward trùng và restart; UI drag đụng nút; đường tới trạm bị tắc; timeout hòa và căn cứ chết cùng tick.
Phần nào chưa chạy/đo sẽ ghi chưa xác minh; không dùng kết quả mô phỏng để tuyên bố 60 FPS Android.
