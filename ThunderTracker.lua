local ThunderTracker = CreateFrame("Frame", "ThunderstormTrackerFrame", UIParent)

-- ✅ Possible Thunderstorm spell IDs (expand if needed)
local THUNDERSTORM_IDS = { [59156] = true, [51490] = true }

local trackingEnabled = true -- Allows toggling via /tt show or /tt hide

-- ✅ Create a moveable UI icon container
local stormFrame = CreateFrame("Frame", "ThunderstormIconFrame", UIParent)
stormFrame:SetSize(60, 60)  -- Main icon size
stormFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
stormFrame:SetMovable(true)
stormFrame:EnableMouse(true)
stormFrame:RegisterForDrag("LeftButton")
stormFrame:SetScript("OnDragStart", stormFrame.StartMoving)
stormFrame:SetScript("OnDragStop", function()
    stormFrame:StopMovingOrSizing()
    -- Save position when the frame is moved
    local point, _, _, x, y = stormFrame:GetPoint()
    ThunderTrackerDB = ThunderTrackerDB or {}
    ThunderTrackerDB.posX = x
    ThunderTrackerDB.posY = y
end)
stormFrame:Hide() -- Start hidden

-- ✅ Create Thunderstorm Icon
local stormTexture = stormFrame:CreateTexture(nil, "BACKGROUND")
stormTexture:SetAllPoints()
stormTexture:SetTexture("Interface\\Icons\\Spell_Shaman_ThunderStorm")
stormTexture:SetVertexColor(1, 0, 0, 0.8)  -- Red tint (adjust last value for transparency)

-- ✅ Cooldown text overlay
local cooldownText = stormFrame:CreateFontString(nil, "OVERLAY")
cooldownText:SetPoint("CENTER", stormFrame, "CENTER", 0, 0)
cooldownText:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE") -- Adjust size here
cooldownText:SetText("")

-- ✅ Enlarged Glow Border (10% Bigger Than Icon)
local glowBorder = stormFrame:CreateTexture(nil, "OVERLAY", nil, 7)
glowBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
glowBorder:SetBlendMode("ADD")
glowBorder:SetSize(117, 117)  -- **Now 20% larger than the 60x60 icon**
glowBorder:SetPoint("CENTER", stormFrame, "CENTER", 0, 0)
glowBorder:SetAlpha(0)  -- Start invisible

local flashing = false

-- ✅ Function to display the Thunderstorm icon for 15 seconds
local function ShowThunderstormIcon()
    if not trackingEnabled then return end  
    stormFrame:Show()
    local endTime = GetTime() + 15
    flashing = false
    glowBorder:SetAlpha(0) -- Ensure glow is off initially

    -- Update cooldown text & add flashing effect for the last 1 second
    local function UpdateCooldown()
        local remaining = math.ceil(endTime - GetTime())
        if remaining > 0 then
            cooldownText:SetText(remaining)

            -- Start flashing effect in the last 2 second
            if remaining == 2 and not flashing then
                flashing = true
                local flashState = false

                local function FlashBorder()
                    if flashing then
                        flashState = not flashState
                        glowBorder:SetAlpha(flashState and 1 or 0) -- Toggle glow visibility
                        C_Timer.After(0.3, FlashBorder) -- Repeat every 0.3s
                    else
                        glowBorder:SetAlpha(0) -- Ensure border resets
                    end
                end

                FlashBorder()
            end

            C_Timer.After(1, UpdateCooldown)
        else
            stormFrame:Hide()
            cooldownText:SetText("")
            flashing = false
            glowBorder:SetAlpha(0) -- Ensure border disappears
        end
    end

    UpdateCooldown()
end

-- ✅ Function to check if the source is a RAID member (excluding the player)
local function IsRaidMember(sourceName)
    if not sourceName or sourceName == UnitName("player") then
        return false -- Ignore if it's the player
    end

    for i = 1, GetNumRaidMembers() do
        local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
        if name and name == sourceName and online then
            return true -- Valid RAID member
        end
    end

    return false
end

-- ✅ Listen to combat log for Thunderstorm casts from RAID members
ThunderTracker:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
ThunderTracker:SetScript("OnEvent", function(self, event, ...)
    if not trackingEnabled then return end  

    local eventData = { ... }  
    if #eventData == 0 then return end

    local _, subEvent, _, sourceName, _, _, _, _, spellID = unpack(eventData)

    -- ✅ If Thunderstorm (ANY valid ID) is cast by a RAID member (excluding the player)
    if subEvent == "SPELL_ENERGIZE" and THUNDERSTORM_IDS[spellID] and IsRaidMember(sourceName) then
        ShowThunderstormIcon()
    end
end)

-- ✅ Slash command to move, lock, change size, or toggle visibility
SLASH_THUNDERTRACKER1 = "/tt"
SlashCmdList["THUNDERTRACKER"] = function(msg)
    if msg == "lock" then
        stormFrame:EnableMouse(false)
        print("ThunderTracker: Frame locked.")
    elseif msg == "unlock" then
        stormFrame:EnableMouse(true)
        print("ThunderTracker: Frame unlocked.")
    elseif msg == "hide" then
        trackingEnabled = false
        stormFrame:Hide()
        print("ThunderTracker: Tracking disabled. Icon will no longer appear.")
    elseif msg == "show" then
        trackingEnabled = true
        stormFrame:Hide() 
        print("ThunderTracker: Tracking enabled. Icon will appear when Thunderstorm is cast by a RAID member.")
    elseif msg == "test" then
        print("ThunderTracker: Running TEST mode.")
        ShowThunderstormIcon()
    elseif msg == "small" then
        currentSize = "small"
        UpdateSize()
        print("ThunderTracker: Switched to SMALL size.")
    elseif msg == "standard" then
        currentSize = "standard"
        UpdateSize()
        print("ThunderTracker: Switched to STANDARD size.")
    elseif msg == "large" then
        currentSize = "large"
        UpdateSize()
        print("ThunderTracker: Switched to LARGE size.")
    else
        print("ThunderTracker Commands:")
        print("/tt lock - Locks the frame")
        print("/tt unlock - Unlocks the frame")
        print("/tt hide - Disables tracking (icon will never show)")
        print("/tt show - Enables tracking (icon will appear on Thunderstorm cast)")
        print("/tt test - Simulates Thunderstorm for testing (icon will show for 15s)")
       
    end
end

-- ✅ "DONT" (Above Icon)
local dontText = stormFrame:CreateFontString(nil, "OVERLAY")
dontText:SetPoint("BOTTOM", stormFrame, "TOP", 0, 1)  -- Properly spaced above
dontText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")  -- Moderate size
dontText:SetText("DONT")
dontText:SetTextColor(1, 1, 1)  -- White text

-- ✅ "STORM" (Below Icon)
local stormText = stormFrame:CreateFontString(nil, "OVERLAY")
stormText:SetPoint("TOP", stormFrame, "BOTTOM", 0, -1)  -- Properly spaced below
stormText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")  -- Moderate size
stormText:SetText("STORM")
stormText:SetTextColor(1, 1, 1)  -- White text

-- ✅ **Final Confirmation Message (Only Debug Message Left)**
print("|cffffcc00ThunderTracker by Bolty - Friendly Thunderstorm Tracker - /tt show to enable.|r")
