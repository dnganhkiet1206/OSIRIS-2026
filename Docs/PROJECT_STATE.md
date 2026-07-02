# PROJECT_STATE.md — Trạng Thái Dự Án OSIRIS

> **Cập nhật lần cuối:** 2026-07-02
> Đây là **nguồn sự thật duy nhất** về trạng thái dự án (nguyên tắc *State Over Chat*). Mọi phiên phát triển bắt đầu bằng việc đọc file này và kết thúc bằng việc cập nhật file này. Đây là **file duy nhất luôn được nạp** vào AI dev session (AD-29) — giữ file ngắn gọn, dạng cấu trúc.

---

## 1. Tổng quan nhanh

| Hạng mục | Giá trị |
|---|---|
| Giai đoạn | **M0 — Walking Skeleton, đang triển khai** |
| Task hiện tại | M0-1 (Bootstrap) ✅ hoàn thành · kế tiếp: M0-2 (xem `NEXT_TASK.md`) |
| Nền tảng | iOS (iPhone), SwiftUI · Core = SwiftPM package build được mọi nền tảng (AD-30) |
| Trạng thái kiến trúc | ✅ v1.1 — Core **6 thành phần**, đã qua Principal review lần 2 |
| Trạng thái codebase | ✅ Bootstrap compile sạch: **0 error / 0 warning, 8/8 test pass** (Swift 6.0.3, Linux) |

## 2. Mục tiêu hiện tại (Current Goal)

Hoàn thành Milestone 0: một lát cắt dọc mỏng chạy end-to-end (Chat UI → Kernel tối giản → AI Gateway → kết quả + persist ProjectState).

## 3. Việc đã hoàn thành (Completed)

- [x] Viết 18 phần đặc tả gốc (OSIRIS 1–18 .docx).
- [x] **Review vòng 1** (trên đặc tả gốc): 21 quyết định AD-01 → AD-21; ~16–20 tên component → 9 Core; 5 pipeline → 1 vòng đời chuẩn 5 pha; 6 registry → 2.
- [x] **Review vòng 2** (Principal review trên v1.0): 8 quyết định AD-22 → AD-29; Core 9 → **6**; sửa lỗi dual-source-of-truth (State Store vs Memory Store); hợp nhất Context Engine vào AI Gateway; Vision → Config artifact.
- [x] Ban hành bộ 5 tài liệu nền tảng v1.1: BLUEPRINT, STATE, PLAN, FOLDER_STRUCTURE, SYSTEM_COMPONENTS.
- [x] **M0-1 — Project Bootstrap** (AD-30): SwiftPM package (OsirisCore 6 thành phần + OsirisInfrastructure 5 thành phần), App shell SwiftUI + `project.yml` (XcodeGen), Config ngoài source (preamble + 5 json), tài liệu vào `Docs/`, kiểm chứng build + test trên Linux. Kernel skeleton chạy đủ 5 pha với placeholder provider (không tốn chi phí AI).

## 4. Việc đang chờ (Next Tasks) — theo thứ tự

1. **M0-2 — Store v0 bền vững + nạp Config thật** (chi tiết: `NEXT_TASK.md`): FileStorage-backed Store, ProjectState sống sót qua app restart; CompositionRoot đọc preamble/routing/budgets từ ConfigurationLoader thay vì hardcode.
2. M0-3 — AI Gateway v0: provider adapter thật (URLSession), API key qua SecretsVault (Keychain impl trên app layer), model từ routing.json.
3. M0-4 — Kernel Decide v0: direct vs ai + reuse check qua Store.search; nối ApprovalGate/ConfidenceTier vào pha Decide.
4. M0-5 — Chat UI v0 nối Kernel + hiển thị Execution Status events.
5. M0-6 — M0 review tổng: tiêu chí hoàn thành milestone + baseline token đầu tiên.

## 5. Quyết định kiến trúc đã chốt (Architecture Decisions Log)

Chi tiết đầy đủ tại PROJECT_BLUEPRINT.md §3.

**Vòng 1 — trên đặc tả gốc:**

| ID | Quyết định |
|---|---|
| AD-01 | Một bộ não duy nhất: `Kernel` (hợp nhất Planner + Executive Brain + Intelligent Execution) |
| AD-02 | ~~Một Context Engine duy nhất~~ → **superseded bởi AD-24** |
| AD-03 | Một `Skill Registry`; Capability = tag trên Skill, không có registry riêng |
| AD-04 | Prompt template nằm trong Skill definition; không có Prompt Registry |
| AD-05 | Validation = gates trong vòng đời Kernel; Confidence = 3 tier (High/Medium/Low), không dùng điểm số |
| AD-06 | `AI Gateway` = cửa duy nhất cho AI call (Model Router + Token Manager + Provider Layer) |
| AD-07 | Workflow = declarative skill composition, chạy bởi Execution Engine; không có Workflow Engine riêng |
| AD-08 | Executive State = view phái sinh, không persist riêng |
| AD-09 | Memory taxonomy chuẩn hóa → **tinh chỉnh bởi AD-22/AD-23**; Archive là flag |
| AD-10 | Deliverable = file trên đĩa (nguồn sự thật) + index phái sinh; không có Deliverable Registry |
| AD-11 | Chat thuộc Presentation, không thuộc Core |
| AD-12 | Một vòng đời chuẩn 5 pha: Intake → Decide → Execute → Verify → Persist |
| AD-13 | System Preamble tĩnh < 400 token, dùng prompt caching |
| AD-14 | 5 tài liệu này thay 18 file gốc làm context cho dev session |
| AD-15 | Mọi AI call phải được đo (token, cost, cache-hit, model) tại AI Gateway |
| AD-16 | Roadmap theo walking skeleton, không big-bang foundation |
| AD-17 | Chỉ 2 registry: Skill Registry + Module Manifest |
| AD-18 | Tool Layer chia on-device (Apple frameworks) và remote (MCP client, tùy chọn) |
| AD-19 | Module giao tiếp qua Event Bus + capability contract, không gọi đích danh module khác |
| AD-20 | Learning bị gate: chỉ từ kết quả đo được / user correction xác nhận; là policy ghi của Store |
| AD-21 | YouTube Module là reference implementation cho mọi module sau |

**Vòng 2 — Principal review trên v1.0 (Core 9 → 6):**

| ID | Quyết định |
|---|---|
| AD-22 | **Một `Store` duy nhất** (hợp nhất State Store + Memory Store — sửa lỗi dual-source-of-truth): 3 loại bản ghi ProjectState / Knowledge / WorkingContext; search là năng lực của Store; "Memory" người dùng = view trên Store |
| AD-23 | Vision = artifact tĩnh trong `Config/` (chính là System Preamble), không phải memory tier |
| AD-24 | Context Engine hợp nhất vào AI Gateway (retrieve → assemble → budget → cache → route → đo); đường AI call: `Kernel → AI Gateway → Provider` |
| AD-25 | Kernel là nơi duy nhất được quyền chọn; Execution thi hành máy móc theo policy khai báo trong Skill contract; vượt policy → quay về Kernel |
| AD-26 | Event Bus hạ xuống Infrastructure (pub/sub mỏng), không phải Core component |
| AD-27 | Bỏ Networking layer; consumer dùng URLSession trực tiếp |
| AD-28 | Skill schema tối thiểu: 6 trường bắt buộc (`id, version, capabilityTags, purpose, inputs, outputs`), còn lại optional — thêm khi có bằng chứng |
| AD-29 | Context tiering cho tài liệu: chỉ PROJECT_STATE.md luôn nạp; các file khác nạp theo tình huống |

**Triển khai:**

| ID | Quyết định |
|---|---|
| AD-30 | Core + Infrastructure = SwiftPM targets (dependency direction do compiler cưỡng chế; build/test mọi nền tảng); App shell qua `project.yml` (XcodeGen) trên macOS |

## 6. Vấn đề đã biết & Nợ kỹ thuật (Known Issues / Tech Debt)

| Mức | Mô tả | Kế hoạch |
|---|---|---|
| Minor | `InMemorySecretsVault` là placeholder không mã hóa, không persist | Thay bằng Keychain impl ở app layer tại M0-3; cấm dùng cho key thật |
| Minor | `InMemoryStore` không bền vững; Store search là substring match ngây thơ | File-backed Store ở M0-2; relevance ranking ở M1 |
| Minor | Build iOS app (`project.yml`) chưa được kiểm chứng vì môi trường không có macOS/Xcode; Swift files trong App/ + Presentation/ chưa qua compiler | Xác minh `xcodegen generate` + build lần đầu trên Mac; giữ App shell tối giản đến lúc đó |
| Minor | Chưa chọn provider AI đầu tiên cho M0-3 | Quyết định ở M0-3; yêu cầu: adapter thuần URLSession, đúng contract AIProvider |
| Ghi chú | Chưa có số liệu token baseline | Bắt đầu đo từ AI call thật đầu tiên (AD-15) |

## 7. Rủi ro đang theo dõi

- **Scope creep module:** chỉ bắt đầu module mới sau khi YouTube module đạt chuẩn reference (AD-21).
- **iOS background limits:** Execution Engine phải resume được sau khi app bị suspend (tiêu chí M1).
- **Provider lock-in:** mọi tính năng chỉ được dùng provider qua AI Gateway; vi phạm = fail code review.
- **Tái tạo component đã loại bỏ:** danh sách cấm tại SYSTEM_COMPONENTS.md §6; các merge đã bác (sàn kiến trúc) tại §7 — không lặp lại phân tích.

## 8. Quy tắc cập nhật file này

- Cập nhật sau **mỗi** phiên phát triển (nguyên tắc Session Continuity).
- Chỉ ghi thông tin có giá trị tương lai; xóa mục đã hết hạn.
- Không ghi lại nội dung hội thoại; chỉ ghi trạng thái, quyết định, việc còn lại.
