# SketchyBar Settings

SketchyBar の表示項目・並び順・見た目を GUI で編集する macOS メニューバー常駐アプリです。

## 要件

- macOS 14 以上
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- SketchyBar（Homebrew 経由のインストールを想定）

## ビルド

```bash
cd 03_src
xcodegen generate
xcodebuild -project SketchyBarSettings.xcodeproj \
  -scheme SketchyBarSettings \
  -destination 'platform=macOS' \
  -derivedDataPath .build \
  build
```

## テスト

```bash
cd 03_src
xcodebuild -project SketchyBarSettings.xcodeproj \
  -scheme SketchyBarSettings \
  -destination 'platform=macOS' \
  -derivedDataPath .build \
  test
```

テストは `TemplateRenderer` / `SettingsStore` / `SketchyBarApplier` のモック境界を検証します。実環境の SketchyBar 再起動は行いません。

## 起動

Xcode から `SketchyBar Settings` スキームを Run するか、ビルド成果物を起動します。

- Dock には表示されません（`LSUIElement = true`）
- メニューバーのスライダーアイコンから設定パネルを開きます
- 「適用」で `~/.config/sketchybar/sketchybarrc` を再生成し、同梱 `spotify.sh` を `~/.config/sketchybar/plugins/` へ同期（実行権限を付与）、`brew services restart sketchybar` を実行します

## 設定ファイル

| 種類 | パス |
|---|---|
| アプリ内設定（JSON） | UserDefaults キー `sketchybar.settings.v1` |
| 生成先 rc | `~/.config/sketchybar/sketchybarrc` |
| プラグイン（適用時に同期） | `~/.config/sketchybar/plugins/spotify.sh`（同梱版を上書きコピーし、実行権限 0755 を付与） |

生成された `sketchybarrc` 先頭には `DO NOT EDIT BY HAND` コメントが付きます。生成元はアプリ同梱の `SketchyBarSettings/Resources/sketchybarrc.template` で、バー設定やウィジェット配置はプレースホルダー置換で反映されます。高度なカスタムはテンプレートと `WidgetCatalog` の編集で対応します。

### Spotify カバーと `spotify.sh`

`spotify_cover` の width / height / scale / corner_radius は **sketchybarrc の初期設定**で決まります。以前の `spotify.sh` はメディア更新のたびに `background.image.scale=0.05` 等を上書きしていたため、アプリでカバーサイズを変えても表示が変わりませんでした。同梱 `Resources/plugins/spotify.sh` は画像パスと drawing の更新のみ行い、サイズ関連プロパティは rc を尊重します。「適用」時にこのスクリプトを plugins へコピーし、実行権限を付与します（`copyItem` では権限が保持されないため明示的に `chmod 755` 相当を行います）。

### アースカラーパレット

バー背景色・項目テキスト色・項目背景色の Hex 入力欄の下に、クリック可能な丸スウォッチを表示します。ColorWell が動作しない環境でもプリセットと Hex 入力で設定できます。プリセット選択は即座に UserDefaults へ保存されます。

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

パネル背景など不透明度を持つ用途では `0xAARRGGBB` 形式（例: `0xD02A2A37`）を維持します。

### ウィジェット背景

各ウィジェットに `backgroundEnabled` / `backgroundHex` を設定できます。`backgroundEnabled=true` のとき `background.drawing=on` と色・角丸・高さを sketchybarrc に生成します。Spotify 本文と `spotify_cover` は同一の背景色設定を共有します。既定値は Spotify のみ背景表示 ON（`0xD02A2A37`）、他ウィジェットは OFF です。

## MVP 機能

- ウィジェット ON/OFF、左/中央/右配置、配置内の並び順（ドラッグ&ドロップ + 上下ボタン）
- バー: 高さ、y_offset、角丸、背景色（アースカラーパレット + NSColorWell + Hex）、シャドウ、左右パディング、項目間隔（Slider + 数値表示）
- Spotify カバー（`spotify_cover`）サイズ: 16〜64 pt
- 項目スタイル: 色（アースカラーパレット + NSColorWell + Hex）、フォントファミリー、フォントサイズ、アイコン表示
- 項目背景: 背景表示 on/off、背景色（アースカラーパレット + Hex）。Spotify は既定で背景表示 ON
- デフォルトへリセット、適用時の成功/エラー表示

対象ウィジェット: `date` / `clock` / `volume` / `audio_output` / `ai_usage` / `umi_icon` / `umi_status` / `spotify` / `battery`

## 制約

- ライブ `sketchybar --set` による即時反映は行いません（再生成 + 再起動方式）
- 適用時に同期するプラグインは `spotify.sh` のみ（他スクリプトは手動管理）
- SoundSource エイリアスなど環境依存の設定は生成 rc 内コメントとして残します
- サンドボックスは無効（`~/.config/sketchybar/` への書き込みと `brew` 実行のため）

## プロジェクト構成

```
03_src/
├── project.yml
├── SketchyBarSettings/
│   ├── App/
│   ├── Models/
│   ├── Utilities/                # SketchyBarColorHex, FontFamilies, EarthColorCatalog
│   ├── Resources/
│   │   ├── sketchybarrc.template
│   │   └── plugins/
│   │       └── spotify.sh
│   ├── Services/
│   └── Views/
└── SketchyBarSettingsTests/
```
