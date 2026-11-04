local addonName = ...
local events = CreateFrame("Frame")
local activeTrack
local manualTrack
local activePoolKey
local autoRecent = {}
local autoCursor = {}
local intervalRemaining = 0
local elapsed = 0
local generation = 0
local paused = false
local history = {}
local panel
local minimapButton
local trackText
local statusText
local panelButtons
local libraryTabs
local trackRows
local libraryNote
local pageText
local trackPage = 1
local miniBar
local miniToggleButton
local miniButtons
local miniTimeText
local lastTimeText
local libraries = {
    pwi = { tracks = PWZoneMusicTracks, order = PWZoneMusicOrder, zones = PWZoneMusicZones,
        defaultTrack = PWZoneMusicDefaultTrack, audioFolder = "PerfectWorld", pools = PWZoneMusicPools },
    morrowind = PWZoneMusicMorrowind,
}

local function Library()
    return libraries[PWZoneMusicSettings.library or "pwi"]
end

local function LibraryReady()
    return PWZoneMusicInstalled[PWZoneMusicSettings.library or "pwi"] == true
end

local function Say(message)
    print("|cff88cceeWoW Zone Music Player:|r " .. message)
end

local function MapID()
    if C_Map and C_Map.GetBestMapForUnit then
        return C_Map.GetBestMapForUnit("player")
    end
end

local function TrackForMap(mapID)
    local library = Library()
    local id = mapID
    while id do
        local key = library.zones[id]
        if key then return key end
        if not C_Map or not C_Map.GetMapInfo then break end
        local info = C_Map.GetMapInfo(id)
        id = info and info.parentMapID
        if id == 0 then break end
    end
    return library.defaultTrack
end

local function PickAutoTrack(poolKey)
    local pool = Library().pools[poolKey] or { poolKey }
    local candidates = {}
    for index, key in ipairs(pool) do
        if key ~= autoRecent[1] and key ~= autoRecent[2] then
            candidates[#candidates + 1] = index
        end
    end
    if #candidates == 0 then
        for index, key in ipairs(pool) do
            if key ~= autoRecent[1] then candidates[#candidates + 1] = index end
        end
    end
    if #candidates == 0 then candidates[1] = 1 end
    local selected
    if PWZoneMusicSettings.shuffle then
        selected = candidates[math.random(#candidates)]
    else
        local cursor = autoCursor[poolKey] or 0
        for _, index in ipairs(candidates) do
            if index > cursor then selected = index break end
        end
        selected = selected or candidates[1]
    end
    autoCursor[poolKey] = selected
    local key = pool[selected]
    autoRecent[2] = autoRecent[1]
    autoRecent[1] = key
    return key
end

local function TrackDuration(key)
    local track = key and Library().tracks[key]
    local duration = track and tonumber(track.duration) or 180
    return math.max(duration, 5)
end

local function ShortTitle(title, limit)
    if #title <= limit then return title end
    return title:sub(1, limit - 3) .. "..."
end

local function UpdateTime()
    if not miniTimeText then return end
    local label = "--:--"
    if activeTrack then
        local remaining = math.max(0, math.ceil(TrackDuration(activeTrack) - elapsed))
        label = string.format("-%d:%02d", math.floor(remaining / 60), remaining % 60)
    elseif intervalRemaining > 0 then
        local remaining = math.ceil(intervalRemaining)
        label = string.format("%d:%02d", math.floor(remaining / 60), remaining % 60)
    end
    if label ~= lastTimeText then
        miniTimeText:SetText(label)
        lastTimeText = label
    end
end

local function UpdateUI()
    if not panel then return end
    local settings = PWZoneMusicSettings
    local key = activeTrack or manualTrack or (intervalRemaining <= 0 and TrackForMap(MapID()))
    local track = key and Library().tracks[key]
    local title = intervalRemaining > 0 and "Ambient interval" or
        (track and track.title or (key and key:gsub("_", " ") or "None"))
    trackText:SetText(ShortTitle(title, 27))
    local state = not LibraryReady() and "Files missing" or not settings.enabled and "Off" or
        paused and "Paused" or intervalRemaining > 0 and "Interval" or "Playing"
    statusText:SetText(state .. " / " .. (manualTrack and "Manual" or "Auto zone"))
    miniToggleButton.label:SetText(settings.miniBar and "Mini bar ON" or "Mini bar OFF")
    libraryNote:SetText(LibraryReady() and "SELECT A TRACK" or "INSTALL MUSIC FILES TO PLAY")
    for id, tab in pairs(libraryTabs) do
        local selected = settings.library == id
        local tone = selected and 1 or 0.48
        tab.icon:SetVertexColor(tone, tone, tone)
        tab.label:SetTextColor(selected and 1 or 0.65, selected and 0.85 or 0.72, 0.55)
        tab.background:SetColorTexture(selected and 0.16 or 0.07, selected and 0.24 or 0.11, 0.27, 0.96)
    end
    local order = Library().order
    local pages = math.ceil(#order / 16)
    if trackPage > pages then trackPage = pages end
    pageText:SetText(string.format("%d / %d", trackPage, pages))
    for index, row in ipairs(trackRows) do
        local orderIndex = (trackPage - 1) * 16 + index
        local rowKey = order[orderIndex]
        if rowKey then
            local rowTrack = Library().tracks[rowKey]
            row.key = rowKey
            row.label:SetText(string.format("%02d  %s", orderIndex,
                ShortTitle(rowTrack.title or rowKey:gsub("_", " "), 24)))
            row.label:SetTextColor(rowKey == key and 1 or 0.72, rowKey == key and 0.85 or 0.79, rowKey == key and 0.55 or 0.82)
            row:Show()
        else
            row.key = nil
            row:Hide()
        end
    end
    local playing = settings.enabled and not paused
    panelButtons.play.icon:SetTexCoord(playing and 3 / 8 or 2 / 8, playing and 4 / 8 or 3 / 8, 0, 1)
    for id, on in pairs({ power = settings.enabled, repeatOne = settings.repeatOne,
        shuffle = settings.shuffle, auto = not manualTrack }) do
        local button = panelButtons[id]
        local tone = on and 1 or 0.44
        button.icon:SetVertexColor(tone, tone, tone)
    end
    minimapButton.icon:SetVertexColor(settings.enabled and 1 or 0.5, settings.enabled and 1 or 0.5, settings.enabled and 1 or 0.5)
    if miniButtons then
        miniButtons.play.icon:SetTexCoord(settings.enabled and not paused and 3 / 8 or 2 / 8, settings.enabled and not paused and 4 / 8 or 3 / 8, 0, 1)
        local powerTone = settings.enabled and 1 or 0.45
        local repeatTone = settings.repeatOne and 1 or 0.45
        local shuffleTone = settings.shuffle and 1 or 0.45
        local autoTone = manualTrack and 0.45 or 1
        miniButtons.power.icon:SetVertexColor(powerTone, powerTone, powerTone)
        miniButtons.repeatOne.icon:SetVertexColor(repeatTone, repeatTone, repeatTone)
        miniButtons.shuffle.icon:SetVertexColor(shuffleTone, shuffleTone, shuffleTone)
        miniButtons.auto.icon:SetVertexColor(autoTone, autoTone, autoTone)
    end
    UpdateTime()
end

local function Stop()
    generation = generation + 1
    if activeTrack or intervalRemaining > 0 then StopMusic() end
    activeTrack = nil
    intervalRemaining = 0
    elapsed = 0
    UpdateUI()
end

local function Play(key)
    local track = Library().tracks[key]
    if not track or not track.file or track.file == "" then
        Stop()
        return
    end
    local folder = Library().audioFolder
    local path = "Interface\\AddOns\\" .. addonName .. "\\Audio\\"
        .. (folder ~= "" and folder .. "\\" or "") .. track.file
    Stop()
    PlayMusic(path)
    activeTrack = key
    elapsed = 0
    generation = generation + 1
    UpdateUI()
end

local function BeginInterval()
    local previous = activeTrack
    activeTrack = nil
    elapsed = 0
    intervalRemaining = math.random(30, 90)
    if previous then
        PlayMusic("Interface\\AddOns\\" .. addonName .. "\\Audio\\silence.mp3")
    end
    UpdateUI()
end

local function Refresh(force)
    if not PWZoneMusicSettings or not PWZoneMusicSettings.enabled or paused or not LibraryReady() then
        Stop()
        return
    end
    local mapID = MapID()
    if manualTrack then
        if force or manualTrack ~= activeTrack then Play(manualTrack) else UpdateUI() end
    else
        local poolKey = TrackForMap(mapID)
        if force or poolKey ~= activePoolKey or (not activeTrack and intervalRemaining <= 0) then
            activePoolKey = poolKey
            Play(PickAutoTrack(poolKey))
        else
            UpdateUI()
        end
    end
end

local function SelectRelative(direction)
    if not LibraryReady() then Say("Install this library's music files first.") return end
    local order = Library().order
    if not order or #order == 0 then return end
    local current = manualTrack or activeTrack or TrackForMap(MapID())
    local target
    if PWZoneMusicSettings.shuffle and direction < 0 and #history > 0 then
        target = table.remove(history)
    elseif PWZoneMusicSettings.shuffle and direction > 0 and #order > 1 then
        local index = 1
        for i, key in ipairs(order) do
            if key == current then index = i break end
        end
        local offset = math.random(#order - 1)
        target = order[((index - 1 + offset) % #order) + 1]
        history[#history + 1] = current
    else
        local index = 1
        for i, key in ipairs(order) do
            if key == current then index = i break end
        end
        target = order[((index - 1 + direction) % #order) + 1]
    end
    manualTrack = target
    PWZoneMusicSettings.enabled = true
    paused = false
    Play(target)
end

local function SelectAuto()
    manualTrack = nil
    history = {}
    PWZoneMusicSettings.enabled = LibraryReady()
    paused = false
    Refresh(true)
end

local function SetPower(enabled)
    if enabled and not LibraryReady() then
        Say("Install this library's music files first.")
        enabled = false
    end
    PWZoneMusicSettings.enabled = enabled
    paused = false
    if enabled then Refresh(true) else Stop() end
end

local function TogglePlayback()
    if PWZoneMusicSettings.enabled and not paused then
        paused = true
        Stop()
    else
        if not LibraryReady() then Say("Install this library's music files first.") return end
        PWZoneMusicSettings.enabled = true
        paused = false
        Refresh(true)
    end
end

local function SelectTrack(key)
    if not LibraryReady() then Say("Install this library's music files first.") return end
    if not Library().tracks[key] then return end
    manualTrack = key
    history = {}
    PWZoneMusicSettings.enabled = true
    paused = false
    Play(key)
end

local function SetLibrary(id)
    if not libraries[id] or PWZoneMusicSettings.library == id then return end
    Stop()
    PWZoneMusicSettings.library = id
    manualTrack = nil
    activePoolKey = nil
    autoRecent = {}
    autoCursor = {}
    history = {}
    paused = false
    trackPage = 1
    if not LibraryReady() then PWZoneMusicSettings.enabled = false end
    if PWZoneMusicSettings.enabled then Refresh(true) else UpdateUI() end
end

local function ToggleRepeat()
    PWZoneMusicSettings.repeatOne = not PWZoneMusicSettings.repeatOne
    UpdateUI()
end

local function ToggleShuffle()
    PWZoneMusicSettings.shuffle = not PWZoneMusicSettings.shuffle
    history = {}
    UpdateUI()
end

local function SetMiniBar(enabled)
    PWZoneMusicSettings.miniBar = enabled
    if miniBar then
        if enabled then miniBar:Show() else miniBar:Hide() end
    end
    UpdateUI()
end

local function MakeButton(parent, caption, x, y, width, action, name)
    local button = CreateFrame("Button", name, parent)
    button:SetSize(width, 27)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.14, 0.18, 0.24, 0.96)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.label:SetAllPoints()
    button.label:SetText(caption)
    button:SetScript("OnClick", action)
    button:SetScript("OnEnter", function()
        background:SetColorTexture(0.23, 0.31, 0.39, 0.96)
    end)
    button:SetScript("OnLeave", function()
        background:SetColorTexture(0.14, 0.18, 0.24, 0.96)
    end)
    return button
end

local function MakePanelIcon(parent, name, index, x, hint, action)
    local button = CreateFrame("Button", "PWZMPanel" .. name, parent)
    button:SetSize(42, 42)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -149)
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.08, 0.15, 0.18, 0.86)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(30, 30)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\ControlIcons.tga")
    icon:SetTexCoord(index / 8, (index + 1) / 8, 0, 1)
    button.icon = icon
    button:SetScript("OnClick", action)
    button:SetScript("OnEnter", function(self)
        background:SetColorTexture(0.18, 0.29, 0.32, 0.96)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(hint)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        background:SetColorTexture(0.08, 0.15, 0.18, 0.86)
        if GameTooltip then GameTooltip:Hide() end
    end)
    return button
end

local function MakeLibraryTab(parent, id, caption, iconIndex, x)
    local button = CreateFrame("Button", "PWZMLibrary" .. id, parent)
    button:SetSize(208, 34)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -44)
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    button.background = background
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("LEFT", button, "LEFT", 13, 0)
    icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\SourceIcons.tga")
    icon:SetTexCoord(iconIndex / 2, (iconIndex + 1) / 2, 0, 1)
    button.icon = icon
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", button, "LEFT", 45, 0)
    label:SetText(caption)
    button.label = label
    button:SetScript("OnClick", function() SetLibrary(id) end)
    return button
end

local function MakeTrackRow(parent, index)
    local column = math.floor((index - 1) / 8)
    local line = (index - 1) % 8
    local row = CreateFrame("Button", "PWZMTrack" .. index, parent)
    row:SetSize(205, 22)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 13 + column * 214, -(226 + line * 23))
    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.07, 0.12, 0.15, 0.66)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", row, "LEFT", 8, 0)
    label:SetWidth(190)
    label:SetJustifyH("LEFT")
    row.label = label
    row:SetScript("OnClick", function(self) SelectTrack(self.key) end)
    row:SetScript("OnEnter", function(self)
        background:SetColorTexture(0.16, 0.25, 0.28, 0.9)
        if GameTooltip and self.key then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(Library().tracks[self.key].title or self.key)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function()
        background:SetColorTexture(0.07, 0.12, 0.15, 0.66)
        if GameTooltip then GameTooltip:Hide() end
    end)
    return row
end

local function MakeMiniButton(parent, iconIndex, x, hint, action)
    local button = CreateFrame("Button", "PWZMMini" .. iconIndex, parent)
    button:SetSize(24, 24)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -5)
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.08, 0.15, 0.18, 0.45)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\ControlIcons.tga")
    icon:SetTexCoord(iconIndex / 8, (iconIndex + 1) / 8, 0, 1)
    button.icon = icon
    button:SetScript("OnClick", action)
    button:SetScript("OnEnter", function(self)
        background:SetColorTexture(0.14, 0.26, 0.29, 0.78)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(hint)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        background:SetColorTexture(0.08, 0.15, 0.18, 0.45)
        if GameTooltip then GameTooltip:Hide() end
    end)
    return button
end

local function CreateMiniBar()
    miniBar = CreateFrame("Frame", "PWZoneMusicMiniBar", UIParent)
    miniBar:SetSize(264, 34)
    miniBar:SetFrameStrata("HIGH")
    miniBar:SetClampedToScreen(true)
    miniBar:SetMovable(true)
    miniBar:EnableMouse(true)
    miniBar:RegisterForDrag("LeftButton")
    if PWZoneMusicSettings.miniX and PWZoneMusicSettings.miniY then
        miniBar:SetPoint("CENTER", UIParent, "CENTER", PWZoneMusicSettings.miniX, PWZoneMusicSettings.miniY)
    else
        miniBar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 280, -18)
    end
    miniBar:SetScript("OnDragStart", function(self) self:StartMoving() end)
    miniBar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local centerX, centerY = UIParent:GetCenter()
        PWZoneMusicSettings.miniX = x - centerX
        PWZoneMusicSettings.miniY = y - centerY
    end)
    miniBar:SetScript("OnMouseUp", function(self, button)
        if button ~= "RightButton" then return end
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 280, -18)
        PWZoneMusicSettings.miniX = nil
        PWZoneMusicSettings.miniY = nil
    end)
    miniBar:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Drag to move; right-click to reset position")
            GameTooltip:Show()
        end
    end)
    miniBar:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    local background = miniBar:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.025, 0.07, 0.08, 0.53)
    for _, x in ipairs({5, 9}) do
        local grip = miniBar:CreateTexture(nil, "ARTWORK")
        grip:SetSize(1, 17)
        grip:SetPoint("TOPLEFT", miniBar, "TOPLEFT", x, -8)
        grip:SetColorTexture(0.65, 0.68, 0.6, 0.6)
    end
    miniButtons = {
        power = MakeMiniButton(miniBar, 0, 16, "Power on/off", function() SetPower(not PWZoneMusicSettings.enabled) end),
        previous = MakeMiniButton(miniBar, 1, 44, "Previous track", function() SelectRelative(-1) end),
        play = MakeMiniButton(miniBar, 2, 72, "Play / pause", TogglePlayback),
        next = MakeMiniButton(miniBar, 4, 100, "Next track", function() SelectRelative(1) end),
        repeatOne = MakeMiniButton(miniBar, 5, 128, "Repeat current track", ToggleRepeat),
        shuffle = MakeMiniButton(miniBar, 6, 156, "Shuffle tracks", ToggleShuffle),
        auto = MakeMiniButton(miniBar, 7, 184, "Auto zone selection", SelectAuto),
    }
    miniTimeText = miniBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    miniTimeText:SetSize(44, 24)
    miniTimeText:SetPoint("TOPRIGHT", miniBar, "TOPRIGHT", -5, -5)
    miniTimeText:SetJustifyH("RIGHT")
    miniTimeText:SetTextColor(0.85, 0.94, 0.94)
    miniBar.timeText = miniTimeText
    lastTimeText = nil
    UpdateTime()
    if not PWZoneMusicSettings.miniBar then miniBar:Hide() end
end

local function PlaceMinimapButton()
    if not minimapButton or not Minimap then return end
    local angle = PWZoneMusicSettings.minimapAngle or 3.9269908
    local radius = (Minimap:GetWidth() or 140) / 2 + 8
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function CursorAngle(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 then return math.atan(y / x) + math.pi end
    return y >= 0 and math.pi / 2 or -math.pi / 2
end

local function MoveMinimapButton()
    local x, y = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local centerX, centerY = Minimap:GetCenter()
    PWZoneMusicSettings.minimapAngle = CursorAngle(y / scale - centerY, x / scale - centerX)
    PlaceMinimapButton()
end

local function CreateUI()
    if panel or not Minimap then return end
    panel = CreateFrame("Frame", "PWZoneMusicPanel", UIParent)
    panel:SetSize(450, 455)
    panel:SetFrameStrata("HIGH")
    panel:SetClampedToScreen(true)
    panel:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -10)
    local background = panel:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.025, 0.04, 0.06, 0.96)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -13)
    title:SetText("WORLD MUSIC PLAYER")
    miniToggleButton = MakeButton(panel, "Mini bar", 307, 8, 101, function()
        SetMiniBar(not PWZoneMusicSettings.miniBar)
    end)
    libraryTabs = {
        pwi = MakeLibraryTab(panel, "pwi", "PERFECT WORLD", 0, 13),
        morrowind = MakeLibraryTab(panel, "morrowind", "MORROWIND", 1, 229),
    }
    local card = panel:CreateTexture(nil, "BACKGROUND")
    card:SetPoint("TOPLEFT", panel, "TOPLEFT", 13, -88)
    card:SetSize(424, 49)
    card:SetColorTexture(0.06, 0.10, 0.13, 0.96)
    local playingLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playingLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 23, -95)
    playingLabel:SetText("NOW PLAYING")
    trackText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    trackText:SetPoint("TOPLEFT", panel, "TOPLEFT", 23, -114)
    trackText:SetWidth(225)
    trackText:SetJustifyH("LEFT")
    statusText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -23, -111)
    panelButtons = {
        power = MakePanelIcon(panel, "Power", 0, 13, "Power on/off", function() SetPower(not PWZoneMusicSettings.enabled) end),
        previous = MakePanelIcon(panel, "Previous", 1, 75, "Previous track", function() SelectRelative(-1) end),
        play = MakePanelIcon(panel, "Play", 2, 137, "Play / pause", TogglePlayback),
        next = MakePanelIcon(panel, "Next", 4, 199, "Next track", function() SelectRelative(1) end),
        repeatOne = MakePanelIcon(panel, "Repeat", 5, 261, "Repeat current track", ToggleRepeat),
        shuffle = MakePanelIcon(panel, "Shuffle", 6, 323, "Shuffle within current library", ToggleShuffle),
        auto = MakePanelIcon(panel, "Auto", 7, 385, "Auto zone selection", SelectAuto),
    }
    libraryNote = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    libraryNote:SetPoint("TOPLEFT", panel, "TOPLEFT", 15, -204)
    trackRows = {}
    for index = 1, 16 do trackRows[index] = MakeTrackRow(panel, index) end
    MakeButton(panel, "<", 13, 420, 27, function()
        if trackPage > 1 then trackPage = trackPage - 1 UpdateUI() end
    end, "PWZMPanelPagePrevious")
    pageText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pageText:SetPoint("TOPLEFT", panel, "TOPLEFT", 45, -426)
    MakeButton(panel, ">", 92, 420, 27, function()
        if trackPage * 16 < #Library().order then trackPage = trackPage + 1 UpdateUI() end
    end, "PWZMPanelPageNext")
    MakeButton(panel, "X", 419, 6, 23, function() panel:Hide() end)
    panel:Hide()

    minimapButton = CreateFrame("Button", "PWZoneMusicMinimapButton", Minimap)
    minimapButton:SetSize(30, 30)
    minimapButton:SetFrameStrata("HIGH")
    minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    minimapButton:RegisterForDrag("LeftButton")
    local icon = minimapButton:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(minimapButton)
    icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\MusicIcon.tga")
    minimapButton.icon = icon
    minimapButton:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            SetPower(not PWZoneMusicSettings.enabled)
        elseif mouseButton == "MiddleButton" then
            SetMiniBar(not PWZoneMusicSettings.miniBar)
        elseif panel:IsShown() then
            panel:Hide()
        else
            panel:Show()
        end
    end)
    minimapButton:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("WoW Zone Music Player")
        GameTooltip:AddLine("Left click: controls", 1, 1, 1)
        GameTooltip:AddLine("Right click: power on/off", 1, 1, 1)
        GameTooltip:AddLine("Middle click: mini bar", 1, 1, 1)
        GameTooltip:AddLine("Drag: move around minimap", 1, 1, 1)
        GameTooltip:Show()
    end)
    minimapButton:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    minimapButton:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", MoveMinimapButton)
    end)
    minimapButton:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        MoveMinimapButton()
    end)
    CreateMiniBar()
    PlaceMinimapButton()
    UpdateUI()
end

local function ScheduleRefresh(delay)
    generation = generation + 1
    local token = generation
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, function()
            if token == generation then Refresh(false) end
        end)
    else
        Refresh(false)
    end
end

events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("ZONE_CHANGED")
events:RegisterEvent("ZONE_CHANGED_INDOORS")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
        if PWZoneMusicSettings == nil then PWZoneMusicSettings = { enabled = false } end
        if PWZoneMusicSettings.library ~= "morrowind" then PWZoneMusicSettings.library = "pwi" end
        if PWZoneMusicSettings.ambientVersion ~= 1 then
            PWZoneMusicSettings.repeatOne = false
            PWZoneMusicSettings.ambientVersion = 1
        end
        if PWZoneMusicSettings.shuffle == nil then PWZoneMusicSettings.shuffle = false end
        if PWZoneMusicSettings.miniBar == nil then PWZoneMusicSettings.miniBar = false end
        if PWZoneMusicSettings.miniPositionVersion ~= 2 then
            PWZoneMusicSettings.miniX = nil
            PWZoneMusicSettings.miniY = nil
            PWZoneMusicSettings.miniPositionVersion = 2
        end
    end
    CreateUI()
    ScheduleRefresh(0.5)
end)

events:SetScript("OnUpdate", function(_, delta)
    if intervalRemaining > 0 then
        intervalRemaining = math.max(0, intervalRemaining - delta)
        if intervalRemaining <= 0 then Refresh(false) else UpdateTime() end
        return
    end
    if not activeTrack then return end
    local track = Library().tracks[activeTrack]
    if not track then Stop() return end
    local duration = TrackDuration(activeTrack)
    elapsed = elapsed + delta
    if elapsed >= duration then
        if PWZoneMusicSettings.repeatOne then
            Play(activeTrack)
        elseif manualTrack then
            SelectRelative(1)
        else
            BeginInterval()
        end
    else
        UpdateTime()
    end
end)

SLASH_PWZONEMUSIC1 = "/pwm"
SlashCmdList.PWZONEMUSIC = function(input)
    local command = (input or ""):match("^%s*(%S*)")
    command = command and command:lower() or ""
    if command == "on" then
        SetPower(true)
    elseif command == "off" then
        SetPower(false)
    elseif command == "pause" then
        TogglePlayback()
    elseif command == "next" then
        SelectRelative(1)
    elseif command == "prev" then
        SelectRelative(-1)
    elseif command == "auto" then
        SelectAuto()
    elseif command == "repeat" then
        ToggleRepeat()
    elseif command == "shuffle" then
        ToggleShuffle()
    elseif command == "mini" then
        SetMiniBar(not PWZoneMusicSettings.miniBar)
    elseif command == "show" then
        if panel then panel:Show() end
    elseif command == "hide" then
        if panel then panel:Hide() end
    elseif command == "map" then
        Say("Map ID: " .. tostring(MapID()))
    elseif command == "pwi" or command == "morrowind" then
        SetLibrary(command)
    else
        Say("/pwm on, off, pause, prev, next, auto, repeat, shuffle, mini, pwi, morrowind, show, hide, map")
    end
end
