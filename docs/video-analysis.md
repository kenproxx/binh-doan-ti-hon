# Phân tích video tham khảo

Nguồn: video game(1).mp4 do người dùng cung cấp. 720×1280 dọc, 30 FPS, 360 frame, video 12.000s/audio 12.005s. Giải mã toàn bộ video; rà chuỗi ảnh 10 frame/s trong toàn bộ 0–12s, đối chiếu contact sheet 2 frame/s. Không xác định tên hoặc nguồn game từ hình ảnh. Không lấy sprites/âm thanh/bản đồ vào sản phẩm.

## Các cảnh và bằng chứng

| Thời gian | Quan sát trực tiếp | Suy luận có giới hạn |
|---|---|---|
| 00:00–00:03 | Góc nhìn gần top-down, nền cỏ/hoa hồng, sông dọc nối nhánh ngang, đất chia mảng, nhiều cầu gỗ/cầu cong. Quân đỏ/xanh tụ quanh cầu và nhà mái đỏ/xanh. HUD trên: biểu tượng tiền với 6000, nhãn TIME/đồng hồ, biểu tượng giống bao tài nguyên với số xanh thay đổi và thanh đỏ/xanh. Dưới có ba thẻ hình quân, biểu tượng búa, minimap góc phải. Có vệt sáng, quả cầu lửa, nổ khi hai phe giao tranh. | Nhà lớn có thể là căn cứ. Biểu tượng bao có thể là tài nguyên tuyển quân; số tăng/giảm chưa đủ chứng minh quy luật thu nhập/chi phí. Đường cầu dẫn quân giữa các vùng, chưa chứng minh collision hay thuật toán tìm đường. |
| 00:03–00:06 | Chuyển cảnh cắt thẳng: phối cảnh xiên/pseudo-isometric, sông chéo, cầu cong và cổng đỏ ở trung tâm, nhà kiểu thành nhiều tầng, hàng rào, quân đỏ phía trên/trái và xanh bên dưới/phải. Nổ và khói tập trung tại cầu. HUD khác: nhiều số trên cùng, thanh đỏ/xanh với hình quân ở hai đầu, hiển thị 00:58. Hàng thẻ có cả hình quân và búa, minimap vẫn bên phải. | Cầu có khả năng là điểm nghẽn. Các hàng quân trông có tổ chức nhưng không chứng minh người chơi kéo đội hình hay lệnh tập kết. Có thể cùng chủ đề với cảnh1 nhưng giao diện khác; chưa biết cùng game/bản dựng. |
| 00:06–00:09 | Cắt sang đảo cát/cây cọ/vách đá, nước bao quanh. Một cầu tàu và tàu đỏ ở dưới. Quân đỏ/xanh đánh nhau trên bờ, lửa vàng, đạn vệt/khói từ phía biển, splash xanh trên đất/nước. Trên có 55/50,536, biểu tượng lửa kèm 1:25, hai thanh màu kèm số; thanh ở giữa ghi 1m 5s. Hai thẻ quân+búa bên trái dưới, bánh răng phía phải, minimap dưới phải. | Tàu có vẻ tham chiến/bị bắn. 55/50 có thể là dân số/giới hạn nhưng giá trị vượt mẫu số nên không khẳng định. Hiệu ứng xanh có thể trúng đạn trên nước hoặc kỹ năng, không đủ dữ liệu. |
| 00:09–00:12 | Cắt sang hai đảo cát lớn nối cầu hẹp dài theo chiều dọc. Quân đỏ trên đảo bắc, xanh đảo nam; các cụm chạy/đánh dọc cầu. Có nhà nhỏ, cọ, hàng rào, tàu ngoài bờ và lửa/nổ. Trên có 50000/200, đồng hồ 00:45, thanh xanh kèm tim. Dưới có nhiều thẻ hình quân khác nhau và búa, minimap phải. | Bản đồ nhiều tuyến/đảo và cầu có thể là nền tảng chiến thuật. Số lượng thẻ khác trước củng cố khả năng đây là montage nhiều phiên bản/game. Không thể suy ra cơ chế mở khóa quân hay chiến dịch. |

Mốc cắt xấp xỉ 3,6,9 giây; phần phân tích không coi thay đổi camera giữa các cảnh là thao tác của người chơi. Video chỉ cho vài giây mỗi trận, không cho thấy khởi đầu/kết thúc trận hay tổng thời lượng.

## Tổng hợp quan sát
- Pixel 2D nhiều màu, quân rất nhỏ, màu phe chủ yếu đỏ/xanh; có sprite cầm vũ khí nhưng độ dài đoạn và mật độ không đủ gọi chính xác tên từng loại.
- Cảnh1 top-down; cảnh2 xiên; cảnh3–4 nhìn trên xuống có độ cao vách/nhà. Luôn bố cục dọc, thông tin ở trên, thẻ quân dưới và minimap bên phải.
- Có nhiều công trình, hàng rào/đá/cây trang trí, nước và cầu. Chưa xác nhận công trình có phá được, nước có đi qua được hay thuyền có điều khiển.
- Quân nhỏ di chuyển tự động qua các frame, đạn/vệt sáng/nổ và khói tạo nhịp giao chiến nhanh. Không có con trỏ, vòng chọn, dấu chạm hay chuỗi thao tác UI đáng tin cậy.
- Audio có track AAC; việc gán một âm thanh cụ thể cho đòn đánh hoặc nút UI không được xác minh bằng nghe trực tiếp trong môi trường này.

## Điều không đủ bằng chứng
Không khẳng định chạm triển khai, kéo camera, chọn nhiều quân, build bằng búa, cooldown, tự tăng tài nguyên, mua/nâng quân, công trình là căn cứ, cơ chế capture, AI công bằng, kỹ năng, điều kiện thắng hoặc campaign. Không suy ra số liệu damage/HP/tốc độ từ video.

## Giả định và đề xuất để tạo luật nhất quán
Chọn top-down orthogonal thay vì ghép luật tàu/isometric chưa rõ. Giữ màu phe tương phản, quân tự chiến đấu, cầu nối đảo, nhiều tuyến và minimap. Màu ta xanh ngọc kèm hình khiên, địch đỏ kèm cờ; hình từng vai trò khác nhau, không chỉ khác màu. Game có bối cảnh đảo tiền đồn hư cấu, tên Binh Đoàn Tí Hon, toàn bộ địa hình và tài sản được làm riêng.

Giả định ban đầu: hai căn cứ1500HP (bản0.2.0 giữ1500HP cho hướng dẫn1–4 và dùng10000HP/giáp đối xứng từải5; xem design.md); tài nguyên tuyển quân180 đầu trận/8 mỗi giây; tối đa48 mỗi phe; trận180–300s; chạm thẻ rồi chạm đất triển khai; drag camera riêng biệt UI; ba lệnh và hai kỹ năng. Đề xuất mới: chiếm trạm+4 tài nguyên/s và vùng triển khai; 6 vai trò; tiến triển30 ải/3 chương; nâng cấp; hồ sơ offline; mục tiêu capture/hold/survive; sao và thưởng. Những phần này là thiết kế trong design.md, không được trình bày là tính năng đã quan sát được.

## Các lựa chọn đã cân nhắc
1. RTS top-down hai căn cứ + cầu + tự chiến đấu (chọn): dễ đọc và điều khiển một tay, thích hợp Android, có quyết định tuyến/đội hình/tài nguyên.
2. Chiến thuật đội hình góc xiên: gần cảnh2, nhưng chọn/điều khiển nhiều quân trên điện thoại cần thêm bằng chứng và UI phức tạp.
3. RTS hải chiến đổ bộ: khai thác cảnh3–4, cần thêm luật thuyền/đổ bộ khác biệt. Hoãn sang phiên bản khác để không trộn các quy tắc chưa rõ.
