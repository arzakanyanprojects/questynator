-- In-world waypoint: our own marker over the current route stop.
-- The game draws a navigation frame on screen at the super-tracked map waypoint (C_Navigation),
-- pinned to the screen edge when the spot is behind you. We put the route stop there as the map
-- waypoint and hang our marker on that frame: a beam, a round icon (! pickup, ? turn-in, dot for an
-- objective) and a label with the quest, distance and time to get there. Off screen it shrinks to
-- the icon and distance. Clients without C_Navigation keep the compass only.
local _, ns = ...
local L = ns.L
local MEDIA = "Interface\\AddOns\\Questynator\\Media\\"
local TEAL, GOLD = { 0.31, 0.82, 0.77 }, { 1, 0.83, 0.3 }
local RUN_SPEED = 7          -- yards a second on foot; used until you start moving
local BEAM_H = 130           -- the icon floats this far above the spot
local marker, placed, ours   -- our frame, the stop we put on the map, the waypoint we set

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
    local ok = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(uiMap, target.x / 100, target.y / 100))
    if not ok then return false end
    ours = { uiMap = uiMap, x = target.x / 100, y = target.y / 100 }
    if not QuestSelected() and C_SuperTrack.SetSuperTrackedUserWaypoint then
        pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
    end
    return true
end

local function Clear()
    if ours and C_Map.GetUserWaypoint and C_Map.ClearUserWaypoint then
        local current = C_Map.GetUserWaypoint()
        if current and SameSpot({ uiMap = current.uiMapID, x = current.position.x, y = current.position.y }, ours) then
            pcall(C_Map.ClearUserWaypoint)
        end
    end
    ours, placed = nil, nil
end

local WHITE = "Interface\\Buttons\\WHITE8X8"
local GREEN = { 0.37, 0.83, 0.54 }
local ARRIVE = 8              -- yards: close enough to call it "here"
local NEAR, FAINT = 45, 0.15  -- from NEAR yards in, the marker fades down to FAINT so it never hides the target

-- vertical fade on a texture (newer clients take colour objects, older ones four numbers)
local function Fade(tex, r, g, b, bottom, top)
    tex:SetVertexColor(1, 1, 1, 1)
    if CreateColor and pcall(tex.SetGradient, tex, "VERTICAL", CreateColor(r, g, b, bottom), CreateColor(r, g, b, top)) then return end
    if tex.SetGradientAlpha then pcall(tex.SetGradientAlpha, tex, "VERTICAL", r, g, b, bottom, r, g, b, top) return end
    tex:SetVertexColor(r, g, b, (bottom + top) / 2)
end

local function Shadow(fs)
    if fs.SetShadowOffset then fs:SetShadowOffset(1, -1) end
    if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 0.85) end
    return fs
end

-- A looping animation on a texture. "REPEAT" grows and fades out (the ripple on the ground, which
-- starts faint and hidden under the solid ring, so the restart can't be seen); "BOUNCE" breathes
-- back and forth with no restart at all (the halo).
local function Pulse(tex, from, to, seconds, looping, alphaFrom, alphaTo)
    local group = tex:CreateAnimationGroup()
    group:SetLooping(looping or "REPEAT")
    local scale = group:CreateAnimation("Scale")
    if scale.SetScaleFrom then scale:SetScaleFrom(from, from); scale:SetScaleTo(to, to)
    elseif scale.SetFromScale then scale:SetFromScale(from, from); scale:SetToScale(to, to) end
    scale:SetDuration(seconds)
    local alpha = group:CreateAnimation("Alpha")
    alpha:SetFromAlpha(alphaFrom or 0.45)
    alpha:SetToAlpha(alphaTo or 0)
    alpha:SetDuration(seconds)
    group:Play()
    return group
end

local function Build()
    local UI = ns.UI
    -- A tall frame whose bottom is the spot on the ground: rings on the spot, a beam fading upward,
    -- the badge at the top with the distance under it and a label card beside it. At the screen
    -- edge only the badge, the distance and an arrow toward the spot remain.
    local f = CreateFrame("Frame", "QuestynatorWorldMarker", UIParent)
    f:SetSize(60, BEAM_H)
    f:SetFrameStrata("BACKGROUND")
    f:EnableMouse(false)
    f:SetAlpha(0)
    f:Hide()

    -- ground: a solid ring on the spot and a wider one that keeps pulsing outward
    f.foot = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    f.foot:SetTexture(MEDIA .. "CompassRing")
    f.foot:SetSize(44, 13)
    f.foot:SetPoint("CENTER", f, "BOTTOM", 0, 0)
    f.footPulse = f:CreateTexture(nil, "BACKGROUND")
    f.footPulse:SetTexture(MEDIA .. "CompassRing")
    f.footPulse:SetSize(44, 13)
    f.footPulse:SetPoint("CENTER", f.foot, "CENTER")
    f.footAnim = Pulse(f.footPulse, 1, 1.9, 2.2, "REPEAT", 0.45, 0)

    -- beam: a thin bright core in a soft glow, both fading toward the badge
    f.badge = CreateFrame("Frame", nil, f)
    f.badge:SetSize(34, 34)
    f.badge:SetPoint("TOP", f, "TOP", 0, 0)
    f.glow = f:CreateTexture(nil, "BACKGROUND", nil, 2)
    f.glow:SetTexture(WHITE)
    f.glow:SetWidth(12)
    f.glow:SetPoint("TOP", f.badge, "BOTTOM", 0, -32)    -- starts under the distance and time
    f.glow:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
    f.beam = f:CreateTexture(nil, "BACKGROUND", nil, 3)
    f.beam:SetTexture(WHITE)
    f.beam:SetWidth(2)
    f.beam:SetPoint("TOP", f.badge, "BOTTOM", 0, -32)    -- starts under the distance and time
    f.beam:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)

    -- badge: a soft halo, a dark disc with a coloured ring, the gold glyph (or a dot for objectives)
    f.halo = f.badge:CreateTexture(nil, "BACKGROUND")
    f.halo:SetTexture(MEDIA .. "Circle")
    f.halo:SetSize(46, 46)
    f.halo:SetPoint("CENTER")
    f.haloAnim = Pulse(f.halo, 1, 1.15, 1.6, "BOUNCE", 0.55, 1)
    f.disc = f.badge:CreateTexture(nil, "ARTWORK")
    f.disc:SetTexture(MEDIA .. "Circle")
    f.disc:SetSize(30, 30)
    f.disc:SetPoint("CENTER")
    f.disc:SetVertexColor(0.06, 0.07, 0.09, 0.96)
    f.ring = f.badge:CreateTexture(nil, "ARTWORK", nil, 1)
    f.ring:SetTexture(MEDIA .. "CompassRing")
    f.ring:SetSize(34, 34)
    f.ring:SetPoint("CENTER")
    f.glyph = Shadow(UI.Text(f.badge, 18, "text", "OVERLAY", "bold"))
    f.glyph:SetPoint("CENTER", 0, 1)
    f.glyph:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    f.dot = f.badge:CreateTexture(nil, "OVERLAY")
    f.dot:SetTexture(MEDIA .. "Circle")
    f.dot:SetSize(10, 10)
    f.dot:SetPoint("CENTER")

    -- under the badge: the distance (the number you look for) and the time to get there
    f.dist = Shadow(UI.Text(f, 12, "text", "OVERLAY", "bold"))
    f.dist:SetPoint("TOP", f.badge, "BOTTOM", 0, -3)
    f.eta = Shadow(UI.Text(f, 10, "text", "OVERLAY", "medium"))
    f.eta:SetPoint("TOP", f.dist, "BOTTOM", 0, -1)
    f.eta:SetTextColor(0.79, 0.82, 0.85)

    -- off screen: an arrow on the badge pointing toward the spot
    f.arrow = f.badge:CreateTexture(nil, "OVERLAY", nil, 2)
    f.arrow:SetTexture(MEDIA .. "NavArrow")
    f.arrow:SetSize(16, 16)
    f.arrow:Hide()

    -- the label card beside the badge: the quest, then what to do and where
    f.card = CreateFrame("Frame", nil, f)
    f.card:SetPoint("LEFT", f.badge, "RIGHT", 8, 0)
    f.card:SetSize(170, 40)
    UI.Flat(f.card, { 0.06, 0.07, 0.09, 0.88 }, { 0.17, 0.29, 0.3, 1 })
    f.title = UI.Text(f.card, 12, "text", nil, "bold")
    f.title:SetPoint("TOPLEFT", 10, -7)
    f.title:SetWordWrap(false)
    f.title:SetJustifyH("LEFT")
    f.sub = UI.Text(f.card, 10, "muted")
    f.sub:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)
    f.sub:SetWordWrap(false)
    f.sub:SetJustifyH("LEFT")

    -- fade in when it appears; position and text are refreshed 10 times a second
    local acc = 0
    f:SetScript("OnShow", function(self)
        if not self.hiddenAt or GetTime() - self.hiddenAt > 1 then self:SetAlpha(0); self.fading = 0 end
    end)
    f:SetScript("OnHide", function(self) self.hiddenAt = GetTime() end)
    f:SetScript("OnUpdate", function(self, dt)
        dt = dt or 0
        if self.fading then
            self.fading = self.fading + dt * 4
            if self.fading >= 1 then self.fading = nil end
            self:SetAlpha(math.min(1, self.fading or 1) * (self.targetAlpha or 1))
        end
        acc = acc + dt
        if acc < 0.1 then return end
        acc = 0
        ns.WorldMarkerUpdate()
    end)
    return f
end

local KIND = {
    pickup = { glyph = "!", label = "Pickup" },
    turnin = { glyph = "?", label = "Turn in" },
    objective = { label = "Objective" },
}

local function Clock(seconds)
    seconds = math.floor(seconds + 0.5)
    if seconds >= 3600 then return string.format("%d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60) end
    return string.format("%d:%02d", seconds / 60, seconds % 60)
end

-- teal on the way, green when you're there
local function Paint(color)
    local m = marker
    if m.painted == color then return end
    m.painted = color
    local r, g, b = color[1], color[2], color[3]
    m.ring:SetVertexColor(r, g, b, 1)
    m.dot:SetVertexColor(r, g, b, 1)
    m.foot:SetVertexColor(r, g, b, 0.9)
    m.footPulse:SetVertexColor(r, g, b, 0.6)
    m.halo:SetVertexColor(r, g, b, 0.22)
    m.arrow:SetVertexColor(r, g, b, 1)
    Fade(m.beam, r, g, b, 0.95, 0)
    Fade(m.glow, r, g, b, 0.22, 0)
    ns.UI.SetEdge(m.card, { r * 0.55, g * 0.55, b * 0.55, 1 })
end

-- Distance, time, arrival, off-screen arrow and where the marker sits (on the navigation frame).
function ns.WorldMarkerUpdate()
    if not marker or not marker.summary then return end
    local now = GetTime()
    local nav = C_Navigation.GetFrame and C_Navigation.GetFrame()
    if QuestSelected() then marker:Hide(); return end
    if not nav then
        -- the game rebuilds its navigation frame when the waypoint changes: wait it out
        marker.lostAt = marker.lostAt or now
        if now - marker.lostAt > 0.6 then marker:Hide() end
        return
    end
    marker.lostAt = nil
    -- only switch between "in view" and "at the screen edge" once the new state has held a moment
    local raw = C_Navigation.WasClampedToScreen and C_Navigation.WasClampedToScreen() or false
    if marker.clamped == nil then marker.clamped = raw end
    if raw ~= marker.clamped then
        marker.flipAt = marker.flipAt or now
        if now - marker.flipAt < 0.35 then raw = marker.clamped end
    else
        marker.flipAt = nil
    end
    local clamped = raw
    if marker.nav ~= nav or marker.anchored ~= clamped then
        -- in view: the frame's bottom (the rings) on the spot; at the edge: the badge on the edge point
        marker:ClearAllPoints()
        if clamped then marker:SetPoint("TOP", nav, "CENTER", 0, 17)
        else marker:SetPoint("BOTTOM", nav, "CENTER", 0, 0) end
        marker.nav, marker.anchored, marker.clamped, marker.flipAt = nav, clamped, clamped, nil
    end
    local yards = C_Navigation.GetDistance and C_Navigation.GetDistance()
    if not yards or yards <= 0 then yards = ns.ArrowGeometry(marker.summary.target).yards end
    local here = yards and yards <= ARRIVE
    Paint(here and GREEN or TEAL)

    if here then
        marker.dist:SetText(L["You're here"])
        marker.dist:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
        marker.eta:SetText("")
    elseif yards then
        local speed = (GetUnitSpeed and GetUnitSpeed("player")) or 0
        marker.dist:SetText(string.format(L["%d yd"], math.floor(yards + 0.5)))
        marker.dist:SetTextColor(1, 1, 1)
        marker.eta:SetText(clamped and "" or ("~" .. Clock(yards / (speed > 0.5 and speed or RUN_SPEED))))
    else
        marker.dist:SetText(""); marker.eta:SetText("")
    end

    -- nearer is a little bigger; far away it gets smaller and slightly see-through
    local target = 1
    if yards and not clamped then target = math.max(0.78, math.min(1, 1 - math.max(0, yards - 60) / 800)) end
    marker.scale = marker.scale and (marker.scale + (target - marker.scale) * 0.3) or target   -- glide, don't jump
    marker:SetScale(marker.scale)
    -- close by it fades to a faint outline so you can see the NPC or object; far away it's slightly dimmed
    local want = 1
    if yards and not clamped then
        if yards < NEAR then want = FAINT + (1 - FAINT) * math.max(0, yards - ARRIVE) / (NEAR - ARRIVE)
        elseif yards > 300 then want = 0.85 end
    end
    marker.targetAlpha = marker.targetAlpha and (marker.targetAlpha + (want - marker.targetAlpha) * 0.25) or want
    if not marker.fading then marker:SetAlpha(marker.targetAlpha) end

    marker.card:SetShown(not clamped)
    marker.beam:SetShown(not clamped)
    marker.glow:SetShown(not clamped)
    marker.foot:SetShown(not clamped)
    marker.footPulse:SetShown(not clamped)

    -- off screen: point the arrow from the middle of the screen toward the edge point
    local ax, ay = nav.GetCenter and nav:GetCenter()
    local cx, cy = UIParent.GetCenter and UIParent:GetCenter()
    if clamped and ax and cx then
        local angle = math.atan2(ay - cy, ax - cx)
        marker.arrow:ClearAllPoints()
        marker.arrow:SetPoint("CENTER", marker.badge, "CENTER", math.cos(angle) * 22, math.sin(angle) * 22)
        marker.arrow:SetRotation(angle - math.pi / 2)
        marker.arrow:Show()
    else
        marker.arrow:Hide()
    end
    marker:Show()
end

-- Called whenever the route may have changed (and from the compass refresh).
function ns.WorldMarkerRefresh()
    if not Supported() then return end
    local summary = Enabled() and ns.RouteStopSummary and ns.RouteStopSummary()
    if not summary or not summary.target.x then
        if marker then marker:Hide(); marker.summary = nil end
        if placed then Clear() end
        if SuperTrackedFrame and SuperTrackedFrame.SetAlpha then SuperTrackedFrame:SetAlpha(1) end
        return
    end
    marker = marker or Build()
    if not SameSpot(placed, { uiMap = summary.target.uiMap, x = summary.target.x, y = summary.target.y }) then
        if Place(summary.target) then
            placed = { uiMap = summary.target.uiMap, x = summary.target.x, y = summary.target.y }
        end
    end
    marker.summary = summary
    local kind = KIND[summary.kind]
    marker.glyph:SetText(kind.glyph or "")
    marker.dot:SetShown(kind.glyph == nil)
    marker.title:SetText(summary.title or "")
    local sub = L[kind.label] .. (summary.who and ("  ·  " .. summary.who) or "")
    marker.sub:SetText(sub .. (summary.more > 0 and ("  ·  +" .. summary.more) or ""))
    local width = math.max(tonumber(marker.title:GetStringWidth()) or 0, tonumber(marker.sub:GetStringWidth()) or 0, 90)
    width = math.min(width, 230)
    marker.card:SetWidth(width + 20)
    marker.title:SetWidth(width)
    marker.sub:SetWidth(width)
    -- our marker replaces the game's own icon on the navigation frame
    if SuperTrackedFrame and SuperTrackedFrame.SetAlpha then SuperTrackedFrame:SetAlpha(0) end
    ns.WorldMarkerUpdate()
end

-- Turning the option off clears our waypoint and gives the game its own marker back.
function ns.WorldMarkerToggle()
    if Enabled() then ns.WorldMarkerRefresh() return end
    if marker then marker:Hide(); marker.summary = nil end
    Clear()
    if SuperTrackedFrame and SuperTrackedFrame.SetAlpha then SuperTrackedFrame:SetAlpha(1) end
end
