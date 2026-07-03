# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thực hiện → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc.
>
> **Song song:** user vẫn chưa chạy `Docs/RUNBOOK_M1-0.md`. Kết quả runbook là INPUT quan trọng cho M1 Review — nếu có trước phiên M1-5 thì baseline/verification được nghiệm thu trọn vẹn.

## Current Milestone

**M1 — Core Runtime** — task cuối: nghiệm thu milestone.

## Current Task

**M1-5 — M1 Review: nghiệm thu Core Runtime**

## Objective

Nghiệm thu M1 theo đúng khuôn M0 closeout (PROJECT_STATE §4b): đối chiếu Definition of Done của DEVELOPMENT_PLAN §2/M1 + §3, chốt các quyết định treo, ghi Milestone Acceptance Report, tag `M1`, và đề xuất ưu tiên M2.

## Phạm vi (REVIEW — không viết tính năng mới)

1. **Đối chiếu tiêu chí M1** (DEVELOPMENT_PLAN §2/M1): Skill Registry ✅/❓, Store đầy đủ ✅/❓, Gateway đầy đủ ✅/❓, Execution (parallel/resume — quyết định cuối cho phần hoãn AD-36), Kernel đầy đủ (Confidence 3 tier — mới có High/Low v0; approval gates — RequireUserApprovalGate wired nhưng chưa được Decide tham vấn vì chưa có risky action; đánh giá trung thực: đạt mức M1 hay ghi nợ sang M2/M3?), Tool Layer v1 ✅. Tiêu chí "task hoàn thành không cần AI call nào khi tài nguyên đáp ứng" — ✅ có test (reuse + tool).
2. **Quyết định cuối parallel/resume:** đề xuất giữ hoãn (bằng chứng vẫn chưa xuất hiện) — ghi thành quyết định của milestone, điều kiện kích hoạt rõ ràng (parallel: khi Planner tách goal đa task ở M3; resume: khi có bằng chứng suspend làm mất tiến độ thật trên thiết bị).
3. **Tổng kết nợ kỹ thuật** phân loại Critical/High/Medium/Low; Critical phải = 0 trước khi mở M2.
4. **Chạy đủ review battery:** Self/Architecture/Quality/Security/Performance (số pipeline baseline có thể đo lại để so M0).
5. **Milestone Acceptance Report** (khuôn M0): hoàn thành/chưa, chỉ số chất lượng, kiến trúc, khuyến nghị M2 (ưu tiên đề xuất: M2 = User Experience — Sidebar/Projects/Search/Dashboard — hoặc chèn M1-6 nếu review lộ thiếu sót chặn).
6. **Tag `M1`** (local nếu push vẫn bị chặn — ghi chú như M0).

## Files cần sửa

- `Docs/PROJECT_STATE.md` (mục §4c — M1 Closeout), `CHANGELOG.md` (mục [M1]), `Docs/DEVELOPMENT_PLAN.md` (đánh dấu M1 + ghi quyết định parallel/resume), `NEXT_TASK.md` (M2-1 hoặc M1-6 tùy kết quả review).

## Checklist

- [ ] Từng tiêu chí M1 đánh giá trung thực: pass / partial / pending kèm lý do — không che giấu (Confidence medium chưa dùng; approval gate chưa được tham vấn; EventBus chưa consumer; runbook M1-0 pending là của user).
- [ ] Quyết định parallel/resume ghi vào DEVELOPMENT_PLAN với điều kiện kích hoạt.
- [ ] Nợ Critical = 0; bảng nợ cập nhật đủ.
- [ ] Security quét lại nhanh (key literal, log).
- [ ] Tag M1 tạo (annotated, message tổng kết).
- [ ] Báo cáo nghiệm thu đầy đủ trong PROJECT_STATE + chat; NEXT_TASK mới.

## Definition of Done

M1 được nghiệm thu (hoặc danh sách thiếu sót chặn rõ ràng kèm M1-6); mọi quyết định treo được chốt và ghi; tag tạo; đề xuất M2 sẵn sàng chờ user duyệt.

## Estimated Complexity

Thấp — phiên review + tài liệu, không code mới (trừ sửa nhỏ nếu review lộ lỗi).

## Estimated AI Cost

Dev session: nhỏ. Runtime: 0.

## Risk

- Review lộ thiếu sót chặn → trung thực ghi M1-6 thay vì ép nghiệm thu.

## Những phần tuyệt đối không được sửa

- Toàn bộ code trừ khi review phát hiện lỗi thật (fix có bằng chứng, không "tiện tay").
- Architecture Test rules (chỉ THÊM); ADR cũ (AD-01…AD-37).
