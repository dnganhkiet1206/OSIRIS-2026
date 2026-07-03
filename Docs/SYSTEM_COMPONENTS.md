# SYSTEM_COMPONENTS.md — Danh Mục Core & Module OSIRIS

> **Phiên bản:** 1.1 · **Ngày:** 2026-07-02
> Danh mục chính thức mọi thành phần hệ thống sau **hai vòng** hợp nhất kiến trúc (PROJECT_BLUEPRINT.md §3, đặc biệt §3.5: Core 9 → 6). **Chỉ những thành phần trong file này được phép tồn tại.** Muốn thêm thành phần Core mới phải qua Architecture Review và trả lời được Năm Câu Hỏi của Constitution.

---

## 1. Sơ đồ quan hệ

```
                    ┌──────────────┐
   User ──────────► │ Presentation │  (Chat là giao diện chính)
                    └──────┬───────┘
                           ▼
                    ┌──────────────┐          ┌─────────────────────┐
                    │    KERNEL    │ ◄──────► │        STORE        │
                    │ 5-phase loop │          │ ProjectState        │
                    │ (mọi quyết   │          │ Knowledge           │
                    │  định ở đây) │          │ WorkingContext      │
                    └──────┬───────┘          │ + search/retrieval  │
                           │                  └──────────▲──────────┘
                           ▼                             │ retrieve
                 ┌───────────────────┐                   │
                 │ Execution Engine  │──► Tool Layer     │
                 │ (thi hành theo    │   (on-device/MCP) │
                 │  policy khai báo) │                   │
                 └─────────┬─────────┘                   │
                           │ (khi Kernel duyệt AI)       │
                           ▼                             │
                    ┌──────────────┐─────────────────────┘
                    │  AI GATEWAY  │ assemble → budget → cache
                    │              │ → route → đo → Provider
                    └──────────────┘

   Skill Registry: Kernel tra capability tag → Execution chọn skill
   Event Bus (Infrastructure): progress events → Presentation
```

**Đường AI call bắt buộc:** `Kernel → AI Gateway → Provider`. Gateway tự retrieve context qua Store. Không có đường tắt (AD-06, AD-24).

**Quy tắc một câu (AD-25):** *Kernel là nơi duy nhất được quyền chọn; Execution Engine là nơi duy nhất được quyền làm.*

---

## 2. CORE — 6 thành phần

*Core không bao giờ chứa business logic. Business logic sống trong Modules.*

### 2.1. Kernel (Executive Brain)
- **Hợp nhất từ:** Planner (P4) + Executive Brain (P18) + Intelligent Execution (P5) + Validation/Confidence (P5/P10/P18). *(AD-01, AD-05, AD-12)*
- **Trách nhiệm:** Điều phối vòng đời chuẩn 5 pha (Intake → Decide → Execute → Verify → Persist); hiểu mục tiêu thật và xác định deliverable; chọn chiến lược theo thứ tự tài nguyên (data → cache → logic → tool → workflow → AI); duyệt mọi AI usage; giữ Confidence tier (High: chạy / Medium: chạy + ghi giả định / Low: hỏi lại); thực thi approval gates cho hành động rủi ro (publish, delete, chi tiêu lớn); tiếp nhận escalation từ Execution Engine khi tình huống vượt policy khai báo (AD-25).
- **Không làm:** tự tạo deliverable; gọi provider trực tiếp; chứa logic nghiệp vụ; **mọi I/O** (AD-33: Kernel chỉ phụ thuộc protocol Core, không import Infrastructure; progress events qua closure inject từ composition root — cưỡng chế bằng Architecture Test AD-34).
- **Executive State:** view phái sinh trong bộ nhớ từ `Store.ProjectState` — không persist riêng (AD-08).

### 2.2. Execution Engine
- **Hợp nhất từ:** Execution Engine (P4) + Workflow Engine/Runtime (P4/P6/P11). *(AD-07, AD-25)*
- **Trách nhiệm:** Thi hành task/skill; task độc lập chạy song song, task phụ thuộc chạy tuần tự; retry/fallback **theo đúng policy khai báo trong Skill contract** — máy móc, không tự quyết; tình huống vượt policy quay về Kernel; chạy **composition** (chuỗi skill khai báo qua `SkillDefinition.compositionSteps`, ≤5 bước — AD-36; Kernel resolve steps trong Decide, Execution chạy tuần tự, output bước trước nối bước sau); phát progress events; resume sau khi iOS suspend app; không bao giờ để project ở trạng thái không nhất quán.
- **Không làm:** mọi hình thức quyết định chiến lược (chọn model khác, đổi hướng — việc của Kernel); chứa business logic trong composition.

### 2.3. Skill Registry
- **Hợp nhất từ:** Skill Registry (P8) + Capability Registry (P4/P6) + Prompt Registry (P17). *(AD-03, AD-04, AD-17)*
- **Trách nhiệm:** Điểm mở rộng duy nhất của platform — danh mục các đơn vị năng lực. **Capability = tag/hợp đồng**; Kernel hỏi "cần capability gì", registry trả về skill phù hợp. Prompt template sống bên trong skill, version cùng skill. Skill chỉnh được qua ứng dụng (không cần sửa source cho cấu hình đơn giản).
- **Skill schema (AD-28):**
  - Bắt buộc: `id, version, capabilityTags[], purpose, inputs, outputs`
  - Optional (thêm khi có bằng chứng cần): `preferredTools, preferredModelTier, promptTemplate, compositionSteps, cost, fallbackPolicy`
- **Chất lượng skill:** nhỏ, một mục đích, tái dùng, dự đoán được, test độc lập được. Không có "skill khổng lồ". Skill built-in trong Core chỉ được là skill **tổng quát** (Research, Summarize…) — skill nghiệp vụ thuộc Modules.

### 2.4. Store
- **Hợp nhất từ:** Project State Manager (P4) + Memory Manager (P4) + Knowledge Engine (P7/P11) + Executive State (P18) + Experience Engine (P8, dạng policy). *(AD-08, AD-09, AD-20, AD-22, AD-23)*
- **Trách nhiệm:** **Nguồn sự thật duy nhất** cho mọi dữ liệu bền vững của platform (State Over Chat). Ba loại bản ghi:
  | Loại bản ghi | Nội dung | Vòng đời |
  |---|---|---|
  | **ProjectState** | Goal, current task, progress, completed/next tasks, architecture decisions, known issues, deliverable index (derived từ file — AD-10) | Bền vững, có cấu trúc; project cô lập lẫn nhau |
  | **Knowledge** | Cách OSIRIS hoạt động: kiến trúc, chuẩn, quy tắc routing | Searchable; cập nhật một nơi, tham chiếu mọi nơi |
  | **WorkingContext** | File/feature/lỗi/nghiên cứu của task hiện tại | Tạm thời; **TTL tự hết hạn** |
- **Vision KHÔNG nằm ở đây** — nó là artifact tĩnh trong `Config/` (System Preamble, AD-23).
- **Persister duy nhất (AD-32):** chỉ Store được chạm LocalStorage — kể cả deliverable file (`saveDeliverable`); Execution trả kết quả in-memory, Kernel orchestrate qua Store. Cưỡng chế bằng Architecture Test (AD-34).
- **Search/retrieval là năng lực của Store** — phục vụ cả pha Decide (check reuse) lẫn AI Gateway (lấy context) và Global Search trên UI.
- **Policy ghi:** chỉ lưu khi có giá trị tương lai (dùng lại? ảnh hưởng kiến trúc? giảm token?). Store phải **nhỏ và thông minh dần**, không phình to. `Archive` là flag, không phải loại bản ghi.
- **Learning gate (AD-20):** chỉ học từ execution thành công có đo lường, user correction đã xác nhận, decision đã duyệt. Không lưu phỏng đoán.
- **Khái niệm "Memory" với người dùng:** là view sản phẩm trên Store (Memory Viewer trong Advanced Mode) — không phải component riêng.

### 2.5. AI Gateway
- **Hợp nhất từ:** Model Router (P4) + Token Manager (P11) + AI Provider Layer (P11) + Context Loader/Engine/Builder (P4/P7/P17). *(AD-06, AD-13, AD-15, AD-24)*
- **Trách nhiệm:** Cửa duy nhất cho mọi AI call — nhận `(task, references)` từ Kernel và tự lo toàn chuỗi:
  1. **Retrieve:** lấy context liên quan qua Store.search (không bao giờ dump toàn project).
  2. **Assemble:** System Preamble tĩnh (< 400 token, cached) → Knowledge liên quan → ProjectState liên quan → WorkingContext → User Request. Cô lập theo request — không module/hội thoại/memory không liên quan.
  3. **Budget:** 4 mức Critical > Important > Helpful > Optional — cắt Optional trước; nén/tóm tắt khi vượt.
  4. **Cache:** prompt cache (preamble) + response cache/reuse.
  5. **Route:** chọn model nhỏ nhất đủ chất lượng theo yêu cầu reasoning/creativity/speed/cost; không hardcode model; provider hoán đổi qua adapter.
  6. **Đo:** log token in/out, cost, latency, cache-hit, model cho mọi call — nguồn số liệu cho Dashboard, Token Analysis và Milestone 7.
- **Nguyên tắc:** "Hệ thống context thông minh hơn luôn tốt hơn cửa sổ context lớn hơn."

### 2.6. Tool Layer
- **Từ:** Tool Layer/MCP (P4/P11), làm rõ theo ràng buộc iOS. *(AD-18)*
- **Trách nhiệm:** Tool luôn được ưu tiên hơn AI khi làm được cùng việc. Hai hạng sau một interface chung:
  - **On-device:** filesystem, media (AVFoundation/Vision/Speech của Apple), calendar, email, search, network (URLSession trực tiếp — AD-27).
  - **Remote (MCP client):** browser automation, xử lý video nặng, database ngoài… — tùy chọn, thêm từ M6, không phải điều kiện của Core.
- Thêm tool mới = thêm adapter, không đổi Core.

---

## 3. INFRASTRUCTURE — 5 thành phần kỹ thuật nền

| Thành phần | Trách nhiệm |
|---|---|
| **Storage** | Local-first: đọc/ghi/cache local (nền vật lý cho Store); chỉ ra ngoài khi cần |
| **Logging** | Structured logs: debugging, cost analysis, execution review; nuôi Developer Mode; không ảnh hưởng UX |
| **Security** | Keychain cho API keys; bảo vệ user data, project files; không lộ dữ liệu nhạy cảm vào prompt (Prompt Security — P17) |
| **Configuration** | Nạp `Config/*.json` (preamble/vision, models, routing, budgets, policies, feature flags); hành vi đổi qua config, không qua code |
| **Event Bus** *(AD-26)* | Pub/sub mỏng: giao tiếp lỏng giữa thành phần và giữa Modules (module không gọi đích danh module khác — AD-19); nguồn của Execution Status trên UI: `Understanding… Planning… Generating… Completed.` — không bao giờ chở chain-of-thought |

*(Không có component Networking riêng — AD-27: consumer dùng URLSession trực tiếp.)*

## 4. APPLICATION & PRESENTATION

**Application Layer (AD-35)** — SPM target `OsirisApplication`, chỉ phụ thuộc OsirisCore:
- **ChatService**: cầu nối DUY NHẤT giữa UI và Core — nhận goal từ UI, gọi Kernel, dịch `ExecutionEvent`/error thành `TaskUpdate` (activity / needsClarification / completed / failed) theo UI contract. Không business logic, không quyết định. UI không bao giờ biết kết quả đến từ reuse hay AI, không biết provider/retry/strategy là gì.
- **Quy tắc import (cưỡng chế bằng arch test):** Presentation chỉ import `OsirisApplication`; Application chỉ import `OsirisCore`; ViewModel chỉ nói chuyện với Application, chỉ quản lý trạng thái giao diện.

**Presentation — các màn hình:**

| Màn hình | Vai trò | Ghi chú |
|---|---|---|
| **Chat** | Ứng dụng chính — mở app vào thẳng đây | Input: text, voice, ảnh, file, link |
| **Sidebar** | "Hệ điều hành": Chat, Projects, Settings (+Advanced khi bật) | Searchable, tối giản |
| **Projects** | Resume công việc tức thì | Goals, files, deliverables, history |
| **Dashboard** | Nhận thức vận hành — không phải trang thống kê | Goal, Task, Progress, Token Usage, Status |
| **Settings** | Tối giản: General, AI, Models, Memory, Token, Developer | |
| **Advanced Mode** | Ẩn mặc định | Memory/Knowledge Viewer (view trên Store), Log Viewer, Token Analysis, Model Routing, Skill config |
| **Execution Status** | Component hiển thị progress events (từ Event Bus) | Không lộ reasoning; không % giả |

## 5. MODULES — nghiệp vụ (plugin)

**Module contract (AD-21):** mỗi module tự chứa `Manifest / UI / Skills / Templates / Config / Docs / Tests`; đăng ký skill vào Skill Registry với capability tags; giao tiếp qua Event Bus + capability, không phụ thuộc module khác; 4 trạng thái: installed / enabled / disabled (≈0 tài nguyên) / archived (không nạp runtime); tái dùng 100% Core — module cần sửa Core là red flag kiến trúc.

| Module | Milestone | Capabilities chính (dạng tag) |
|---|---|---|
| **YouTube** ⭐ reference | M4 | research, channel-analysis, idea-generation, script-generation, seo, thumbnail-planning, shorts-planning, publishing-package |
| TikTok | M5 | content-planning, trend-research, publishing-package |
| Shopify | M5 | product-research, landing-page, store-analysis |
| Etsy | M5 | product-research, listing-optimization |
| Instagram / Facebook | M5 | content-planning, publishing-package |
| Research | M5 | deep-research, company-research, summarization |
| Documents | M5 | document-analysis, report-generation |
| Trading Research | M5+ | investment-research, market-analysis *(chỉ research — không tự giao dịch)* |
| Voice AI, Podcast, Amazon FBA, Course Creator, CRM, Personal Finance… | Tương lai | Chỉ bắt đầu khi có nhu cầu thực; copy đúng module contract |

## 6. Thành phần đã bị loại bỏ (không được tái tạo)

Các tên sau xuất hiện trong đặc tả gốc hoặc bản v1.0 nhưng **đã hợp nhất/loại bỏ** — tạo lại chúng như component riêng là vi phạm kiến trúc:

**Từ vòng review 1 (trên đặc tả gốc):** `Planner` (riêng) · `Executive Brain` (riêng) · `Intelligence Engine` · `Context Loader` · `Context Builder` · `Capability Registry` (riêng) · `Prompt Registry` · `Deliverable Registry` · `Workflow Engine` / `Workflow Runtime` (riêng) · `Model Router` (đỉnh) · `Token Manager` (đỉnh) · `Validation Engine` (riêng) · `Confidence Engine` (riêng) · `Experience Engine` (riêng) · `Executive State` (persist riêng) · `Chat Engine` (trong Core)

**Từ vòng review 2 (trên v1.0):** `Context Engine` (riêng — vào AI Gateway, AD-24) · `State Store` + `Memory Store` (riêng — hợp nhất thành Store, AD-22) · `Vision` như memory tier (→ Config artifact, AD-23) · `Event Bus` như Core component (→ Infrastructure, AD-26) · `Networking` layer (→ URLSession trực tiếp, AD-27)

**Từ triển khai M1:** struct `SkillComposition` (→ hợp nhất vào `SkillDefinition.compositionSteps`, AD-36 — một khái niệm một cách biểu diễn)

## 7. Các hợp nhất đã cân nhắc và bác bỏ (sàn kiến trúc — không tối ưu thêm)

| Merge bị bác | Lý do |
|---|---|
| Kernel + Execution Engine | Ranh giới pure (quyết định, test không cần side effect) vs effectful (thi hành, resume, parallel); gộp tạo god object |
| Skill Registry → Kernel | Registry là điểm mở rộng duy nhất cho 10 năm module growth; gộp = mỗi module mới đụng vào bộ não |
| AI Gateway → Kernel | Provider độc lập là điều kiện sống còn; cô lập thứ biến động nhất khỏi thứ ổn định nhất |
| Tool Layer → Skill Registry | Skill = ý định/composition; Tool = adapter side-effect; gộp làm mờ nguyên tắc "Tools trước AI" |

Lý do chi tiết từng quyết định: PROJECT_BLUEPRINT.md §3 và §7.1.
