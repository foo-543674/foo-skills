# Bootstrap チェックリスト

各 Phase の完了判定に使う。

## Phase 1: Seed

- [ ] プロジェクトの目的が 1-2 文に凝縮されている
- [ ] 技術スタック (言語・FW・ランタイム) が確定している
- [ ] プロジェクトの規模感 (個人/チーム、短期/長期) が明確
- [ ] 既存プロジェクトの場合、現状調査が完了している

## Phase 2: Context Design

- [ ] philosophy/ を読み込んだ
- [ ] 関連する perspectives を選定した
- [ ] プロジェクト固有の例外・調整をユーザーに確認した

## Phase 3: Generate AI Context

- [ ] **AGENTS.md (原典) が生成された** — プロジェクト指示の単一原典として全 AI ツール向け内容を収録
- [ ] CLAUDE.md が生成された (`@AGENTS.md` で AGENTS.md を import している)
- [ ] GEMINI.md が生成された (`@AGENTS.md` で AGENTS.md を import している、Gemini CLI 利用者がいる場合)
- [ ] .github/copilot-instructions.md が生成された (GitHub Copilot 利用の場合、AGENTS.md から派生生成)
- [ ] .cursorrules が生成された (Cursor 利用者がいる場合、AGENTS.md から派生生成)
- [ ] 派生生成系ファイルの冒頭に「派生元: AGENTS.md / 再 bootstrap で再同期」を明記している
- [ ] コミット規約が AGENTS.md に含まれている
- [ ] AI の判断委任範囲が AGENTS.md に明示されている
- [ ] 設計成果物の役割分担 (canonical 領域 / 実装計画のスコープ / 3 階層の目的) が AGENTS.md に含まれ、技術スタックに合わせて具体化されている
- [ ] .contexts/bootstrap-decisions.md に判断記録が残されている

## Phase 4: Generate Architecture Tests

- [ ] テストツールが選定・導入された
- [ ] 依存方向のテストが生成された
- [ ] 型漏出のテストが生成された (該当する場合)
- [ ] CI にアーキテクチャテストが組み込まれた

## Phase 5: Technical Infrastructure

- [ ] **書ける**: 追加 install なしにコードが書き始められる
- [ ] **走る**: テスト・lint・format・型チェック・ビルドが成功する
- [ ] **止まる**: 規約違反・型エラー・テスト失敗が検知されて止まる
- [ ] **再現する**: devcontainer 等で別環境でも同じ結果になる
- [ ] **見える**: ログ・エラー・テストレポートが読める
- [ ] AGENTS.md の「開発コマンド」が実際のコマンドで埋まっている (CLAUDE.md / GEMINI.md は `@AGENTS.md` で連動)
- [ ] .claude/settings.json の allow が非破壊操作のみで構成されている (コンテナのライフサイクル操作・履歴破壊・環境削除は ask / deny)
- [ ] known-pitfalls.md の該当エントリを確認し、該当する場合は回避策を適用した
- [ ] ローカルレビューゲートが有効: git hook (pre-commit / pre-push) が決定的ゲートとレビュー記録を確認し、Claude Code PreToolUse hook が `git commit` / `git push` を差し戻す。迂回 (`--no-verify` / `core.hooksPath`) が deny されている (local-review-gate.md)
- [ ] リモートの AI レビュー workflow を生成していない
