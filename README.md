# SketchyBar Settings

SketchyBar の表示項目・並び順・見た目を GUI で編集する macOS メニューバー常駐アプリです。

## スクリーンショット

<!-- TODO: スクリーンショットを追加する（例: docs/screenshots/settings-panel.png） -->

## 目的

SketchyBar の `sketchybarrc` を手編集せずに、ウィジェットの ON/OFF・配置・スタイル・バー外観を視覚的に設定し、ワンクリックで適用できるようにします。

## 必要環境

| 項目 | 要件 |
|---|---|
| OS | macOS 14 以上 |
| Xcode | Swift 5.9 対応版（Command Line Tools 以上） |
| [XcodeGen](https://github.com/yonaskolb/XcodeGen) | `project.yml` から `.xcodeproj` を生成 |
| [SketchyBar](https://github.com/FelixKratz/SketchyBar) | メニューバー表示の本体（適用時に再起動） |

### 依存ツールの導入

XcodeGen（Homebrew core）:

```bash
brew install xcodegen
```

SketchyBar（[felixkratz/formulae](https://github.com/FelixKratz/homebrew-formulae) タップ）:

```bash
brew tap felixkratz/formulae
brew install sketchybar
brew services start sketchybar
```

Intel Mac では Homebrew のパスが `/usr/local` になる場合があります。アプリは既定で `/opt/homebrew/bin/brew` と `/opt/homebrew/bin/sketchybar` を参照します。

## SketchyBar の前提

- SketchyBar がインストール済みで、通常は Homebrew の `brew services` で管理されていること
- 適用時に `~/.config/sketchybar/sketchybarrc` を再生成し、同梱の `spotify.sh` を `~/.config/sketchybar/plugins/` へ同期します
- 再起動は `brew services restart sketchybar` で行います

## ビルド

リポジトリには `.xcodeproj` を含めません。必ず XcodeGen で生成してください。

```bash
xcodegen generate
xcodebuild -project SketchyBarSettings.xcodeproj \
  -scheme SketchyBarSettings \
  -destination 'platform=macOS' \
  -derivedDataPath .build \
  build
```

ビルド成果物: `.build/Build/Products/Debug/SketchyBarSettings.app`

## テスト

```bash
xcodebuild -project SketchyBarSettings.xcodeproj \
  -scheme SketchyBarSettings \
  -destination 'platform=macOS' \
  -derivedDataPath .build \
  test
```

テストは `TemplateRenderer` / `SettingsStore` / `SketchyBarApplier` のモック境界を検証します。**実環境の SketchyBar 再起動は行いません。**

## 起動・適用

Xcode から `SketchyBarSettings` スキームを Run するか、ビルド成果物を起動します。

```bash
open .build/Build/Products/Debug/SketchyBarSettings.app
```

- Dock には表示されません（`LSUIElement = true`）
- メニューバーのスライダーアイコンから設定パネルを開きます
- 「適用」で `~/.config/sketchybar/sketchybarrc` を再生成し、同梱 `spotify.sh` を `~/.config/sketchybar/plugins/` へ同期（実行権限を付与）、`brew services restart sketchybar` を実行します

## 設定ファイル

| 種類 | パス |
|---|---|
| アプリ内設定（JSON） | UserDefaults キー `sketchybar.settings.v1` |
| 生成先 rc | `~/.config/sketchybar/sketchybarrc` |
| プラグイン（適用時に同期） | `~/.config/sketchybar/plugins/spotify.sh` |

生成された `sketchybarrc` 先頭には `DO NOT EDIT BY HAND` コメントが付きます。生成元はアプリ同梱の `SketchyBarSettings/Resources/sketchybarrc.template` で、バー設定やウィジェット配置はプレースホルダー置換で反映されます。高度なカスタムはテンプレートと `WidgetCatalog` の編集で対応します。

### Spotify カバーと `spotify.sh`

`spotify_cover` の width / height / scale / corner_radius は **sketchybarrc の初期設定**で決まります。同梱 `Resources/plugins/spotify.sh` は画像パスと drawing の更新のみ行い、サイズ関連プロパティは rc を尊重します。「適用」時にこのスクリプトを plugins へコピーし、実行権限を付与します。

### アースカラーパレット

バー背景色・項目テキスト色・項目背景色の Hex 入力欄の下に、クリック可能な丸スウォッチを表示します。

| 名称 | Hex |
|---|---|
| 砂 | `0xFFD8C3A5` |
| テラコッタ | `0xFFC97C5D` |
| オリーブ | `0xFF87986A` |
| モス | `0xFF606C38` |
| クレイ | `0xFF9C6644` |
| チャコールブラウン | `0xFF3C2F2F` |
| 深い森 | `0xFF283618` |
| 透明 | `0x00000000` |

### ウィジェット背景

各ウィジェットに `backgroundEnabled` / `backgroundHex` を設定できます。Spotify 本文と `spotify_cover` は同一の背景色設定を共有します。

## 主な機能

- ウィジェット ON/OFF、左/中央/右配置、配置内の並び順（ドラッグ&ドロップ + 上下ボタン）
- バー: 高さ、y_offset、角丸、背景色、シャドウ、左右パディング、項目間隔
- Spotify カバー（`spotify_cover`）サイズ: 16〜64 pt
- 項目スタイル: 色、フォントファミリー、フォントサイズ、アイコン表示
- 項目背景: 背景表示 on/off、背景色
- デフォルトへリセット、適用時の成功/エラー表示

対象ウィジェット: `date` / `clock` / `volume` / `audio_output` / `ai_usage` / `umi_icon` / `umi_status` / `spotify` / `battery`

## 制約

- ライブ `sketchybar --set` による即時反映は行いません（再生成 + 再起動方式）
- 適用時に同期するプラグインは `spotify.sh` のみ（他スクリプトは手動管理）
- SoundSource エイリアスなど環境依存の設定は生成 rc 内コメントとして残します
- サンドボックスは無効（`~/.config/sketchybar/` への書き込みと `brew` 実行のため）

## 既知の注意点

- 「適用」は実際の SketchyBar 設定を上書きします。事前に `sketchybarrc` のバックアップを推奨します
- `umi_icon` / `umi_status` / `ai_usage` などは個人環境向けのウィジェット定義を含みます。不要な項目は OFF にしてください
- ColorWell が動作しない環境では、アースカラーパレットと Hex 入力で色を設定できます

## プロジェクト構成

```
├── project.yml
├── SketchyBarSettings/
│   ├── App/
│   ├── Models/
│   ├── Utilities/
│   ├── Resources/
│   │   ├── sketchybarrc.template
│   │   └── plugins/
│   │       └── spotify.sh
│   ├── Services/
│   └── Views/
└── SketchyBarSettingsTests/
```

## 貢献

バグ報告・機能提案・Pull Request を歓迎します。詳細は [CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。

## ライセンス

[MIT License](LICENSE) — Copyright (c) 2026 Takumi Kato
