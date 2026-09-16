# Mochi UI Roadmap

優先順序依據 `~/things/project/mochi_cube_timer/apps/gui` 目前使用的 forui 元件（2026-09-16 統計，括號內為使用次數）。
標 ⭐ 的是 cube timer 沒用到、但我建議加上的項目。

**完成的定義**：元件 + 預覽頁（`lib/main.dart`）+ widget test + light/dark 都檢查過。

---

## 0. 基礎建設

- [x] 顏色系統：palette → `MochiColors` / `MochiTone` → 元件 style
- [x] Typography：`title` / `body` × `xs3…xl8`，Comfortaa + 假粉圓 fallback
- [x] 主題動畫（`AnimatedMochiTheme`）與狀態動畫（`MochiStateTransition`）
- [x] `MochiApp` / `MochiApp.router`（取代 `CupertinoApp`，搭配 go_router）
- [x] Theme 擴充機制 `MochiThemeExtension`（取代 material `ThemeExtension`）
- [x] `touch` 旗標（桌面 / 觸控兩套尺寸）
- [x] Geometry tokens `MochiGeometry`：圓角 xs–xl/full（superellipse）、間距 xs3–xl3、border 寬度、陰影 sm/md/lg、頁面 padding
- [x] 共用 focus ring `MochiFocusRing`（顏色 `colors.focusRing`，寬度 / 間隙在 geometry）
- [x] Motion tokens `MochiMotion`：state / theme 動畫時間、按壓彈簧
- [x] 按壓動畫：iOS 風格按下放大（`MochiPressScale`，彈簧回彈、上限 6% / 每邊 3px、尊重減少動態效果）
- [x] 圓角改用 superellipse（`RoundedSuperellipseBorder`）
- [x] Flutter 改跟 master：stable 3.47 的 Linux Impeller 沒開 MSAA，描邊和路徑都有鋸齒（flutter#191171，修正只在 master）
- [x] 圖示庫決定：Tabler（有 filled variant）。目前元件庫沒有任何內建圖示，換組是零成本
- [x] `MochiIcons` token：元件自己會畫的 8 個圖示，`copyWith(icons:)` 可整組替換
- [x] ⭐ 尺寸過渡動畫 — `MochiValueTransition<T>`：只在數值本身改變時才重跑（隱式 `Animated*` 會被主題動畫每幀重啟）。Button / Tile / Switch 已接上，時間為 `motion.sizeDuration`
- [ ] ⭐ 以 `ColorScheme` 產生主題的 helper（像 forui CLI preset），方便 app 換主色
- [ ] ⭐ 評估各元件是否需要獨立的 style 類別：目前只有 button 有（`MochiButtonStyle` / `MochiButtonMetrics`），其餘直接讀 token。forui 是每個 widget 一份 style，代價是每個元件多一份類別加 lerp。等 P3 的 dialog / popover 做完再看哪些真的需要覆寫
- [ ] ⭐ 評估導入 Widgetbook：等 P3 / P4 做完、元件穩定後再看。要導入的話放獨立 package（它的介面是 Material 的），現有的 gallery 保留矩陣視圖，Widgetbook 負責單一元件加 knobs

## 1. 已完成的元件

- [x] Tappable（8）— `MochiTappable`：hover / focus / pressed / selected / disabled、長按、雙擊、右鍵
- [x] Button（13）— `MochiButton`：6 intent × 6 appearance、selected、prefix / suffix、`size`（xs/sm/md/lg）
- [x] Button.icon（9）— `MochiButton.icon`：正方形圖示按鈕
- [x] Tooltip（4）+ TooltipGroup（1）— `MochiTooltip`：hover / 長按 / 鍵盤 focus
- [x] Icon（22）— Flutter `Icon` + `IconTheme`

## 2. P1：小元件

- [x] Divider（4）— `MochiDivider`：水平 / 垂直、indent
- [x] CircularProgress（3）— `MochiCircularProgress`：determinate / indeterminate，顏色跟隨外層文字色
- [x] Switch（2）— `MochiSwitch`：intent、focus ring、尊重減少動態效果
- [x] Card（2）— `MochiCard`：elevation、可選 onPress（hover 上色、不放大）
- [x] LinearProgress — `MochiLinearProgress`：determinate / indeterminate
- [x] Badge / Tag — `MochiBadge`：solid / soft / outlined 膠囊

## 3. P2：頁面骨架

- [x] Tile / TileGroup（1 / 8 + 3 / 1）— `MochiTile` / `MochiTileGroup`：forui 的 FTile 只是 FItem 加觸控 padding，這裡合併成一個
- [x] Header（5）+ HeaderAction — `MochiHeader` / `MochiHeaderAction`（含 `.back()` / `.close()`）；不分 nested，返回鍵放 prefixes 就好
- [x] Scaffold（3）— `MochiScaffold`：header / content / footer
- [x] ScrollArea — `MochiScrollArea`：可捲動的那一端會淡出

## 4. P3：浮層

- [ ] Popover（底層，下面兩個都靠它）
- [ ] PopoverMenu（1）— session 選單
- [ ] ContextMenu（2）— 紀錄、session 長按 / 右鍵
- [ ] Dialog（4）+ `showMochiDialog`（5）
- [ ] Dialog.adaptive（1）— 桌面 dialog、手機 sheet
- [ ] Sheet（1）+ `showMochiSheet` — 首頁側邊選單
- [ ] ⭐ Toast / Toaster — cube timer 已包了 `FToaster`，之後刪除紀錄的「復原」會用到

## 5. P4：輸入

- [ ] TextField（4）— 基於 `EditableText`：hint、control、inputFormatters、keyboardType、maxLength
- [ ] TextField.multiline（1）— scramble 輸入
- [ ] ⭐ Checkbox
- [ ] ⭐ RadioGroup
- [ ] ⭐ Select — 設定頁「Alert type」目前是 disabled tile，看起來需要下拉選單
- [ ] ⭐ Slider — 檢查時間、音量類設定
- [ ] ⭐ SegmentedControl / Tabs — 統計頁切換（ao5 / ao12 / 圖表）

## 6. P5：導覽

- [x] Page transition：`MochiSurfaceTransition`（scaleFade / fade / slide）+ `MochiPageRoute` / `MochiPage`；時長與曲線收在 `MochiMotion`，浮層之後共用同一組
- [ ] Sidebar / SidebarGroup / SidebarItem（1 / 2 / 2）
- [ ] BottomNavigationBar（1）
- [ ] Breadcrumb（1）
