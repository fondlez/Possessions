--[[
Possessions: AddOn to keep track of all of your items.

License:
	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program (see GLP.txt); if not, write to the Free Software
	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA	02110-1301, USA.
]]

local _G = getfenv(0)
local tonumber = _G.tonumber
local pairs = _G.pairs
local GetItemInfo = _G.GetItemInfo
local GetInventoryItemLink = _G.GetInventoryItemLink
local string = _G.string
local DEFAULT_CHAT_FRAME = _G.DEFAULT_CHAT_FRAME


local POSSESSIONS_VERSION = GetAddOnMetadata("Possessions","Version"):match("%d+\.%d*\.%d*")

local CHARACTER_NUM_ITEMS = 19

local POSSESSIONS_ITEMS_TOSHOW = 15
local POSSESSIONS_ITEMS_HEIGHT = 16

local Possessions_INVENTORY_SLOT_LIST = {
	{ name = "HeadSlot" },
	{ name = "NeckSlot" },
	{ name = "ShoulderSlot" },
	{ name = "BackSlot" },
	{ name = "ChestSlot" },
	{ name = "ShirtSlot" },
	{ name = "TabardSlot" },
	{ name = "WristSlot" },
	{ name = "HandsSlot" },
	{ name = "WaistSlot" },
	{ name = "LegsSlot" },
	{ name = "FeetSlot" },
	{ name = "Finger0Slot" },
	{ name = "Finger1Slot" },
	{ name = "Trinket0Slot" },
	{ name = "Trinket1Slot" },
	{ name = "MainHandSlot" },
	{ name = "SecondaryHandSlot" },
	{ name = "RangedSlot" },
}

local realmName, playerName, playerFaction, playerGuild

local searchString
local searchChar
local searchLoc
local searchSlot
local searchType
local searchSubType

local characterTable = { }
local DisplayIndices = { }
local TempTable = { }
local PlayerItemTable
local info = {}

local lastScan = 0
local GuildBankUpdateCount = 0

local INDEX_LINK = 0
local INDEX_NAME = 1
local INDEX_ICON = 2
local INDEX_QUANTITY = 3
local INDEX_RARITY = 4
local INDEX_LOCS = 5

local POSS_INVENTORY_CONTAINER = 0
local POSS_BANK_CONTAINER = -1
local POSS_PLAYER_CONTAINER = -2
local POSS_MAIL_CONTAINER = -3
local POSS_KEYRING_CONTAINER = -4
local POSS_PLAYERBAG_CONTAINER = -5
local POSS_BANKBAG_CONTAINER = -6
local POSS_GUILDBANK_CONTAINER = -7

local sendMailItems = {}
local sendMailItemQuantities = {}
local sendMailMoney = 0
local sendMailRecipient = ""


local possessionsLocationNames = {
		{container = POSS_BANK_CONTAINER, name = PossessionsLocale.TEXT_BANK},
		{container = POSS_MAIL_CONTAINER, name = PossessionsLocale.TEXT_INBOX},
		{container = POSS_INVENTORY_CONTAINER, name = PossessionsLocale.TEXT_INVENTORY},
		{container = POSS_KEYRING_CONTAINER, name = PossessionsLocale.TEXT_KEYRING},
		{container = POSS_PLAYER_CONTAINER, name = PossessionsLocale.TEXT_PLAYER},
		{container = POSS_PLAYERBAG_CONTAINER, name = PossessionsLocale.TEXT_PLAYERBAGS},
		{container = POSS_BANKBAG_CONTAINER, name = PossessionsLocale.TEXT_BANKBAGS},
		{container = POSS_GUILDBANK_CONTAINER, name = PossessionsLocale.TEXT_GUILDBANK}
};

local possessionsSlotNames = {
	{slot = INVTYPE_AMMO,				name = "INVTYPE_AMMO"}, --Ammo
	{slot = INVTYPE_CLOAK, 				name = "INVTYPE_CLOAK"}, --Back
	{slot = INVTYPE_BAG, 				name = "INVTYPE_BAG"}, --Bag
	{slot = INVTYPE_RANGED, 			name = "INVTYPE_RANGED"}, --Bow
	{slot = INVTYPE_CHEST, 				name = "INVTYPE_CHEST"}, --Chest
	{slot = INVTYPE_FEET, 				name = "INVTYPE_FEET"}, --Feet
	{slot = INVTYPE_FINGER, 			name = "INVTYPE_FINGER"}, --Finger
	{slot = INVTYPE_HAND, 				name = "INVTYPE_HAND"}, --Hands
	{slot = INVTYPE_HEAD, 				name = "INVTYPE_HEAD"}, --Head
	{slot = INVTYPE_HOLDABLE, 			name = "INVTYPE_HOLDABLE"}, --Held in Off-hand
	{slot = INVTYPE_LEGS, 				name = "INVTYPE_LEGS"}, --Legs
	{slot = INVTYPE_WEAPONMAINHAND,		name = "INVTYPE_WEAPONMAINHAND"}, --Main Hand
	{slot = INVTYPE_NECK, 				name = "INVTYPE_NECK"}, --Neck
	{slot = INVTYPE_WEAPONOFFHAND,		name = "INVTYPE_WEAPONOFFHAND"}, --Off Hand
	{slot = INVTYPE_WEAPON, 			name = "INVTYPE_WEAPON"}, --One-Hand
	{slot = INVTYPE_RELIC, 				name = "INVTYPE_RELIC"}, --Relic
	{slot = INVTYPE_ROBE, 				name = "INVTYPE_ROBE"}, --Robe
	{slot = INVTYPE_SHIELD, 			name = "INVTYPE_SHIELD"}, --Shield
	{slot = INVTYPE_SHOULDER, 			name = "INVTYPE_SHOULDER"}, --Shoulder
	{slot = INVTYPE_BODY, 				name = "INVTYPE_BODY"}, --Shirt
	{slot = INVTYPE_TABARD, 			name = "INVTYPE_TABARD"}, --Tabard
	{slot = INVTYPE_THROWN, 			name = "INVTYPE_THROWN"}, --Thrown
	{slot = INVTYPE_TRINKET, 			name = "INVTYPE_TRINKET"}, --Trinket
	{slot = INVTYPE_2HWEAPON, 			name = "INVTYPE_2HWEAPON"}, --Two-Hand
	{slot = INVTYPE_WAIST, 				name = "INVTYPE_WAIST"}, --Waist
	{slot = INVTYPE_RANGEDRIGHT, 			name = "INVTYPE_RANGEDRIGHT"}, --Wand/Gun/Crossbow
	{slot = INVTYPE_WRIST, 				name = "INVTYPE_WRIST"} --Wrist
};

local possessionsTypes = {}
local possessionsSubTypes = PossessionsLocale.TYPE_TABLE

function Possessions_SlotDropDown_OnClick(self)
	local id = self:GetID()
	UIDropDownMenu_SetSelectedID(Possessions_SlotDropDown, id)
	
	if( id > 1) then
		searchSlot = possessionsSlotNames[id-1].name
	else
		searchSlot = nil
	end
	
	Possessions_Update()
end

function Possessions_SlotDropDown_Initialize(self)
	info.text = PossessionsLocale.TEXT_ALLSLOTS
	info.func = Possessions_SlotDropDown_OnClick
	info.checked = nil
	UIDropDownMenu_AddButton(info)

	for i,slotname in pairs(possessionsSlotNames) do
		if slotname.name == "INVTYPE_SHIELD" then
			info.text = SHIELDSLOT
		elseif slotname.name == "INVTYPE_RANGED" then
			info.text = "Bow"
		elseif slotname.name == "INVTYPE_RANGEDRIGHT" then
			info.text = "Wand/Gun/Crossbow"
		elseif slotname.name == "INVTYPE_ROBE" then
			info.text = "Robe"
		else
			info.text = slotname.slot
		end
		info.func = Possessions_SlotDropDown_OnClick
		info.checked = nil
		UIDropDownMenu_AddButton(info)
	end
end

function Possessions_SlotDropDown_OnShow(self)
	UIDropDownMenu_Initialize(self, Possessions_SlotDropDown_Initialize)
	UIDropDownMenu_SetSelectedID(self, 1)
	UIDropDownMenu_SetWidth(self, 90, 0)
end

function Possessions_LocDropDown_OnClick(self)
	local id = self:GetID();
	UIDropDownMenu_SetSelectedID(Possessions_LocDropDown, id);

	if( id > 1) then
		searchLoc = possessionsLocationNames[id-1].container;
	else
		searchLoc = nil;
	end

	Possessions_Update();
end
function Possessions_LocDropDown_Initialize(self)
	info.text = PossessionsLocale.TEXT_ALLLOCS;
	info.func = Possessions_LocDropDown_OnClick;
	info.checked = nil
	UIDropDownMenu_AddButton(info);

	for i,location in pairs(possessionsLocationNames) do
		info.text = location.name;
		info.func = Possessions_LocDropDown_OnClick;
		info.checked = nil
		UIDropDownMenu_AddButton(info);
	end
end

function Possessions_LocDropDown_OnShow(self)
	UIDropDownMenu_Initialize(self, Possessions_LocDropDown_Initialize);
	UIDropDownMenu_SetSelectedID(self, 1);
	UIDropDownMenu_SetWidth(self, 90, 0);
end

function Possessions_CharDropDown_OnClick(self)
	local id = self:GetID();
	UIDropDownMenu_SetSelectedID(Possessions_CharDropDown, id);
	
	if( id > 1) then
		searchChar = characterTable[id-1];
	else
		searchChar = nil;
	end
	Possessions_Update();
end
function Possessions_CharDropDown_Initialize(self)
	info.text = PossessionsLocale.TEXT_ALLCHARS
	info.func = Possessions_CharDropDown_OnClick
	info.checked = nil
	UIDropDownMenu_AddButton(info);

	for i = 1, #characterTable do
		info.text = characterTable[i]
		info.func = Possessions_CharDropDown_OnClick
		info.checked = nil
		UIDropDownMenu_AddButton(info)
	end

end
function Possessions_CharDropDown_OnShow(self)
	UIDropDownMenu_Initialize(self, Possessions_CharDropDown_Initialize);
	UIDropDownMenu_SetSelectedID(self, 1);
	UIDropDownMenu_SetWidth(self, 90, 0);
end

function Possessions_TypeDropDown_OnClick(self)
	local id = self:GetID();
	UIDropDownMenu_SetSelectedID(Possessions_TypeDropDown, id);

	if( id > 1) then
		searchType = possessionsTypes[id-1];
	else
		searchType = nil;
	end

	Possessions_Update();
end
function Possessions_TypeDropDown_Initialize(self)
	info.text = PossessionsLocale.TEXT_ALLTYPES;
	info.func = Possessions_TypeDropDown_OnClick;
	info.checked = nil
	UIDropDownMenu_AddButton(info);

	for i = 1, #possessionsTypes, 1 do
		info.text = possessionsTypes[i];
		info.func = Possessions_TypeDropDown_OnClick;
		info.checked = nil
		UIDropDownMenu_AddButton(info);
	end
end
function Possessions_TypeDropDown_OnShow(self)
	UIDropDownMenu_Initialize(self, Possessions_TypeDropDown_Initialize);
	UIDropDownMenu_SetSelectedID(self, 1);
	UIDropDownMenu_SetWidth(self, 207, 0);
end

function Possessions_SubTypeDropDown_OnClick(self)
	
	searchType = self.value["Level1_Key"];
	searchSubType = self.value["Sublevel_Key"];

	if (searchType and searchSubType) then
		Possessions_SubTypeDropDownText:SetText(self.value["Level1_Key"].." - "..self.value["Sublevel_Key"]);
	else
		Possessions_SubTypeDropDownText:SetText(self.value["Level1_Key"] or PossessionsLocale.TEXT_ALLTYPES);
	end
	DropDownList1:Hide();
	Possessions_Update();
end
function Possessions_SubTypeDropDown_Initialize(self, level)
	level = level or 1;
	
	if (level == 1) then
		local subInfo = UIDropDownMenu_CreateInfo();
		subInfo.notCheckable = true;
		subInfo.text = PossessionsLocale.TEXT_ALLTYPES;
		subInfo.func = Possessions_SubTypeDropDown_OnClick;
		UIDropDownMenu_AddButton(subInfo, level);

		for key, subarray in pairs(possessionsSubTypes) do
			local subInfo = UIDropDownMenu_CreateInfo();
			if #subarray > 1 then
				subInfo.hasArrow = true;
			end
			subInfo.notCheckable = true;
			subInfo.text = key;
			subInfo.func = Possessions_SubTypeDropDown_OnClick;
			subInfo.value = {
				["Level1_Key"] = key;
			};
			UIDropDownMenu_AddButton(subInfo, level);
		end
	end

	if (level == 2) then
		local Level1_Key = UIDROPDOWNMENU_MENU_VALUE["Level1_Key"];
		local subarray = possessionsSubTypes[Level1_Key];
		for key, value in ipairs(subarray) do
			local subInfo = UIDropDownMenu_CreateInfo();
			subInfo.hasArrow = false; -- no submenus this time
			subInfo.notCheckable = true;
			subInfo.text = value;
			subInfo.func = Possessions_SubTypeDropDown_OnClick;
			subInfo.value = {
				["Level1_Key"] = Level1_Key;
				["Sublevel_Key"] = value;
			};
			UIDropDownMenu_AddButton(subInfo, level);
		end
	end
end
function Possessions_SubTypeDropDown_OnShow(self)
	UIDropDownMenu_Initialize(self, Possessions_SubTypeDropDown_Initialize);
	UIDropDownMenu_SetWidth(self, 207, 0);
end

function Possessions_FixLink(link)
	if( not link ) then
		return nil
	end
	if string.match(link, "item:") then
		return link
	end

	local ncolon = select(2,string.gsub(link, ":", ""))
	
	if( ncolon == 3 ) then
		return "item:" .. string.gsub(link, "(%-?%d+):(.*):(.*):(%-?%d+)", "%1:%2:0:0:0:0:%3:%4")
	elseif( ncolon < 7 ) then	--Link is too short
		return "item:" .. link .. string.rep(":0",7-ncolon)
	elseif( ncolon > 7 ) then	--Link is too long for some reason
		return "item:" .. string.match(link, "^(%-?%d+:.*:.*:.*:.*:.*:.*:%-?%d+)")
	else
		return "item:" .. link
	end
end

function Possessions_BuildLink(item)
	return select(4, GetItemQualityColor(item[INDEX_RARITY])) .."|Hitem:".. Possessions_FixLink(item[INDEX_LINK]) .. "|h["..item[INDEX_NAME].."]|h|r";
end

function Possessions_CompressLink(link)
	if not link then return end
	local itemLink

	local _, _, itemID, ench, j1, j2, j3, j4, suffixID, uniqueID = string.find(link, "(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+)")

	j1 = tonumber(j1)
	j2 = tonumber(j2)
	j3 = tonumber(j3)
	j4 = tonumber(j4)
	suffixID = tonumber(suffixID)
	if (suffixID < 0) then
		uniqueID = bit.band( tonumber(uniqueID), 65535)
	end
	
	if(j1 == 0 and j2 == 0 and j3 == 0 and j4 == 0) then				--If there are no occupied Jewel slots
		if(tonumber(ench) == 0 and suffixID == 0) then						--If there is no enchant nor suffix
			itemLink = itemID							 								--Store itemID only to save memory
		elseif(suffixID < 0) then												--If the suffixID is negative, store the full uniqueID
			itemLink = itemID..":"..ench..":"..suffixID..":"..uniqueID	--Store short format
		else
			itemLink = itemID..":"..ench..":"..suffixID..":0"		--Use the pre 2.0.1 style itemString to save memory
		end
	elseif(suffixID < 0) then --Some jewel slots are occupied and the suffixid is negative
		itemLink = itemID..":"..ench..":"..j1..":"..j2..":"..j3..":"..j4..":"..suffixID..":"..uniqueID	--Full link with uniqueID needed
	else
		itemLink = itemID..":"..ench..":"..j1..":"..j2..":"..j3..":"..j4..":"..suffixID	--Full link needed
	end

	return itemLink
end

function Possessions_StoreLink(bagnum, containerItemNum, link)
	if(link) then
		local name, _, rarity = GetItemInfo(link)
		if name then
			if not PlayerItemTable[bagnum] then
				PlayerItemTable[bagnum] = { }
				PlayerItemTable[bagnum][containerItemNum] = {}
			elseif not PlayerItemTable[bagnum][containerItemNum] then
				PlayerItemTable[bagnum][containerItemNum] = {}
			end

			--Only assign values if they have changed. May or may not help performance
			local compressedLink = Possessions_CompressLink(link)
			if PlayerItemTable[bagnum][containerItemNum][INDEX_LINK] ~= compressedLink then
				PlayerItemTable[bagnum][containerItemNum][INDEX_LINK] = compressedLink
				PlayerItemTable[bagnum][containerItemNum][INDEX_NAME] = name
				PlayerItemTable[bagnum][containerItemNum][INDEX_RARITY] = rarity
			end

			return true
		end
	end
	return false
end

function Possessions_ReloadBag(bagnum)
	local link
	local maxContainerItems = GetContainerNumSlots(bagnum)
	local bagLink	= nil
	local bagSlotContainer = nil


	local storebagnum = bagnum
	--Done in this manner to preserve backwards compatibility with SavedVariables from Oystein's versions
	if ( bagnum == KEYRING_CONTAINER ) then
		storebagnum = POSS_KEYRING_CONTAINER
	elseif ( bagnum > 0 and bagnum <= NUM_BAG_SLOTS ) then
		--This is an inventory bag, store its info
		bagLink = GetInventoryItemLink("player",ContainerIDToInventoryID(bagnum))
		bagSlotContainer = POSS_PLAYERBAG_CONTAINER
	elseif ( bagnum > NUM_BAG_SLOTS ) then
		--This is a bank bag, store its info
		bagLink = GetInventoryItemLink("player",ContainerIDToInventoryID(bagnum))
		bagSlotContainer = POSS_BANKBAG_CONTAINER
	end

	--Try to store the bag itself
	if( Possessions_StoreLink(bagSlotContainer, bagnum, bagLink) ) then
		PlayerItemTable[bagSlotContainer][bagnum][INDEX_QUANTITY] = 1
		if( Possessions_IsLiteMode() == false ) then
			PlayerItemTable[bagSlotContainer][bagnum][INDEX_ICON] = select(10, GetItemInfo(bagLink))
		end
	end

	if ( maxContainerItems > 0) then
		if not PlayerItemTable[storebagnum] then
			PlayerItemTable[storebagnum] = { }
		end

		local storeBag = PlayerItemTable[storebagnum]

		local storeContainerItemNum
		for containerItemNum = 1, maxContainerItems do
			storeContainerItemNum = containerItemNum
			link = GetContainerItemLink(bagnum, containerItemNum)
			if( link ) then
				local compressedLink = Possessions_CompressLink(link)
				--Try to find an existing stack of this item type in the same bag to use

				if( Possessions_IsLiteMode() == true ) then --Only search for existing stack if Lite Mode is enabled
					--Look through previous bag contents
					for prevContItemNum=1, containerItemNum-1 do
						if storeBag[prevContItemNum] then
							if storeBag[prevContItemNum][INDEX_LINK] == compressedLink then -- and storeBag[prevContItemNum][INDEX_QUANTITY] > 0 then --Don't want quantity to be 0 since we might put stuff into a slot that will soon be overwritten by new contents
								storeContainerItemNum = prevContItemNum
								break
							end
						end
					end
				end
				if storeContainerItemNum ~= containerItemNum then
					storeBag[storeContainerItemNum][INDEX_QUANTITY] = storeBag[storeContainerItemNum][INDEX_QUANTITY] + select(2,GetContainerItemInfo(bagnum, containerItemNum))
					if storeBag[containerItemNum] then
						storeBag[containerItemNum] = nil
					end
				else	--Did not find existing stack within same bag

					--Store the new link normally
					if( Possessions_StoreLink(storebagnum, containerItemNum, link) ) then
						storeBag[containerItemNum][INDEX_ICON], storeBag[containerItemNum][INDEX_QUANTITY] = GetContainerItemInfo(bagnum, containerItemNum) --select(2,GetContainerItemInfo(bagnum, containerItemNum))
						if( Possessions_IsLiteMode() == true ) then
							storeBag[containerItemNum][INDEX_ICON] = nil
						end
					end

				end

			else
				if storeBag[containerItemNum] and storeBag[containerItemNum][INDEX_QUANTITY] > 0 then
					storeBag[containerItemNum] = nil
				end
			end
		end
	end
end

function Possessions_Hide()
	HideUIPanel(Possessions_Frame)
end

function Possessions_Show()
	Possessions_ClearDropDowns()
	Possessions_Update()

	ShowUIPanel(Possessions_Frame)
	Possessions_SearchBox:SetFocus();
end

function Possessions_Toggle()
	if( Possessions_Frame:IsVisible() ) then
		Possessions_Hide()
	else
		Possessions_Show()
	end
end

function Possessions_SlashCommandHandler(msg)
	if (msg == "") then
		Possessions_Toggle()
		return
	end

	local command, argument = msg:match("^(%S+)%s*(.-)$")
	command = (command or ""):lower()
	argument = (argument or "")

	if(command == "-clear") then
		if( not PossessionsData[realmName][argument] ) then
			argument = argument:lower()
		end

		if( PossessionsData[realmName][argument] ) then
			if(argument == playerName) then
				DEFAULT_CHAT_FRAME:AddMessage("[Possessions]: Cannot clear data for the current character.")
			else
				PossessionsData[realmName][argument] = nil
				characterTable = { }
				for index, value in pairs(PossessionsData[realmName]) do
					table.insert(characterTable, Possessions_Capitalize(index))
				end
				table.sort(characterTable)
				DEFAULT_CHAT_FRAME:AddMessage("[Possessions]: Data for '"..argument.."' cleared.")
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("[Possessions]: No data stored for '"..Possessions_Capitalize(argument).."'.")
		end
	elseif command == "-validate" and argument == "all" then
		--/poss -validate all
		local link
		local numValidated = 0
		for character, charTable in pairs(PossessionsData[realmName]) do
			for index, value in pairs(charTable.items) do
				for index2, value2 in pairs(value) do
					if value2[INDEX_LINK] then
						link = Possessions_FixLink( value2[INDEX_LINK] )
						if not GetItemInfo(link) then
							PossScanningTooltip:ClearLines()
							PossScanningTooltip:SetHyperlink(link)
							numValidated = numValidated + 1
						end
					end
				end
			end
		end
		DEFAULT_CHAT_FRAME:AddMessage("[Possessions]: Validated "..numValidated.." items.")
	elseif command == "-globaltooltip" then
		if argument == "on" or argument == "enable" then
			PossessionsData.config.globalTooltip = true
			DEFAULT_CHAT_FRAME:AddMessage("[Possessions]: -globaltooltip on")
		elseif argument == "off" or argument == "disable" then
			PossessionsData.config.globalTooltip = false
			DEFAULT_CHAT_FRAME:AddMessage("[Possessions]: -globaltooltip off")
		else
			DEFAULT_CHAT_FRAME:AddMessage(
				format("[Possessions]: -globaltooltip %s", 
					PossessionsData.config.globalTooltip and "on" or "off")
			)
		end
	elseif command == "-forcetooltip" then
		if argument == "on" or argument == "enable" then
			PossessionsData.config.forcedGlobalTooltip = true
			DEFAULT_CHAT_FRAME:AddMessage("[Possessions]: -forcetooltip on")
		elseif argument == "off" or argument == "disable" then
			PossessionsData.config.forcedGlobalTooltip = false
			DEFAULT_CHAT_FRAME:AddMessage("[Possessions]: -forcetooltip off")
		else
			DEFAULT_CHAT_FRAME:AddMessage(
				format("[Possessions]: -forcetooltip %s", 
					PossessionsData.config.forcedGlobalTooltip and "on" or "off")
			)
		end
	else
		local itemName = GetItemInfo(msg)
		Possessions_SearchBox:SetText(itemName or msg or "")

		Possessions_Show()
	end
end

function Possessions_ClearDropDowns()
	searchChar = nil;
	searchLoc = nil;
	searchSlot = nil;
	searchType = nil;
	searchSubType = nil;

	UIDropDownMenu_SetSelectedID(Possessions_CharDropDown, 0);
	UIDropDownMenu_SetSelectedID(Possessions_LocDropDown, 0);
	UIDropDownMenu_SetSelectedID(Possessions_SlotDropDown, 0);
	UIDropDownMenu_SetSelectedID(Possessions_SubTypeDropDown, 0);

	Possessions_CharDropDownText:SetText(PossessionsLocale.TEXT_ALLCHARS);
	Possessions_LocDropDownText:SetText(PossessionsLocale.TEXT_ALLLOCS);
	Possessions_SlotDropDownText:SetText(PossessionsLocale.TEXT_ALLSLOTS);
	Possessions_SubTypeDropDownText:SetText(PossessionsLocale.TEXT_ALLTYPES);
end

function Possessions_ResetButton_OnClick(self)
	Possessions_ClearDropDowns()
	Possessions_SearchBox:SetText("")
	
	Possessions_Update()
end

function Possessions_Update()
	FauxScrollFrame_SetOffset(Possessions_IC_ScrollFrame, 0);
	_G.Possessions_IC_ScrollFrameScrollBar:SetValue(0);	
	
	local msg = Possessions_SearchBox:GetText();
	
	if( msg and msg ~= "" ) then
		searchString = string.lower(msg);
	else
		searchString = nil;
	end
	
	Possessions_BuildDisplayIndices();
	Possessions_UpdateView();
end

function Possessions_BuildDisplayIndices()
	local link
	local location
	local slot = nil
	local subtype = nil
	local itemType = nil
	local theLink = nil
	local textResult

	for link, value in pairs(TempTable) do
		if value[INDEX_QUANTITY] > 0 then
			TempTable[link][INDEX_QUANTITY] = 0
			for charName, locations in pairs(value[INDEX_LOCS]) do
				for location, quant in pairs(locations) do
					if quant > 0 then
						TempTable[link][INDEX_LOCS][charName][location] = 0
					end
				end
			end
		end
	end

	for index, value in pairs(PossessionsData[realmName]) do
		if (not value.faction or value.faction == playerFaction) then
			for index2, value2 in pairs(value.items) do
				for index3, value3 in pairs(value2) do

					if value3[INDEX_LINK] then
						link = Possessions_FixLink( value3[INDEX_LINK] )
	
						textResult = false
						_, theLink, _, _, _, itemType, subtype, _, slot = GetItemInfo( link )

						--See if the item is in a guild bank
						
						
						--Check if the name matches, or the tooltip lines if fulltext searching is enabled
						if ( (Possessions_SearchGuildBank() == true) or (POSS_GUILDBANK_CONTAINER~=index2) ) then
							if not searchString or searchString == "" then
								textResult = true
							elseif string.find(string.lower(value3[INDEX_NAME]), searchString) then
								textResult = true
							elseif Possessions_SearchFullText() == true and theLink then
								PossScanningTooltip:ClearLines()
								PossScanningTooltip:SetHyperlink(theLink)
								for i=1,PossScanningTooltip:NumLines() do
									if string.find(string.lower( _G["PossScanningTooltipTextLeft"..i]:GetText() or "" ), searchString) or
											string.find(string.lower( _G["PossScanningTooltipTextRight"..i]:GetText() or "" ), searchString) then
										textResult = true
										break
									end
								end
							end
						end
	
						if( textResult
							and (not searchChar or searchChar == Possessions_Capitalize(index))
							and (not searchLoc or searchLoc == Possessions_Bag2Loc(index2))
							and (not searchSlot or searchSlot == slot)
							and (not searchType or searchType == itemType)
							and (not searchSubType or searchSubType == subtype)
							)	then
	
							--Check if an entry has been created yet for the item. Items are bunched up by name
							if (not TempTable[link]) then
								TempTable[link] = { }
								TempTable[link][INDEX_NAME] = value3[INDEX_NAME]
								TempTable[link][INDEX_RARITY] = value3[INDEX_RARITY]
								TempTable[link][INDEX_ICON] = value3[INDEX_ICON]
								TempTable[link][INDEX_QUANTITY] = 0
								TempTable[link][INDEX_LOCS] = { }
							elseif( TempTable[link][INDEX_RARITY] == -1 ) then
								TempTable[link][INDEX_RARITY] = value3[INDEX_RARITY]
							end
	
							--Increment quantity held
							TempTable[link][INDEX_QUANTITY] = TempTable[link][INDEX_QUANTITY] + value3[INDEX_QUANTITY]
	
							if( not TempTable[link][INDEX_LOCS][index] ) then
								TempTable[link][INDEX_LOCS][index] = { }
							end
	
							location = Possessions_Bag2Loc(index2)
	
							TempTable[link][INDEX_LOCS][index][location] = (TempTable[link][INDEX_LOCS][index][location] or 0) + value3[INDEX_QUANTITY]
						end
					end --if value3[INDEX_LINK]
				end
			end
		end
	end

	local iNew = 1
	--Copy search results from TempTable to Display Table
	for index, value in pairs(TempTable) do
		if value[INDEX_QUANTITY] > 0 then
			if not DisplayIndices[iNew] then
				DisplayIndices[iNew] = { }
			end
			DisplayIndices[iNew][INDEX_LINK] = index
			DisplayIndices[iNew][INDEX_NAME] = value[INDEX_NAME]
			DisplayIndices[iNew][INDEX_RARITY] = value[INDEX_RARITY]
			DisplayIndices[iNew][INDEX_QUANTITY] = value[INDEX_QUANTITY]
			DisplayIndices[iNew][INDEX_ICON] = value[INDEX_ICON]
			DisplayIndices[iNew][INDEX_LOCS] = value[INDEX_LOCS]
			
			--Copy location data to DisplayIndices and Reset quantities in TempTable to 0 for next search
			iNew = iNew + 1
		end
	end
	DisplayIndices.OnePastEnd = iNew	--Keep track of number of Indices

	--Hide extra stuff from previous searches by setting the quantity to 0
	while(iNew <= #DisplayIndices ) do
		DisplayIndices[iNew][INDEX_QUANTITY] = 0
		iNew = iNew + 1
	end

	--Sort functions are modified to keep entries with Quantity=0 at the end of the list
	if( POSSESSIONS_Sort_Name == 1) then
		table.sort(DisplayIndices, Possessions_NameComparison);
	else
		table.sort(DisplayIndices, Possessions_RarityComparison);
	end
	Possessions_CountMoney();
end

function Possessions_UpdateView()
	local item, itemIndex, buttonPrefix, iItem

	FauxScrollFrame_Update(Possessions_IC_ScrollFrame, DisplayIndices.OnePastEnd-1, POSSESSIONS_ITEMS_TOSHOW, POSSESSIONS_ITEMS_HEIGHT)
	for iItem = 1, POSSESSIONS_ITEMS_TOSHOW, 1 do
		itemIndex = iItem + FauxScrollFrame_GetOffset(Possessions_IC_ScrollFrame)
		
		buttonPrefix = "POSSESSIONS_BrowseButton"..iItem

		if( itemIndex < DisplayIndices.OnePastEnd ) then
			item = DisplayIndices[itemIndex]

			if( item[INDEX_RARITY] ~= -1) then
				_G[buttonPrefix.."Name"]:SetText( select(4,GetItemQualityColor(item[INDEX_RARITY])) .. item[INDEX_NAME].."|r")
			else
				_G[buttonPrefix.."Name"]:SetText(item[INDEX_NAME])
			end

			_G[buttonPrefix.."Quantity"]:SetText(item[INDEX_QUANTITY])

			--Find the item's icon
			_G[buttonPrefix.."ItemIconTexture"]:SetTexture( item[INDEX_ICON] or (item[INDEX_LINK] and select(10, GetItemInfo( item[INDEX_LINK] ))) or "Interface\\Icons\\INV_Misc_QuestionMark")
			_G[buttonPrefix]:Show()
		else
			_G[buttonPrefix]:Hide()
		end
	end
end

function Possessions_Bag2Loc(bag)
	if( bag < -1 ) then
		return bag
	elseif( bag > NUM_BAG_SLOTS or bag == -1 ) then
		return POSS_BANK_CONTAINER
	else
		-- 0 to NUM_BAG_SLOTS is inventory
		return POSS_INVENTORY_CONTAINER
	end
end

function Possessions_RarityComparison(elem1, elem2)
	if elem1[INDEX_QUANTITY] == 0 and elem2[INDEX_QUANTITY] == 0 then
		return elem1[INDEX_NAME] < elem2[INDEX_NAME]
	elseif elem1[INDEX_QUANTITY] == 0 then
		return false
	elseif elem2[INDEX_QUANTITY] == 0 then
		return true
	elseif( elem1[INDEX_RARITY] == elem2[INDEX_RARITY] ) then
		return elem1[INDEX_NAME] < elem2[INDEX_NAME]
	else
		return elem1[INDEX_RARITY] > elem2[INDEX_RARITY]
	end
end


function Possessions_NameComparison(elem1, elem2)
	if elem1[INDEX_QUANTITY] == 0 and elem2[INDEX_QUANTITY] == 0 then
		return elem1[INDEX_NAME] < elem2[INDEX_NAME]
	elseif elem1[INDEX_QUANTITY] == 0 then
		return false
	elseif elem2[INDEX_QUANTITY] == 0 then
		return true
	else
		return elem1[INDEX_NAME] < elem2[INDEX_NAME]
	end
end


--------------------------------------------------
-- Handle button clicks
--------------------------------------------------
function Possessions_Click(self, button)
	local id = self:GetID();

	if(id == 0) then
		id = self:GetParent():GetID();
	end

	local offset = FauxScrollFrame_GetOffset(Possessions_IC_ScrollFrame);
	local item = DisplayIndices[id + offset];

	if (item[INDEX_LINK]) then
		local itemLink	= select(2,GetItemInfo( item[INDEX_LINK] ))	--Don't need to FixLink this since it is fixed for DisplayIndices
		if( button == "RightButton" ) then
			if(itemLink) then
				DEFAULT_CHAT_FRAME:AddMessage("[Possessions]: "..itemLink..PossessionsLocale.SAFE_MESSAGE)
			else
				GameTooltip:SetHyperlink( item[INDEX_LINK] )
				--Saeris's LootLink color!
				DEFAULT_CHAT_FRAME:AddMessage("[Possessions]: "..PossessionsLocale.QUERY_MESSAGE..Possessions_BuildLink(item)..".")
			end
		elseif( button == "LeftButton" ) then
			if not itemLink then return end
			if IsShiftKeyDown() then
				if (WIM and WIM.EditBoxInFocus) then
					WIM.EditBoxInFocus:Insert(itemLink)
				else
					local editbox = ChatEdit_ChooseBoxForSend()

					ChatEdit_ActivateChat(editbox)

					if editbox then
						editbox:Insert(itemLink)
					end
				end
			elseif IsControlKeyDown() then
				DressUpItemLink(itemLink)
			else
				SetItemRef(itemLink)
				ItemRefTooltip:Show()
			end
		end
	end
end

local PossItemTooltip = CreateFrame("GameTooltip",
	"PossessionsItemTooltip", UIParent, "GameTooltipTemplate")

function Possessions_ItemButton_OnEnter(self)
	local id = self:GetID()
	local itemLink
	local itemStackCount
	
	if(id == 0) then
		id = self:GetParent():GetID()
	end
	
	local offset = FauxScrollFrame_GetOffset(Possessions_IC_ScrollFrame)
	local item = DisplayIndices[id + offset]
	
	PossItemTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")

	_, itemLink, _, _, _, _, _, itemStackCount = GetItemInfo( item[INDEX_LINK] )
	
	if( itemLink ) then
		PossItemTooltip:SetHyperlink(itemLink)

		if (IsAddOnLoaded("RecipeBook")) then
			RecipeBook_DoHookedFunction(PossItemTooltip, itemLink)
		end

	else
		PossItemTooltip:AddLine(item[INDEX_NAME].." ("..PossessionsLocale.ERRORTOOLTIP_L1..")")
		if( item[INDEX_LINK]) then
			PossItemTooltip:AddLine(PossessionsLocale.ERRORTOOLTIP_L2..item[INDEX_LINK])
			PossItemTooltip:AddLine(PossessionsLocale.ERRORTOOLTIP_L3, 1, 1, 1, 1)
			PossItemTooltip:AddLine(PossessionsLocale.ERRORTOOLTIP_L4, nil, nil, nil, 1)	--Last 1 tells the tooltip to wrap the text
		end
	end

	local location
	local adj
	local texture
	local line
	
	PossItemTooltip:AddLine(" ");
	
	for charName, value in pairs(item[INDEX_LOCS]) do
		for index2, quantity in pairs(value) do
			if quantity > 0 then	--Make sure that the quantity is greater than 0
				adj = " in "
				if( index2 == POSS_BANK_CONTAINER ) then
					location = "bank"
					texture = "Interface\\Icons\\INV_Misc_Bag_16"
				elseif( index2 == POSS_KEYRING_CONTAINER ) then
					location = "keyring"
					texture = "Interface\\Icons\\INV_Misc_Key_14"
				elseif( index2 == POSS_PLAYER_CONTAINER ) then
					location = "person"
					adj = " on "
					texture = "Interface\\Icons\\INV_Misc_Bag_09_Blue"
				elseif( index2 == POSS_INVENTORY_CONTAINER ) then
					location = "inventory"
					texture = "Interface\\Icons\\INV_Misc_Bag_08"
				elseif( index2 == POSS_MAIL_CONTAINER ) then
					location = "Inbox"
					texture = "Interface\\Icons\\INV_Letter_02"
				elseif( index2 == POSS_PLAYERBAG_CONTAINER ) then
					location = "Inventory Bag Slots"
					texture = "Interface\\Icons\\INV_Misc_Bag_EnchantedMageweave"	--FIXME
				elseif( index2 == POSS_BANKBAG_CONTAINER ) then
					location = "Bank Bag Slots"
					texture = "Interface\\Icons\\INV_Misc_Bag_15"
				elseif( index2 == POSS_GUILDBANK_CONTAINER ) then
					location = "Guild Bank"
					texture = "Interface\\Icons\\INV_Misc_Bag_14"
				else
					location = "unknown"
					texture = "Interface\\Icons\\INV_Misc_QuestionMark"
				end
	
				line = quantity .. adj .. Possessions_Capitalize(charName) .. "'s " .. location
				PossItemTooltip:AddLine(line)
				PossItemTooltip:AddTexture(texture)
			end
		end
	end

	if( itemStackCount ) then
		PossItemTooltip:AddLine("Stack Count: "..itemStackCount)
	end
	
	PossItemTooltip:Show()
end

function Possessions_Capitalize(str)
	--Capitalize only the first letter
	return string.upper(string.sub(str,1,1)) .. string.sub(str,2)
end

function Possessions_ItemButton_OnLeave(self)
	PossItemTooltip:Hide()
end

function Possessions_convertDB0to1()
	DEFAULT_CHAT_FRAME:AddMessage("[Possessions]: Updating data to new format")
	local tempTable = { }
	for item, value in pairs(PossessionsData) do
		tempTable[item] = { }
		DEFAULT_CHAT_FRAME:AddMessage("[Possessions]: Server: " .. item)
		for item2, value2 in pairs(value) do
			tempTable[item][item2] = { }
			tempTable[item][item2].items = { }
			DEFAULT_CHAT_FRAME:AddMessage("[Possessions]: Char: " .. item2)
			for item3, value3 in pairs(value2) do
				tempTable[item][item2].items[item3] = value3
			end			
		end
	end
	PossessionsData = tempTable
	
	for item, value in pairs(PossessionsData) do
		for item2, value2 in pairs(value) do
			for item3, value3 in pairs(value2.items) do
				for item4, value4 in pairs(value3) do
					if (value4) then
						if (value4[INDEX_RARITY] == 5) then
							value4[INDEX_RARITY] = -1
						elseif (value4[INDEX_RARITY] == 4) then
							value4[INDEX_RARITY] = 0
						elseif (value4[INDEX_RARITY] == 0) then
							value4[INDEX_RARITY] = 4
						elseif (value4[INDEX_RARITY] == 3) then
							value4[INDEX_RARITY] = 1
						elseif (value4[INDEX_RARITY] == 1) then
							value4[INDEX_RARITY] = 3
						end
					end
				end
			end
		end
	end

	PossessionsData.config = { }
	PossessionsData.config.version = 1

end

function Possessions_IsLiteMode()
	if not PossessionsData then
		return false
	end

	return ( PossessionsData.config.lite or false )
end

--This function is useful since we can call it in the XML before PossessionsData is loaded
function Possessions_SearchFullText()
	if not PossessionsData then
		return false
	end

	return ( PossessionsData.config.fulltext or false )
end

function Possessions_SearchGuildBank()
	if not PossessionsData then
		return false
	end

	return ( PossessionsData.config.guildsearch or false )
end


function Possessions_VarsLoaded(self)
	self:UnregisterEvent("VARIABLES_LOADED")
	realmName = GetRealmName()
	playerName = string.lower(UnitName("player"))
	
	if( not PossessionsData ) then
		PossessionsData = { }
		PossessionsData.config = { }
		PossessionsData.config.version = 1
	elseif ( not PossessionsData.config ) then
		Possessions_convertDB0to1()
	end

	if( not PossessionsData[realmName] ) then
		PossessionsData[realmName] = {}
	end
	
	if( not PossessionsData[realmName][playerName] ) then
		PossessionsData[realmName][playerName] = { }
	end

	if( not PossessionsData[realmName][playerName].items ) then
		PossessionsData[realmName][playerName].items = { }
	end

	if not PossessionsData[realmName][playerName].inboxMoney then
		PossessionsData[realmName][playerName].inboxMoney = 0
	end

	PlayerItemTable = PossessionsData[realmName][playerName].items

	if not PlayerItemTable[POSS_PLAYER_CONTAINER] then
		PlayerItemTable[POSS_PLAYER_CONTAINER] = { }
	end

	--Set text to localized strings from globals
	for index, slot in pairs(Possessions_INVENTORY_SLOT_LIST) do
		slot.id = GetInventorySlotInfo(slot.name);
	end

	if (PossessionsData.config.lite == nil) then
		PossessionsData.config.lite = true
		Possessions_RemoveTextures()
	else
		if( PossessionsData.config.lite == true) then
			Possessions_RemoveTextures()
		else
			Possessions_AddTextures()
		end
	end
	if (PossessionsData.config.fulltext == nil) then
		PossessionsData.config.fulltext = false
	end
	if (PossessionsData.config.guildsearch == nil) then
		PossessionsData.config.guildsearch = false
	end
	
	-- Option default: enable global tooltip
	if PossessionsData.config.globalTooltip == nil then
		PossessionsData.config.globalTooltip = true
	end
	-- Option default: disable forced tooltip
	-- (in presence of other addons, such as BankItems)
	if PossessionsData.config.forcedGlobalTooltip == nil then
		PossessionsData.config.forcedGlobalTooltip = false
	end
	
	-- MyAddOns is an old WoW addon management tool
	if(myAddOnsFrame) then
		myAddOnsList.Possessions = {
			name = "Possessions",
			description = "AddOn to keep track of all your items.",
			version = POSSESSIONS_VERSION,
			category = MYADDONS_CATEGORY_INVENTORY,
			frame = "Possessions_Frame"
		};
	end
	
	SLASH_POSSESSIONS1 = "/possessions"
	SLASH_POSSESSIONS2 = "/poss"
	
	SlashCmdList["POSSESSIONS"] = function(msg)
		Possessions_SlashCommandHandler(msg)
	end
	
	for index, _ in pairs(PossessionsData[realmName]) do
		table.insert(characterTable, Possessions_Capitalize(index))
	end
	table.sort(characterTable)

	if ( Possessions_IsLiteMode() == true) then
		POSSESSIONS_CHK_LiteMode:SetChecked(1)
	else
		POSSESSIONS_CHK_LiteMode:SetChecked(0)
	end
	if ( PossessionsData.config.fulltext == true) then
		POSSESSIONS_CHK_FullText:SetChecked(1)
	else
		POSSESSIONS_CHK_FullText:SetChecked(0)
	end
	if ( PossessionsData.config.guildsearch == true) then
		POSSESSIONS_CHK_GuildBank:SetChecked(1)
	else
		POSSESSIONS_CHK_GuildBank:SetChecked(0)
	end

	--Set Text in UI
	Possessions_FrameTitle:SetText(PossessionsLocale.INV_TITLE_TEXT .. " v" .. POSSESSIONS_VERSION)
	Possessions_FrameSearchText:SetText(PossessionsLocale.TEXT_SEARCH)
	POSSESSIONS_CHK_FullTextText:SetText(PossessionsLocale.CFG_FULLTEXT)
	POSSESSIONS_CHK_GuildBankText:SetText(PossessionsLocale.CFG_GUILDBANK)
	POSSESSIONS_CHK_SortValueText:SetText(PossessionsLocale.INV_HELP3)
	POSSESSIONS_CHK_SortRarityText:SetText(PossessionsLocale.INV_HELP4)
	POSSESSIONS_CHK_LiteModeText:SetText(PossessionsLocale.CFG_LITEMODE)
	
	Possessions_HookGlobalTooltips()
end

function Possessions_PlayerLogin(self)
	Possessions_ScanMoney()
	playerFaction = UnitFactionGroup("player")
	if IsInGuild() then
		playerGuild = GetGuildInfo("player")
	end
	PossessionsData[realmName][playerName].faction = playerFaction
	Possessions_Inspect()
	Possessions_ReloadBag(POSS_INVENTORY_CONTAINER)	 --Other inventory bags will be loaded by events
	if ( HasKey() ) then Possessions_ReloadBag(KEYRING_CONTAINER) end	--Load keyring bag

	self:UnregisterEvent("PLAYER_ENTERING_WORLD")

	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	self:RegisterEvent("PLAYER_MONEY")
	self:RegisterEvent("MAIL_SEND_SUCCESS")
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("MAIL_INBOX_UPDATE")
	
	self:RegisterEvent("GUILDBANKFRAME_OPENED")
	self:RegisterEvent("GUILDBANKFRAME_CLOSED")
	self:RegisterEvent("PLAYER_GUILD_UPDATE")
end

--------------------------------------------------
-- Store all items that the character is wearing
--------------------------------------------------
function Possessions_Inspect()
	local index, link

	for index, slot in pairs(Possessions_INVENTORY_SLOT_LIST) do
		link = GetInventoryItemLink("player", slot.id)

		if( link ) then
			if( Possessions_StoreLink(POSS_PLAYER_CONTAINER, index, link) ) then
				PlayerItemTable[POSS_PLAYER_CONTAINER][index][INDEX_QUANTITY] = 1
				if( Possessions_IsLiteMode() == false ) then
					PlayerItemTable[POSS_PLAYER_CONTAINER][index][INDEX_ICON] = GetInventoryItemTexture("player", slot.id)
				end
			end
		else
			-- If this index has already been created in memory, just set quantity to 0 to hide it.
			PlayerItemTable[POSS_PLAYER_CONTAINER][index] = nil
		end
	end
end

function Possessions_RemoveTextures()
	for character, charTable in pairs(PossessionsData[realmName]) do
		for index, value in pairs(charTable.items) do
			for index2, value2 in pairs(value) do
				if value2[INDEX_ICON] then
					value[index2][INDEX_ICON] = nil
				end
			end
		end
	end
end

function Possessions_AddTextures()
	local texture
	for character, charTable in pairs(PossessionsData[realmName]) do
		for index, value in pairs(charTable.items) do
			for index2, value2 in pairs(value) do
				if not value2[INDEX_ICON] then
					texture = select(10, GetItemInfo( Possessions_FixLink(value2[INDEX_LINK]) ) )
					value[index2][INDEX_ICON] = texture or "Interface\\Icons\\INV_Misc_QuestionMark"
				end
			end
		end
	end
end

--Scan and store all items in the character's bank
function Possessions_ScanBank()
	Possessions_ReloadBag(POSS_BANK_CONTAINER)

	for bagid = NUM_BAG_SLOTS + 1, (NUM_BAG_SLOTS + NUM_BANKBAGSLOTS), 1 do
		Possessions_ReloadBag(bagid)
	end
end

function Possessions_ScanGuildBank()
	GuildBankUpdateCount = 0

	for guildBankTabNum=1, GetNumGuildBankTabs() do	--MAX_GUILDBANK_TABS
		QueryGuildBankTab(guildBankTabNum)
	end
	hooksecurefunc("GuildBankFrame_Update", Possessions_GBFUpdate)
end


--------------------------------------------------
-- Scan Character's Inbox
--------------------------------------------------
function Possessions_ScanMail()
	local index
	local currTime = GetTime()
	if (currTime - lastScan < 1) then
		return
	end
	lastScan = currTime

	PossessionsData[realmName][playerName].inboxMoney = 0

	local numInboxItems = GetInboxNumItems()
	if( numInboxItems > 0 ) then
		if not PlayerItemTable[POSS_MAIL_CONTAINER] then
			PlayerItemTable[POSS_MAIL_CONTAINER] = { }
		end
		--Remove old 0 index entry if present
		if PlayerItemTable[POSS_MAIL_CONTAINER][0] then
			PlayerItemTable[POSS_MAIL_CONTAINER][0] = nil
		end

		local mailItems = PlayerItemTable[POSS_MAIL_CONTAINER]

		local name, icon, quantity, quality
		local money, hasItem
		local compressedLink
		local storeIndex = 1
		local reuseStoreIndex
		for index = 1, numInboxItems do
			_, _, _, _, money, _, _, hasItem = GetInboxHeaderInfo(index)
			if money > 0 then
				PossessionsData[realmName][playerName].inboxMoney = PossessionsData[realmName][playerName].inboxMoney + money
			end
			if hasItem then
				for attachSlot=1, ATTACHMENTS_MAX_SEND do
					name, icon, quantity, quality = GetInboxItem(index, attachSlot)
					if name then	--If uncached items are in the inbox, ignore them
						compressedLink = Possessions_CompressLink( GetInboxItemLink(index, attachSlot) )
						if( Possessions_IsLiteMode() == true ) then --Only search for existing stack if Lite Mode is enabled
							--Look through previous bag contents
							reuseStoreIndex=1
							while reuseStoreIndex < storeIndex do
								if mailItems[reuseStoreIndex] and mailItems[reuseStoreIndex][INDEX_LINK] == compressedLink then
									break
								end
								reuseStoreIndex = reuseStoreIndex + 1
							end
						else
							reuseStoreIndex = storeIndex
						end

						if reuseStoreIndex == storeIndex then
							if not mailItems[storeIndex] then
								mailItems[storeIndex] = { }
							end
							mailItems[storeIndex][INDEX_LINK] = compressedLink
							mailItems[storeIndex][INDEX_NAME] = name
							if(Possessions_IsLiteMode() == false) then
								mailItems[storeIndex][INDEX_ICON] = icon
							end
							mailItems[storeIndex][INDEX_QUANTITY] = quantity
							mailItems[storeIndex][INDEX_RARITY] = quality
							storeIndex = storeIndex + 1
						else
							mailItems[reuseStoreIndex][INDEX_QUANTITY] = mailItems[reuseStoreIndex][INDEX_QUANTITY] + quantity
						end
					end --if name
				end -- for each attachment
			end	--if hasItem
		end
		for index, _ in pairs(PlayerItemTable[POSS_MAIL_CONTAINER]) do
			if index >= storeIndex then
				PlayerItemTable[POSS_MAIL_CONTAINER][index] = nil
			end
		end
		Possessions_ScanMoney()
	else	--numinboxitems is 0
		if PlayerItemTable[POSS_MAIL_CONTAINER] then
			PlayerItemTable[POSS_MAIL_CONTAINER] = nil
		end
	end
end

--------------------------------------------------
--	Money Tooltip functions
--------------------------------------------------
function Possessions_HideMoneyTooltip()
	GameTooltip:Hide()
end

function Possessions_ShowMoneyTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
	local name, playerData
	local playermoney
	local inboxmoney
	for name, playerData in pairs(PossessionsData[realmName]) do
		playermoney = playerData.money
		inboxmoney = playerData.inboxMoney
		name = Possessions_Capitalize(name)
		if (playermoney and playermoney > 0) then
				GameTooltip:AddDoubleLine(name..":", Possessions_getTextGSC(playermoney), 1, 1, 1)
		end
		if (inboxmoney and inboxmoney > 0) then
				GameTooltip:AddDoubleLine(name.."'s Inbox:", Possessions_getTextGSC(inboxmoney), 1, 1, 1)
		end
	end

	GameTooltip:Show()
end

function Possessions_getTextGSC(money)
	local moneystring = ""

	local g = math.floor((money or 0) / 10000)
	local s = math.floor(((money or 0) - (g*10000)) / 100)
	local c = math.ceil((money or 0) - (g*10000) - (s*100))

	if (g > 0) then
		moneystring = "|cffffd700"..g.."g|r"
	end
	if (s > 0) or (c > 0) then
		moneystring = moneystring.."|cffc7c7cf"..s.."s|r"
	end
	if (c > 0) then
		moneystring = moneystring.."|cffeda55f"..c.."c|r"
	end
	if (moneystring == "") then
		moneystring = "|cffa0a0a0".."0".."|r"
	end

	return moneystring
end

function Possessions_CountMoney()
	local totalMoney = 0

	for _, values in pairs(PossessionsData[realmName]) do
		if (values.money) then
			totalMoney = totalMoney + values.money
		end
		if (values.inboxMoney) then
			totalMoney = totalMoney + values.inboxMoney
		end
	end

	POSSESSIONS_MoneyField_Text:SetText(Possessions_getTextGSC(totalMoney))
end

function Possessions_ScanMoney()
	PossessionsData[realmName][playerName].money = GetMoney()
end

--------------------------------------------------
-- SendMail Hook
--------------------------------------------------
function Possessions_SendMail(name, ...)
	--Store current SendMail information for recording if the mail is sent successfully
	for i=1, ATTACHMENTS_MAX_SEND do
		sendMailItems[i] = GetSendMailItemLink(i)
		sendMailItemQuantities[i] = select(3,GetSendMailItem(i))
	end
	sendMailMoney = MoneyInputFrame_GetCopper(SendMailMoney)
	sendMailRecipient = name
end
hooksecurefunc("SendMail", Possessions_SendMail);

function Possessions_ReturnInboxItem(index)
	local hasItem
	_, _, sendMailRecipient, _, sendMailMoney, _, _, hasItem = GetInboxHeaderInfo(index)
	if (hasItem) then
		for attachSlot=1, ATTACHMENTS_MAX_SEND do
			sendMailItems[attachSlot] = GetInboxItemLink(index, attachSlot)
			sendMailItemQuantities[attachSlot] = select(3, GetInboxItem(index, attachSlot))
		end
	else
		for attachSlot=1, ATTACHMENTS_MAX_SEND do
			sendMailItems[attachSlot] = nil
			sendMailItemQuantities[attachSlot] = 0
		end
	end
	Possessions_MailSendSuccess()
end
hooksecurefunc("ReturnInboxItem", Possessions_ReturnInboxItem)


function Possessions_MailSendSuccess()
	if sendMailRecipient == "" then return end

	local namelc = string.lower(sendMailRecipient)
	if( namelc and PossessionsData[realmName][namelc] ) then
		if sendMailMoney > 0 then
			PossessionsData[realmName][namelc].inboxMoney = PossessionsData[realmName][namelc].inboxMoney + sendMailMoney
		end
		if( not PossessionsData[realmName][namelc].items[POSS_MAIL_CONTAINER] ) then
			PossessionsData[realmName][namelc].items[POSS_MAIL_CONTAINER] = { }
		end
		local mailTable = PossessionsData[realmName][namelc].items[POSS_MAIL_CONTAINER]
		local sendMailItem
		--Iterate over all 12 possible attachments
		for i, sendMailItem in pairs(sendMailItems) do
				local itemName, _, rarity, _, _, _, _, _, _, itemTexture = GetItemInfo( sendMailItem )
				local n = #mailTable + 1

				mailTable[n] = { }
				mailTable[n][INDEX_NAME] = itemName
				mailTable[n][INDEX_LINK] = Possessions_CompressLink( string.match(sendMailItem, "item:(.*)|h") )
				if(Possessions_IsLiteMode() == false) then
					mailTable[n][INDEX_ICON] = itemTexture
				end
				mailTable[n][INDEX_QUANTITY] = sendMailItemQuantities[i]
				mailTable[n][INDEX_RARITY] = rarity
				
				--Remove the item from the table
				sendMailItems[i] = nil
				sendMailItemQuantities[i] = 0
--			end
		end
	end
	sendMailMoney = 0
	sendMailRecipient = ""
end

function Possessions_OnLoad(self)	
	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	table.insert(UISpecialFrames, "Possessions_Frame")
end

--------------------------------------------------
-- Event Handler
--------------------------------------------------
function Possessions_OnEvent(self, event, arg1)
	if( event == "BAG_UPDATE" ) then
		Possessions_ReloadBag(arg1)
		Possessions_InvalidateCaches()
	elseif ( event == "PLAYER_MONEY") then
		Possessions_ScanMoney()
	elseif( event == "UNIT_INVENTORY_CHANGED" ) then
		if( arg1 == "player") then
			Possessions_Inspect()
			Possessions_InvalidateCaches()
		end
	elseif( event == "PLAYERBANKSLOTS_CHANGED" ) then
		--Something within the 24 free bank slots has changed
		Possessions_ReloadBag(POSS_BANK_CONTAINER)
		Possessions_InvalidateCaches()
	elseif( event == "MAIL_INBOX_UPDATE" ) then
		Possessions_ScanMail()
		Possessions_InvalidateCaches()
	elseif( event == "MAIL_SEND_SUCCESS" ) then
		--MAIL_SEND_SUCCESS is fired when the inbox is opened with arg1 set to "up"
		if not arg1 then
			Possessions_MailSendSuccess()
			Possessions_InvalidateCaches()
		end
	elseif( event == "BANKFRAME_OPENED" ) then
		Possessions_ScanBank()
		Possessions_InvalidateCaches()
	elseif( event == "GUILDBANKFRAME_OPENED" ) then
		--SCAN THE GUILD BANK
		Possessions_ScanGuildBank()
		Possessions_InvalidateCaches()
	elseif( event == "GUILDBANKFRAME_CLOSED" ) then
		GuildBankUpdateCount = 0
	elseif( event == "PLAYER_GUILD_UPDATE" ) then
		if IsInGuild() then
			playerGuild = GetGuildInfo("player")
		else
			playerGuild = nil
		end
		Possessions_InvalidateCaches()
	elseif( event == "VARIABLES_LOADED" ) then
		Possessions_VarsLoaded(self)
	elseif( event == "PLAYER_ENTERING_WORLD" ) then
		Possessions_PlayerLogin(self)
	end
end

function Possessions_GBFUpdate(...)
	local numTabs = GetNumGuildBankTabs()

	if (numTabs > 0) then
		GuildBankUpdateCount = GuildBankUpdateCount + 1
		if ( not PossessionsData[realmName][playerGuild] ) then
			PossessionsData[realmName][playerGuild] = { items = {} }
			PossessionsData[realmName][playerGuild].items[POSS_GUILDBANK_CONTAINER] = {}
			--Rebuild the table of character names
			characterTable = { }
			for index, value in pairs(PossessionsData[realmName]) do
				table.insert(characterTable, Possessions_Capitalize(index))
			end
			table.sort(characterTable)
		end
		if (GuildBankUpdateCount > numTabs) then
			local storeBag = PossessionsData[realmName][playerGuild].items[POSS_GUILDBANK_CONTAINER]
			local storeContainerItemNum
			local link

			for guildBankTabNum=1, numTabs do	--MAX_GUILDBANK_TABS
				for guildBankSlot=1, MAX_GUILDBANK_SLOTS_PER_TAB do
					local link = GetGuildBankItemLink(guildBankTabNum, guildBankSlot)
					local containerItemNum = (guildBankTabNum * MAX_GUILDBANK_SLOTS_PER_TAB) + guildBankSlot
					storeContainerItemNum = containerItemNum
					link = GetGuildBankItemLink(guildBankTabNum, guildBankSlot)
					if( link ) then
						local compressedLink = Possessions_CompressLink(link)

						--Try to find an existing stack of this item type in the same bag to use
						if( Possessions_IsLiteMode() == true ) then --Only search for existing stack if Lite Mode is enabled
							--Look through previous bag contents
							for prevContItemNum=1, containerItemNum-1 do
								if storeBag[prevContItemNum] then
									if storeBag[prevContItemNum][INDEX_LINK] == compressedLink then -- and storeBag[prevContItemNum][INDEX_QUANTITY] > 0 then --Don't want quantity to be 0 since we might put stuff into a slot that will soon be overwritten by new contents
										storeContainerItemNum = prevContItemNum
										break
									end
								end
							end
						end
						if storeContainerItemNum ~= containerItemNum then
							storeBag[storeContainerItemNum][INDEX_QUANTITY] = storeBag[storeContainerItemNum][INDEX_QUANTITY] + select(2,GetGuildBankItemInfo(guildBankTabNum, guildBankSlot))
							if storeBag[containerItemNum] then
								storeBag[containerItemNum] = nil
							end
						else	--Did not find existing stack for the same item
							--Store the new link normally
							local name, _, rarity = GetItemInfo(link)
							if name then
								if (not storeBag[containerItemNum]) then
									storeBag[containerItemNum] = {}
								end
								--Only assign values if they have changed. May or may not help performance
								if storeBag[containerItemNum][INDEX_LINK] ~= compressedLink then
									storeBag[containerItemNum][INDEX_LINK] = compressedLink
									storeBag[containerItemNum][INDEX_NAME] = name
									storeBag[containerItemNum][INDEX_RARITY] = rarity
								end
								storeBag[containerItemNum][INDEX_ICON], storeBag[containerItemNum][INDEX_QUANTITY] = GetGuildBankItemInfo(guildBankTabNum, guildBankSlot)
								if( Possessions_IsLiteMode() == true ) then
									storeBag[containerItemNum][INDEX_ICON] = nil
								end
							end
						end

					else
						if storeBag[containerItemNum] and storeBag[containerItemNum][INDEX_QUANTITY] > 0 then
							storeBag[containerItemNum] = nil
						end
					end
				end
			end
		end
	end
end

-- Global item tooltip, inspired by addon BankItems
do 
	local EnumerateFrames = EnumerateFrames
	local strfind, format, gsub, strupper = strfind, string.format, string.gsub, 
		string.upper
	local tinsert, wipe = table.insert, table.wipe
	
	local function c(r, g, b, a)
		if not a then a = 1 end
		
		local mt = {
			__metatable=false,
			__newindex=pass,
			color={ r, g, b, a },
		}
		
		function mt:__call(text)
			local r, g, b, a = unpack(mt.color)
			if text then
				return format("|c%02X%02X%02X%02X", a, r, g, b) 
					.. tostring(text) .. FONT_COLOR_CODE_CLOSE
			else
				return r/255, g/255, b/255, a
			end
		end
		
		function mt:__concat(text)
			local r, g, b, a = unpack(mt.color)
			return format("|c%02X%02X%02X%02X", a, r, g, b) .. tostring(text)
		end
		
		return setmetatable({}, mt)
	end
	
	local function strFirstUpper(str)
		return gsub(str, "^%a", strupper, 1)
	end
	
	local function strGuild(str)
		return format("<%s>", strFirstUpper(str))
	end
	
	local COLOR_BLUE = c(74, 177, 213)
	local LOCATIONS = {
		[POSS_INVENTORY_CONTAINER] = "Bags",
		[BACKPACK_CONTAINER + 1] = "Bags",
		[BACKPACK_CONTAINER + 2] = "Bags",
		[BACKPACK_CONTAINER + 3] = "Bags",
		[BACKPACK_CONTAINER + 4] = "Bags",
		[POSS_PLAYERBAG_CONTAINER] = "Bags",
		[POSS_KEYRING_CONTAINER] = "Bags",
		[POSS_BANK_CONTAINER] = "Bank",
		[BACKPACK_CONTAINER + NUM_BAG_SLOTS + 1] = "Bank",
		[BACKPACK_CONTAINER + NUM_BAG_SLOTS + 2] = "Bank",
		[BACKPACK_CONTAINER + NUM_BAG_SLOTS + 3] = "Bank",
		[BACKPACK_CONTAINER + NUM_BAG_SLOTS + 4] = "Bank",
		[BACKPACK_CONTAINER + NUM_BAG_SLOTS + 5] = "Bank",
		[BACKPACK_CONTAINER + NUM_BAG_SLOTS + 6] = "Bank",
		[BACKPACK_CONTAINER + NUM_BAG_SLOTS + 7] = "Bank",
		[POSS_BANKBAG_CONTAINER] = "Bank",
		[POSS_PLAYER_CONTAINER] = "Equipped",
		[POSS_MAIL_CONTAINER] = "Mail",
		[POSS_GUILDBANK_CONTAINER] = "Guild Bank",
	}
	local locationsOrder = { "Bank", "Bags", "Equipped", "Mail" }
	local locationFormats = {
		"%s %d",
		"%s %d, %s %d",
		"%s %d, %s %d, %s %d",
		"%s %d, %s %d, %s %d, %s %d",
	}
	local possessionFormat = "%s has %d [%s]"
	local totalFormat = "Total: %d"
	
	local isAlreadyAdded = false
	local tooltipCache = {}
	
	local function quantitiesToText(quantities, order)
		local count = 0
		for k,v in pairs(quantities) do count = count + 1 end
		
		local locationText = locationFormats[count]
		
		for i=1, #order do
			local location = order[i]
			local quantity = quantities[location]
			
			if quantity and quantity > 0 then
				locationText = gsub(locationText, "%%s %%d",
					format("%s %d", location, quantity), 1)
			end
		end
		
		return locationText
	end
	
	local function getItemData(itemId)
		if not tooltipCache[itemId] then
			tooltipCache[itemId] = {}
			
			local total = 0
			
			-- Current player
			local playerTotal = 0
			local playerTable = PossessionsData[realmName][playerName]
			local quantities = {}
			
			for containerId, container in pairs(playerTable.items) do
				for slotId, slot in pairs(container) do
					local slotItemId = slot[INDEX_LINK]
						
					if slotItemId and tonumber(slotItemId) == itemId then
						local location = LOCATIONS[containerId]
						local quantity = slot[INDEX_QUANTITY]
						
						if location and quantity then
							quantities[location] = (quantities[location] or 0) + quantity
							playerTotal = playerTotal + quantity
						end
					end
				end
			end
			
			if playerTotal > 0 then
				local textLine = format(possessionFormat, strFirstUpper(playerName), 
					playerTotal, quantitiesToText(quantities, locationsOrder))
					
				tinsert(tooltipCache[itemId], textLine)
				
				total = total + playerTotal
			end
			
			-- All other characters, including collecting guild bank data
			local guildBanks = {}
			
			for character, charTable in pairs(PossessionsData[realmName]) do
				if character ~= playerName then
					local quantities = {}
					local charTotal = 0
					
					for containerId, container in pairs(charTable.items) do
						for slotId, slot in pairs(container) do
							local slotItemId = slot[INDEX_LINK]
								
							if slotItemId and tonumber(slotItemId) == itemId then
								local location = LOCATIONS[containerId]
								local quantity = slot[INDEX_QUANTITY]
								
								if location and quantity then
									quantities[location] = (quantities[location] or 0) + quantity
									charTotal = charTotal + quantity
								end
							end
						end
					end 
					
					if charTotal > 0 then
						if not quantities["Guild Bank"] then
							local textLine = format(possessionFormat, 
								strFirstUpper(character), charTotal, 
								quantitiesToText(quantities, locationsOrder))
					
							tinsert(tooltipCache[itemId], textLine)
							total = total + charTotal
						else
							guildBanks[character] = quantities["Guild Bank"]
							
							if PossessionsData.config.guildsearch then
								total = total + charTotal
							end
						end
					end
				end
			end
			
			-- Finally, guild banks
			if PossessionsData.config.guildsearch then
				for guildBank, quantity in pairs(guildBanks) do
					if quantity > 0 then
						local textLine = format(possessionFormat, strGuild(guildBank), 
							quantity, format("%s %d", "Guild Bank", quantity))
						
						tinsert(tooltipCache[itemId], textLine)
					end
				end
			end
			
			-- Complete total for the item
			if total > 0 then
				tinsert(tooltipCache[itemId], format(totalFormat, total))
			end
		end
		
		return tooltipCache[itemId]
	end
	
	local function detectOtherTooltips()
		if BankItems_HookTooltips then return true end
		return false
	end
	
	local function addTooltip(self, ...)
		if not PossessionsData.config.globalTooltip
				or (detectOtherTooltips()
				and not PossessionsData.config.forcedGlobalTooltip) then
			return
		end
		
		if isAlreadyAdded then return end
		
		local _, link = self:GetItem()
		local itemId = link and tonumber(link:match("item:(%d+)"))
		if not itemId then return end
		
		local data = getItemData(itemId)
		if data and #data > 0 then 
			for i = 1, #data do
				self:AddLine(data[i], COLOR_BLUE())
			end
			
			self:Show()
		end
		
		isAlreadyAdded = true
	end
	
	local function clearTooltip(self, ...)
		isAlreadyAdded = false
	end
	
	local function hookGlobalTooltip(tooltip)
		if not tooltip then return end
		
		local setItem = tooltip:GetScript("OnTooltipSetItem")
		if setItem then
			tooltip:SetScript("OnTooltipSetItem", function(self, ...)
				addTooltip(self, ...)
				return setItem(self, ...)
			end)
		else
			tooltip:SetScript("OnTooltipSetItem", addTooltip)
		end
		
		local clearItem = tooltip:GetScript("OnTooltipCleared")
		if clearItem then
			tooltip:SetScript("OnTooltipCleared", function(self, ...)
				isAlreadyAdded = false
				return clearItem(self, ...)
			end)
		else
			tooltip:SetScript("OnTooltipCleared", clearTooltip)
		end
	end
	
	local whitelistTooltips = {
		"GameTooltip",
		"ItemRefTooltip",
		"ShoppingTooltip",
		"ComparisonTooltip",					 -- EquipCompare support
		"EQCompareTooltip",						-- EQCompare support
		"tekKompareTooltip",					 -- tekKompare support
		"IRR_",
		"LinksTooltip",								-- Links support
		"AtlasLootTooltip",						-- AtlasLoot support
		"ItemMagicTooltip",						-- ItemMagic support
		"SniffTooltip",								-- Sniff support
		"LH_",												 -- LinkHeaven support
		"MirrorTooltip",							 -- Mirror support
		"LootLink_ResultsTooltip",		 -- Saeris' LootLink support
		"TooltipExchange_TooltipShow", -- TooltipExchange support
	}
	
	function Possessions_HookGlobalTooltips()
		local tooltip = EnumerateFrames()
		while tooltip do
			if tooltip:GetObjectType() == "GameTooltip" then
				local name = tooltip:GetName()
				if name then
					for i = 1, #whitelistTooltips do
						if strfind(name, whitelistTooltips[i], 1, true) then
							hookGlobalTooltip(tooltip)
							break
						end
					end
				end
			end
			tooltip = EnumerateFrames(tooltip)
		end
		-- Prevent re-running this function
		Possessions_HookGlobalTooltips = function() end
	end
	
	function Possessions_InvalidateTooltipCache()
		if tooltipCache then wipe(tooltipCache) end
	end
end

function Possessions_InvalidateCaches()
	Possessions_InvalidateTooltipCache()
end