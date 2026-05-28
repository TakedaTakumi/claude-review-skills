# legacy/ — 凍結された旧仕様

この配下は、claude-review-skills 移行（Phase 1〜8）で再構築する前の **旧 Slash Command の単一ファイル仕様** を保持しています。

| ファイル | 内容 |
|---|---|
| [review-branch.md](review-branch.md) | 旧 `/review-branch` の単一ファイル仕様 |
| [review-repo.md](review-repo.md) | 旧 `/review-repo` の単一ファイル仕様 |
| [review-slice.md](review-slice.md) | 旧 `/review-slice` の単一ファイル仕様 |

## 位置付け

- これらは移行作業のトレーサビリティ・設計判断の照合のために保持されている **歴史的資料** です。
- **現運用の真実の源ではありません**。現運用は Skill + Sub Agent + 軽量 Slash Command の組み合わせで提供されます。
- **編集禁止**: このディレクトリのファイルは編集しないでください。

## 真実の源

現運用の観点・分類・テンプレート・Sub Agent・Slash Command の真実の源:

| 種類 | 場所 |
|---|---|
| 観点・分類カタログ | [skills/code-review-perspectives/SKILL.md](../../skills/code-review-perspectives/SKILL.md) |
| 観点本体（32観点） | [skills/code-review-perspectives/perspectives/](../../skills/code-review-perspectives/perspectives/) |
| 分類（8分類） | [skills/code-review-perspectives/categories/](../../skills/code-review-perspectives/categories/) |
| テンプレート | [skills/code-review-perspectives/templates/](../../skills/code-review-perspectives/templates/) |
| Sub Agent | [agents/](../../agents/) |
| Slash Command | [commands/](../../commands/) |
| 移行時の差分記録 | [docs/MIGRATION_NOTES.md](../MIGRATION_NOTES.md) |
