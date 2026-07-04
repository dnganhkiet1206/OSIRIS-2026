# FOLDER_STRUCTURE.md — Cấu Trúc Thư Mục Chuẩn OSIRIS

> **Phiên bản:** 1.1 · **Ngày:** 2026-07-02
> Cấu trúc này hiện thực hóa Part 16 (Project Structure gốc) sau **hai vòng** hợp nhất kiến trúc (PROJECT_BLUEPRINT.md §3–4: Core 6 thành phần). Tổ chức dự án là **mối quan tâm kiến trúc hạng nhất**: một developer (hoặc AI session) mới phải hiểu dự án trong vài phút.

---

## 1. Nguyên tắc

1. **Mỗi thư mục một trách nhiệm.** Không có thư mục "misc/utils2/helpers-new".
2. **Phụ thuộc chỉ hướng xuống:** `Presentation → Modules/Core → Infrastructure`. Không import ngược, không import ngang giữa module.
3. **Nông hơn là sâu:** tối đa ~4 cấp trong mã nguồn; nếu cần cấp 5, xem lại thiết kế.
4. **File nhỏ, một mục đích.** File khó hiểu = tách.
5. **Tăng trưởng bằng cách thêm (additive):** thêm module mới không đụng cấu trúc hiện có.
6. **Tách config/assets/generated khỏi source.** Generated không bao giờ ghi đè file viết tay.

## 2. Cây thư mục chuẩn

```
OSIRIS/
├── App/                          # Điểm vào ứng dụng
│   ├── OsirisApp.swift           # @main, lifecycle
│   ├── AppComposition/           # Dependency wiring (composition root)
│   └── AppConfig/                # Bootstrap, environment
│
├── Presentation/                 # Toàn bộ SwiftUI — KHÔNG chứa business logic
│   ├── Chat/                     # Màn hình chính (app mở thẳng vào đây)
│   ├── Sidebar/                  # Điều hướng: Chat, Projects, Settings, (Advanced)
│   ├── Projects/                 # Danh sách & chi tiết project
│   ├── Dashboard/                # Nhận thức vận hành (goal, task, usage, status)
│   ├── Settings/                 # Cài đặt tối giản
│   ├── Advanced/                 # Advanced/Developer Mode (ẩn mặc định)
│   │   ├── StoreViewer/          # Memory/Knowledge Viewer = view trên Store
│   │   ├── LogViewer/
│   │   ├── TokenAnalysis/
│   │   └── ModelRouting/
│   └── ExecutionStatus/          # Hiển thị execution events (không lộ reasoning)
│
├── Core/                         # 6 thành phần nền tảng — KHÔNG chứa business logic
│   ├── Kernel/                   # Executive Brain: nơi DUY NHẤT quyết định
│   │   ├── Lifecycle/            # Vòng đời 5 pha: Intake, Decide, Execute, Verify, Persist
│   │   └── Decision/             # Chiến lược, resource order, confidence tiers
│   │   # KHÔNG còn Gates/ — ApprovalGate xóa tại M6-0 (AD-47): 0 consumer/6 milestone;
│   │   # tái sinh cùng risky action thật (external effect, = mở tool-channel AD-45)
│   ├── Execution/                # Execution Engine: nơi DUY NHẤT thi hành
│   │   ├── TaskRunner/           # Chạy task, parallel, resume sau suspend
│   │   └── Recovery/             # Retry/fallback theo policy khai báo (AD-25)
│   │                             # (composition = SkillDefinition.compositionSteps,
│   │                             #  chạy trong DefaultExecutionEngine — AD-36)
│   ├── Skills/                   # Skill Registry — điểm mở rộng DUY NHẤT
│   │   ├── Registry/             # Đăng ký, tra cứu theo capability tag, versioning
│   │   ├── Contracts/            # Skill schema tối thiểu (AD-28), Capability tags
│   │   └── BuiltIn/              # Skill tổng quát (Research, Summarize, Document…)
│   ├── Modules/
│   │   └── Contracts/            # ModuleManifest — Module Contract v1 (AD-44), thuần data
│   ├── Store/                    # Nguồn sự thật DUY NHẤT (AD-22)
│   │   ├── ProjectState/         # Goal, tasks, progress, decisions, issues,
│   │   │                         #   deliverable index (derived từ file)
│   │   ├── Knowledge/            # Cách hệ thống hoạt động — searchable
│   │   ├── WorkingContext/       # Tạm thời, TTL tự hết hạn
│   │   ├── Search/               # Retrieval: phục vụ Decide, AI Gateway, Global Search
│   │   ├── Policies/             # Ghi/nén/hết hạn/learning gate (AD-20)
│   │   └── Persistence/          # Đọc/ghi, migration, khôi phục
│   ├── AIGateway/                # Cửa DUY NHẤT cho mọi AI call (AD-06, AD-24)
│   │   ├── Assembly/             # Retrieve (qua Store) → assemble context
│   │   ├── Budgeting/            # Budget 4 mức, compression, đo lường (AD-15)
│   │   ├── Caching/              # Prompt cache (preamble), response cache
│   │   ├── Routing/              # Chọn model theo yêu cầu/chi phí
│   │   └── Providers/            # Adapter từng provider (hoán đổi được)
│   └── Tools/                    # Tool Layer (AD-18)
│       ├── Contracts/            # Interface tool chung
│       ├── OnDevice/             # Filesystem, media (AVFoundation/Vision/Speech),
│       │                         #   calendar, network (URLSession trực tiếp — AD-27)
│       └── MCP/                  # MCP client cho remote tools (tùy chọn, thêm từ M6)
│
├── Application/                  # Application Layer (AD-35) — SPM target OsirisApplication
│   └── ChatService.swift         # Cầu nối DUY NHẤT UI ↔ Core: gọi Kernel, dịch
│                                 #   ExecutionEvent/error → TaskUpdate; không business logic
│
├── Modules/                      # Nghiệp vụ — mỗi module một plugin độc lập
│   └── YouTube/                  # ← REFERENCE IMPLEMENTATION (AD-21)
│       ├── Manifest/             # id, version, capabilities, dependencies, status
│       ├── UI/                   # Màn hình riêng của module
│       ├── Skills/               # Skill của module (đăng ký vào Skill Registry)
│       ├── Templates/            # Deliverable & prompt templates
│       ├── Config/               # Cấu hình mặc định của module
│       ├── Docs/                 # README ngắn: purpose, capabilities, interfaces
│       └── Tests/                # Test riêng của module
│   # TikTok/, Shopify/, Etsy/, … copy đúng cấu trúc trên. Không sáng tạo cấu trúc mới.
│
├── Shared/                       # Dùng chung — không thuộc Core, không thuộc module nào
│   ├── DesignSystem/             # Màu, typography, spacing, component style
│   ├── Components/               # UI tái dùng: Cards, Lists, Progress, MediaViewer
│   ├── Extensions/               # Swift/SwiftUI extensions
│   └── Utilities/                # Tiện ích thuần (formatter, parser…) — không state
│
├── Infrastructure/               # Kỹ thuật nền — không biết gì về nghiệp vụ
│   ├── Storage/                  # Local storage engine (nền vật lý cho Store), files
│   ├── Logging/                  # Structured logs (debug, cost, execution review)
│   ├── Security/                 # Keychain (API keys), bảo vệ dữ liệu
│   ├── Configuration/            # Nạp/ghi config, feature flags
│   # KHÔNG còn Events/ — EventBus xóa tại M4-4 (AD-46): progress events
│   # fan-out trực tiếp từ closure publish của Kernel tại composition root
│   # KHÔNG có Networking/ — URLSession dùng trực tiếp tại consumer (AD-27)
│
├── Modules/                      # SPM target OsirisModules — CHỈ import OsirisCore (AD-44)
│   ├── YouTube/                  # Reference module (AD-21): manifest + skills thuần data
│   │   └── YouTubeModule.swift   # ModuleManifest "youtube" — 9 skill/composition
│   ├── TikTok/                   # Module thứ hai (M5-0): dựng chỉ từ MODULE_GUIDE.md
│   │   └── TikTokModule.swift    # ModuleManifest "tiktok" — hook/content/trend + composition
│   └── Shopify/                  # Module thứ ba (M5-1): domain e-commerce khác hẳn
│       └── ShopifyModule.swift   # ModuleManifest "shopify" — product/listing/store + composition
│
├── Config/                       # CẤU HÌNH NGOÀI SOURCE (editable không cần sửa code)
│   ├── preamble.md               # Vision + System Preamble tĩnh < 400 token (AD-13, AD-23)
│   ├── models.json               # Danh mục model, tier, giá
│   ├── routing.json              # Quy tắc chọn model
│   ├── budgets.json              # Token/context budget
│   ├── policies.json             # Store, execution, approval policies
│   ├── features.json             # Feature flags
│   └── deliverable-scaffold.md   # Cấu trúc output deliverable AI (M3-3, AD-43) — ≤80 token
│
├── Resources/                    # Assets — không trộn với source
│   ├── Assets.xcassets/          # Icon, hình ảnh
│   ├── Localization/             # Chuỗi đa ngôn ngữ
│   └── SampleData/               # Dữ liệu mẫu cho preview/test
│
├── Tests/                        # Test phản chiếu cấu trúc source
│   ├── CoreTests/                #   (test module nằm trong module — xem trên)
│   ├── InfrastructureTests/
│   └── SharedTests/
│
└── Docs/                         # Tài liệu dự án (quy tắc nạp context: AD-29)
    ├── PROJECT_BLUEPRINT.md
    ├── PROJECT_STATE.md          # ← file DUY NHẤT luôn nạp vào AI dev session
    ├── DEVELOPMENT_PLAN.md
    ├── FOLDER_STRUCTURE.md
    ├── SYSTEM_COMPONENTS.md
    ├── MODULE_GUIDE.md           # Cách viết module (M5-0) — đủ để mở rộng không cần đọc Core
    ├── RUNBOOK_M1-0.md           # Hướng dẫn user tự verify trên Mac + thu baseline thật
    └── archive/                  # 18 file đặc tả gốc (tham chiếu lịch sử — AD-14)
```

> Ghi chú: khi khởi tạo Xcode project (M0-1), 5 file .md hiện ở repo root sẽ chuyển vào `Docs/`; 18 file .docx gốc chuyển vào `Docs/archive/`.

## 3. Quy ước đặt tên

- Tên mô tả **trách nhiệm**, không viết tắt, không mơ hồ.
  - ✅ `Kernel`, `ExecutionEngine`, `SkillRegistry`, `Store`, `AIGateway`
  - ❌ `Helper`, `Utils2`, `ManagerNew`, `ServiceFinal`
- Tên chuẩn hóa duy nhất theo AD-01…AD-08 và AD-22…AD-27 (không dùng tên cũ đã hợp nhất):
  - Dùng `Kernel` — không dùng "Planner service" / "Executive Brain service" riêng.
  - Dùng `Store` — không dùng "StateStore" / "MemoryStore" / "MemoryManager" như component riêng.
  - Dùng `AIGateway` — không dùng "ModelRouter" / "TokenManager" / "ContextEngine" / "ContextLoader" / "ContextBuilder" như component đỉnh.
  - Workflow là composition khai báo qua `SkillDefinition.compositionSteps` (AD-36) — không có "WorkflowEngine", không struct `SkillComposition` riêng.
  - Không tạo tầng "Networking" — URLSession trực tiếp (AD-27).
- File Swift: một type chính mỗi file, tên file = tên type.

## 4. Quy tắc vệ sinh

- **Temporary data** dùng thư mục tạm của hệ thống, tự dọn — không bao giờ nằm trong cấu trúc dự án.
- **Generated files** (nếu có) nằm tách biệt, đưa vào `.gitignore` khi phù hợp.
- **Git:** commit nhỏ, message rõ; không commit file sinh tự động không cần thiết.
- Mỗi thư mục lớn (`Core/*`, `Modules/*`) có README ngắn: Purpose · Responsibilities · Dependencies · Public Interfaces. Không viết tài liệu thừa.
