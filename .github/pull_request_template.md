## 概要

<!-- この PR で何を解決するか -->

## 変更内容

-

## 検証

- [ ] `xcodegen generate` を実行した
- [ ] `xcodebuild ... build` が成功した
- [ ] `xcodebuild ... test` が成功した

```bash
xcodegen generate
xcodebuild -project SketchyBarSettings.xcodeproj \
  -scheme SketchyBarSettings \
  -destination 'platform=macOS' \
  -derivedDataPath .build \
  build
xcodebuild -project SketchyBarSettings.xcodeproj \
  -scheme SketchyBarSettings \
  -destination 'platform=macOS' \
  -derivedDataPath .build \
  test
```

## 実環境での確認

<!-- 「適用」ボタンで SketchyBar 設定を変更した場合は結果を記載。未実施ならその旨 -->

- [ ] 実環境での「適用」確認は未実施（ユニットテストのみ）
- [ ] 実環境で「適用」を確認した（結果: ）

## チェックリスト

- [ ] 秘密情報（API キー、トークン、個人パス）を含まない
- [ ] 既存の挙動を意図せず壊していない
- [ ] 必要に応じて README / CONTRIBUTING を更新した
- [ ] 関連 Issue があればリンクした（Fixes #）
