# Binh Đoàn Tí Hon

RTS 2D pixel offline cho Android dọc, phát triển bằng **Godot 4.4.1 stable + GDScript**, renderer Compatibility. Có luồng khởi động → menu → chiến dịch → chuẩn bị → trận → kết quả → thưởng/nâng cấp → ải tiếp theo và lưu hồ sơ.

**Trạng thái:** bản thử nghiệm có toàn bộ luồng và 30 ải; chưa đạt nghiệm thu Android thiết bị thật, chưa được công nhận bản phát hành hoàn chỉnh. Chi tiết kết quả cuối cùng ở [báo cáo kiểm thử](docs/testing.md).

## Chơi và chạy
1. Cài Godot4.4.1 standard (không cần.NET).
2. Import project.godot, chờ import audio/SVG, nhấn F5.
3. Chọn Chiến dịch → Ải1 → Chuẩn bị → Vào trận. Chọn thẻ quân rồi chạm vùng tròn sáng gần căn cứ. Kéo bản đồ để quan sát, minimap đổi góc nhìn. Quân tự đi/đánh; lệnh Tiến công/Phòng thủ/Tập kết điều khiển toàn quân. Kỹ năng chọn vùng mục tiêu.
4. Thắng mở ải và quân mới. Dùng tiền ngoài trận nâng cấp0–5; stat nâng cấp được chụp vào trận khi bắt đầu.

APK debug được bàn giao trong cuộc trò chuyện, không commit APK/keystore vào repo. [Build APK, AAB và ký](docs/android.md). Bản APK offline không xin quyền Internet.

## Nội dung
- Ba chương, 30 ải khác cầu/chướng ngại/đội hình địch/mục tiêu; đồng cỏ, hẻm đá, quần đảo.
- Sáu vai trò: kiếm, vệ binh, cung, hỏa pháo, quân y, phá thành. Đội hình tối đa4 loại đã mở + kỹ năng mưa bom/hồi phục.
- Hai căn cứ, tài nguyên/cooldown/giới hạn48 quân mỗi phe, hai trạm có thưởng thu nhập và vùng triển khai.
- Mục tiêu phá căn cứ/chiếm hai trạm/giữ hai trạm/sống sót. Có giới hạn thời gian; phá căn cứ địch cũng thắng các nhiệm vụ phụ.
- Ba sao, thưởng lần đầu riêng, sao mới riêng, replay15 vàng tối đa3 lần/ải. Token kết quả chống trao trùng, lỗi ghi cho phép thử lưu lại.
- Save checksum/version, temp rename và bản dự phòng; cài đặt nhạc/SFX/rung/30–60FPS mục tiêu. Chưa đo60FPS trên điện thoại.

## Chỉnh sửa
| File/hệ thống | Vai trò |
|---|---|
| data/units.json | Stat, giá, cooldown, cap, vai trò và counters |
| data/stages.json | 30 ải/map seed, cầu/chướng ngại, AI, nhiệm vụ, thời gian, sao, thưởng |
| data/upgrades.json | Năm giá nâng cấp từng loại |
| data/strings.json | Tiếng Việt/English và fallback, UI đã dùng các khóa chính; mô tả chi tiết còn Việt |
| scripts/game_db.gd | Đọc dữ liệu, snapshot stat nâng cấp |
| scripts/profile.gd | Hồ sơ, backup, unlock, upgrade và settlement nguyên tử |
| scripts/map_grid.gd | Đất/nước/chướng ngại và AStarGrid2D |
| scripts/battle_sim.gd | Tài nguyên, deploy, AI, auto combat, capture, skills và kết quả |
| scripts/main.gd | Điều hướng, UI, lifecycle, tutorial và reward |
| scripts/battlefield.gd, minimap.gd | Vẽ pixel, camera cảm ứng, minimap |
| scripts/audio.gd | Âm thanh gốc và giới hạnFPS theo setting |

Tái tạo dữ liệu: python tools/generate_data.py (ghi đè toàn bộ JSON). Tái tạo âm thanh: python tools/generate_audio.py (Godot import lại). Lưu trong user://profile.json. Có kiểm tra shape/checksum và phiên bản1. Không cần backend/tài khoản/quảng cáo/IAP.

## Kiểm thử
```bash
python -m unittest discover -s tests -p 'test_*.py'
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/test_audio.gd
godot --headless --path . --script tests/test_profile.gd
godot --headless --path . --script tests/test_battle.gd
godot --headless --path . --script tests/test_ui.gd
godot --headless --path . --script tests/test_acceptance.gd
```
Tests dùng thư mục hồ sơ kiểm thử riêng hoặc khôi phục snapshot, không chạy acceptance với save người dùng. Acceptance xác minh cácAPI thật và Control signals; không thay thế đo cảm ứng Android.

## Tài liệu
- [Phân tích video và mốc cảnh](docs/video-analysis.md)
- [Luật và kiến trúc](docs/design.md)
- [Các mốc triển khai](docs/plan.md)
- [Kiểm thử/hạn chế](docs/testing.md), [đánh giá độc lập](docs/review.md)
- [Nguồn tài sản](CREDITS.md), [MIT](LICENSE)


## Bản beta 0.2.0

Đã sửa thắng sai mục tiêu, cân bằng giáp căn cứ đối xứng và kiểm thử hai đội hình chiến dịch (có/không ưu tiên Phá thành). Các ải5–30 trong hai lượt đo đều khoảng3–5phút; bốn ải hướng dẫn ngắn. Chưa đo FPS trên điện thoại thật.

Chạy toàn bộ: `GODOT_BIN=/path/to/godot python3 tools/run_tests.py`. Thử đội hình Phá thành: `godot --headless --path . --script tests/test_acceptance.gd -- --siege`.

GitHub Actions `.github/workflows/android.yml` chạy kiểm thử, build APK và smoke cảm ứng/cài đặt/lifecycle trên giả lậpAPI34; xem kết quả cụ thể trong tab Actions trước khi coi Android pass. `tools/android_smoke.py` chỉ dành cho giả lập CI dùng một lần, không phải checklist nghiệm thu gameplay hoặc máy thật.

**Nếu đã cài0.1.0:** APK0.2.0 dùng chứng thư debug khác. Không gỡ bản cũ trước khi sao lưu tiến độ; xem mục chuyển dữ liệu trong [Android](docs/android.md). Các bản beta tiếp theo cần dùng lại khóa0.2.0 đã giữ riêng.

Android smoke thực tế: [CI38016747465](https://github.com/kenproxx/binh-doan-ti-hon/actions/runs/38016747465) PASS cài/mở, chạm đổi setting/lưu, menuHome/Back, vào battle/triển khai/kỹ năng và force-stop/relaunch giữ hồ sơ. Chưa nghiệm thu thắng trận, hướng dẫn1–4/campaign toàn trình, battlepause/resume hoặc FPS trên điện thoại thật.
