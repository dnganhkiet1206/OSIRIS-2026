# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** user vẫn chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu user dán kết quả runbook vào phiên, xử lý trước (điền baseline §4b / sửa lỗi compile nếu có) rồi mới làm task dưới.

## Current Milestone

**M1 — Core Runtime** (DEVELOPMENT_PLAN.md §2)

## Current Task

**M1-2 — Gateway Retrieval & Assembly: context từ Store vào prompt theo budget (AD-24)**

## Objective

AI Gateway thực hiện đúng chuỗi đã khai báo trong AD-24: **retrieve (qua Store.search) → assemble → budget → cache → route → đo**. Sau M1-2: một goal về chủ đề đã có Knowledge/WorkingContext trong project sẽ mang theo context liên quan trong prompt — chất lượng tăng mà không tăng kích thước context bừa bãi (budget 4 mức cắt từ Optional).

## Phạm vi

1. **DefaultAIGateway nhận `store: (any Store)?`** (optional — Gateway vẫn hoạt động không cần Store, giữ test hiện tại nguyên trạng): trước khi gọi provider, `store.search(task, projectID)` lấy tối đa N kết quả (từ budgets.json, vd `maxContextSnippets: 3`).
2. **Assembly theo ContextPriority** (trả nợ "ContextPriority chưa tiêu thụ"): preamble + task = `.critical`; WorkingContext = `.important`; Knowledge/Deliverable snippet = `.helpful`. Vượt `contextBudgetTokens` (đã có trong budgets.json) → cắt từ ưu tiên thấp lên (TokenEstimator đo).
3. **Cache key phải gồm context** (context khác → không được trả cache cũ sai).
4. **Store.search relevance v1:** tokenize needle theo từ, score = số từ khớp (thay vì cần nguyên chuỗi) — CHỈ cho search phục vụ Gateway; **reuse của Kernel giữ strict full-goal match** (không nới — thà miss còn hơn sai). Cách tách: `StoreQuery.matchMode: .exact | .anyWord` (field mới, default `.exact` — hành vi cũ không đổi) — quyết định cuối trong phiên với Năm Câu Hỏi.
5. **Tests:** knowledge liên quan xuất hiện trong captured prompt; project khác không rò context (Context Isolation); vượt budget → phần Optional/Helpful bị cắt, Critical không bao giờ; cache không trả nhầm khi context đổi; toàn bộ test cũ pass nguyên trạng.

## Files cần tạo

- `Tests/CoreTests/GatewayRetrievalTests.swift`.

## Files cần sửa

- `Core/AIGateway/DefaultAIGateway.swift` (+ có thể `Core/AIGateway/AIGateway.swift` nếu cần type assembly nhỏ).
- `Core/Store/Store.swift` + `FileBackedStore.swift` (matchMode).
- `Config/budgets.json` (+`maxContextSnippets`), CompositionRoot (truyền store vào Gateway).
- `Docs/PROJECT_STATE.md`, `CHANGELOG.md`, `NEXT_TASK.md` (M1-3) — cuối phiên.

## Dependency

- Store.search + ContextPriority + TokenEstimator + budget đã sẵn. Không dependency ngoài, offline.

## Checklist

- [ ] Đường AI call vẫn duy nhất `Kernel → Gateway → Provider`; Gateway chạm Store qua protocol (AD-24 cho phép), KHÔNG chạm LocalStorage (arch test canh).
- [ ] Reuse của Kernel không đổi hành vi (strict match giữ nguyên — test cũ pass nguyên trạng).
- [ ] Context Isolation: query luôn scope theo projectID; không project nào thấy dữ liệu project khác.
- [ ] Preamble + task không bao giờ bị cắt (Critical); log metrics thêm số snippet đưa vào (đo được mới tối ưu được).
- [ ] Không tạo Context Engine/Builder/Loader như component riêng (banned — assembly là private trong Gateway).
- [ ] `swift build` 0 warning; toàn bộ test pass offline.
- [ ] Self/Architecture Review + docs + NEXT_TASK mới (M1-3).

## Definition of Done

Captured prompt chứng minh: context liên quan (đúng project) được đưa vào theo ưu tiên, bị cắt đúng thứ tự khi vượt budget, cache an toàn với context; ContextPriority hết là dead contract; zero regression.

## Estimated Complexity

Trung bình — chạm pipeline Gateway (vùng nhạy cảm nhất), nhưng toàn bộ sau interface hiện có.

## Estimated AI Cost

Dev session: trung bình. Runtime: 0 (Placeholder/Capturing provider).

## Risk

- Retrieval kém chất lượng → nhiễu prompt: giữ N nhỏ (3), score đơn giản, đo bằng metrics — tối ưu ở M3 khi có số liệu thật.
- Đổi `search` semantics làm reuse tham → matchMode default `.exact` bảo toàn hành vi cũ; test reuse hiện có là guard.

## Những phần tuyệt đối không được sửa

- Contract `AIGateway`/`AIProvider`/`ChatService`/`TaskUpdate` (assembly là nội bộ DefaultAIGateway).
- Kernel Decide/skill matching (vừa chốt ở M1-1).
- Ranh giới AD-25/32/33; Architecture Test rules (chỉ được THÊM).
- ADR cũ (AD-01…AD-35).
