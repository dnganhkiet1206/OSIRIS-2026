# FOLDER_STRUCTURE.md — Cấu Trúc Thư Mục Chuẩn OSIRIS

> **Phiên bản:** 1.0 · **Ngày:** 2026-07-02
> Cấu trúc này hiện thực hóa Part 16 (Project Structure gốc) sau khi hợp nhất kiến trúc (PROJECT_BLUEPRINT.md §4). Tổ chức dự án là **mối quan tâm kiến trúc hạng nhất**: một developer (hoặc AI session) mới phải hiểu dự án trong vài phút.

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
│   │   ├── MemoryViewer/
│   │   ├── LogViewer/
│   │   ├── TokenAnalysis/
│   │   └── ModelRouting/
│   └── ExecutionStatus/          # Hiển thị execution events (không lộ reasoning)
│
├── Core/                         # 9 thành phần nền tảng — KHÔNG chứa business logic
│   ├── Kernel/                   # Executive Brain: vòng đời 5 pha, decision, gates
│   │   ├── Lifecycle/            # Intake, Decide, Execute, Verify, Persist
│   │   ├── Decision/             # Chiến lược, resource order, confidence tiers
│   │   └── Gates/                # Validation & approval gates
│   ├── Execution/                # Execution Engine
│   │   ├── TaskRunner/           # Chạy task, parallel, retry, resume
│   │   ├── Composition/          # Workflow = declarative skill composition (AD-07)
│   │   └── Recovery/             # Fallback, restore state
│   ├── Skills/                   # Skill Registry (registry DUY NHẤT cho năng lực)
│   │   ├── Registry/             # Đăng ký, tra cứu theo capability tag, versioning
│   │   ├── Contracts/            # Skill schema, Capability tags
│   │   └── BuiltIn/              # Skill tổng quát (Research, Summarize, Document…)
│   ├── State/                    # State Store — nguồn sự thật duy nhất
│   │   ├── ProjectState/         # Goal, tasks, progress, decisions, issues
│   │   └── Persistence/          # Đọc/ghi, migration, khôi phục
│   ├── Memory/                   # Memory Store — 4 tầng (AD-09)
│   │   ├── Vision/               # Bất biến, rất nhỏ, luôn nạp (trong preamble)
│   │   ├── Knowledge/            # Cách hệ thống hoạt động — searchable
│   │   ├── ProjectMemory/        # Tiến độ, quyết định, ghi chú theo project
│   │   ├── WorkingContext/       # Tạm thời, tự hết hạn
│   │   └── Policies/             # Ghi/nén/hết hạn/learning gate (AD-20)
│   ├── Context/                  # Context Engine (AD-02)
│   │   ├── Retrieval/            # Truy hồi theo relevance
│   │   ├── Budget/               # 4 mức ưu tiên, cắt Optional trước
│   │   └── Compression/          # Tóm tắt, khử trùng lặp
│   ├── AIGateway/                # Cửa DUY NHẤT cho mọi AI call (AD-06)
│   │   ├── Routing/              # Chọn model theo yêu cầu/chi phí
│   │   ├── Budgeting/            # Token budget, đo lường (AD-15)
│   │   ├── Caching/              # Prompt cache, response cache
│   │   └── Providers/            # Adapter từng provider (hoán đổi được)
│   ├── Tools/                    # Tool Layer (AD-18)
│   │   ├── Contracts/            # Interface tool chung
│   │   ├── OnDevice/             # Filesystem, media (AVFoundation/Vision/Speech),
│   │   │                         #   calendar, network…
│   │   └── MCP/                  # MCP client cho remote tools (tùy chọn, thêm sau)
│   └── Events/                   # Event Bus: progress, state-changed, task events
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
│   ├── Storage/                  # Local storage engine, file management
│   ├── Networking/               # HTTP client, reachability
│   ├── Logging/                  # Structured logs (debug, cost, execution review)
│   ├── Security/                 # Keychain (API keys), bảo vệ dữ liệu
│   └── Configuration/            # Nạp/ghi config, feature flags
│
├── Config/                       # CẤU HÌNH NGOÀI SOURCE (editable không cần sửa code)
│   ├── models.json               # Danh mục model, tier, giá
│   ├── routing.json              # Quy tắc chọn model
│   ├── budgets.json              # Token/context budget
│   ├── policies.json             # Memory, execution, approval policies
│   └── features.json             # Feature flags
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
└── Docs/                         # Tài liệu dự án
    ├── PROJECT_BLUEPRINT.md
    ├── PROJECT_STATE.md
    ├── DEVELOPMENT_PLAN.md
    ├── FOLDER_STRUCTURE.md
    ├── SYSTEM_COMPONENTS.md
    └── archive/                  # 18 file đặc tả gốc (tham chiếu lịch sử — AD-14)
```

> Ghi chú: khi khởi tạo Xcode project (M0-1), 5 file .md hiện ở repo root sẽ chuyển vào `Docs/`; 18 file .docx gốc chuyển vào `Docs/archive/`.

## 3. Quy ước đặt tên

- Tên mô tả **trách nhiệm**, không viết tắt, không mơ hồ.
  - ✅ `ProjectStateManager`, `ExecutionEngine`, `SkillRegistry`, `ContextEngine`
  - ❌ `Helper`, `Utils2`, `ManagerNew`, `ServiceFinal`
- Tên chuẩn hóa duy nhất theo AD-01…AD-08 (không dùng tên cũ đã hợp nhất):
  - Dùng `Kernel` — không dùng "Planner service" / "Executive Brain service" riêng.
  - Dùng `ContextEngine` — không dùng "ContextLoader" / "ContextBuilder".
  - Dùng `AIGateway` — không dùng "ModelRouter" / "TokenManager" như component đỉnh.
  - Workflow là `SkillComposition` — không có "WorkflowEngine".
- File Swift: một type chính mỗi file, tên file = tên type.

## 4. Quy tắc vệ sinh

- **Temporary data** dùng thư mục tạm của hệ thống, tự dọn — không bao giờ nằm trong cấu trúc dự án.
- **Generated files** (nếu có) nằm tách biệt, đưa vào `.gitignore` khi phù hợp.
- **Git:** commit nhỏ, message rõ; không commit file sinh tự động không cần thiết.
- Mỗi thư mục lớn (`Core/*`, `Modules/*`) có README ngắn: Purpose · Responsibilities · Dependencies · Public Interfaces. Không viết tài liệu thừa.
