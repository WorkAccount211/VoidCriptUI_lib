--[[
	VoidCriptUI — Full Example
	Демонстрирует ВСЕ возможности библиотеки:
	темизация, key system, конфиги, флаги, подписки, тултипы,
	все элементы, нотификации, программное управление.

	Замените URL ниже на raw-ссылку вашего GitHub репозитория.
]]

local VoidCript = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/VoidCriptUI.lua"))()
-- или локально: local VoidCript = require(path.to.VoidCriptUI)

-- ══════════════════════════════════════════════════════════════
-- 1. ТЕМИЗАЦИЯ (вызывается ДО CreateWindow)
--    Принимает Color3 или hex-строки
-- ══════════════════════════════════════════════════════════════
VoidCript:SetTheme({
	Accent     = "#C73E6E",              -- hex-строка
	AccentDark = Color3.fromRGB(140, 40, 78), -- или Color3
	-- Background, Sidebar, Header, Section, Element, ElementHover,
	-- Outline, OutlineSoft, Text, TextDim, TextDark — всё переопределяемо
})

-- ══════════════════════════════════════════════════════════════
-- 2. ОКНО: Key System + автосохранение конфига + ToggleKey
-- ══════════════════════════════════════════════════════════════
local Window = VoidCript:CreateWindow({
	Name = "voidcript",
	LoadingSubtitle = "v1.1.0 | example build",
	ToggleKey = Enum.KeyCode.RightShift, -- клавиша скрытия/показа меню

	ConfigurationSaving = {
		Enabled = true,
		FolderName = "VoidCript",
		FileName = "ExampleConfig", -- сохранится в VoidCript/ExampleConfig.json
	},

	KeySystem = false, -- поставьте true чтобы включить
	KeySettings = {
		Title = "VoidCript | Key System",
		Subtitle = "discord.gg/example",
		Note = "Ключ можно получить в нашем Discord",
		Key = { "FreeKey123", "VIPKey456" }, -- несколько валидных ключей
		SaveKey = true,                      -- запомнить ключ в файл
		FileName = "VoidCriptKey",
	},
})

if not Window then return end -- пользователь не прошёл key system

-- ══════════════════════════════════════════════════════════════
-- 3. ВКЛАДКИ: иконка-глиф или rbxassetid, сабтабы
--    Встроенные глифы: skull, crosshair, eye, settings, brush,
--    code, file, zap, world, user, shield, star
-- ══════════════════════════════════════════════════════════════
local CombatTab   = Window:CreateTab("Combat", "crosshair", { "Aim", "Triggerbot" })
local VisualsTab  = Window:CreateTab("Visuals", "eye", { "ESP", "World" })
local MiscTab     = Window:CreateTab("Misc", "zap")
local SettingsTab = Window:CreateTab("Settings", "settings")

-- ══════════════════════════════════════════════════════════════
-- 4. СЕКЦИИ: колонка left/right, привязка к сабтабу, фикс. высота
-- ══════════════════════════════════════════════════════════════
local AimSection = CombatTab:CreateSection({
	Name = "Aim Assist",
	Side = "left",
	Subtab = "Aim", -- по имени или по индексу (Subtab = 1)
})

local AimVisSection = CombatTab:CreateSection({
	Name = "Aim Visuals",
	Side = "right",
	Subtab = "Aim",
})

local TriggerSection = CombatTab:CreateSection({
	Name = "Triggerbot",
	Side = "left",
	Subtab = "Triggerbot",
})

-- ══════════════════════════════════════════════════════════════
-- 5. TOGGLE — с флагом, тултипом и колбэком
-- ══════════════════════════════════════════════════════════════
local AimToggle = AimSection:CreateToggle({
	Name = "Enable Aim Assist",
	CurrentValue = false,
	Flag = "AimEnabled",                       -- доступ через VoidCript.Flags
	Tooltip = "Включает наведение на цель",    -- всплывающая подсказка
	Callback = function(state)
		print("Aim Assist:", state)
	end,
})

-- ══════════════════════════════════════════════════════════════
-- 6. SLIDER — диапазон, шаг, суффикс, тултип
-- ══════════════════════════════════════════════════════════════
local FovSlider = AimSection:CreateSlider({
	Name = "FOV Radius",
	Range = { 10, 500 },
	Increment = 5,
	Suffix = " px",
	CurrentValue = 120,
	Flag = "AimFOV",
	Tooltip = "Радиус зоны наведения",
	Callback = function(value)
		print("FOV:", value)
	end,
})

AimSection:CreateSlider({
	Name = "Smoothness",
	Range = { 0, 1 },
	Increment = 0.05, -- поддержка дробного шага
	CurrentValue = 0.35,
	Flag = "AimSmooth",
	Callback = function(v) end,
})

-- ══════════════════════════════════════════════════════════════
-- 7. DROPDOWN — с Refresh для динамических списков
-- ══════════════════════════════════════════════════════════════
local TargetDropdown = AimSection:CreateDropdown({
	Name = "Target Part",
	Options = { "Head", "Torso", "Closest" },
	CurrentOption = "Head",
	Flag = "AimPart",
	Callback = function(option, index)
		print("Target:", option, "index:", index)
	end,
})

-- динамическое обновление списка (например, список игроков):
-- TargetDropdown:Refresh({ "Head", "Torso", "Closest", "Random" })

-- ══════════════════════════════════════════════════════════════
-- 8. KEYBIND — обычный и удерживаемый (HoldToInteract)
-- ══════════════════════════════════════════════════════════════
AimSection:CreateKeybind({
	Name = "Aim Key (hold)",
	CurrentKeybind = Enum.KeyCode.E,
	HoldToInteract = true, -- Callback(true) при нажатии, Callback(false) при отпускании
	Flag = "AimKey",
	Callback = function(pressed)
		print("Aim key held:", pressed)
	end,
})

-- ══════════════════════════════════════════════════════════════
-- 9. COLOR PICKER — SV-квадрат + hue, опционально alpha
-- ══════════════════════════════════════════════════════════════
AimVisSection:CreateColorPicker({
	Name = "FOV Circle Color",
	Color = Color3.fromRGB(199, 62, 110),
	Alpha = 0.8, -- укажите Alpha чтобы появился alpha-бар
	Flag = "FovColor",
	Callback = function(color, alpha)
		print("Color:", color, "Alpha:", alpha)
	end,
})

AimVisSection:CreateToggle({
	Name = "Show FOV Circle",
	CurrentValue = true,
	Flag = "ShowFov",
	Callback = function(v) end,
})

-- ══════════════════════════════════════════════════════════════
-- 10. INPUT — текстовое поле
-- ══════════════════════════════════════════════════════════════
TriggerSection:CreateInput({
	Name = "Delay (ms)",
	PlaceholderText = "например 50",
	CurrentValue = "50",
	RemoveTextAfterFocusLost = false,
	Flag = "TriggerDelay",
	Callback = function(text)
		print("Delay:", text)
	end,
})

-- ══════════════════════════════════════════════════════════════
-- 11. VISUALS: ESP секции
-- ══════════════════════════════════════════════════════════════
local EspSection = VisualsTab:CreateSection({ Name = "Player ESP", Side = "left", Subtab = "ESP" })

EspSection:CreateToggle({ Name = "Boxes", CurrentValue = false, Flag = "EspBoxes", Callback = function(v) end })
EspSection:CreateToggle({ Name = "Names", CurrentValue = false, Flag = "EspNames", Callback = function(v) end })
EspSection:CreateToggle({ Name = "Health Bars", CurrentValue = false, Flag = "EspHealth", Callback = function(v) end })
EspSection:CreateColorPicker({ Name = "Box Color", Color = Color3.fromRGB(255, 255, 255), Flag = "EspColor", Callback = function(c) end })

local WorldSection = VisualsTab:CreateSection({ Name = "World", Side = "left", Subtab = "World" })
WorldSection:CreateSlider({ Name = "Time of Day", Range = { 0, 24 }, Increment = 1, CurrentValue = 14, Flag = "WorldTime", Callback = function(v) end })
WorldSection:CreateToggle({ Name = "Fullbright", CurrentValue = false, Flag = "Fullbright", Callback = function(v) end })

-- ══════════════════════════════════════════════════════════════
-- 12. MISC: Button (обычный + с подтверждением), Paragraph, Label, Divider
-- ══════════════════════════════════════════════════════════════
local MiscSection = MiscTab:CreateSection({ Name = "Actions", Side = "left" })

MiscSection:CreateButton({
	Name = "Print Hello",
	Tooltip = "Простая кнопка",
	Callback = function()
		print("Hello from VoidCript!")
	end,
})

MiscSection:CreateButton({
	Name = "Reset Character",
	Confirm = true,                  -- требует второй клик для подтверждения
	ConfirmText = "Точно сбросить?", -- текст подтверждения
	Callback = function()
		local char = game.Players.LocalPlayer.Character
		if char then char:BreakJoints() end
	end,
})

MiscSection:CreateDivider()

local StatusLabel = MiscSection:CreateLabel({ Name = "Status: idle", Icon = "star" })

local InfoParagraph = MiscSection:CreateParagraph({
	Title = "О скрипте",
	Content = "Это демонстрация всех элементов VoidCriptUI. Параграф поддерживает перенос строк и обновление через :Set().",
})

-- обновление в рантайме:
task.delay(5, function()
	StatusLabel:Set("Status: running")
	InfoParagraph:Set("О скрипте", "Текст обновлён через 5 секунд после запуска.")
end)

-- ══════════════════════════════════════════════════════════════
-- 13. SETTINGS: управление меню и конфигом
-- ══════════════════════════════════════════════════════════════
local MenuSection = SettingsTab:CreateSection({ Name = "Menu", Side = "left" })

MenuSection:CreateKeybind({
	Name = "Menu Toggle Key",
	CurrentKeybind = Enum.KeyCode.RightShift,
	Flag = "MenuKey",
	Callback = function() end,
})

-- смена клавиши меню в рантайме через подписку на флаг:
VoidCript:OnChanged("MenuKey", function(newKey)
	if newKey then Window:SetToggleKey(newKey) end
end)

MenuSection:CreateButton({
	Name = "Save Config",
	Callback = function()
		Window:SaveConfiguration()
		VoidCript:Notify({ Title = "Config", Content = "Конфиг сохранён", Type = "success", Duration = 3 })
	end,
})

MenuSection:CreateButton({
	Name = "Load Config",
	Callback = function()
		Window:LoadConfiguration()
		VoidCript:Notify({ Title = "Config", Content = "Конфиг загружен", Type = "info", Duration = 3 })
	end,
})

MenuSection:CreateButton({
	Name = "Unload UI",
	Confirm = true,
	Callback = function()
		VoidCript:Unload() -- полностью удаляет все GUI библиотеки
	end,
})

local ConfigSection = SettingsTab:CreateSection({ Name = "Window API", Side = "right" })

ConfigSection:CreateButton({ Name = "Hide Window", Callback = function() Window:Hide() end })
ConfigSection:CreateButton({ Name = "Go to Combat Tab", Callback = function() Window:SelectTab("Combat") end })
ConfigSection:CreateButton({
	Name = "Rename Window",
	Callback = function()
		Window:SetTitle("voidcript")
		Window:SetSubtitle("renamed at runtime")
	end,
})

-- ══════════════════════════════════════════════════════════════
-- 14. ФЛАГИ: чтение и запись из любого места скрипта
-- ══════════════════════════════════════════════════════════════
-- Классический способ (Weave-стиль):
print("FOV из флага:", VoidCript.Flags["AimFOV"]:Get())
-- VoidCript.Flags["AimEnabled"]:Set(true)

-- Новые шорткаты:
print("FOV шорткатом:", VoidCript:GetFlag("AimFOV"))
-- VoidCript:SetFlag("AimFOV", 200)

-- Подписка на изменения любого флага (из любого места):
VoidCript:OnChanged("AimFOV", function(value)
	print("FOV изменился на:", value)
end)

-- ══════════════════════════════════════════════════════════════
-- 15. НОТИФИКАЦИИ: 4 типа + кнопки-действия
-- ══════════════════════════════════════════════════════════════
VoidCript:Notify({
	Title = "VoidCript загружен",
	Content = "Нажмите RightShift чтобы скрыть меню",
	Type = "success", -- success | error | warning | info
	Duration = 6,
})

VoidCript:Notify({
	Title = "Обновление доступно",
	Content = "Вышла версия 1.2.0",
	Type = "warning",
	Duration = 10,
	Actions = {
		{ Name = "Скачать", Callback = function() print("Открываю ссылку...") end },
		{ Name = "Позже", Callback = function() end },
	},
})
