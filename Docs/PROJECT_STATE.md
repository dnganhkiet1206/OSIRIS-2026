# PROJECT_STATE.md — Trạng Thái Dự Án OSIRIS

> **Cập nhật lần cuối:** 2026-07-02
> Đây là **nguồn sự thật duy nhất** về trạng thái dự án (nguyên tắc *State Over Chat*). Mọi phiên phát triển bắt đầu bằng việc đọc file này và kết thúc bằng việc cập nhật file này. Đây là **file duy nhất luôn được nạp** vào AI dev session (AD-29) — giữ file ngắn gọn, dạng cấu trúc.

---

## 1. Tổng quan nhanh

| Hạng mục | Giá trị |
|---|---|
| Giai đoạn | **M1 — Core Runtime, đang triển khai** (M0 nghiệm thu: tag `M0` local tại `dc54059`; push tag khi merge) |
| Task hiện tại | **M3 — Intelligence Layer, đang triển khai** · M3-1 (Reflection & Write Gate v1) ✅ hoàn thành — **AD-20 PROVEN** · kế tiếp: M3-2 (xem `NEXT_TASK.md`) · **[USER] runbook M1-0 vẫn chờ — nợ High** |
| Nền tảng | iOS (iPhone), SwiftUI · Core/Application = SwiftPM build được mọi nền tảng (AD-30/35) |
| Trạng thái kiến trúc | ✅ v1.1 — Core **6 thành phần** + Application Layer (AD-35) · **14 Architecture Test chống drift** · resource order Decide ĐẦY ĐỦ: reuse → tool → skill/composition → AI |
| Trạng thái codebase | ✅ **0 error / 0 warning (debug + release), 66/66 test pass** (Swift 6.0.3, Linux) · toàn bộ test offline |

## 2. Mục tiêu hiện tại (Current Goal)

M1 — Core Runtime: Kernel đầy đủ, hệ điều hành AI thực sự vận hành (DEVELOPMENT_PLAN §2/M1). Trước mắt: user chạy `Docs/RUNBOOK_M1-0.md` (Mac build + key + baseline thật); song song có thể tiến M1-1.

## 3. Việc đã hoàn thành (Completed)

- [x] Viết 18 phần đặc tả gốc (OSIRIS 1–18 .docx).
- [x] **Review vòng 1** (trên đặc tả gốc): 21 quyết định AD-01 → AD-21; ~16–20 tên component → 9 Core; 5 pipeline → 1 vòng đời chuẩn 5 pha; 6 registry → 2.
- [x] **Review vòng 2** (Principal review trên v1.0): 8 quyết định AD-22 → AD-29; Core 9 → **6**; sửa lỗi dual-source-of-truth (State Store vs Memory Store); hợp nhất Context Engine vào AI Gateway; Vision → Config artifact.
- [x] Ban hành bộ 5 tài liệu nền tảng v1.1: BLUEPRINT, STATE, PLAN, FOLDER_STRUCTURE, SYSTEM_COMPONENTS.
- [x] **M0-1 — Project Bootstrap** (AD-30): SwiftPM package (OsirisCore 6 thành phần + OsirisInfrastructure 5 thành phần), App shell SwiftUI + `project.yml` (XcodeGen), Config ngoài source (preamble + 5 json), tài liệu vào `Docs/`, kiểm chứng build + test trên Linux. Kernel skeleton chạy đủ 5 pha với placeholder provider (không tốn chi phí AI).
- [x] **M0-2 — Store v0 bền vững + Config wiring**: `FileBackedStore` (JSON qua LocalStorage; layout `project-state|knowledge|working-context/<id>.json`; ID percent-encode chống path traversal); test "restart" chứng minh ProjectState sống sót qua app restart; `LocalStorage` thêm `keys(withPrefix:)` (điều kiện bắt buộc cho Store.search — công khai trong Self Review); CompositionRoot đọc preamble/routing từ Config, fail-fast khi thiếu; **xóa InMemoryStore** (thừa sau khi có FileBackedStore — một implementation Store duy nhất).
- [x] **M0-3 — AI Gateway hoàn thiện như thành phần độc lập** (AD-31, phạm vi do user điều chỉnh: KHÔNG provider thật): pipeline validate → budget → cache → (dry-run | retry khai báo) → metrics → log; `AIRequestMetrics` đầy đủ (AD-15); `GatewayConfiguration` throwing init = config validation fail-fast (kèm cưỡng chế preamble ≤ 400 token — AD-13 bằng máy); `ResponseCache` protocol + in-memory impl; Dry Run mode; retry tái dùng `RetryPolicy` duy nhất; 9 test Gateway offline.
- [x] **M0-4A — Kernel Decide thuần túy + Architecture Tests** (AD-32/33/34; M0-4 được chia A/B sau Architecture Review): 10 Architecture Test quét source (import matrix, Kernel purity, một persister, một cổng AI, chỉ Kernel tạo ExecutionPlan, 1 impl Store/Gateway, cấm component đã loại bỏ, module isolation) — **bắt được ngay vi phạm thật**: Kernel import Infrastructure → sửa bằng closure inject (AD-33); pha Decide thật: Confidence v0 (goal rỗng → hỏi lại, không đoán), reuse-before-AI qua Store.search (strategy `.reuse` mang content để Execution máy móc), hết reuse → `.ai` (Gateway lần đầu được gọi từ vòng đời thật).
- [x] **M0-4B — Execution & Deliverable Persistence** (AD-10/32): `Store.saveDeliverable` + `deliverableContent` — chỉ Store chạm đĩa; deliverable = file .md có goal trong front matter (để search khớp goal lặp lại — không cần record phụ); Kernel Persist cập nhật `deliverablePaths` index, KHÔNG ghi lại file khi reuse (tránh duplicate); search deliverable đi qua index (AD-10), dừng sớm khi đủ limit; **vòng Reuse khép kín — goal lặp lại = 0 AI call (có test chứng minh)**; reuse lấy nội dung đầy đủ (trả nợ M0-4A); `preferredTier` truyền xuyên suốt; +1 arch rule mới (Presentation không import Infrastructure).

- [x] **M0-5 — Chat UI v0 & Application Layer** (AD-35): SPM target `OsirisApplication` — `ChatService` là cầu nối duy nhất UI ↔ Core, dịch `ExecutionEvent`/error → `TaskUpdate` với thông điệp thân thiện theo UI contract (test chứng minh không rò tên error nội bộ); `ChatViewModel` (@MainActor @Observable) chỉ quản lý state UI; ChatView kiểu ChatGPT (sidebar + transcript + composer + status line); giữ nguyên tên `ExecutionEvent` (tính tổng quát đạt bằng tầng dịch, không rename); +2 arch rule (Presentation chỉ import OsirisApplication; Application chỉ import OsirisCore); 4 test ChatService chạy trên Linux.

- [x] **M0-6 — M0 Closeout**: `AnthropicProvider` (Messages API, URLSession thuần, pin `anthropic-version: 2023-06-01`, parse usage thật, error = status + hint không chứa key) — **cắm vào Gateway với 0 dòng thay đổi ở Core: AD-31 được chứng minh**; `KeychainSecretsVault` (App layer); composition graceful: có key → Anthropic + model thật, không key → Placeholder + model offline (app không bao giờ crash vì thiếu key); models/routing.json thêm claude-haiku (tier light, $1/$5 per 1M); Security Review sạch; 4 test provider offline.

- [x] **M1-0 (phần code) — Settings & API key entry**: `ProviderSettings` port dạng closure-struct trong Application (giải ràng buộc: arch rule cấm cả Presentation lẫn Application chạm Infrastructure → composition root bọc Keychain vào closures); `SettingsView` tối giản (SecureField, không bao giờ hiển thị lại key, trạng thái Connected/Offline, ghi rõ cần restart); sidebar thêm mục Settings; `Docs/RUNBOOK_M1-0.md` — hướng dẫn từng bước cho user tự chạy Mac verification + smoke test + thu baseline thật.
- [x] **M1-1 — Skill Registry v1**: 3 skill tổng quát thuần dữ liệu (`core.summarize`, `core.draft`, `core.research-outline` — version 1.0.0, promptTemplate với `{goal}`, tier khai báo); `triggerKeywords` = field optional mới trên SkillDefinition (AD-28, có lập luận: matching data-driven để **thêm skill không cần sửa Kernel** — đúng mục tiêu milestone); Kernel Decide: reuse → skill-match (nhiều hit thắng, tie theo id, không hit = fallback nguyên trạng) → plain AI; strategy `.ai(skill:)` payload — skill chỉ tồn tại trên đường AI; Execution assemble template máy móc; **trả nợ `Kernel.skills` chưa tiêu thụ**; 4 test mới chứng minh bằng captured prompt (template vào prompt, không khớp giữ prompt trần, registry rỗng an toàn, tie-break deterministic).

- [x] **M1-2 — Gateway Retrieval & Assembly** (AD-24): Gateway retrieve context qua `Store.search` (`.anyWord` mới — rank theo word-hit; `.exact` default giữ nguyên cho reuse của Kernel); assembly theo section có cấu trúc (`## Relevant context` → Working Context/Knowledge/Previous results → `## Task`) với ưu tiên Critical(preamble+task, không bao giờ cắt) > Important(WC) > Helpful(Knowledge, lấy body đầy đủ) > Optional(deliverable history); trim nguyên-snippet từ ưu tiên thấp theo `contextBudgetTokens`; snippet cap 600 chars, N≤3 (`maxContextSnippets`); **retrieval trước cache lookup → cache key phản ánh đúng context (test: context đổi = cache miss)**; metrics thêm `contextSnippetCount`; một Store instance chia sẻ Kernel+Gateway (không nguồn sự thật thứ hai); không context → prompt y hệt trước M1-2 (zero regression, có test); ContextPriority hết là dead contract; 5 test mới.

- [x] **M1-3 — Composition Execution v1** (AD-36, cả 3 đề xuất được user duyệt): xóa struct `SkillComposition` — composition = `SkillDefinition.compositionSteps` (≤5 bước, precondition); composition mẫu `core.research-then-draft` với triggerKeywords = hợp keywords các bước con (goal nhiều keyword → composition thắng tự nhiên, một keyword → tie-break về skill đơn — test chứng minh); Kernel resolve steps trong Decide (Execution không chạm registry), composition hỏng degrade về plain AI; Execution chạy tuần tự máy móc — output bước trước (cap 6000 chars) nối vào bước sau, mỗi bước một `ai.request` metrics, deliverable = output bước cuối; **parallel + resume-sau-suspend hoãn có duyệt** — xét lại tại M1 review; 3 test mới (chuỗi 2 bước đúng thứ tự qua captured prompts, precedence skill đơn, degrade an toàn).

- [x] **M1-4 — Tool Layer v1** (AD-37): `CurrentDateTimeTool` — goal ngày/giờ hoàn thành **0 AI call, 0 token** ("AI Is The Last Tool" thành test vĩnh viễn); `triggerKeywords` trên protocol Tool, **một** thuật toán matching dùng chung skill+tool (`selectByKeywords`); tools inject qua Kernel init (không Tool Registry); `.tool(any Tool)` — plan mang tool đã resolve; **tool results không persist** (deviation có lập luận so với NEXT_TASK: tool re-run miễn phí, kết quả cũ là câu trả lời sai chờ trong reuse — test chứng minh goal lặp lại vẫn fresh + 0 AI); tool fail không rơi sang AI (Kernel đã quyết); metrics `tool.run` tối thiểu; +1 arch rule (Core/Tools là leaf — không biết AI/Skill/Store/Kernel); 4 test mới.

- [x] **M2-1 — Projects v1** (AD-38): multi-project thật — `Store.listProjectStates()` (mới nhất trước) + `ProjectState.name` với decode-fallback về id (file cũ migrate im lặng, có test); `ProjectDirectory` closure-port (Application, cùng pattern ProviderSettings — không cạnh import mới): list/create là state management đi thẳng composition→Store, execution results vẫn chỉ qua Kernel; ChatService.submit bắt buộc projectID (UI sở hữu project hiện tại — hết hardcode "default"); sidebar Projects (chọn/tạo qua alert); Project Isolation test ở tầng Application (2 project không rò state); 4 test mới.

- [x] **M2-2 — Project Resume v1**: mở project → thấy ngay trạng thái từ ProjectState (State Over Chat — transcript chat không persist): `ProjectOverview` (lastGoal, completedCount, ≤5 deliverables mới nhất với preview 120 chars) + đọc full deliverable qua sheet; **toàn bộ logic lắp resume nằm trong MỘT hàm thuần `ProjectOverview.assemble`** (test được trên Linux — composition chỉ fetch); port `ProjectDirectory` mở rộng 2 closure (không method Store mới — checklist giữ vững); overview là read-through, refresh khi đổi project/hoàn thành goal; file deliverable mất không phá resume (test); 4 test mới.

- [x] **M2-3 — Global Search v1**: một ô search từ sidebar, kết quả nhóm theo loại xuyên mọi project (Projects khớp tên case-insensitive → Deliverables → Knowledge → Working notes); `SearchHit.assemble` là hàm thuần testable (composition chỉ fetch — pattern M2-2); deliverable titled bằng preview, **không lộ path nội bộ**; project-hit chuyển workspace, deliverable-hit mở reader (tái dùng flow M2-1/M2-2); search closure thêm vào port `ProjectDirectory` (Năm Câu Hỏi: 1 closure không đáng port mới; tên port xem lại ở M2 review); không method Store mới (StoreQuery projectID:nil + .anyWord có sẵn từ M1-2); 4 test mới.

- [x] **M2-4 — Dashboard v1** (AD-39): operational awareness đúng BLUEPRINT (Now / Today's usage / System / Recent activity — không chart, không %, không analytics); `DefaultAIGateway.onMetrics` — MỘT callback optional (seam quan sát duy nhất, test cũ pass nguyên trạng); `DashboardModel` (Application): metrics **session-only** (không persist — M7 quyết lịch sử), activity strip newest-first cap 10, tất cả logic testable; **EventBus có 2 consumer production đầu tiên** (chat relay + dashboard) — trả nợ từ M0-5, tái đánh giá giá trị tại M4; 5 test mới (gồm seam fire cả cache-hit).

- [x] **M2-5 — Advanced Mode gate + Accessibility pass** (AD-40): toggle trong Settings, ẩn mặc định — `@AppStorage` nằm trọn trong Presentation (không cần port); **AD-40 định nghĩa ranh giới hai loại persist** (UI-pref = UserDefaults ở App/Presentation; platform data = Store) + arch rule mới cưỡng chế (15 rule); AdvancedView read-only: Skills inventory (`SkillInfo.from` — pure mapping, composition badge) + System (provider/version) — không dev-tool platform, không hành động phá hoại; accessibility: label cho nút icon-only, status combine, không fixed font; 3 test mapping + 1 arch rule.

- [x] **M3-1 — Reflection & Write Gate v1** (AD-41; **AD-20 AWAITING → PROVEN**): Reflection deterministic (0 AI/0 token, tiêu chí chặt: `.ai/.composition` + goal ≥4 từ + có deliverable, tối đa 1 candidate) sinh `MemoryCandidate` — không biết Store, không persist; `WriteGate` là điểm quyết định duy nhất (policy từ policies.json — key nằm chờ từ M0-1; unknown justification = fail fast; đích = WorkingContext TTL tự dọn; default `.disabled` — memory là opt-in); arch rule mới: memory record chỉ construct trong Core/Store (không bypass — 16 rule); save best-effort; **test giá trị khép vòng: goal LIÊN QUAN (không exact) nhận được memory phản chiếu trong prompt qua retrieval**; 6 test mới.

## 4. Việc đang chờ (Next Tasks)

1. **[USER] Chạy `Docs/RUNBOOK_M1-0.md`** — nợ **High**.
2. **M3-2 — Smart Planning v1** (chi tiết: `NEXT_TASK.md`): ước lượng complexity deterministic trong Decide → chọn tier; Confidence **Medium** có consumer đầu tiên (assumption ghi qua đúng WriteGate vừa xây).

## 4d. M2 Closeout (nghiệm thu 2026-07-02, tag `M2`)

**Tiêu chí M2 — đánh giá trung thực:**

| Tiêu chí | Kết quả |
|---|---|
| Sidebar (Chat/Search/Dashboard/Projects/Settings; Advanced ẩn) | ✅ |
| Projects: multi-project + resume tức thì | ✅ (AD-38; isolation + migration có test) |
| Settings tối giản + API key + Advanced toggle | ✅ |
| Global Search nhóm loại, xuyên project | ✅ (0 API Store mới) |
| Dashboard = operational awareness, không analytics | ✅ (AD-39) |
| Advanced Mode read-only | ✅ (AD-40) |
| Accessibility | ✅ code-level · ⚠️ mắt thường PENDING Mac |
| "Người dùng mới hiểu app trong phút đầu" / "app cảm giác hoàn chỉnh" | ⚠️ **PENDING — chỉ xác minh được trên thiết bị (runbook)** |

**Câu treo — quyết định có lý do:**
- Tên port `ProjectDirectory` (5 vai): **GIỮ** — rename là churn thẩm mỹ không lợi ích chức năng (Constitution: không refactor chỉ vì có cách khác); điều kiện tách: khi M3 làm search giàu lên thành surface riêng.
- `InMemorySecretsVault`: **ĐÃ XÓA** đúng hẹn (zero consumer — lời hứa M2-1 thực thi; test double conform protocol tại chỗ khi cần).
- `ChatViewModel` (172 dòng, 4 deps): **chưa god object** — hoãn tách với trigger cứng: *task UI kế tiếp chạm file này (M4 module UI) phải TÁCH thay vì mở rộng* (ghi nợ Medium).
- `SkillDefinition.retryPolicy`: giữ — deadline là M3 review như hẹn từ M1.

**ADR M2 evidence:** AD-38 (isolation test 2 project + migration test) ✅ PROVEN · AD-39 (seam test cả cache-hit; bus 2 consumer — giá trị "≈ fan-out" ghi trung thực, tái đánh giá M4) ✅ PROVEN · AD-40 (arch rule cưỡng chế, 15 rule xanh) ✅ PROVEN.

**Chất lượng:** build 0/0 debug+release · 87/87 test offline ~1s · baseline: fresh **5.53ms** / reuse **3.49ms** (M1: 5.45/3.14 — nhích trong biên độ đo, theo dõi tiếp) · security sạch · Application lớn nhất 152 dòng, ViewModel 172 · chi phí AI tích lũy **$0.00**.

**Kết luận: M2 ĐẠT (code-complete)** — như M0, phần xác minh thiết bị PENDING có địa chỉ (runbook). Rủi ro lớn nhất không đổi: nợ High Mac ngày càng đắt.

## 4c. M1 Closeout (nghiệm thu 2026-07-02, tag `M1`)

**Tiêu chí M1 (DEVELOPMENT_PLAN §2/M1) — đánh giá trung thực:**

| Tiêu chí | Kết quả |
|---|---|
| Skill Registry: schema AD-28 + 3–5 skill tổng quát | ✅ 4 skill (3 đơn + 1 composition); *chỉnh skill qua app UI: chưa — M2+* |
| Store đầy đủ: 3 record type + search | ✅ (exact + anyWord relevance); *write gate/learning gate (AD-20): contract chờ consumer — Reflection thuộc M3* |
| Gateway đầy đủ: retrieve→assemble→budget→cache→route→đo | ✅; *compression = trim v1; tier routing chờ ≥2 model thật* |
| Execution: composition + retry khai báo | ✅ composition (AD-36); Gateway retry ✅; *per-skill RetryPolicy field chưa consumed*; **parallel + resume: HOÃN CÓ DUYỆT** — điều kiện kích hoạt ghi tại DEVELOPMENT_PLAN |
| Kernel: resource order + Confidence + gates | ✅ reuse→tool→skill→AI (test); *Confidence: High/Low dùng, Medium chờ; ApprovalGate wired nhưng chưa được tham vấn — chưa tồn tại risky action (publish/delete thuộc M2+/M6)* |
| Tool Layer v1 | ✅ 0-AI-call có test (AD-37) |
| "Task hoàn thành 0 AI call khi tài nguyên đáp ứng" | ✅ test vĩnh viễn (reuse + tool) |
| "Mọi AI call qua Gateway" | ✅ cưỡng chế bằng arch rule |

**ADR M1 — Decision → Evidence → Result:** AD-31 (provider cắm vào, Gateway diff = 0 dòng ở M0-6) ✅ PROVEN · AD-32/33 (arch tests + purity) ✅ PROVEN · AD-34 (suite bắt vi phạm thật ngay lần đầu) ✅ PROVEN · AD-35 (ChatService tests + import rules) ✅ PROVEN · AD-36 (composition tests 2 chiều precedence) ✅ PROVEN · AD-37 (0-AI + staleness tests) ✅ PROVEN · AD-20 (learning gate) ⏳ AWAITING CONSUMER (M3) · Superseded mới: không.

**Chất lượng:** build 0/0 debug+release · 66/66 test (52 unit + 14 arch), offline, ~1.1s · baseline nội bộ: fresh **5.45ms** / reuse **3.14ms** (M0: 4.65/2.54 — +≈0.8ms là chi phí matching tool+skill và Gateway retrieval, chấp nhận ở mức ms) · security scan sạch · không god object (file lớn nhất 281 dòng) · chi phí AI tích lũy: **$0.00**.

**Kết luận: M1 ĐẠT.** Các mục partial đều là *contract chờ consumer* (không phải lỗ hổng đang chảy máu), có chủ sở hữu milestone rõ. Rủi ro lớn nhất mang sang M2: UI chưa qua compiler Mac (nợ High — runbook).

## 4b. M0 Closeout & Final Verification (nghiệm thu 2026-07-02, tag `M0`)

| Tiêu chí M0 / Definition of Done | Kết quả |
|---|---|
| Vòng đời 5 pha end-to-end: goal → events → deliverable → restart vẫn còn ProjectState | ✅ chứng minh bằng test (package level) |
| Token/cost/latency mỗi AI call được log (AD-15) | ✅ pipeline đo hoạt động; cost accounting xác minh bằng integration test ($0.0035 cho 1000 in/500 out haiku) |
| Kiến trúc sạch, không vi phạm dependency rule | ✅ 13 arch test + compiler; debug + release build 0 warning |
| Reuse loop: goal lặp lại = 0 AI call | ✅ test chứng minh |
| App hoạt động không cần API key | ✅ graceful fallback |
| Config/ shipped hợp lệ (cả 2 chế độ online/offline) | ✅ `ShippedConfigurationTests` — validation vĩnh viễn trong suite |
| Tích hợp Anthropic end-to-end (URLSession thật, không Internet) | ✅ URLProtocol stub: headers pinned, body đúng schema, parse usage, cost từ catalog |
| App/Presentation (6 file SwiftUI) | ✅ qua `swiftc -parse` (cú pháp); ⚠️ **type-check/simulator PENDING — cần Mac** |
| Smoke test provider thật + baseline token/cost thật | ⚠️ **PENDING — cần API key của user** (không giả số liệu) |
| Nợ kỹ thuật Critical = 0 | ✅ (toàn bộ Minor/Low, có ghi nhận §6) |
| Docs + State + NEXT_TASK + git tag | ✅ |

### Baseline (AD-15) — đo ngày 2026-07-02, Linux container, Swift 6.0.3

| Chỉ số | Giá trị | Ghi chú |
|---|---|---|
| Pipeline overhead, goal mới (5 pha + search miss + ghi file, KHÔNG gồm provider) | **~4.65 ms/request** | mean 30 runs, `PipelineBaselineTests` |
| Pipeline overhead, đường reuse (0 AI call) | **~2.54 ms/request** | mean 30 runs |
| Cost accounting | ✅ xác minh: 1000 in + 500 out (haiku $1/$5 per 1M) = $0.0035 | integration test |
| Token/latency/cost provider thật | **PENDING** | cần API key; đo ở M1-0 bằng 1–3 smoke call |
| Chi phí AI tích lũy toàn M0 | **$0.00** | |

**Kết luận nghiệm thu:** M0 ĐẠT — mọi thứ kiểm chứng được trong môi trường hiện tại đều xanh; 2 mục pending (Mac type-check/simulator, baseline provider thật) đã khoanh vùng, có kế hoạch tại M1-0, không chặn kiến trúc M1.

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
| AD-31 | AI Provider là Integration, không phải Core: Core hoàn thiện trước khi kết nối provider thật; PlaceholderProvider là provider duy nhất đến hết M0; Gateway hoạt động đầy đủ không phụ thuộc provider thật; adapter thật thêm sau không đổi Gateway |
| AD-32 | Một persister duy nhất: chỉ Store chạm LocalStorage; Store ghi cả deliverable file (`saveDeliverable`); Execution trả kết quả in-memory; Kernel orchestrate persistence chỉ qua Store |
| AD-33 | Kernel thuần túy: chỉ phụ thuộc protocol Core, không I/O, không import Infrastructure; progress events qua closure `@Sendable (ExecutionEvent) async -> Void` inject từ composition root |
| AD-34 | Architecture Test Suite trong `swift test` quét source cưỡng chế quy tắc kiến trúc; compiler cưỡng chế đồ thị target, test cưỡng chế quy tắc trong target; AD mới có rule kiểm được → thêm rule |
| AD-35 | Application Layer (`OsirisApplication`, chỉ phụ thuộc OsirisCore): ChatService là cầu nối duy nhất UI ↔ Core, dịch event/error → TaskUpdate; Presentation chỉ import OsirisApplication; UI không biết provider/retry/reuse; không rename ExecutionEvent — tổng quát hóa bằng tầng dịch |
| AD-36 | Composition = `SkillDefinition.compositionSteps` (≤5 bước); xóa struct `SkillComposition` (nguồn sự thật đôi); Kernel resolve steps trong Decide, Execution chạy tuần tự máy móc; parallel + resume hoãn có duyệt đến khi có bằng chứng — xét lại tại M1 review |
| AD-37 | Tool Layer v1: triggerKeywords trên protocol Tool; MỘT thuật toán matching chung skill+tool; tools inject qua Kernel init (không Tool Registry — AD-17); `.tool(any Tool)` đã resolve; tool results không persist (re-run miễn phí, stale = sai); tool fail không rơi sang AI; metrics tool.run tối thiểu; arch rule: Core/Tools là leaf adapter |
| AD-38 | Quản lý project = state management (không phải goal execution): closure-port `ProjectDirectory` từ composition root xuống Store; execution results vẫn chỉ qua vòng đời Kernel; ProjectState.name decode-fallback về id |
| AD-39 | Gateway.onMetrics: MỘT callback optional phát metrics mỗi request — Gateway không aggregate/persist; DashboardModel session-only (M7 quyết lịch sử); EventBus 2 consumer đầu tiên, tái đánh giá tại M4 |
| AD-40 | Ranh giới persist: UI preferences = UserDefaults/@AppStorage, chỉ App/Presentation (arch rule cưỡng chế); platform data = Store (AD-32 nguyên vẹn) |
| AD-41 | Reflection v1 deterministic (0 AI/0 token) sinh MemoryCandidate → WriteGate (policy từ config, điểm quyết định duy nhất, không bypass — arch rule) → Store persist; đích WC-TTL; Knowledge đóng; AI-reflection cấm đến khi trả lời 4 câu bằng chứng; AD-20 PROVEN |

## 6. Nợ kỹ thuật (phân loại lại tại M1 Review — Critical/High/Medium/Low)

**Critical: 0.**

| Mức | Mô tả | Kế hoạch |
|---|---|---|
| **High** | 8 file SwiftUI (App/ + Presentation/) tích tụ 6 milestone chưa qua compiler (môi trường không có Mac); mới qua `swiftc -parse` | **[USER] chạy `Docs/RUNBOOK_M1-0.md`** trước hoặc song song đầu M2 — M2 là milestone toàn UI, xây tiếp trên nền chưa compile là rủi ro kép |
| Medium | Token/latency/cost baseline provider thật chưa có (cần API key) | Phần C của runbook; không giả số liệu |
| ~~Medium~~ | ~~Store write gate / learning gate (AD-20) chưa enforce~~ — **ĐÃ TRẢ tại M3-1** (WriteGate + arch rule không-bypass) | ✅ |
| Medium | Tier routing chưa hoạt động (`preferredTier` chưa được Gateway tiêu thụ — 1 model thật) | Kích hoạt khi có ≥2 model thật trong catalog |
| Medium | `SkillDefinition.retryPolicy` (per-skill) chưa được consumed — Gateway retry là mức duy nhất đang chạy | Kích hoạt cùng tool/AI failure patterns thật (M2+); nếu M3 vẫn không có consumer → cân nhắc xóa field (AD-28 hai chiều) |
| Low | Store search đọc lại toàn bộ file mỗi lần (chưa cache/index); relevance = word-hit v1 | Tối ưu ở M3/M7 khi có số liệu thật |
| Low | Working-context hết hạn chỉ lọc khi đọc, chưa xóa vật lý | Cleanup policy M1→M3 (policies.json đã có TTL) |
| Low | `InMemoryResponseCache` không bound/TTL | Eviction khi có bằng chứng; interface là seam |
| Low | Keyword matching khớp cả ngữ cảnh phủ định ("don't summarize") | Chấp nhận v1 — fallback rẻ; nâng cấp theo sử dụng thật |
| Low | Reuse per-project (đúng Project Isolation; chưa có cross-project reuse có kiểm soát) | M3 với policy rõ |
| Low | Arch-test scanner cắt `//` theo dòng — string literal chứa URL có thể false-negative | Nâng parser khi có ca thật |
| Medium | `ChatViewModel` gánh 5 vai (chat/projects/search/dashboard/skills) — 172 dòng, chưa đau nhưng trend rõ | **Trigger cứng:** task UI kế tiếp chạm file này phải TÁCH (không mở rộng thêm) |
| Low | EventBus: 2 consumer tĩnh hiện tại ≈ closure fan-out — giá trị thật chờ consumer động | Tái đánh giá tại M4 (Modules); xóa nếu modules không dùng (AD-39) |
| Low | Metrics chỉ session-only — restart mất "Today's usage" | Chấp nhận theo thiết kế; persist history là câu hỏi M7 với dữ liệu thật |

*(Đã xử lý & gỡ khỏi bảng: UI nhập API key — SettingsView M1-0; InMemoryStore — xóa M0-2; reuse-snippet — trả M0-4B; ContextPriority/`Kernel.skills` dead contract — tiêu thụ M1-2/M1-1.)*

## 7. Rủi ro đang theo dõi

- **Scope creep module:** chỉ bắt đầu module mới sau khi YouTube module đạt chuẩn reference (AD-21).
- **iOS background limits:** Execution Engine phải resume được sau khi app bị suspend (tiêu chí M1).
- **Provider lock-in:** mọi tính năng chỉ được dùng provider qua AI Gateway; vi phạm = fail code review.
- **Tái tạo component đã loại bỏ:** danh sách cấm tại SYSTEM_COMPONENTS.md §6 — **nay được cưỡng chế tự động** bởi Architecture Test (AD-34); các merge đã bác (sàn kiến trúc) tại §7 — không lặp lại phân tích.

## 8. Quy tắc cập nhật file này

- Cập nhật sau **mỗi** phiên phát triển (nguyên tắc Session Continuity).
- Chỉ ghi thông tin có giá trị tương lai; xóa mục đã hết hạn.
- Không ghi lại nội dung hội thoại; chỉ ghi trạng thái, quyết định, việc còn lại.
