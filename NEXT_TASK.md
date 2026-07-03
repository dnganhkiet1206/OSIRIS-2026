# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M3 — Intelligence Layer** (DEVELOPMENT_PLAN.md §2/M3)

## Current Task

**M3-4 — M3 Milestone Review & Acceptance**

## Vì sao review thay vì làm tiếp phạm vi M3 còn lại (lập luận đã tự đánh giá tại M3-3)

Phạm vi M3 theo DEVELOPMENT_PLAN: smart planning ✅ (M3-2) · reflection có gate ✅ (M3-1) · deliverable templates ✅ (M3-3) · auto-update state ✅ (có từ M0, reflection bồi thêm M3-1). Hai mục còn lại đều **evidence-gated**:
- *Reuse pipeline "hoàn chỉnh"*: reuse exact-match + search 3 loại record + cache Gateway ĐÃ chạy từ M0-4/M1-2; phần "hoàn chỉnh" (relevance-ranked reuse, cross-project) mang rủi ro wrong-reuse — cần dữ liệu sử dụng thật trước khi nới (thà miss còn hơn reuse sai).
- *Cache optimization*: `InMemoryResponseCache` chưa có số liệu hit-rate thật (chưa chạy trên thiết bị với API key) — tối ưu không số liệu là đoán.

→ Cả hai chờ baseline thật từ runbook (nợ High của user). Review milestone bây giờ, kích hoạt 2 mục này khi có evidence (ghi điều kiện vào DEVELOPMENT_PLAN).

## Phạm vi review (theo mẫu M1-5/M2-6)

1. **Đánh giá trung thực tiêu chí M3** (DEVELOPMENT_PLAN §2/M3) — bảng Tiêu chí → Kết quả, PENDING ghi trung thực kèm địa chỉ.
2. **ADR M3:** AD-41/42/43 — Decision → Evidence → Result (PROVEN bằng test nào).
3. **Xử deadline đã hẹn:**
   - `SkillDefinition.retryPolicy` — deadline "M3 review nếu vẫn không consumer → cân nhắc xóa field (AD-28 hai chiều)". Đến hạn: quyết định + thực thi.
   - Tier routing (nợ Medium nửa còn lại): xác nhận điều kiện kích hoạt (≥2 model thật) và chủ sở hữu.
   - EventBus: deadline là M4 — KHÔNG xử ở đây, chỉ xác nhận còn hẹn.
4. **Phân loại lại nợ kỹ thuật** Critical/High/Medium/Low; retrospective ngắn (pattern lặp: default-param → clean rebuild ×4 — có đáng ghi quy trình?).
5. **Acceptance report + git tag `M3`** (local, push khi merge) + NEXT_TASK cho M4 (YouTube Module — reference implementation, AD-21; đọc kỹ DEVELOPMENT_PLAN §2/M4 trước khi viết).
6. **DEVELOPMENT_PLAN:** đánh dấu M3, ghi điều kiện kích hoạt 2 mục hoãn.

## Checklist

- [ ] Không sửa code trừ khi review phát hiện lỗi thật hoặc quyết định xóa `retryPolicy` được chốt.
- [ ] ADR cũ không sửa (chỉ Superseded nếu cần); arch test chỉ THÊM.
- [ ] Mọi PENDING có địa chỉ + chủ sở hữu (không giấu).
- [ ] Zero regression nếu có thay đổi code (114 test + số mới nếu thêm).

## Definition of Done

Bảng tiêu chí M3 trung thực; AD-41/42/43 có evidence; deadline `retryPolicy` xử xong; nợ phân loại lại; tag `M3`; NEXT_TASK M4-0; DỪNG chờ user xác nhận trước khi vào M4.

## Estimated Complexity

Thấp — chủ yếu đánh giá + tài liệu; một quyết định xóa-field có thể kèm code nhỏ.

## Estimated AI Cost

Dev session: nhỏ. Runtime: 0.

## Risk

- Tự nghiệm thu dễ dãi — dùng đúng thước DEVELOPMENT_PLAN, PENDING ghi trung thực như M0/M1/M2.
- Xóa `retryPolicy` vội trong khi M4 module có thể cần — quyết định phải kèm lập luận chi phí giữ vs xóa (AD-28 hai chiều: thêm khi có bằng chứng, xóa khi hết lý do chờ).

## Những phần tuyệt đối không được sửa

- WriteGate/Reflection (M3-1), ComplexityEstimate/confidence (M3-2), scaffold pipeline (M3-3) — vừa chốt.
- Architecture Test rules (chỉ THÊM); ADR cũ (AD-01…AD-43).
