# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M4 — YouTube Module (Reference Implementation)** (DEVELOPMENT_PLAN.md §2/M4, AD-21/44/45)

## Current Task

**M4-4 — M4 Milestone Review & Acceptance**

## Vì sao review bây giờ (lập luận tại M4-3)

Khuôn mẫu module đã LẶP 4 mảng nghiệp vụ (ideas, script, SEO/publishing, channel analysis) + 3 composition (gồm xuyên namespace) mà không một lần chạm Core/contract — mục tiêu M4 ("chứng minh mô hình mở rộng") đã đủ bằng chứng để nghiệm thu khuôn. Phần capability còn thiếu so với danh mục gốc (Thumbnail/Shorts Planning — data thuần theo khuôn có sẵn, Research đã có qua composition xuyên namespace) không thêm bằng chứng kiến trúc mới — bổ sung theo NHU CẦU THẬT khi user dùng app, không phải để đủ danh sách.

## Phạm vi review (theo mẫu M1-5/M2-6/M3-4)

1. **Đánh giá trung thực tiêu chí M4** (DEVELOPMENT_PLAN §2/M4): "hoàn thành công việc YouTube có ý nghĩa end-to-end bằng mục tiêu một câu" — ✅/⚠️ từng phần, PENDING thiết bị ghi rõ; "module tuân thủ 100% Module contract, không đụng Core" — bằng chứng git + thí nghiệm gỡ module (M4-2).
2. **ADR M4:** AD-44/45 — Decision → Evidence → Result.
3. **Xử deadline EventBus (hẹn từ M2-4/AD-39):** 4 điểm dữ liệu "module không cần events" đã đếm đủ M4 — quyết giữ/xóa với lập luận (lưu ý: chat relay + dashboard vẫn là 2 consumer thật; câu hỏi là bus có đáng hơn 2 closure trực tiếp không).
4. **Phân loại lại nợ kỹ thuật**; retrospective khuôn M4 (guideline curated-union 2 lần tinh chỉnh → chốt thành văn cho M5).
5. **Acceptance report + tag `M4`** (local) + cập nhật DEVELOPMENT_PLAN (M4 marked; Thumbnail/Shorts ghi "theo nhu cầu thật") + NEXT_TASK cho M5-0 (module thứ hai — TikTok theo thứ tự giá trị; khuôn copy từ YouTube).
6. **Open-source readiness check** (đã hẹn ở M3-4): M4 xong = điều kiện "module contract proven" đạt; còn lại runbook + Store versioning — cập nhật đánh giá.

## Checklist

- [ ] Không sửa code trừ khi review phát hiện lỗi thật hoặc quyết định EventBus được chốt là XÓA (khi đó thực thi + arch test cập nhật theo chiều XÓA component khỏi codebase — không phải nới rule).
- [ ] Mọi PENDING có địa chỉ; ADR cũ không sửa; tag M4 local.
- [ ] Zero regression (133 + thay đổi nếu có).

## Definition of Done

Bảng tiêu chí M4 trung thực; AD-44/45 evidence; EventBus quyết xong có lập luận; nợ phân loại lại; tag `M4`; NEXT_TASK M5-0; DỪNG chờ user xác nhận.

## Estimated Complexity

Thấp–trung bình — quyết định EventBus là phần nặng nhất.

## Estimated AI Cost

Dev session: nhỏ. Runtime: 0.

## Risk

- EventBus: 2 consumer thật đang chạy — xóa vội phá chat status + dashboard activity; giữ vô điều kiện lại nuôi abstraction thiếu bằng chứng. Quyết định phải so CHI PHÍ THAY THẾ (2 closure inject) vs CHI PHÍ GIỮ (1 actor generic mỏng).
- Tự nghiệm thu dễ dãi — PENDING thiết bị ghi trung thực như mọi milestone.

## Những phần tuyệt đối không được sửa

- Core 6; ModuleManifest; matcher; toàn bộ M3 vừa chốt.
- Architecture Test rules (chỉ THÊM/siết trừ trường hợp xóa-component có quyết định); ADR cũ (AD-01…AD-45).
