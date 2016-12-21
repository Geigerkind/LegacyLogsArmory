local VERSION = 5

LLA = CreateFrame("Frame", nil, UIParent)
LLA:RegisterEvent("PLAYER_TARGET_CHANGED")
LLA:RegisterEvent("VARIABLES_LOADED")
LLA:RegisterEvent("UNIT_INVENTORY_CHANGED")
LLA:RegisterEvent("RAID_ROSTER_UPDATE")
LLA:RegisterEvent("PARTY_MEMBERS_CHANGED")
LLA:RegisterEvent("PLAYER_ENTERING_WORLD")

local UIP = UnitIsPlayer
local UN = UnitName
local UL = UnitLevel
local UC = UnitClass
local UR = UnitRace
local US = UnitSex
local UFG = UnitFactionGroup
local UIR = UnitInRaid
local UIC = UnitIsConnected
local REALM = GetRealmName()
local UPVPR = UnitPVPRank

local NeedsUpdate = false

function LLA:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("LLA: "..msg)
end

function LLA:OnEvent(event, arg1, arg2)
	if self[event] and this.loaded then
		self.arg1 = arg1
		self.arg2 = arg2
		self[event]()
	else
		self["VARIABLES_LOADED"]()
	end
end

function LLA:GetUnitData(unit, bool)
	local UName = UN(unit)
	local check = GetInventoryItemLink(unit, 5)
	if check and check~="" then
		if not LLADATA[UName] then
			LLADATA[UName] = {}
		end
		local guildName, guildRankName, guildRankIndex = GetGuildInfo(unit)
		local sessionHK, sessionDK, yesterdayHK, yesterdayHonor, thisweekHK, thisweekHonor, lastweekHK, lastweekHonor, lastweekStanding, lifetimeHK, lifetimeDK, lifetimeRank, progress = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
		sessionHK, sessionDK, yesterdayHK, yesterdayHonor, thisweekHK, thisweekHonor, lastweekHK, lastweekHonor, lastweekStanding, lifetimeHK, lifetimeDK, lifetimeRank = GetInspectHonorData();
		progress = GetInspectPVPRankProgress();
		local rankname, rankNumber = GetPVPRankInfo(UPVPR(unit));
		local _, raceEn = UR(unit)
		local U = LLADATA[UName]
		local _, unitclass = UC(unit)
		U[1] = UL(unit) -- Level
		U[2] = guildName -- Guildname
		U[3] = guildRankIndex -- GRankIndex
		U[4] = guildRankName -- GRankName
		U[5] = unitclass
		U[6] = raceEn
		U[7] = US(unit)
		U[8] = UFG(unit)
		U[9] = REALM
		for i=1, 19 do
			local ILink = GetInventoryItemLink(unit, i)
			if ILink then
				U[9+i] = ILink
			end
		end
		U[29] = rankname;
		U[30] = rankNumber;
		if (lifetimeHK or 0)>0 and bool then
			U[31] = sessionHK;
			U[32] = sessionDK;
			U[33] = yesterdayHK;
			U[34] = yesterdayHonor;
			U[35] = thisweekHK;
			U[36] = thisweekHonor;
			U[37] = lastweekHK;
			U[38] = lastweekHonor;
			U[39] = lastweekStanding;
			U[40] = lifetimeHK;
			U[41] = lifetimeDK;
			U[42] = lifetimeRank;
			U[43] = progress
		end
	end
end

function LLA:PLAYER_TARGET_CHANGED()
	if UIP("target") then
		NotifyInspect("target");
		RequestInspectHonorData();
		NeedsUpdate = true
	end
end

function LLA:UNIT_INVENTORY_CHANGED()
	this:GetUnitData(this.arg1)
end

function LLA:RAID_ROSTER_UPDATE()
	if UIR("player") then
		for i=1, 40 do
			local UName = UN("raid"..i)
			if not UName then break end
			if UIC("raid"..i) then
				if not LLADATA[UName] then
					this:GetUnitData("raid"..i)
				end
			end
		end
	end
end

function LLA:PARTY_MEMBERS_CHANGED()
	for i=1, 4 do
		local UName = UN("party"..i)
		if not UName then break end
		if UIC("party"..i) then
			if not LLADATA[UName] then
				this:GetUnitData("party"..i)
			end
		end
	end
end

function LLA:VARIABLES_LOADED()
	if not this.isLoaded then
		if not LLADATA then
			LLADATA = {}
		end
		this:GetUnitData("player")
		this.loaded = true
	end
end

function LLA:OnUpdate()
	if NeedsUpdate then
		if HasInspectHonorData() then
			LLA:GetUnitData("target", true)
			NeedsUpdate = false
		end
	end
end

LLA:SetScript("OnEvent", function() LLA:OnEvent(event, arg1, arg2) end)
LLA:SetScript("OnUpdate", LLA.OnUpdate)