# VoidCriptUI

Кастомная UI-библиотека для Roblox (Luau), объединяющая **функциональность Weave** (флаги, конфиги, key system, сабтабы, простой API) и **дизайн CompKiller** (тёмная тема, боковой icon rail, акцентная линия, groupbox-секции, квадратные чекбоксы, двухколоночная раскладка).

**Версия:** 1.1.0

---

## Содержание

- [Установка](#установка)
- [Быстрый старт](#быстрый-старт)
- [Темизация](#темизация)
- [Окно (Window)](#окно-window)
- [Key System](#key-system)
- [Вкладки (Tabs) и сабтабы](#вкладки-tabs-и-сабтабы)
- [Секции (Sections)](#секции-sections)
- [Элементы](#элементы)
  - [Toggle](#toggle)
  - [Slider](#slider)
  - [Dropdown](#dropdown)
  - [Input](#input)
  - [Keybind](#keybind)
  - [ColorPicker](#colorpicker)
  - [Button](#button)
  - [Paragraph](#paragraph)
  - [Label](#label)
  - [Divider](#divider)
- [Флаги (Flags)](#флаги-flags)
- [Подписки OnChanged](#подписки-onchanged)
- [Тултипы](#тултипы)
- [Нотификации](#нотификации)
- [Система конфигов](#система-конфигов)
- [Утилиты](#утилиты)
- [FAQ](#faq)
- [Roadmap — 45 идей развития](#roadmap--45-идей-развития)

---

## Установка

```lua
local VoidCript = loadstring(game:HttpGet("https://raw.githubusercontent.com/WorkAccount211/VoidCriptUI_lib/refs/heads/main/VoidCriptUI.lua"))()
```

Или локально в Studio:

```lua
local VoidCript = require(path.to.VoidCriptUI)
```

---

## Быстрый старт

```lua
local Window = VoidCript:CreateWindow({
    Name = "voidcript",
    LoadingSubtitle = "v1.1.0",
    ToggleKey = Enum.KeyCode.RightShift,
    ConfigurationSaving = { Enabled = true, FolderName = "VoidCript", FileName = "Config" },
})

local Tab = Window:CreateTab("Main", "star")
local Section = Tab:CreateSection({ Name = "General", Side = "left" })

Section:CreateToggle({
    Name = "Enable",
    CurrentValue = false,
    Flag = "MainEnable",
    Callback = function(state) print(state) end,
})
```

---

## Темизация

Вызывается **до** `CreateWindow`. Принимает `Color3` **или hex-строки**:

```lua
VoidCript:SetTheme({
    Accent     = "#C73E6E",
    Background = Color3.fromRGB(12, 12, 14),
})
```

| Токен | Назначение | Дефолт |
|---|---|---|
| `Accent` | Акцентный цвет (линии, заливки, активные элементы) | `RGB(199, 62, 110)` |
| `AccentDark` | Тёмный акцент (нажатие кнопок) | `RGB(140, 40, 78)` |
| `Background` | Фон окна | `RGB(12, 12, 14)` |
| `Sidebar` | Фон бокового rail | `RGB(9, 9, 11)` |
| `Header` | Фон шапки и нотификаций | `RGB(15, 15, 17)` |
| `Section` | Фон groupbox-секций | `RGB(16, 16, 18)` |
| `Element` | Фон элементов (кнопки, поля) | `RGB(24, 24, 27)` |
| `ElementHover` | Фон элементов при наведении | `RGB(32, 32, 36)` |
| `Outline` | Основная обводка | `RGB(38, 38, 42)` |
| `OutlineSoft` | Мягкая обводка | `RGB(28, 28, 32)` |
| `Text` | Основной текст | `RGB(230, 230, 235)` |
| `TextDim` | Приглушённый текст | `RGB(130, 130, 140)` |
| `TextDark` | Неактивный текст | `RGB(90, 90, 100)` |

---

## Окно (Window)

```lua
local Window = VoidCript:CreateWindow({
    Name = "voidcript",                 -- заголовок
    LoadingSubtitle = "v1.1.0",         -- подпись акцентным цветом рядом с заголовком
    ToggleKey = Enum.KeyCode.RightShift,-- клавиша скрытия/показа
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "VoidCript",
        FileName = "Config",
    },
    KeySystem = false,
    KeySettings = { ... },              -- см. Key System
})
```

Если key system включён и пользователь его не прошёл, `CreateWindow` вернёт `nil` — всегда проверяйте:

```lua
if not Window then return end
```

### Методы окна

| Метод | Описание |
|---|---|
| `Window:Show()` | Показать окно |
| `Window:Hide()` | Скрыть окно |
| `Window:Toggle()` | Переключить видимость |
| `Window:SetTitle(text)` | Сменить заголовок |
| `Window:SetSubtitle(text)` | Сменить подпись |
| `Window:SetToggleKey(keyCode)` | Сменить клавишу меню в рантайме |
| `Window:SelectTab(name)` | Программно открыть вкладку по имени |
| `Window:SaveConfiguration()` | Принудительно сохранить конфиг |
| `Window:LoadConfiguration()` | Принудительно загрузить конфиг |
| `Window:Destroy()` | Удалить только окно |

---

## Key System

```lua
KeySystem = true,
KeySettings = {
    Title = "VoidCript | Key System",
    Subtitle = "discord.gg/example",
    Note = "Ключ можно получить в Discord",
    Key = { "Key1", "Key2" },  -- строка или таблица валидных ключей
    SaveKey = true,            -- запомнить ключ (файл <FileName>.key)
    FileName = "VoidCriptKey",
}
```

Окно ключа перетаскиваемое; при неверном ключе поле мигает красным. При `SaveKey = true` повторный ввод не требуется.

---

## Вкладки (Tabs) и сабтабы

```lua
local Tab = Window:CreateTab("Combat", "crosshair", { "Aim", "Triggerbot" })
```

- **name** — подпись под иконкой в rail
- **icon** — имя встроенного глифа, произвольный символ (до 3 знаков) или `rbxassetid` числом
- **subtabs** — опциональная таблица имён сабтабов (горизонтальные кнопки сверху страницы)

Встроенные глифы: `skull`, `crosshair`, `eye`, `settings`, `brush`, `code`, `file`, `zap`, `world`, `user`, `shield`, `star`.

---

## Секции (Sections)

Groupbox в стиле CompKiller — заголовок «сидит» на рамке. Двухколоночная раскладка.

```lua
local Section = Tab:CreateSection({
    Name = "Aim Assist",
    Side = "left",      -- "left" | "right"
    Subtab = "Aim",     -- имя или индекс сабтаба (опционально)
    Height = 200,       -- фиксированная высота со скроллом (опционально)
})
-- краткая форма: Tab:CreateSection("Name")
```

---

## Элементы

Все элементы поддерживают `Flag` (регистрация во флагах) и большинство — `Tooltip` (всплывающая подсказка).

### Toggle

```lua
Section:CreateToggle({
    Name = "Enable",
    CurrentValue = false,
    Flag = "MyToggle",
    Tooltip = "Подсказка при наведении",
    Callback = function(state) end,
})
```

Методы: `:Set(bool)`, `:Get()`.

### Slider

```lua
Section:CreateSlider({
    Name = "FOV",
    Range = { 10, 500 },
    Increment = 5,        -- поддерживает дробные шаги (0.05)
    Suffix = " px",
    CurrentValue = 120,
    Flag = "MySlider",
    Tooltip = "...",
    Callback = function(value) end,
})
```

Методы: `:Set(number)`, `:Get()`.

### Dropdown

```lua
local dd = Section:CreateDropdown({
    Name = "Target",
    Options = { "Head", "Torso" },
    CurrentOption = "Head",
    Flag = "MyDropdown",
    Callback = function(option, index) end,
})
dd:Refresh({ "Head", "Torso", "Random" }) -- динамическое обновление списка
```

Методы: `:Set(option)`, `:Get()`, `:Refresh(options)`.

### Input

```lua
Section:CreateInput({
    Name = "Delay",
    PlaceholderText = "например 50",
    CurrentValue = "",
    RemoveTextAfterFocusLost = false,
    Flag = "MyInput",
    Callback = function(text) end,
})
-- алиас: Section:CreateTextbox(...)
```

Методы: `:Set(text)`, `:Get()`.

### Keybind

```lua
Section:CreateKeybind({
    Name = "Aim Key",
    CurrentKeybind = Enum.KeyCode.E,
    HoldToInteract = true, -- Callback(true) при нажатии, Callback(false) при отпускании
    Flag = "MyBind",
    Callback = function(pressed) end,
})
-- алиас: Section:CreateBind(...)
```

Клик по кнопке — режим прослушивания следующей клавиши. Методы: `:Set(keyCode)`, `:Get()`.

### ColorPicker

```lua
Section:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Alpha = 0.8,  -- укажите — появится alpha-бар; не укажете — только цвет
    Flag = "MyColor",
    Callback = function(color, alpha) end,
})
```

Раскрывающийся пикер: SV-квадрат + hue-бар (+ alpha-бар). Методы: `:Set(color3 | {Color=..., Alpha=...})`, `:Get()` → `color, alpha`.

### Button

```lua
Section:CreateButton({
    Name = "Reset",
    Tooltip = "...",
    Confirm = true,               -- второй клик для подтверждения
    ConfirmText = "Точно?",       -- текст подтверждения (2.5 сек)
    Callback = function() end,
})
```

Методы: `:Fire()` — программный вызов.

### Paragraph

```lua
local p = Section:CreateParagraph({ Title = "Инфо", Content = "Текст с переносами..." })
p:Set("Новый заголовок", "Новый текст")
```

### Label

```lua
local l = Section:CreateLabel({ Name = "Status: idle", Icon = "star" })
l:Set("Status: running")
```

### Divider

```lua
Section:CreateDivider()
```

---

## Флаги (Flags)

Любой элемент с параметром `Flag` доступен глобально:

```lua
-- Weave-стиль:
VoidCript.Flags["AimFOV"]:Get()
VoidCript.Flags["AimFOV"]:Set(200)

-- шорткаты VoidCript:
VoidCript:GetFlag("AimFOV")
VoidCript:SetFlag("AimFOV", 200)
```

`Set` вызывает колбэк элемента и обновляет UI.

---

## Подписки OnChanged

Реагируйте на изменение флага из любого места скрипта — без доступа к объекту элемента:

```lua
VoidCript:OnChanged("AimFOV", function(value)
    print("Новый FOV:", value)
end)
```

Срабатывает при любом изменении пользователем (клик, драг слайдера, выбор в дропдауне, ввод текста, смена бинда, выбор цвета). Подписок на один флаг может быть сколько угодно.

---

## Тултипы

Добавьте `Tooltip = "текст"` в конфиг Toggle, Slider или Button — при наведении появится подсказка, следующая за курсором.

---

## Нотификации

```lua
VoidCript:Notify({
    Title = "Готово",
    Content = "Описание",
    Type = "success",   -- success | error | warning | info (цвет боковой линии)
    Duration = 5,
    Actions = {         -- опциональные кнопки
        { Name = "OK", Callback = function() end },
    },
})
```

---

## Система конфигов

При `ConfigurationSaving.Enabled = true`:

- **Автосохранение**: через 2 секунды после последнего изменения любого флага (debounce)
- **Автозагрузка**: через ~0.5 сек после построения окна
- **Формат**: JSON в `<FolderName>/<FileName>.json`
- Сериализуются все типы, включая `Color3 + Alpha` и `Enum.KeyCode`

Требует executor с поддержкой `writefile` / `readfile` / `isfile` / `makefolder`.

---

## Утилиты

| Функция | Описание |
|---|---|
| `VoidCript.FromHex("#C73E6E")` | hex → Color3 |
| `VoidCript:SetTheme(table)` | Переопределить тему (до CreateWindow) |
| `VoidCript:GetFlag(flag)` / `:SetFlag(flag, v)` | Шорткаты флагов |
| `VoidCript:OnChanged(flag, fn)` | Подписка на изменения |
| `VoidCript:Notify(cfg)` | Нотификация |
| `VoidCript:Unload()` | Полное удаление всех GUI библиотеки и сброс состояния |
| `VoidCript.Version` | Строка версии |

---

## FAQ

**Меню не появляется.** Проверьте, что key system пройден (`CreateWindow` вернул не `nil`) и нажмите `ToggleKey` (по умолчанию RightShift).

**Конфиг не сохраняется.** Ваш executor должен поддерживать `writefile`. В Studio файловые функции недоступны.

**Как сделать смену клавиши меню через UI?** Создайте Keybind с флагом и подпишитесь: `VoidCript:OnChanged("MenuKey", function(k) Window:SetToggleKey(k) end)`.

**Можно ли несколько окон?** Да, каждый `CreateWindow` независим, но флаги (`VoidCript.Flags`) общие.

---

## Roadmap — 45 идей развития

### UX и элементы
1. **Multi-select Dropdown** — выбор нескольких опций с чипами.
2. **Searchable Dropdown** — поле поиска внутри длинных списков.
3. **Range Slider** — слайдер с двумя ползунками (min/max).
4. **Ввод значения слайдера с клавиатуры** — клик по числу превращает его в поле ввода.
5. **Keybind с модификаторами** — Ctrl+X, Shift+E, поддержка кнопок мыши.
6. **Toggle + Keybind в одной строке** — бинд, переключающий тоггл (классика CompKiller).
7. **Toggle + ColorPicker в одной строке** — компактный паттерн для ESP-настроек.
8. **Пресеты цветов в пикере** — палитра последних/сохранённых цветов, ввод hex.
9. **Rainbow-режим ColorPicker** — автоцикл hue с настраиваемой скоростью.
10. **Progress Bar элемент** — индикатор для длительных операций.
11. **Image элемент** — вывод rbxasset-изображений в секции.
12. **Table/List элемент** — прокручиваемый список с выбором строки (плеерлист).

### Навигация и окно
13. **Поиск по всем настройкам** — глобальное поле, фильтрующее элементы по имени.
14. **Ресайз окна** — драг за угол с минимальными размерами.
15. **Сворачивание в мини-бар** — компактный режим "только заголовок".
16. **Запоминание позиции/размера окна** в конфиге.
17. **Мобильная адаптация** — крупные хитбоксы, кнопка-тоггл на экране.
18. **Кастомный курсор внутри меню** и блокировка ввода в игру при открытом UI.
19. **Свободный порядок вкладок** — drag-and-drop в rail.
20. **Пины (избранное)** — закрепление часто используемых элементов на отдельной вкладке.

### Конфиги
21. **Менеджер конфигов в UI** — список, создание, переименование, удаление, дефолтный конфиг.
22. **Автоконфиг на игру** — отдельный файл на game.PlaceId.
23. **Экспорт/импорт конфига строкой** (base64) — обмен настройками без файлов.
24. **Версионирование конфигов** — миграции при изменении структуры флагов.
25. **Облачные конфиги** — загрузка пресетов с GitHub/сервера скрипта.

### Темизация
26. **Полноценный рантайм SetTheme** — реестр покрашенных инстансов и мгновенная перекраска без пересоздания UI.
27. **Встроенные пресеты тем** — Midnight, Blood, Ocean, Mono и т.д.
28. **Редактор темы в UI** — вкладка с колорпикерами на каждый токен + сохранение в конфиг.
29. **Кастомные шрифты** — параметр Font в SetTheme.
30. **Настраиваемый масштаб UI** — множитель размеров для 1080p/1440p/мобильных.

### API и DX
31. **Идемпотентный Unload + защита от двойной загрузки** — `getgenv().VoidCript` с автоматическим выгрузом старой копии.
32. **`element:Destroy()` и `Section:Clear()`** — удаление элементов в рантайме.
33. **`element:SetVisible(bool)` / условная видимость** — показывать элемент только при включённом другом флаге (DependsOn).
34. **Валидация Input** — параметры Numeric, MaxLength, Pattern с подсветкой ошибки.
35. **Типизация через luau-lsp** — аннотации `--!strict` и экспорт типов для автодополнения.
36. **Централизованный менеджер соединений** — все `Connect` в один Maid/Janitor, чистое отключение при Unload (сейчас часть глобальных подписок остаётся).
37. **Троттлинг колбэков слайдера** — режим "callback только при отпускании" для тяжёлых операций.
38. **Защита от ошибок в колбэках** — pcall-обёртка с выводом ошибки в нотификацию, чтобы UI не «умирал».
39. **Событие Window.OnClose / OnToggle** — хуки видимости меню для рендер-логики (FOV-круг и т.п.).
40. **Документация JSDoc-стиля в коде** + автогенерация API-референса.

### Инфраструктура
41. **Watermark-модуль** — плавающая плашка с ником/FPS/пингом в стиле CompKiller.
42. **Кейлист (активные бинды)** — плавающий список включённых функций.
43. **Юнит-тесты на чистой Lua** — тестирование сериализации, флагов, OnChanged без Roblox.
44. **CI на GitHub Actions** — luau-analyze + selene-линт на каждый коммит.
45. **Минифицированная сборка + загрузчик версий** — `loadstring(...)("v1.1.0")` с закреплением версии и CDN-зеркалом.

---

## Лицензия

MIT. Используйте свободно, указание авторства приветствуется.
