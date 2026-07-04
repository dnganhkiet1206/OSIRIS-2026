# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M5 — Platform Expansion** (DEVELOPMENT_PLAN.md §2/M5) — tiêu chí ≥3 module ĐÃ ĐẠT

## Current Task

**M5-2 — M5 Milestone Review & Acceptance**

## Vì sao review bây giờ

Tiêu chí hoàn thành M5 (DEVELOPMENT_PLAN §2/M5) = "≥3 module hoạt động mà Core không đổi" — ĐÃ ĐẠT: YouTube (M4) + TikTok (M5-0) + Shopify (M5-1), mỗi module 0 dòng Core/contract. Guide-test đạt 2 lần trên 2 domain khác nhau (content-creation, e-commerce). Không có bằng chứng cần thêm module thứ 4 để nghiệm thu khuôn — module tiếp theo thêm theo NHU CẦU THẬT, không phải để review.

## Phạm vi review (mẫu M1-5/M2-6/M3-4/M4-4)

1. **Đánh giá trung thực tiêu chí M5:** bảng Tiêu chí → Kết quả; "≥3 module Core-không-đổi" (bằng chứng git 5 lần liên tiếp + thí nghiệm gỡ module M4-2); "chứng minh plugin architecture" (2 guide-test, 2 domain).
2. **MODULE_GUIDE tự-đủ:** xác nhận đủ cho người ngoài (Phụ lục A+B đóng finding M5-0); còn thiếu gì cho module #4 không — trả lời bằng bằng chứng từ chính M5-1.
3. **Matcher theo số liệu:** giờ ~18 skill / 3 module + generic; curated-union + sweep tự động đã chặn mọi ca; có bằng chứng cần đổi matcher chưa? (kết luận từ số liệu, không dự đoán).
4. **Nợ kỹ thuật rà toàn bộ:** latent overlap tiếng Việt YouTube (M5-0, Low) — đến hạn sửa chưa hay vẫn evidence-gated; ApprovalGate (M6), tier routing (≥2 model), ChatViewModel trigger — không đến điều kiện thì giữ hẹn.
5. **Acceptance report + tag `M5`** (local) + DEVELOPMENT_PLAN (M5 marked) + NEXT_TASK cho M6-0 (Automation — scheduling/background/MCP; đọc kỹ §2/M6; đây là nơi tool-channel AD-45 + risky-action ApprovalGate + EventBus-tái-sinh có thể đến điều kiện).
6. **Open-source readiness:** cập nhật đánh giá — module contract PROVEN + guide tự-đủ; còn lại runbook (user) + Store versioning (M7).

## Checklist

- [ ] Không sửa code trừ khi review phát hiện lỗi thật (vd quyết định sửa latent overlap YouTube — nếu làm thì kèm precedence test tiếng Việt).
- [ ] Mọi PENDING có địa chỉ; ADR cũ không sửa; tag M5 local.
- [ ] Zero regression (146 + thay đổi nếu có).

## Definition of Done

Bảng tiêu chí M5 trung thực; plugin architecture PROVEN bằng bằng chứng; matcher/nợ kết luận theo số liệu; tag `M5`; NEXT_TASK M6-0; DỪNG chờ user xác nhận trước khi vào M6.

## Estimated Complexity

Thấp — đánh giá + tài liệu.

## Estimated AI Cost

Dev session: nhỏ. Runtime: 0.

## Risk

- Tự nghiệm thu dễ dãi — dùng đúng thước DEVELOPMENT_PLAN; PENDING thiết bị (runbook) ghi trung thực như mọi milestone.
- Cám dỗ thêm module thứ 4 "cho chắc" — tiêu chí đã đạt, thêm là scope creep; module mới theo nhu cầu thật ở M5+/M6.

## Những phần tuyệt đối không được sửa

- Core 6; ModuleManifest; matcher; 3 module (trừ khi sửa latent overlap có test).
- Architecture Test rules (chỉ THÊM/siết); ADR cũ (AD-01…AD-46).
