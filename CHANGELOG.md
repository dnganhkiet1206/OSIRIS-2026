# CHANGELOG

## [Unreleased — M1]

### 2026-07-02 — M1-3: Composition Execution v1 (AD-36)

- **AD-36 — một khái niệm một cách biểu diễn:** xóa struct `SkillComposition` (tồn tại song song với field `compositionSteps` từ AD-28 = nguồn sự thật đôi); composition nay là `SkillDefinition` có `compositionSteps` (≤5 bước, precondition cưỡng chế). Strategy `.composition(steps: [SkillDefinition])` — Kernel resolve step IDs trong Decide nên Execution không bao giờ chạm registry (AD-25).
- Composition mẫu `core.research-then-draft` (research-outline → draft). Matching M1-1 hoạt động cho composition **miễn phí**: triggerKeywords = hợp keywords các bước con — goal chứa nhiều keyword ⇒ composition thắng theo hit-count; goal một keyword ⇒ tie-break id chọn đúng skill đơn (test chứng minh cả hai chiều).
- Execution chạy steps tuần tự, máy móc, đúng khai báo: không đổi thứ tự, không thêm/bỏ bước, không tối ưu luồng; output bước trước (cap 6000 chars — chống phình token) nối vào task bước sau; mỗi bước một Gateway call = một `ai.request` metrics; deliverable = output bước cuối; chuỗi rỗng/hỏng → Verify gate chặn, không deliverable nửa vời. Composition thiếu step degrade về plain AI — goal vẫn hoàn thành.
- Không Workflow Engine/Runtime/DSL/Graph/Scheduler — composition chạy trong `DefaultExecutionEngine` (~25 dòng thêm). Parallel + Resume-sau-suspend hoãn có user duyệt (thiếu bằng chứng cần) — xét lại tại M1 review.
- 3 test mới (chuỗi 2 bước: captured prompts chứng minh template từng bước + output bước 1 vào bước 2 + deliverable là output cuối + có persist; precedence; degrade). Tổng 61/61 pass, 0 warning, offline.

### 2026-07-02 — M1-2: Gateway Retrieval & Assembly (AD-24 hoàn chỉnh)

- Pipeline Gateway đủ chuỗi AD-24: validate → **retrieve → trim → assemble** → budget → cache → (dry-run | retry) → metrics → log. Retrieval đứng TRƯỚC cache lookup nên cache key (model + prompt đã assemble) luôn phản ánh đúng context — test chứng minh: context đổi = cache miss, context giữ = cache hit.
- `StoreQuery.matchMode`: `.exact` (default — bảo toàn strict reuse của Kernel, zero regression) | `.anyWord` (retrieval: tokenize ≥3 ký tự, rank theo hit count, tie theo thứ tự duyệt). FileBackedStore search hợp nhất một lượt duyệt cho cả hai mode.
- Assembly có cấu trúc section (không ghép chuỗi tự do): preamble → `## Relevant context` (`### Current working context` / `### Knowledge` / `### Previous results`) → `## Task`. Ưu tiên: Critical (preamble+task, không bao giờ cắt) > Important (WC) > Helpful (Knowledge — lấy body đầy đủ thay vì topic) > Optional (deliverable history). Trim nguyên-snippet từ ưu tiên thấp, deterministic, không phá cấu trúc. Không context → prompt y hệt trước M1-2 (test).
- Token efficiency: N≤3 snippet (`maxContextSnippets`), mỗi snippet cap 600 chars, `contextBudgetTokens` = 4000 (budgets.json); search lỗi không bao giờ chặn AI call.
- Metrics thêm `contextSnippetCount` (đo được mới tối ưu được); ContextPriority hết là contract chết.
- CompositionRoot: MỘT Store instance chia sẻ Kernel + Gateway (tránh nguồn sự thật thứ hai).
- 5 test mới (knowledge vào đúng section với body đầy đủ; project khác không rò context; trim đúng thứ tự ưu tiên, critical bất khả xâm; cache an toàn khi context đổi; không context giữ prompt shape cũ). Tổng 58/58 pass, 0 warning, offline.

### 2026-07-02 — M1-1: Skill Registry v1 — thêm khả năng bằng cách thêm Skill

- 3 skill tổng quát **thuần dữ liệu** (`Core/Skills/BuiltIn/GenericSkills.swift`): summarize / draft / research-outline — version 1.0.0, promptTemplate với điểm chèn `{goal}` duy nhất, preferredModelTier khai báo. Không reflection, không plugin system, không dynamic loading.
- `SkillDefinition.triggerKeywords` (field optional mới theo AD-28, có lập luận): matching data-driven — skill tự khai báo nó khớp gì, **thêm skill mới không cần sửa Kernel** (đúng mục tiêu milestone). Keyword giữ hẹp: thà fallback còn hơn khớp sai.
- Kernel Decide mở rộng thứ tự tài nguyên: reuse → skill-match → plain AI; thuật toán chọn bất biến (nhiều hit thắng, tie theo id tăng dần — deterministic); tier lấy từ skill. Strategy `.ai` mang payload `skill:` — skill chỉ tồn tại trên đường AI, combo vô nghĩa bị type loại trừ.
- Execution assemble template máy móc (thay `{goal}`) — không chọn, không sửa prompt (AD-25); prompt template là data qua registry, không hardcode trong code (AD-04).
- `InMemorySkillRegistry(registering:)` — seed đồng bộ cho composition; CompositionRoot đăng ký GenericSkills.
- Trả nợ kỹ thuật: `Kernel.skills` nay được tiêu thụ thật.
- 4 test mới chứng minh bằng captured prompt (template vào prompt + `{goal}` được thay; goal không khớp giữ **nguyên** prompt trần — zero regression; registry rỗng an toàn; tie-break deterministic). Tổng 53/53 pass, 0 warning, offline.

### 2026-07-02 — M1-0 (phần code): Settings, API key entry & Runbook

- `ProviderSettings` (Application): port dạng closure-struct cho quản lý key — mức abstraction nhỏ nhất thỏa ràng buộc arch rules (Presentation và Application đều không được chạm Infrastructure); composition root bọc KeychainSecretsVault vào closures. UI chỉ biết `ProviderStatus` (connected/offline).
- `SettingsView`: SecureField nhập key (không bao giờ hiển thị lại), Save/Remove, trạng thái, ghi rõ áp dụng sau restart; sidebar thêm mục Settings (selection-based; root view sẽ tái cấu trúc ở M2).
- `Docs/RUNBOOK_M1-0.md`: hướng dẫn từng bước cho user — Mac build (xcodegen), checklist kiểm tra bằng mắt (chat, reuse, restart, clarification), nhập key, smoke test 3 goal + đọc log `ai.request` để thu token/latency/cost baseline thật. Không giả số liệu — baseline điền vào PROJECT_STATE §4b khi user dán kết quả.
- 49/49 test pass, 0 warning; toàn bộ file UI mới qua `swiftc -parse`.

## [M0] — 2026-07-02 (tag `M0`)

### M0 Final Verification & Acceptance

- 3 test xác minh mới (49/49 pass, debug + release 0 warning):
  - `ShippedConfigurationTests`: Config/ thật phải qua đúng validation của Gateway (cả 2 chế độ online/offline) — guard vĩnh viễn chống config drift.
  - `AnthropicProviderIntegrationTests`: round-trip qua URLSession thật với URLProtocol stub (không Internet) — body đúng schema Messages API, preamble được assemble, parse usage thật, **cost accounting xác minh: $0.0035 cho 1000 in/500 out haiku**; headers (pin version, key) assert trực tiếp trên URLRequest (phát hiện quirk: URLProtocol trên Linux không expose request headers → tách `makeRequest` internal cho testability).
  - `PipelineBaselineTests`: baseline AD-15 đầu tiên — **fresh-goal ~4.65 ms/request, reuse-path ~2.54 ms/request** (overhead nội bộ, không gồm provider).
- App/Presentation (6 file SwiftUI) qua `swiftc -parse`; Config JSON + project.yml validate.
- Nghiệm thu M0 ghi tại PROJECT_STATE §4b; 2 mục pending có kế hoạch (Mac simulator, baseline provider thật — M1-0).

## [Unreleased]

### 2026-07-02 — M0-6: Milestone Closeout — provider thật đầu tiên (AD-31 được chứng minh)

- `AnthropicProvider` (Core/AIGateway/Providers): adapter Messages API bằng URLSession thuần (continuation-based, chạy cả Linux), pin `anthropic-version: 2023-06-01`, parse text + usage thật (input/output tokens); error = HTTP status + hint hành động được, **không bao giờ chứa key hay response body**. Adapter chỉ làm một việc — budget/cache/retry/dry-run/metrics vẫn thuộc Gateway.
- **Phép thử AD-31 đạt: cắm provider thật vào hệ thống với 0 dòng thay đổi ở DefaultAIGateway, Kernel, Execution, Store, ChatService.**
- `KeychainSecretsVault` (App layer, Security framework): SecretsVault production; secrets không xuất hiện trong logs/prompts/config/errors.
- Composition graceful: key trong vault → AnthropicProvider + `defaultModelID`; không key → PlaceholderAIProvider + `offlineModelID` (routing.json mới có 2 trường; models.json thêm claude-haiku-4-5 tier light $1/$5 per 1M) — app không bao giờ crash vì thiếu key.
- Security Review: scan sạch — không key literal; key chỉ đi Keychain → header; điểm log duy nhất chỉ phát metrics.
- 4 test AnthropicProvider offline (fixture parse, ignore non-text blocks, malformed body, HTTP hint mapping không rò thông tin). Tổng 46/46 pass, 0 warning.
- M0 nghiệm thu: code-complete; 2 mục PENDING có ghi nhận (Mac build verification, token baseline thật — cần Mac/API key).

### 2026-07-02 — M0-5: Chat UI v0 & Application Layer (AD-35)

- **Application Layer mới** — SPM target `OsirisApplication` (chỉ phụ thuộc OsirisCore, test được trên Linux): `ChatService` là cầu nối duy nhất UI ↔ Core — nhận goal, gọi Kernel, dịch `ExecutionEvent` → activity text và error → thông điệp thân thiện (what happened / attempted / next); guard "một goal tại một thời điểm"; không business logic.
- `TaskUpdate`: tất cả những gì UI được biết (activity / needsClarification / completed / failed) — UI không phân biệt reuse hay AI, không biết provider/retry/strategy.
- Quyết định: **không rename `ExecutionEvent`** — tính tổng quát cho UI đạt bằng tầng dịch của Application, không bằng đổi tên type Core.
- Presentation: `ChatViewModel` (@MainActor @Observable, chỉ import OsirisApplication, chỉ quản lý state UI) + `ChatView` kiểu ChatGPT (NavigationSplitView: sidebar tối giản, transcript, composer, status line calm) + `ExecutionStatusView`.
- CompositionRoot: `makeChatService()` nối Kernel.publish thẳng vào service (EventBus tham gia khi có nhiều consumer — M2); project.yml link OsirisApplication.
- +2 Architecture rule (chỉ thêm): Presentation chỉ import OsirisApplication; Application chỉ import OsirisCore. Tổng 13 arch rule.
- 4 test ChatService mới (activity → completed; goal mơ hồ → câu hỏi; error dịch thân thiện không rò tên nội bộ; terminal event không thành activity). Tổng 42/42 pass, 0 warning, offline.

### 2026-07-02 — M0-4B: Execution & Deliverable Persistence — vòng Reuse khép kín (AD-10/32)

- `Store.saveDeliverable(content:goal:for:)` + `deliverableContent(at:)`: chỉ Store chạm đĩa; deliverable là file `.md` với goal nhúng trong front matter — file vẫn là asset dùng được và goal lặp lại khớp search tự nhiên, không cần record phụ (không nguồn sự thật thứ hai). Front matter được strip khi đọc lại.
- Kernel Persist: ghi deliverable qua Store, thêm path vào `ProjectState.deliverablePaths` (index phái sinh — AD-10); khi strategy là `.reuse` thì KHÔNG ghi lại (tránh duplicate làm bẩn reuse detection).
- `Store.search` thêm `Kind.deliverable` — tìm qua index thay vì duyệt thư mục, dừng sớm khi đủ limit; reuse ở Kernel giờ lấy nội dung đầy đủ (`knowledge.body` / `deliverableContent`) thay vì snippet — trả nợ M0-4A.
- **Vòng Reuse khép kín có test chứng minh:** goal mới → AI → file + index; cùng goal lần 2 → reuse, đúng 0 provider call, không file mới.
- `ExecutionPlan.preferredTier` (Kernel quyết định, Execution truyền qua nguyên vẹn — routing theo tier kích hoạt khi có ≥2 model thật, AD-31).
- +1 Architecture rule (chỉ thêm, không sửa cũ): Presentation không được import OsirisInfrastructure. Tổng 36/36 test pass, 0 warning, offline.

### 2026-07-02 — M0-4A: Kernel Decide thuần túy + Architecture Tests (AD-32/33/34)

- **Architecture Test Suite** (Tests/ArchitectureTests, chạy trong `swift test`): 10 rule quét source — import matrix theo tầng, Kernel purity, chỉ Store chạm LocalStorage, chỉ Gateway chạm provider, chỉ Kernel tạo ExecutionPlan, đúng 1 impl Store/AIGateway, cấm khai báo lại component đã loại bỏ, module isolation. Scanner bỏ qua comment (rule đánh giá code, không đánh giá văn xuôi).
- Suite **bắt được ngay vi phạm thật**: Kernel import OsirisInfrastructure (EventBus) → sửa theo AD-33: progress events qua closure `@Sendable (ExecutionEvent) async -> Void` inject từ composition root; Kernel chỉ còn phụ thuộc protocol Core.
- **Pha Decide thật (M0-4A)**: Confidence v0 (goal rỗng → `needsClarification`, không đoán, 0 AI call); reuse-before-AI qua `Store.search` — strategy mới `.reuse(existing:)` mang content để Execution materialize máy móc (không chạm Store, AD-25); hết reuse → `.ai` (Gateway lần đầu được dùng từ vòng đời thật).
- M0-4 chia thành M0-4A (quyết định, thuần túy) / M0-4B (materialize + persist qua Store — AD-32) sau Architecture Review theo yêu cầu user.
- 3 test Decide mới (reuse hit = 0 provider call; miss = đúng 1; goal rỗng = hỏi lại). Tổng 32/32 pass, build 0 warning, toàn bộ offline.

### 2026-07-02 — M0-3: AI Gateway hoàn thiện như thành phần độc lập (AD-31)

- Pipeline đầy đủ trong `DefaultAIGateway`: validate → budget (token + cost, từ chối trước khi tốn) → cache → (dry-run | provider với retry khai báo) → metrics → log.
- `AIRequestMetrics` (AD-15): requestID, provider, model, latency, estimated/actual tokens, cost, cacheHit, retryCount, dryRun, succeeded/failureReason — log qua Logger, không bao giờ chứa prompt/secret.
- `GatewayConfiguration` với throwing init = validation fail-fast (model tồn tại, budget dương, preamble ≤ giới hạn AD-13 — cưỡng chế bằng máy).
- `BudgetPolicy`, `TokenEstimator` (một estimator duy nhất), `ResponseCache` protocol + `InMemoryResponseCache` (seam thay thế sau này), Dry Run mode (`features.json: aiDryRun`).
- Retry thuộc Gateway, tái dùng đúng `RetryPolicy` đã có (một type policy duy nhất, AD-25); cấu hình từ `policies.json: aiRetry`.
- `AIProvider` chuẩn hóa: adapter chỉ làm một việc (prompt → text + usage thật); mọi thứ khác thuộc Gateway. `AIUsage` thay bằng metrics thống nhất.
- 9 unit test mới (cache bỏ qua provider, budget từ chối trước spend, dry-run không chạm provider, retry phục hồi/exhausted, config invalid fail-fast…) — toàn bộ offline. Tổng 19/19 pass, build 0 warning.

### 2026-07-02 — M0-2: Store bền vững + Config wiring

- `FileBackedStore`: Store production, mỗi bản ghi một file JSON qua `LocalStorage` (`project-state|knowledge|working-context/<id>.json`); ID percent-encode; ISO8601 dates, sortedKeys cho diff ổn định. Test "restart" chứng minh ProjectState sống sót qua app restart.
- `LocalStorage` thêm `keys(withPrefix:)`; `FileStorage.write` tạo thư mục cha (hỗ trợ key phân cấp).
- `CompositionRoot`: đọc `preamble.md` + `routing.json` qua ConfigurationLoader (hết hardcode), Store trỏ Application Support, fail-fast khi thiếu Config.
- Xóa `InMemoryStore` + `StoreTests` (thừa sau FileBackedStore — một implementation Store duy nhất, hết duplicate search logic); KernelTests chuyển sang FileBackedStore.
- Build 0 error / 0 warning; 10/10 test pass (Swift 6.0.3, Linux).

### 2026-07-02 — M0-1: Project Bootstrap (M0-0 theo cách gọi của phiên làm việc)

- Khởi tạo cấu trúc dự án theo FOLDER_STRUCTURE.md v1.1; tài liệu chuyển vào `Docs/`, 18 file đặc tả gốc vào `Docs/archive/`.
- SwiftPM package `OsirisKit` (AD-30): target `OsirisCore` (6 thành phần: Kernel, Execution, Skills, Store, AIGateway, Tools) + `OsirisInfrastructure` (Storage, Logging, Security, Configuration, Events) + 2 test target.
- Kernel skeleton chạy đủ vòng đời 5 pha (Intake → Decide → Execute → Verify → Persist) với placeholder provider — end-to-end, không tốn chi phí AI.
- App shell SwiftUI (App/ + Presentation/Chat) + `project.yml` (XcodeGen) cho build iOS trên macOS.
- Config ngoài source: `preamble.md` (System Preamble < 400 token), models/routing/budgets/policies/features.json.
- Kiểm chứng trên Linux + Swift 6.0.3: build 0 error / 0 warning, 8/8 test pass.

### 2026-07-02 — Tài liệu kiến trúc v1.1

- Vòng review 2 (AD-22 → AD-29): Core 9 → 6 thành phần; một `Store` duy nhất (sửa dual-source-of-truth); Context Engine hợp nhất vào AI Gateway; Vision → Config artifact; Event Bus → Infrastructure; bỏ Networking layer; Skill schema tối thiểu; context tiering cho tài liệu.

### 2026-07-02 — Tài liệu kiến trúc v1.0

- Architecture Review 18 file đặc tả gốc (AD-01 → AD-21); ban hành 5 tài liệu nền tảng: PROJECT_BLUEPRINT, PROJECT_STATE, DEVELOPMENT_PLAN, FOLDER_STRUCTURE, SYSTEM_COMPONENTS.
