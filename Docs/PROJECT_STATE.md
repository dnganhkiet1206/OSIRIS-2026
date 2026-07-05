# PROJECT_STATE.md — Trạng Thái Dự Án OSIRIS

> **Cập nhật lần cuối:** 2026-07-03
> Đây là **nguồn sự thật duy nhất** về trạng thái dự án (nguyên tắc *State Over Chat*). Mọi phiên phát triển bắt đầu bằng việc đọc file này và kết thúc bằng việc cập nhật file này. Đây là **file duy nhất luôn được nạp** vào AI dev session (AD-29) — giữ file ngắn gọn, dạng cấu trúc.

---

## 1. Tổng quan nhanh

| Hạng mục | Giá trị |
|---|---|
| Giai đoạn | **M9 — Product Experience & UI/UX: đang triển khai** (M0→M8 nghiệm thu; tag local chờ push). M9-0 Architecture Review ✅ (§4t). KHÔNG mở rộng AI/module/tool — chỉ biến prototype → sản phẩm production |
| Task hiện tại | **M9-0 (Architecture Review & Design Audit) ✅ — KHÔNG code (đúng "không viết code trước").** Audit 10 câu bằng bằng chứng (§4t): Design System `Shared/` RỖNG · 0 animation · 0 app icon/brand color · card/button DUPLICATE inconsistent · spacing/radius ad-hoc · responsive cấu trúc OK (NavigationSplitView adaptive, 0 fixed frame) nhưng chưa audit iPhone từng màn. **Giải pháp nhỏ nhất: `Shared/DesignSystem` = hằng số + ViewModifier (data), KHÔNG framework/engine.** kế tiếp: **M9-1 chờ USER xác nhận** (bước Consistency đầu — thứ tự Consistency→Clarity→Responsive→A11y→Animation→Polish) — KHÔNG tự mở |
| Nền tảng | iOS (iPhone), SwiftUI · Core/Application = SwiftPM build được mọi nền tảng (AD-30/35) |
| Trạng thái kiến trúc | ✅ v1.1 — Core **6 thành phần** + Application + **3 module** (YouTube, TikTok, Shopify) qua Contract v1 (AD-44) · **18 Architecture Test (function) chống drift** (cưỡng chế đồ thị phụ thuộc + eliminated-components: EventBus AD-46, automation-engine AD-47) · resource order Decide ĐẦY ĐỦ: reuse → tool → skill/composition → AI |
| Trạng thái codebase | ✅ **0 error / 0 warning (debug + release), 164 test / 2 opt-in skip / 0 fail** (~1.1s offline; +1 test provider-contract) (Swift 6.0.3 CI · đo/test trên 6.3.3 Linux) · Keychain fix (M8-1) + MessageRow a11y (M8-6) = verify qua CI macOS · **XÁC THỰC MAC THẬT 2026-07-05: App/Presentation compile 0 lỗi, iPhone 17 Pro sim (iOS 26.2), UI end-to-end (§4i)** |

## 2. Mục tiêu hiện tại (Current Goal)

M6 — Automation: nối trí tuệ với thực thi tự động, KHÔNG visual workflow builder (DEVELOPMENT_PLAN §2/M6). M6-0 chốt thiết kế (AD-47); M6-1 hiện thực: `AutomationRule` = data trong Store + "run now" tái dùng Kernel (0 engine). Trigger theo lịch = iOS background PENDING thiết bị. Song song: user chạy `Docs/RUNBOOK_M1-0.md` — nợ High.

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

- [x] **M3-2 — Smart Planning v1** (AD-42): `ComplexityEstimate` (pure, Core/Kernel/Decision) — simple/standard/complex từ số từ + tín hiệu khối lượng ("detailed/toàn diện…") + số mệnh đề, deterministic tuyệt đối (có test 10 lần cùng input); **tier được earn thay vì hardcode**: skill khai báo > estimate (`simple/standard→.light`, `complex→.standard`), Gateway chỉ tiêu thụ — nợ Medium "preferredTier chưa mang giá trị thật" TRẢ MỘT NỬA (phía Kernel xong, Gateway routing vẫn chờ ≥2 model); **Confidence Medium có consumer đầu tiên** (hết case chết): tín hiệu mơ hồ chặt ("somehow/gì đó/…") → vẫn thực thi + assumption ghi **qua đúng WriteGate M3-1** (không đường ghi mới; gate `.disabled` chặn cả assumption — test), assumption xuất hiện trong retrieval của goal liên quan sau (test khép vòng); goal thường KHÔNG sinh assumption (test chống spam); `.reuse/.tool` path không bị ảnh hưởng; 13 test mới (RecordingEngine đọc plan tại biên thật).

- [x] **M3-3 — Deliverable Templates & Executive Summary v1** (AD-43): Executive Summary = cấu trúc output KHAI BÁO, không phải component — scaffold là DATA trong `Config/deliverable-scaffold.md` (test cưỡng chế ≤80 token + phải chứa "Executive Summary"), composition root inject vào Execution như chuỗi khai báo (KHÔNG hardcode trong Kernel/Execution — sửa format = sửa 1 file Config, 0 dòng code); Execution nối máy móc sau template + previous-step; áp dụng đúng nơi sinh deliverable: `.ai` + BƯỚC CUỐI composition (bước giữa = nguyên liệu, có test), plain-AI không skill cũng nhận (user không cần biết skill tồn tại); `.reuse` trả nguyên văn/`.tool` không AI — không re-format; default `nil` → prompt byte-identical trước M3-3 (zero regression by construction — 0 test cũ phải sửa); Kernel/Gateway/Store không chạm; KHÔNG Summary/Report/Formatter Engine; 7 test mới (6 template + 1 shipped-config).

- [x] **M4-0 — Module Contract v1 + YouTube Module skeleton** (AD-44): `ModuleManifest` (Core/Modules/Contracts) — id/version/purpose/skills, thuần DATA, registry thứ hai theo AD-17 là DESCRIPTOR không phải engine; skill namespace theo module id (precondition structural — không collision); target SPM `OsirisModules` CHỈ depend OsirisCore (compiler: Core không thể biết module); composition root là nơi DUY NHẤT biết module cài đặt (`installedModules`), merge skills vào MỘT registry chung; **YouTube module v0** (`youtube.idea-generation`, `youtube.script-outline` — thuần data, overlapping-phrase keywords thắng generic skill 2-1 có test); **3 arch rule mới/siết** (18 tổng): Modules chỉ import OsirisCore (siết từ Core+Infra), Modules-are-data-only (cấm Kernel/Gateway/Store/Execution/I-O), Core/App/Infra/Presentation cấm nhắc tên module cụ thể; **KHÔNG Plugin Engine/Module Manager/Extension Framework**; bằng chứng "thêm module không sửa Core": `git status Core/` = chỉ THÊM file contract mới, 0 file sửa; EventBus evidence bắt đầu đếm: module v1 KHÔNG cần events; 5 test module mới + zero regression; 121/121.

- [x] **M4-1 — Idea → Script pipeline, composition xuyên namespace**: `youtube.script-generation` (full script, tier `.standard` khai báo — skill nặng nhất module, AD-42 hoạt động cho module data); 2 composition thuần data: `youtube.idea-to-script` (idea → script) và `youtube.research-to-script` (**bước 1 = `core.research-outline` — built-in, resolve xuyên namespace CHỈ bằng SkillID qua registry chung: cross-namespace PROVEN bằng test captured-prompt**); **tinh chỉnh guideline data (không đổi matcher):** union keywords của composition được TUYỂN CHỌN — bỏ keyword rộng nhất ("script") để composition chỉ thắng khi goal chứa CẢ HAI domain; goal thuần script/idea về single skill (test 1-AI-call); composition thiếu built-in step degrade về plain AI đúng luật M1-3 (test); scaffold M3-3 áp dụng nguyên trạng cho pipeline module (bước giữa raw, bước cuối có Executive Summary — test); **0 dòng sửa Core, 0 dòng sửa contract** — toàn bộ M4-1 là data + test; 6 test mới; 127/127.

- [x] **M4-2 — SEO + Publishing Package**: `youtube.seo-package` (metadata: titles/description/tags/hashtags) + `youtube.publishing-package` — **package là DELIVERABLE, không phải hệ thống**: skill một-prompt dùng độc lập (1 AI call) HOẶC làm bước cuối composition `youtube.script-to-package` (package grounded trong script thật qua previous-step chaining — test); không Publishing/SEO/Metadata Engine; module vẫn 0 state/session/OAuth/upload/cache/persistence; **guideline union tinh chỉnh lần 2 (vẫn thuần data):** quy tắc thật = "tuyển chọn union sao cho MỌI tie về single skill, kiểm từng cặp overlap bằng test với tie-break id trong đầu" (ở đây GIỮ "script" trong union vì các id tie đều sort trước composition — ngược với case M4-1 bỏ "script"); phát hiện qua test fail-first (tie 2-2 → single thắng sai domain); 0 dòng Core, 0 dòng contract; 3 test mới; 130/130.

- [x] **M4-3 — Channel Analysis v1 + quyết định tool-channel** (AD-45): Architecture Review TRƯỚC code (11 câu, 3 phương án so sánh — xem report phiên); **quyết định: KHÔNG mở contract** — lý do cấu trúc: manifest là Codable data, Tool là protocol hành vi → `[any Tool]` đổi bản chất contract, không phải thêm field; `youtube.channel-analysis` = skill phân tích dữ liệu USER DÁN VÀO goal (0 tool/OAuth/network/state — dữ liệu dán luôn tươi, cùng logic AD-37; insight từ text = việc AI thật, không vi phạm "AI Is The Last Tool"); tier `.standard` khai báo; keywords 0 overlap với toàn registry (test sweep tự động — chống n² bằng máy thay vì rà tay); điều kiện kích hoạt tool-channel ghi tại AD-45 (M6: OAuth/network do user quyết + MCP flag); EventBus: 4 mảng liên tiếp không cần events; 0 dòng Core, 0 dòng contract; 3 test mới; 133/133.

- [x] **M5-0 — TikTok Module + MODULE_GUIDE.md**: `Docs/MODULE_GUIDE.md` (≤2 trang, prescriptive: manifest/namespace/keywords/composition/curated-union/tests/arch-rules/cấm) — tài liệu DUY NHẤT cần để viết module, 0 tham chiếu Core; **bài kiểm tra guide ĐẠT**: TikTok module (`tiktok` — hook-ideas, content-plan, trend-brief + composition `tiktok.research-to-plan` xuyên namespace `core.research-outline`→module) dựng CHỈ từ guide + `ModuleManifest`, không cần đọc Core; **0 dòng Core, 0 dòng Infrastructure, 0 dòng contract** (lần 4 chứng minh "thêm module = data + 1 dòng wiring"); trend-brief dùng dữ liệu user dán (AD-45); sweep test nâng cấp cho 2 module (keyword TikTok 0 giẫm toàn registry); 7 test mới; 139/139. **Không AD mới — contract giữ nguyên là chính bằng chứng.** Phát hiện trung thực: latent overlap tiếng Việt nội bộ YouTube ("viết"⊂"viết kịch bản đầy đủ") — ngoài phạm vi M5-0, ghi nợ Low.

- [x] **M5-1 — Shopify Module (module thứ 3, domain e-commerce khác hẳn)**: guide-validation lần 2 — dựng từ `Docs/MODULE_GUIDE.md` + `ModuleManifest`; `shopify` (product-research, listing-optimization, store-analysis dùng dữ liệu user dán AD-45 + composition `shopify.research-to-listing` xuyên namespace `core.research-outline`→module); keyword single-skill CỐ Ý tránh từ built-in ("research"/"draft") để không tie với `core.*` (test precedence chứng minh goal "research…" thuần vẫn về core); **0 dòng Core/Infrastructure/contract** (lần 5); **MODULE_GUIDE nâng cấp tự-đủ**: Phụ lục A (built-in skill IDs) + Phụ lục B (khung test copy sẵn) — đóng finding M5-0; arch rule cấm-tên-module siết thêm "shopify"; **đạt tiêu chí M5 ≥3 module**; 7 test mới; 146/146.

- [x] **M6-2 — Automation UI v1** (code-complete; type-check + UX chờ CI macOS/thiết bị như mọi UI từ M0): surface Presentation cho port `Automation` M6-1 — tạo rule từ 1 goal, **"Run now" thủ công** (tái dùng đúng Kernel qua ChatService, không path mới), toggle enabled, xoá, xem kết quả lần chạy; **`AutomationViewModel` RIÊNG** (không nhồi ChatViewModel — tôn trọng trigger cứng M2-6: "task UI kế tiếp phải TÁCH, không mở rộng god-object") + `AutomationView` + mục sidebar "Automation"; import chỉ OsirisApplication (arch rule giữ); rule v1 chạy trong project "default" (per-project chờ bằng chứng — AD-28); **scheduled `.daily` firing HOÃN** (iOS BGTaskScheduler — 0 đường verify, code nền tảng thuần; `.manual` + run-now đã đủ dùng); 5 file parse-sạch, 157+1 test không đổi (Presentation ngoài SPM — CI macOS type-check).

- [x] **M6-1 — Automation-as-data v1** (AD-47 câu 4 hiện thực): `AutomationRule` = **record thứ 4 của Store** (schema tối thiểu AD-28: `id`, `projectID`, `goalText`, `trigger`, `enabled` — "goal" tách 2 trường, KHÔNG field để dành); `AutomationTrigger` enum data (`.manual` chạy được / `.daily(hour:)` = SCHEMA cho iOS scheduling, không fire trên Linux); Store CRUD (`automationRules`/`save`/`deleteAutomationRule`, layout `automation-rules/<id>`, persist qua Store duy nhất AD-32 — test restart); Application port `Automation` (closure struct, pattern AD-38) — **`runNow` gọi đúng `ChatService.submit` như goal thủ công, KHÔNG execution path thứ hai** (test: rule goal qua Kernel = 1 AI call ordinary); pure mapping `AutomationRuleSummary.from` testable; arch rule cấm-tái-tạo siết thêm `AutomationEngine/AutomationManager/RuleRunner/AutomationRuntime` (cưỡng chế "0 engine" của user); **0 component mới, 0 pipeline riêng**; 7 test mới; 153/153.

- [x] **M6-0 — Automation Architecture Review + xóa ApprovalGate** (AD-47): review 4 quyết định bằng bằng chứng grep/git — **(1) XÓA ApprovalGate + RiskyAction/ApprovalDecision/RequireUserApprovalGate**: `evaluate(_:)` chưa từng gọi, `RiskyAction` chưa từng construct qua 6 milestone; automation sinh deliverable local-reversible ≠ risky action; xóa (Kernel init bớt 1 param, ~18 test site, file Gates/ xóa) — **146/146 pass, 0 test logic sửa = bằng chứng 0 consumer**; tái sinh cùng risky action THẬT đầu tiên (= mở tool-channel AD-45); **(2)** tool-channel KHÔNG mở (không module cần); **(3)** EventBus KHÔNG tái sinh (không audience động); **(4)** automation = DATA (rule: goal + trigger) + Kernel hiện có, KHÔNG Engine/Runtime/Scheduler — build M6-1; trigger lịch = iOS PENDING thiết bị.

## 4. Việc đang chờ (Next Tasks)

1. **[USER] Xác nhận mở M9-1** (`NEXT_TASK.md`): bước Consistency #1 (design tokens + card/button ViewModifier, data). M9-0 Architecture Review ✅ (§4t). **KHÔNG tự mở M9-1.**
2. **[USER] Mac/key (không chặn M9):** test provider contract key thật (§4r+§4s) · a11y runtime pass (§4q) · M7 provider-side (key thường trực).
2. **[USER] Cấp API key THƯỜNG TRỰC** để mở **M7 provider-side** (tối ưu token/latency/cost qua Gateway) — hiện HOÃN; key một-lần đã thu sàn provider (§4j), cần key thường trực cho baseline qua-Gateway nhiều sample.
3. M8-0 ✅ (§4k). CI macOS giữ chống regression UI.

## 4h. M6 Closeout (nghiệm thu core 2026-07-04, tag `M6`)

**Tiêu chí M6 (DEVELOPMENT_PLAN §2/M6) — đánh giá trung thực (M6 là milestone PARTIAL rõ nhất: nửa nền-tảng hoãn):**

| Tiêu chí | Kết quả |
|---|---|
| Automation rules đơn giản (điều kiện → skill/composition) | ✅ `AutomationRule` = data (M6-1) + UI tạo/chạy/xoá (M6-2); "điều kiện" = `AutomationTrigger` (.manual chạy được / .daily schema) |
| Công việc lặp lại chạy tự động | ⚠️ **thủ công xong** ("Run now" tái dùng Kernel, có test); **tự động theo lịch HOÃN** — iOS `BGTaskScheduler` là code nền tảng thuần, 0 đường verify Linux/CI (chỉ compile) |
| MCP integration cho remote tools (AD-18) | **HOÃN** = mở tool-channel (AD-45) + risky action + ApprovalGate tái sinh — cụm 1 quyết định, chờ use case thật + user consent network |
| Execution monitoring | ✅ tái dùng Dashboard M2-4 (automation chạy qua cùng Kernel → cùng metrics/activity) |
| "Mọi hành động rủi ro qua approval gate" | ✅ **thỏa mãn rỗng đúng nghĩa**: automation v1 KHÔNG có risky action (chỉ sinh deliverable local-reversible); ApprovalGate đã xóa (AD-47) chính vì 0 risky action — tái sinh CÙNG risky action thật đầu tiên |

**ADR M6:** AD-46 (xóa EventBus — 146/146 pass 0 test sửa) ✅ PROVEN · AD-47 (4 quyết định: xóa ApprovalGate + tool-channel không mở + EventBus không tái sinh + automation=data) ✅ PROVEN (M6-1 build đúng thiết kế, 0 engine, arch rule cấm engine).

**Nợ — cập nhật theo hành động phiên debt-sweep:**
- **Nợ High (UI compile Mac): ✅ RETIRED 2026-07-05** — user build & chạy trên iPhone 17 Pro sim (iOS 26.2), 0 compile error toàn App/Presentation, Automation UI chạy end-to-end (§4i). Đây là rủi ro lớn nhất suốt M0→M6 (UI chưa qua compiler Mac), nay đóng bằng bằng chứng thiết bị thật — KHÔNG còn "unknown". CI macOS vẫn giữ để bắt regression tự động về sau.
- **Nợ Medium (baseline thật):** harness `LiveBaselineTests` sẵn, chạy Linux khi có key — chờ [USER].
- Bug tiếng Việt (Low): ĐÃ SỬA. ChatViewModel 5-vai: trigger tôn trọng (M6-2 dùng VM riêng). ApprovalGate: XÓA. Tier-routing/nhóm Low perf: chờ M7 + số liệu thật.

**Risky action / ApprovalGate — xác nhận điều kiện:** vẫn 0 risky action thật (external/irreversible effect cần external tools = tool-channel AD-45 chưa mở + chưa có user consent network). Gate + tool-channel + MCP tái sinh CÙNG NHAU khi có use case thật — không tách rời.

**Chất lượng:** build 0/0 debug+release · **157/157 test + 1 live-baseline opt-in skip** offline ~1.8s · baseline nội bộ không đổi (M6 không chạm hot path) · AI spend tích lũy **$0.00** · arch suite giữ (Presentation/App type-check do CI macOS).

**Open-source (cập nhật):** CI macOS giờ compile-check UI tự động (contributor + tôi thấy build status thật) — bước tiến lớn cho readiness. Còn: baseline thật (key) + device UX + scheduled-firing/MCP.

**Kết luận: M6 CORE ĐẠT** (automation-as-data + UI + manual run, kiến trúc sạch AD-46/47). Nửa nền-tảng (scheduled background firing, MCP) HOÃN CÓ ĐIỀU KIỆN rõ ràng — nhất quán cách M0/M2 tag với mục PENDING thiết bị. Tag `M6` đánh dấu core code-complete.

## 4i. Mac Validation — nợ High đóng bằng bằng chứng thiết bị (2026-07-05)

User tự chạy toàn bộ stack trên Mac thật (branch `claude/osiris-arch-review-docs-w3na6h`). Đây là lần đầu App/Presentation qua compiler + runtime trên thiết bị Apple sau M0→M6.

| Hạng mục | Kết quả |
|---|---|
| `swift test` (macOS) | 158 executed / 1 skipped (live-baseline opt-in) / **0 failures** — khớp Linux |
| `xcodegen generate` + Xcode build | ✅ OSIRIS.xcodeproj sinh & build **0 compile error** toàn App/Presentation |
| Chạy | iPhone 17 Pro Simulator, iOS 26.2 — app mở thẳng vào Chat |
| Chat | Gửi goal chạy; placeholder provider trả đúng |
| Settings | Offline mode + trường API key + Save Key + Advanced Mode toggle — đủ |
| **Automation UI (M6-2)** | ✅ Add rule · Run Now · Enable/Disable · Delete · empty state sau xoá — **end-to-end đúng** |
| Reuse (AD lifecycle) | ✅ lặp goal → "Recently completed…", deliverable cũ tái dùng, không sinh lại |

**Ý nghĩa:** rủi ro lớn nhất của dự án (UI chưa qua compiler Mac, mang từ M0) **đóng lại bằng bằng chứng thật, không phải suy đoán**. M6-2 Automation UI — thứ mới nhất, chưa từng chạy trên UI thật — hoạt động đầy đủ ngay lần đầu. CI macOS giữ để chống regression tự động.

**CHƯA test (có chủ đích, không phải lỗ hổng):** live Anthropic (chưa cấu hình key) → **baseline thật vẫn là nợ Medium đang mở**, và là điều kiện tiên quyết của M7. App vẫn placeholder-local.

## 4t. M9-0 Closeout — Product Experience Architecture Review & Design Audit (2026-07-05)

**M9 mở (USER xác nhận):** biến OSIRIS từ architecture-prototype → **ứng dụng production** (iPhone/iPad/macOS). KHÔNG thêm provider/module/MCP/automation/workflow/tool/intelligence/architecture. Chỉ trải nghiệm. Thứ tự ưu tiên: **Consistency → Clarity → Responsive → Accessibility → Animation → Polish.**

**M9-0 = Architecture Review only (KHÔNG code).** 10 câu, bằng chứng codebase:

| # | Câu | Bằng chứng |
|---|---|---|
| 1 | UI còn "developer tool" ở đâu? | empty/loading = text trần; 0 app icon/brand color (system accent); Dashboard/Advanced = bảng LabeledContent khô; 0 animation; message bubble không avatar/timestamp |
| 2 | Lần đầu mở chưa production? | emptyState text phẳng, 0 onboarding/welcome/identity; sidebar List generic; 0 app icon |
| 3 | Design System có/thiếu? | CÓ: SF Symbols, semantic font (Dynamic Type), semantic color (dark-safe), NavigationSplitView adaptive. THIẾU: `Shared/DesignSystem/` **0 file swift**, 0 token spacing/radius, 0 brand accent, **0 Assets.xcassets** (0 app icon), 0 component chuẩn, 0 animation |
| 4 | Duplicate? chuẩn hóa? | card-bg `.background(.quaternary.opacity(X), in: RoundedRectangle(cornerRadius:Y))` lặp (ProjectResume 8/0.4 & 14/0.25, Chat bubble 14) — X/Y inconsistent; icon-only button lặp (Chat+Automation). → ViewModifier nhỏ, KHÔNG manager |
| 5 | Typo/spacing/radius/card/button/toolbar/sidebar/nav/list/sheet/dialog thống nhất? | typo semantic nhưng role→style chưa rõ; spacing ad-hoc (2/4/6/8/10/14/80); radius 8 vs 14; card duplicate; button mix; toolbar chỉ navigationTitle; nav/list/sheet/dialog native (nhất quán mức native, chưa polish) |
| 6 | Animation? | **0** (grep NONE, chỉ spinner). Thiếu: transition đổi màn, list insert/remove, sheet, state-change, micro-interaction |
| 7 | Responsive iPhone? | cấu trúc TỐT (NavigationSplitView collapse, maxWidth:.infinity, 0 fixed frame). Rủi ro chưa verify: split-view iPhone compact, composer/sheet màn nhỏ. Chưa audit từng màn iPhone thật |
| 8 | A11y ảnh hưởng nếu chuẩn hóa? | KHÔNG nếu qua semantic. Phải GIỮ: accessibilityLabel (MessageRow M8-6), SecureField, LabeledContent, semantic font. Ràng buộc: không hardcode size/màu |
| 9 | Cần framework? nhỏ nhất? | **KHÔNG framework/engine.** Nhỏ nhất = `Shared/DesignSystem/` hằng số (enum Spacing/Radius) + ViewModifier (`.osirisCard()`) + Assets.xcassets (accent+icon). Constants+modifier, không Theme/Style/Component Manager |
| 10 | Sau M9 khác gì? | nhất quán · rõ ràng · hiện đại (animation+bản sắc) · responsive thật 3 nền tảng · vẫn nhanh & accessible → quên đây là dự án kỹ thuật |

**Quyết định kiến trúc M9 (KHÔNG ADR mới — chỉ hướng thực thi):** giải pháp nhỏ nhất = **`Shared/DesignSystem/` = data + ViewModifier**, tuyệt đối KHÔNG Theme/Design/UI/Animation/Component/Style Engine/Manager/Framework. Reusable component chỉ tạo khi có bằng chứng duplication (Q4 đã có). Không redesign toàn bộ, không viết lại app. Chuẩn hóa qua semantic để không hỏng a11y/Dynamic Type/dark-mode đã có.

**Đề xuất M9-1 (chờ USER xác nhận — KHÔNG tự mở):** bước **Consistency #1** — tạo `Shared/DesignSystem/` token spacing+radius (data) + 1–2 ViewModifier chuẩn hóa card/button (bằng chứng Q4), áp dụng vào view hiện có. KHÔNG animation (ưu tiên #5, sau), KHÔNG redesign. Zero regression a11y (giữ mọi label/SecureField/LabeledContent).

**Chất lượng M9-0:** 0 dòng code · 0 test đổi · suite giữ **164 test / 2 opt-in skip / 0 fail** · $0.00. Deliverable = bằng chứng + hướng nhỏ nhất, đánh giá bằng trải nghiệm không phải dòng code.

## 4s. Provider contract transport — system channel (issue identity/localization ĐÓNG, 2026-07-05)

**Architecture Review (8 câu, bằng chứng code + API) — quyết định đổi CÓ bằng chứng, không suy luận:**
- **Q1–3:** `AIProvider.complete(prompt:modelID:)` = 1 chuỗi; Gateway ghép `preamble+context+task` → gửi; `AnthropicProvider` map `messages:[{role:"user"}]`, **bỏ trống field `system`** dù API có.
- **Q4 (bằng chứng API, 8/8 provider):** Anthropic `system` · OpenAI `role:system`/`developer` + Responses `instructions` · Gemini `systemInstruction` · Grok/Mistral/Qwen/DeepSeek OpenAI-compat `role:system` · Llama chat-template + OpenAI-compat `role:system`. **Mọi provider có system channel riêng, hierarchy MẠNH HƠN user.**
- **Q5:** gửi preamble bằng user-message = **SAI kiến trúc** — (a) system > user ở mọi provider; (b) **test thật cho thấy model phớt lờ "You are OSIRIS" ở user-role**. Bằng chứng đủ → đổi.
- **Q6–8:** không phá abstraction (vẫn agnostic) · Gateway không phức tạp thêm (vẫn nơi ghép duy nhất) · không sửa từng provider (default lo) · **0 AD vi phạm** (AD-24 Gateway-ghép giữ; AD-13/23 preamble-1-Config giữ, nay đúng hơn = system prompt; AD-15 token giữ) · mở rộng `complete(systemPrompt,userPrompt)` provider-agnostic được · **cải tiến transport CHUNG, không fix riêng Claude**.

**Refactor NHỎ NHẤT (thiết kế then chốt = default method → 0 churn test):**
- `AIProvider`: +requirement `complete(systemPrompt:userPrompt:modelID:)` **CÓ default** = concat y nguyên hành vi cũ → **21 test double + Placeholder: 0 sửa** (kế thừa default). Vì là requirement (không phải extension-only) → dynamic dispatch đúng cho provider override.
- `AnthropicProvider`: override → `systemPrompt`→field `system` (encodeIfPresent, rỗng thì bỏ field), `userPrompt`→user message; `complete(prompt:)` delegate `system:""`.
- `DefaultAIGateway`: tách `assembleUserPrompt` (body, không preamble) khỏi `assemblePrompt` (full = preamble+body, GIỮ cho token/cache/trim byte-identical); 1 call-site đổi sang `complete(systemPrompt: preamble, userPrompt: body)`.
- Test: chỉ `AnthropicProviderIntegrationTests` đổi — khẳng định preamble ở `system`, task ở user message, contract KHÔNG rò vào user.

**Ràng buộc:** 0 Persona Engine · 0 Prompt Builder mới · 0 Provider Wrapper mới · 0 abstraction thừa · 0 `if provider==`. Gateway vẫn nơi ghép DUY NHẤT · preamble vẫn 1 Config DUY NHẤT.

**Chất lượng:** 4 file (3 prod + 1 test) · **164 test / 2 opt-in skip / 0 fail** · release 0 warning · budget/cache byte-identical (mọi test cũ pass không sửa) · $0.00.

**ĐÓNG ISSUE (kiến trúc):** identity + localization nay hoàn chỉnh 2 lớp — **content** (§4r luật preamble) + **transport** (§4s system channel, provider-agnostic). Không còn lever kiến trúc nào nữa: nếu model vẫn lệch sau khi USER test key thật, chỉ tinh chỉnh CHỮ trong `Config/preamble.md` (data, 1 chỗ) — không phải đổi kiến trúc. Trigger "system-role transport" ở §4r = ĐÃ GIẢI QUYẾT.

## 4r. Provider behaviour contract — identity + language (2026-07-05)

**Bối cảnh:** test thật của USER — hỏi tiếng Việt, OSIRIS trả lời tiếng Anh + tự nhận "I am Claude… Current Model: Claude 3.5 Sonnet". Vi phạm mục tiêu OSIRIS. Yêu cầu: giải pháp cho MỌI provider (Claude/OpenAI/Gemini/Grok/DeepSeek/Qwen/Mistral/Llama…), KHÔNG `if provider==`, KHÔNG hardcode model.

**Architecture Review (8 câu, bằng chứng) — tóm tắt:** identity OSIRIS đã nêu ở `preamble` nhưng **thiếu 2 luật**: (a) ngôn ngữ, (b) kỷ luật-identity. Prompt gửi provider = `preamble + context + task` (một chuỗi, `AnthropicProvider` gửi role `user`). Contract hành vi sống ở **preamble** (AD-13/23) — provider-agnostic, Gateway prepend cho mọi provider. **→ Đây là lỗ hổng CONTENT của contract, KHÔNG phải bug code Gateway/provider, KHÔNG per-provider.** Model tự nhận Claude vì bị hỏi thẳng mà không có luật cấm + không có luật ngôn ngữ → default English + factory persona. (Ghi chú: model tự báo "3.5 Sonnet" trong khi catalog dùng haiku → self-report của model KHÔNG đáng tin; nguồn model thật = metrics/UI của OSIRIS.)

**Sửa MỘT chỗ (data, provider-agnostic):** `Config/preamble.md` +2 luật:
- **7 (ngôn ngữ):** "Reply in the same language the user writes in, unless they request another."
- **8 (identity):** "You are OSIRIS. Do not volunteer that you are any particular AI model or company… Discuss the underlying model/provider only when the user directly asks or for debugging — then be truthful: never invent a model name/version, never state a falsehood to maintain the persona. If asked who you are, answer as OSIRIS."

Thỏa mọi ràng buộc contract USER nêu: ngôn ngữ user · default identity OSIRIS · không chủ động khai model/hãng · minh bạch khi hỏi thẳng · không nói sai để giữ persona.

**Regression test (Linux):** `ShippedConfigurationTests.testShippedPreambleCarriesIdentityAndLanguageContract` — pin preamble chứa OSIRIS + luật ngôn ngữ + cấm-khai-model + trung-thực-khi-hỏi-thẳng. Token budget (≤`preambleMaxTokens`) vẫn pass → preamble mở rộng vẫn trong ngân sách.

**KHÔNG làm (đúng ràng buộc):** 0 Persona Engine / Identity Manager / Localization Engine / Provider Wrapper · 0 abstraction · 0 code · 0 `if provider==`. Mở rộng contract có sẵn, đúng một chỗ.

**Trigger đã ghi (chưa làm — chỉ khi bằng chứng):** preamble đi ở **user-role**, không phải **system-role**. Content-fix là điều kiện cần; nếu USER test lại với key thật mà model VẪN không tuân → nâng transport sang system-role (đổi protocol `AIProvider` để tách system/task — abstraction lớn hơn, chỉ làm khi có bằng chứng content-fix chưa đủ).

**Chất lượng:** 0 code · 1 file data (`preamble.md`) + 1 test · **164 test / 2 opt-in skip / 0 fail** · preamble trong token budget · $0.00. **Runtime obedience = USER test lại với key thật** (điều kiện đủ nằm ở model, không verify được trên Linux).

## 4q. M8-6 Closeout — Accessibility audit (2026-07-05)

**Architecture Review (audit cái đã tồn tại, không redesign UI, không tạo Accessibility Engine/Manager/abstraction).** SwiftUI a11y = modifier inline trên view có sẵn.

**Ràng buộc trung thực:** môi trường dev = **Linux, không Mac/Xcode/VoiceOver** → không chạy app được. Audit làm ở **cấp SOURCE** (bằng chứng code, quan sát được thật); phần chỉ-quan-sát-lúc-chạy giao **checklist runtime cho USER** trên Mac.

**Kết quả audit 10 view Presentation — app đã tốt sẵn (bằng chứng code):**
| Hạng mục | Bằng chứng code | KL |
|---|---|---|
| VoiceOver labels | mọi control có text (`Label(text,…)`) hoặc `.accessibilityLabel` (3 icon-only: send/save/deliverable); Dashboard dùng `LabeledContent` | ✅ tốt |
| Icon-only controls | `plus.circle.fill`/`arrow.up.circle.fill`/`doc.text` đều có `.accessibilityLabel` | ✅ |
| Dynamic Type | 0 `.font(.system(size:))` cứng — toàn semantic (`.title2/.caption/.callout/.subheadline`) → scale | ✅ |
| Sheet/Dialog | `.alert` New Project + `.sheet` Deliverable = native (NavigationStack, title) | ✅ native |
| Sidebar navigation | `NavigationSplitView` + `List(selection:)` + `Label` có text → native keyboard/focus | ✅ native |
| Key field | `SecureField` (masked, VoiceOver không đọc secret) | ✅ (cả security) |
| Status line | `ExecutionStatusView` `.accessibilityElement(children: .combine)` | ✅ |

**1 lỗi THẬT đã sửa (bằng chứng code, diff nhỏ nhất):**
- `MessageRow` (ChatView): sender user/OSIRIS chỉ báo bằng **màu nền + căn lề (Spacer)** — `message.role` chỉ dùng cho styling, KHÔNG có text a11y. VoiceOver đọc chuỗi message text không phân biệt được ai nói. → thêm 1 dòng `.accessibilityLabel("\(You/OSIRIS): \(text)")`. **0 redesign, 0 abstraction, 0 type mới.**

**Regression test:** KHÔNG khả thi — Presentation là Xcode-only (không trong SPM test target); tách `role→text` thành helper testable = tạo abstraction (bạn cấm) cho một ternary. → verify qua **CI macOS compile** + **VoiceOver runtime của USER**. (Nhất quán giới hạn Keychain M8-1.)

**Checklist RUNTIME cho USER (trên Mac — chỉ quan sát được lúc chạy):**
1. **VoiceOver** (⌘F5): duyệt sidebar → Chat/Search/Dashboard/Automation/Settings đọc đúng tên; gõ goal → transcript đọc "You: …" / "OSIRIS: …" (fix M8-6).
2. **Keyboard nav / focus order**: Tab qua composer → send; sidebar ↑↓; sheet/alert focus vào field đầu, Esc đóng.
3. **Dynamic Type**: Settings → text lớn nhất → UI không vỡ/cắt (kỳ vọng OK vì semantic font).
4. **Color contrast**: message bubble (accent .opacity(0.15) / quaternary .opacity(0.5)) + secondary/tertiary text — kiểm bằng Accessibility Inspector Contrast; nếu < WCAG AA, dán số cho tôi (fix = tăng opacity/đổi style, diff nhỏ).
5. **Icon-only**: VoiceOver trên nút gửi/lưu/xoá/run đọc đúng nhãn.
> Nếu bước nào lỗi → dán quan sát cho tôi (như CI errors); sửa diff nhỏ nhất. Không lỗi → runtime coi như pass.

**Chất lượng:** production diff = 1 dòng + comment (Presentation, CI-macOS verify) · SPM suite không đổi **163 test / 2 opt-in skip / 0 fail** · 0 abstraction/type mới · AI spend **$0.00**.

## 4p. M8-5 Closeout — Production Readiness Milestone Review (nghiệm thu core, tag `M8`, 2026-07-05)

**Architecture Review (đối chiếu bằng chứng, không tính năng mới, không ADR mới — chỉ tổng kết).** Đối chiếu từng hạng mục M8 (DEVELOPMENT_PLAN §2/M8) với code + test + docs:

| Hạng mục M8 | Bằng chứng | Đủ Production? |
|---|---|---|
| **Test coverage cho Core contracts** | M8-0: audit + 2 test canh property thật (dry-run cache poison, `.anyWord` ranking); 163 test tổng, mọi public protocol có test | ✅ ĐỦ |
| **Performance review** | M7-0 §4j: baseline nội bộ thật (search 1–7ms scale thật, pipeline ~3.8ms); M8-5 đo lại **fresh 4.07 / reuse 2.52 ms — no-regression** dù M8-3 đổi reuse | ✅ ĐỦ (nội bộ). Provider-side tối ưu = evidence-gated (key) |
| **Security review** | M8-1 §4l: SỬA Keychain accessibility (device-only); test canh "error không lộ key/body"; key chỉ header, log metrics-only, 0 hardcoded secret | ✅ ĐỦ (App-layer verify qua CI macOS) |
| **Backup & Recovery** | M8-2 §4m: atomic write, restore = copy thư mục Store, migration versioned + test; **no-hole** | ✅ ĐỦ |
| **Crash recovery (không mất tiến độ)** | M8-3 §4n: SỬA lỗ hổng reuse-trả-process-note; data-trước-index; state sống sót restart (test); in-flight = re-run an toàn | ✅ ĐỦ (criterion "crash → không mất trạng thái" ĐẠT) |
| **Documentation** | M8-4 §4o: sửa 5 lỗi doc có bằng chứng (harness compile-được, docs phản ánh AD-46/47) | ✅ ĐỦ |
| **Accessibility audit** | CHƯA làm — cần Mac/simulator + a11y harness (VoiceOver/Dynamic Type là runtime UI, không verify được trên Linux) | ⚠️ **CHƯA ĐỦ — evidence-gated** |

**Definition of Done (§3) — 8/8 ✅:** feature qua Verify · kiến trúc sạch (18 arch test) · PROJECT_STATE cập nhật · docs cập nhật · test contract quan trọng · token review (no-regression) · nợ phân loại Critical=0 · next work ghi.

**Dead-code scan (bằng chứng — chỉ xóa nếu chết rõ):** quét public symbol + switch + marker → **KHÔNG có dead code để xóa.** `ResponseCache`/`Reflection`/`ComplexityEstimate`/`TokenEstimator`… đều có consumer; 0 TODO/FIXME. `StoreSearchResult.Kind.projectState` không được search PRODUCE nhưng được switch CONSUME (defensive/exhaustive) — không phải dead-code có hại, xóa = đổi public contract vô ích → GIỮ. Dead-code thật (EventBus/ApprovalGate) đã xóa ở M4-4/M6-0.

**Arch ban-list — asymmetry CÓ CHỦ Ý (không sửa):** `testEliminatedComponentsAreNotRecreated` cấm EventBus (AD-46) + automation-engine (AD-47) nhưng KHÔNG cấm ApprovalGate — đúng: AD-47 nói gate **tái sinh cùng risky action thật đầu tiên** (cấm sẽ tạo tripwire cho tính năng dự kiến), khác EventBus (return khó xảy ra). Không thêm ban.

**Nợ còn lại + evidence-gated (bằng chứng, có địa chỉ):**
- **Accessibility audit** — cần Mac/a11y harness. *Chưa đủ Production vì:* chưa verify VoiceOver/Dynamic Type/contrast trên thiết bị.
- **M7 provider-side optimization** — cần key thường trực (baseline qua-Gateway nhiều sample). Nội bộ đã tối ưu-đủ (no-regression); provider-side chưa đo → chưa tối ưu.
- **Scheduled automation (BGTask) + MCP/tool-channel** — HOÃN từ M6 (AD-45/47), chờ use case + consent + thiết bị.
- **Trigger nhỏ (Low, không chặn Production):** Keychain on-device check; `.atomic` fsync; Store-level dangling-path test; migration-discipline rule; reuse `limit:10` starvation. Tất cả có trigger, chỉ làm khi có bằng chứng.

**Đủ điều kiện Production (core):** Core 6 + Application + 3 module + persistence crash-safe + security hardened + provider thật (validate Mac §4i) + offline placeholder. 163 test / 2 opt-in skip / 0 fail · release 0/0 · $0.00.
**Chưa đủ (lý do):** Accessibility (chưa audit thiết bị) · UX thật trên thiết bị lâu dài (mới smoke §4i) · provider-side cost/latency chưa tối ưu (chưa có baseline key).

**Kết luận: M8 CORE NGHIỆM THU** — completion criterion ("crash → mở lại không mất trạng thái" + DoD) ĐẠT bằng bằng chứng. Accessibility là hạng mục M8 SCOPE duy nhất chưa làm, evidence-gated rõ ràng (nhất quán cách M6 tag core với phần device-gated). Tag `M8` = production-readiness core code-complete. **Không ADR mới (chỉ tổng kết), 0 dòng code đổi (chỉ 1 sửa số liệu doc 19→18).**

## 4o. M8-4 Closeout — Documentation review (2026-07-05)

**Architecture Review (audit tài liệu, chỉ sửa cái có bằng chứng sai/lỗi thời — không viết lại vì diễn đạt, không tạo doc mới).** Rà toàn bộ docs sống, cross-check tuyên bố kiểm chứng được với code. **Phân biệt then chốt:** doc tự khai "trạng thái hiện tại" (SYSTEM_COMPONENTS "danh mục chính thức, chỉ thành phần trong file được tồn tại"; MODULE_GUIDE how-to; RUNBOOK guide) → PHẢI đúng hiện tại → sửa; doc roadmap (DEVELOPMENT_PLAN) + lịch sử bất biến (ADR trong BLUEPRINT, checklist milestone trong PROJECT_STATE) → giữ nguyên.

**5 lỗi có bằng chứng đã sửa (diff nhỏ nhất, thuần factual):**
| # | File | Lỗi (bằng chứng) | Sửa |
|---|---|---|---|
| 1 | `MODULE_GUIDE.md` khung test | `approvalGate: RequireUserApprovalGate()` — type + param đã XÓA (AD-47), `Kernel.init` không còn param này → **contributor copy harness sẽ KHÔNG compile** | bỏ arg; harness giờ khớp `DeliverablePersistenceTests` |
| 2 | `MODULE_GUIDE.md` §9 list cấm | liệt kê `EventBus` — type đã XÓA (AD-46) | bỏ khỏi list |
| 3 | `SYSTEM_COMPONENTS.md` §2.1 | "thực thi approval gates cho hành động rủi ro (publish/delete/…)" present-tense — ApprovalGate đã XÓA (AD-47); doc này tự khai "danh mục hiện tại" và đã đánh dấu EventBus xóa ở §111 nhưng bỏ sót ApprovalGate | ghi rõ "hiện KHÔNG có, xóa M6-0/AD-47, tái sinh cùng risky action thật" |
| 4 | `SYSTEM_COMPONENTS.md` §5 | "đếm bằng chứng cho quyết định EventBus tại M4 review" — **mâu thuẫn chính dòng 111 cùng file** (đã ghi XÓA tại M4-4) | phản ánh quyết định đã ra: XÓA (AD-46) |
| 5 | `RUNBOOK_M1-0.md` | `swift test # kỳ vọng: 49/49` — nay 163 test | count-agnostic ("toàn bộ PASS, tăng theo milestone") |

**KHÔNG sửa (có lý do bằng chứng):**
- `DEVELOPMENT_PLAN.md` (approval-gate ở M1/M6 criteria): là **roadmap/intent**; AD-47 HOÃN gate (tái sinh cùng risky action), không bỏ khái niệm → không sai. PROJECT_STATE §4h đã đối chiếu.
- ADR trong `PROJECT_BLUEPRINT §3` + checklist milestone trong `PROJECT_STATE` (M2-4 "EventBus 2 consumer", M1 "ApprovalGate wired") = **lịch sử bất biến** (AD-14): ghi đúng cái đã đúng LÚC ĐÓ; deletion ghi sau tại §4h/AD-46/47. Sửa = viết lại lịch sử.
- ADR log đôi (PROJECT_STATE §5 quick-ref ↔ BLUEPRINT §3 detail): quan hệ index→detail (§5 tự ghi "chi tiết tại BLUEPRINT §3"), không phải dual-source-of-truth drift → giữ.
- `FOLDER_STRUCTURE.md` (Shared/DesignSystem… chưa tồn tại): doc tự khai là **cấu trúc CHUẨN/convention** (nơi thứ sẽ nằm khi có), không phải trạng thái hiện tại → không sai.

**Chất lượng:** 0 dòng code · 0 doc mới · 3 file docs / 5 sửa factual · suite không đổi **163 test / 2 opt-in skip / 0 fail** · harness guide giờ compile-được (tương đương test đã ship) · AI spend **$0.00**.

## 4n. M8-3 Closeout — Crash Recovery review: TÌM & SỬA 1 lỗ hổng (2026-07-05)

**Architecture Review (chỉ đổi khi có bằng chứng — không checkpoint/transaction/journal/recovery-manager/state-machine).** Vòng đời Kernel chỉ persist ở cuối (data-trước-index, §4m); mid-goal chỉ có 1 ghi sớm = memory note qua WriteGate. Đào theo 6 điểm crash → **phát hiện 1 lỗ hổng correctness+crash thật.**

**Lỗ hổng (bằng chứng code, đã tái hiện bằng test):** `Kernel.reusableResult` search `.exact` (limit 1), thứ tự walk knowledge→**WorkingContext**→deliverable. HAI loại note WC **nhúng goal verbatim**: assumption medium-confidence (`"Assumption (medium confidence)… \"<goal>\""`) và reflection (`Reflection.swift:31` `"Recently completed: <goal> — deliverable at <path>"`). Cả hai match exact goal và được walk TRƯỚC deliverable → **run thứ 2 / crash-resubmit trả về NOTE thay vì deliverable thật, và bỏ làm lại việc thật** (mất dữ liệu: deliverable thật không được tạo). Production reachable: `makeWritePolicy()` admit `.reusableLater`. *(Bị che trong test cũ: dùng gate `.disabled` + goal 3 từ né reflection ≥4 từ.)*

**Fix (diff nhỏ nhất, khu trú trong Kernel — vai trò decider hợp lệ):**
- **Fix A (`reusableResult`):** reuse CHỈ trả created-result thật (`.deliverable`/`.knowledge`); bỏ qua `.workingContext`/`.projectState` (process-note, không phải câu trả lời). Miss → re-run (an toàn). Aligns reuse với đúng mục đích của nó.
- **Fix B (ghi assumption):** chỉ ghi khi KHÔNG reuse (`!isReuse`). Trước đây assumption ghi mọi run kể cả reuse, id UUID mới mỗi lần → tích luỹ duplicate không giới hạn; nay chỉ 1 lần/goal.

**Regression test:** `CrashRecoveryReuseTests.testReRunReusesDeliverableNotProcessNoteAndDoesNotDuplicate` — gate production-shaped, goal medium ≥4 từ (ghi cả 2 note), run 2 lần → khẳng định trả deliverable thật (không phải note) + provider gọi đúng 1 lần (reuse, không duplicate) + assumption count = 1. **Đã chứng minh test FAIL nếu revert Fix A** (trả "Recently completed: …" thay vì deliverable) → test có ý nghĩa, không tautology.

**6 điểm crash — kết luận sau fix:**
| Điểm | Kết luận |
|---|---|
| Kill giữa goal (trước Persist) | ✅ chưa persist gì (trừ note self-expiring) → resubmit chạy mới, không rác (nhờ Fix A) |
| In-flight execution | ✅ Kernel không persist "executive state" (AD-08); engine không chạm Store |
| Mở lại project sau crash | ✅ ProjectState là file độc lập, restart tests |
| Deliverable ghi dở | ✅ atomic write (§4m) — không file cụt |
| Store consistency | ✅ data-trước-index → tệ nhất orphan vô hình (§4m) |
| Không duplicate/mất dữ liệu | ✅ Fix A (không rác + không bỏ làm lại) + Fix B (không tích luỹ note) |

**Trigger đã ghi (không sửa — residual an toàn):** `reusableResult` dùng `limit:10`; nếu MỘT goal medium bị re-run rất nhiều lần trong TTL, note WC tích luỹ có thể đẩy deliverable (walk cuối) ra ngoài top-10 → reuse MISS (re-run an toàn, không rác). Fix B đã giảm mạnh (assumption không tích luỹ; reflection không ghi trên reuse) → thực tế chỉ ~1 assumption + ~1 reflection/goal, dưới 10 xa. Chỉ siết (kind-restricted search ở Store API) nếu có bằng chứng starvation thật.

**Chất lượng:** build 0/0 · **163 test / 2 opt-in skip / 0 fail** ~1.1s · production diff = 2 sửa nhỏ khu trú Kernel + 1 test · arch suite nguyên · AI spend **$0.00**.

## 4m. M8-2 Closeout — Backup & Recovery review: KHÔNG lỗ hổng (2026-07-05)

**Architecture Review (audit-only, chỉ đổi khi có bằng chứng lỗ hổng — không thiết kế trước cloud/version/snapshot/replication/backup-manager).** Kết luận: **backup & recovery đã sound, đủ test; 0 dòng đổi.** Bằng chứng theo 6 ưu tiên:

| Ưu tiên | Bằng chứng | Kết luận |
|---|---|---|
| **Store durability** | file-per-record qua `FileStorage`; sống sót restart | ✅ đạt |
| **Atomic write** | `FileStorage.write` dùng `Data.write(options:.atomic)` (temp+rename) — atomic mức record | ✅ đạt |
| **Recovery sau restart** | `testProjectStateSurvivesRestart`, `testRuleSurvivesRestartAndListsSorted`, `testSearchFindsKnowledgeAcrossRestart…` | ✅ có test |
| **Restore toàn bộ project** | thư mục Store LÀ project đầy đủ (ProjectState + index deliverable NẰM TRONG nó + knowledge + working-context + file deliverable, đều plain file); không có DB/index ngoài để lệch. Backup = copy thư mục; restore = copy lại. `DeliverablePersistenceTests(a)` round-trip | ✅ đạt — **không cần manager/engine** |
| **Cross-record consistency** | thứ tự persist **data-trước-index**: Kernel ghi file deliverable trước (`saveDeliverable`, Kernel:125) rồi mới lưu ProjectState (Kernel:132). Crash giữa chừng → tệ nhất là **orphan vô hình** (file chưa được index — vô hại), KHÔNG bao giờ dangling pointer. Read bỏ qua file thiếu (`search` FileBackedStore:152 `guard let data … else continue`; `deliverableContent` trả nil:106; `ProjectOverviewTests.testMissingBodiesAreSkippedNotFailed`). Deliverable không có API xoá → path không dangle do xoá | ✅ an toàn theo thiết kế + test (Application-level) |
| **Migration safety** | `ProjectState` có custom decoder versioned: `decodeIfPresent(name) ?? projectID` → store pre-M2 (thiếu `name`) migrate im lặng, **có test** `testLegacyStateWithoutNameMigratesSilently` | ✅ đạt |

**Không sửa gì (không có lỗ hổng) — nhưng ghi 3 TRIGGER (chưa làm, không suy đoán):**
1. **Durability sâu:** `.atomic` = temp+rename (atomic cùng volume) nhưng KHÔNG `F_FULLFSYNC` → mất mát lý thuyết nếu mất điện trước khi OS flush. Chấp nhận cho local single-user iOS; hardening = suy đoán → chỉ thêm khi có bằng chứng mất dữ liệu thật.
2. **Store-level dangling-path test:** `FileBackedStore.search` bỏ qua deliverable path thiếu ĐÚNG nhưng chỉ được test gián tiếp ở Application-level (ProjectOverview dùng mock), chưa test trực tiếp ở Store thật. KHÔNG phải lỗ hổng (hành vi đúng) → ứng viên regression guard nếu sau này siết.
3. **Migration discipline:** quy tắc "field mới phải `decodeIfPresent`/có default" đang áp per-field (đúng cho `name`), chưa có rule/test-helper cưỡng chế. Field bắt buộc thêm sau này mà quên → vỡ decode dữ liệu cũ (và qua `loadAll` compactMap-throw sẽ brick bulk read — nối với finding §4k). Hiện KHÔNG vi phạm → ghi trigger, không sửa.

**Chất lượng:** 0 dòng production/test đổi (đúng khung "no-hole → document + dừng") · **162 test / 2 opt-in skip / 0 fail** không đổi · AI spend **$0.00**.

## 4l. M8-1 Closeout — Security review (2026-07-05)

**Architecture Review TRƯỚC code (chỉ đổi khi có bằng chứng codebase):** audit toàn bộ đường đi secret (lưu trữ → dùng → mọi đường log).

**1 lỗ hổng THẬT đã sửa:**
- **Keychain thiếu `kSecAttrAccessible`** (`KeychainSecretsVault.baseQuery` → item lấy default OS, KHÔNG `ThisDeviceOnly` → API key phục hồi được sang máy khác qua encrypted backup — sai với secret device-local tính tiền vào tài khoản user). Bằng chứng: đọc code + hành vi mặc định Apple documented. **Sửa:** đặt `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` **chỉ trên đường ADD** (không nhét vào search query — sẽ vỡ matching read/update/delete). Device-only + loại khỏi backup/iCloud; `AfterFirstUnlock` = đọc được sau lần mở khoá đầu, không kẹt khi app nền. *App-layer (Security framework) → CI macOS compile-verify; `swift test` Linux không chạm được.*

**1 hợp đồng bảo mật ĐÃ TÀI LIỆU nhưng CHƯA có test → thêm test (Linux-verified):**
- `AnthropicProvider` doc ghi "errors NEVER contain the API key or response bodies" nhưng 0 test canh. `AnthropicProviderSecurityTests.testProviderErrorNeverContainsKeyOrResponseBody`: URLProtocol stub trả 401 với body **cố tình echo key** (worst case) → khẳng định error (và hint) KHÔNG chứa key/body. Regression gập key vào log/UI sẽ đỏ ngay.

**Verify SẠCH — không đổi (audit ghi bằng chứng):**
- Provider gửi key CHỈ ở header `x-api-key` (line 51), không bao giờ ở URL; error enum chỉ mang `Int + hint tĩnh` (không key/body by construction).
- Logging: `DefaultAIGateway` log metrics-only (đã có test canh prompt-absence, line 99); Gateway KHÔNG giữ key (key sống ở provider). `ConsoleLogger` generic — an toàn nhờ kỷ luật call-site (Gateway kỷ luật).
- 0 hardcoded secret toàn repo (`grep` sạch); Config/*.json không chứa secret (chỉ số budget/model).

**Trigger đã ghi (chưa làm — không suy đoán):** hành vi `KeychainSecretsVault` (accessibility thật, read/write/delete) chỉ verify được on-device/simulator; thêm on-device check khi có harness UI/device test. Nếu M6 background firing (BGTask) hồi sinh và cần đọc key lúc khoá → xem lại mức accessibility (hiện `AfterFirstUnlock` đã hỗ trợ nền sau first-unlock).

**Chất lượng:** build 0/0 · **162 test / 2 opt-in skip / 0 fail** ~1.1s · production đổi = 1 dòng+comment App-layer (0-warning, CI-macOS-compiled) · arch suite nguyên (test chỉ THÊM) · 0 rò rỉ key (đã quét) · AI spend **$0.00**.

## 4k. M8-0 Closeout — Core contract test coverage (2026-07-05)

**Bối cảnh:** user chấp nhận M7-0, chọn "tiếp tục theo NEXT_TASK" + đã khoá key → Đường A (M7 provider-side) cần key thường trực nên bất khả thi → đường khả thi = **Đường B, task M8 đầu tiên: Core contract test coverage** (Linux, không key, chỉ THÊM test).

**Architecture Review TRƯỚC code (kỷ luật "chỉ đổi khi có bằng chứng"):**
- Khảo sát 7 public protocol Core + ~140 test → coverage đã rộng. **Nhồi test cho đủ số = over-engineering → từ chối.** Chỉ vá lỗ hổng THẬT có bằng chứng.
- **Góc crash-recovery (phạm vi M8):** `FileStorage.write` dùng `.atomic` → crash giữa chừng để lại file cũ nguyên vẹn, KHÔNG bao giờ file cụt. Vector crash-corruption **đã đóng sẵn**. → Sửa `loadAll` cho "resilient skip file hỏng" lúc này = **suy đoán** (chống đường mà atomic đã chặn) → **HOÃN** (ghi trigger: chỉ thêm khi có bằng chứng file hỏng thật, vd bit-rot/sync-conflict, không phải crash).
- **Tìm được 2 property production-quan-trọng nhưng CHƯA có test canh (thêm test không đổi hành vi):**
  1. **Dry-run KHÔNG được đầu độc cache** — `DefaultAIGateway` bước 5a chỉ có comment "would poison the cache", không test canh. Regression → phục vụ "[dry-run]…" như câu trả lời thật. → `testDryRunDoesNotPoisonCache` (chung 1 cache instance qua gateway dry-run + gateway thật, cùng task; rò rỉ = cache-hit trên call thật).
  2. **Ranking `.anyWord`** (hits desc, tie-break theo thứ tự walk = id tăng, tôn trọng limit) — chỉ được perf-test (§4j đo tốc độ), CHƯA test tính đúng. Ranking này nuôi Gateway context retrieval (`retrieveContext` search `.anyWord`) → quyết định context AI thấy. → `testAnyWordSearchRanksByHitCountThenStableOrder`.

**Quyết định:** thêm ĐÚNG 2 test cho 2 lỗ hổng có bằng chứng; **từ chối** đổi resilience suy đoán; **0 dòng production đổi.** Đúng mẫu M7-0: audit → vá lỗ hổng thật → từ chối suy đoán → ghi trigger.

**Chất lượng:** build 0/0 · **161 test / 2 opt-in skip / 0 fail** ~1.0s offline · diff chỉ test (production 0-warning nguyên) · arch suite nguyên (chỉ THÊM test, không nới) · CI macOS không ảnh hưởng (không chạm Presentation/App) · AI spend **$0.00**.

**Còn mở trong M8 (chờ USER chọn task kế — không tự mở):** Performance review (đã có baseline §4j/§4b) · Security review (API key/dữ liệu) · Backup & Recovery · Crash recovery (write đã atomic — phần còn lại: khôi phục tiến độ dở) · Docs · Accessibility. Store-resilience có trigger riêng ở trên.

## 4j. M7-0 Closeout — Đo baseline nội bộ, quyết KHÔNG tối ưu (2026-07-05)

**Bối cảnh:** user chọn "mở M7 ngay, không key". M7 cấm tối ưu-không-số-liệu (đoán = churn = vi phạm hiến pháp). Vì container fresh không có Swift, tôi **cài toolchain Swift 6.3.3 trên Linux** để đo thật (không đoán). 158→159 test vẫn xanh trên 6.3.3.

**Đối tượng đo — `Store.search` đọc-lại-toàn-bộ-file mỗi query** (ứng viên số 1 suốt M1→M6, comment code tự ghi "measured optimization belongs to M3/M7"). Harness mới `StoreSearchBaselineTests` (opt-in `OSIRIS_SEARCH_BASELINE=1`, không nặng suite mặc định) seed Knowledge tăng dần, đo mean 20 query, release mode:

| Store size | `.exact` (early-exit) | `.anyWord` (đi hết, worst case) |
|---|---|---|
| 100 records | ~1.3 ms | ~1.5 ms |
| 500 records | ~6.7 ms | ~7.5 ms |
| 2000 records | ~28 ms | ~30 ms |

Cộng baseline pipeline-overhead (đo lại 6.3.3, release): **fresh ~3.8 ms/goal · reuse ~3.4 ms/goal**.

**Đọc số liệu — trung thực:**
- Tuyến tính O(n) đúng như dự đoán code — NHƯNG hằng số tí xíu và **N thật rất nhỏ**. Knowledge = "cách hệ thống hoạt động", một-người-dùng, đời-app chỉ hàng-chục→trăm bản; WorkingContext có TTL (nhỏ); Deliverable KHÔNG bị walk toàn cục (search chỉ đọc theo `ProjectState.deliverablePaths` của project hỏi — AD-10 index). Ở quy mô thật (≤ vài trăm bản) search = **1–7 ms, không cảm nhận được**.
- Path nội bộ (pipeline + search) đều **đơn-con-số ms**. Một AI call thật (mạng) = hàng-trăm ms→giây → **áp đảo toàn bộ overhead nội bộ ~100×**. Bề mặt tối ưu thật là **provider-side (token/latency/cost)** — đúng thứ CHẶN bởi key.

**Quyết định: 0 tối ưu code trong M7-0.** Đo rồi, số liệu nói "chưa cần". Ship optimization bây giờ = premature = vi phạm chính nguyên tắc M7. **Deliverable của M7-0 = hạ tầng đo lặp-lại-được + số liệu thật + quyết định không-churn** — đây là kỷ luật M7 hoạt động đúng, không phải milestone rỗng.

**Trigger tái xét (ghi rõ để lần sau không đoán lại):** đụng lại `Store.search` chỉ khi (a) store thật > ~1000 Knowledge record, HOẶC (b) profiling latency thật cho thấy search chiếm phần đáng kể. Khi đó: in-memory index/cache theo key + giữ nguyên test hành vi (hits/ranking/tie-break) — đã có `StoreSearchBaselineTests` để chứng minh trước/sau.

**Baseline provider THẬT — đo 2026-07-05 (nợ Medium ĐÓNG một phần):** user cấp key tạm (đã khoá ngay sau đo), chạy `LiveBaselineTests` (haiku `claude-haiku-4-5-20251001`, gọi thẳng provider, `maxOutputTokens=300`):

| Prompt | tokensIn | tokensOut | latency |
|---|---|---|---|
| short (tóm tắt 1 câu) | 21 | 35 | 7.62 s |
| medium (mô tả SP ~150 từ) | 28 | 207 | 2.98 s |

Chi phí ≈ **$0.0013 / 2 call** (haiku $1/$5 per 1M — cost accounting đã xác minh offline từ M0). **Đọc trung thực:** (a) tokensIn rất nhỏ (21–28) vì harness gọi thẳng `AnthropicProvider` với prompt trần — CHƯA qua Gateway assembly (preamble + context), nên đây là sàn token provider, không phải token/goal thực tế qua Kernel; (b) latency biến thiên mạnh (short 7.6s > medium 3.0s dù ít token hơn) = **1 sample/prompt, latency do mạng/API chi phối, không phải steady-state** — đủ để biết bậc độ lớn (giây/call), chưa đủ để tối ưu latency cụ thể; (c) **out ≫ in** → nếu cần tối ưu cost, đòn bẩy là output tokens (giới hạn/nén output), không phải input.

**Kết luận baseline:** bậc độ lớn xác nhận giả thuyết M7-0 — **AI call (3–8 s) áp đảo overhead nội bộ (đơn-con-số ms) ~1000×.** Vẫn 0 tối ưu ship: muốn tối ưu provider-side đúng cách cần đo QUA Gateway (token/goal thật gồm context) với nhiều sample — chưa có key thường trực. Đòn bẩy rõ nhất khi có: **output-token control** (out gấp ~7× in).

**Còn mở (đúng phạm vi):** tối ưu provider-side qua Gateway (context trimming nếu token-in-qua-assembly cao / prompt-cache nếu latency ổn định cao / output-token cap / cache eviction khi có hit-rate thật) — cần baseline QUA-GATEWAY nhiều sample = **nợ Medium còn lại, chờ key thường trực**. Không đoán.

**Chất lượng:** build 0/0 debug+release · **159 test / 2 opt-in skip / 0 fail** ~0.8s offline · 0 dòng Core/Presentation đổi (chỉ thêm 1 file test) · arch suite nguyên · AI spend tích lũy **$0.00**.

## 4g. M5 Closeout (nghiệm thu 2026-07-04, tag `M5`)

**Tiêu chí M5 (DEVELOPMENT_PLAN §2/M5) — đánh giá trung thực:**

| Tiêu chí | Kết quả |
|---|---|
| ≥3 module hoạt động mà Core không đổi (chứng minh plugin architecture) | ✅ **YouTube + TikTok + Shopify; git: 5 task module liên tiếp 0 file Core/Infra chạm** (đo bằng script, không khai) |
| Mỗi module copy đúng khuôn, không sửa Core | ✅ `MODULE_GUIDE.md` tự-đủ; guide-test đạt 2 lần / 2 domain khác nhau (content-creation, e-commerce) |
| Nhân bản mô hình module | ✅ + bằng chứng phủ định: thí nghiệm gỡ hẳn module (M4-2) → platform build sạch |

**5 câu hỏi review — kết luận bằng bằng chứng:**
1. **Guide tự-đủ chưa?** ✅ Nội dung tự-đủ (Shopify dựng 0 read Core sau khi thêm Phụ lục A+B tại M5-1). KHÔNG bổ sung thêm — không tìm thấy gap nội dung nào có bằng chứng.
2. **Contract v1 còn đúng sau 3 module?** ✅ Đúng — 0 dòng contract đổi qua 5 task. Dấu hiệu mở rộng duy nhất (tool-channel cho dữ liệu ngoài) đã được quyết ĐÓNG có lập luận cấu trúc (AD-45), gate M6. Không có v2.
3. **Matcher cần nâng cấp?** ❌ Chưa — 18 skill, 2 lần chỉnh curated-union (đều DATA), sweep tự động chặn n², 0 sự cố ship. 1 latent tiếng Việt là artifact TRƯỚC guideline §4; guideline (tránh từ generic trong keyword single-skill) đã chặn cho module mới. Curated keywords vẫn đủ.
4. **Nợ:** EventBus/retryPolicy đã xóa đúng hẹn (M4-4/M3-4); ApprovalGate → M6 (nay milestone kế, phải quyết); tier-routing chờ ≥2 model; Vietnamese overlap giữ Low (bug thật, không bằng chứng tác động mới, fix cần ma trận precedence riêng); nhóm Low khác evidence-gated vào runbook/M7. Không gia hạn nào thiếu lý do.
5. **Open source:** contributor đọc guide → viết module → `swift test` (mọi OS) → PR: **luồng kỹ thuật đủ**. Thiếu đúng MỘT thứ = signpost README → MODULE_GUIDE (đã thêm tại M5-2). Rough edge trung thực: dòng đăng ký `installedModules` nằm ở `App/` (Xcode-only) → contributor Linux không compile-verify được đúng 1 dòng đó (nhưng module + test của họ verify được); không sửa (dời đăng ký = đổi kiến trúc, chưa có bằng chứng).

**ADR M5:** KHÔNG có AD mới — **contract v1 giữ nguyên qua 3 module chính là kết quả**; AD-44/45 (M4) tái xác nhận bằng bằng chứng, không cần ADR mới cho review.

**Chất lượng:** build 0/0 debug+release · **146/146 test** offline ~1s · baseline (M4) fresh 3.78ms / reuse 2.54ms (M5 thuần data, không đổi pipeline) · AI spend tích lũy **$0.00** · 19 arch rule.

**Kết luận: M5 ĐẠT (code-complete).** Plugin architecture PROVEN bằng lặp (3 module) + thí nghiệm (gỡ module) + guide-test (2 domain). PENDING duy nhất: chất lượng nội dung thật trên thiết bị (runbook — nợ High, nay đắt hơn với 3 module).

## 4f. M4 Closeout (nghiệm thu 2026-07-03, tag `M4`)

**Tiêu chí M4 (DEVELOPMENT_PLAN §2/M4) — đánh giá trung thực:**

| Tiêu chí | Kết quả |
|---|---|
| Module nghiệp vụ production-quality đầu tiên = khuôn mẫu (AD-21) | ✅ 9 skill / 4 mảng (ideas, script, SEO+publishing, channel analysis) + 3 composition (1 xuyên namespace) |
| "Hoàn thành công việc YouTube có ý nghĩa end-to-end bằng mục tiêu một câu" | ✅ offline bằng test (captured prompts, goal một câu → pipeline nhiều bước → deliverable); ⚠️ chất lượng NỘI DUNG thật PENDING thiết bị + API key (runbook) |
| Module tuân thủ 100% contract, không đụng Core | ✅ **bằng chứng mạnh nhất: M4-1/2/3 mỗi task 0 dòng Core, 0 dòng contract** (git); thí nghiệm gỡ hẳn module (M4-2): platform build sạch, 116/116 pass |
| 9 mảng capability danh mục gốc | ⚠️ 4/9 — đủ để CHỨNG MINH KHUÔN (mục tiêu thật của M4); Thumbnail/Shorts/… là data thuần theo khuôn có sẵn, bổ sung **theo nhu cầu thật khi dùng app**, không phải để đủ danh sách |

**Module Contract v1 đã chứng minh:** (1) thêm module = thêm data — 3 task liên tiếp 0 dòng Core/contract; (2) xóa module = gỡ data — thí nghiệm build thật; (3) xuyên namespace miễn phí — composition module dùng skill built-in chỉ bằng ID; (4) kỷ luật chiều ngược — cơ hội mở contract (tool-channel M4-3) bị TỪ CHỐI bằng lập luận cấu trúc (AD-45). **ADR M4:** AD-44 ✅ PROVEN (3 lớp cưỡng chế + 2 thí nghiệm) · AD-45 ✅ PROVEN (lát cắt ship 0 contract change) · AD-46 ✅ thực thi đúng hẹn · AD-26 → Superseded.

**EventBus — xử đúng deadline (AD-39 → AD-46):** bằng chứng xóa: 1 producer + 2 consumer TĨNH + 0 consumer động sau 4 mảng module; chi phí giữ (actor 31 dòng + 2 subscribe task + 1 hop async) > chi phí thay (2 dòng fan-out trong closure publish có sẵn — seam AD-33 không đổi). Xóa: component + test + cập nhật 6 docs; thêm vào danh sách cấm-tái-tạo; điều kiện tái sinh ghi trong AD-46 (audience ĐỘNG thật). Baseline sau xóa: fresh 3.78ms (M3: 4.98) — bớt một actor hop.

**Module architecture — business logic creep: KHÔNG.** `YouTubeModule.swift` = 100% struct literal; arch rule data-only canh bằng máy; module 0 state/persistence qua cả 4 mảng (kể cả mảng "cần dữ liệu thật" — giải bằng user-provided data, AD-45).

**Skill Registry / matcher — theo số liệu:** 14 skill + 1 tool; 2 lần tinh chỉnh curated-union (M4-1/M4-2, đều là DATA); 1 tie bất ngờ bị test bắt trước khi ship; keyword-sweep test tự động hóa việc rà n² (M4-3). **Kết luận: chưa có bằng chứng cần đổi matcher** — mọi sự cố đều giải được bằng data + được test khóa; tín hiệu theo dõi = khi curated-union không còn giải được một ca thật.

**Open source (cập nhật từ M3-4):** điều kiện "module contract proven" ✅ ĐẠT. Người ngoài viết module thứ hai hôm nay: về CƠ HỌC là copy `YouTubeModule.swift` + 1 dòng composition root — nhưng guideline (namespace, curated-union, precedence tests) đang nằm rải trong code comments/CHANGELOG → **thiếu MỘT tài liệu `MODULE_GUIDE.md`** — giao cho M5-0 (viết bằng chính trải nghiệm dựng TikTok). Còn lại: runbook (user) + Store versioning (M7).

**Nợ kỹ thuật — rà toàn bộ, không kéo deadline thiếu bằng chứng:** EventBus **XÓA** (deadline M4 ✅) · retryPolicy đã xóa M3-4 · ApprovalGate deadline M6 chưa điểm (giữ nguyên hẹn) · tier routing Gateway-side: điều kiện ≥2 model thật chưa xảy ra (evidence-gated, không phải deadline quá hạn) · ChatViewModel trigger cứng còn nguyên (M3/M4 không chạm UI) · nhóm Low (search re-read, TTL cleanup, cache eviction, negation, cross-project reuse, scanner) đều evidence-gated vào runbook/M7 — blocker là dữ liệu thật, chủ sở hữu đã rõ.

**Chất lượng:** build 0/0 debug+release · **132/132 test** offline ~1.2s · baseline M4: fresh **3.78ms** / reuse **2.54ms** (M3: 4.98/3.20 — cải thiện sau khi bớt actor hop) · AI spend tích lũy **$0.00** · 19 arch rule (18 + EventBus vào banned list).

**Kết luận: M4 ĐẠT (code-complete).** Khuôn mẫu module PROVEN bằng lặp + thí nghiệm; phần PENDING duy nhất là chất lượng nội dung trên thiết bị thật (runbook — nợ High của user, đã qua 5 milestone).

## 4e. M3 Closeout (nghiệm thu 2026-07-03, tag `M3`)

**Tiêu chí M3 (DEVELOPMENT_PLAN §2/M3) — đánh giá trung thực:**

| Tiêu chí | Kết quả |
|---|---|
| Smart planning: ước lượng complexity trước khi chạy | ✅ M3-2 (AD-42) — deterministic, tier được earn, test lặp chứng minh |
| Reuse pipeline hoàn chỉnh (search deliverable/memory/cache trước khi tạo) | ✅ cơ chế đầy đủ từ M0-4/M1-2 (exact reuse + search 3 loại record + cache); phần NỚI (relevance-ranked reuse, cross-project) **HOÃN CÓ LẬP LUẬN** — wrong-reuse đắt hơn miss, cần dữ liệu sử dụng thật |
| Response cache + prompt cache tối ưu | ⚠️ cache hoạt động, key phản ánh context (test M1-2); TỐI ƯU **HOÃN** — chưa có hit-rate thật, tối ưu không số liệu là đoán |
| Reflection sau task, có gate AD-20 | ✅ M3-1 (AD-41) — AD-20 PROVEN sau 4 milestone chờ |
| Deliverable indexing & templates (Executive Summary, next steps) | ✅ indexing từ M0-4B (AD-10); templates M3-3 (AD-43) — scaffold là Config data |
| Tự động cập nhật State/Memory sau execution | ✅ recordCompletion (M0) + reflection memory qua gate (M3-1) |
| **Tiêu chí hoàn thành: AI call/token giảm CÓ ĐO LƯỜNG vs baseline M1** | ⚠️ **cơ chế giảm chứng minh bằng test vĩnh viễn** (reuse = 0 call, tool = 0 call, cache-hit, composition degrade an toàn); **số token thật PENDING** — cần API key + thiết bị (runbook), không giả số liệu |
| Chất lượng deliverable qua Verify gate ổn định | ✅ Verify gate từ M0 + scaffold cấu trúc M3-3 |

**ADR M3 — Decision → Evidence → Result:** AD-41 (6 test: gate chặn/mở đúng policy, no-bypass, vòng giá trị retrieval) ✅ PROVEN · AD-42 (13 test: determinism, tier earn, skill outrank, assumption qua gate, disabled chặn) ✅ PROVEN · AD-43 (7 test: scaffold mọi đường AI, bước giữa không scaffold, reuse nguyên văn, ≤80 token) ✅ PROVEN · Superseded: không.

**Xử deadline & xóa theo bằng chứng (AD-28 hai chiều — "không giữ vì có thể sẽ cần"):**
- `SkillDefinition.retryPolicy`: **XÓA** — hẹn từ M1 review, đến hạn M3 review vẫn 0 consumer (grep: chỉ khai báo/gán, không nơi nào đọc); retry thật là policy Gateway từ Config.
- `ExecutionPlan.retryPolicy`: **XÓA** — cùng bằng chứng (không ai đọc `plan.retryPolicy` từ M0).
- `ExecutionStrategy.direct/.hybrid`: **XÓA** — chưa bao giờ được construct trong 4 milestone; chỉ tồn tại trong 2 switch cho đủ case (dead case = cognitive load thuần).
- **Bằng chứng xóa đúng:** 114/114 test pass sau xóa mà KHÔNG sửa một test nào.
- EventBus: giữ nguyên hẹn — deadline M4 (modules subscribe hay xóa).
- `ApprovalGate`: wired từ M0, chưa từng được tham vấn (chưa tồn tại risky action) — **hẹn cứng M6 (Automation)**: nếu M6 mở mà vẫn không có risky action thật → xóa.

**Intelligence Layer — kiểm tra "AI tự học quá sớm": KHÔNG có dấu hiệu.** Reflection deterministic (0 AI, test); WriteGate policy từ Config, default `.disabled`, không bypass (arch rule + test); ComplexityEstimate/Confidence là hằng số trong code, không lịch sử, không tự điều chỉnh (test lặp 10 lần); AI-reflection vẫn bị CẤM theo AD-41 (4 câu bằng chứng chưa trả lời). Mọi "trí thông minh" hiện tại đều đọc được, giải thích được, tắt được bằng config.

**Kiến trúc:** không ứng viên hợp nhất (Core 6 không đổi từ v1.1, mỗi thành phần có test riêng chứng minh vai trò); không API mở quá sớm (extension-by-algorithm đóng có chủ đích — AD-42); API NÊN mở tương lai: per-skill `outputScaffold` (khi module cần format riêng — M4), heuristic constants → Config (khi có ca thật cần chỉnh).

**Chất lượng:** build 0/0 debug+release · **114/114 test** offline ~1.2s · baseline M3: fresh **4.98ms** / reuse **3.20ms** (M2: 5.53/3.49, M1: 5.45/3.14 — dao động trong biên độ đo, không trend xấu) · chi phí AI tích lũy **$0.00** · retrospective: pattern "đổi chữ ký public init default-param → `rm -rf .build`" lặp lần 5 — nay là BƯỚC CHUẨN trong quy trình, không phải sự cố.

**Kết luận: M3 ĐẠT (code-complete).** Hai mục hoãn có điều kiện kích hoạt ghi tại DEVELOPMENT_PLAN; mục "đo token thật" PENDING có địa chỉ (runbook — nợ High của user, càng để càng đắt vì 4 milestone UI chưa qua compiler Mac).

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
| Token/latency/cost provider thật | ✅ **ĐO 2026-07-05** (haiku): in 21–28 tok, out 35–207 tok, latency 3–8 s/call, ~$0.0013/2-call — chi tiết §4j | key user (đã thu, đã khoá) |
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
| AD-26 | ~~Event Bus hạ xuống Infrastructure~~ → **superseded bởi AD-46** (xóa tại deadline M4) |
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
| AD-42 | Smart Planning v1 deterministic: `ComplexityEstimate` pure (số từ/tín hiệu khối lượng/số mệnh đề — 0 AI/0 token/0 lịch sử); tier được earn (skill > estimate), Gateway chỉ tiêu thụ; Confidence Medium consumer đầu tiên — assumption qua đúng WriteGate (không đường ghi thứ hai); extension-by-data mở, extension-by-algorithm đóng có chủ đích |
| AD-43 | Executive Summary = cấu trúc output khai báo, không phải component: scaffold là data trong Config (≤80 token, test cưỡng chế), inject vào Execution, nối máy móc vào `.ai` + bước cuối composition; reuse/tool/bước giữa không scaffold; default nil = zero regression; không Summary/Report/Formatter Engine |
| AD-44 | Module Contract v1: module LÀ manifest — thuần data (id/version/purpose/skills); target OsirisModules chỉ depend OsirisCore; skill namespace structural theo module id; composition root duy nhất biết module cài đặt; 3 lớp cưỡng chế (compiler + 2 nhóm arch rule); Core không bao giờ biết module cụ thể; không Plugin Engine/Module Manager |
| AD-45 | Tool-channel cho manifest: KHÔNG mở (manifest = Codable data, Tool = protocol hành vi — đổi bản chất contract); Channel Analysis v1 = skill trên dữ liệu user cung cấp (0 tool/OAuth/network); điều kiện kích hoạt: M6 Automation với user quyết consent + phương án tách code khỏi manifest |
| AD-46 | XÓA EventBus đúng deadline M4 (AD-39): 0 consumer động sau 4 mảng module; thay bằng fan-out trực tiếp trong closure publish (seam AD-33 không đổi); vào danh sách cấm-tái-tạo; tái sinh chỉ khi có audience động thật; AD-26 Superseded |
| AD-47 | M6-0 Architecture Review (4 quyết định bằng bằng chứng): xóa ApprovalGate (0 consumer/6 milestone, shape phỏng đoán — tái sinh cùng risky action thật = mở tool-channel AD-45); tool-channel KHÔNG mở; EventBus KHÔNG tái sinh; automation = data + Kernel hiện có, KHÔNG engine/runtime/scheduler |

## 6. Nợ kỹ thuật (phân loại lại tại M1 Review — Critical/High/Medium/Low)

**Critical: 0.**

| Mức | Mô tả | Kế hoạch |
|---|---|---|
| **High (đang cháy)** | App/ + Presentation/ SwiftUI compile trên Xcode — CI macOS ĐÃ CHẠY. **Run #1: Linux job PASS, macOS job lộ 1 lỗi type thật** (`ChatViewModel.swift:112` — `try?` flatten nested optional SE-0230, double `let content` sai; `swiftc -parse` không bắt được vì là lỗi type không phải cú pháp). **ĐÃ SỬA**, chờ CI run kế xác nhận xanh. Cơ chế hoạt động đúng mục đích: biến 6 milestone "unknown UI" thành lỗi CI thấy + sửa được. **Còn lại:** lặp tới khi macOS job xanh; verify UX mắt thường vẫn cần thiết bị (runbook) |
| Medium | Token/latency/cost baseline provider thật chưa có (cần API key) | **Đã thêm harness `LiveBaselineTests`** (opt-in, gated `OSIRIS_LIVE_BASELINE=1` + `ANTHROPIC_API_KEY`) — chạy được TRÊN LINUX (AnthropicProvider thuần Swift, network tới Anthropic đã xác nhận reachable), **KHÔNG cần Mac**. **Còn lại [USER]:** cung cấp API key rồi chạy `OSIRIS_LIVE_BASELINE=1 ANTHROPIC_API_KEY=… swift test --filter LiveBaseline`, dán số vào §4b |
| ~~Medium~~ | ~~Store write gate / learning gate (AD-20) chưa enforce~~ — **ĐÃ TRẢ tại M3-1** (WriteGate + arch rule không-bypass) | ✅ |
| Medium | Tier routing: phía Kernel ĐÃ XONG tại M3-2 (`preferredTier` mang giá trị thật từ estimate/skill — AD-42); còn lại phía Gateway chưa tiêu thụ tier khi route (1 model thật) | Kích hoạt khi có ≥2 model thật trong catalog |
| ~~Medium~~ | ~~`SkillDefinition.retryPolicy` chưa được consumed~~ — **ĐÃ XÓA tại M3-4 đúng hẹn** (cùng `ExecutionPlan.retryPolicy` và `.direct/.hybrid` — 0 consumer, 114/114 pass không sửa test) | ✅ |
| ~~Low~~ | ~~`ApprovalGate` wired từ M0, chưa từng tham vấn~~ — **ĐÃ XÓA tại M6-0 đúng deadline** (AD-47; grep 0 consumer/6 milestone; 146/146 pass 0 test logic sửa; tái sinh cùng risky action thật) | ✅ |
| Low | Store search đọc lại toàn bộ file mỗi lần (chưa cache/index); relevance = word-hit v1 | Tối ưu ở M3/M7 khi có số liệu thật |
| Low | Working-context hết hạn chỉ lọc khi đọc, chưa xóa vật lý | Cleanup policy M1→M3 (policies.json đã có TTL) |
| Low | `InMemoryResponseCache` không bound/TTL | Eviction khi có bằng chứng; interface là seam |
| Low | Keyword matching khớp cả ngữ cảnh phủ định ("don't summarize") | Chấp nhận v1 — fallback rẻ; nâng cấp theo sử dụng thật |
| ~~Low~~ | ~~Latent overlap tiếng Việt "viết" (core.draft) ⊂ "viết kịch bản đầy đủ"~~ — **ĐÃ SỬA tại debt-sweep**: bare "viết" → "viết bài" ở `core.draft` VÀ composition `core.research-then-draft` (không thì composition vẫn cướp theo id); 4 test precedence tiếng Việt pin (full-script→script-generation; viết bài/soạn→draft; kịch bản video→outline) | ✅ |
| Low | Reuse per-project (đúng Project Isolation; chưa có cross-project reuse có kiểm soát) | M3 với policy rõ |
| Low | Arch-test scanner cắt `//` theo dòng — string literal chứa URL có thể false-negative | Nâng parser khi có ca thật |
| Medium | `ChatViewModel` gánh 5 vai (chat/projects/search/dashboard/skills) — chưa đau nhưng trend rõ | **Trigger cứng ĐÃ được tôn trọng tại M6-2:** surface Automation dùng `AutomationViewModel` RIÊNG, KHÔNG chạm ChatViewModel (precedent "một VM/surface"). ChatViewModel vẫn 5 vai — tách khi có task UI thật chạm chính nó |
| ~~Low~~ | ~~EventBus: 2 consumer tĩnh ≈ closure fan-out~~ — **ĐÃ XÓA tại M4-4 đúng deadline** (AD-46; 0 consumer động, thay bằng 2 dòng fan-out trực tiếp) | ✅ |
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
