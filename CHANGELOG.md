# CHANGELOG

## [Unreleased — M6]

### 2026-07-04 — M6-2: Automation UI v1 — saved goals reachable, ViewModel split honored

- **Surface Presentation cho automation** (port `Automation` M6-1 giờ có consumer UI): tạo rule từ 1 goal, **"Run now" thủ công**, toggle enabled, xoá, xem kết quả lần chạy. "Run now" gọi đúng `ChatService.submit` → Kernel (AD-47) — không path thực thi thứ hai.
- **Tôn trọng trigger cứng M2-6:** tạo `AutomationViewModel` RIÊNG thay vì nhồi vai thứ 6 vào `ChatViewModel` (god-object đã 5 vai). Đây là precedent đúng cho mọi surface UI sau: một ViewModel/surface. `ChatViewModel` KHÔNG bị chạm.
- `AutomationView` + mục sidebar "Automation" trong `ChatView`; import chỉ OsirisApplication (arch rule Presentation giữ); rule v1 chạy project "default" (per-project chờ bằng chứng — AD-28).
- **Scheduled `.daily` firing HOÃN có lập luận:** iOS `BGTaskScheduler` là code nền tảng thuần, **0 đường verify** trên Linux/CI (chỉ compile, không chạy được bg task) — build code không kiểm chứng được là rủi ro thuần; `.manual` + "Run now" đã đủ dùng. Firing thật khi có thiết bị (M6-3+).
- Presentation ngoài SPM package → chỉ `swiftc -parse` được trên Linux (5 file parse-sạch); type-check thật do **CI macOS** (đã chứng minh bắt lỗi thật với `ChatViewModel`). Package tests 157+1 không đổi.

### 2026-07-04 — Debt sweep (user cấp quyền "truy cập mọi thứ để giải quyết nợ")

- **Trung thực về giới hạn:** "truy cập mọi thứ" là QUYỀN, nhưng 2 nợ lớn nhất bị chặn bởi TÀI NGUYÊN không phải quyền — kiểm chứng bằng bằng chứng: OS vẫn Linux (`uname` — không có macOS SDK để compile SwiftUI); `ANTHROPIC_API_KEY` unset (network tới api.anthropic.com trả 401 = reachable, chỉ thiếu auth). Quyền không tự sinh ra máy Mac hay API key. Nên tôi (a) sửa nợ làm được ngay, (b) dựng cơ chế để 2 nợ kia giải được với đúng 1 hành động của user.
- **Nợ Low tiếng Việt — SỬA HẲN:** `core.draft` dùng bare "viết" (⊂ "viết kịch bản đầy đủ" của youtube.script-generation) → goal tiếng Việt "viết kịch bản đầy đủ" tie 1-1, thua về `core.draft` theo id. Đổi "viết" → "viết bài" ở cả `core.draft` VÀ composition `core.research-then-draft` (nếu chỉ sửa draft, composition vẫn cướp theo id). 4 test precedence tiếng Việt pin hành vi đúng.
- **Nợ High (UI chưa compile Mac) — DỰNG CƠ CHẾ:** thêm `.github/workflows/ci.yml` — job `app-macos` chạy `xcodegen + xcodebuild` compile SwiftUI trên GitHub Actions macOS runner (job `package-linux` chạy `swift test`). **Tự động hoá đúng gốc nợ, không cần Mac cá nhân.** Không verify được từ Linux (không có macOS) — lần chạy CI đầu hoặc xanh hoặc lộ lỗi SwiftUI thật; cả hai đều biến unknown thành sự thật CI thấy được.
- **Nợ Medium (baseline thật) — DỰNG HARNESS:** `LiveBaselineTests` opt-in, gated `OSIRIS_LIVE_BASELINE=1` + `ANTHROPIC_API_KEY` (skip mặc định — không tốn tiền ngoài ý muốn). Chạy được TRÊN LINUX (AnthropicProvider thuần Swift), **không cần Mac** — biến "chạy runbook trên Mac" thành "set key + 1 lệnh test, mọi OS".
- 4 test tiếng Việt mới; harness live (skip). Tổng **157/157 pass** + 1 opt-in skip, 0 warning, offline.

### 2026-07-04 — M6-1: Automation-as-data v1 — rule là data, chạy qua Kernel hiện có (AD-47)

- **`AutomationRule` = record thứ 4 của Store**, schema TỐI THIỂU (AD-28): `id`, `projectID`, `goalText`, `trigger`, `enabled` — "goal" tách thành projectID + text, KHÔNG field "để dành". Persist qua Store duy nhất (AD-32); layout `automation-rules/<id>.json`; test chứng minh sống sót restart.
- **`AutomationTrigger` = data enum, KHÔNG scheduler:** `.manual` (chạy được offline qua "run now") + `.daily(hour:)` (định nghĩa SCHEMA cho iOS background scheduling — M6-2+, KHÔNG fire trên Linux, có test Codable round-trip). Không timer, không dispatcher, không giả lập scheduler.
- **"Run now" tái dùng đúng Kernel:** Application port `Automation` (closure struct, pattern AD-38) — `runNow` fetch rule rồi gọi `ChatService.submit(goalText, projectID)` = **chính xác đường một goal thủ công đi**, KHÔNG execution path thứ hai. Test tại biên Kernel: goal của rule đã lưu → 1 AI call ordinary → deliverable.
- **Cưỡng chế "0 engine" bằng máy:** arch rule cấm-tái-tạo siết thêm `AutomationEngine/AutomationManager/RuleRunner/AutomationRuntime` (20 rule). Không component/runtime/scheduler/dispatcher mới nào được thêm.
- `AutomationRuleSummary.from` = pure mapping testable mọi nền tảng; port wired trong composition root (Presentation surface = M6-2/PENDING thiết bị).
- 7 test mới (persistence restart, delete, trigger round-trip, defaults, run-through-Kernel, summary mapping ×2). Tổng **153/153 pass**, 0 warning, offline.

### 2026-07-04 — M6-0: Automation Architecture Review + xóa ApprovalGate (AD-47)

- **Architecture Review TRƯỚC code (bắt buộc — milestone đầu có risky actions):** 4 quyết định, tất cả bằng bằng chứng grep/git, không phỏng đoán.
- **(1) XÓA ApprovalGate** (+ `RiskyAction`, `ApprovalDecision`, `RequireUserApprovalGate`): grep chứng minh `evaluate(_:)` **chưa từng được gọi** ở đâu và `RiskyAction` **chưa từng được construct** qua 6 milestone. Automation v1 chạy skill sinh deliverable (file local, reversible) — KHÔNG phải risky action (publish/delete/external effect). Xóa: Kernel init bớt 1 param, ~18 test site, file `Core/Kernel/Gates/` xóa. **Bằng chứng xóa đúng: 146/146 pass mà 0 dòng logic test nào sửa** (sed chỉ gỡ dòng tham số). Shape cũ (publish/delete/largeSpend/…) là phỏng đoán M0 — giữ sẽ neo thiết kế tương lai vào phỏng đoán. **Tái sinh:** cùng sự kiện với risky action THẬT đầu tiên (external/irreversible) = cũng chính là lúc mở tool-channel (AD-45) — một quyết định thống nhất.
- **(2) Tool-channel: KHÔNG mở** — không module M6-0 nào cần (AD-45 giữ nguyên). **(3) EventBus: KHÔNG tái sinh** — automation v1 không tạo audience động; fan-out closure vẫn đủ (AD-46 giữ nguyên). **(4) Automation sống ở đâu:** = DATA (rule = goal + trigger) + tái dùng vòng đời Kernel hiện có; **KHÔNG Engine/Runtime/Scheduler/Dispatcher**. Trigger theo lịch = iOS background (PENDING thiết bị). Build ở M6-1 với schema tối thiểu (AD-28) khi trigger model rõ — M6-0 chốt thiết kế + dọn scaffolding chết.
- **Không thêm feature ở M6-0** (đúng "review trước, build sau"): thay đổi thuần là xóa code chết + docs. Kernel giờ chỉ còn seam thật (skills/tools/engine/store/writeGate/publish). Tổng **146/146 pass**, 0 warning, offline.

## [M5] — 2026-07-04 (tag `M5`)

### M5-2: Milestone Review & Acceptance — plugin architecture proven

- **M5 ĐẠT (code-complete)** — nghiệm thu tại PROJECT_STATE §4g. Tiêu chí "≥3 module Core-không-đổi" đạt: YouTube + TikTok + Shopify; đo bằng script trên git = **5 task module liên tiếp, 0 file Core/Infrastructure chạm** (không khai số).
- **5 câu review, kết luận bằng bằng chứng:** (1) Guide tự-đủ — không gap nội dung, KHÔNG bổ sung; (2) Contract v1 đúng qua 3 module, 0 dòng đổi, không có v2 (dấu hiệu mở rộng duy nhất = tool-channel, đã đóng có lập luận AD-45, gate M6); (3) Matcher chưa cần nâng cấp — curated keyword + guideline §4 + sweep tự động chặn mọi ca, 0 sự cố ship; (4) nợ rà sạch, không gia hạn thiếu lý do; (5) open-source: luồng contributor đủ, thiếu đúng 1 signpost README→MODULE_GUIDE (đã thêm).
- **Thay đổi duy nhất (doc):** README thêm mục "Contributing a module" trỏ MODULE_GUIDE. Rough edge ghi trung thực: dòng đăng ký `installedModules` ở App/ (Xcode-only) — contributor Linux verify được module+test của họ nhưng không compile-check đúng 1 dòng đăng ký; không sửa (dời = đổi kiến trúc, chưa có bằng chứng).
- **Không AD mới** — contract v1 giữ nguyên qua 3 module chính là kết quả review.
- Bằng chứng: build 0/0 debug+release; 146/146 test offline; baseline fresh 3.78ms / reuse 2.54ms; AI spend tích lũy $0.00; 19 arch rule.

### 2026-07-04 — M5-1: Shopify Module — guide-validation lần 2 trên domain khác hẳn

- **Shopify = module thứ 3, domain e-commerce** (không phải content-creation như YouTube/TikTok) — bằng chứng mạnh hơn rằng Contract v1 đủ tổng quát. `shopify`: product-research, listing-optimization, store-analysis (dữ liệu user dán — AD-45) + composition `shopify.research-to-listing` xuyên namespace (bước 1 = built-in `core.research-outline`).
- **Bài học keyword cho domain mới:** single-skill keyword CỐ Ý tránh từ built-in ("research"/"draft") — vì "product research" ⊃ "research" sẽ tie 1-1 và THUA `core.research-outline` theo id. Dùng "winning products"/"product opportunities" thay thế; composition ĐƯỢC tái dùng "research" trong union (§6). Test precedence pin: goal "research…" thuần vẫn về core, không bị Shopify cướp.
- **MODULE_GUIDE nâng cấp tự-đủ (đóng finding M5-0):** thêm **Phụ lục A** (built-in skill IDs cho composition) + **Phụ lục B** (khung test copy sẵn). Guide cũ trỏ "copy từ YouTubeModule/test YouTube" — vi phạm chính bài kiểm tra "cấm đọc module cũ". Giờ guide đứng một mình: manifest từ contract, skill từ §3, composition IDs từ Phụ lục A, test từ Phụ lục B.
- **Bằng chứng "mở rộng không sửa Core" lần 5:** 0 dòng Core, 0 dòng Infrastructure, 0 dòng contract. Đạt **tiêu chí hoàn thành M5: ≥3 module Core-không-đổi**.
- Arch rule cấm-tên-module siết thêm "shopify". 7 test mới. Tổng **146/146 pass**, 0 warning, offline.

### 2026-07-04 — M5-0: TikTok Module + MODULE_GUIDE.md — Contract v1 tự chứng minh bằng module thứ hai

- **`Docs/MODULE_GUIDE.md`** (≤2 trang, prescriptive — không triết lý): manifest, namespace, triggerKeywords, composition, precedence, curated union, mandatory tests, architecture rules, những điều cấm. Tham chiếu code duy nhất: `ModuleManifest` (~50 dòng) + mẫu YouTube. Là tài liệu DUY NHẤT người ngoài cần để viết module.
- **Bài kiểm tra guide (PHẦN 3 của yêu cầu) — ĐẠT:** TikTok module dựng chỉ từ MODULE_GUIDE + Module Contract, KHÔNG cần đọc Core. `tiktok` module: `hook-ideas`, `content-plan`, `trend-brief` (dữ liệu user dán — AD-45) + composition `tiktok.research-to-plan` (xuyên namespace: bước 1 = built-in `core.research-outline`, resolve bằng ID qua registry chung).
- **Bằng chứng "mở rộng không cần sửa Core" lần 4:** `git status` — 0 dòng Core, 0 dòng Infrastructure, 0 dòng contract; toàn bộ thay đổi = `Modules/TikTok/`, `Tests/ModuleTests/`, 1 dòng `installedModules` ở composition root. **Không AD mới — contract giữ nguyên chính là kết quả.**
- **Sweep test nâng cấp cho 2 module:** mọi keyword skill đơn của TikTok không giẫm/bị giẫm bởi bất kỳ skill/tool nào khác toàn registry (chống n² đúng phạm vi module mới). Composition miễn (union là cơ chế).
- Bài học trung thực: sweep test bản đầu quá rộng, phát hiện overlap CÓ CHỦ ĐÍCH nội bộ YouTube ("script" dùng chung) + latent overlap tiếng Việt ("viết"⊂"viết kịch bản đầy đủ"). Thu hẹp test về đúng bất biến "module mới không giẫm ai"; latent YouTube ghi nợ Low (ngoài phạm vi clone khuôn).
- 7 test mới (TikTok manifest/e2e/precedence/cross-namespace/curated-union/sweep). Tổng **139/139 pass**, 0 warning, offline.

## [M4] — 2026-07-03 (tag `M4`)

### M4-4: Milestone Review & Acceptance — EventBus xóa đúng deadline (AD-46)

- **M4 ĐẠT (code-complete)** — nghiệm thu tại PROJECT_STATE §4f. Module Contract v1 PROVEN bốn chiều: thêm module = data (3 task 0 dòng Core/contract), xóa module = gỡ data (thí nghiệm build 116/116), xuyên namespace = miễn phí (test), kỷ luật chiều ngược (từ chối mở contract có lập luận — AD-45).
- **EventBus XÓA đúng deadline AD-39** (AD-46; AD-26 → Superseded): bằng chứng — 1 producer, 2 consumer tĩnh, **0 consumer động sau 4 mảng module**; chi phí giữ (actor 31 dòng + 2 subscribe task + 1 async hop) > chi phí thay (2 dòng fan-out trong closure `publish` có sẵn — seam AD-33 không đổi, Kernel không biết gì thay đổi). Xóa component + test theo quy trình; "EventBus" vào danh sách cấm-tái-tạo (19 arch rule); điều kiện tái sinh: audience ĐỘNG thật. Baseline hưởng lợi: fresh 4.98 → **3.78ms**.
- **Matcher — kết luận theo số liệu:** 14 skill, 2 lần tinh chỉnh đều bằng DATA, 0 sự cố lọt qua test, sweep n² đã tự động — CHƯA có bằng chứng cần đổi matcher.
- **Open source:** điều kiện "module contract proven" đạt; thiếu đúng MỘT thứ cho người ngoài viết module: `MODULE_GUIDE.md` (guideline đang rải trong comments/CHANGELOG) — giao M5-0 viết bằng trải nghiệm dựng TikTok thật.
- Nợ rà toàn bộ: EventBus xóa ✅; ApprovalGate (M6) và tier-routing (≥2 model) chưa đến điều kiện — giữ nguyên hẹn, không kéo dài tùy tiện; nhóm Low đều evidence-gated vào runbook/M7.
- Bằng chứng: build 0/0 debug+release; **132/132 test**; baseline fresh 3.78ms / reuse 2.54ms; AI spend tích lũy $0.00.

### 2026-07-03 — M4-3: Channel Analysis v1 — quyết định tool-channel bằng Architecture Review trước code (AD-45)

- **Architecture Review đi trước, code đi sau** (yêu cầu user): 11 câu trả lời đầy đủ, 3 phương án so sánh (A: skill trên dữ liệu user dán; B: mở contract `tools` + API tool; C: tool đọc CSV). **Chọn A — nhỏ nhất**: 0 dòng Core, 0 dòng contract, ship giá trị ngay.
- **AD-45 — vì sao KHÔNG mở contract (quyết định phủ định có điều kiện kích hoạt):** lý do cấu trúc quyết định — `ModuleManifest` là **Codable thuần data** (bản chất của AD-44), `Tool` là **protocol mang hành vi** (không Codable): nhét `[any Tool]` vào manifest đổi BẢN CHẤT contract từ data sang code. Cộng bằng chứng vận hành: auto-fetch cần OAuth/network/privacy — quyết định thuộc user tại M6 Automation (mcpRemoteTools đang false). Điều kiện kích hoạt + phương án ưu tiên (tách code khỏi manifest) ghi trong AD.
- **`youtube.channel-analysis`**: phân tích dữ liệu kênh user DÁN vào goal (từ YouTube Studio) — best performer + why, 2 pattern nên lặp, 1 thứ nên dừng, 3 hành động; template tự nhận "dữ liệu không đủ thì nói rõ, không bịa số"; tier `.standard` khai báo; dữ liệu dán luôn tươi đúng mức user muốn (cùng logic AD-37); insight từ text = việc AI thật — "AI Is The Last Tool" giữ nguyên.
- **Keyword sweep tự động thay rà tay:** test mới quét MỌI cặp keyword (skill mới × toàn registry + tool) khẳng định 0 overlap — trả lời rủi ro n² ghi từ M4-2 bằng máy.
- Module vẫn 0 state/persistence/business logic; EventBus: 4 mảng liên tiếp không cần events (điểm dữ liệu cho M4 review).
- **0 dòng Core, 0 dòng contract.** 3 test mới. Tổng **133/133 pass**, 0 warning, offline.

### 2026-07-03 — M4-2: SEO + Publishing Package — package là deliverable, không phải hệ thống

- **`youtube.seo-package`**: metadata một video (3 title ≤60 ký tự, description 2 đoạn, 10 tags, 3 hashtags) — skill prompt-data, 1 AI call.
- **`youtube.publishing-package`**: gói xuất bản hoàn chỉnh = MỘT deliverable có cấu trúc từ pipeline hiện có — dùng độc lập (1 AI call, tie-break về single skill có test) hoặc làm bước cuối composition; template tự ground vào script ở previous material khi có. Không Publishing Engine / SEO Engine / Metadata Engine.
- **`youtube.script-to-package`**: composition script → package — package grounded trong script THẬT qua previous-step chaining (test captured prompt); deliverable = package cuối.
- **Guideline union tinh chỉnh lần 2 (phát hiện qua test fail-first):** tie 2-2 giữa composition và `script-generation` khiến goal hai-domain rơi về single skill sai. Quy tắc thật rút ra: *"tuyển chọn union sao cho MỌI tie resolve về single skill — kiểm từng cặp overlap với tie-break id trong đầu, pin bằng test"*. Ở đây GIỮ "script" trong union (3 hit thắng 2) vì mọi id tie đều sort trước composition — ngược hướng với case M4-1. Vẫn thuần data, 0 dòng matcher.
- Module tiếp tục 0 state / 0 session / 0 OAuth / 0 upload / 0 cache / 0 persistence — không nhu cầu nào như vậy xuất hiện trong 2 mảng này.
- **0 dòng Core, 0 dòng contract.** 3 test mới. Tổng **130/130 pass**, 0 warning, offline.

### 2026-07-03 — M4-1: Idea → Script pipeline — workflow là data, xuyên namespace là miễn phí

- **`youtube.script-generation`**: full script ready-to-record, tier `.standard` KHAI BÁO — skill nặng nhất module tự nói lên điều đó (AD-42 hoạt động nguyên trạng cho module data).
- **2 composition thuần data:** `youtube.idea-to-script` (idea → script, output bước 1 nuôi bước 2 — test thứ tự bằng captured prompts) và `youtube.research-to-script` — **bước 1 là `core.research-outline`, built-in resolve XUYÊN NAMESPACE chỉ bằng SkillID qua registry chung**. Không API đặc biệt, không `if YouTube`, không Workflow/Pipeline Engine, không Module Runtime — Kernel resolve steps y như M1-3.
- **Guideline data mới (không đổi matcher):** union keywords của composition được TUYỂN CHỌN — bỏ keyword rộng nhất để composition chỉ thắng khi goal chứa CẢ HAI domain. Goal thuần script → single skill, 1 AI call (test); goal thuần idea → tie-break về idea-generation (test); goal hai domain → composition thắng 3-2 (test).
- Composition thiếu built-in step (module cài mà không có built-ins) degrade về plain AI đúng luật M1-3 — goal vẫn hoàn thành (test). Scaffold M3-3 áp dụng nguyên trạng: bước giữa raw, bước cuối Executive Summary (test).
- Sửa 1 assertion test M4-0 (giả định "mọi skill có promptTemplate" — tổng quát hóa thành template HOẶC compositionSteps khi composition đầu tiên vào manifest, đúng AD-36).
- **0 dòng sửa Core, 0 dòng sửa contract.** 6 test mới. Tổng **127/127 pass**, 0 warning, offline.

### 2026-07-03 — M4-0: Module Contract v1 + YouTube Module skeleton — module là data, không phải plugin (AD-44)

- **Module Contract v1 nhỏ nhất có thể:** `ModuleManifest` (Core/Modules/Contracts) = id/version/purpose/**skills** — hết. Registry thứ hai được phép theo AD-17 và nó là DESCRIPTOR thuần data, không phải engine. Skills là kênh đóng góp duy nhất v1 (skill đã chở đủ mọi thứ theo AD-28); kênh mới chỉ thêm khi module thật không ship được nếu thiếu. Namespace skill theo module id là precondition structural — không thể collision với `core.*` hay module khác.
- **Ranh giới 3 lớp cưỡng chế:** (1) compiler — target SPM `OsirisModules` CHỈ depend OsirisCore, Core không depend Modules (Core về mặt cấu trúc KHÔNG THỂ biết module); (2) arch rule siết: Modules chỉ import OsirisCore (trước đây cho phép cả Infrastructure — siết là hợp lệ, chỉ nới mới cấm) + rule mới Modules-are-data-only (cấm Kernel/Gateway/Store/Execution/EventBus/I-O); (3) rule mới: Core/Application/Infrastructure/Presentation cấm nhắc tên module cụ thể (`youtube` chỉ được xuất hiện trong Modules/ và composition root). 18 arch rule tổng.
- **YouTube module v0 (reference, AD-21):** 2 skill thuần data (`youtube.idea-generation`, `youtube.script-outline`); overlapping-phrase keywords ("video script" + "script" = 2 hit) thắng generic skill 1-hit một cách deterministic — cùng cơ chế composition M1-3, không đổi matcher. Composition root: `installedModules` là nơi DUY NHẤT biết module nào được cài; merge skills vào MỘT registry.
- **Bằng chứng "thêm module không sửa Core":** diff Core/ = chỉ THÊM `Core/Modules/Contracts/ModuleManifest.swift` (chính contract — deliverable một-lần của M4-0), 0 file Core bị SỬA; module #2 sẽ là 0 dòng Core, 0 dòng contract.
- EventBus evidence (deadline M4): module đầu tiên KHÔNG cần events — điểm dữ liệu đầu tiên cho quyết định giữ/xóa.
- 5 test module mới (manifest namespaced, no-collision, end-to-end qua lifecycle nguyên trạng, generic không bị hijack, precedence 2-1). Tổng **121/121 pass**, 0 warning, offline.

## [M3] — 2026-07-03 (tag `M3`)

### M3-4: Milestone Review & Acceptance

- **M3 ĐẠT (code-complete)** — nghiệm thu tại PROJECT_STATE §4e. AD-41/42/43 đều PROVEN bằng test (6+13+7). Tiêu chí "AI call/token giảm có đo lường": cơ chế chứng minh bằng test vĩnh viễn (reuse/tool = 0 call, cache-hit); số token thật PENDING trung thực (runbook).
- **Xóa theo bằng chứng, đúng hẹn (AD-28 hai chiều):** `SkillDefinition.retryPolicy` (hẹn từ M1 review, 0 consumer), `ExecutionPlan.retryPolicy` (0 nơi đọc từ M0), `ExecutionStrategy.direct/.hybrid` (chưa bao giờ construct trong 4 milestone). Bằng chứng xóa đúng: **114/114 pass mà không sửa một test nào**. RetryPolicy type giữ — Gateway config là consumer thật.
- **Kiểm tra "AI tự học quá sớm": không dấu hiệu** — mọi heuristic là hằng số đọc được, gate default disabled, AI-reflection vẫn cấm (AD-41). Hai mục M3 hoãn có điều kiện kích hoạt: reuse-nới + cache-tối-ưu chờ số liệu thật từ runbook (ghi tại DEVELOPMENT_PLAN).
- Deadline còn hẹn: EventBus → M4 (modules subscribe hay xóa); `ApprovalGate` → M6 (risky action thật hay xóa).
- Bằng chứng: build 0/0 debug+release; 114/114 offline ~1.2s; baseline fresh 4.98ms / reuse 3.20ms (M2: 5.53/3.49 — trong biên độ đo); AI spend tích lũy $0.00. Retrospective: "public init đổi default-param → clean rebuild" lặp lần 5 → nâng thành bước chuẩn quy trình.

### 2026-07-03 — M3-3: Deliverable Templates & Executive Summary v1 — cấu trúc là data, không phải engine (AD-43)

- **Executive Summary không phải component:** là cấu trúc output KHAI BÁO — scaffold sống trong `Config/deliverable-scaffold.md` (data, cùng họ preamble; test cưỡng chế ≤80 token + phải chứa "Executive Summary" — không phải preamble thứ hai). Composition root load fail-fast và inject vào `DefaultExecutionEngine` như chuỗi khai báo — **KHÔNG hardcode trong Kernel, KHÔNG hardcode trong Execution**; đổi format mọi deliverable = sửa MỘT file Config, 0 dòng code.
- **Execution nối máy móc, không quyết định:** scaffold append sau template + previous-step, đúng nơi sinh deliverable — đường `.ai` (kể cả plain AI không skill: user không cần biết skill tồn tại) và **BƯỚC CUỐI** composition (bước giữa là nguyên liệu, không scaffold — test 2 prompt chứng minh); `.reuse` trả nguyên văn không re-format; `.tool` không AI nên không scaffold.
- **Zero regression by construction:** `deliverableScaffold` default `nil` → prompt byte-identical trước M3-3; không một test captured-prompt cũ nào phải sửa (dự phòng trong NEXT_TASK hóa ra không cần dùng).
- Không Summary Engine / Report Builder / Document Generator / Formatter Engine — toàn bộ thay đổi Core là 1 optional String + 1 phép nối trong `assembleTask`. Kernel/Gateway/Store không chạm.
- 7 test mới (assembleTask thuần ×2, captured-prompt plain-AI/skill/composition/reuse ×4, shipped-config scaffold ×1). Tổng **114/114 pass**, 0 warning, offline. Gặp lại pattern đã biết lần 4: đổi chữ ký public init default-param → `rm -rf .build`.

### 2026-07-03 — M3-2: Smart Planning v1 — tier được earn, assumption có kỷ luật (AD-42)

- **`ComplexityEstimate` (pure, `Core/Kernel/Decision/`):** `simple/standard/complex` chỉ từ dữ liệu có sẵn trong goal — số từ, tín hiệu khối lượng khai báo ("detailed/comprehensive/chi tiết/toàn diện/…"), số mệnh đề (dấu câu + "and/và/then/rồi"). Deterministic tuyệt đối: cùng input cùng output (test lặp 10 lần), 0 AI, 0 ML, 0 lịch sử, 0 token.
- **Tier được earn, không hardcode:** Decide đặt `preferredTier = skill khai báo ?? estimate` (`simple/standard → .light`, `complex → .standard`) — skill hiểu việc của nó nhất nên outrank estimate (test). Gateway CHỈ tiêu thụ — routing theo tier vẫn chờ catalog ≥2 model thật (nợ Medium trả một nửa: phía Kernel xong). `.reuse/.tool` path không bị ảnh hưởng (test: goal chứa "detailed" vẫn đi tool với tier mặc định).
- **Confidence Medium có consumer đầu tiên — `ConfidenceTier` hết case chết:** tín hiệu mơ hồ chặt, deliberately ít ("something/somehow/gì đó/sao cũng được/…" — thà High, không spam assumption; test goal thường KHÔNG sinh assumption) → vẫn thực thi + assumption "interpreting the goal literally" đi **qua đúng WriteGate M3-1** với justification `reusableLater`, đích WorkingContext TTL tự dọn. **KHÔNG đường ghi mới** — gate `.disabled` chặn cả assumption (test không-bypass); assumption xuất hiện trong retrieval của goal liên quan sau (test khép vòng qua captured prompt).
- Không Planner Engine / Intelligence Engine / Decision Engine — Kernel vẫn là nơi quyết duy nhất; toàn bộ heuristic là hằng số đọc được trong 2 file.
- 13 test mới (`SmartPlanningTests` — RecordingEngine đọc `ExecutionPlan` tại biên Kernel↔Execution thật thay vì suy diễn lại). Tổng **107/107 pass**, 0 warning, offline.

### 2026-07-02 — M3-1: Reflection & Write Gate v1 — hệ thống bắt đầu ghi nhớ có kỷ luật (AD-41; AD-20 PROVEN)

- **Chuỗi trách nhiệm bằng type, không bypass:** Reflection (pure, deterministic — 0 AI, 0 token) chỉ nhìn strategy/goal/deliverable đã có, sinh tối đa MỘT `MemoryCandidate` — không biết Store, không persist → `WriteGate` là điểm quyết định DUY NHẤT (ghi/không/ghi-đâu; policy đọc từ `policies.json` — key `storeWriteGate`/`workingContextDefaultTTLHours` nằm chờ từ M0-1; unknown justification = fail fast) → Store persist. Arch rule mới (16 tổng): `WorkingContextRecord`/`KnowledgeRecord` chỉ được construct trong Core/Store — Reflection *về mặt type* không thể tự tạo record.
- Tiêu chí chặt — trí nhớ đáng tin hơn nhiều trí nhớ: chỉ `.ai/.composition` (reuse đã trên đĩa, tool free-to-recompute theo AD-37), goal ≥4 từ, có deliverable; đích duy nhất = WorkingContext với TTL từ policy (tự dọn); Knowledge writes đóng cho đến khi justification có consumer; save best-effort (memory phụ không fail goal); Kernel default `.disabled` — memory là opt-in qua composition.
- **Test giá trị khép vòng:** goal thứ hai *liên quan* (không exact — "Write catchy thumbnail captions…" sau "Research thumbnail ideas…") nhận memory phản chiếu trong prompt qua Gateway retrieval (`### Current working context`). Disabled policy → zero record (chứng minh không đường ngầm).
- AD-20 (khai từ kiến trúc v1.1, AWAITING 4 milestone) → **PROVEN**; trả nợ Medium "write gate chưa enforce".
- 6 test mới; 94/94 pass, 0 warning, offline. Không Learning Engine, không AI reflection (bị cấm đến khi trả lời đủ 4 câu bằng chứng).

## [M2] — 2026-07-02 (tag `M2`)

### M2-6: Milestone Review & Acceptance

- **M2 ĐẠT (code-complete)** — nghiệm thu tại PROJECT_STATE §4d; các mục UX chỉ xác minh được trên thiết bị PENDING trung thực (runbook). AD-38/39/40 đều PROVEN bằng test.
- Câu treo xử có lý do: giữ tên `ProjectDirectory` (rename = churn thẩm mỹ; điều kiện tách ghi rõ); **xóa `InMemorySecretsVault` đúng hẹn** (zero consumer); `ChatViewModel` hoãn tách với trigger cứng (task UI kế tiếp phải tách); `retryPolicy` deadline M3 review.
- Bằng chứng: build 0/0 debug+release; 87/87 test; baseline 5.53/3.49ms (theo dõi); security sạch; AI spend tích lũy $0.00.

### 2026-07-02 — M2-5: Advanced Mode gate + Accessibility pass (AD-40)

- **AD-40 — ranh giới hai loại persist:** UI preferences (`@AppStorage`/UserDefaults) chỉ ở App/Presentation, không bao giờ là input cho Kernel/Gateway/Store; platform data vẫn chỉ qua Store (AD-32 nguyên vẹn). Cưỡng chế bằng arch rule mới (tổng 15). Nhờ đó Advanced Mode toggle nằm trọn trong Presentation — zero port.
- Advanced Mode: toggle trong Settings (ẩn mặc định, footer giải thích); sidebar hiện mục Advanced khi bật; `AdvancedView` read-only: Skills inventory (id/version/purpose/composition badge — `SkillInfo.from` pure mapping từ registry qua closure trong AppDependencies) + System (provider status, app version). Không dev-tool platform, không hành động phá hoại; viewer đầy đủ chờ nhu cầu thật.
- Accessibility pass: `accessibilityLabel` cho nút icon-only (Send goal, Open deliverable), ExecutionStatus combine element; rà soát không fixed font size (Dynamic Type tự do); xác minh mắt thường thuộc Mac runbook.
- 3 test SkillInfo mapping + arch rule mới. Tổng 87/87 pass, 0 warning, offline; UI qua `swiftc -parse`.

### 2026-07-02 — M2-4: Dashboard v1 — operational awareness (AD-39)

- Dashboard đúng BLUEPRINT: Now (project, current goal, last completed, count) / Today's usage (requests, tokens in·out, cost, cache hits) / System (provider Connected/Offline) / Recent activity (≤6 dòng). **Không chart, không trends, không analytics, không %.**
- **AD-39 — seam quan sát duy nhất:** `DefaultAIGateway.onMetrics` callback optional (default nil — toàn bộ test Gateway cũ pass nguyên trạng); Gateway không aggregate, không persist. `DashboardModel` (Application) cộng dồn **session-only** — không database metrics, không lịch sử (M7 quyết bằng dữ liệu thật); fallback estimated khi provider không báo actual tokens; đo cả cache-hit.
- **EventBus có consumer production đầu tiên sau 7 milestone:** Kernel publish → bus → 2 subscription (ChatService relay + DashboardModel activity). Đánh giá trung thực ghi vào AD-39: với 2 consumer tĩnh, giá trị hôm nay ≈ closure fan-out — giá trị thật ở consumer động; tái đánh giá tại M4, xóa nếu modules không dùng.
- Sửa trong phiên: NSLock trong async context (2 warning) → tách đọc-dưới-lock thành hàm sync.
- 5 test mới (accumulate + estimated fallback; activity newest-first cap 10; snapshot đọc state + provider status; state mất an toàn; seam fire mỗi request kể cả cache-hit). Tổng 83/83 pass, 0 warning, offline; UI qua `swiftc -parse`.

### 2026-07-02 — M2-3: Global Search v1

- Sidebar có mục Search: một ô, kết quả nhóm loại xuyên mọi project — Projects (khớp tên, case-insensitive) → Deliverables → Knowledge → Working notes. Project-hit chuyển workspace; deliverable-hit mở reader (tái dùng flow có sẵn); knowledge/note hiển thị snippet tại chỗ.
- `SearchHit.assemble`: hàm thuần trong Application gộp project-name matches + dịch `StoreSearchResult` (bỏ projectState), thứ tự nhóm deterministic — test được trên Linux; composition root chỉ fetch (list + `StoreQuery(projectID: nil, matchMode: .anyWord, limit: 15)` — toàn API có sẵn từ M1-2, **không method Store mới**).
- Deliverable hiển thị bằng content preview — path nội bộ không bao giờ thành title (có test).
- Search closure gia nhập port `ProjectDirectory` (một closure không đáng port mới — Năm Câu Hỏi; cân nhắc đổi tên port tại M2 review).
- 4 test mới. Tổng 78/78 pass, 0 warning, offline; UI mới qua `swiftc -parse`.

### 2026-07-02 — M2-2: Project Resume v1 — "resume work instantly"

- Mở project → thấy ngay: goal gần nhất, số task hoàn thành, ≤5 deliverables mới nhất (preview 120 chars), bấm đọc full qua sheet. Tất cả từ ProjectState + files (State Over Chat — transcript chat là UI tạm, không persist).
- **`ProjectOverview.assemble`**: toàn bộ logic resume (thứ tự mới-nhất-trước, cap, cắt preview, chọn lastGoal, bỏ qua file mất) trong MỘT hàm thuần ở Application — test được mọi nền tảng; composition root chỉ fetch (bài học AD-35: logic không được rơi vào vùng Xcode-only).
- Port `ProjectDirectory` mở rộng 2 closure (`overview`, `deliverableContent`) — không method Store mới (checklist NEXT_TASK giữ vững), không type port mới.
- Overview là read-through, refresh khi đổi project và sau mỗi goal hoàn thành; guard chống race khi đổi project giữa lúc load.
- 4 test mới (lắp đúng dữ liệu; cap + truncate; project rỗng an toàn; file mất không phá resume). Tổng 74/74 pass, 0 warning, offline; UI mới qua `swiftc -parse`.

### 2026-07-02 — M2-1: Projects v1 — multi-project thật (AD-38)

- `Store.listProjectStates()` (mới cập nhật trước) + `ProjectState.name` với decode-fallback về id — file state cũ (không có name) migrate im lặng, dữ liệu cũ nguyên vẹn (test bằng file legacy raw).
- **AD-38:** list/create project là *state management*, không phải goal execution — closure-port `ProjectDirectory` (Application: `ProjectSummary` + 2 closure, không cạnh import mới, cùng pattern ProviderSettings) do composition root nối xuống Store (persister duy nhất). Kernel không thành query service; ChatService không ôm Store; execution results vẫn chỉ persist qua vòng đời Kernel.
- `ChatService.submit` bắt buộc `projectID` — hết hardcode "default"; UI sở hữu project hiện tại.
- Sidebar: section Projects (chọn project → transcript reset về project đó; tạo project qua alert); `AppDependencies` gói wiring một lần.
- Project Isolation test mới ở tầng Application: goal của "alpha" và "beta" không rò state sang nhau.
- 4 test mới. Tổng 70/70 pass, 0 warning, offline; UI mới qua `swiftc -parse` (nợ High Mac-compiler vẫn treo — runbook).

## [M1] — 2026-07-02 (tag `M1`)

### M1-5: Milestone Review & Acceptance

- **M1 ĐẠT** — nghiệm thu tại PROJECT_STATE §4c: mọi tiêu chí pass hoặc partial-có-chủ-milestone; 7/7 ADR của M1 (AD-31…AD-37) PROVEN bằng code + test; AD-20 awaiting consumer (M3).
- Bằng chứng: build 0/0 debug+release; 66/66 test (52 unit + 14 arch) offline ~1.1s; baseline nội bộ fresh 5.45ms / reuse 3.14ms (tăng ≈0.8ms so M0 = chi phí matching + retrieval, chấp nhận); security sạch; không god object (file lớn nhất 281 dòng, 35 file Swift Core+Infra+Application); không nguồn sự thật thứ hai (AD-36 đã xóa nguồn cuối); chi phí AI tích lũy $0.00.
- Nợ kỹ thuật phân loại lại: **Critical 0 · High 1** (UI chưa qua compiler Mac — runbook của user, phải xử lý trước/đầu M2) · Medium 4 · Low 7; dọn 4 mục đã trả khỏi bảng.
- Quyết định chốt: parallel + resume HOÃN với điều kiện kích hoạt ghi tại DEVELOPMENT_PLAN §M1.
- Retrospective ghi nhận: (1) Architecture Tests đáng lẽ viết từ M0-1 — suite bắt ngay vi phạm tồn tại từ bootstrap; (2) runbook Mac nên chạy ngay sau M0-5 thay vì để nợ UI tích tụ; (3) pattern đã biết: đổi chữ ký public có default-param cần clean build (2 lần dính linker cache).

### 2026-07-02 — M1-4: Tool Layer v1 — "AI Is The Last Tool" thành test vĩnh viễn (AD-37)

- `CurrentDateTimeTool` (Core/Tools/OnDevice): tool on-device đầu tiên — goal "What is the date today?" hoàn thành qua đường `.tool` với **0 AI request, 0 token** (CountingProvider chứng minh). Deterministic với clock inject được; keywords rất hẹp (goal thường không bị cướp — có test).
- Resource order của Decide ĐẦY ĐỦ: **reuse → tool → skill/composition → plain AI** (đúng thứ tự tài nguyên BLUEPRINT).
- Matching data-driven: `triggerKeywords` trên protocol `Tool`; **một thuật toán matching duy nhất** (`selectByKeywords` generic private trong Kernel) dùng chung skill + tool — matchedSkill refactor sang cùng hàm, không Tool Matcher riêng.
- Tools inject qua Kernel init (composition root) — **không Tool Registry** (AD-17 giữ trần 2 registry); `.tool(any Tool)` mang tool đã resolve — Execution không chọn/đổi/tự rơi sang AI khi tool fail (Kernel đã quyết → lỗi phải lộ, có test).
- **Deviation có lập luận so với NEXT_TASK:** tool results KHÔNG persist — persistence tồn tại để tránh tốn lại token, tool re-run miễn phí, còn kết quả cũ ("ngày hôm qua") là câu trả lời sai nằm chờ trong reuse path. Test: goal lặp lại → tool chạy lại (fresh), vẫn 0 AI, không file.
- Metrics tool tối thiểu: log `tool.run` (tool/duration/succeeded) qua Logger hiện có — không telemetry framework; DefaultExecutionEngine nhận logger.
- +1 arch rule (chỉ thêm): Core/Tools là leaf adapter — không tham chiếu AIGateway/AIProvider/Skill/Store/Kernel. Tổng 14 rule.
- 4 test mới. Tổng 66/66 pass, 0 warning, offline. Không plugin system/reflection/dynamic loading/tool graph/scheduler.

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
