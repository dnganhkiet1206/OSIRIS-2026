# PROJECT_BLUEPRINT.md — Bản Thiết Kế Tổng Thể OSIRIS

> **Phiên bản:** 1.0 · **Ngày:** 2026-07-02 · **Trạng thái:** Đã duyệt kiến trúc (Architecture Review hoàn tất)
>
> Tài liệu này là kết quả rà soát toàn bộ 18 phần đặc tả gốc (OSIRIS 1–18), hợp nhất và tối ưu kiến trúc **nhưng giữ nguyên triết lý dự án**. Khi có mâu thuẫn giữa tài liệu này và 18 file gốc, **tài liệu này thắng** — vì nó là bản đã loại bỏ trùng lặp và mâu thuẫn.

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

Đây là danh sách các điểm trùng lặp, mâu thuẫn và nguy cơ technical debt được phát hiện trong 18 phần gốc, cùng quyết định xử lý. Mỗi mục là một **Architecture Decision** đã chốt.

### 3.1. Trùng lặp thành phần (Component Duplication)

| # | Vấn đề trong đặc tả gốc | Nguy cơ | Quyết định hợp nhất |
|---|---|---|---|
| AD-01 | **Planner** (P4) + **Executive Brain** (P18) + **Intelligent Execution System** (P5) + **Intelligence Engine** (P17) đều làm cùng một việc: hiểu goal, quyết định chiến lược, duyệt việc dùng AI | 4 bộ não song song → logic quyết định phân mảnh, không biết ai quyết định cuối cùng | Hợp nhất thành **một thành phần duy nhất: `Kernel` (Executive Brain)**. Planner là một pha bên trong Kernel, không phải component riêng |
| AD-02 | **Context Loader** (P4) + **Context Engine** (P7) + **Context Builder** (P17) — ba tên cho cùng một trách nhiệm | Ba implementation trùng nhau, drift theo thời gian | Một component duy nhất: **`Context Engine`** |
| AD-03 | **Capability Registry** (P6) và **Skill Registry** (P8) có schema gần trùng khớp (Purpose, Inputs, Outputs, Preferred Tools/Workflow/Models, Execution Cost…) | Hai registry song song cho cùng khái niệm → mọi capability phải khai báo 2 lần, Planner không biết tra registry nào | **Một registry duy nhất: `Skill Registry`.** *Capability là tag/interface* gắn trên Skill (Skill = implementation, Capability = hợp đồng). Planner tra theo capability tag, Execution Engine chọn Skill cụ thể |
| AD-04 | **Prompt Registry** (P17) tách riêng khỏi Skill | Prompt và Skill version lệch nhau; thêm một hệ CRUD + versioning + UI phải bảo trì | Prompt template là **thuộc tính bên trong Skill definition**, version cùng Skill. Không có Prompt Registry riêng |
| AD-05 | **Validator** (P4) + **Validation Engine** (P11) + toàn bộ P10 + **Confidence System** (P5) + **Confidence Engine** (P18) | Validation vừa là component, vừa là engine, vừa là pipeline riêng — không rõ ranh giới | Validation là **các gate cố định bên trong vòng đời Kernel** (mục 5), không phải component độc lập. Confidence là 3 mức (High/Medium/Low) — *tier, không phải điểm số* — vì LLM tự chấm điểm số không đáng tin |
| AD-06 | **Model Router** + **Token Manager** + **AI Provider Layer** là 3 component rời, nhưng P13 bắt buộc mọi call đi qua chuỗi cả 3 | 3 component luôn đi cùng nhau = 1 component bị cắt làm 3; tăng boilerplate | Hợp nhất thành **`AI Gateway`**: một cửa duy nhất cho mọi AI call (routing + budget + provider adapter + prompt cache) |
| AD-07 | **Workflow Engine** (P4) vs **Workflow Runtime** (P6, P11) — hai tên; đồng thời mâu thuẫn roadmap: Milestone 1 cần Workflow Runtime nhưng Milestone 6 mới xây Workflow Engine | Xây hai lần hoặc bế tắc thứ tự | **Workflow không phải engine riêng.** Workflow = *bản khai báo chuỗi Skill* (declarative composition), do Execution Engine chạy. M1 có composition nhẹ; M6 chỉ thêm scheduling/automation |
| AD-08 | **Executive State** (P18) tách khỏi **Project State** (P4) và yêu cầu "luôn đồng bộ" | Hai nguồn sự thật phải sync = nguồn bug kinh điển | Executive State là **view phái sinh trong bộ nhớ (ephemeral)** tính từ Project State. Không persist riêng, không cần sync |
| AD-09 | Memory taxonomy mâu thuẫn: P4 có 5 loại (Permanent/Project/Working/Temporary/Archive), P7 có 4 tầng (Vision/Knowledge/Project Memory/Working Context) | Hai mô hình chồng lấn → schema lưu trữ không nhất quán | **Chuẩn hóa 4 tầng của P7** (Vision / Knowledge / Project Memory / Working Context). Mapping: Permanent→Vision+Knowledge; Project→Project Memory; Working+Temporary→Working Context (tự hết hạn); **Archive là thuộc tính (flag)**, không phải tầng |
| AD-10 | **Deliverable Registry** (P15, M3) | Thêm một registry thứ N | Deliverable là **bản ghi trong Project State + file trong Files**, có index để search. Không có registry riêng |
| AD-11 | **Chat Engine** nằm trong danh sách Core components (P11) | Chat là UI, đặt vào Core vi phạm chính nguyên tắc "không trộn tầng" của P11 | Chat thuộc **Presentation layer**, không phải Core |

### 3.2. Trùng lặp quy trình (Pipeline Duplication)

Đặc tả gốc định nghĩa **ít nhất 5 pipeline vòng đời** khác nhau cho cùng một request (P4 Runtime Lifecycle, P5 Decision Pipeline, P8 Executive Loop, P10 Validation Pipeline, P18 Decision Pipeline) với số bước và thứ tự khác nhau.

**Nguy cơ:** mỗi module/AI session implement theo một pipeline khác nhau → hành vi không nhất quán, không test được.

**Quyết định (AD-12):** Chỉ tồn tại **một vòng đời chuẩn 5 pha** (mục 5). Mọi pipeline trong tài liệu gốc là góc nhìn khác nhau của cùng vòng đời này.

### 3.3. Nguy cơ tốn token

| # | Vấn đề | Quyết định |
|---|---|---|
| AD-13 | P7 yêu cầu "Always load Vision" + P17 yêu cầu "Execution Constraints consistent across platform" trong mọi prompt → mỗi request cõng một khối boilerplate lặp lại | Vision + constraints gộp thành **một System Preamble tĩnh, ngắn (mục tiêu < 400 token), bất biến** → tận dụng **prompt caching** của provider. Mọi thứ khác đều retrieve theo nhu cầu |
| AD-14 | 18 file đặc tả lặp ý nhau ~40% — nếu nạp cho AI dev session sẽ đốt token vô ích | Bộ 5 tài liệu này (BLUEPRINT / STATE / PLAN / FOLDER / COMPONENTS) **thay thế 18 file gốc làm nguồn context cho phát triển**. File gốc giữ làm tham chiếu lịch sử, không nạp vào context |
| AD-15 | Không có cơ chế đo | Mọi AI call qua AI Gateway đều ghi: token in/out, cost, cache-hit, model. Không đo được thì không tối ưu được |

### 3.4. Nguy cơ technical debt & khó mở rộng

| # | Vấn đề | Quyết định |
|---|---|---|
| AD-16 | **Big-bang foundation:** Milestone 0+1 gốc xây ~16 core component trước khi có bất kỳ giá trị người dùng nào — vi phạm chính nguyên tắc "smallest solution", và không có gì kiểm chứng kiến trúc sớm | Roadmap sửa thành **walking skeleton**: M0 là lát cắt dọc mỏng chạy end-to-end (Chat → Kernel tối giản → AI Gateway → kết quả + persist State), rồi dày dần từng lớp. Xem DEVELOPMENT_PLAN.md |
| AD-17 | **Registry proliferation:** 6 registry (Capability, Skill, Prompt, Workflow, Deliverable, Module) — mỗi cái cần CRUD, versioning, UI, migration | Còn **2**: Skill Registry (chứa skill + capability tag + prompt + workflow definition) và Module Manifest. |
| AD-18 | **MCP/Tool trên iOS không thực tế** như đặc tả ngầm định: FFmpeg, browser automation, MCP server chạy trên iPhone bị giới hạn background, battery, sandbox | Tool Layer chia 2 hạng rõ ràng: **on-device tools** (filesystem, media qua AVFoundation/Vision/Speech framework của Apple, calendar, network) và **remote tools** (MCP client gọi server bên ngoài — tùy chọn, thêm sau, không phải điều kiện của Core). Kiến trúc Core không đổi khi thêm remote |
| AD-19 | "Cross-module communication through the Core" (P6) dễ biến Core thành god-object message hub | Module giao tiếp qua **Event Bus + capability contract** (module A yêu cầu capability, không yêu cầu module B đích danh). Core chỉ định tuyến, không chứa logic nghiệp vụ trung gian |
| AD-20 | **Experience Engine / self-improvement** (P8) không có ranh giới → nguy cơ memory phình vô hạn và "học" từ suy đoán | Learning bị gate chặt: chỉ ghi nhận từ (a) execution thành công có đo lường, (b) user correction đã xác nhận, (c) architecture decision đã duyệt. Mọi bản ghi learning có TTL review. Không phải component riêng ở giai đoạn đầu — là **policy của Memory Store** |
| AD-21 | Danh sách module tương lai rất rộng (Trading, Crypto, CRM…) nhưng không có chuẩn nào ràng buộc | **YouTube Module (M4) là reference implementation** — mọi module sau copy đúng cấu trúc, không sáng tạo cấu trúc mới |

---

## 4. Kiến trúc tối ưu — Tổng quan

### 4.1. Phân tầng

```
┌────────────────────────────────────────────────────┐
│  PRESENTATION  (SwiftUI: Chat, Sidebar, Projects,  │
│                 Dashboard, Settings, Advanced Mode)│
├────────────────────────────────────────────────────┤
│  MODULES       (YouTube, TikTok, Shopify, …)       │
│                 UI riêng + Skills + Templates      │
├────────────────────────────────────────────────────┤
│  CORE                                              │
│   Kernel ─ Execution Engine ─ Skill Registry       │
│   State Store ─ Memory Store ─ Context Engine      │
│   AI Gateway ─ Tool Layer ─ Event Bus              │
├────────────────────────────────────────────────────┤
│  INFRASTRUCTURE (Storage, Config, Logging, Network)│
├────────────────────────────────────────────────────┤
│  EXTERNAL      (AI Providers, MCP Servers, APIs)   │
└────────────────────────────────────────────────────┘
```

Quy tắc phụ thuộc: **chỉ hướng xuống**. Presentation → Modules/Core; Modules → Core; Core → Infrastructure. Không có phụ thuộc ngược, không có phụ thuộc ngang giữa các Module.

### 4.2. Core sau hợp nhất: 9 thành phần (từ ~16–20 tên gọi trong đặc tả gốc)

| Thành phần | Hợp nhất từ (đặc tả gốc) | Trách nhiệm một câu |
|---|---|---|
| **Kernel** (Executive Brain) | Planner + Executive Brain + Intelligent Execution + Validation gates + Confidence | Quyết định *cái gì* được làm, *bằng cách nào*, và *có cần AI không* |
| **Execution Engine** | Execution Engine + Workflow Engine/Runtime | Thực thi task/skill/workflow-composition; retry, parallel, progress events |
| **Skill Registry** | Skill Registry + Capability Registry + Prompt Registry | Danh mục duy nhất các đơn vị năng lực (skill), tag theo capability, chứa prompt template |
| **State Store** | Project State Manager + Executive State | Nguồn sự thật duy nhất về dự án; Executive State là view phái sinh |
| **Memory Store** | Memory Manager + Knowledge Engine + Experience Engine (policy) | 4 tầng: Vision / Knowledge / Project Memory / Working Context |
| **Context Engine** | Context Loader + Context Engine + Context Builder | Lắp ráp context nhỏ nhất đủ dùng, theo budget ưu tiên 4 mức |
| **AI Gateway** | Model Router + Token Manager + AI Provider Layer | Cửa duy nhất cho mọi AI call: route model, quản budget, cache, đo lường |
| **Tool Layer** | Tool Layer (MCP) | Tool on-device + MCP client cho remote tools |
| **Event Bus** | Event System + Runtime Events + Progress Events | Giao tiếp lỏng giữa các thành phần; nguồn của Execution Status trên UI |

(Config Manager, Logging, Storage, Security thuộc tầng **Infrastructure** — xem SYSTEM_COMPONENTS.md.)

## 5. Vòng đời chuẩn duy nhất (Canonical Lifecycle) — AD-12

Mọi request đi qua đúng **5 pha**, do Kernel điều phối. Đây là hợp nhất của toàn bộ 5 pipeline trong đặc tả gốc:

```
1. INTAKE     Nhận goal → hiểu mục tiêu thật → xác định deliverable
              [Gate: goal rõ chưa? thiếu thông tin → hỏi tối thiểu, không đoán]

2. DECIDE     Ước lượng độ phức tạp → tra tài nguyên có sẵn (cache, memory,
              deliverable cũ, file) → chọn capability cần → chọn chiến lược:
              Direct / Tool / Workflow / AI / Hybrid → duyệt ngân sách
              [Gate: có cách rẻ hơn AI không? Confidence Low → hỏi lại]
              [Gate: rủi ro (xóa, publish, chi phí lớn) → cần user approval]

3. EXECUTE    Execution Engine chạy skill/tool/workflow; task độc lập chạy
              song song; retry + fallback khi lỗi; phát progress event
              [Gate: mọi AI call bắt buộc qua Context Engine → AI Gateway]

4. VERIFY     Kiểm deliverable: đủ – đúng – dùng được – có next action
              [Gate: fail → tự sửa trước khi trả; không trả kết quả hỏng]

5. PERSIST    Cập nhật Project State, Progress, Memory (chỉ khi đáng lưu),
              log chi phí; reflection ngắn để cải thiện lần sau
```

Đường đi bắt buộc của một AI call: `Kernel → Context Engine → AI Gateway → Provider`. Không có đường tắt.

## 6. Các hợp đồng kiến trúc (Architecture Contracts)

1. **Skill contract:** mỗi Skill khai báo: `id, version, capabilityTags[], purpose, inputs, outputs, preferredTools, preferredModelTier, promptTemplate?, workflowSteps?, cost, fallback`. Skill nhỏ, một mục đích, test độc lập được.
2. **Module contract:** mỗi Module có Manifest (`id, version, capabilities cung cấp, dependencies, trạng thái: installed/enabled/disabled/archived`). Module disabled tiêu thụ ~0 tài nguyên; archived không nạp vào runtime.
3. **Context budget:** 4 mức ưu tiên Critical > Important > Helpful > Optional; cắt từ Optional trước; System Preamble tĩnh < 400 token, được cache.
4. **Memory contract:** chỉ ghi khi trả lời CÓ cho ít nhất một: dùng lại sau? ảnh hưởng kiến trúc? giảm token tương lai? Working Context tự hết hạn.
5. **Approval contract:** bắt buộc hỏi người dùng trước khi: publish, delete, overwrite, chi tiêu lớn, đổi cài đặt vĩnh viễn, đổi hành vi Core.
6. **UI contract:** không bao giờ lộ chain-of-thought; chỉ hiển thị execution events ("Đang phân tích…", "Đang tạo…"); lỗi hiển thị dạng: chuyện gì xảy ra – đã thử gì – gợi ý tiếp theo.

## 7. Những gì cố tình KHÔNG xây (Non-Goals)

- Visual workflow builder — trái triết lý "complexity inside the engine".
- Multi-user / multi-tenant — OSIRIS là hệ điều hành cá nhân.
- Registry riêng cho Prompt / Deliverable / Capability — đã hợp nhất (AD-03, AD-04, AD-10).
- Fine-tuning model riêng — thông minh đến từ kiến trúc quyết định, không từ model to hơn.
- Chạy MCP server / FFmpeg trực tiếp trên iPhone — dùng Apple framework on-device + remote tool khi cần (AD-18).

## 8. Tài liệu liên quan

| Tài liệu | Nội dung |
|---|---|
| `PROJECT_STATE.md` | Trạng thái hiện tại, quyết định đã chốt, việc kế tiếp |
| `DEVELOPMENT_PLAN.md` | Roadmap milestone đã sửa (walking skeleton) |
| `FOLDER_STRUCTURE.md` | Cấu trúc thư mục chuẩn |
| `SYSTEM_COMPONENTS.md` | Danh mục chi tiết Core & Module |
