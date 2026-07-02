# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** user chạy `Docs/RUNBOOK_M1-0.md` (Mac verification + baseline thật). Nếu user dán kết quả runbook vào phiên, ưu tiên xử lý trước (điền baseline §4b / sửa lỗi compile nếu có) rồi mới làm task dưới.

## Current Milestone

**M1 — Core Runtime** (DEVELOPMENT_PLAN.md §2)

## Current Task

**M1-1 — Skill Registry hoạt động: skill tổng quát đầu tiên đi qua vòng đời thật**

## Objective

Kernel chọn skill theo capability và Execution chạy skill qua Gateway — trả món nợ "`Kernel.skills` là dependency chưa tiêu thụ" và biến Skill Registry từ skeleton thành thành phần sống. Sau M1-1: goal dạng "summarize…" chạy qua skill Summarize với promptTemplate riêng thay vì prompt trần.

## Phạm vi

1. **3 skill tổng quát** (Core/Skills/BuiltIn — generic, KHÔNG business): `summarize`, `draft`, `research-outline`. Mỗi skill: schema AD-28 (id, version, capabilityTags, purpose, inputs, outputs) + `promptTemplate` (có chỗ chèn `{goal}`), `preferredModelTier`.
2. **Kernel Decide chọn skill:** sau reuse-check, tra `skills.skills(providing:)` theo capability suy ra từ goal (heuristic keyword đơn giản v0 — khai báo trong skill? cân nhắc: capability matching bằng keyword list trong SkillDefinition optional field mới `triggerKeywords`? CHỈ thêm nếu qua Năm Câu Hỏi; thay thế: map keyword→capability đặt trong Kernel Decision — quyết định trong phiên, ghi lý do).
3. **ExecutionStrategy/Plan mang skill:** đường `.ai` có thêm thông tin skill được chọn (vd `ExecutionPlan.skill: SkillDefinition?`); Execution assemble template + goal → AIRequest (máy móc — template là data, không phải quyết định). Không skill khớp → `.ai` trần như hiện tại (fallback không đổi hành vi cũ).
4. **Đăng ký tại composition:** BuiltIn skills đăng ký vào InMemorySkillRegistry khi khởi động.
5. **Tests:** chọn đúng skill theo goal; template được áp vào prompt (kiểm qua CountingProvider/URLProtocol capture); goal không khớp → fallback nguyên trạng; registry lookup theo capability đã có test.

## Files cần tạo

- `Core/Skills/BuiltIn/GenericSkills.swift` — 3 SkillDefinition (data, không logic).
- `Tests/CoreTests/SkillSelectionTests.swift`.

## Files cần sửa

- `Core/Kernel/Kernel.swift` — Decide: reuse → skill-match → ai-fallback (thứ tự tài nguyên).
- `Core/Execution/ExecutionEngine.swift` + `DefaultExecutionEngine.swift` — plan mang skill; assemble template máy móc.
- `App/AppComposition/CompositionRoot.swift` — đăng ký BuiltIn skills.
- `Docs/PROJECT_STATE.md`, `CHANGELOG.md`, `NEXT_TASK.md` (M1-2) — cuối phiên.

## Dependency

- Registry, schema, Gateway đã sẵn. Không dependency ngoài, không network, chạy Placeholder.

## Checklist

- [ ] `Kernel.skills` được tiêu thụ thật (xóa dòng nợ tương ứng trong PROJECT_STATE §6).
- [ ] Skill matching là quyết định → chỉ ở Kernel; template assembly là thi hành → chỉ ở Execution (arch tests canh).
- [ ] Goal không khớp skill nào → hành vi y hệt trước M1-1 (không regression; test cũ pass nguyên trạng).
- [ ] Skill là data thuần — không skill nào chứa closure/logic.
- [ ] Không tạo Prompt Registry (AD-04 — template sống trong SkillDefinition).
- [ ] `swift build` 0 warning; toàn bộ test pass offline.
- [ ] Self/Architecture Review + docs + NEXT_TASK mới (M1-2).

## Definition of Done

Một goal khớp capability chạy qua skill với template riêng (chứng minh bằng captured prompt); goal không khớp giữ nguyên hành vi; nợ `Kernel.skills` đã trả; tài liệu cập nhật.

## Estimated Complexity

Trung bình — chạm Decide (nhạy cảm về ranh giới) nhưng không contract mới lớn.

## Estimated AI Cost

Dev session: nhỏ–trung bình. Runtime: 0 (Placeholder).

## Risk

- Keyword matching quá tham → chọn nhầm skill: giữ danh sách keyword hẹp, thà fallback còn hơn sai (nhất quán triết lý reuse).
- Field optional mới trên SkillDefinition (nếu chọn hướng đó) phải qua Năm Câu Hỏi — AD-28 cho phép thêm khi có bằng chứng.

## Những phần tuyệt đối không được sửa

- `DefaultAIGateway` pipeline; contract Store/AIProvider/ChatService/TaskUpdate.
- Ranh giới AD-25/33 (Kernel quyết định — Execution thi hành — arch tests canh).
- Architecture Test rules (chỉ được THÊM).
- ADR cũ (AD-01…AD-35).
