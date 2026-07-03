# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M4 — YouTube Module (Reference Implementation)** (DEVELOPMENT_PLAN.md §2/M4, AD-21/44)

## Current Task

**M4-3 — Channel Analysis v1 + quyết định tool-contribution-channel (có bằng chứng đầu tiên)**

## Objective

Channel Analysis là capability M4 ĐẦU TIÊN không sống được bằng prompt thuần: phân tích kênh cần DỮ LIỆU THẬT (danh sách video, views, CTR…). Đây chính là bằng chứng cụ thể mà M4-0/M4-1 đã hẹn cho câu hỏi: **mở rộng `ModuleManifest` thêm kênh đóng góp `tools`?** Task này (1) đặt và TRẢ LỜI câu hỏi contract với bằng chứng, (2) ship lát cắt mỏng nhất chứng minh.

## Phạm vi

1. **Phân tích trước khi code (BẮT BUỘC — đây là thay đổi contract đầu tiên):** trả lời Năm Câu Hỏi cho field optional `tools: [any Tool]` trên ModuleManifest (hoặc phương án khác nếu lập luận thắng — vd tool vẫn inject ở composition root, module chỉ khai báo SKILL dùng dữ liệu user dán vào). **So sánh ít nhất 2 phương án, chọn cái ít máy móc hơn.** Lưu ý: `any Tool` trong manifest kéo Tool protocol vào contract surface — cân nhắc Codable bị mất (manifest hiện Codable thuần data). Nếu quyết mở rộng contract → AD-45 + DỪNG trình user TRƯỚC KHI code nếu thay đổi lớn hơn 1 field optional.
2. **Lát cắt v1 (chọn theo kết quả (1)):** phương án tối thiểu có thể là `youtube.channel-analysis` skill nhận dữ liệu kênh do user DÁN VÀO goal (0 tool, 0 API, phân tích = prompt trên dữ liệu có sẵn — "AI Is The Last Tool" không vi phạm vì không có nguồn deterministic); tool/API thật để M6 (Automation) khi có MCP/network policy rõ.
3. **EventBus evidence tiếp tục đếm:** module thứ 3 mảng liên tiếp không cần events.
4. **Không làm:** YouTube API client/OAuth (M6+, cần user quyết privacy/network); Thumbnail/Shorts (M4-4+ hoặc M4 review quyết).

## Files cần tạo/sửa

- Tùy quyết định (1); tối thiểu: `Modules/YouTube/YouTubeModule.swift`, tests, docs (+AD-45 nếu contract đổi).

## Checklist

- [ ] Quyết định contract có văn bản Năm Câu Hỏi + 2 phương án trong report.
- [ ] Nếu contract KHÔNG đổi: 0 dòng Core, 0 dòng contract như M4-1/M4-2.
- [ ] Precedence keywords rà toàn registry (giờ 12+ skill — bảng overlap trong report).
- [ ] Zero regression 130 test cũ.
- [ ] Đủ quy trình review + docs + NEXT_TASK (đề xuất: M4-4 Milestone Review — khuôn mẫu đã lặp 3 lần, đủ bằng chứng đánh giá; Thumbnail/Shorts là data thuần có thể vào M5 cùng module mới).

## Definition of Done

Câu hỏi tool-channel được trả lời bằng lập luận + bằng chứng (không phải "để sau" mơ hồ); lát cắt Channel Analysis v1 chạy end-to-end offline; zero regression; contract chỉ đổi nếu Năm Câu Hỏi thắng VÀ user duyệt.

## Estimated Complexity

Trung bình — trọng tâm là quyết định kiến trúc, không phải khối lượng code.

## Estimated AI Cost

Dev session: trung bình. Runtime: 0.

## Risk

- Mở contract sớm vì "chắc sẽ cần" — kỷ luật: chỉ mở khi lát cắt v1 KHÔNG THỂ ship thiếu nó.
- Channel Analysis phình thành Analytics Engine — v1 là MỘT skill phân tích dữ liệu được cung cấp.

## Những phần tuyệt đối không được sửa

- Core 6 thành phần; matcher; WriteGate/Reflection/ComplexityEstimate/scaffold.
- `ModuleManifest` — CHỈ được đổi qua đúng quy trình mục (1) + user duyệt.
- Architecture Test rules (chỉ THÊM/siết); ADR cũ (AD-01…AD-44).
