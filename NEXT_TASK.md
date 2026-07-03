# NEXT_TASK.md

> **TRẠNG THÁI: CHỜ USER DUYỆT MỞ M3.** M2 đã nghiệm thu (PROJECT_STATE §4d, tag `M2`). Task dưới đây là ĐỀ XUẤT đầu tiên của M3 — không tự ý bắt đầu.
>
> **Nợ High vẫn treo:** `Docs/RUNBOOK_M1-0.md` — giờ chặn cả xác minh UX M2 trên thiết bị. M3 là milestone Core-heavy (ít UI) nên có thể chạy song song, nhưng càng để lâu càng đắt.

## Current Milestone

**M3 — Intelligence Layer** (DEVELOPMENT_PLAN.md §2/M3: smart planning, reuse pipeline hoàn chỉnh, cache tối ưu, reflection có gate, deliverable templates, auto state update)

## Current Task (đề xuất)

**M3-1 — Reflection & Write Gate v1: AD-20 có consumer đầu tiên**

## Objective

ADR chờ lâu nhất (AD-20 — learning gate, từ v1.1) có consumer thật: sau mỗi execution thành công, pha Persist chạy một bước **reflection tối giản, deterministic** (chưa AI): quyết định *có gì đáng ghi vào Store làm việc tương lai rẻ hơn không* — và mọi ghi phải qua **write gate** đọc từ `policies.json` (trả nợ Medium "write gate chưa enforce bằng code"). Sau M3-1: goal lặp *gần giống* (không exact) bắt đầu hưởng lợi từ WorkingContext do hệ thống tự ghi.

## Phạm vi

1. **WriteGate (Core/Store/Policies/):** đọc `policies.json > storeWriteGate.requiresAnyOf` (đã có sẵn từ M0-1!) — một hàm thuần `allows(WriteJustification) -> Bool`; `WriteJustification` = tập lý do khai báo (`reusableLater`, `affectsArchitecture`, `reducesFutureTokens`).
2. **Reflection v0 (deterministic, KHÔNG AI call):** trong Persist, sau khi save deliverable: nếu strategy là `.ai/.composition` và goal chứa tín hiệu chủ đề (đơn giản: goal length ≥ N từ) → ghi một `WorkingContextRecord` (TTL từ policies.json `workingContextDefaultTTLHours` — cũng có sẵn!) tóm tắt: goal + path deliverable, justification `reusableLater`. Gate từ chối → không ghi (test).
3. **Kernel giữ thuần:** quyết định "ghi gì" là Decide-đúng-nghĩa → logic reflection nằm trong Kernel (pure decision) nhưng thao tác ghi qua Store như mọi khi; policies inject qua init (data, không I/O trong Kernel — composition đọc file).
4. **Đo được:** event mới? Không — log qua Store? Giữ tối giản: đếm trong test.
5. **Tests:** gate cho phép/từ chối theo policy; reflection ghi WorkingContext đúng TTL; goal ngắn không ghi (không rác); reuse `.anyWord` của Gateway retrieval nhặt được record vừa ghi ở goal liên quan (khép vòng giá trị).

## Files cần tạo

- `Core/Store/Policies/WriteGate.swift`, `Tests/CoreTests/ReflectionTests.swift`.

## Files cần sửa

- `Core/Kernel/Kernel.swift` (Persist + reflection decision; init nhận `WritePolicy` data), `App/AppComposition/CompositionRoot.swift` (đọc policies.json đầy đủ → inject), có thể `PoliciesFile` mở rộng.
- Docs cuối phiên (+AD-41: reflection v0 deterministic — AI-reflection chỉ khi có bằng chứng đáng tiền).

## Checklist

- [ ] AD-20 chuyển trạng thái AWAITING → PROVEN (gate có consumer + test).
- [ ] Reflection KHÔNG gọi AI, KHÔNG thêm token cost; mọi ghi qua gate; gate đọc từ config (không hardcode lý do).
- [ ] Kernel vẫn thuần (arch test canh); Store vẫn persister duy nhất.
- [ ] Không ghi rác: goal ngắn/tool/reuse không sinh record (tool đã 0-persist theo AD-37).
- [ ] `swift build` 0 warning; toàn bộ test pass offline.
- [ ] Đủ quy trình review + docs + NEXT_TASK (M3-2 — Smart Planning: complexity estimate + confidence Medium có consumer).

## Definition of Done

Write gate enforce từ config; reflection deterministic ghi WorkingContext có TTL sau execution AI thành công; retrieval nhặt được record ở goal liên quan (test end-to-end); AD-20 PROVEN; zero regression.

## Estimated Complexity

Trung bình — chạm Persist của Kernel (vùng nhạy cảm), nhưng thuần data-driven.

## Estimated AI Cost

Dev session: nhỏ–trung bình. Runtime: 0 (reflection deterministic).

## Risk

- Reflection ghi rác làm nhiễu retrieval — tiêu chí ghi chặt (thà không ghi), TTL tự dọn, gate từ config.
- Đụng Persist → giữ mọi test reuse/persist hiện có làm guard.

## Những phần tuyệt đối không được sửa

- Gateway pipeline; Execution; contract Store hiện có (WriteGate là type mới cạnh Store, không đổi protocol trừ khi có bằng chứng trong phiên — nếu cần method mới phải lập luận).
- Architecture Test rules (chỉ THÊM); ADR cũ (AD-01…AD-40).
