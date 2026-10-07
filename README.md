# mk-skills

Bộ skill cho AI coding agent (Claude Code, omp và các agent đọc thư mục skill chuẩn). Hiện có một skill: **`mk-specs`** — Spec-Driven Development (SDD).

*English summary at the end.*

## mk-specs là gì

`mk-specs` dạy agent làm việc theo spec: người chốt *ý định* trong thư mục `specs/` (Business Requirement, Use Case, Entity, Acceptance Criteria, ADR), AI viết test và code theo spec; khi có gì sai thì sửa spec trước rồi mới sửa code.

Skill gồm:

- **Quy trình** cho từng việc: khởi tạo specs (dự án mới hoặc codebase đang chạy), đề xuất thay đổi, thực hiện, hợp nhất, viết commit, kiểm tra, rà soát.
- **Mẫu** UC, BR, ADR, proposal, entity, README cho `specs/`.
- **Scripts** (Python chuẩn, không cần cài thêm gì): sinh `traceability.md` (UC ↔ AC ↔ test) và `open-issues.md` (mọi `[DIVERGENCE]`/`[OPEN]`), kiểm mọi tên test được trích có thật và mọi link mở được, tính chỉ số AC Coverage / Spec Coverage / Trace Ratio, báo cáo vệ sinh spec.
- **Cổng cứng**: không AC thì không code; luật tiền / quyền truy cập / bảo mật do người quyết, AI chỉ đề xuất; spec không nói thì không đoán; không tự duyệt; commit spec trước code và mọi commit mang ID UC/BR/ADR.

## Vì sao SDD

Khi AI viết phần lớn code, điều gì không được viết ra thì với AI coi như không tồn tại — nó lấp chỗ trống bằng xác suất. Spec rõ giúp AI đi nhanh *đúng hướng*; AC gắn test cho phép AI viết lại code mà vẫn biết hành vi có vỡ không; lịch sử quyết định nằm trong git chứ không nằm trong trí nhớ của ai. Xem `skills/mk-specs/references/principles.md`, kể cả phần "khi nào **không** nên dùng".

## Yêu cầu

- `bash` (macOS hoặc Linux), `python3` ≥ 3.8, `git`.
- Một agent đọc skill: Claude Code (`~/.claude/skills`, `<repo>/.claude/skills`), omp hoặc agent khác đọc `~/.agents/skills` / `.claude/skills`.

## Cài đặt

```bash
git clone https://github.com/minhtv0101/mk-skills.git
cd mk-skills

./install.sh --global                      # ~/.claude/skills/mk-specs và ~/.agents/skills/mk-specs
./install.sh --project ~/code/my-shop      # <repo>/.claude/skills/mk-specs + tạo specs/mk-specs.yml nếu chưa có
./install.sh --global --project ~/code/my-shop   # cả hai
```

- Luôn **chép**, không symlink — bản trong project được commit cùng repo, nên mọi người (và CI) chạy cùng một phiên bản scripts.
- Bản project có sửa tay chưa commit → `install.sh` từ chối ghi đè; commit/bỏ thay đổi trước, hoặc thêm `--force`.
- Script in phiên bản cũ → mới sau mỗi lần cài.

Khi project dùng `npm`, thêm vào `package.json`:

```json
"specs:gen": "python3 .claude/skills/mk-specs/scripts/gen.py",
"specs:check": "python3 .claude/skills/mk-specs/scripts/verify.py"
```

## Cập nhật

```bash
cd mk-skills && git pull
./install.sh --global --project ~/code/my-shop
```

Rồi trong project: chạy `specs:gen` — `traceability.md`/`open-issues.md` phải không đổi nếu spec không đổi — và commit `.claude/skills/mk-specs` (`chore(specs): update mk-specs to vX.Y.Z`). Agent sẽ cảnh báo khi bản cài chung khác bản trong project.

## Gỡ cài đặt

```bash
./install.sh --uninstall --global
./install.sh --uninstall --project ~/code/my-shop   # giữ lại specs/ và specs/mk-specs.yml
```

## Cấu hình `specs/mk-specs.yml`

Ví dụ cho một cửa hàng online:

```yaml
version: 1
language: vi
specs_dir: specs
contexts:
  - id: catalog
    title: "Danh mục (catalog)"
  - id: checkout
    title: "Đặt hàng (checkout)"
ids:
  uc: 'UC-\d{3}'
  br: 'BR-\d+'
  adr: 'ADR-\d+'
decisions_file: decisions.md
tests:
  list_command: "npx vitest list --json"   # in JSON [{file, name}]
  citation_style: pointer                  # pointer | name | both
readme:
  banner:
    match: '^> (Cập nhật|Hợp nhất) '
    keep: 5
  lines:
    - match: '^(?P<uc>\d+) UC · (?P<ac>\d+) AC · (?P<tested>\d+) AC có test'
metrics:
  since: "2026-01-31"                      # ngày áp dụng, mốc đo Trace Ratio
  exempt_scopes: [specs, deps]
```

Đủ các khoá và mặc định: `skills/mk-specs/references/traceability.md` §5; mẫu có chú thích: `skills/mk-specs/assets/mk-specs.yml.template`. File dùng **YAML rút gọn** (map, list, chuỗi có/không nháy, số, true/false/null, `[a, b]`, chú thích) để scripts không cần PyYAML.

## Các mode

Gọi bằng lời thường; agent tự chọn mode.

| Mode | Làm gì | Ví dụ câu lệnh |
|---|---|---|
| `init` | Dựng `specs/` cho dự án mới (BR → UC → AC) hoặc codebase đang chạy (5 bước brownfield) | "Khởi tạo SDD cho repo này theo mk-specs, đây là codebase đang chạy." |
| `change` | Viết proposal trong `specs/changes/<yyMMdd>-<slug>/`, review hai phía | "Đề xuất thay đổi: mã QR thanh toán hết hạn sau 15 phút thay vì 5." |
| `apply` | Test theo AC (đỏ → xanh) rồi code theo proposal đã duyệt | "Làm proposal 260131-qr-het-han đã duyệt." |
| `merge` | Hợp nhất vào UC/ADR, History có hash, archive, sinh lại file | "Hợp nhất change 260131-qr-het-han vào specs." |
| `check` | Chạy gen + verify, giải thích lỗi và chỉ số | "Kiểm spec và test có khớp nhau không." |
| `commit` | Viết commit `<type>(UC-xxx): …` từ diff đang stage | "Viết commit message cho thay đổi đang stage." |
| `audit` | Báo cáo mục thiếu, chữ kỹ thuật trong flow/AC, commit thiếu ID | "Rà soát chất lượng specs và quy trình SDD." |

## Cấu trúc repo

```
mk-skills/
├── install.sh
├── LICENSE
├── README.md
└── skills/mk-specs/
    ├── SKILL.md                 điểm vào: chọn mode, cổng cứng, scripts
    ├── references/              principles, artifacts, workflow-change, workflow-bootstrap, traceability, anti-patterns
    ├── assets/                  mk-specs.yml.template, templates/ (UC, BR, ADR, proposal, entities, README)
    └── scripts/                 gen.py, verify.py, audit.py, commit-hash.py, mkspecs.py, tests/
```

## Đóng góp

- Issue/PR bằng tiếng Việt hoặc tiếng Anh đều được. Commit theo Conventional Commits.
- Sửa scripts: giữ thư viện chuẩn, đầu ra tất định; chạy `python3 -m unittest discover -s skills/mk-specs/scripts/tests` và `bash -n install.sh`.
- Sửa skill: `SKILL.md` và mỗi reference dưới 300 dòng, không lặp nội dung giữa chúng; ví dụ dùng dữ liệu giả, không đưa thông tin riêng của dự án nào vào.
- Tăng `metadata.version` trong `SKILL.md` theo semver khi phát hành.

## Ghi công

Tri ân anh **Huy (huynt — [huynt.dev](https://huynt.dev))**, tác giả ebook *Spec Driven Development*. Phương pháp trong `mk-specs` — sáu nguyên tắc, bốn tầng yêu cầu, mẫu UC/BR, quy trình greenfield và brownfield, các chỉ số và anti-pattern — dựa trên cuốn sách này; skill diễn giải lại và ghi số trang để tra cứu, không chép nguyên văn. Cuốn sách tổng hợp từ **AI Unified Process** (Simon Martinelli), **GitHub Spec Kit**, **OpenSpec**, **Domain-Driven Design** và **Hexagonal Architecture**.

Phần `mk-specs` thêm vào (đánh dấu ✚ trong references): đánh dấu `[DIVERGENCE]`/`[OPEN]` và luật trọng tài giữa specs/docs/plans, ma trận truy vết sinh tự động và kiểm bằng máy, ADR có phương án bị loại và "Verified in code", History mang hash commit, giới hạn README — rút ra từ việc vận hành SDD trên các dự án thật.

## Giấy phép

MIT — xem [LICENSE](LICENSE).

---

## English

**mk-specs** is an agent skill for Spec-Driven Development. Humans agree on intent in `specs/` (business requirements, use cases, entities, acceptance criteria, ADRs); the AI writes tests and code from the spec; when something is wrong, fix the spec first. It ships workflows (init, change, apply, merge, check, commit, audit), templates, and stdlib-only Python scripts that generate a UC ↔ AC ↔ test traceability matrix and an open-issues list, verify every cited test exists and every relative link resolves, and report AC Coverage, Spec Coverage and Trace Ratio.

Install with `./install.sh --global` (copies to `~/.claude/skills` and `~/.agents/skills`) and/or `./install.sh --project <repo>` (copies to `<repo>/.claude/skills` and creates `specs/mk-specs.yml`). Requirements: bash, python3 ≥ 3.8, git. Skill text is Vietnamese; generated files support `language: vi | en`.

Credits: the method follows the ebook *Spec Driven Development* by Huy (huynt.dev), which builds on AI Unified Process (Simon Martinelli), GitHub Spec Kit, OpenSpec, DDD and Hexagonal Architecture. License: MIT.
