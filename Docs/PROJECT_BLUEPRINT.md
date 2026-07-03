# PROJECT_BLUEPRINT.md — Bản Thiết Kế Tổng Thể OSIRIS

> **Phiên bản:** 1.1 · **Ngày:** 2026-07-02 · **Trạng thái:** Đã duyệt kiến trúc (2 vòng review)
>
> Tài liệu này là kết quả rà soát toàn bộ 18 phần đặc tả gốc (OSIRIS 1–18), hợp nhất và tối ưu kiến trúc **nhưng giữ nguyên triết lý dự án**. Phiên bản 1.1 bổ sung vòng review thứ hai (Principal review, §3.5) — giảm Core từ 9 xuống **6 thành phần** và loại bỏ nốt một lỗi dual-source-of-truth. Khi có mâu thuẫn giữa tài liệu này và 18 file gốc, **tài liệu này thắng**.

---

## 1. Định nghĩa sản phẩm

**OSIRIS** (Operating System for Intelligent Revenue, Intelligence, Research & Integrated Strategy) là một **AI Executive Operating System** cho **một người dùng duy nhất**, chạy native trên **iPhone (SwiftUI)**.

OSIRIS **không phải** chatbot, không phải workflow builder, không phải dashboard. Hội thoại chỉ là giao diện. **Execution (thực thi công việc) mới là sản phẩm.**

Trải nghiệm lý tưởng:

```
Người dùng nhập mục tiêu → Chờ → Nhận deliverable dùng được ngay
```

## 2. Triết lý bất biến (kế thừa nguyên vẹn từ Constitution — Part 14)

Các nguyên tắc sau **không được vi phạm** bởi bất kỳ quyết định kiến trúc nào:

1. **Goal First** — tối ưu cho việc hoàn thành mục tiêu, không phải trả lời.
2. **Simplicity First** — luôn chọn kiến trúc đơn giản nhất cho cùng kết quả.
3. **AI Is The Last Tool** — thứ tự ưu tiên: Dữ liệu có sẵn → Cache → Logic ứng dụng → Tool/MCP → Workflow → AI Model.
4. **Token Efficiency** — token là ngân sách; mỗi token thừa là một lỗi thiết kế.
5. **Context On Demand** — chỉ nạp đúng ngữ cảnh cần cho task hiện tại.
6. **State Over Chat** — Project State là nguồn sự thật duy nhất, không phải lịch sử chat.
7. **Validate Everything** — kiểm chứng trước/sau mỗi bước đắt đỏ.
8. **Reuse Before Create** — tìm kiếm trước khi tạo mới bất cứ thứ gì.
9. **Human Control** — người dùng sở hữu chiến lược; OSIRIS sở hữu thực thi.
10. **Protect the Core** — Core nhỏ, ổn định; mọi tăng trưởng qua Modules.

**Ba quy tắc vàng:** Giảm độ phức tạp · Giảm mức dùng AI · Tăng chất lượng thực thi.

**Năm câu hỏi** trước mọi feature: (1) Có thật sự cần? (2) Có cách đơn giản hơn? (3) Tái dùng được component nào? (4) Có tăng chất lượng/năng suất/giá trị? (5) Có thêm phức tạp/token/chi phí bảo trì không? — Nếu (5) là CÓ: dừng, thiết kế lại.

---

## 3. Kết quả Architecture Review — Các vấn đề của đặc tả gốc

Đây là danh sách các điểm trùng lặp, mâu thuẫn và nguy cơ technical debt được phát hiện trong 18 phần gốc, cùng quyết định xử lý. Mỗi mục là một **Architecture Decision** đã chốt. §3.1–3.4 là vòng review thứ nhất (trên đặc tả gốc); §3.5 là vòng review thứ hai (trên chính bản hợp nhất v1.0).

### 3.1. Trùng lặp thành phần (Component Duplication)

| # | Vấn đề trong đặc tả gốc | Nguy cơ | Quyết định hợp nhất |
|---|---|---|---|
| AD-01 | **Planner** (P4) + **Executive Brain** (P18) + **Intelligent Execution System** (P5) + **Intelligence Engine** (P17) đều làm cùng một việc: hiểu goal, quyết định chiến lược, duyệt việc dùng AI | 4 bộ não song song → logic quyết định phân mảnh, không biết ai quyết định cuối cùng | Hợp nhất thành **một thành phần duy nhất: `Kernel` (Executive Brain)**. Planner là một pha bên trong Kernel, không phải component riêng |
| AD-02 | **Context Loader** (P4) + **Context Engine** (P7) + **Context Builder** (P17) — ba tên cho cùng một trách nhiệm | Ba implementation trùng nhau, drift theo thời gian | Một component duy nhất: `Context Engine` — **⚠ superseded bởi AD-24:** trách nhiệm này nay nằm trong AI Gateway (assembly) + Store (retrieval) |
| AD-03 | **Capability Registry** (P6) và **Skill Registry** (P8) có schema gần trùng khớp (Purpose, Inputs, Outputs, Preferred Tools/Workflow/Models, Execution Cost…) | Hai registry song song cho cùng khái niệm → mọi capability phải khai báo 2 lần, Planner không biết tra registry nào | **Một registry duy nhất: `Skill Registry`.** *Capability là tag/interface* gắn trên Skill (Skill = implementation, Capability = hợp đồng). Kernel tra theo capability tag, Execution Engine chọn Skill cụ thể |
| AD-04 | **Prompt Registry** (P17) tách riêng khỏi Skill | Prompt và Skill version lệch nhau; thêm một hệ CRUD + versioning + UI phải bảo trì | Prompt template là **thuộc tính bên trong Skill definition**, version cùng Skill. Không có Prompt Registry riêng |
| AD-05 | **Validator** (P4) + **Validation Engine** (P11) + toàn bộ P10 + **Confidence System** (P5) + **Confidence Engine** (P18) | Validation vừa là component, vừa là engine, vừa là pipeline riêng — không rõ ranh giới | Validation là **các gate cố định bên trong vòng đời Kernel** (mục 5), không phải component độc lập. Confidence là 3 mức (High/Medium/Low) — *tier, không phải điểm số* — vì LLM tự chấm điểm số không đáng tin |
| AD-06 | **Model Router** + **Token Manager** + **AI Provider Layer** là 3 component rời, nhưng P13 bắt buộc mọi call đi qua chuỗi cả 3 | 3 component luôn đi cùng nhau = 1 component bị cắt làm 3; tăng boilerplate | Hợp nhất thành **`AI Gateway`**: một cửa duy nhất cho mọi AI call (routing + budget + provider adapter + prompt cache) |
| AD-07 | **Workflow Engine** (P4) vs **Workflow Runtime** (P6, P11) — hai tên; đồng thời mâu thuẫn roadmap: Milestone 1 cần Workflow Runtime nhưng Milestone 6 mới xây Workflow Engine | Xây hai lần hoặc bế tắc thứ tự | **Workflow không phải engine riêng.** Workflow = *bản khai báo chuỗi Skill* (declarative composition), do Execution Engine chạy. M1 có composition nhẹ; M6 chỉ thêm scheduling/automation |
| AD-08 | **Executive State** (P18) tách khỏi **Project State** (P4) và yêu cầu "luôn đồng bộ" | Hai nguồn sự thật phải sync = nguồn bug kinh điển | Executive State là **view phái sinh trong bộ nhớ (ephemeral)** tính từ Project State. Không persist riêng, không cần sync |
| AD-09 | Memory taxonomy mâu thuẫn: P4 có 5 loại (Permanent/Project/Working/Temporary/Archive), P7 có 4 tầng (Vision/Knowledge/Project Memory/Working Context) | Hai mô hình chồng lấn → schema lưu trữ không nhất quán | Chuẩn hóa theo 4 tầng của P7 — **⚠ tinh chỉnh bởi AD-22/AD-23:** Vision tách ra thành artifact tĩnh; 3 loại còn lại là record type trong Store duy nhất. **Archive là thuộc tính (flag)**, không phải tầng |
| AD-10 | **Deliverable Registry** (P15, M3) | Thêm một registry thứ N | Deliverable là **file trên đĩa** (nguồn sự thật) + index phái sinh trong ProjectState, có search. Không có registry riêng |
| AD-11 | **Chat Engine** nằm trong danh sách Core components (P11) | Chat là UI, đặt vào Core vi phạm chính nguyên tắc "không trộn tầng" của P11 | Chat thuộc **Presentation layer**, không phải Core |

### 3.2. Trùng lặp quy trình (Pipeline Duplication)

Đặc tả gốc định nghĩa **ít nhất 5 pipeline vòng đời** khác nhau cho cùng một request (P4 Runtime Lifecycle, P5 Decision Pipeline, P8 Executive Loop, P10 Validation Pipeline, P18 Decision Pipeline) với số bước và thứ tự khác nhau.

**Nguy cơ:** mỗi module/AI session implement theo một pipeline khác nhau → hành vi không nhất quán, không test được.

**Quyết định (AD-12):** Chỉ tồn tại **một vòng đời chuẩn 5 pha** (mục 5). Mọi pipeline trong tài liệu gốc là góc nhìn khác nhau của cùng vòng đời này.

### 3.3. Nguy cơ tốn token

| # | Vấn đề | Quyết định |
|---|---|---|
| AD-13 | P7 yêu cầu "Always load Vision" + P17 yêu cầu "Execution Constraints consistent across platform" trong mọi prompt → mỗi request cõng một khối boilerplate lặp lại | Vision + constraints gộp thành **một System Preamble tĩnh, ngắn (mục tiêu < 400 token), bất biến** → tận dụng **prompt caching** của provider. Mọi thứ khác đều retrieve theo nhu cầu |
| AD-14 | 18 file đặc tả lặp ý nhau ~40% — nếu nạp cho AI dev session sẽ đốt token vô ích | Bộ 5 tài liệu này (BLUEPRINT / STATE / PLAN / FOLDER / COMPONENTS) **thay thế 18 file gốc làm nguồn context cho phát triển**. File gốc giữ làm tham chiếu lịch sử, không nạp vào context. Cách nạp 5 file: xem AD-29 |
| AD-15 | Không có cơ chế đo | Mọi AI call qua AI Gateway đều ghi: token in/out, cost, cache-hit, model. Không đo được thì không tối ưu được |

### 3.4. Nguy cơ technical debt & khó mở rộng

| # | Vấn đề | Quyết định |
|---|---|---|
| AD-16 | **Big-bang foundation:** Milestone 0+1 gốc xây ~16 core component trước khi có bất kỳ giá trị người dùng nào — vi phạm chính nguyên tắc "smallest solution", và không có gì kiểm chứng kiến trúc sớm | Roadmap sửa thành **walking skeleton**: M0 là lát cắt dọc mỏng chạy end-to-end (Chat → Kernel tối giản → AI Gateway → kết quả + persist State), rồi dày dần từng lớp. Xem DEVELOPMENT_PLAN.md |
| AD-17 | **Registry proliferation:** 6 registry (Capability, Skill, Prompt, Workflow, Deliverable, Module) — mỗi cái cần CRUD, versioning, UI, migration | Còn **2**: Skill Registry (chứa skill + capability tag + prompt + workflow definition) và Module Manifest |
| AD-18 | **MCP/Tool trên iOS không thực tế** như đặc tả ngầm định: FFmpeg, browser automation, MCP server chạy trên iPhone bị giới hạn background, battery, sandbox | Tool Layer chia 2 hạng rõ ràng: **on-device tools** (filesystem, media qua AVFoundation/Vision/Speech framework của Apple, calendar, network) và **remote tools** (MCP client gọi server bên ngoài — tùy chọn, thêm sau, không phải điều kiện của Core). Kiến trúc Core không đổi khi thêm remote |
| AD-19 | "Cross-module communication through the Core" (P6) dễ biến Core thành god-object message hub | Module giao tiếp qua **Event Bus + capability contract** (module A yêu cầu capability, không yêu cầu module B đích danh). Event Bus chỉ định tuyến, không chứa logic nghiệp vụ trung gian |
| AD-20 | **Experience Engine / self-improvement** (P8) không có ranh giới → nguy cơ memory phình vô hạn và "học" từ suy đoán | Learning bị gate chặt: chỉ ghi nhận từ (a) execution thành công có đo lường, (b) user correction đã xác nhận, (c) architecture decision đã duyệt. Mọi bản ghi learning có TTL review. Không phải component riêng — là **policy ghi của Store** |
| AD-21 | Danh sách module tương lai rất rộng (Trading, Crypto, CRM…) nhưng không có chuẩn nào ràng buộc | **YouTube Module (M4) là reference implementation** — mọi module sau copy đúng cấu trúc, không sáng tạo cấu trúc mới |

### 3.5. Vòng review thứ hai (Principal review trên v1.0) — Core 9 → 6

Vòng này áp lại chính bộ tiêu chí trên vào bản hợp nhất v1.0 và phát hiện các vấn đề còn sót:

| # | Vấn đề trong v1.0 | Nguy cơ | Quyết định |
|---|---|---|---|
| AD-22 | **State Store và Memory Store là hai nguồn sự thật cho cùng loại dữ liệu:** Architecture Decisions, Progress, Known Issues xuất hiện ở cả hai (đúng lỗi AD-08 tái xuất hiện ở tầng dưới) | Hai bản ghi drift sau thời gian; "quyết định X nằm ở đâu?" có hai câu trả lời | Hợp nhất thành **một `Store` duy nhất** với 3 loại bản ghi có chủ sở hữu rõ: `ProjectState` (goal, tasks, decisions, issues, deliverable index) · `Knowledge` (cách hệ thống hoạt động, searchable) · `WorkingContext` (scratch, TTL tự hết hạn). "Memory" với người dùng là **khái niệm sản phẩm** — view trên Store, không phải component riêng. **Search/retrieval là năng lực của Store** |
| AD-23 | Vision được xếp làm một tầng memory dù "gần như bất biến, rất nhỏ, luôn nằm trong preamble" | Trả chi phí read-path/schema runtime cho một hằng số | **Vision là artifact tĩnh trong `Config/`** — chính là System Preamble (AD-13). Không phải dữ liệu runtime, không phải memory tier |
| AD-24 | **Context Engine vi phạm chính AD-06:** không bao giờ được gọi mà không có AI Gateway ngay sau, và ngược lại — hai component luôn đi cùng nhau | Một ranh giới phải định nghĩa, tài liệu hóa, giữ đồng bộ suốt 10 năm mà không mang lại giá trị tách biệt | **Hợp nhất Context Engine vào AI Gateway.** Gateway nhận `(task, references)` và tự lo chuỗi: retrieve (qua Store) → assemble → budget 4 mức → compress → cache → route → đo. "Một cửa cho AI" nay đúng nghĩa đen là một component |
| AD-25 | Execution Engine v1.0 được phép "fallback sang model khác/chiến lược khác" — tức chứa **quyết định**, việc của Kernel | Hai nơi chứa decision logic sẽ mâu thuẫn theo thời gian | Siết hợp đồng: **Kernel là nơi duy nhất được quyền chọn; Execution là nơi duy nhất được quyền làm.** Retry/fallback là *policy khai báo trong Skill contract*, Execution thi hành máy móc; tình huống vượt policy phải quay về Kernel |
| AD-26 | Event Bus xếp ngang hàng Kernel/Gateway trong Core | Thổi phồng cognitive load; nó là pub/sub mỏng trong app đơn tiến trình | **Hạ Event Bus xuống Infrastructure** (cạnh Logging). Chức năng giữ nguyên 100% |
| AD-27 | Infrastructure/Networking là wrapper trên URLSession — abstraction thừa cho app không có backend riêng | Thêm một lớp phải bảo trì không mang giá trị | **Bỏ Networking như component riêng.** Consumer cần network (provider adapter của Gateway, remote tools) dùng URLSession trực tiếp |
| AD-28 | Skill schema v1.0 có ~12 trường bắt buộc trước khi tồn tại skill đầu tiên (YAGNI) | Schema sai ở M1 đắt hơn schema thiếu, với chân trời 10 năm | **Schema tối thiểu 5 trường bắt buộc:** `id, version, capabilityTags, purpose, inputs/outputs`. Mọi trường khác (preferredTools, modelTier, cost, fallback, promptTemplate, compositionSteps…) là **optional** — thêm khi có bằng chứng cần |
| AD-29 | AD-14 thay 18 file bằng 5 file nhưng chưa quy định file nào nạp khi nào — nạp cả 5 mỗi dev session là tái phạm lỗi cũ | Token phí trong chính vòng lặp phát triển | **Context tiering cho tài liệu:** chỉ `PROJECT_STATE.md` luôn trong context; BLUEPRINT/COMPONENTS nạp khi chạm kiến trúc; PLAN nạp khi chuyển milestone; FOLDER_STRUCTURE nạp khi tạo file mới |

### 3.6. Quyết định trong quá trình triển khai

| # | Bối cảnh | Quyết định |
|---|---|---|
| AD-30 | Core/Infrastructure là pure Swift không phụ thuộc UI; cần cưỡng chế dependency direction và build/test được ngoài Xcode | **Core + Infrastructure là SwiftPM targets** (`Package.swift` tại repo root; Core phụ thuộc Infrastructure — compiler cưỡng chế, không thể import ngược). App shell (App/ + Presentation/, SwiftUI) build qua Xcode project sinh từ `project.yml` (XcodeGen) trên macOS, link package này. Core build/test được trên mọi nền tảng: `swift build && swift test` |
| AD-31 | AI Gateway là Core nhưng AI Provider là Integration; tích hợp sớm sẽ để chi tiết provider ảnh hưởng thiết kế Core | **Core hoàn thiện và ổn định trước khi kết nối provider thật.** PlaceholderAIProvider (offline, deterministic, 0 chi phí) là provider duy nhất đến khi Core M0 hoàn tất. Gateway phải hoạt động đầy đủ (validate → budget → cache → dry-run/retry → metrics → log) không phụ thuộc bất kỳ provider thật nào. Adapter thật (Anthropic/OpenAI/…) chỉ là một struct conform `AIProvider` thêm vào sau — không đổi Gateway |
| AD-32 | Deliverable là file (AD-10) nhưng nếu Kernel hoặc Execution tự ghi file thì có ≥ 2 nơi persist — vi phạm "một persister duy nhất" | **Chỉ Store được chạm LocalStorage.** Store persist mọi bản ghi VÀ deliverable file (`saveDeliverable`); Execution trả kết quả in-memory; Kernel orchestrate persistence chỉ qua Store. Phân công: *Kernel quyết định — Execution thi hành — Store là nơi duy nhất chạm đĩa* |
| AD-33 | Kernel (bộ quyết định thuần túy) đang import OsirisInfrastructure vì phụ thuộc trực tiếp EventBus — phát hiện qua Architecture Review M0-4 | **Kernel chỉ phụ thuộc protocol của Core.** Progress events phát qua closure `@Sendable (ExecutionEvent) async -> Void` inject từ composition root (không tạo protocol mới — một function type là đủ). `import OsirisInfrastructure` bị cấm trong `Core/Kernel/**`, cưỡng chế bằng Architecture Test |
| AD-34 | Quy tắc kiến trúc chỉ nằm trong tài liệu sẽ suy thoái theo thời gian (architecture drift) | **Architecture Test Suite** (`Tests/ArchitectureTests`) chạy trong `swift test`: quét source cưỡng chế — chỉ Gateway chạm provider; chỉ Store chạm LocalStorage; Kernel thuần túy; chỉ Kernel tạo ExecutionPlan; đúng 1 implementation cho Store/AIGateway (single source of truth); import matrix theo tầng; cấm khai báo lại component đã loại bỏ. Compiler cưỡng chế đồ thị target; test cưỡng chế quy tắc trong target. Mỗi AD mới có quy tắc kiểm được → thêm rule |
| AD-35 | UI cần dùng platform nhưng Presentation import Core trực tiếp sẽ rò rỉ khái niệm nội bộ (provider, retry, reuse, strategy) vào UI; đồng thời logic dịch sự kiện/lỗi đặt trong App/ (Xcode-only) thì không test được trên Linux | **Application Layer** (`Application/`, SPM target `OsirisApplication`, chỉ phụ thuộc OsirisCore): cầu nối DUY NHẤT giữa UI và Core — nhận goal, gọi Kernel, dịch `ExecutionEvent`/error thành `TaskUpdate` (activity / needsClarification / completed / failed) theo UI contract; không chứa business logic. **Presentation chỉ được import OsirisApplication** — UI không phân biệt kết quả đến từ reuse hay AI. Không đổi tên `ExecutionEvent` (Core-internal); tính tổng quát cho UI đạt bằng tầng dịch, không bằng rename. Cưỡng chế bằng 2 arch rule mới |
| AD-36 | Hai cách mô tả cùng một khái niệm composition tồn tại song song: struct `SkillComposition` (M0-1) và field `SkillDefinition.compositionSteps` (AD-28) — nguồn sự thật đôi, phát hiện khi triển khai M1-3 | **Một khái niệm một cách biểu diễn: composition = `SkillDefinition` có `compositionSteps`** (≤5 bước, precondition cưỡng chế); struct `SkillComposition` bị xóa. Lợi ích kép: matching M1-1 hoạt động cho composition miễn phí (triggerKeywords = hợp keywords các bước con → goal nhiều keyword tự nhiên chọn composition, một keyword tie-break về skill đơn). Kernel resolve step IDs thành definitions ngay trong Decide — Execution chạy tuần tự máy móc, không bao giờ chạm registry (AD-25). **Hoãn có lập luận (duyệt bởi user):** Parallel (chưa có nguồn sinh task độc lập) và Resume-sau-suspend (cần thiết kế checkpoint riêng qua Store) — xét lại tại M1 review |
| AD-38 | M2-1 cần list/create project từ UI, nhưng Kernel là decision engine (không phải query service) và cho ChatService ôm Store sẽ xói mòn AD-35 | **Quản lý project là state management, không phải goal execution** — đi qua closure-port `ProjectDirectory` (Application: types + closures, không cạnh import mới — cùng pattern ProviderSettings) do composition root nối xuống Store (persister duy nhất). Ghi *kết quả execution* vẫn chỉ qua vòng đời Kernel. `ProjectState.name` mới có decode-fallback về id — file cũ migrate im lặng |
| AD-37 | Tool Layer v1 (M1-4): tool cần matching + Kernel cần biết tools + tool results có nên persist? | **Tool matching data-driven** qua `triggerKeywords` ngay trên protocol `Tool` (không ToolDescriptor, không Tool Matcher riêng); **một thuật toán matching duy nhất** dùng chung skill + tool (`selectByKeywords` trong Kernel). **Tools inject qua Kernel init** — không Tool Registry (AD-17: Skill Registry là registry duy nhất, đến khi có bằng chứng). **`.tool` case mang `any Tool` đã resolve** — Execution không bao giờ chọn/đổi tool. **Tool results KHÔNG persist:** persistence tồn tại để tránh tốn lại token, tool re-run miễn phí, còn kết quả cũ ("ngày hôm qua") là câu trả lời sai nằm chờ trong reuse path. Tool fail không tự rơi sang AI — Kernel đã quyết định tool thì lỗi phải lộ ra. Metrics tối thiểu: `tool.run` log (name/duration/outcome). Cưỡng chế bằng arch rule mới: Core/Tools không biết AI/Skill/Store/Kernel |

---

## 4. Kiến trúc tối ưu — Tổng quan

### 4.1. Phân tầng

```
┌────────────────────────────────────────────────────┐
│  PRESENTATION  (SwiftUI: Chat, Sidebar, Projects,  │
│                 Dashboard, Settings, Advanced Mode)│
├────────────────────────────────────────────────────┤
│  APPLICATION   (ChatService — cầu nối duy nhất     │
│                 UI ↔ Core; dịch event/error, AD-35)│
├────────────────────────────────────────────────────┤
│  MODULES       (YouTube, TikTok, Shopify, …)       │
│                 UI riêng + Skills + Templates      │
├────────────────────────────────────────────────────┤
│  CORE (6)                                          │
│   Kernel ─ Execution Engine ─ Skill Registry       │
│   Store ─ AI Gateway ─ Tool Layer                  │
├────────────────────────────────────────────────────┤
│  INFRASTRUCTURE (Storage, Config, Logging,         │
│                  Security, Event Bus)              │
├────────────────────────────────────────────────────┤
│  EXTERNAL      (AI Providers, MCP Servers, APIs)   │
└────────────────────────────────────────────────────┘
```

Quy tắc phụ thuộc: **chỉ hướng xuống**. Presentation → Modules/Core; Modules → Core; Core → Infrastructure. Không có phụ thuộc ngược, không có phụ thuộc ngang giữa các Module.

### 4.2. Core sau hai vòng hợp nhất: 6 thành phần (từ ~16–20 tên gọi trong đặc tả gốc)

| Thành phần | Hợp nhất từ | Trách nhiệm một câu |
|---|---|---|
| **Kernel** (Executive Brain) | Planner + Executive Brain + Intelligent Execution + Validation gates + Confidence | Nơi **duy nhất** quyết định: *cái gì* được làm, *bằng cách nào*, *có cần AI không* |
| **Execution Engine** | Execution Engine + Workflow Engine/Runtime | Nơi **duy nhất** thi hành: task/skill/composition theo policy khai báo; retry, parallel, resume, progress events |
| **Skill Registry** | Skill Registry + Capability Registry + Prompt Registry | Điểm mở rộng duy nhất: danh mục skill, tag theo capability, chứa prompt template |
| **Store** | Project State Manager + Memory Manager + Knowledge Engine + Executive State | Nguồn sự thật duy nhất: `ProjectState` / `Knowledge` / `WorkingContext` + search/retrieval |
| **AI Gateway** | Model Router + Token Manager + AI Provider Layer + Context Loader/Engine/Builder | Cửa duy nhất cho AI: retrieve → assemble → budget → cache → route → đo |
| **Tool Layer** | Tool Layer (MCP) | Adapter thế giới thực: tool on-device + MCP client cho remote tools |

Kiểm tra chéo bằng **tốc độ thay đổi** (SRP theo volatility): sáu thành phần không có cặp nào chia sẻ cùng lý do thay đổi — UI đổi hằng tuần, module hằng tháng, policy Kernel hằng quý, Gateway khi thị trường provider đổi, Store schema hiếm nhất. Đây là lý do **6 là sàn**: giảm nữa sẽ ép hai tốc độ thay đổi sống chung một component.

(Config, Logging, Storage, Security, Event Bus thuộc tầng **Infrastructure** — xem SYSTEM_COMPONENTS.md.)

### 4.3. Một loại dữ liệu — một chủ sở hữu (Single Source of Truth Map)

| Dữ liệu | Chủ sở hữu duy nhất | Mọi thứ khác là |
|---|---|---|
| Vision / System Preamble | `Config/` (tĩnh) | — |
| Goal, tasks, decisions, issues, progress | `Store.ProjectState` | view phái sinh |
| Deliverables | File trên đĩa | index trong ProjectState là derived |
| Knowledge (cách hệ thống hoạt động) | `Store.Knowledge` | — |
| Working context | `Store.WorkingContext` (TTL) | — |
| Skill / prompt / composition định nghĩa | `Skill Registry` | — |
| Token/cost metrics | Log của AI Gateway | Dashboard là view |
| Executive State | *(không tồn tại — derived từ ProjectState)* | |

## 5. Vòng đời chuẩn duy nhất (Canonical Lifecycle) — AD-12

Mọi request đi qua đúng **5 pha**, do Kernel điều phối:

```
1. INTAKE     Nhận goal → hiểu mục tiêu thật → xác định deliverable
              [Gate: goal rõ chưa? thiếu thông tin → hỏi tối thiểu, không đoán]

2. DECIDE     Ước lượng độ phức tạp → tra tài nguyên có sẵn (Store.search:
              cache, deliverable cũ, knowledge, file) → chọn capability cần
              → chọn chiến lược: Direct / Tool / Workflow / AI / Hybrid
              → duyệt ngân sách
              [Gate: có cách rẻ hơn AI không? Confidence Low → hỏi lại]
              [Gate: rủi ro (xóa, publish, chi phí lớn) → cần user approval]

3. EXECUTE    Execution Engine chạy skill/tool/composition theo policy khai báo;
              task độc lập chạy song song; vượt policy → quay về Kernel (AD-25);
              phát progress event
              [Gate: mọi AI call bắt buộc qua AI Gateway]

4. VERIFY     Kiểm deliverable: đủ – đúng – dùng được – có next action
              [Gate: fail → tự sửa trước khi trả; không trả kết quả hỏng]

5. PERSIST    Cập nhật Store (ProjectState; Knowledge/learning chỉ khi qua gate
              AD-20), log chi phí; reflection ngắn để cải thiện lần sau
```

Đường đi bắt buộc của một AI call: `Kernel → AI Gateway → Provider` (Gateway tự retrieve context qua Store). Không có đường tắt.

## 6. Các hợp đồng kiến trúc (Architecture Contracts)

1. **Skill contract (AD-28):** bắt buộc: `id, version, capabilityTags[], purpose, inputs, outputs`. Optional (thêm khi có bằng chứng cần): `preferredTools, preferredModelTier, promptTemplate, compositionSteps, cost, fallbackPolicy`. Skill nhỏ, một mục đích, test độc lập được.
2. **Module contract:** mỗi Module có Manifest (`id, version, capabilities cung cấp, dependencies, trạng thái: installed/enabled/disabled/archived`). Module disabled tiêu thụ ~0 tài nguyên; archived không nạp vào runtime.
3. **Decision/Execution contract (AD-25):** Kernel là nơi duy nhất được quyền chọn; Execution là nơi duy nhất được quyền làm. Retry/fallback là policy khai báo; escalation quay về Kernel.
4. **Context budget (trong AI Gateway):** 4 mức ưu tiên Critical > Important > Helpful > Optional; cắt từ Optional trước; System Preamble tĩnh < 400 token, được cache.
5. **Store contract:** chỉ ghi khi trả lời CÓ cho ít nhất một: dùng lại sau? ảnh hưởng kiến trúc? giảm token tương lai? WorkingContext tự hết hạn. Learning qua gate AD-20.
6. **Approval contract:** bắt buộc hỏi người dùng trước khi: publish, delete, overwrite, chi tiêu lớn, đổi cài đặt vĩnh viễn, đổi hành vi Core.
7. **UI contract:** không bao giờ lộ chain-of-thought; chỉ hiển thị execution events ("Đang phân tích…", "Đang tạo…"); lỗi hiển thị dạng: chuyện gì xảy ra – đã thử gì – gợi ý tiếp theo.

## 7. Những gì cố tình KHÔNG xây (Non-Goals)

- Visual workflow builder — trái triết lý "complexity inside the engine".
- Multi-user / multi-tenant — OSIRIS là hệ điều hành cá nhân.
- Registry riêng cho Prompt / Deliverable / Capability — đã hợp nhất (AD-03, AD-04, AD-10).
- Component riêng cho Context / Memory / State / Networking — đã hợp nhất hoặc loại bỏ (AD-22, AD-24, AD-27).
- Fine-tuning model riêng — thông minh đến từ kiến trúc quyết định, không từ model to hơn.
- Chạy MCP server / FFmpeg trực tiếp trên iPhone — dùng Apple framework on-device + remote tool khi cần (AD-18).

### 7.1. Các hợp nhất đã cân nhắc và bác bỏ (sàn của kiến trúc)

Để tránh vòng "tối ưu hóa" tương lai lặp lại phân tích này, ghi rõ các merge đã xét và **từ chối**:

| Merge bị bác | Lý do |
|---|---|
| Kernel + Execution Engine | Ranh giới *pure vs effectful*: decision logic test được không cần side effect; gộp tạo god object (P16 cấm) |
| Skill Registry → Kernel | Registry là điểm mở rộng duy nhất; gộp nghĩa là mỗi module mới đụng vào bộ não — chết "Protect the Core" |
| AI Gateway → Kernel | Provider độc lập là điều kiện sống còn 10 năm; ranh giới này cô lập thứ biến động nhất khỏi thứ ổn định nhất |
| Tool Layer → Skill Registry | Skill là ý định/composition, Tool là adapter side-effect; gộp làm mờ nguyên tắc "Tools trước AI" |

## 8. Tài liệu liên quan & quy tắc nạp context (AD-29)

| Tài liệu | Nội dung | Khi nào nạp vào AI dev session |
|---|---|---|
| `PROJECT_STATE.md` | Trạng thái, quyết định, việc kế tiếp | **Luôn luôn** (file được thiết kế ngắn) |
| `PROJECT_BLUEPRINT.md` | Thiết kế tổng thể, AD log chi tiết | Khi chạm quyết định kiến trúc |
| `SYSTEM_COMPONENTS.md` | Danh mục Core & Module | Khi chạm quyết định kiến trúc / thêm component |
| `DEVELOPMENT_PLAN.md` | Roadmap milestone | Khi chuyển milestone / lập kế hoạch |
| `FOLDER_STRUCTURE.md` | Cấu trúc thư mục | Khi tạo file/thư mục mới |
