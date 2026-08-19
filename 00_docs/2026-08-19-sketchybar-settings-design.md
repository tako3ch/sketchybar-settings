# SketchyBar 設定パネル（SketchyBar Settings）要件定義

- 作成: 2026-08-19
- 形態: 個人用ツール（01_Private/_tools）・macOS メニューバー常駐アプリ

---

## 1. 概要

SketchyBar の **表示項目・並び順・見た目（バー全体／項目個別）** を GUI で編集できる
macOS メニューバー常駐アプリ。設定変更は `~/.config/sketchybar/sketchybarrc` を
**テンプレートから再生成して SketchyBar を再起動**することで反映する。

前提: ネイティブメニューバーは残し、SketchyBar を中央アイランド（下部に浮かべ）で
情報表示のみ運用（AeroSpace 無し・space ウィジェット無し）。本アプリはその
SketchyBar 設定の操作パネルにあたる。

## 2. 形態（アプリ）

- **メニューバー常駐型**: `LSUIElement = true`（Dock・アプリスイッチャーに非表示）
- メニューバーのアイコンクリックで **設定パネル（ポップオーバー）** を表示
- 技術: SwiftUI + `@Observable` + AppKit 連携、**XcodeGen** プロジェクト
- **配布前提**（他 Mac でも動く）: `xcodebuild` によるビルド・テスト検証ループ重視。
  Development / Release 両対応の署名

## 3. 反映メカニズム（核心の設計判断）

| 項目 | 決定 |
|---|---|
| 設定の保持 | アプリが UserDefaults（JSON）で保持。**`SettingsStore`（@Observable シングルトン）が唯一の導出点** |
| 生成元 | **テンプレート `sketchybarrc.template`**（人間が手編集可能・git 管理） |
| 反映 | テンプレートに設定値を埋め込んで `~/.config/sketchybar/sketchybarrc` を再生成 → SketchyBar 再起動 |
| 手動編集との共存 | テンプレート自体が書き換え可能なので、高度なカスタムはテンプレート側で行える |
| プラグイン | `plugins/*.sh, *.py` は**アプリが内容を管理・改変しない**（参照のみ） |

### 反映フロー
```
設定値 (UserDefaults JSON)
   ↓ 純粋な生成関数（テスト容易）
sketchybarrc.template ──▶ ~/.config/sketchybar/sketchybarrc
   ↓
SketchyBar 再起動（brew services restart sketchybar 相当）
   ↓
sketchybar --query <item> で反映確認
```

## 4. スコープ（MVP）

### 4-1. 表示項目（ウィジェット）管理
対象項目（現行設定に存在するもの）:
`date` / `clock` / `volume` / `audio_output` / `ai_usage` / `umi_icon` / `umi_status` /
`spotify` / `battery`

各項目に対して:
- **表示 ON/OFF**
- **配置**: 左 / 中央 / 右（変更時は移動先配置の末尾へ）
- **並び順**（同一配置内: ドラッグ&ドロップ + 上下ボタン。`SettingsStore.reorderWidget` / `moveWidgetBefore` に集約）

### 4-2. バー（全体）の見た目
- 位置（top / bottom）、**高さ**、**y_offset**（ネイティブメニューバーとの間隔）
- **角丸**（corner_radius）、**背景色 + 不透明度**（アースカラーパレット + ColorWell + Hex 双方向同期）、シャドウ on/off
- パディング（左右）、アイテム間スペース（Slider + 数値表示）
- **Spotify カバーサイズ**（16〜64 pt、`spotify_cover` の width / height / corner_radius / image.scale へ反映）

### 4-3. 項目個別のスタイル
- **テキスト色**（color。アースカラーパレット + ColorWell + Hex。`SketchyBarColorHex` で `0xAARRGGBB` 変換）
- **背景色**（`backgroundEnabled` / `backgroundHex`。アースカラーパレット + Hex。Spotify 本文と `spotify_cover` は同一設定）
- **フォント**: ファミリ（インストール済み一覧から Picker、既定 `SF Pro Text`）/ サイズ
- **アイコン**: 表示 on/off / 指定（SF Symbol・テキスト）
- 更新間隔（update_freq）は既存プラグイン定義を維持（変更対象としない）

### 4-4. UI 改善（2026-08-20 追加）
- `HexColorField`: ColorWell と Hex 入力の双方向同期、不正 Hex はエラー表示 + rc 生成時フォールバック
- `EarthColorCatalog`: 砂 / テラコッタ / オリーブ / モス / クレイ / チャコールブラウン / 深い森 / 透明のプリセットスウォッチ
- ウィジェット一覧: `ScrollView` + `LazyVStack`、行 D&D（同一配置内のみ）、ドロップ位置ハイライト
- スペース系設定: Stepper に加え Slider + pt 数値表示
- ウィジェット背景: 背景表示 Toggle + 背景色（プリセット + Hex）。旧設定 JSON は読み込み時に Spotify 背景を自動移行

## 5. 画面構成（設定パネル）

- **セクション1「項目（Widgets）」**: 項目一覧。ON/OFF トグル、配置切替（左/中央/右）、並び順操作
- **セクション2「バー（Bar）」**: 位置 / 高さ / y_offset / 角丸 / 背景色 / スペース
- **セクション3「スタイル（Style）」**: パネル上で選択中の項目の色・背景・フォント・アイコン
- **適用ボタン**: テンプレート再生成 → SketchyBar 再起動
- **リセット**: デフォルト値へ / テンプレート再読込

## 6. 検証方針

- `xcodebuild` build / test
- テンプレート→rc 生成関数の**単体テスト**（期待値スナップショットで差分検出）
- Color Hex 変換（有効 / 不正 / 透明度）、D&D 順序変更、フォント・Spotify カバーサイズ反映の単体テスト
- 反映後、`sketchybar --query <item>` で対象項目の状態を確認（ヘッドレス検証）
- 実機の見た目（アイランドの位置・並び）はユーザー確認

## 7. 非スコープ（今回はやらない）

- AeroSpace / 他 WM との連携
- プラグインスクリプトの中身の編集・管理（内容は管理しない）
- 「ライブ --set での即時反映」（基本は再生成 + 再起動方式）
- 複数モニタ・notch 対応の高度化

## 8. 設計方針（既存流儀に準拠）

- `SettingsStore`（@Observable シングルトン）が設定の唯一の導出点
- テンプレート→rc 生成は**純粋関数**に分離してテストする
- 項目・配置・プロパティは enum / データモデルで明示（ハードコードの散在を避ける）
- 反映は `Process` で CLI 実行（配布前提 → サンドボックス外・もしくは一時例外を明示）
- Swift の罠（スキル `swiftui-macos-development` 参照）:
  - `@State` に `@Observable` インスタンスを入れない（表示が更新されない）
  - バインディングが必要なら `@Bindable` シャドウイング
  - Swift 識別子に「〜」を使わない（swiftc クラッシュ）
  - Swift 文字列補間・keypath を含む編集は patch でなく raw 文字列 / Python で行う

## 9. プロジェクト構成（予定）

```
01_Private/_tools/sketchybar-settings/
├── 00_docs/                      # 本要件・設計書
├── 03_src/
│   ├── project.yml               # XcodeGen
│   └── SketchyBarSettings/       # Swift ソース
│       ├── App/                  # エントリ・LSUIElement
│       ├── Models/               # 項目定義・設定モデル（単一導出点）
│       ├── Services/             # テンプレート生成・SketchyBar 再起動
│       ├── Views/                # 設定パネル UI
│       └── Resources/            # sketchybarrc.template・アイコン
│   └── SketchyBarSettingsTests/  # 生成関数の単体テスト
└── README.md
```
