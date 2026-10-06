# 分層（layering）Roadmap

目標：手機上的 Mochi 要像手機，桌面維持現在的樣子。Mochi 的元件 API 參考網頁框架，card、field 都是同一個 surface 色，靠 1px 框線和陰影隔開，放在 iPhone 上像一張平的紙。Material 的失敗是反過來：放到網頁上像被拉寬的手機 app。所以不選邊，**材質和顏色共用，分層方式跟著 `theme.touch` 走**。

**完成的定義**：元件 + gallery 比較頁 + widget test + light/dark 都檢查過，而且在 iPhone 上看過（測試用 Skia，看不到 Impeller 的實際畫面）。

## 已決定

- **不做玻璃材質**。Liquid Glass 只是舉例；不做模糊、折射、`BackdropFilter`。
- **不換底色，改加深陰影**。第一版試過 Catppuccin surface0/1/2 的底色分層（`layer1/2/3`），看起來怪，已整個移除。淺色底色往深疊會讓文字對比掉到 4.4 以下，也是原因之一。
- **`layering` 跟著 `touch` 走**：touch 是 `raised`，否則是 `outlined`；`MochiDefaults(layering:)` 可以覆蓋。
- **field 不加陰影**，維持框線。
- 陰影只給浮起來的東西；平放的東西靠框線。
- 深色背景太暗，黑色陰影不明顯：深色的 raised card 另外加一層白色光暈。

---

## 1. 開關

- [x] `MochiLayering { outlined, raised }`，`MochiTheme.layering` 預設跟著 `touch`
- [x] `MochiDefaults.layering` 覆蓋
- [x] 測試：預設跟 touch、覆蓋
- [x] `CLAUDE.md` 補一段 Layering 說明

## 2. 加深陰影（`raised`）

- [x] **card**：不畫框、底色改用 `overlay`（比頁面亮：淺色是白、深色是 surface0，不然陰影只會從淺灰漸變到深灰、沒有邊緣）、陰影比 `elevation` 深一階、圓角 `md` → `lg`；`selected` 也不畫框，只用 intent 色的淡底色；`outlined` / `soft` 外觀不變
- [x] **soft card**：raised 時圓角 `md` → `lg`、完全不畫框（含 selected）、不加陰影；`outlined` 不動
- [x] 在 iPhone 上看過（web 版，淺色），決定陰影深度夠不夠（可能需要 touch 專用的陰影層）
- [x] 深色模式的陰影：黑影在暗背景看不見，改在黑影上加白色光暈（alpha 0.5、模糊 12、spread 1；原本 0.35 / 24 太糊，並排的 card 會黏在一起）。試過頂端亮線，看起來怪；光暈 0.12 / 0.22 太淡
- [x] **tile group**：整組一塊、底色 `overlay`、沒有框，用 `MochiShadows.raised` 托起、圓角 `lg`；列的底色跟著組；分隔線保留
- [x] **bottom nav**：不畫上緣那條線，底色用 `overlay`，改用向上的陰影（深色一樣有光暈；`MochiShadows.raised` 是 card 和 bar 共用的）
- [ ] **dialog / sheet / popover / menu**：確認已有的陰影在 raised 下不重複、深度一致
- [ ] 每改一個元件就補一個 raised 的測試，並確認 outlined 的原有測試不動

## 3. gallery 比較頁

- [ ] gallery 加一頁「分層」：同一組內容（一張有標題的 card、兩個 field、一個 select、下方 bottom nav）outlined 和 raised 並排
- [ ] top bar 的 look bar 加 layering 切換（跟著 touch / outlined / raised）
- [ ] `gallery_smoke_test` 涵蓋新頁面

## 4. 浮起來的 bar

- [ ] **bottom nav**：touch 模式下離開螢幕邊緣，變成懸浮的膠囊；選中的那一格是一顆比較亮的膠囊
- [ ] **header**：touch 模式下預設用 `floating` variant
- [ ] **`MochiScaffold.extendBody`**：內容延伸到 header / footer 底下，並把量出來的高度加進 `MediaQuery.padding`，捲動區自動留空。預設關閉，先在比較頁和 app 各開一頁看
- [ ] 浮起來的 bar 配 `md` 陰影，確認不被 `ClipRect` 裁掉

## 5. 手機才有的動作

跟分層無關，任何時候都可以插進來：

- [ ] **select / 選單 / 右鍵選單在手機上改成 bottom sheet**（規則同 date picker：平板寬度以上用 popover）。CP 值最高
- [ ] **`MochiSwipeActions`**：清單列滑開出現動作（例如紀錄列滑開出現刪除）
- [ ] **大標題 header**：捲動時從大標題縮成 bar 上的小標題（等第 4 節完成）

## 風險

- **外觀整個變**：`raised` 影響幾乎所有元件，gallery 和 app 都要檢查一遍；每次只改一個元件。
- **測試看不出畫面差異**：每一階段都要在 iPhone 上看。
- **對比**：底色一變，文字對比要重新驗證，尤其淺色模式下 `mutedForeground` 放在較深的那一階上。
