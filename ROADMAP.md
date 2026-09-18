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
- [x] 按壓動畫：iOS 風格按下放大（`MochiPressScale`，彈簧回彈、上限 12% / 每邊 8px，兩個都是上限、取較小者、尊重系統的「減少動態效果」設定 `MediaQuery.disableAnimations`）
- [x] 圓角改用 superellipse（`RoundedSuperellipseBorder`）
- [x] Flutter 改跟 master：stable 3.47 的 Linux Impeller 沒開 MSAA，描邊和路徑都有鋸齒（flutter#191171，修正只在 master）
- [x] 圖示庫決定：Tabler（有 filled variant）。目前元件庫沒有任何內建圖示，換組是零成本
- [x] `MochiIcons` token：元件自己會畫的 8 個圖示，`copyWith(icons:)` 可整組替換
- [x] ⭐ 尺寸過渡動畫 — `MochiValueTransition<T>`：只在數值本身改變時才重跑（隱式 `Animated*` 會被主題動畫每幀重啟）。Button / Tile / Switch 已接上，時間為 `motion.sizeDuration`
- [ ] ⭐ 以 `ColorScheme` 產生主題的 helper（像 forui CLI preset），方便 app 換主色
- [x] ⭐ 評估各元件是否需要獨立的 style 類別 — **結論：不要整組加 style，但有 size 軸的元件要有 metrics。** P3 做完後回頭看，實際會想覆寫的是「尺寸」而不是「顏色」：顏色都能從 intent × appearance 推出來，真的要換主色是換 `MochiColors`，要換單一 app 的規則是 `MochiThemeExtension`，兩條路都已經有了。所以規則訂為：
  - **有 size 選項的元件 → 一份 `XxxMetrics`**（像 `MochiButtonMetrics`）：值要有 value equality 才能餵給 `MochiValueTransition`。Badge、Progress 接下來就是照這個做
  - **顏色 → 不開 style 類別**，除非某個元件的配色規則複雜到不是 `(colors, states) → color` 能講完（目前只有 button 是）
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
- [x] Switch（2）— `MochiSwitch`：intent、focus ring、尊重系統的「減少動態效果」設定
- [x] Card（2）— `MochiCard`：elevation、可選 onPress（hover 上色、不放大）
- [x] LinearProgress — `MochiLinearProgress`：determinate / indeterminate
- [x] Badge / Tag — `MochiBadge`：solid / soft / outlined 膠囊

## 3. P2：頁面骨架

- [x] Tile / TileGroup（1 / 8 + 3 / 1）— `MochiTile` / `MochiTileGroup`：forui 的 FTile 只是 FItem 加觸控 padding，這裡合併成一個
- [x] Header（5）+ HeaderAction — `MochiHeader` / `MochiHeaderAction`（含 `.back()` / `.close()`）；不分 nested，返回鍵放 prefixes 就好
- [x] Scaffold（3）— `MochiScaffold`：header / content / footer
- [x] ScrollArea — `MochiScrollArea`：可捲動的那一端會淡出；滑鼠滾輪捲到底不會帶動外層（`containScroll`，內容沒超出時不攔）

## 4. P3：浮層

- [x] Popover（底層，下面幾個都靠它）— `MochiPopover`：基於 widgets 層的 `RawMenuAnchor`（overlay、點外面關閉、Esc、focus 還原都是現成的），這裡補上定位（side × align、沒空間就翻面、夾在畫面內）與面板外觀
- [x] PopoverMenu（1）— `MochiPopoverMenu` + `MochiMenu` / `MochiMenuItem` / `MochiMenuDivider` / `MochiMenuLabel`，項目按下會關掉整個選單（含子選單）
- [x] ContextMenu（2）— `MochiContextMenu`：右鍵 / 長按在游標位置開啟；子項目有自己的長按時讓給子項目
- [x] ⭐ Submenu — `MochiSubmenu`：hover 停留 120ms 或方向鍵開啟（cube timer 的 Penalty / Move to 會用到）
- [x] Dialog（4）+ `showMochiDialog`（5）— `MochiDialog` + `MochiDialogRoute`；按鈕桌面橫排、touch 直排全寬（cube timer 原本自己包一層就是為了這個）
- [x] Sheet（1）+ `showMochiSheet` — `MochiSheet`：四個邊都能貼，往自己那邊拖曳可以關掉（直接倒轉 route 的 animation，barrier 跟著淡出）
- [x] `showMochiModal`（1）— 桌面用 dialog、手機用 sheet（以 breakpoint 判斷，`form:` 可指定）。**不做 `Dialog.adaptive`**：dialog 和 sheet 是兩種外觀，會變的是呈現方式而不是元件，叫 dialog 等於說「這個 dialog 有時候不是 dialog」。`showMochiModal` 收的是內容描述（title / content / actions）而不是一棵 widget，因為 dialog 的按鈕橫排、sheet 的直排全寬，沒辦法共用同一棵樹
- [x] ⭐ Toast / Toaster — `MochiToaster`（`MochiApp` 自動裝在 navigator 之上）+ `showMochiToast`：intent 上在邊框並自帶圖示、hover 會暫停倒數、超過上限的排隊、handle 可提前關掉
- [x] ⭐ 現成的問句 — `showMochiConfirm` / `showMochiAlert` / `showMochiChoice`，都走 `showMochiModal`，所以名字裡沒有 dialog；`MochiModalAction` 是按下就把 modal pop 掉的按鈕
- [x] ⭐ `showMochiPrompt`（輸入一段文字，例如改名 session）：一打開就 focus、文字全選；`validate` 在按確定時才跑，不通過就留著並顯示錯誤，再打字就清掉錯誤；`maxLength` 顯示計數

## 5. P3.5：回頭對齊 Bulma / forui

依這個順序做：

- [x] ⭐ `MochiStrings` — 元件自己會說的字（`MochiApp(strings:)`，內建 `en` / `zhHant`）。**排第一，因為之後每個會說話的元件都會用到，越晚做要回頭改的地方越多。** 現在已經漏了 9 個寫死的英文預設值：`showMochiConfirm` 的 `"OK"` / `"Cancel"`、`MochiHeaderAction` 的 `"Back"` / `"Close"`、三個 route 的 `barrierLabel = "Dismiss"`。規則照 `MochiIcons` 抄：**元件只會說 `MochiStrings` 裡的話，app 傳進來的字是 app 自己的事**。
  - **不做 `LocalizationsDelegate`**：delegate + 每個 locale 一個 class + `Localizations.of` 那套機器是給對外發行的套件用的，這裡一個 `MochiApp(strings:)` 就結束了，順便跟其他 token 一樣有 value equality 和 `copyWith`
  - 例外：Calendar 的月份名 / 星期名 / 日期格式不進 `MochiStrings`，那時候直接用 `intl` 的 `DateFormat(locale)`。等 P6 再說
- [x] ⭐ `MochiCloseButton`（Bulma 的 `delete`）— × 按鈕（`shape: .rounded` 預設、跟 icon button 同樣的圓角，toast 用它；`.circle` 給 badge 用），顏色取自所在位置的 `IconTheme`（放在 danger badge 裡就是 danger 色），平常淡、hover 才填底；`size` xs–lg 走 `MochiCloseButtonMetrics`（xs 給 badge 用）。toast 已改用它，之後 dialog / sheet 的關閉也用同一顆
- [x] Badge 加 `size`（走 `MochiBadgeMetrics`）：桌面高 16 / 20 / 24 / 28，touch 各加 4，預設 `sm`（等於原本的大小）。順便把 `MochiButtonSize` 改名成共用的 `MochiSize`，button、close button、badge、progress 都用同一個
- [x] Badge 的圓角改成可選（`shape: .pill / .rounded`）：現在一律 pill，加一個比較方的（接近 card 的感覺），Bulma 的 tag 本身就是圓角矩形而不是膠囊
- [x] Badge 的 `onDelete`（Bulma `is-delete`）：右側一個小叉，用上面的 `MochiCloseButton`，跟 badge 的端點同心；螢幕閱讀器念 `MochiStrings.remove`（新增的字）
- [x] Tag addons（Bulma `has-addons`）— `MochiBadgeGroup`：Row 排列，中間的圓角打平、共用邊界，每個 badge 各自的 intent。做法照 `MochiTileGroup` 的 `_TileGroupScope`：group 用 InheritedWidget 告訴每個 badge 自己是第一個 / 中間 / 最後一個，badge 自己決定哪幾個角要打平
- [x] Progress 加 `size`（Bulma 的 `is-small/normal/medium/large`）：linear 的高度、circular 的直徑與線寬，走 `MochiProgressMetrics`
- [x] Card 加 collapsible — `MochiCard.collapsible(title:)`，底層是 `MochiCollapsible`（header + 可收合的 body，高度過渡走 `motion.sizeDuration` / `sizeCurve`，chevron 跟著轉）。可受控（`expanded:`）或不受控（`initiallyExpanded:`），`maintainState` 保留收起時的狀態，收起的內容 Tab 不到。之後 Accordion 和 Sidebar 也用它
- [x] ⭐ 三個全域外觀旋鈕（參考 shadcn_flutter，但**都做成純量 / 預設組，不做成第二張 metrics 表**），都開在 `MochiApp(radius:, density:, textScale:)`，gallery 標題下有一排可以切：
  - **圓角預設**：`MochiRadius.sharp` / `.subtle` / `.standard` / `.rounded` / `.pill`（`MochiRadius.scaled(factor)` 可自訂），`full` 不跟著縮（pill 就是 pill）
  - **`density`**（`MochiTheme.density`）：乘在 `MochiSpace`、page padding 和各 metrics 的高度 / padding 上，字、圖示、圓角、線不動；progress 和 switch 也不動（那是控制項本身的大小，不是鬆緊）。**不要加 density enum** — `touch` 已經是一個密度軸了（它管的是最小點擊區 48px），再加一個 enum 會讓每個 `XxxMetrics.of` 變成 touch × density 的矩陣；一個乘數就夠，而且乘數天生可以餵給 `MochiValueTransition`
  - **`textScale`**：最後沒有用 `MochiTypography.scale`，而是在 `MochiApp` 裡把 `MediaQuery.textScaler` 乘上去：跟系統設定相乘（系統 1.5 × app 1.2 = 1.8），而且 app 自己的文字也一起變，不只 mochi 的字型

## 6. P4：輸入

- [x] TextField（4）— `MochiTextField`：基於 `EditableText` + `TextSelectionGestureDetectorBuilder`。label / hint / description / error、prefix / suffix、`clearable`、`maxLength`（含計數）、`size` 跟同尺寸按鈕等高。右鍵選單用 `MochiMenu`，文字走 `MochiStrings`（剪下 / 複製 / 貼上 / 全選）；web 上瀏覽器會用自己的右鍵選單
- [x] TextField.multiline（1）— `MochiTextField.multiline`：從 `minLines`（預設 3）開始隨內容長高。shadcn_flutter 的 text area 就是這個，不另外開元件
- [x] ⭐ Checkbox — `MochiCheckbox`：`tristate`（部分選取顯示橫線，新增 `MochiIcons.minus`）、`label` / `description`（點文字也會切換）、intent、桌面 16 / 觸控 20
- [x] ⭐ RadioGroup — `MochiRadioGroup` / `MochiRadio`，包 widgets 層的 `RadioGroup` + `RawRadio`（方向鍵換選項、整組只佔一個 Tab 位置、互斥群組語意都是現成的）。`appearance: .card` 就是 shadcn 的 radio card，橫排時平分寬度。含 shadcn 的 radio card：**不是新元件，是 `appearance`**（項目長得像一行 tile 還是一張 card）。照既有規則，外觀是軸不是元件；checkbox 之後要 card 版也走同一條路
- [x] ⭐ Stepper — `MochiStepper`：整數、min / max / step、`format`（如 `15s`）、按住連發且越來越快、鍵盤方向鍵 / Home / End、整個只佔一個 Tab 位置、跟同尺寸按鈕等高、寬度以最寬的值為準不會跳。新增 `MochiIcons.plus`
- [ ] ⭐ Select — 設定頁「Alert type」目前是 disabled tile，看起來需要下拉選單。要含 **multi select**（多選時用 badge 顯示已選項目）
- [ ] ⭐ Autocomplete — 建議加，但排在 TextField + Select 之後：它等於兩者相加，而且 widgets 層已經有 `RawAutocomplete` 可以包，成本低
- [ ] ⭐ OTP field — 一格一個字元，貼上會自動分配，自動跳下一格
- [ ] ⭐ SearchBar — TextField 加上搜尋圖示、清除鈕、debounce；接上 Autocomplete 就是搜尋建議
- [ ] ⭐ Slider — 檢查時間、音量類設定
- [ ] ⭐ SegmentedControl / Tabs — 統計頁切換（ao5 / ao12 / 圖表）
- [ ] ⭐ Stepper 可直接輸入數字 — 點中間的數字就能打字（只收數字、觸控跳數字鍵盤），按 Enter 或離開那格才生效，超出範圍拉回 min / max，清空或打錯就還原；`format` 只在顯示時套用（編輯時是 `15` 不是 `15s`）；編輯時 ↑↓ 照樣加減、Esc 取消；預設開啟，`editable: false` 可關。ao 個數這種範圍大的值，打字比按住連發快

## 7. P5：導覽

- [x] Page transition：`MochiSurfaceTransition`（scaleFade / fade / slide）+ `MochiPageRoute` / `MochiPage`；時長與曲線收在 `MochiMotion`，浮層之後共用同一組
- [ ] Sidebar / SidebarGroup / SidebarItem（1 / 2 / 2）— 含 **expandable**，但注意是兩種不同的「展開」，兩個都要：group 的收合（共用 P3.5 的 `MochiCollapsible`），以及整條 sidebar 收成只剩圖示的 rail（寬度過渡走 `MochiValueTransition`，收起時項目文字換成 tooltip）
- [ ] BottomNavigationBar（1）
- [ ] Breadcrumb（1）
- [ ] ⭐ Pagination — Bulma 有，長列表用得到
- [ ] ⭐ Menubar — 桌面的橫排選單列。成本很低：`MochiPopover` + `MochiMenu` + `MochiSubmenu` 都有了，只差「已經開著的時候 hover 到隔壁會直接換過去」這個行為
- [ ] ⭐ Tree — 縮排、展開收合、縮排線、鍵盤（方向鍵進出層級）。widgets 層沒有現成的，整棵要自己寫，比 menubar 貴不少

## 8. P6：內容與日期

- [ ] ⭐ Accordion — 一組 `MochiCollapsible`，可設定單開 / 多開。跟 P3.5 的 card collapsible 共用同一個底層
- [ ] ⭐ Avatar — 圖片 / 縮寫文字 / fallback 圖示，圓形與方形，size
- [ ] ⭐ Calendar — 月曆本體（選單日 / 多日 / 區間），下面三個 picker 都靠它
- [ ] ⭐ DatePicker — Calendar 裝進 popover / sheet
- [ ] ⭐ TimePicker — 時 / 分（/ 秒）滾輪或輸入
- [ ] ⭐ DateTimePicker — 上面兩個合起來
- [ ] ⭐ Skeleton — 載入中的佔位方塊（`MochiSkeleton` + `.text(lines:)`），脈動或 shimmer。很便宜，但要有非同步內容才划算，cube timer 是本地資料，所以不急
- [ ] ⭐ Sortable — 拖曳排序。widgets 層有 `ReorderableList` / `SliverReorderableList` 可以包，成本不高
- [ ] ⭐ RefreshIndicator — 下拉重新整理。**不併進 toast**：toast 是時間驅動、浮在 navigator 之上、跟捲動無關；refresh 是手勢驅動、綁在某一個 scrollable 上、進度由手指決定，塞進 toaster 只會讓它多一個不相干的狀態機。做法是包一個 scrollable，用 `OverscrollNotification` 驅動現成的 `MochiCircularProgress`（determinate → indeterminate）
- [ ] ⭐ Resizable — 可拖曳分隔線的分割面板。**優先度最低**，cube timer 沒有這種版面

## 9. 決定不做的（免得再繞回來）

- **Chart** — 圖表是一整個領域（scale、tick、legend、hit test、動畫、a11y），做一半比沒有更糟。也不建議 `fl_chart`：它 import `package:flutter/material.dart`，會把這個專案唯一的硬規則破掉。cube timer 統計頁真正要的是「一條 solve time 折線 + ao5 / ao12 疊上去」，那是一個 `CustomPainter`，約 150 行、顏色直接讀 `context.colors`，**寫在 app 裡**。等出現第二種圖表再回來談
- **Steps（精靈步驟）/ Timeline** — 是內容排版，不是互動原語。要用的時候在 app 裡用 Divider + Tile 拼出來就好
- **`Dialog.adaptive`** — 見 P3 的 `showMochiModal`
- **Radio card 當成獨立元件** — 見 P4 的 RadioGroup
- **各元件的 style 類別** — 見 P0 的結論（有 size 軸的給 metrics，顏色不開 style）
- **Animated icon — 暫緩，不是「換一組圖示」那麼簡單。** `MochiIcons` 存的是 `IconData`、元件寫的是 `Icon(theme.icons.close)`，而會動的圖示是一個帶 controller 的 widget，型別就對不上。更關鍵的是狀態：它需要知道「從哪個狀態到哪個狀態」（chevron 展開轉 90°、menu→close 變形），那是元件要把進度交給圖示，不是換 icon set 能解決的。真的要做的時候，第一步是把元件裡的 `Icon(theme.icons.x)` 換成 `theme.buildIcon(context, ...)` 這層間接（目前只有 6 個呼叫點，隨時可以補）
