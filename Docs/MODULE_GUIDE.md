# MODULE_GUIDE.md — Cách viết một Module cho OSIRIS

> Tài liệu này là TẤT CẢ những gì bạn cần để viết module mới. Không cần đọc Core.
> Tham chiếu code duy nhất: `Core/Modules/Contracts/ModuleManifest.swift` (contract, ~50 dòng).
> Mẫu hoàn chỉnh để copy: `Modules/YouTube/YouTubeModule.swift`.

## 1. Module là gì

Một module = MỘT file Swift trong `Modules/<Tên>/`, chứa MỘT `ModuleManifest` — thuần data:

```swift
import OsirisCore   // import duy nhất được phép

public enum MyModule {
    public static let manifest = ModuleManifest(
        id: ModuleID("mymodule"),          // lowercase, không dấu cách
        version: "0.1.0",
        purpose: "Một câu mô tả module làm gì",
        skills: [skillA, skillB]           // kênh đóng góp DUY NHẤT
    )
}
```

## 2. Namespace (bắt buộc, máy cưỡng chế)

Mọi skill id PHẢI có prefix `<moduleID>.` — ví dụ `mymodule.skill-a`. Vi phạm = crash ngay khi khởi tạo manifest (precondition). Nhờ đó không thể đụng `core.*` hay module khác.

## 3. Skill = data

```swift
static let skillA = SkillDefinition(
    id: SkillID("mymodule.skill-a"),
    version: "1.0.0",
    capabilityTags: [CapabilityTag("mymodule"), CapabilityTag("việc-nó-làm")],
    purpose: "Một câu — hiện trong Advanced panel",
    inputs: ["goal"],
    outputs: ["tên-loại-output"],
    promptTemplate: """
    Hướng dẫn cho AI. Bắt buộc chứa đúng chuỗi {goal} — hệ thống thay bằng
    câu lệnh của user, máy móc, không sửa gì khác.

    Request: {goal}
    """,
    preferredModelTier: .light,        // .standard cho việc nặng (script dài, phân tích)
    triggerKeywords: ["cụm từ kích hoạt", "trigger phrase"]
)
```

- Template là chỗ DUY NHẤT đặt "nghiệp vụ". Không hàm, không if, không state, không gọi network/file — module chỉ là dữ liệu (bị Architecture Test quét).
- Skill cần dữ liệu thật (số liệu kênh, trend…): viết template phân tích **dữ liệu user dán vào goal**, kèm chỉ thị "dữ liệu không đủ thì nói rõ, không bịa". KHÔNG viết API client/tool — chưa có kênh đó trong contract (xem §9).
- Output cuối tự động được nối "Executive Summary + Next Steps" scaffold — KHÔNG tự viết cấu trúc đó vào template.

## 4. Cách hệ thống chọn skill (luật matcher — học thuộc)

1. Goal lowercase; skill được điểm = số keyword là **substring** của goal.
2. Nhiều điểm nhất thắng. **0 điểm = fallback AI trần (luôn đúng — thà miss còn hơn cướp sai).**
3. **Hòa điểm → id nhỏ hơn theo alphabet thắng** (`core.*` < `tiktok.*` < `youtube.*`).

Hệ quả phải nhớ khi chọn keywords:
- Keyword hẹp (cụm ≥2 từ) > keyword rộng (1 từ). Không bao giờ dùng tên platform đứng một mình ("tiktok") — mọi goal nhắc platform sẽ bị cướp.
- **Cross-module:** cụm từ chung chung ("publishing package") đã thuộc về module có trước — module mới PHẢI thêm định danh platform vào keyword của mình ("tiktok publishing package") nếu muốn cùng khái niệm.

## 5. Composition = skill có `compositionSteps`

```swift
static let aThenB = SkillDefinition(
    id: SkillID("mymodule.a-then-b"),
    ...không có promptTemplate...,
    compositionSteps: [SkillID("core.research-outline"), SkillID("mymodule.skill-b")],
    triggerKeywords: [/* union TUYỂN CHỌN — xem §6 */]
)
```

- Steps là ID — được resolve qua registry chung, nên **dùng skill của core hay module khác đều được** (nếu step thiếu lúc runtime → hệ thống tự degrade về AI trần, goal vẫn xong).
- 1–5 bước (precondition); mỗi bước = 1 AI call — ghi số call vào `purpose` cho user biết chi phí.
- Output bước trước tự nối vào prompt bước sau; CHỈ bước cuối nhận scaffold.

## 6. Curated union (luật keywords cho composition)

Union keywords của composition lấy từ các bước con, nhưng **tuyển chọn để composition chỉ thắng khi goal chứa CẢ HAI domain**, và **mọi ca hòa điểm phải rơi về single skill**. Quy trình bắt buộc:

1. Liệt kê mọi goal mẫu: thuần domain A, thuần domain B, cả hai.
2. Đếm điểm từng skill/composition cho từng goal — nhớ luật hòa §4.3.
3. Chỉnh union (thêm/bớt keyword rộng) đến khi: goal 2-domain → composition thắng SỐ ĐIỂM (không nhờ hòa); goal 1-domain → single skill thắng (điểm hoặc hòa-theo-id).
4. Pin MỖI ca bằng một test (§7). Tiền lệ thật: YouTube bỏ "script" khỏi union này nhưng giữ trong union kia — vì thứ tự id khác nhau. Đừng đoán, hãy đếm.

## 7. Tests bắt buộc (copy khuôn `Tests/ModuleTests/*`)

Mỗi module PHẢI có, chạy offline bằng `SequencedProvider`/`PromptCapture` (copy từ test YouTube):

1. **Manifest test:** mọi skill namespaced đúng; có promptTemplate HOẶC compositionSteps; có triggerKeywords; không trùng id với built-in.
2. **End-to-end test:** 1 goal thật → đúng template xuất hiện trong captured prompt.
3. **Precedence tests:** mỗi cặp keyword giao nhau (trong module, với module khác, với generic) = 1 test khẳng định goal về đúng skill; goal thuần-1-domain KHÔNG bị composition cướp.
4. **Sweep test:** với MỖI skill đơn (không composition) của module BẠN, không keyword nào chứa/bị chứa bởi keyword của BẤT KỲ skill/tool nào KHÁC (mọi namespace) — chứng minh module bạn không giẫm ai và không bị ai giẫm (copy `TikTokModuleTests.testTikTokSingleSkillKeywordsCollideWithNothing`). Composition được miễn (union chia sẻ keyword là cơ chế). Ghi chú: test này KHÔNG rà overlap nội bộ có chủ đích của module KHÁC (vd YouTube dùng chung "script") — đó là việc precedence tests của module đó lo.
5. **Composition test** (nếu có): 2 prompts đúng thứ tự, bước 2 chứa "Result of the previous step".

## 8. Đăng ký — đúng 1 dòng

`App/AppComposition/CompositionRoot.swift`, mảng `installedModules`:

```swift
let installedModules: [ModuleManifest] = [YouTubeModule.manifest, MyModule.manifest]
```

Đó là dòng DUY NHẤT ngoài thư mục module của bạn. Không sửa gì khác.

## 9. Tuyệt đối không được (Architecture Test sẽ đánh trượt build)

- Import bất kỳ thứ gì ngoài `OsirisCore`.
- Nhắc đến `Kernel`, `AIGateway`, `Store`, `ExecutionEngine`, `ExecutionPlan`, `WriteGate`, `EventBus`, `URLSession`, `FileManager`, `UserDefaults` — dù chỉ một chữ trong code.
- Logic: hàm, điều kiện, vòng lặp, state, persistence — module là struct literal.
- Tên module của bạn xuất hiện trong Core/Application/Presentation/Infrastructure (rule quét chuỗi).
- Sửa Core, contract, matcher, hay module khác "cho tiện". Cần thứ contract chưa có (tool/API/OAuth/event)? DỪNG — đó là quyết định kiến trúc M6 (AD-45), mang use case thật đến review, đừng tự mở.

## 10. Definition of Done cho một module mới

`swift test` xanh toàn bộ (cũ + mới) · 0 dòng thay đổi ngoài `Modules/<Tên>/`, `Tests/ModuleTests/`, và 1 dòng đăng ký · mọi checklist §7 có mặt.
