# Contributing to SketchyBar Settings

ご協力ありがとうございます。小さな修正から大きな機能追加まで歓迎します。

## 開発環境

- macOS 14 以上
- Xcode（Swift 5.9）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
```

SketchyBar 本体はアプリの実行・手動確認時に必要です（ユニットテストではモックを使用）。

```bash
brew tap felixkratz/formulae
brew install sketchybar
```

## プロジェクト生成

`.xcodeproj` はリポジトリに含めません。clone 後に必ず生成してください。

```bash
xcodegen generate
```

## ビルド

```bash
xcodebuild -project SketchyBarSettings.xcodeproj \
  -scheme SketchyBarSettings \
  -destination 'platform=macOS' \
  -derivedDataPath .build \
  build
```

## テスト

```bash
xcodebuild -project SketchyBarSettings.xcodeproj \
  -scheme SketchyBarSettings \
  -destination 'platform=macOS' \
  -derivedDataPath .build \
  test
```

ユニットテストは `TemplateRenderer` / `SettingsStore` / `SketchyBarApplier` の境界を検証します。**テスト実行中に SketchyBar は再起動されません。**

## 実環境での確認（テストと分離）

アプリの「適用」機能を手動で試す場合は、以下に注意してください。

- `~/.config/sketchybar/sketchybarrc` が上書きされます
- `brew services restart sketchybar` が実行されます
- 本番のメニューバー設定に影響します

手動確認前に `sketchybarrc` をバックアップし、テスト用マシンまたは自分の環境でのみ実行してください。CI やユニットテストに実環境適用を組み込まないでください。

## 変更方針

- 既存の Swift コードスタイルに合わせる
- スコープを絞った変更を優先する（無関係なリファクタリングは避ける）
- 挙動を変える変更にはテストを追加・更新する
- 秘密情報（API キー、個人パス、トークン）をコミットしない

## Pull Request の出し方

1. Issue で議論するか、小さな修正はそのまま PR を作成
2. `xcodegen generate` 後に build / test が通ることを確認
3. 変更内容と検証手順を PR テンプレートに記入
4. 実環境で「適用」を試した場合は、その結果を PR に明記

質問や提案は [GitHub Issues](https://github.com/tako3ch/sketchybar-settings/issues) を利用してください。

## 行動規範

[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) に従ってください。
