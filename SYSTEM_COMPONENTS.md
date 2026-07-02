# SYSTEM_COMPONENTS.md — Danh Mục Core & Module OSIRIS

> **Phiên bản:** 1.0 · **Ngày:** 2026-07-02
> Danh mục chính thức mọi thành phần hệ thống sau hợp nhất kiến trúc (PROJECT_BLUEPRINT.md §3–4). **Chỉ những thành phần trong file này được phép tồn tại.** Muốn thêm thành phần Core mới phải qua Architecture Review và trả lời được Năm Câu Hỏi của Constitution.

---

## 1. Sơ đồ quan hệ

```
                    ┌──────────────┐
   User ──────────► │ Presentation │  (Chat là giao diện chính)
                    └──────┬───────┘
                           ▼
                    ┌──────────────┐         ┌───────────────┐
                    │    KERNEL    │ ◄─────► │  State Store  │ (nguồn sự thật)
                    │ 5-phase loop │         └───────────────┘
                    └──────┬───────┘         ┌───────────────┐
                           │        ◄─────►  │  Memory Store │ (4 tầng)
                           ▼                 └───────────────┘
                 ┌───────────────────┐
                 │ Execution Engine  │──► Tool Layer (on-device / MCP)
                 └─────────┬─────────┘
                           │ (khi cần AI)
                           ▼
              Context Engine ──► AI Gateway ──► Providers
                           
        Event Bus: xuyên suốt — progress events → Presentation
        Skill Registry: Kernel tra capability, Execution chọn skill
```

**Đường AI call bắt buộc:** `Kernel → Context Engine → AI Gateway → Provider`. Không có đường tắt (AD-06).

---

## 2. CORE — 9 thành phần

*Core không bao giờ chứa business logic. Business logic sống trong Modules.*

### 2.1. Kernel (Executive Brain)
- **Hợp nhất từ:** Planner (P4) + Executive Brain (P18) + Intelligent Execution (P5) + Validation/Confidence (P5/P10/P18). *(AD-01, AD-05, AD-12)*
- **Trách nhiệm:** Điều phối vòng đời chuẩn 5 pha (Intake → Decide → Execute → Verify → Persist); hiểu mục tiêu thật và xác định deliverable; chọn chiến lược theo thứ tự tài nguyên (data → cache → logic → tool → workflow → AI); duyệt mọi AI usage; giữ Confidence tier (High: chạy / Medium: chạy + ghi giả định / Low: hỏi lại); thực thi approval gates cho hành động rủi ro (publish, delete, chi tiêu lớn).
- **Không làm:** tự tạo deliverable; gọi provider trực tiếp; chứa logic nghiệp vụ.
- **Executive State:** view phái sinh trong bộ nhớ từ Project State — không persist riêng (AD-08).

### 2.2. Execution Engine
- **Hợp nhất từ:** Execution Engine (P4) + Workflow Engine/Runtime (P4/P6/P11). *(AD-07)*
- **Trách nhiệm:** Chạy task/skill; task độc lập chạy song song, task phụ thuộc chạy tuần tự; retry thông minh + fallback (tool khác → workflow khác → model khác); chạy **Skill Composition** (workflow dạng khai báo, < 5 bước logic); phát progress events; resume sau khi iOS suspend app; không bao giờ để project ở trạng thái không nhất quán.
- **Không làm:** quyết định chiến lược (việc của Kernel); chứa business logic trong composition.

### 2.3. Skill Registry
- **Hợp nhất từ:** Skill Registry (P8) + Capability Registry (P4/P6) + Prompt Registry (P17). *(AD-03, AD-04, AD-17)*
- **Trách nhiệm:** Danh mục duy nhất các đơn vị năng lực. Mỗi **Skill** khai báo: `id, version, capabilityTags[], purpose, inputs, outputs, preferredTools, preferredModelTier, promptTemplate?, compositionSteps?, cost, fallback, ownerModule`. **Capability = tag/hợp đồng**; Kernel hỏi "cần capability gì", registry trả về skill phù hợp. Prompt template sống bên trong skill, version cùng skill. Skill chỉnh được qua ứng dụng (không cần sửa source cho cấu hình đơn giản).
- **Chất lượng skill:** nhỏ, một mục đích, tái dùng, dự đoán được, test độc lập được. Không có "skill khổng lồ".

### 2.4. State Store
- **Hợp nhất từ:** Project State Manager (P4) + Executive State (P18). *(AD-08)*
- **Trách nhiệm:** Nguồn sự thật duy nhất (State Over Chat). Lưu theo từng project: Vision link, Current Goal, Current Task, Progress, Completed/Next Tasks, Architecture Decisions, Known Issues, Deliverable index (AD-10), Status. Project cô lập lẫn nhau (memory, files, progress, logs riêng). Persist bền vững, khôi phục nguyên trạng khi mở lại app.

### 2.5. Memory Store
- **Hợp nhất từ:** Memory Manager (P4) + Knowledge Engine (P7/P11) + Experience Engine (P8, dạng policy). *(AD-09, AD-20)*
- **Trách nhiệm:** Bốn tầng chuẩn:
  | Tầng | Nội dung | Vòng đời |
  |---|---|---|
  | **Vision** | Mission, nguyên tắc bất biến | Gần như không đổi; rất nhỏ; nằm trong System Preamble |
  | **Knowledge** | Cách OSIRIS hoạt động: kiến trúc, chuẩn, quy tắc routing | Searchable; chỉ truy hồi phần liên quan; cập nhật một nơi, tham chiếu mọi nơi |
  | **Project Memory** | Tiến độ, quyết định, vấn đề, ghi chú theo project | Tự động duy trì; nén/tóm tắt định kỳ |
  | **Working Context** | File/feature/lỗi/nghiên cứu hiện tại | Tạm thời; **tự hết hạn** |
- **Policy ghi:** chỉ lưu khi có giá trị tương lai (dùng lại? ảnh hưởng kiến trúc? giảm token?). Memory phải **nhỏ và thông minh dần**, không phình to. `Archive` là flag, không phải tầng.
- **Learning gate (AD-20):** chỉ học từ execution thành công có đo lường, user correction đã xác nhận, decision đã duyệt. Không lưu phỏng đoán.

### 2.6. Context Engine
- **Hợp nhất từ:** Context Loader (P4) + Context Engine (P7) + Context Builder (P17). *(AD-02, AD-13)*
- **Trách nhiệm:** Lắp ráp context nhỏ nhất đủ cho chất lượng cao. Thứ tự lắp: System Preamble (tĩnh, < 400 token, cached) → Knowledge liên quan → Project Memory liên quan → Working Context → User Request. **Context budget** 4 mức: Critical > Important > Helpful > Optional — cắt Optional trước. Nén/tóm tắt khi vượt budget. Cô lập theo request: không bao giờ đưa module/hội thoại cũ/memory không liên quan.
- **Nguyên tắc:** "Hệ thống context thông minh hơn luôn tốt hơn cửa sổ context lớn hơn."

### 2.7. AI Gateway
- **Hợp nhất từ:** Model Router (P4) + Token Manager (P11) + AI Provider Layer (P11). *(AD-06, AD-15)*
- **Trách nhiệm:** Cửa duy nhất cho mọi AI call. **Routing:** chọn model nhỏ nhất đủ chất lượng theo yêu cầu reasoning/creativity/speed/cost; không hardcode model; provider hoán đổi được qua adapter. **Budgeting:** áp token budget mỗi request; từ chối call vượt ngân sách chưa duyệt. **Caching:** prompt cache (preamble tĩnh) + response cache/reuse. **Đo lường:** log token in/out, cost, latency, cache-hit, model cho mọi call — nguồn số liệu cho Dashboard, Token Analysis và Milestone 7.

### 2.8. Tool Layer
- **Từ:** Tool Layer/MCP (P4/P11), làm rõ theo ràng buộc iOS. *(AD-18)*
- **Trách nhiệm:** Tool luôn được ưu tiên hơn AI khi làm được cùng việc. Hai hạng sau một interface chung:
  - **On-device:** filesystem, network, media (AVFoundation/Vision/Speech của Apple), calendar, email, search.
  - **Remote (MCP client):** browser automation, xử lý video nặng, database ngoài… — tùy chọn, thêm từ M6, không phải điều kiện của Core.
- Thêm tool mới = thêm adapter, không đổi Core.

### 2.9. Event Bus
- **Hợp nhất từ:** Event System (P11) + Runtime/Progress Events (P4). *(AD-19)*
- **Trách nhiệm:** Giao tiếp lỏng giữa các thành phần và giữa Modules (module không gọi đích danh module khác). Nguồn của Execution Status trên UI: `Understanding… Planning… Searching… Generating… Updating memory… Completed.` — không bao giờ chở chain-of-thought.

---

## 3. INFRASTRUCTURE — 5 thành phần kỹ thuật nền

| Thành phần | Trách nhiệm |
|---|---|
| **Storage** | Local-first: đọc/ghi/cache local; chỉ ra ngoài khi cần |
| **Networking** | HTTP client, reachability, retry hạ tầng |
| **Logging** | Structured logs: debugging, cost analysis, execution review; nuôi Developer Mode; không ảnh hưởng UX |
| **Security** | Keychain cho API keys; bảo vệ user data, project files, memory; không lộ dữ liệu nhạy cảm vào prompt (Prompt Security — P17) |
| **Configuration** | Nạp `Config/*.json` (models, routing, budgets, policies, feature flags); hành vi đổi qua config, không qua code |

## 4. PRESENTATION — các màn hình

| Màn hình | Vai trò | Ghi chú |
|---|---|---|
| **Chat** | Ứng dụng chính — mở app vào thẳng đây | Input: text, voice, ảnh, file, link |
| **Sidebar** | "Hệ điều hành": Chat, Projects, Settings (+Advanced khi bật) | Searchable, tối giản |
| **Projects** | Resume công việc tức thì | Goals, files, deliverables, history |
| **Dashboard** | Nhận thức vận hành — không phải trang thống kê | Goal, Task, Progress, Token Usage, Status |
| **Settings** | Tối giản: General, AI, Models, Memory, Token, Developer | |
| **Advanced Mode** | Ẩn mặc định | Memory/Knowledge/Log Viewer, Token Analysis, Model Routing, Skill config |
| **Execution Status** | Component hiển thị progress events | Không lộ reasoning; không % giả |

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

Các tên sau xuất hiện trong đặc tả gốc nhưng **đã hợp nhất** — tạo lại chúng như component riêng là vi phạm kiến trúc:

`Planner` (riêng) · `Executive Brain` (riêng) · `Intelligence Engine` · `Context Loader` · `Context Builder` · `Capability Registry` (riêng) · `Prompt Registry` · `Deliverable Registry` · `Workflow Engine` / `Workflow Runtime` (riêng) · `Model Router` (đỉnh) · `Token Manager` (đỉnh) · `Validation Engine` (riêng) · `Confidence Engine` (riêng) · `Experience Engine` (riêng) · `Executive State` (persist riêng) · `Chat Engine` (trong Core)

Lý do từng mục: PROJECT_BLUEPRINT.md §3.
