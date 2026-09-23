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
- [x] ⭐ 換主色的 helper — `MochiTone.from(base, background:, softAlpha:)` 把一個顏色補成四個（`onBase` 在兩個墨色裡挑對比高的，都不到 4.5:1 就退回純白 / 純黑；`onSoft` 沿著自己的亮度調到對頁面背景 4.5:1，色相不動；`soft` 是既有的疊色公式），`MochiColors.branded({brightness, primary, info?, ...})` 換 accent 但保留中性色，另外補上 `MochiColors.copyWith`。對比計算在 `theme/contrast.dart`（不匯出）。**不接 Material 的 `ColorScheme`**、**不從單一 seed 推語意色**（綠色必須是綠的）。測試對 8 個品牌色 × 明暗兩套斷言每個 tone 的對比都達標；gallery 的 look bar 有換主色的按鈕
- [x] ⭐ 評估各元件是否需要獨立的 style 類別 — **結論：不要整組加 style，但有 size 軸的元件要有 metrics。** P3 做完後回頭看，實際會想覆寫的是「尺寸」而不是「顏色」：顏色都能從 intent × appearance 推出來，真的要換主色是換 `MochiColors`，要換單一 app 的規則是 `MochiThemeExtension`，兩條路都已經有了。所以規則訂為：
  - **有 size 選項的元件 → 一份 `XxxMetrics`**（像 `MochiButtonMetrics`）：值要有 value equality 才能餵給 `MochiValueTransition`。Badge、Progress 接下來就是照這個做
  - **顏色 → 不開 style 類別**，除非某個元件的配色規則複雜到不是 `(colors, states) → color` 能講完（目前只有 button 是）
- [x] ⭐ 評估導入 Widgetbook — **結論：不導入。** 它有非 Material 的 `Widgetbook(...)` 和 `ThemeAddon<T>`（`themeBuilder` 可以包 `MochiApp`），所以技術上接得起來，但外殼是 Material 寫的，一定要獨立 package + build_runner，51 個元件要寫 use case，而且會和現有 gallery 變成兩份要同步的東西。它真正多給的只有「單一元件 knobs」和「裝置框」，這兩件事改成直接做進 gallery：頁面頂端的 knob bar（size / intent / enabled，頁面自己宣告用哪些，樣本從 `_Knobs` 讀）和 viewport 切換（mobile / tablet / full，同時設 `ResponsiveScope`，所以 popover↔sheet 這種斷點規則不用縮視窗就能驗）。真的要重看的時機：這個 kit 要發佈給別人用，或是有第二個人 review UI

## 0.5 預覽 gallery

- [x] gallery 改成 sidebar + scaffold 的外框，分成 7 頁（foundations / buttons / inputs / navigation / content / dates / overlays），不用一路往下滑
- [x] 頂端 top bar：頁名、viewport（mobile 420 / tablet 900 / full，同時套 `ResponsiveScope`）、touch、中文、主題模式，第二排是 look bar（圓角 / 密度 / 字級 / 主色），第三排是該頁的 knobs
- [x] knobs 走 `_Knobs` InheritedWidget，每頁第一段「knobs」把 size / intent / enabled 直接畫出來；其餘樣本維持自己刻意的變化組合
- [x] `lib/main.dart` 只留外框和頁面清單，樣本拆進 `lib/gallery/*.dart`（用 `part`，所以私有類別名稱不用改）
- [x] `test/gallery_smoke_test.dart`：每頁都開得起來（順便抓 overflow）、knob bar 真的會傳到樣本、mobile viewport 會讓 picker 變 sheet

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
- [x] ⭐ Select — `MochiSelect` / `MochiMultiSelect` + `MochiSelectOption`：外觀跟同尺寸的 TextField 一樣（label / description / error、跟按鈕等高），清單是 `MochiPopoverMenu`、至少跟欄位一樣寬、已選項打勾。多選時清單不會關、已選項目用 badge 顯示（按 × 直接移除，不會打開清單）、badge 多了欄位會長高。鍵盤 Enter / Space / 方向鍵開啟並停在已選的那一行（滑鼠點開則不搶 focus）。寬度沒限制時以最長選項為準，換選項不會跳。`MochiPopover` 新增 `matchAnchorWidth`、`MochiMenuItem` 新增 `autofocus`
- [x] ⭐ Autocomplete — `MochiAutocomplete`：包 widgets 層的 `RawAutocomplete`，欄位是 `MochiTextField`、清單是 `MochiMenu` 放在 `MochiPopoverSurface` 上、寬度跟輸入框一樣。`optionsBuilder` 可回傳 Future（非同步建議），↑↓ 移動且會自動捲到看得見、Enter 選取、Esc 收起、失焦收起；打什麼都算數，`onChanged` 每次打字都回報、`onSelected` 只在選到選項時。沒有 `maxLength`（計數會卡在輸入框和清單中間），要限制長度用 `inputFormatters`
- [x] ⭐ OTP field — `MochiOtpField`：底下只有一個看不見的 `EditableText`，畫出來的是一排格子，所以貼上整組碼會自動分配、backspace 往回刪、平台的 one-time-code 自動填入也能用。正在填的那格有游標會閃、`obscure` 顯示圓點、`digitsOnly` 可關、填滿時 `onCompleted`；格子跟同尺寸按鈕等高且是正方形
- [x] ⭐ SearchBar — `MochiSearchBar`：`MochiTextField` 加放大鏡、× 和 debounce（預設 300ms，`Duration.zero` 就是每次打字都搜）。`onChanged` 每次打字、`onSearch` 是真的要搜的那次（停下來、送出、清空都會立刻搜），同一個字串不會搜兩次；`loading` 時 × 換成轉圈。hint 走 `MochiStrings.search`（新增），圖示走 `MochiIcons.search`（新增）。要搜尋建議就用 `MochiAutocomplete` 加放大鏡 prefix，不另外做
- [x] ⭐ Slider — `MochiSlider`：拖曳、點軌道直接跳過去、方向鍵 / Home / End（右左跟著畫面走，RTL 會鏡像）、`divisions` 吸附、`step` 可調。`valueLabel` 把目前的值放在 label 那行的尾端，intent / size 可選，thumb 按住會變大（跟按鈕一樣是長大不是縮小）；一次只佔一個 Tab 位置，語意是 slider 並附上加減後的值
- [x] ⭐ SegmentedControl / Tabs — `MochiSegmentedControl` + `MochiSegment`：**tabs 不是新元件，是 `appearance`**（`segmented` 是控制項、`underline` 是頁籤）。每格平分寬度（`expanded: false` 就以最寬的那格為準），指示器會滑過去、整組只佔一個 Tab 位置、方向鍵換選項且會跳過 disabled 的那格。下面要換什麼內容由 app 自己 `switch`，這個元件只負責選
- [x] ⭐ Stepper 可直接輸入數字 — `MochiStepper(editable:)`（預設開）：點中間的數字就變成輸入框（只收數字、觸控跳數字鍵盤、一打開就全選），Enter 或離開那格才生效，超出範圍拉回 min / max，清空或打錯就還原；`format` 只在顯示時套用（編輯時是 `15` 不是 `15s`）；編輯時 ↑↓ 照樣加減、Esc 取消

## 7. P5：導覽

- [x] Page transition：`MochiSurfaceTransition`（scaleFade / fade / slide）+ `MochiPageRoute` / `MochiPage`；時長與曲線收在 `MochiMotion`，浮層之後共用同一組
- [x] Sidebar / SidebarGroup / SidebarItem — `MochiSidebar` / `MochiSidebarGroup` / `MochiSidebarItem`（+ `MochiSidebarHeading`）：兩種展開都有。group 收合共用 `MochiCollapsible`；整條收成 rail 時寬度走 `MochiValueTransition`（56 / 觸控 64），label 用 `Align(widthFactor)` 夾掉並淡出所以圖示不會位移，文字改用 tooltip（`Text` label 會自動拿字串），group 的標題在 rail 狀態直接不顯示
- [x] BottomNavigationBar — `MochiBottomNav` / `MochiBottomNavItem`：平分寬度、選中的那格圖示後面有 soft 藥丸、可放 badge、`selectedIcon` 可換實心版、`showLabels: false` 就只有選中的那格有字；自己吃掉系統底部安全區，放進 scaffold 不用再包 SafeArea
- [x] Breadcrumb — `MochiBreadcrumb` / `MochiBreadcrumbItem`：最後一階是「你在這」所以是純文字不是連結（語意上標成 header），分隔符跟著文字方向翻面，`maxItems` 超過就把中間折進 … 的選單裡（pagination 的 … 可以按，會跳出小 popover 輸入頁數，`jumpable` 可關；超出範圍會夾到最近的一端，空白或亂打就什麼都不做）
- [x] ⭐ Pagination — `MochiPagination`：頁碼從 1 起算，目前這頁是 solid、其他是 ghost，`around` 決定左右各寫幾頁，中間折成 …（只差一頁時直接寫出來）。每頁的寬度都一樣：格數固定（靠邊時窗格會變長補回折掉的那格），每格寬度以最大頁碼為準，箭頭到頭到尾會 disable。… 可以按，會跳出小 popover 輸入頁數（`jumpable` 預設開）：… 代表的就是被折起來的那些頁，問路問在那裡最合理，而且不佔額外寬度。超出範圍夾到最近的一端，空白或亂打就什麼都不做。窄到放不下時先縮 `around`，連最少的五格都放不下才橫向捲動
- [x] ⭐ Menubar — `MochiMenubar` / `MochiMenubarMenu`：一個 menu 一個 `MochiPopoverMenu`，加上「已經開著的時候 hover 到隔壁就直接換過去」（沒有延遲、不用再按）、方向鍵沿著列走且跳過 disabled 的、開著的那個字會保持 selected
- [x] ⭐ Tree — `MochiTree` / `MochiTreeNode`：縮排、展開收合、縮排線（只畫在下面還有東西的那層）、鍵盤（↑↓ 走看得見的列、→ 先展開再進去、← 先收起再回父層、Home / End）。展開狀態預設自己管（`initiallyExpanded`），給 `expanded` 就換 app 管；選取一律是 app 的

## 8. P6：內容與日期

- [x] ⭐ Accordion — `MochiAccordion` / `MochiAccordionItem`：每一列就是一個 `MochiCollapsible`，accordion 只負責決定誰開著。`multiple` 關掉是單開（開一個就關掉上一個）、打開是各自獨立；沒給 `expanded` 就自己管狀態，給了就交給 app
- [x] ⭐ Avatar — `MochiAvatar`：圖片 → 縮寫 → 圖示，自己往下退（載不到圖就用縮寫、沒縮寫就用 `MochiIcons.user`，新增這個 token）。圓形 / 圓角方形、四種尺寸、intent 決定底色。另有 `MochiAvatarGroup`：互相疊一角、超過 `max` 的變成 +n，疊法共用 badge group 那個負邊距的 render box（`Padding` 不收負值）
- [x] ⭐ Calendar — `MochiCalendar.single` / `.multiple` / `.range`（+ `MochiDateRange`）：三種選法各一個 constructor，值的型別不同所以不混成一個參數。月份預設自己管（箭頭會動），給 `month` 就交給 app；`first` / `last` / `enabledDay` 管哪些日子能選，今天有外框；區間只有兩端是圓角、中間接成一條，兩端填實心其餘填淡色；區間也可以用拖的（從手指按下的那天算起）；永遠畫六週所以每個月高度一樣；多選有「清除」按鈕。鍵盤整個格子都能走（←→ 一天、↑↓ 一週、PageUp/Down 換月、Home/End 到該週兩端、Enter 選取），走出月底會自動翻頁。月份和星期名稱走 `MochiStrings`（新增 `months` / `weekdays` / `monthYear` / 兩個箭頭的說明，中文是「2026 年 7 月」）
- [x] ⭐ DatePicker — `MochiDatePicker.single` / `.range`：長得跟同尺寸的 TextField 一樣（label / description / error 共用 `MochiFieldFrame`），桌面在欄位下面開 popover、手機從下面開 sheet（跟 `showMochiModal` 同一條 breakpoint 規則）。單日選完就關、區間選完第二端才關。區間文字只寫一次共通的部分（`MochiStrings.dateRange` + `monthsShort`，今年就不寫年份），真的太長就換第二行而不是打點點。日期文字走 `MochiStrings.date`（英文「12 July 2026」、中文「2026 年 7 月 12 日」），也可以用 `format` 自己接管；新增 `MochiIcons.calendar` 和 `MochiStrings.pickDate`
- [x] ⭐ TimePicker — `MochiTimeWheel`（滾輪本體：時 / 分 / 可選秒，整數對齊、會繞回去，選取的那排在後面用一條底色帶標示）+ `MochiTimePicker`（欄位，桌面 popover、手機 sheet，跟 DatePicker 同一套）。`MochiTime` 是值型別（時分秒 + `hourOf12` / `isAfternoon` / `onDay`）；`minuteStep` 可設 5 / 15、`use24HourFormat: false` 會多一欄上午 / 下午（新增 `MochiStrings.am` / `pm` / `pickTime` 和 `MochiIcons.clock`）
- [x] ⭐ DateTimePicker — `MochiDateTimePicker`：Calendar 和 TimeWheel 上下疊在同一個面板裡（桌面 popover、手機 sheet，跟上面兩個同一套）。一天不是答案、一個時間也不是，所以不會自己關，下面有一顆 `strings.ok` 的按鈕收工；選日子留著原本的時間、轉輪子留著原本的日子，兩邊都還沒選過就分別落在今天和早上九點。手機的 sheet 預設只開到半個螢幕，這裡放寬到九成並且包一層捲動，短螢幕就用捲的而不是溢位。欄位文字預設是「3 July 2026 14:45」（`showSeconds` 會多秒數、`use24HourFormat: false` 會寫上午 / 下午），也可以用 `format` 自己接管（手機 sheet 一律是「填草稿 → 按確定」：sheet 是 route，route 的 page 只建一次，picker 的 setState 進不去，所以草稿存在 sheet 自己身上；date / time picker 的 sheet 也一樣，共用 `showPickerSheet`）
- [x] ⭐ Skeleton — `MochiSkeleton`（方塊）/ `.circle(size:)` / `.text(lines:)`：預設 shimmer，也可以選 pulse 或 none，`MediaQuery.disableAnimations` 會自動變成 none。同一頁上的 skeleton 都同相位（週期從 scheduler 的 frame timestamp 取，不是從自己被 build 的時間），一排列的時候才不會像雜訊。沒給寬度就填滿（跟 divider 一樣需要有界的寬度），`.text` 的最後一行是短的。週期沿用 `motion.indeterminateDuration`
- [x] ⭐ Sortable — `MochiSortable`（包 widgets 層的 `ReorderableList`）+ `MochiSortableHandle`：桌面用 grip 拖、觸控長按整列拖（`wholeItemDrags` 可以自己指定，預設看 `theme.touch`）。`onReorder(from, to)` 的 to 已經是把那列抽掉之後的索引（用新的 `onReorderItem`，省掉大家手寫的 off-by-one）。被拿起來的那列會長大一點並帶 lg 陰影（陰影是超橢圓的，`liftRadius` 可調，不然圓角的列下面會出現一塊直角灰塊）；`spacing` 的間距算在列身上，放手才會落在眼睛預期的位置。新增 `MochiIcons.grip` 和 `MochiStrings.reorder`
- [x] ⭐ RefreshIndicator — `MochiRefresh`：包住一個 scrollable，聽 `OverscrollNotification`（clamping）和捲過頭的 `ScrollUpdateNotification`（bouncing），拉的距離打五折才是指示器下來的距離。指示器就是現成的 `MochiCircularProgress`：拉的時候是 determinate（還差多少才會觸發），放手觸發之後變 indeterminate 並把清單頂住，直到 `onRefresh` 的 future 結束；丟例外也會還原，例外走 `FlutterError.reportError` 而不是吞掉或留一個沒人接的 future。滑鼠也拉得動（`mouseDrags`，預設開：桌面平台的 scrollable 預設不吃滑鼠拖曳，滾輪到頂也不會報 overscroll，不開就等於桌面完全沒有這個手勢）。**沒有併進 toast**，理由寫在元件註解裡
- [x] ⭐ Resizable — `MochiResizable` + `MochiResizablePane`：尺寸存的是比例，所以視窗變大變小時分割不會全部倒向某一邊；拖曳線只在相鄰兩個 pane 之間搬空間，兩邊的 `minSize` / `maxSize` 誰先到底誰決定停在哪。每條線自己是一個 tab stop，方向鍵一次走 `keyboardStep`（只能用拖的等於不能用鍵盤設定）。可以巢狀，橫的裡面包直的。handle 桌面 8px / 觸控 16px，hover 和拖曳時線會變成 primary

## 9. 決定不做的（免得再繞回來）

- **Chart** — 圖表是一整個領域（scale、tick、legend、hit test、動畫、a11y），做一半比沒有更糟。也不建議 `fl_chart`：它 import `package:flutter/material.dart`，會把這個專案唯一的硬規則破掉。cube timer 統計頁真正要的是「一條 solve time 折線 + ao5 / ao12 疊上去」，那是一個 `CustomPainter`，約 150 行、顏色直接讀 `context.colors`，**寫在 app 裡**。等出現第二種圖表再回來談
- **Steps（精靈步驟）/ Timeline** — 是內容排版，不是互動原語。要用的時候在 app 裡用 Divider + Tile 拼出來就好
- **`Dialog.adaptive`** — 見 P3 的 `showMochiModal`
- **Radio card 當成獨立元件** — 見 P4 的 RadioGroup
- **各元件的 style 類別** — 見 P0 的結論（有 size 軸的給 metrics，顏色不開 style）
- **Animated icon — 暫緩，不是「換一組圖示」那麼簡單。** `MochiIcons` 存的是 `IconData`、元件寫的是 `Icon(theme.icons.close)`，而會動的圖示是一個帶 controller 的 widget，型別就對不上。更關鍵的是狀態：它需要知道「從哪個狀態到哪個狀態」（chevron 展開轉 90°、menu→close 變形），那是元件要把進度交給圖示，不是換 icon set 能解決的。真的要做的時候，第一步是把元件裡的 `Icon(theme.icons.x)` 換成 `theme.buildIcon(context, ...)` 這層間接（目前只有 6 個呼叫點，隨時可以補）
