# CHANGELOG

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
