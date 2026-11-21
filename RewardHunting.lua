local _, ns = ...
local L = ns.L

-- Only return routes this character could still earn. An accepted downstream
-- quest is stronger evidence of progress than an incomplete completion cache.
function ns.RewardProgress(reward, states)
    local steps = reward.steps
    states = states or {}
    local nextIndex = 1
    for i, id in ipairs(steps) do
        local state = states[id] or ns.QuestState(id)
        states[id] = state
        if state == "done" then nextIndex = i + 1
        elseif state == "inlog" then nextIndex = i end
    end
    if nextIndex > #steps then return nil end
    for i = nextIndex, #steps do
        local state = states[steps[i]]
        if state == "hidden" or state == "unknown" then return nil end
    end
    local id = steps[nextIndex]
    local state = states[id]
    local ready = state == "inlog" and ns.IsReadyToTurnIn(id)
    return { reward = reward, index = nextIndex, id = id, state = state, ready = ready,
        claimable = ready and nextIndex == #steps, remaining = #steps - nextIndex + 1 }
end

local function StepName(id)
    local quest = ns.ZoneQuest(id)
    return quest and quest.name or ("#" .. id)
end

function ns.RewardStepLabel(entry)
    if entry.ready then return L["Turn in"] end
    if entry.state == "inlog" then return L["In your log"] end
    if entry.state == "available" then return L["Pick up"] end
    local quest = ns.ZoneQuest(entry.id)
    if quest and quest.req > UnitLevel("player") then return string.format(L["Requires level %d"], quest.req) end
    return L["Prerequisite required"]
end

local waitingForItem = {}
-- Keep hybrid builds and items with only universal stats (such as Stamina).
-- Filter only when an item specifically favors primary stats the class doesn't use.
local melee = { ITEM_MOD_STRENGTH_SHORT = true, ITEM_MOD_AGILITY_SHORT = true }
local caster = { ITEM_MOD_INTELLECT_SHORT = true }
local preferredStats = { WARRIOR = melee, ROGUE = melee, PRIEST = caster, MAGE = caster, WARLOCK = caster }
local primaryStats = { "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_INTELLECT_SHORT" }
local function FitsPrimaryStats(stats, preferred)
    local hasPrimary = false
    for _, key in ipairs(primaryStats) do
        if (stats[key] or 0) > 0 then
            if preferred[key] then return true end
            hasPrimary = true
        end
    end
    return not hasPrimary
end

local armorNames = { "Cloth", "Leather", "Mail", "Plate" }
local bodySlots = {
    INVTYPE_HEAD = true, INVTYPE_SHOULDER = true, INVTYPE_CHEST = true, INVTYPE_ROBE = true,
    INVTYPE_WRIST = true, INVTYPE_HAND = true, INVTYPE_WAIST = true, INVTYPE_LEGS = true, INVTYPE_FEET = true,
}
local function PreferredArmor(class, level)
    if class == "WARRIOR" or class == "PALADIN" then return level >= 40 and 4 or 3 end
    if class == "SHAMAN" or class == "HUNTER" then return level >= 40 and 3 or 2 end
    if class == "DRUID" or class == "ROGUE" then return 2 end
    return 1
end

-- Classify by the game's inventory slot. A held-in-off-hand item is not a
-- one-handed weapon, and cloaks have the Cloth subclass regardless of wearer.
local function MatchesCategory(filter, slot, itemClass, subclass, armor)
    local bodyArmor = itemClass == 4 and bodySlots[slot] and subclass and subclass >= 1 and subclass <= 4
    if bodyArmor and subclass ~= armor then return false end
    if not filter or filter == "All" then return true end
    if filter == "Armor" then return bodyArmor end
    if filter == "Jewelry" then return slot == "INVTYPE_FINGER" or slot == "INVTYPE_NECK" end
    if filter == "Trinkets" then return slot == "INVTYPE_TRINKET" end
    return filter == "Weapon" and itemClass == 2
end

local function EquippedTypes()
    local instant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    local types = {}
    if not instant or not GetInventoryItemID then return types end
    for index = 1, 18 do
        local id = GetInventoryItemID("player", index)
        if id then
            local _, _, _, slot, _, itemClass, subclass = instant(id)
            if subclass and (itemClass == 2 or (itemClass == 4 and (bodySlots[slot] or slot == "INVTYPE_SHIELD"))) then
                types[itemClass * 100 + subclass] = true
            end
        end
    end
    return types
end

local function FishingRank()
    if GetProfessions and GetProfessionInfo then
        local _, _, _, fishing = GetProfessions()
        if fishing then return select(3, GetProfessionInfo(fishing)) end
    end
    if GetNumSkillLines and GetSkillLineInfo then
        local fishing = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(7620) or (GetSpellInfo and GetSpellInfo(7620))
        for i = 1, GetNumSkillLines() do
            local name, header, _, rank = GetSkillLineInfo(i)
            if name and name == fishing and not header then return rank end
        end
    end
    return 0
end

local function FitsCharacter(reward, level, class, filter, equipped)
    if waitingForItem[reward.item] == false then return false end
    local getInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
    if not getInfo then return false end
    local name, link, _, _, requiredLevel, _, subtype, _, slot, _, _, itemClass, subclass = getInfo(reward.item)
    if not name then
        local requested = waitingForItem[reward.item]
        waitingForItem[reward.item] = true
        if not requested and C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(reward.item)
        end
        return false, true
    end
    if requiredLevel and requiredLevel > level then return false end
    if not itemClass or not subclass or not slot then
        local instant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
        if instant then
            local _, _, _, instantSlot, _, instantClass, instantSubclass = instant(reward.item)
            slot, itemClass, subclass = instantSlot, instantClass, instantSubclass
        end
    end
    if not slot or slot == "" or slot == "INVTYPE_NON_EQUIP" then return false end
    if not MatchesCategory(filter, slot, itemClass, subclass, PreferredArmor(class, level)) then return false end
    if reward.fishingRank and (FishingRank() or 0) < reward.fishingRank then return false end
    if reward.proficiency and not (itemClass and subclass and equipped[itemClass * 100 + subclass]) then
        local knows = C_SpellBook and C_SpellBook.IsSpellKnown or IsPlayerSpell or IsSpellKnown
        if knows and not knows(reward.proficiency) then return false end
        if not knows and not (C_PlayerInfo and C_PlayerInfo.CanUseItem) then return false end
    end
    local preferred = itemClass ~= 2 and preferredStats[class]
    local getStats = C_Item and C_Item.GetItemStats or GetItemStats
    local stats = preferred and link and getStats and getStats(link)
    if stats and not FitsPrimaryStats(stats, preferred) then return false end
    if C_PlayerInfo and C_PlayerInfo.CanUseItem and C_PlayerInfo.CanUseItem(reward.item) == false then return false end
    return true, false, _G[slot], itemClass == 2 and (subtype or L[reward.kind])
end

-- Only look up item data for the quest being handed in. The reminder ticker
-- never needs to run the full Reward Hunting search.
local rewardsByQuest
function ns.TurnInGear(id)
    if not rewardsByQuest then
        rewardsByQuest = {}
        for _, reward in pairs(ns.RewardCatalog) do
            local final = reward.steps[#reward.steps]
            local options = rewardsByQuest[final] or {}
            options[#options + 1] = reward
            rewardsByQuest[final] = options
        end
    end
    local options = rewardsByQuest[id]
    if not options then return end
    local level, class = UnitLevel("player"), select(2, UnitClass("player"))
    local equipped, best = EquippedTypes()
    for _, reward in ipairs(options) do
        if FitsCharacter(reward, level, class, "All", equipped) then
            if reward.item == QuestynatorRewardGoal then return reward end
            if not best or reward.name < best.name then best = reward end
        end
    end
    return best
end

local function InCurrentZone(entry, maps, matches)
    if matches[entry.id] == nil then
        matches[entry.id] = false
        for _, place in ipairs(ns.RewardDestinations(entry)) do
            if maps[place.uiMap] then
                matches[entry.id] = true
                break
            end
        end
    end
    return matches[entry.id]
end

function ns.RewardResults(filter, query, zoneOnly)
    local results, states, pending = {}, {}, 0
    local maps = zoneOnly and ns.CurrentZoneMaps()
    if maps and not next(maps) then return results, pending, true end
    local matches = {}
    local level = UnitLevel("player")
    local _, class = UnitClass("player")
    local green = ns.QuestGreenRange(level)
    local equipped = EquippedTypes()
    query = (query or ""):lower()
    for _, reward in pairs(ns.RewardCatalog) do
        local quest = ns.ZoneQuest(reward.steps[#reward.steps])
        if ns.QuestFitsLevel(quest, level, green) then
            local entry = ns.RewardProgress(reward, states)
            if entry and (not maps or InCurrentZone(entry, maps, matches)) then
                local fits, loading, slot, weaponType = FitsCharacter(reward, level, class, filter, equipped)
                if loading then pending = pending + 1 end
                if fits then
                    entry.slot = slot
                    entry.weaponType = weaponType
                    local text = reward.name .. " " .. L[reward.kind] .. " " .. (weaponType or "") .. " " .. (slot or "") .. " " .. quest.name
                    if text:lower():find(query, 1, true) then results[#results + 1] = entry end
                end
            end
        end
    end
    table.sort(results, function(a, b)
        if a.claimable ~= b.claimable then return a.claimable end
        if (a.state == "locked") ~= (b.state == "locked") then return b.state == "locked" end
        if a.remaining ~= b.remaining then return a.remaining < b.remaining end
        if a.state ~= b.state then return a.state == "inlog" end
        return a.reward.name < b.reward.name
    end)
    return results, pending
end

local view, selected, filter, query, weaponTypeFilter
local currentZoneOnly = true
local function Button(parent, width, label, click)
    local b = ns.UI.Button(parent, width, 22, "outline")
    b:SetText(L[label])
    b:SetScript("OnClick", click)
    return b
end

local function ItemTip(owner)
    if not owner.reward then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink("item:" .. owner.reward.item)
    if GameTooltip:NumLines() == 0 then GameTooltip:SetText(owner.reward.name) end
    if owner.remaining then
        GameTooltip:AddLine(string.format(L["Quests remaining: %d"], owner.remaining), 0.31, 0.82, 0.77)
    end
    GameTooltip:Show()
    if GameTooltip_ShowCompareItem then GameTooltip_ShowCompareItem(GameTooltip) end
end

local function ShowItem(item)
    selected = item
    view.choosingWeaponType = false
    view.scroll:SetVerticalScroll(0)
    ns.RefreshRewardHunting()
end

local function SelectWeaponType(button)
    weaponTypeFilter = button.weaponType
    ShowItem(nil)
end

-- Called only for an empty zone search. Count exactly what the button will open.
local function AllZonesAction(missingMap, localPending)
    local generic = L["Search all zones"]
    if missingMap or localPending > 0 then return generic end
    local results, pending = ns.RewardResults(filter, query, false)
    if pending > 0 then return generic end
    local count, allLocated = 0, true
    for _, entry in ipairs(results) do
        if not weaponTypeFilter or entry.weaponType == weaponTypeFilter then
            count = count + 1
            if allLocated and #ns.RewardDestinations(entry) == 0 then allLocated = false end
        end
    end
    if count == 0 then return generic end
    -- Locked chains and quests without coordinates can still appear in all zones.
    if not allLocated then return string.format(L["Search all zones (%d)"], count) end
    if filter == "Weapon" then
        if count == 1 then return L["Show 1 weapon in other zones"] end
        return string.format(L["Show %d weapons in other zones"], count)
    end
    if count == 1 then return L["Show 1 reward in other zones"] end
    return string.format(L["Show %d rewards in other zones"], count)
end

local function LayoutWeaponTypes(types)
    local kinds = {}
    local count = 0
    if view.choosingWeaponType then
        for kind in pairs(types) do kinds[#kinds + 1] = kind end
        table.sort(kinds)
        count = #kinds + 1
    end
    local columns = math.min(3, count)
    for i = 1, count do
        local b = view.typeButtons[i]
        if not b then
            b = Button(view, 164, "All weapon types", SelectWeaponType)
            b.label:SetWidth(156)
            b.label:SetWordWrap(false)
            view.typeButtons[i] = b
        end
        local column, row = (i - 1) % 3, math.floor((i - 1) / 3)
        b:SetPoint("TOPRIGHT", view.weaponType, "BOTTOMRIGHT", (column + 1 - columns) * 169, -4 - row * 26)
        b.weaponType = kinds[i - 1]
        b:SetText(b.weaponType or L["All weapon types"])
        b:SetKind(b.weaponType == weaponTypeFilter and "primary" or "outline")
        b:Show()
    end
    for i = count + 1, #view.typeButtons do view.typeButtons[i]:Hide() end
    view.scroll:SetPoint("TOPLEFT", 8, -92 - math.ceil(count / 3) * 26)
end

function ns.BuildRewardHunting(p, inset)
    local UI = ns.UI
    view = CreateFrame("Frame", nil, inset)
    view:SetAllPoints(inset)
    view:SetScript("OnHide", function()
        if view.choosingWeaponType then
            view.choosingWeaponType = false
            view.weaponType:SetKind("outline")
            LayoutWeaponTypes()
        end
    end)
    view:SetScript("OnShow", function()
        for id, pending in pairs(waitingForItem) do
            if not pending then waitingForItem[id] = nil end
        end
    end)
    -- Item stats arrive asynchronously. Weapon training can change eligibility
    -- while the window is open without changing any quest in the log.
    view:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    view:RegisterEvent("SPELLS_CHANGED")
    view:RegisterEvent("SKILL_LINES_CHANGED")
    view:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    view:RegisterEvent("ZONE_CHANGED")
    view:RegisterEvent("ZONE_CHANGED_INDOORS")
    view:RegisterEvent("PLAYER_ENTERING_WORLD")
    view:SetScript("OnEvent", function(self, event, id, success)
        if event == "GET_ITEM_INFO_RECEIVED" then
            if not waitingForItem[id] then return end
            if success == false then waitingForItem[id] = false else waitingForItem[id] = nil end
        end
        if not self:IsVisible() or self.refreshPending then return end
        self.refreshPending = true
        C_Timer.After(0.15, function()
            self.refreshPending = nil
            if self:IsVisible() then ns.RefreshRewardHunting() end
        end)
    end)
    p.rewardView = view
    view.search = UI.SearchBox(view, 300, L["Search item, slot or quest"], function(text)
        query = text
        if view.scroll then view.scroll:SetVerticalScroll(0); ns.RefreshRewardHunting() end
    end)
    view.search:SetPoint("TOPLEFT", 8, -8)
    view.filters = {}
    local previous
    for _, category in ipairs({ { "All", 42 }, { "Weapon", 76 },
                                { "Armor", 108 }, { "Jewelry", 70 }, { "Trinkets", 70 } }) do
        local label, width = category[1], category[2]
        local b = Button(view, width, label, function()
            weaponTypeFilter = nil
            filter = label
            ShowItem(nil)
        end)
        if previous then b:SetPoint("LEFT", previous, "RIGHT", 5, 0)
        else b:SetPoint("TOPLEFT", view.search, "BOTTOMLEFT", 0, -6) end
        view.filters[label] = b
        previous = b
    end
    view.zone = Button(view, 98, "Current zone", function()
        currentZoneOnly = not currentZoneOnly
        ShowItem(nil)
    end)
    view.zone:SetPoint("LEFT", previous, "RIGHT", 5, 0)
    view.typeButtons = {}
    view.weaponType = Button(view, 180, "All weapon types", function()
        view.choosingWeaponType = not view.choosingWeaponType
        ns.RefreshRewardHunting()
    end)
    view.weaponType:SetPoint("TOPRIGHT", -12, -64)
    view.back = Button(view, 104, "All rewards", function() ShowItem(nil) end)
    view.back:SetPoint("TOPLEFT", 8, -8)
    view.action = Button(view, 136, "Pursue Reward", function()
        ns.SetRewardPursuit(selected ~= QuestynatorRewardGoal and selected or nil)
        ns.RefreshRewardHunting()
    end)
    view.action:SetPoint("TOPRIGHT", -12, -8)
    view.caption = UI.Text(view, 12, "accent")
    view.caption:SetPoint("TOPLEFT", 8, -42)
    view.scroll = CreateFrame("ScrollFrame", nil, view, "UIPanelScrollFrameTemplate")
    view.scroll:SetPoint("TOPLEFT", 8, -65)
    view.scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    UI.SkinScroll(view.scroll)
    view.child = CreateFrame("Frame", nil, view.scroll)
    view.child:SetSize(502, 1)
    view.scroll:SetScrollChild(view.child)
    view.zoneEmpty = UI.Empty(view.child, function()
        currentZoneOnly = false
        ShowItem(nil)
    end)
    view.zoneEmpty:SetPoint("TOP", 0, -12)
    view.zoneEmpty:Hide()
    view.rows = {}
end

local function Row(i, title, subtitle, reward, destination, pinLabel, remaining)
    local row = view.rows[i]
    if not row then
        row = CreateFrame("Button", nil, view.child)
        row:SetSize(502, 42)
        if i == 1 then row:SetPoint("TOPLEFT")
        else row:SetPoint("TOPLEFT", view.rows[i - 1], "BOTTOMLEFT", 0, -4) end
        ns.UI.Flat(row, ns.UI.C.panel)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(32, 32)
        row.icon:SetPoint("LEFT", 7, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.title = ns.UI.Text(row, 13, "text", nil, "medium")
        row.sub = ns.UI.Text(row, 11, "muted")
        row.sub:SetJustifyH("LEFT")
        row.pin = Button(row, 110, "Pin", function()
            local place = row.destination
            if place then ns.Waypoint(place.area, place.x, place.y, place.name, true) end
        end)
        row.pin:SetPoint("RIGHT", -8, 0)
        row:SetScript("OnClick", function(self)
            if self.reward and not selected then
                GameTooltip:Hide()
                view.search:ClearFocus()
                ShowItem(self.reward.item)
            end
        end)
        row:SetScript("OnEnter", ItemTip)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        view.rows[i] = row
    end
    row.reward = reward
    row.destination, row.remaining = destination, remaining
    row.pin:SetShown(destination ~= nil)
    if destination then row.pin:SetText(pinLabel) end
    row.icon:SetShown(reward ~= nil)
    if reward then
        local getIcon = C_Item and C_Item.GetItemIconByID or GetItemIcon
        row.icon:SetTexture(getIcon and getIcon(reward.item) or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
    local left = reward and 48 or 10
    row.title:SetPoint("TOPLEFT", left, -5)
    row.title:SetWidth(502 - left - (destination and row.pin:GetWidth() + 18 or 8))
    row.title:SetJustifyH("LEFT")
    row.title:SetWordWrap(false)
    row.sub:SetPoint("TOPLEFT", left, -23)
    row.sub:SetWidth(row.title:GetWidth())
    row.title:SetText(title)
    row.sub:SetText(subtitle)
    row:SetHeight(math.max(42, 29 + math.ceil(row.sub:GetStringHeight())))
    row:Show()
    return row:GetHeight() + 4
end

function ns.RefreshRewardHunting()
    if not view then return end
    local reward = selected and ns.RewardCatalog[selected]
    local entry = reward and ns.RewardProgress(reward)
    if entry then
        local level = UnitLevel("player")
        local _, class = UnitClass("player")
        local quest = ns.ZoneQuest(reward.steps[#reward.steps])
        local fits, _, slot, weaponType = FitsCharacter(reward, level, class, nil, EquippedTypes())
        entry.slot, entry.weaponType = slot, weaponType
        if not ns.QuestFitsLevel(quest, level, ns.QuestGreenRange(level)) or not fits then entry = nil end
    end
    if not entry then selected = nil end
    view.search:SetShown(not selected)
    view.weaponType:SetShown(not selected and filter == "Weapon")
    view.weaponType:SetKind(view.choosingWeaponType and "primary" or "outline")
    view.weaponType:SetText(weaponTypeFilter or L["All weapon types"])
    view.zone:SetShown(not selected)
    view.zone:SetKind(currentZoneOnly and "primary" or "outline")
    if not selected then
        local _, class = UnitClass("player")
        local armor = armorNames[PreferredArmor(class, UnitLevel("player"))]
        view.filters.Armor:SetText(string.format(L["Armor (%s)"], L[armor]))
    end
    for kind, b in pairs(view.filters) do
        b:SetShown(not selected)
        b:SetKind(kind == (filter or "All") and "primary" or "outline")
    end
    view.back:SetShown(selected ~= nil)
    -- A saved pursuit can outlive a level bracket or a search filter.
    view.action:SetShown(selected ~= nil or QuestynatorRewardGoal ~= nil)
    local stopping = QuestynatorRewardGoal and (not selected or selected == QuestynatorRewardGoal)
    view.action:SetPoint("TOPRIGHT", -12, -8)
    view.caption:SetPoint("TOPLEFT", 8, selected and -42 or -69)
    view.action:SetText(stopping and L["Stop pursuit"] or L["Pursue Reward"])
    view.action:SetEnabled(not not (stopping or (entry and entry.state ~= "locked")))
    local used, height = 0, 0
    view.zoneEmpty:Hide()
    local function AddRow(...)
        used = used + 1
        height = height + Row(used, ...)
    end
    if entry then
        view.scroll:SetPoint("TOPLEFT", 8, -65)
        for _, b in ipairs(view.typeButtons) do b:Hide() end
        view.caption:SetText(L["Reward Hunting"] .. "  /  " .. reward.name)
        local label = L["Quest reward"]
        if reward.choice ~= nil then label = reward.choice and L["Choice of reward"] or L["Guaranteed reward"] end
        local kind = entry.weaponType or (reward.kind == "Accessory" and entry.slot) or L[reward.kind]
        AddRow(reward.name, kind .. "  ·  " .. label, reward, nil, nil, entry.remaining)
        for i = entry.index, #reward.steps do
            local id = reward.steps[i]
            local status = i == entry.index and ns.RewardStepLabel(entry) or L["Later"]
            local pickup = i ~= entry.index or entry.state ~= "inlog"
            local pinLabel = ns.PinLabel(pickup, not entry.ready)
            local giver, reason
            if i == entry.index and entry.state ~= "locked" then
                local target = QuestynatorRewardGoal == reward.item and ns.RouteTarget()
                if target and target.questID == id and target.rewardItem == reward.item then
                    giver = target
                else
                    giver, reason = ns.RewardDestination(entry)
                end
            else
                giver = ns.QuestGiver(id)
            end
            local where = reason or (pickup and L["Pickup location unknown"] or L["Location unknown"])
            if giver then
                local zone = ns.AreaName(giver.area)
                local map = not zone and ns.UiMapForArea(giver.area)
                local info = map and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(map)
                zone = zone or (info and info.name) or string.format(L["Area %d"], giver.area)
                where = string.format("%s\n%s (%.1f, %.1f)", giver.name, zone, giver.x, giver.y)
                if not ns.UiMapForArea(giver.area) or giver.x < 0 or giver.x > 100 or giver.y < 0 or giver.y > 100 then giver = nil end
            end
            AddRow(i .. ". " .. StepName(id) .. "  ·  " .. status, where, nil, giver, pinLabel)
        end
    else
        local results, pending, missingMap = ns.RewardResults(filter, query, currentZoneOnly)
        view.caption:SetText(L["Reward Hunting"] .. "  /  " .. L["Closest to earning"])
        local weaponTypes = {}
        for _, e in ipairs(results) do
            if e.weaponType then weaponTypes[e.weaponType] = true end
            if not weaponTypeFilter or e.weaponType == weaponTypeFilter then
                local progress = e.claimable and L["Ready to claim"] or string.format(L["%d of %d quests complete"], e.index - 1, #e.reward.steps)
                local status = e.reward.item == QuestynatorRewardGoal and L["Pursuing"] or ns.RewardStepLabel(e)
                local kind = e.weaponType or (e.reward.kind == "Accessory" and e.slot) or L[e.reward.kind]
                AddRow(e.reward.name, kind .. "  ·  " .. progress .. "  ·  " .. status, e.reward, nil, nil, e.remaining)
            end
        end
        LayoutWeaponTypes(weaponTypes)
        if used == 0 then
            if currentZoneOnly then
                local title = filter == "Weapon" and L["No matching weapons in this zone"] or L["No matching rewards in this zone"]
                local subtitle
                if missingMap then
                    title = L["Current zone unavailable"]
                elseif pending > 0 then
                    title, subtitle = L["Loading reward items…"], L["Waiting for item details from the game."]
                elseif weaponTypeFilter and next(weaponTypes) then
                    subtitle = L["Choose All weapon types to see the other matching weapons."]
                end
                view.zoneEmpty:Set(title, subtitle, AllZonesAction(missingMap, pending))
                view.zoneEmpty:Show()
                height = view.zoneEmpty:GetHeight() + 12
            elseif pending > 0 then
                AddRow(L["Loading reward items…"], L["Waiting for item details from the game."])
            elseif weaponTypeFilter and next(weaponTypes) then
                AddRow(L["No matching weapons of this type"], L["Choose All weapon types to see the other matching weapons."])
            else
                AddRow(L["No matching rewards"], L["Showing unfinished reward quests for your level and equipment proficiencies."])
            end
        end
    end
    for i = used + 1, #view.rows do view.rows[i]:Hide() end
    view.child:SetHeight(height)
end
