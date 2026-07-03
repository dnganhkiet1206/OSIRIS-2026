# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → thực hiện → cập nhật tài liệu → tạo NEXT_TASK mới → dừng.
>
> **Input quan trọng:** nếu user đã chạy `Docs/RUNBOOK_M1-0.md`, kết quả điền vào nghiệm thu; nếu chưa, mục simulator/baseline tiếp tục PENDING trung thực.

## Current Milestone

**M2 — User Experience** — task cuối: nghiệm thu milestone.

## Current Task

**M2-6 — M2 Review: nghiệm thu User Experience**

## Objective

Nghiệm thu M2 theo khuôn M1-5 (bằng chứng, không giả định): đối chiếu DoD của DEVELOPMENT_PLAN §2/M2, xử các câu treo đã tích lũy, Milestone Acceptance Report, tag `M2`, đề xuất M3.

## Phạm vi (REVIEW — không tính năng mới)

1. **Đối chiếu tiêu chí M2:** Sidebar ✅ · Projects (resume tức thì) ✅ · Settings tối giản ✅ · Global Search ✅ · Dashboard nhận thức vận hành ✅ · Advanced Mode ✅ · Accessibility (code-level ✅ / mắt thường PENDING Mac) · "Người dùng mới hiểu app trong phút đầu" — đánh giá trung thực (chưa xác minh được trên thiết bị → partial/pending). Tiêu chí gốc "app cảm giác hoàn chỉnh" phụ thuộc runbook.
2. **Xử các câu treo:**
   - Tên port `ProjectDirectory` đang gánh list/create/overview/deliverable/search — đổi tên (`Workspace`? `ProjectPort`?) hay giữ? Quyết bằng Năm Câu Hỏi (rename churn vs rõ nghĩa).
   - `InMemorySecretsVault`: hết M2 không consumer → theo hẹn là XÓA (kiểm tra lần cuối rồi thực thi).
   - `ChatViewModel` 4 deps + nhiều vai (chat/search/dashboard/skills/projects) — god-object risk ở Presentation; đánh giá tách (SearchModel/DashboardModel-view riêng?) hay hoãn có điều kiện.
   - `SkillDefinition.retryPolicy` chưa consumer (hẹn từ M1 review: M3 không dùng → xóa field).
3. **Review battery:** Self/Architecture/Quality/Security/Performance (đo lại pipeline baseline so M0/M1).
4. **ADR M2 evidence table:** AD-38/39/40 → evidence → result.
5. **Tech debt tái phân loại**; Critical phải = 0.
6. **Acceptance Report + tag `M2`** (local nếu push bị chặn) + **NEXT_TASK đề xuất M3-1** (M3 = Intelligence Layer: smart planning, reuse pipeline hoàn chỉnh, reflection có gate AD-20, context optimization — chọn lát cắt đầu).

## Files cần sửa

- `Docs/PROJECT_STATE.md` (§4d M2 Closeout), `CHANGELOG.md` ([M2]), `Docs/DEVELOPMENT_PLAN.md` (đánh dấu M2), `NEXT_TASK.md` (M3-1); xóa `InMemorySecretsVault` nếu đúng hẹn (+ cập nhật docs liên quan).

## Checklist

- [ ] Từng tiêu chí M2: pass/partial/pending có bằng chứng, không che giấu.
- [ ] Các câu treo có quyết định ghi lại (kể cả quyết định "giữ nguyên" phải có lý do).
- [ ] Nợ Critical = 0; bảng nợ cập nhật.
- [ ] Security quét nhanh; baseline đo lại.
- [ ] Tag M2; báo cáo đầy đủ; NEXT_TASK M3-1.

## Definition of Done

M2 nghiệm thu (hoặc danh sách chặn rõ); câu treo xử xong; tag tạo; đề xuất M3 chờ duyệt.

## Estimated Complexity

Thấp — review + dọn dẹp nhỏ.

## Estimated AI Cost

Dev session: nhỏ. Runtime: 0.

## Risk

- Nhiều tiêu chí UX chỉ xác minh được trên thiết bị — nếu runbook vẫn chưa chạy, M2 sẽ nghiệm thu "code-complete với pending" như M0; trung thực, không ép.

## Những phần tuyệt đối không được sửa

- Code trừ dọn dẹp đã hẹn (InMemorySecretsVault) hoặc fix lỗi review lộ ra.
- Architecture Test rules (chỉ THÊM); ADR cũ (AD-01…AD-40).
