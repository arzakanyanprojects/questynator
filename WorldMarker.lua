-- In-world pin over the current route stop, in three modes (after the WaypointUI addon):
--   far:   a dashed beam rising from the spot to a round badge (! pickup, ? turn-in, dot for an
--          objective), the quest name above it, distance and time under it; the dashes march upward
--   near:  under 100 yd a card floats over the target with the quest, what to do and the objectives
--   orbit: when the spot is off screen the badge circles the screen centre and points toward it
-- The game draws a navigation frame on screen at the super-tracked map waypoint (C_Navigation). We put
-- the route stop there as the map waypoint and hang our frames on it. Clients without C_Navigation
-- keep the compass only.
local _, ns = ...
local L = ns.L
local MEDIA = "Interface\\AddOns\\Questynator\\Media\\"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local TEAL, GOLD, GREEN = { 0.31, 0.82, 0.77 }, { 1, 0.83, 0.3 }, { 0.37, 0.83, 0.54 }
local RUN_SPEED = 7            -- yards a second on foot; used until you start moving
local ARRIVE = 8               -- yards: close enough to call it "here"
local NEAR_IN, NEAR_OUT = 95, 110 -- the card takes over under NEAR_IN yards and gives way above NEAR_OUT
local FAINT_FROM = 25          -- from here in, the card fades to half so the NPC or object stays visible
local EDGE = 0.1               -- off screen once the spot is this share of the screen from an edge
local HOLD = 0.35              -- a new mode must hold this long before we switch (no flicker)
local CROSSFADE = 0.175
local BEAM_H = 120             -- far mode: the badge sits this far above the spot
local DASH, GAP = 6, 4         -- the beam's dashes
local marker, placed, ours     -- our frame, the stop we put on the map, the waypoint we set
local Source                   -- what the pin shows: "quest", "pin" or "route" (below)

-- the game hides some numbers from addons (in combat, instances); those can't be compared, so treat them as missing
local function Readable(v)
    if v == nil or (issecretvalue and issecretvalue(v)) then return nil end
    return v
end

local function Supported()
    return C_Navigation and C_Navigation.GetFrame and C_Map and C_Map.SetUserWaypoint
        and UiMapPoint and UiMapPoint.CreateFromCoordinates and C_SuperTrack
end

local function Enabled()
    local db = ns.DB and ns.DB()
    return db and db.worldMarker ~= false
end

-- the player has picked a quest in the tracker: the game guides to that, and we step aside
local function QuestSelected()
    local id = C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID()
    return id and id ~= 0
end

local function SameSpot(a, b)
    return a and b and a.uiMap == b.uiMap and math.abs(a.x - b.x) < 0.01 and math.abs(a.y - b.y) < 0.01
end

-- Put the stop on the map as the waypoint and track it, unless the player set their own pin.
local function Place(target)
    local uiMap = target.uiMap or ns.UiMapForArea(target.area)
    if not uiMap then return false end
    if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(uiMap) then return false end
    local current = C_Map.GetUserWaypoint and C_Map.GetUserWaypoint()
    if current and ours and not SameSpot({ uiMap = current.uiMapID, x = current.position.x, y = current.position.y }, ours) then
        return false                                  -- a pin the player placed: leave it alone
    end
    -- mark it ours first: setting it fires USER_WAYPOINT_UPDATED right away, and whoever handles that
    -- must already see our pin, not a stranger's
    local before = ours
    ours = { uiMap = uiMap, x = target.x / 100, y = target.y / 100 }
    local ok = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(uiMap, target.x / 100, target.y / 100))
    if not ok then ours = before; return false end
    if not QuestSelected() and C_SuperTrack.SetSuperTrackedUserWaypoint then
        pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
    end
    return true
end

-- Our pin is still the map waypoint. The player may remove it or pin somewhere else; the game's
-- navigation frame then stops moving or follows their pin, so the marker must not stay on it.
local function OurPinUp()
    local current = ours and C_Map.GetUserWaypoint and C_Map.GetUserWaypoint()
    return current and SameSpot({ uiMap = current.uiMapID, x = current.position.x, y = current.position.y }, ours) or false
end

-- The waypoint is only there so the game gives us an on-screen spot for the stop; its pin on the
-- world map stays invisible and can't be clicked. A pin the player places is shown as usual.
local MAP_PIN = "WaypointLocationPinTemplate"
local function SyncMapPin()
    local map = WorldMapFrame
    if not (map and map.EnumeratePinsByTemplate) then return end
    local hide = OurPinUp()
    for pin in map:EnumeratePinsByTemplate(MAP_PIN) do
        pin:SetAlpha(hide and 0 or 1)
        if pin.EnableMouse then pin:EnableMouse(not hide) end
    end
end
ns.SyncWorldPinMapPin = SyncMapPin

-- The map re-creates its pins when it opens or changes zone, and when the waypoint moves: hide ours
-- again each time. Set up when the pin is first built (after login).
local function WatchMap(owner)
    if WorldMapFrame and hooksecurefunc then
        if WorldMapFrame.HookScript then WorldMapFrame:HookScript("OnShow", SyncMapPin) end
        if WorldMapFrame.OnMapChanged then hooksecurefunc(WorldMapFrame, "OnMapChanged", SyncMapPin) end
    end
    if owner.RegisterEvent then pcall(owner.RegisterEvent, owner, "USER_WAYPOINT_UPDATED") end
    owner:SetScript("OnEvent", function()
        -- after the map's own refresh for the new waypoint
        if C_Timer and C_Timer.After then C_Timer.After(0, SyncMapPin) else SyncMapPin() end
    end)
end

local function Clear()
    if ours and C_Map.GetUserWaypoint and C_Map.ClearUserWaypoint then
        local current = C_Map.GetUserWaypoint()
        if current and SameSpot({ uiMap = current.uiMapID, x = current.position.x, y = current.position.y }, ours) then
            pcall(C_Map.ClearUserWaypoint)
        end
    end
    ours, placed = nil, nil
    SyncMapPin()
end

local function ShowGameIcon(on)
    if SuperTrackedFrame and SuperTrackedFrame.SetAlpha then SuperTrackedFrame:SetAlpha(on and 1 or 0) end
end

---------------------------------------------------------------------------
-- easing and screen geometry
---------------------------------------------------------------------------
local function Clamp01(x) return x < 0 and 0 or (x > 1 and 1 or x) end
local function ExpoIn(t) return t <= 0 and 0 or (t >= 1 and 1 or 2 ^ (10 * t - 10)) end
local function ExpoInOut(t)
    if t <= 0 then return 0 elseif t >= 1 then return 1 end
    if t < 0.5 then return 2 ^ (20 * t - 10) / 2 end
    return (2 - 2 ^ (-20 * t + 10)) / 2
end

-- Where the navigation frame is, relative to the middle of the screen, in UIParent units.
-- (Call GetCenter on its own line: "a and f()" would keep only the x.)
local function NavOffset(nav)
    local nx, ny, cx, cy
    if nav and nav.GetCenter then nx, ny = nav:GetCenter() end
    if UIParent.GetCenter then cx, cy = UIParent:GetCenter() end
    if not (nx and ny and cx and cy) then return nil end
    local navScale = (nav.GetEffectiveScale and nav:GetEffectiveScale()) or 1
    local uiScale = (UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    local k = navScale / uiScale
    return nx * k - cx, ny * k - cy
end

-- The spot is behind you or at the screen edge: the game pins its frame there.
local function Offscreen(nav)
    if C_Navigation.WasClampedToScreen and Readable(C_Navigation.WasClampedToScreen()) then return true end
    local x, y = NavOffset(nav)
    if not x then return false end
    local w = tonumber(UIParent.GetWidth and UIParent:GetWidth()) or 0
    local h = tonumber(UIParent.GetHeight and UIParent:GetHeight()) or 0
    if w <= 0 or h <= 0 then return false end
    return math.min((w / 2 - math.abs(x)) / w, (h / 2 - math.abs(y)) / h) < EDGE
end

-- The oval the off-screen badge rides on: wider when the camera is close (WaypointUI's numbers).
local function OrbitRadii()
    local zoom = GetCameraZoom and Readable(GetCameraZoom()) or 39
    zoom = math.max(12, tonumber(zoom) or 39)
    return math.min(200 * 35 / zoom, 500), math.min(100 * 35 / zoom, 500)
end

---------------------------------------------------------------------------
-- frames
---------------------------------------------------------------------------
local KIND = {
    pickup = { glyph = "!", label = "Pickup" },
    turnin = { glyph = "?", label = "Turn in" },
    objective = { label = "Objective" },
    pin = { label = "Map pin" },
}

local function Clock(seconds)
    seconds = math.floor(seconds + 0.5)
    if seconds >= 3600 then return string.format("%d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60) end
    return string.format("%d:%02d", seconds / 60, seconds % 60)
end

local function Shadow(fs)
    if fs.SetShadowOffset then fs:SetShadowOffset(1, -1) end
    if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 0.85) end
    return fs
end

-- the round badge: a dark disc in a coloured ring with a gold ! or ? (a dot for objectives)
local function Badge(parent, size)
    local UI = ns.UI
    local b = CreateFrame("Frame", nil, parent)
    b:SetSize(size, size)
    b.disc = b:CreateTexture(nil, "ARTWORK")
    b.disc:SetTexture(MEDIA .. "Circle")
    b.disc:SetSize(size - 4, size - 4)
    b.disc:SetPoint("CENTER")
    b.disc:SetVertexColor(0.06, 0.07, 0.09, 0.96)
    b.ring = b:CreateTexture(nil, "ARTWORK", nil, 1)
    b.ring:SetTexture(MEDIA .. "CompassRing")
    b.ring:SetSize(size, size)
    b.ring:SetPoint("CENTER")
    b.glyph = Shadow(UI.Text(b, math.floor(size * 0.53 + 0.5), "text", "OVERLAY", "bold"))
    b.glyph:SetPoint("CENTER", 0, 1)
    b.glyph:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    b.dot = b:CreateTexture(nil, "OVERLAY")
    b.dot:SetTexture(MEDIA .. "Circle")
    b.dot:SetSize(math.floor(size * 0.3), math.floor(size * 0.3))
    b.dot:SetPoint("CENTER")
    return b
end

local function SetBadge(b, kind)
    b.glyph:SetText(kind.glyph or "")
    b.dot:SetShown(kind.glyph == nil)
end

local function BuildFar(f)
    local UI = ns.UI
    local far = CreateFrame("Frame", nil, f)
    far:SetSize(60, BEAM_H)
    far.spot = CreateFrame("Frame", nil, far)       -- the badge scales around this point
    far.spot:SetSize(1, 1)
    far.spot:SetPoint("CENTER", far, "TOP", 0, -17)
    far.badge = Badge(far, 34)
    far.badge:SetPoint("CENTER", far.spot, "CENTER")
    far.title = Shadow(UI.Text(far, 11, "text", "OVERLAY", "medium"))
    far.title:SetPoint("BOTTOM", far.spot, "CENTER", 0, 22)
    far.title:SetWordWrap(false)
    far.title:SetTextColor(0.79, 0.82, 0.85)
    far.dist = Shadow(UI.Text(far, 12, "text", "OVERLAY", "bold"))
    far.dist:SetPoint("TOP", far.spot, "CENTER", 0, -20)
    far.eta = Shadow(UI.Text(far, 10, "text", "OVERLAY", "medium"))
    far.eta:SetPoint("TOP", far.dist, "BOTTOM", 0, -1)
    far.eta:SetTextColor(0.6, 0.64, 0.68)
    -- the beam: dashes in a clipped column from the spot up to under the time; they scroll upward
    far.beamFull = BEAM_H - 34 - 34
    far.beam = CreateFrame("Frame", nil, far)
    far.beam:SetSize(2, far.beamFull)
    far.beam:SetPoint("BOTTOM", far, "BOTTOM", 0, 0)
    if far.beam.SetClipsChildren then far.beam:SetClipsChildren(true) end
    far.dashes = {}
    for i = 1, math.ceil(far.beamFull / (DASH + GAP)) + 1 do
        local d = far.beam:CreateTexture(nil, "ARTWORK")
        d:SetTexture(WHITE)
        d:SetSize(2, DASH)
        far.dashes[i] = d
    end
    far.march = 0
    return far
end

local function BuildNear(f)
    local UI = ns.UI
    local card = CreateFrame("Frame", nil, f)
    card:SetSize(200, 90)
    UI.Flat(card, { 0.06, 0.07, 0.09, 0.92 }, { 0.17, 0.29, 0.3, 1 })
    card.badge = Badge(card, 20)
    card.badge:SetPoint("TOPLEFT", 10, -8)
    card.title = UI.Text(card, 12, "text", nil, "bold")
    card.title:SetPoint("LEFT", card.badge, "RIGHT", 6, 0)
    card.title:SetWordWrap(false)
    card.title:SetJustifyH("LEFT")
    card.sub = UI.Text(card, 10, "muted")
    card.sub:SetPoint("TOPLEFT", 10, -32)
    card.sub:SetWordWrap(false)
    card.sub:SetJustifyH("LEFT")
    card.rule = card:CreateTexture(nil, "ARTWORK")
    card.rule:SetTexture(WHITE)
    card.rule:SetHeight(1)
    card.rule:SetPoint("TOPLEFT", 10, -48)
    card.rule:SetPoint("TOPRIGHT", -10, -48)
    card.rule:SetVertexColor(0.17, 0.29, 0.3, 1)
    card.lines = {}
    for i = 1, 4 do                                  -- three objectives and "+N more here"
        local fs = UI.Text(card, 10, "text")
        fs:SetPoint("TOPLEFT", 10, -54 - (i - 1) * 14)
        fs:SetWordWrap(false)
        fs:SetJustifyH("LEFT")
        card.lines[i] = fs
    end
    card.dist = UI.Text(card, 10, "muted")
    card.dist:SetPoint("BOTTOM", 0, 7)
    -- a small arrow under the card, bobbing toward the target
    card.chev = card:CreateTexture(nil, "OVERLAY")
    card.chev:SetTexture(MEDIA .. "NavArrow")
    card.chev:SetSize(14, 14)
    if card.chev.SetRotation then card.chev:SetRotation(math.pi) end
    card.slide = 0
    return card
end

local function BuildOrbit(f)
    local UI = ns.UI
    local o = CreateFrame("Frame", nil, f)
    o:SetSize(34, 34)
    o.badge = Badge(o, 30)
    o.badge:SetPoint("CENTER")
    o.arrow = o:CreateTexture(nil, "OVERLAY", nil, 2)
    o.arrow:SetTexture(MEDIA .. "NavArrow")
    o.arrow:SetSize(14, 14)
    o.dist = Shadow(UI.Text(o, 12, "text", "OVERLAY", "bold"))
    o.dist:SetPoint("TOP", o, "BOTTOM", 0, -2)
    o.x, o.y, o.angle = nil, nil, nil
    return o
end

-- teal on the way, green when you're there
local function Paint(color)
    local m = marker
    if m.painted == color then return end
    m.painted = color
    local r, g, b = color[1], color[2], color[3]
    for _, badge in ipairs({ m.far.badge, m.near.badge, m.orbit.badge }) do
        badge.ring:SetVertexColor(r, g, b, 1)
        badge.dot:SetVertexColor(r, g, b, 1)
    end
    for _, d in ipairs(m.far.dashes) do d:SetVertexColor(r, g, b, 1) end
    m.near.chev:SetVertexColor(r, g, b, 1)
    m.orbit.arrow:SetVertexColor(r, g, b, 1)
    ns.UI.SetEdge(m.near, { r * 0.55, g * 0.55, b * 0.55, 1 })
end

---------------------------------------------------------------------------
-- animation: runs every frame while the pin is up
---------------------------------------------------------------------------
local function AnimateFar(far, now, dt)
    local intro = marker.introAt
    -- new stop: the badge drops in from 2.2x, then the beam unrolls upward
    local t = intro and Clamp01((now - intro) / 0.5) or 1
    far.badge:SetScale(2.2 + (1 - 2.2) * ExpoIn(t))
    local u = intro and ExpoIn(Clamp01((now - intro - 0.175) / 0.5)) or 1
    local h = math.max(1, far.beamFull * u)
    far.beam:SetHeight(h)
    -- dashes march upward, bright at the bottom and fading toward the badge
    local period = DASH + GAP
    far.march = (far.march + dt * 16) % period
    for i, d in ipairs(far.dashes) do
        local y = (i - 2) * period + far.march
        d:ClearAllPoints()
        d:SetPoint("BOTTOM", far.beam, "BOTTOM", 0, y)
        d:SetAlpha(0.95 - 0.7 * Clamp01(y / far.beamFull))
    end
end

local function AnimateNear(card, now)
    -- slides up into place when it appears, drops a little as it goes
    local s = card.slideTo or 0
    if card.slideAt then
        local t = Clamp01((now - card.slideAt) / card.slideFor)
        card.slide = card.slideFrom + (s - card.slideFrom) * ExpoInOut(t)
        if t >= 1 then card.slideAt = nil end
    end
    if marker.nav then
        card:ClearAllPoints()
        card:SetPoint("BOTTOM", marker.nav, "CENTER", 0, 18 + card.slide)
    end
    local bob = 0.5 - 0.5 * math.cos(2 * math.pi * (now % 1.2) / 1.2)
    card.chev:ClearAllPoints()
    card.chev:SetPoint("TOP", card, "BOTTOM", 0, -1 - 4 * bob)
end

local function AnimateOrbit(o)
    local x, y = NavOffset(marker.nav)
    if not x or (x == 0 and y == 0) then return end
    local a, b = OrbitRadii()
    local d = math.sqrt(a * a * y * y + b * b * x * x)
    if d == 0 then return end
    local k = a * b / d
    local tx, ty = x * k, y * k
    if not o.x then o.x, o.y = tx, ty else
        o.x, o.y = o.x + (tx - o.x) / 3, o.y + (ty - o.y) / 3          -- glide, don't jump
    end
    o:ClearAllPoints()
    o:SetPoint("CENTER", UIParent, "CENTER", o.x, o.y)
    local target = math.atan2(y, x)
    if not o.angle then o.angle = target else
        local diff = (target - o.angle + math.pi) % (2 * math.pi) - math.pi
        o.angle = math.abs(diff) > 0.01 and o.angle + diff / 2 or target
    end
    o.arrow:ClearAllPoints()
    o.arrow:SetPoint("CENTER", o, "CENTER", math.cos(o.angle) * 22, math.sin(o.angle) * 22)
    if o.arrow.SetRotation then o.arrow:SetRotation(o.angle - math.pi / 2) end
end

local function Animate(self, dt)
    local now = GetTime()
    if self.introAt then self:SetAlpha(Clamp01((now - self.introAt) / 1)) end
    for _, part in ipairs(self.parts) do
        local goal = part.fadeTo or 0
        local a = part.fade or 0
        if a ~= goal then
            local step = dt / CROSSFADE
            a = goal > a and math.min(goal, a + step) or math.max(goal, a - step)
            part.fade = a
        end
        part:SetAlpha(a * (part.dim or 1))
        if a <= 0 and goal <= 0 and part:IsShown() then part:Hide() end
    end
    if self.far:IsShown() then AnimateFar(self.far, now, dt) end
    if self.near:IsShown() then AnimateNear(self.near, now) end
    if self.orbit:IsShown() then AnimateOrbit(self.orbit) end
    if self.introAt and now - self.introAt > 1.2 then self.introAt = nil end
end

-- Switch to a mode: it fades in while the others fade out.
local function SetMode(mode, now, instant)
    local m = marker
    if m.mode == mode then return end
    local was = m.mode
    m.mode = mode
    for name, part in pairs({ far = m.far, near = m.near, orbit = m.orbit }) do
        if name == mode then
            if not part:IsShown() or instant then part.fade = instant and 1 or (part.fade or 0) end
            part.fadeTo = 1
            part:Show()
        else
            part.fadeTo = 0
            if instant then part.fade = 0; part:Hide() end
        end
    end
    if mode == "near" then
        m.near.slideFrom, m.near.slideTo, m.near.slideAt, m.near.slideFor = -57.5, 0, now, 1
        m.near.slide = -57.5
    elseif was == "near" then
        m.near.slideFrom, m.near.slideTo, m.near.slideAt, m.near.slideFor = m.near.slide or 0, -12.5, now, 0.25
    end
    if mode == "orbit" then m.orbit.x, m.orbit.angle = nil, nil end
end

local function Build()
    local f = CreateFrame("Frame", "QuestynatorWorldMarker", UIParent)
    f:SetSize(1, 1)
    f:SetPoint("CENTER")
    f:SetFrameStrata("BACKGROUND")
    f:EnableMouse(false)
    f:Hide()
    marker = f
    f.far, f.near, f.orbit = BuildFar(f), BuildNear(f), BuildOrbit(f)
    f.parts = { f.far, f.near, f.orbit }
    for _, part in ipairs(f.parts) do part.fade = 0; part:Hide() end
    WatchMap(f)
    local acc = 0
    f:SetScript("OnUpdate", function(self, dt)
        dt = dt or 0
        Animate(self, dt)
        acc = acc + dt
        if acc < 0.1 then return end
        acc = 0
        ns.WorldMarkerUpdate()
    end)
    return f
end

---------------------------------------------------------------------------
-- state: which mode, distance, time; refreshed 10 times a second
---------------------------------------------------------------------------
local function Hide()
    if marker:IsShown() then marker:Hide() end
    marker.mode, marker.pending = nil, nil
end

function ns.WorldMarkerUpdate()
    if not marker or not marker.summary then return end
    local now = GetTime()
    local nav = C_Navigation.GetFrame and C_Navigation.GetFrame()
    local source = Source()
    if source ~= marker.source then
        ns.WorldMarkerRefresh()                     -- picked a quest, or placed or removed a map pin
        return
    end
    if source == "route" and not OurPinUp() then
        -- our hidden waypoint was cleared: nothing for the game to guide to
        Hide()
        ShowGameIcon(true)
        return
    end
    ShowGameIcon(false)
    if not nav then
        -- the game rebuilds its navigation frame when the waypoint changes: wait it out
        marker.lostAt = marker.lostAt or now
        if now - marker.lostAt > 0.6 then Hide() end
        return
    end
    marker.lostAt = nil
    if marker.nav ~= nav then
        marker.nav = nav
        marker.far:ClearAllPoints()
        marker.far:SetPoint("BOTTOM", nav, "CENTER", 0, 0)
    end

    local yards = C_Navigation.GetDistance and Readable(C_Navigation.GetDistance())
    if (not yards or yards <= 0) and marker.summary.target then yards = ns.ArrowGeometry(marker.summary.target).yards end
    local here = yards and yards <= ARRIVE
    Paint(here and GREEN or TEAL)

    -- which mode, held a moment before switching so a brief flip doesn't flicker
    local want
    if Offscreen(nav) then want = "orbit"
    elseif yards and (yards < NEAR_IN or (marker.mode == "near" and yards < NEAR_OUT)) then want = "near"
    else want = "far" end
    local fresh = not marker:IsShown() or not marker.mode
    if fresh then
        marker.introAt = marker.newStop and now or nil
        marker.newStop = nil
        marker:SetAlpha(marker.introAt and 0 or 1)
        marker.pending = nil
        SetMode(want, now, true)
    elseif want ~= marker.mode then
        if marker.pending ~= want then marker.pending, marker.pendingAt = want, now end
        if now - marker.pendingAt >= HOLD then marker.pending = nil; SetMode(want, now) end
    else
        marker.pending = nil
    end

    local distText = yards and string.format(L["%d yd"], math.floor(yards + 0.5)) or ""
    -- far: distance, time, and smaller the farther it is
    local far = marker.far
    far.dist:SetText(distText)
    local speed = (GetUnitSpeed and Readable(GetUnitSpeed("player"))) or 0
    far.eta:SetText(yards and ("~" .. Clock(yards / (speed > 0.5 and speed or RUN_SPEED))) or "")
    local scale = yards and math.max(0.7, math.min(1.1, 0.25 * 2000 / math.max(yards, 1))) or 1
    far.scale = far.scale and (far.scale + (scale - far.scale) * 0.3) or scale
    far:SetScale(far.scale)
    -- near: the distance (or "You're here"), and fading so the target shows through
    local near = marker.near
    if here then
        near.dist:SetText(L["You're here"])
        near.dist:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
    else
        near.dist:SetText(distText)
        near.dist:SetTextColor(0.6, 0.64, 0.68)
    end
    near.dim = yards and (0.5 + 0.5 * Clamp01((yards - ARRIVE) / (FAINT_FROM - ARRIVE))) or 1
    -- off screen: the distance under the badge
    marker.orbit.dist:SetText(distText)
    marker:Show()
end

-- The quest picked in the tracker: the game guides its navigation frame there (the turn-in NPC once
-- it's ready), and our pin shows that quest on it instead of the route stop.
local function SelectedSummary()
    local id = QuestSelected() and C_SuperTrack.GetSuperTrackedQuestID()
    if not id then return nil end
    local t = ns.ArrowTarget and ns.ArrowTarget()
    if not (t and t.selectedQuest and t.questID == id) then t = nil end
    local ready = ns.IsReadyToTurnIn and ns.IsReadyToTurnIn(id)
    local lines = {}
    for _, o in ipairs((C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(id)) or {}) do
        if o.text and o.text ~= "" then lines[#lines + 1] = { text = o.text, done = o.finished and true or false } end
    end
    local title = (t and t.title) or (ns.titleCache and ns.titleCache[id])
        or (C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(id)) or ""
    local who = t and t.name and t.name ~= "" and t.name or nil
    return { kind = ready and "turnin" or "objective", title = title, who = who, more = 0, lines = lines,
             target = t, questID = id }
end

-- A map pin the player placed (not our hidden one): the game guides to it, and our pin shows it there.
local function TheirPin()
    local w = C_Map.GetUserWaypoint and C_Map.GetUserWaypoint()
    if not (w and w.position) then return nil end
    if ours and SameSpot({ uiMap = w.uiMapID, x = w.position.x, y = w.position.y }, ours) then return nil end
    return w
end

local function PinSummary(w)
    local info = C_Map.GetMapInfo and C_Map.GetMapInfo(w.uiMapID)
    return { kind = "pin", title = (info and info.name) or L["Map pin"], more = 0, lines = {},
             target = { uiMap = w.uiMapID, x = w.position.x * 100, y = w.position.y * 100 } }
end

-- what the pin shows: the quest picked in the tracker, else the player's own map pin, else the route stop
function Source()
    if QuestSelected() then return "quest" end
    if TheirPin() then return "pin" end
    return "route"
end

-- Called whenever the route may have changed, the tracker selection or map pin changes (and from the compass refresh).
local function RefreshNow()
    if not Supported() then return end
    local source = Source()
    local summary
    if Enabled() then
        if source == "quest" then summary = SelectedSummary()
        elseif source == "pin" then summary = PinSummary(TheirPin())
        else summary = ns.RouteStopSummary and ns.RouteStopSummary() end
    end
    if not summary or (source == "route" and not summary.target.x) then
        if marker then Hide(); marker.summary, marker.source = nil, nil end
        if placed then Clear() end
        ShowGameIcon(true)
        return
    end
    marker = marker or Build()
    local spot
    if source == "quest" then
        spot = { uiMap = "quest:" .. summary.questID, x = 0, y = 0 }
    elseif source == "pin" then
        spot = { uiMap = "pin:" .. tostring(summary.target.uiMap), x = summary.target.x, y = summary.target.y }
        -- the game only guides to a pin it tracks
        local st = C_SuperTrack
        if st.SetSuperTrackedUserWaypoint and not (st.IsSuperTrackingUserWaypoint and st.IsSuperTrackingUserWaypoint()) then
            pcall(st.SetSuperTrackedUserWaypoint, true)
        end
        marker.hadTheirs = true
    else
        -- the player's own pin is gone: the route stop goes back on the map
        if marker.hadTheirs then placed, marker.hadTheirs = nil, nil end
        -- the route stop goes on the map as a hidden waypoint so the game gives us its spot on screen
        spot = { uiMap = summary.target.uiMap, x = summary.target.x, y = summary.target.y }
        if not SameSpot(placed, spot) then
            if Place(summary.target) then placed = spot end
        end
    end
    marker.source = source
    SyncMapPin()
    if not SameSpot(marker.stop, spot) then
        marker.stop = spot
        marker.newStop = true                       -- play the drop-in when it next appears
        if marker:IsShown() then marker.mode = nil end
    end
    marker.summary = summary
    local kind = KIND[summary.kind]
    for _, badge in ipairs({ marker.far.badge, marker.near.badge, marker.orbit.badge }) do SetBadge(badge, kind) end
    marker.far.title:SetText(summary.title or "")

    -- the card: title, what to do and who, then the objectives
    local card = marker.near
    card.title:SetText(summary.title or "")
    card.sub:SetText(L[kind.label] .. (summary.who and ("  ·  " .. summary.who) or ""))
    local n = 0
    for _, line in ipairs(summary.lines or {}) do
        if n >= 3 then break end
        n = n + 1
        card.lines[n]:SetText(line.text or "")
        local c = line.done and GREEN or { 0.79, 0.82, 0.85 }
        card.lines[n]:SetTextColor(c[1], c[2], c[3])
        card.lines[n]:Show()
    end
    if (summary.more or 0) > 0 then
        n = n + 1
        card.lines[n]:SetText(string.format(L["+%d more here"], summary.more))
        card.lines[n]:SetTextColor(0.6, 0.64, 0.68)
        card.lines[n]:Show()
    end
    for i = n + 1, #card.lines do card.lines[i]:SetText(""); card.lines[i]:Hide() end
    card.rule:SetShown(n > 0)
    local width = math.max((tonumber(card.title:GetStringWidth()) or 0) + 26,tonumber(card.sub:GetStringWidth()) or 0, 150)
    for i = 1, n do width = math.max(width, tonumber(card.lines[i]:GetStringWidth()) or 0) end
    width = math.min(width, 260)
    card.title:SetWidth(width - 26)
    card.sub:SetWidth(width)
    for _, fs in ipairs(card.lines) do fs:SetWidth(width) end
    card:SetSize(width + 20, 48 + (n > 0 and (6 + n * 14) or 0) + 20)
    ShowGameIcon(false)
    ns.WorldMarkerUpdate()
end

-- Placing our waypoint fires events that lead back here; a refresh never starts inside another one.
local refreshing
function ns.WorldMarkerRefresh()
    if refreshing then return end
    refreshing = true
    local ok, err = pcall(RefreshNow)
    refreshing = false
    if not ok then error(err, 0) end
end

-- Turning the option off clears our waypoint and gives the game its own marker back.
function ns.WorldMarkerToggle()
    if Enabled() then ns.WorldMarkerRefresh() return end
    if marker then Hide(); marker.summary = nil end
    Clear()
    ShowGameIcon(true)
end

---------------------------------------------------------------------------
-- WaypointUI draws its own pin on the same navigation frame: keep one
---------------------------------------------------------------------------
local OTHER = "WaypointUI"

local function OtherLoaded()
    local f = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return f and f(OTHER) and true or false
end

-- both pins are on
function ns.WorldPinConflict()
    return Supported() and Enabled() and OtherLoaded() or false
end

-- Keep ours: turn WaypointUI off for this character and reload. Keep theirs: turn our pin off.
function ns.ChooseWorldPin(which)
    if which == "ours" then
        local disable = (C_AddOns and C_AddOns.DisableAddOn) or DisableAddOn
        if disable then pcall(disable, OTHER, UnitName and UnitName("player") or nil) end
        if ReloadUI then ReloadUI() end
    else
        ns.SetOption("worldMarker", false)
    end
end

local chooser
function ns.ShowWorldPinChoice()
    local UI = ns.UI
    if not chooser then
        chooser = UI.Window("QuestynatorPinChoice", 340, 132)
        chooser:SetPoint("CENTER", 0, 120)
        chooser:SetFrameStrata("DIALOG")
        chooser:SetClampedToScreen(true)
        if UISpecialFrames then tinsert(UISpecialFrames, "QuestynatorPinChoice") end
        UI.SetEdge(chooser, { 0.17, 0.29, 0.3, 1 })
        chooser.TitleText:SetText(L["Two world pins are on"])
        chooser.text = UI.Text(chooser, 11, "muted")
        chooser.text:SetPoint("TOPLEFT", 12, -34)
        chooser.text:SetWidth(316)
        chooser.text:SetJustifyH("LEFT")
        chooser.text:SetText(L["WaypointUI also draws a pin on your route stop. Keep one:"])
        chooser.ours = UI.Button(chooser, 150, 24, "outline")
        chooser.ours:SetPoint("TOPLEFT", 12, -66)
        chooser.ours:SetText(L["Use Questynator's"])
        chooser.ours:SetScript("OnClick", function() chooser:Hide(); ns.ChooseWorldPin("ours") end)
        chooser.theirs = UI.Button(chooser, 150, 24, "ghost")
        chooser.theirs:SetPoint("LEFT", chooser.ours, "RIGHT", 8, 0)
        chooser.theirs:SetText(L["Use WaypointUI's"])
        chooser.theirs:SetScript("OnClick", function() chooser:Hide(); ns.ChooseWorldPin("theirs") end)
        chooser.note = UI.Text(chooser, 10, "dim")
        chooser.note:SetPoint("TOPLEFT", 12, -100)
        chooser.note:SetText(L["Picking ours turns WaypointUI off and reloads."])
    end
    chooser:Show()
    return chooser
end

-- at login: ask while both are on (closing it asks again next time)
function ns.CheckWorldPinConflict()
    if ns.WorldPinConflict() then ns.ShowWorldPinChoice() end
end
