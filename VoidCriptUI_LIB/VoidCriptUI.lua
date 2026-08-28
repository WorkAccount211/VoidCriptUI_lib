--[[
	VoidCriptUI Library v2.0
	API: Weave-style (Flags, ConfigurationSaving, KeySystem, Subtabs, Notify)
	Design: CompKiller-style (dark CS2 menu, left icon rail, accent line, square checkboxes)

	v2.0 adds: boot loading screen with animated "V" logo, warn/error-only
	console logging, global settings search, window resize/minimize,
	runtime re-themeable UI with presets + in-UI editor, watermark and
	keylist modules (with custom user modules), range sliders, keyboard-
	editable slider values, keybinds with modifiers/mouse buttons,
	combined toggle+keybind / toggle+colorpicker rows, rainbow color mode,
	progress bar / image / table elements, config manager, DependsOn
	conditional visibility, input validation, throttled sliders,
	pcall-guarded callbacks, a centralized connection Maid, custom
	in-menu cursor with optional game-input lock, mobile touch support,
	and an idempotent getgenv() re-load guard.
]]

local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local HttpService        = game:GetService("HttpService")
local RunService         = game:GetService("RunService")
local Players            = game:GetService("Players")
local GuiService         = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")

local LocalPlayer = Players.LocalPlayer

-- Idempotent re-load guard: if a previous copy of VoidCript is already
-- running (e.g. the script was executed twice), unload it cleanly first
-- so GUIs, connections and hooked game input don't stack up.
if type(getgenv) == "function" then
	local existing = getgenv().VoidCript
	if existing and type(existing.Unload) == "function" then
		pcall(function() existing:Unload() end)
	end
end

local Library = {
	Flags   = {},
	Version = "2.0.0",
	_saveDebounce = nil,
	_listeners = {},
	_guis = {},
	_windows = {},
}
Library.__index = Library

-- ══════════════════════════════ THEME (CompKiller) ══════════════════════════════
local Theme = {
	Accent      = Color3.fromRGB(199, 62, 110),  -- crimson-pink
	AccentDark  = Color3.fromRGB(140, 40, 78),
	Background  = Color3.fromRGB(12, 12, 14),
	Sidebar     = Color3.fromRGB(9, 9, 11),
	Header      = Color3.fromRGB(15, 15, 17),
	Section     = Color3.fromRGB(16, 16, 18),
	Element     = Color3.fromRGB(24, 24, 27),
	ElementHover= Color3.fromRGB(32, 32, 36),
	Outline     = Color3.fromRGB(38, 38, 42),
	OutlineSoft = Color3.fromRGB(28, 28, 32),
	Text        = Color3.fromRGB(230, 230, 235),
	TextDim     = Color3.fromRGB(130, 130, 140),
	TextDark    = Color3.fromRGB(90, 90, 100),

	-- typography (roadmap #29 — override via SetTheme to swap fonts)
	Font        = Enum.Font.Gotham,
	FontMedium  = Enum.Font.GothamMedium,
	FontBold    = Enum.Font.GothamBold,
}

-- Built-in theme presets (roadmap #27). Apply with Library:SetThemePreset(name).
local ThemePresets = {
	Midnight = {
		Accent = Color3.fromRGB(199, 62, 110), AccentDark = Color3.fromRGB(140, 40, 78),
		Background = Color3.fromRGB(12, 12, 14), Sidebar = Color3.fromRGB(9, 9, 11),
		Header = Color3.fromRGB(15, 15, 17), Section = Color3.fromRGB(16, 16, 18),
		Element = Color3.fromRGB(24, 24, 27), ElementHover = Color3.fromRGB(32, 32, 36),
		Outline = Color3.fromRGB(38, 38, 42), OutlineSoft = Color3.fromRGB(28, 28, 32),
		Text = Color3.fromRGB(230, 230, 235), TextDim = Color3.fromRGB(130, 130, 140), TextDark = Color3.fromRGB(90, 90, 100),
	},
	Blood = {
		Accent = Color3.fromRGB(214, 48, 49), AccentDark = Color3.fromRGB(140, 28, 30),
		Background = Color3.fromRGB(14, 10, 10), Sidebar = Color3.fromRGB(10, 7, 7),
		Header = Color3.fromRGB(17, 12, 12), Section = Color3.fromRGB(18, 13, 13),
		Element = Color3.fromRGB(27, 19, 19), ElementHover = Color3.fromRGB(36, 25, 25),
		Outline = Color3.fromRGB(45, 30, 30), OutlineSoft = Color3.fromRGB(32, 22, 22),
		Text = Color3.fromRGB(235, 228, 228), TextDim = Color3.fromRGB(150, 130, 130), TextDark = Color3.fromRGB(100, 85, 85),
	},
	Ocean = {
		Accent = Color3.fromRGB(56, 152, 219), AccentDark = Color3.fromRGB(34, 101, 148),
		Background = Color3.fromRGB(10, 13, 16), Sidebar = Color3.fromRGB(8, 10, 13),
		Header = Color3.fromRGB(12, 16, 20), Section = Color3.fromRGB(14, 18, 22),
		Element = Color3.fromRGB(21, 27, 33), ElementHover = Color3.fromRGB(28, 36, 44),
		Outline = Color3.fromRGB(36, 46, 55), OutlineSoft = Color3.fromRGB(26, 34, 41),
		Text = Color3.fromRGB(228, 235, 240), TextDim = Color3.fromRGB(125, 140, 150), TextDark = Color3.fromRGB(85, 98, 108),
	},
	Mono = {
		Accent = Color3.fromRGB(220, 220, 225), AccentDark = Color3.fromRGB(160, 160, 165),
		Background = Color3.fromRGB(13, 13, 13), Sidebar = Color3.fromRGB(10, 10, 10),
		Header = Color3.fromRGB(16, 16, 16), Section = Color3.fromRGB(17, 17, 17),
		Element = Color3.fromRGB(25, 25, 25), ElementHover = Color3.fromRGB(33, 33, 33),
		Outline = Color3.fromRGB(40, 40, 40), OutlineSoft = Color3.fromRGB(29, 29, 29),
		Text = Color3.fromRGB(230, 230, 230), TextDim = Color3.fromRGB(135, 135, 135), TextDark = Color3.fromRGB(92, 92, 92),
	},
}

-- glyph icons (CompKiller-style minimal rail)
local Icons = {
	skull     = "☠",
	crosshair = "✛",
	eye       = "👁",
	settings  = "⚙",
	brush     = "✎",
	code      = "‹›",
	file      = "🗀",
	zap       = "⚡",
	world     = "◉",
	user      = "☺",
	shield    = "⛨",
	star      = "★",
	search    = "🔍",
	list      = "☰",
	image     = "🖼",
	table     = "▤",
}

-- ══════════════════════════════ PUBLIC UTILITIES ══════════════════════════════
function Library.FromHex(hex)
	hex = hex:gsub("#", "")
	return Color3.fromRGB(
		tonumber(hex:sub(1, 2), 16),
		tonumber(hex:sub(3, 4), 16),
		tonumber(hex:sub(5, 6), 16)
	)
end

-- Merge custom colors into the theme. Call BEFORE CreateWindow.
-- Accepts Color3 values or hex strings ("#C73E6E").
function Library:SetTheme(overrides)
	for key, value in pairs(overrides or {}) do
		if Theme[key] ~= nil then
			if type(value) == "string" then
				Theme[key] = Library.FromHex(value)
			else
				Theme[key] = value
			end
		end
	end
end

function Library:GetFlag(flag)
	local obj = Library.Flags[flag]
	return obj and obj:Get()
end

function Library:SetFlag(flag, value)
	local obj = Library.Flags[flag]
	if obj then obj:Set(value) end
end

-- Subscribe to changes of any flag from anywhere in your script.
function Library:OnChanged(flag, callback)
	Library._listeners[flag] = Library._listeners[flag] or {}
	table.insert(Library._listeners[flag], callback)
end

function Library:_fireChanged(flag, value)
	if flag and Library._listeners[flag] then
		for _, fn in ipairs(Library._listeners[flag]) do
			task.spawn(fn, value)
		end
	end
end

-- Fully remove every GUI the library has created and reset state.
function Library:Unload()
	for _, gui in ipairs(Library._guis) do
		pcall(function() gui:Destroy() end)
	end
	Library._guis = {}
	Library.Flags = {}
	Library._listeners = {}
end

-- ══════════════════════════════ HELPERS ══════════════════════════════
local function Create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, c in ipairs(children or {}) do
		c.Parent = inst
	end
	return inst
end

local function Tween(inst, props, dur)
	TweenService:Create(inst, TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function Stroke(parent, color, thickness)
	return Create("UIStroke", {
		Color = color or Theme.Outline,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function Corner(parent, radius)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or 3), Parent = parent })
end

local function GetGuiParent()
	local ok, hui = pcall(function() return gethui and gethui() end)
	if ok and hui then return hui end
	local ok2, core = pcall(function() return game:GetService("CoreGui") end)
	if ok2 and core then return core end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function MakeDraggable(dragHandle, target)
	local dragging, dragStart, startPos
	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
		end
	end)
	dragHandle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- ══════════════════════════════ TOOLTIP ══════════════════════════════
local TooltipGui, TooltipLabel

local function EnsureTooltip()
	if TooltipGui then return end
	TooltipGui = Create("ScreenGui", {
		Name = "VoidCriptTooltip",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		Parent = GetGuiParent(),
	})
	table.insert(Library._guis, TooltipGui)
	TooltipLabel = Create("TextLabel", {
		BackgroundColor3 = Theme.Header,
		Font = Enum.Font.Gotham,
		Text = "",
		TextColor3 = Theme.Text,
		TextSize = 12,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(0, 0, 0, 0),
		Visible = false,
		ZIndex = 1000,
		Parent = TooltipGui,
	}, {
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5),
		}),
	})
	Corner(TooltipLabel, 3)
	Stroke(TooltipLabel, Theme.Outline)
end

-- Attach a hover tooltip to any element (pass Tooltip = "text" in element config)
local function AttachTooltip(inst, text)
	if not text then return end
	EnsureTooltip()
	inst.MouseEnter:Connect(function()
		TooltipLabel.Text = text
		TooltipLabel.Visible = true
	end)
	inst.MouseLeave:Connect(function()
		TooltipLabel.Visible = false
	end)
	inst.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and TooltipLabel.Visible then
			TooltipLabel.Position = UDim2.new(0, input.Position.X + 16, 0, input.Position.Y + 12)
		end
	end)
end

-- ══════════════════════════════ CONFIG SERIALIZATION ══════════════════════════════
local function SerializeValue(kind, value)
	if kind == "ColorPicker" then
		return { __t = "color", r = value.Color.R, g = value.Color.G, b = value.Color.B, a = value.Alpha }
	elseif kind == "Keybind" then
		return { __t = "key", name = value and value.Name or "Unknown" }
	else
		return value
	end
end

local function DeserializeValue(raw)
	if type(raw) == "table" and raw.__t == "color" then
		return { Color = Color3.new(raw.r, raw.g, raw.b), Alpha = raw.a }
	elseif type(raw) == "table" and raw.__t == "key" then
		return raw.name ~= "Unknown" and Enum.KeyCode[raw.name] or nil
	end
	return raw
end

-- ══════════════════════════════ NOTIFICATIONS ══════════════════════════════
local NotifyGui, NotifyList

local function EnsureNotifyGui()
	if NotifyGui then return end
	NotifyGui = Create("ScreenGui", {
		Name = "VoidCriptNotify",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		Parent = GetGuiParent(),
	})
	table.insert(Library._guis, NotifyGui)
	NotifyList = Create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.new(0, 280, 1, -32),
		Parent = NotifyGui,
	}, {
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
		}),
	})
end

function Library:Notify(cfg)
	EnsureNotifyGui()
	cfg = cfg or {}
	local duration = cfg.Duration or 5

	local card = Create("Frame", {
		BackgroundColor3 = Theme.Header,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		Parent = NotifyList,
	})
	Corner(card, 4)
	Stroke(card, Theme.Outline)

	local typeColors = {
		success = Color3.fromRGB(80, 200, 120),
		error   = Color3.fromRGB(220, 70, 70),
		warning = Color3.fromRGB(230, 175, 60),
		info    = Theme.Accent,
	}
	-- accent line (CompKiller signature), colored by cfg.Type
	Create("Frame", {
		BackgroundColor3 = typeColors[string.lower(cfg.Type or "info")] or Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 2, 1, 0),
		Parent = card,
	})

	local content = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -20, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = card,
	}, {
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
	})

	Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = cfg.Title or "Notification",
		TextColor3 = Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 16),
		Parent = content,
	})

	if cfg.Content then
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = cfg.Content,
			TextColor3 = Theme.TextDim,
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = content,
		})
	end

	if cfg.Actions then
		local row = Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 24),
			Parent = content,
		}, {
			Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
			}),
		})
		for _, action in pairs(cfg.Actions) do
			local btn = Create("TextButton", {
				BackgroundColor3 = Theme.Element,
				Font = Enum.Font.GothamMedium,
				Text = action.Name or "OK",
				TextColor3 = Theme.Text,
				TextSize = 12,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 1, 0),
				AutoButtonColor = false,
				Parent = row,
			}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
			Corner(btn, 3)
			Stroke(btn, Theme.Outline)
			btn.MouseButton1Click:Connect(function()
				if action.Callback then task.spawn(action.Callback) end
				card:Destroy()
			end)
		end
	end

	-- fade in
	card.BackgroundTransparency = 1
	Tween(card, { BackgroundTransparency = 0 }, 0.2)

	task.delay(duration, function()
		if card.Parent then
			Tween(card, { BackgroundTransparency = 1 }, 0.25)
			task.wait(0.3)
			card:Destroy()
		end
	end)
end

-- ══════════════════════════════ KEY SYSTEM ══════════════════════════════
local function RunKeySystem(settings)
	settings = settings or {}
	local correctKeys = type(settings.Key) == "table" and settings.Key or { settings.Key or "" }
	local fileName = (settings.FileName or "VoidCriptKey") .. ".key"

	-- saved key check
	if settings.SaveKey and readfile and isfile and isfile(fileName) then
		local saved = readfile(fileName)
		for _, k in ipairs(correctKeys) do
			if saved == k then return true end
		end
	end

	local gui = Create("ScreenGui", {
		Name = "VoidCriptKey",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		Parent = GetGuiParent(),
	})

	local frame = Create("Frame", {
		BackgroundColor3 = Theme.Background,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 320, 0, 180),
		Parent = gui,
	})
	Corner(frame, 4)
	Stroke(frame, Theme.Outline)
	Create("Frame", { BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), Parent = frame })
	MakeDraggable(frame, frame)

	Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = settings.Title or "Key System",
		TextColor3 = Theme.Text,
		TextSize = 15,
		Position = UDim2.new(0, 16, 0, 14),
		Size = UDim2.new(1, -32, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = settings.Subtitle or "",
		TextColor3 = Theme.Accent,
		TextSize = 12,
		Position = UDim2.new(0, 16, 0, 34),
		Size = UDim2.new(1, -32, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = settings.Note or "",
		TextColor3 = Theme.TextDim,
		TextSize = 12,
		TextWrapped = true,
		Position = UDim2.new(0, 16, 0, 54),
		Size = UDim2.new(1, -32, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})

	local box = Create("TextBox", {
		BackgroundColor3 = Theme.Element,
		Font = Enum.Font.Gotham,
		PlaceholderText = "Enter key...",
		PlaceholderColor3 = Theme.TextDark,
		Text = "",
		TextColor3 = Theme.Text,
		TextSize = 13,
		Position = UDim2.new(0, 16, 0, 94),
		Size = UDim2.new(1, -32, 0, 32),
		ClearTextOnFocus = false,
		Parent = frame,
	})
	Corner(box, 3)
	Stroke(box, Theme.Outline)

	local submit = Create("TextButton", {
		BackgroundColor3 = Theme.Accent,
		Font = Enum.Font.GothamBold,
		Text = "Unlock",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Position = UDim2.new(0, 16, 0, 134),
		Size = UDim2.new(1, -32, 0, 30),
		AutoButtonColor = false,
		Parent = frame,
	})
	Corner(submit, 3)

	local passed = false
	local done = Instance.new("BindableEvent")

	submit.MouseButton1Click:Connect(function()
		local entered = box.Text
		for _, k in ipairs(correctKeys) do
			if entered == k then
				passed = true
				if settings.SaveKey and writefile then
					pcall(writefile, fileName, entered)
				end
				done:Fire()
				return
			end
		end
		box.Text = ""
		box.PlaceholderText = "Wrong key!"
		Tween(frame, { BackgroundColor3 = Color3.fromRGB(40, 12, 18) }, 0.1)
		task.wait(0.15)
		Tween(frame, { BackgroundColor3 = Theme.Background }, 0.2)
	end)

	done.Event:Wait()
	gui:Destroy()
	return passed
end

-- ══════════════════════════════ WINDOW ══════════════════════════════
function Library:CreateWindow(cfg)
	cfg = cfg or {}

	if cfg.KeySystem then
		if not RunKeySystem(cfg.KeySettings) then
			return nil
		end
	end

	local Window = {
		_tabs = {},
		_activeTab = nil,
		_toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift,
		_configEnabled = cfg.ConfigurationSaving and cfg.ConfigurationSaving.Enabled,
		_configFolder = cfg.ConfigurationSaving and cfg.ConfigurationSaving.FolderName or "VoidCript",
		_configFile = cfg.ConfigurationSaving and cfg.ConfigurationSaving.FileName or "Config",
	}

	local gui = Create("ScreenGui", {
		Name = "VoidCript",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		Parent = GetGuiParent(),
	})
	Window._gui = gui
	table.insert(Library._guis, gui)

	local main = Create("Frame", {
		BackgroundColor3 = Theme.Background,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 720, 0, 480),
		Parent = gui,
	})
	Window._main = main
	Corner(main, 4)
	Stroke(main, Theme.Outline)

	-- CompKiller: thin accent line across the very top
	Create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 2),
		ZIndex = 5,
		Parent = main,
	})

	-- ── Header ──
	local header = Create("Frame", {
		BackgroundColor3 = Theme.Header,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 42),
		Parent = main,
	})
	Create("Frame", {
		BackgroundColor3 = Theme.OutlineSoft,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = header,
	})
	MakeDraggable(header, main)

	local titleLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = cfg.Name or "voidcript",
		TextColor3 = Theme.Text,
		TextSize = 15,
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(0, 200, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})
	local subtitleLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = cfg.LoadingSubtitle or "",
		TextColor3 = Theme.Accent,
		TextSize = 12,
		Position = UDim2.new(0, 16 + titleLabel.TextBounds.X + 8, 0, 1),
		Size = UDim2.new(0, 200, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})
	task.defer(function()
		subtitleLabel.Position = UDim2.new(0, 16 + titleLabel.TextBounds.X + 8, 0, 1)
	end)

	-- ── Sidebar (icon rail, CompKiller style) ──
	local sidebar = Create("Frame", {
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(0, 64, 1, -42),
		Parent = main,
	}, {
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 4),
		}),
		Create("UIPadding", { PaddingTop = UDim.new(0, 10) }),
	})
	Create("Frame", {
		BackgroundColor3 = Theme.OutlineSoft,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -1, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		Parent = sidebar,
	})

	-- ── Content area ──
	local contentArea = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 64, 0, 42),
		Size = UDim2.new(1, -64, 1, -42),
		Parent = main,
	})

	-- ── Toggle key ──
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Window._toggleKey then
			main.Visible = not main.Visible
		end
	end)

	-- ══════════ Window methods ══════════
	function Window:Show() main.Visible = true end
	function Window:Hide() main.Visible = false end
	function Window:Toggle() main.Visible = not main.Visible end
	function Window:SetTitle(t) titleLabel.Text = t end
	function Window:SetSubtitle(t) subtitleLabel.Text = t end
	function Window:Destroy() gui:Destroy() end
	function Window:SetToggleKey(key) Window._toggleKey = key end

	function Window:SaveConfiguration()
		if not writefile then return end
		local data = {}
		for flag, obj in pairs(Library.Flags) do
			data[flag] = SerializeValue(obj._kind, obj:GetRaw())
		end
		if makefolder and not (isfolder and isfolder(Window._configFolder)) then
			pcall(makefolder, Window._configFolder)
		end
		pcall(writefile, Window._configFolder .. "/" .. Window._configFile .. ".json", HttpService:JSONEncode(data))
	end

	function Window:LoadConfiguration()
		if not readfile or not isfile then return end
		local path = Window._configFolder .. "/" .. Window._configFile .. ".json"
		if not isfile(path) then return end
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
		if not ok or type(data) ~= "table" then return end
		for flag, raw in pairs(data) do
			local obj = Library.Flags[flag]
			if obj then
				pcall(function() obj:Set(DeserializeValue(raw)) end)
			end
		end
	end

	local function requestAutoSave()
		if not Window._configEnabled then return end
		if Library._saveDebounce then task.cancel(Library._saveDebounce) end
		Library._saveDebounce = task.delay(2, function()
			Window:SaveConfiguration()
			Library._saveDebounce = nil
		end)
	end
	Window._requestAutoSave = requestAutoSave

	-- ══════════ Tabs ══════════
	local function selectTab(tab)
		for _, t in ipairs(Window._tabs) do
			local active = (t == tab)
			t._page.Visible = active
			Tween(t._btn.IconLabel, { TextColor3 = active and Theme.Accent or Theme.TextDark }, 0.15)
			t._btn.Indicator.Visible = active
			Tween(t._btn, { BackgroundColor3 = active and Theme.Element or Theme.Sidebar }, 0.15)
		end
		Window._activeTab = tab
	end

	function Window:SelectTab(name)
		for _, t in ipairs(Window._tabs) do
			if t._name == name then
				selectTab(t)
				return
			end
		end
	end

	function Window:CreateTab(name, icon, subtabs)
		subtabs = subtabs or {}

		local Tab = { _name = name, _sections = {}, _subtabs = {}, _activeSubtab = nil, _window = Window }

		-- sidebar button
		local btn = Create("TextButton", {
			BackgroundColor3 = Theme.Sidebar,
			Text = "",
			Size = UDim2.new(0, 48, 0, 44),
			AutoButtonColor = false,
			Parent = sidebar,
		})
		Corner(btn, 4)

		local iconText = Icons[icon] or (type(icon) == "string" and #icon <= 3 and icon) or "•"
		local isAsset = type(icon) == "number"

		if isAsset then
			Create("ImageLabel", {
				Name = "IconImage",
				BackgroundTransparency = 1,
				Image = "rbxassetid://" .. icon,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, -6),
				Size = UDim2.new(0, 20, 0, 20),
				ImageColor3 = Theme.TextDark,
				Parent = btn,
			})
			Create("TextLabel", {
				Name = "IconLabel",
				BackgroundTransparency = 1,
				Text = "",
				TextColor3 = Theme.TextDark,
				Size = UDim2.new(0, 0, 0, 0),
				Parent = btn,
			})
		else
			Create("TextLabel", {
				Name = "IconLabel",
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = iconText,
				TextColor3 = Theme.TextDark,
				TextSize = 16,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, -6),
				Size = UDim2.new(1, 0, 0, 18),
				Parent = btn,
			})
		end

		Create("TextLabel", {
			Name = "NameLabel",
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = name,
			TextColor3 = Theme.TextDark,
			TextSize = 9,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -4),
			Size = UDim2.new(1, -2, 0, 10),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = btn,
		})

		Create("Frame", {
			Name = "Indicator",
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0.5, -10),
			Size = UDim2.new(0, 2, 0, 20),
			Visible = false,
			Parent = btn,
		})

		Tab._btn = btn

		-- page
		local page = Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Visible = false,
			Parent = contentArea,
		})
		Tab._page = page

		local hasSubtabs = #subtabs > 0
		local subtabBar
		if hasSubtabs then
			subtabBar = Create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 8),
				Size = UDim2.new(1, -24, 0, 28),
				Parent = page,
			}, {
				Create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
				}),
			})
		end

		local pagesHolder = Create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, hasSubtabs and 40 or 4),
			Size = UDim2.new(1, 0, 1, hasSubtabs and -44 or -8),
			Parent = page,
		})

		local function makeSubPage()
			local scroll = Create("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, 0),
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = Theme.Accent,
				Visible = false,
				Parent = pagesHolder,
			})
			local left = Create("Frame", {
				Name = "Left",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(0.5, -18, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = scroll,
			}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }) })
			local right = Create("Frame", {
				Name = "Right",
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 6, 0, 0),
				Size = UDim2.new(0.5, -18, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = scroll,
			}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }) })
			return { Scroll = scroll, Left = left, Right = right }
		end

		local function selectSubtab(subName)
			for sName, s in pairs(Tab._subtabs) do
				local active = (sName == subName)
				s.Page.Scroll.Visible = active
				if s.Button then
					Tween(s.Button, { BackgroundColor3 = active and Theme.Element or Theme.Header }, 0.12)
					Tween(s.Button.TextLabel, { TextColor3 = active and Theme.Accent or Theme.TextDim }, 0.12)
					s.Button.Underline.Visible = active
				end
			end
			Tab._activeSubtab = subName
		end
		Tab._selectSubtab = selectSubtab

		if hasSubtabs then
			for i, subName in ipairs(subtabs) do
				local subPage = makeSubPage()
				local sbtn = Create("TextButton", {
					BackgroundColor3 = Theme.Header,
					Text = "",
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.new(0, 0, 1, 0),
					AutoButtonColor = false,
					Parent = subtabBar,
				}, {
					Create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
					Create("TextLabel", {
						BackgroundTransparency = 1,
						Font = Enum.Font.GothamMedium,
						Text = subName,
						TextColor3 = Theme.TextDim,
						TextSize = 12,
						AutomaticSize = Enum.AutomaticSize.X,
						Size = UDim2.new(0, 0, 1, 0),
					}),
					Create("Frame", {
						Name = "Underline",
						BackgroundColor3 = Theme.Accent,
						BorderSizePixel = 0,
						Position = UDim2.new(0, 0, 1, -2),
						Size = UDim2.new(1, 0, 0, 2),
						Visible = false,
					}),
				})
				Corner(sbtn, 3)
				Stroke(sbtn, Theme.OutlineSoft)
				sbtn.MouseButton1Click:Connect(function() selectSubtab(subName) end)
				Tab._subtabs[subName] = { Page = subPage, Button = sbtn, Index = i }
			end
			selectSubtab(subtabs[1])
		else
			local single = makeSubPage()
			single.Scroll.Visible = true
			Tab._subtabs["__default"] = { Page = single, Index = 1 }
			Tab._activeSubtab = "__default"
		end

		btn.MouseButton1Click:Connect(function() selectTab(Tab) end)
		btn.MouseEnter:Connect(function()
			if Window._activeTab ~= Tab then Tween(btn.IconLabel, { TextColor3 = Theme.TextDim }, 0.1) end
		end)
		btn.MouseLeave:Connect(function()
			if Window._activeTab ~= Tab then Tween(btn.IconLabel, { TextColor3 = Theme.TextDark }, 0.1) end
		end)

		-- ══════════ Sections ══════════
		function Tab:CreateSection(sectionCfg)
			if type(sectionCfg) == "string" then
				sectionCfg = { Name = sectionCfg }
			end
			sectionCfg = sectionCfg or {}

			local subKey = "__default"
			if sectionCfg.Subtab then
				if type(sectionCfg.Subtab) == "number" then
					for sName, s in pairs(Tab._subtabs) do
						if s.Index == sectionCfg.Subtab then subKey = sName break end
					end
				elseif Tab._subtabs[sectionCfg.Subtab] then
					subKey = sectionCfg.Subtab
				end
			elseif Tab._activeSubtab then
				subKey = Tab._activeSubtab
			end

			local subPage = Tab._subtabs[subKey].Page
			local column = (sectionCfg.Side == "right") and subPage.Right or subPage.Left

			local Section = {}

			local box = Create("Frame", {
				BackgroundColor3 = Theme.Section,
				Size = UDim2.new(1, 0, 0, sectionCfg.Height or 0),
				AutomaticSize = sectionCfg.Height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
				Parent = column,
			})
			Corner(box, 4)
			Stroke(box, Theme.OutlineSoft)

			-- section title on border (CompKiller groupbox style)
			local titleHolder = Create("Frame", {
				BackgroundColor3 = Theme.Section,
				Position = UDim2.new(0, 10, 0, -7),
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 0, 14),
				ZIndex = 3,
				Parent = box,
			}, {
				Create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }),
				Create("TextLabel", {
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamMedium,
					Text = sectionCfg.Name or "Section",
					TextColor3 = Theme.Text,
					TextSize = 12,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.new(0, 0, 1, 0),
					ZIndex = 3,
				}),
			})

			local elementsParent
			if sectionCfg.Height then
				elementsParent = Create("ScrollingFrame", {
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0, 14),
					Size = UDim2.new(1, 0, 1, -20),
					CanvasSize = UDim2.new(0, 0, 0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 2,
					ScrollBarImageColor3 = Theme.Accent,
					Parent = box,
				})
			else
				elementsParent = Create("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 0, 0, 14),
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Parent = box,
				})
			end
			Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = elementsParent })
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 10),
				Parent = elementsParent,
			})

			local function registerFlag(flag, obj)
				if flag then Library.Flags[flag] = obj end
			end

			local function changed(flag, value)
				Window._requestAutoSave()
				Library:_fireChanged(flag, value)
			end

			-- ─────────── TOGGLE ───────────
			function Section:CreateToggle(c)
				c = c or {}
				local state = c.CurrentValue or false

				local row = Create("TextButton", {
					BackgroundTransparency = 1,
					Text = "",
					Size = UDim2.new(1, 0, 0, 18),
					Parent = elementsParent,
				})
				local checkbox = Create("Frame", {
					BackgroundColor3 = state and Theme.Accent or Theme.Element,
					Size = UDim2.new(0, 12, 0, 12),
					Position = UDim2.new(0, 0, 0.5, -6),
					Parent = row,
				})
				Corner(checkbox, 2)
				local cbStroke = Stroke(checkbox, state and Theme.Accent or Theme.Outline)
				Create("TextLabel", {
					BackgroundTransparency = 1,
					Font = Enum.Font.Gotham,
					Text = c.Name or "Toggle",
					TextColor3 = state and Theme.Text or Theme.TextDim,
					TextSize = 12,
					Position = UDim2.new(0, 20, 0, 0),
					Size = UDim2.new(1, -20, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					Name = "Label",
					Parent = row,
				})

				AttachTooltip(row, c.Tooltip)

				local Toggle = { _kind = "Toggle" }
				local function apply(v, silent)
					state = v
					Tween(checkbox, { BackgroundColor3 = state and Theme.Accent or Theme.Element }, 0.12)
					cbStroke.Color = state and Theme.Accent or Theme.Outline
					Tween(row.Label, { TextColor3 = state and Theme.Text or Theme.TextDim }, 0.12)
					if not silent then
						if c.Callback then task.spawn(c.Callback, state) end
						changed(c.Flag, state)
					end
				end
				row.MouseButton1Click:Connect(function() apply(not state) end)
				function Toggle:Set(v) apply(v) end
				function Toggle:Get() return state end
				function Toggle:GetRaw() return state end
				registerFlag(c.Flag, Toggle)
				if state and c.Callback then task.spawn(c.Callback, state) end
				return Toggle
			end

			-- ─────────── SLIDER ───────────
			function Section:CreateSlider(c)
				c = c or {}
				local min, max = (c.Range and c.Range[1]) or 0, (c.Range and c.Range[2]) or 100
				local inc = c.Increment or 1
				local value = math.clamp(c.CurrentValue or min, min, max)
				local suffix = c.Suffix or ""

				local holder = Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 32),
					Parent = elementsParent,
				})
				Create("TextLabel", {
					BackgroundTransparency = 1,
					Font = Enum.Font.Gotham,
					Text = c.Name or "Slider",
					TextColor3 = Theme.TextDim,
					TextSize = 12,
					Size = UDim2.new(0.6, 0, 0, 14),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = holder,
				})
				local valueLabel = Create("TextLabel", {
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamMedium,
					Text = tostring(value) .. suffix,
					TextColor3 = Theme.Accent,
					TextSize = 12,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					Size = UDim2.new(0.4, 0, 0, 14),
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = holder,
				})
				local track = Create("Frame", {
					BackgroundColor3 = Theme.Element,
					Position = UDim2.new(0, 0, 0, 20),
					Size = UDim2.new(1, 0, 0, 6),
					Parent = holder,
				})
				Corner(track, 3)
				Stroke(track, Theme.OutlineSoft)
				local fill = Create("Frame", {
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
					Parent = track,
				})
				Corner(fill, 3)

				AttachTooltip(holder, c.Tooltip)

				local Slider = { _kind = "Slider" }
				local function apply(v, silent)
					v = math.clamp(math.floor((v - min) / inc + 0.5) * inc + min, min, max)
					-- fix float noise
					v = tonumber(string.format("%.4f", v))
					value = v
					fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
					valueLabel.Text = tostring(value) .. suffix
					if not silent then
						if c.Callback then task.spawn(c.Callback, value) end
						changed(c.Flag, value)
					end
				end

				local dragging = false
				local function updateFromInput(input)
					local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
					apply(min + rel * (max - min))
				end
				track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						updateFromInput(input)
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						updateFromInput(input)
					end
				end)

				function Slider:Set(v) apply(v) end
				function Slider:Get() return value end
				function Slider:GetRaw() return value end
				registerFlag(c.Flag, Slider)
				return Slider
			end

			-- ─────────── DROPDOWN ───────────
			function Section:CreateDropdown(c)
				c = c or {}
				local options = c.Options or {}
				local current = c.CurrentOption or options[1]

				local holder = Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 40),
					AutomaticSize = Enum.AutomaticSize.Y,
					Parent = elementsParent,
				})
				Create("TextLabel", {
					BackgroundTransparency = 1,
					Font = Enum.Font.Gotham,
					Text = c.Name or "Dropdown",
					TextColor3 = Theme.TextDim,
					TextSize = 12,
					Size = UDim2.new(1, 0, 0, 14),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = holder,
				})
				local btn = Create("TextButton", {
					BackgroundColor3 = Theme.Element,
					Text = "",
					Position = UDim2.new(0, 0, 0, 18),
					Size = UDim2.new(1, 0, 0, 24),
					AutoButtonColor = false,
					Parent = holder,
				})
				Corner(btn, 3)
				Stroke(btn, Theme.OutlineSoft)
				local currentLabel = Create("TextLabel", {
					BackgroundTransparency = 1,
					Font = Enum.Font.Gotham,
					Text = tostring(current or ""),
					TextColor3 = Theme.Text,
					TextSize = 12,
					Position = UDim2.new(0, 8, 0, 0),
					Size = UDim2.new(1, -28, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = btn,
				})
				local arrow = Create("TextLabel", {
					BackgroundTransparency = 1,
					Font = Enum.Font.Gotham,
					Text = "▾",
					TextColor3 = Theme.Accent,
					TextSize = 12,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -8, 0, 0),
					Size = UDim2.new(0, 14, 1, 0),
					Parent = btn,
				})
				local listFrame = Create("Frame", {
					BackgroundColor3 = Theme.Element,
					Position = UDim2.new(0, 0, 0, 46),
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Visible = false,
					ZIndex = 4,
					Parent = holder,
				}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })
				Corner(listFrame, 3)
				Stroke(listFrame, Theme.Outline)

				local Dropdown = { _kind = "Dropdown" }
				local open = false

				local function rebuild()
					for _, child in ipairs(listFrame:GetChildren()) do
						if child:IsA("TextButton") then child:Destroy() end
					end
					for i, opt in ipairs(options) do
						local optBtn = Create("TextButton", {
							BackgroundColor3 = Theme.Element,
							Font = Enum.Font.Gotham,
							Text = tostring(opt),
							TextColor3 = (opt == current) and Theme.Accent or Theme.TextDim,
							TextSize = 12,
							Size = UDim2.new(1, 0, 0, 22),
							TextXAlignment = Enum.TextXAlignment.Left,
							AutoButtonColor = false,
							ZIndex = 4,
							Parent = listFrame,
						}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }) })
						optBtn.MouseEnter:Connect(function() Tween(optBtn, { BackgroundColor3 = Theme.ElementHover }, 0.1) end)
						optBtn.MouseLeave:Connect(function() Tween(optBtn, { BackgroundColor3 = Theme.Element }, 0.1) end)
						optBtn.MouseButton1Click:Connect(function()
							current = opt
							currentLabel.Text = tostring(opt)
							open = false
							listFrame.Visible = false
							arrow.Text = "▾"
							rebuild()
							if c.Callback then task.spawn(c.Callback, opt, i) end
							changed(c.Flag, opt)
						end)
					end
				end
				rebuild()

				btn.MouseButton1Click:Connect(function()
					open = not open
					listFrame.Visible = open
					arrow.Text = open and "▴" or "▾"
				end)

				function Dropdown:Set(opt)
					current = opt
					currentLabel.Text = tostring(opt)
					rebuild()
					local idx = table.find(options, opt)
					if c.Callback then task.spawn(c.Callback, opt, idx) end
					changed(c.Flag, opt)
				end
				function Dropdown:Get() return current end
				function Dropdown:GetRaw() return current end
				function Dropdown:Refresh(newOptions)
					options = newOptions or {}
					if not table.find(options, current) then
						current = options[1]
						currentLabel.Text = tostring(current or "")
					end
					rebuild()
				end
				registerFlag(c.Flag, Dropdown)
				return Dropdown
			end

			-- ─────────── INPUT ───────────
			function Section:CreateInput(c)
				c = c or {}
				local holder = Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 42),
					Parent = elementsParent,
				})
				Create("TextLabel", {
					BackgroundTransparency = 1,
					Font = Enum.Font.Gotham,
					Text = c.Name or "Input",
					TextColor3 = Theme.TextDim,
					TextSize = 12,
					Size = UDim2.new(1, 0, 0, 14),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = holder,
				})
				local box = Create("TextBox", {
					BackgroundColor3 = Theme.Element,
					Font = Enum.Font.Gotham,
					PlaceholderText = c.PlaceholderText or "",
					PlaceholderColor3 = Theme.TextDark,
					Text = c.CurrentValue or "",
					TextColor3 = Theme.Text,
					TextSize = 12,
					Position = UDim2.new(0, 0, 0, 18),
					Size = UDim2.new(1, 0, 0, 24),
					ClearTextOnFocus = false,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = holder,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }) })
				Corner(box, 3)
				local boxStroke = Stroke(box, Theme.OutlineSoft)

				box.Focused:Connect(function() boxStroke.Color = Theme.Accent end)
				box.FocusLost:Connect(function()
					boxStroke.Color = Theme.OutlineSoft
					if c.Callback then task.spawn(c.Callback, box.Text) end
					if c.RemoveTextAfterFocusLost then box.Text = "" end
					changed(c.Flag, box.Text)
				end)

				local Input = { _kind = "Input" }
				function Input:Set(t) box.Text = t or "" end
				function Input:Get() return box.Text end
				function Input:GetRaw() return box.Text end
				registerFlag(c.Flag, Input)
				return Input
			end
			Section.CreateTextbox = Section.CreateInput

			-- ─────────── KEYBIND ───────────
			function Section:CreateKeybind(c)
				c = c or {}
				local key = c.CurrentKeybind
				local listening = false

				local row = Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 20),
					Parent = elementsParent,
				})
				Create("TextLabel", {
					BackgroundTransparency = 1,
					Font = Enum.Font.Gotham,
					Text = c.Name or "Keybind",
					TextColor3 = Theme.TextDim,
					TextSize = 12,
					Size = UDim2.new(0.6, 0, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})
				local keyBtn = Create("TextButton", {
					BackgroundColor3 = Theme.Element,
					Font = Enum.Font.GothamMedium,
					Text = key and key.Name or "None",
					TextColor3 = Theme.Accent,
					TextSize = 11,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.new(0, 0, 0, 18),
					AutoButtonColor = false,
					Parent = row,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })
				Corner(keyBtn, 3)
				Stroke(keyBtn, Theme.OutlineSoft)

				local Keybind = { _kind = "Keybind" }
				local held = false

				keyBtn.MouseButton1Click:Connect(function()
					listening = true
					keyBtn.Text = "..."
				end)

				UserInputService.InputBegan:Connect(function(input, gpe)
					if listening and input.UserInputType == Enum.UserInputType.Keyboard then
						listening = false
						key = input.KeyCode
						keyBtn.Text = key.Name
						changed(c.Flag, key)
						return
					end
					if gpe or not key then return end
					if input.KeyCode == key then
						if c.HoldToInteract then
							held = true
							if c.Callback then task.spawn(c.Callback, true) end
						else
							if c.Callback then task.spawn(c.Callback, true) end
						end
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if key and input.KeyCode == key and c.HoldToInteract and held then
						held = false
						if c.Callback then task.spawn(c.Callback, false) end
					end
				end)

				function Keybind:Set(k)
					key = k
					keyBtn.Text = k and k.Name or "None"
				end
				function Keybind:Get() return key end
				function Keybind:GetRaw() return key end
				registerFlag(c.Flag, Keybind)
				return Keybind
			end
			Section.CreateBind = Section.CreateKeybind

			-- ─────────── COLOR PICKER ───────────
			function Section:CreateColorPicker(c)
				c = c or {}
				local color = c.Color or Theme.Accent
				local alpha = c.Alpha or 1
				local hasAlpha = c.Alpha ~= nil
				local h, s, v = color:ToHSV()

				local row = Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 20),
					AutomaticSize = Enum.AutomaticSize.Y,
					Parent = elementsParent,
				})
				Create("TextLabel", {
					BackgroundTransparency = 1,
					Font = Enum.Font.Gotham,
					Text = c.Name or "Color",
					TextColor3 = Theme.TextDim,
					TextSize = 12,
					Size = UDim2.new(0.7, 0, 0, 20),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})
				local swatch = Create("TextButton", {
					BackgroundColor3 = color,
					Text = "",
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, 0, 0, 3),
					Size = UDim2.new(0, 28, 0, 14),
					AutoButtonColor = false,
					Parent = row,
				})
				Corner(swatch, 2)
				Stroke(swatch, Theme.Outline)

				-- expandable picker
				local picker = Create("Frame", {
					BackgroundColor3 = Theme.Element,
					Position = UDim2.new(0, 0, 0, 24),
					Size = UDim2.new(1, 0, 0, hasAlpha and 130 or 112),
					Visible = false,
					Parent = row,
				})
				Corner(picker, 3)
				Stroke(picker, Theme.Outline)

				-- SV box
				local svBox = Create("TextButton", {
					BackgroundColor3 = Color3.fromHSV(h, 1, 1),
					Text = "",
					Position = UDim2.new(0, 8, 0, 8),
					Size = UDim2.new(1, -16, 0, 70),
					AutoButtonColor = false,
					Parent = picker,
				})
				Corner(svBox, 2)
				Create("UIGradient", {
					Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 1),
					}),
					Parent = svBox,
				})
				local svDark = Create("Frame", {
					BackgroundColor3 = Color3.new(0, 0, 0),
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Parent = svBox,
				})
				Corner(svDark, 2)
				Create("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(1, 0),
					}),
					Parent = svDark,
				})
				svDark.BackgroundTransparency = 0

				local svCursor = Create("Frame", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(s, 0, 1 - v, 0),
					Size = UDim2.new(0, 6, 0, 6),
					ZIndex = 3,
					Parent = svBox,
				})
				Corner(svCursor, 3)
				Stroke(svCursor, Color3.new(0, 0, 0))

				-- hue bar
				local hueBar = Create("TextButton", {
					Text = "",
					BackgroundColor3 = Color3.new(1, 1, 1),
					Position = UDim2.new(0, 8, 0, 86),
					Size = UDim2.new(1, -16, 0, 10),
					AutoButtonColor = false,
					Parent = picker,
				})
				Corner(hueBar, 2)
				Create("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
						ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
						ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
						ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
						ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
						ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
						ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
					}),
					Parent = hueBar,
				})
				local hueCursor = Create("Frame", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(h, 0, 0.5, 0),
					Size = UDim2.new(0, 3, 1, 2),
					ZIndex = 3,
					Parent = hueBar,
				})
				Stroke(hueCursor, Color3.new(0, 0, 0))

				-- alpha bar (optional)
				local alphaBar, alphaCursor
				if hasAlpha then
					alphaBar = Create("TextButton", {
						Text = "",
						BackgroundColor3 = Color3.new(1, 1, 1),
						Position = UDim2.new(0, 8, 0, 102),
						Size = UDim2.new(1, -16, 0, 10),
						AutoButtonColor = false,
						Parent = picker,
					})
					Corner(alphaBar, 2)
					Create("UIGradient", {
						Color = ColorSequence.new(Color3.new(0, 0, 0), color),
						Name = "AlphaGradient",
						Parent = alphaBar,
					})
					alphaCursor = Create("Frame", {
						BackgroundColor3 = Color3.new(1, 1, 1),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(alpha, 0, 0.5, 0),
						Size = UDim2.new(0, 3, 1, 2),
						ZIndex = 3,
						Parent = alphaBar,
					})
					Stroke(alphaCursor, Color3.new(0, 0, 0))
				end

				local ColorPicker = { _kind = "ColorPicker" }

				local function updateVisual(silent)
					color = Color3.fromHSV(h, s, v)
					swatch.BackgroundColor3 = color
					svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
					svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
					hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
					if alphaBar then
						alphaBar.AlphaGradient.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(h, 1, 1))
						alphaCursor.Position = UDim2.new(alpha, 0, 0.5, 0)
					end
					if not silent then
						if c.Callback then task.spawn(c.Callback, color, alpha) end
						changed(c.Flag, color)
					end
				end

				local function bindDrag(bar, onMove)
					local dragging = false
					bar.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							dragging = true
							onMove(input)
						end
					end)
					UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							dragging = false
						end
					end)
					UserInputService.InputChanged:Connect(function(input)
						if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
							onMove(input)
						end
					end)
				end

				bindDrag(svBox, function(input)
					s = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
					v = 1 - math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
					updateVisual()
				end)
				bindDrag(hueBar, function(input)
					h = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
					updateVisual()
				end)
				if alphaBar then
					bindDrag(alphaBar, function(input)
						alpha = math.clamp((input.Position.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
						updateVisual()
					end)
				end

				swatch.MouseButton1Click:Connect(function()
					picker.Visible = not picker.Visible
				end)

				function ColorPicker:Set(val)
					if typeof(val) == "Color3" then
						h, s, v = val:ToHSV()
					elseif type(val) == "table" and val.Color then
						h, s, v = val.Color:ToHSV()
						if val.Alpha then alpha = val.Alpha end
					end
					updateVisual()
				end
				function ColorPicker:Get() return color, alpha end
				function ColorPicker:GetRaw() return { Color = color, Alpha = alpha } end
				registerFlag(c.Flag, ColorPicker)
				return ColorPicker
			end

			-- ─────────── BUTTON ───────────
			function Section:CreateButton(c)
				c = c or {}
				local btn = Create("TextButton", {
					BackgroundColor3 = Theme.Element,
					Font = Enum.Font.GothamMedium,
					Text = c.Name or "Button",
					TextColor3 = Theme.Text,
					TextSize = 12,
					Size = UDim2.new(1, 0, 0, 26),
					AutoButtonColor = false,
					Parent = elementsParent,
				})
				Corner(btn, 3)
				local btnStroke = Stroke(btn, Theme.OutlineSoft)

				btn.MouseEnter:Connect(function()
					Tween(btn, { BackgroundColor3 = Theme.ElementHover }, 0.1)
					btnStroke.Color = Theme.Accent
				end)
				btn.MouseLeave:Connect(function()
					Tween(btn, { BackgroundColor3 = Theme.Element }, 0.1)
					btnStroke.Color = Theme.OutlineSoft
				end)
				AttachTooltip(btn, c.Tooltip)

				local armed = false
				btn.MouseButton1Click:Connect(function()
					Tween(btn, { BackgroundColor3 = Theme.AccentDark }, 0.06)
					task.delay(0.1, function() Tween(btn, { BackgroundColor3 = Theme.Element }, 0.15) end)
					if c.Confirm and not armed then
						armed = true
						btn.Text = c.ConfirmText or "Are you sure?"
						btn.TextColor3 = Theme.Accent
						task.delay(2.5, function()
							if armed then
								armed = false
								btn.Text = c.Name or "Button"
								btn.TextColor3 = Theme.Text
							end
						end)
						return
					end
					armed = false
					btn.Text = c.Name or "Button"
					btn.TextColor3 = Theme.Text
					if c.Callback then task.spawn(c.Callback) end
				end)

				local Button = { _kind = "Button" }
				function Button:Fire()
					if c.Callback then task.spawn(c.Callback) end
				end
				return Button
			end

			-- ─────────── PARAGRAPH ───────────
			function Section:CreateParagraph(c)
				c = c or {}
				local holder = Create("Frame", {
					BackgroundColor3 = Theme.Element,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Parent = elementsParent,
				}, {
					Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }),
					Create("UIPadding", {
						PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
						PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
					}),
				})
				Corner(holder, 3)
				Stroke(holder, Theme.OutlineSoft)
				local titleL = Create("TextLabel", {
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamMedium,
					Text = c.Title or "Paragraph",
					TextColor3 = Theme.Text,
					TextSize = 12,
					Size = UDim2.new(1, 0, 0, 14),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = holder,
				})
				local bodyL = Create("TextLabel", {
					BackgroundTransparency = 1,
					Font = Enum.Font.Gotham,
					Text = c.Content or "",
					TextColor3 = Theme.TextDim,
					TextSize = 11,
					TextWrapped = true,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = holder,
				})
				local Paragraph = {}
				function Paragraph:Set(newTitle, newBody)
					if newTitle then titleL.Text = newTitle end
					if newBody then bodyL.Text = newBody end
				end
				return Paragraph
			end

			-- ─────────── LABEL ───────────
			function Section:CreateLabel(c)
				c = c or {}
				local iconText = c.Icon and (Icons[c.Icon] or c.Icon) or nil
				local label = Create("TextLabel", {
					BackgroundTransparency = 1,
					Font = Enum.Font.Gotham,
					Text = (iconText and (iconText .. "  ") or "") .. (c.Name or "Label"),
					TextColor3 = Theme.TextDim,
					TextSize = 12,
					Size = UDim2.new(1, 0, 0, 16),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = elementsParent,
				})
				local Label = {}
				function Label:Set(t) label.Text = (iconText and (iconText .. "  ") or "") .. t end
				return Label
			end

			-- ─────────── DIVIDER ───────────
			function Section:CreateDivider()
				Create("Frame", {
					BackgroundColor3 = Theme.OutlineSoft,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 1),
					Parent = elementsParent,
				})
			end

			table.insert(Tab._sections, Section)
			return Section
		end

		table.insert(Window._tabs, Tab)
		if #Window._tabs == 1 then
			selectTab(Tab)
		end
		return Tab
	end

	-- auto-load config after everything is built (deferred one frame)
	if Window._configEnabled then
		task.defer(function()
			task.wait(0.5)
			Window:LoadConfiguration()
		end)
	end

	return Window
end

return Library
