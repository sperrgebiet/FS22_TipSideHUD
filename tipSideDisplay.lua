-- tipSideDisplay specialization for FS22
--
-- This mod adds a new HUD which shows the tip side of the currently selected implement/trailer. This enables you to hide the help menu, while still 
-- be able to see the currently selected tip side.
--
-- Author: sperrgebiet
-- Credits: Idea and LS17 implementation as part of the Game Extension Mod: Xentro

TipSideDisplay = {}
TipSideDisplay.eventName = {}
-- It's great that Giants gets rid of functions as part of an update. Now we can do things more complicated than before
--TipSideDisplay.ModName = g_currentModName
--TipSideDisplay.ModDirectory = g_currentModDirectory
TipSideDisplay.ModName = "FS22_TipSideHUD"
TipSideDisplay.ModDirectory = g_modManager.nameToMod.FS22_TipSideHUD.modDir

TipSideDisplay.Version = "1.0.0.2"

TipSideDisplay.debug = fileExists(TipSideDisplay.ModDirectory ..'debug')

if TipSideDisplay.debug then
	print(string.format('TipSideDisplay v%s - DebugMode %s)', TipSideDisplay.Version, tostring(TipSideDisplay.debug)))
end

function TipSideDisplay:dp(val, fun, msg) -- debug mode, write to log
	if not TipSideDisplay.debug then
		return;
	end

	if msg == nil then
		msg = ' ';
	else
		msg = string.format(' msg = [%s] ', tostring(msg));
	end

	local pre = 'TipSideDisplay DEBUG:';

	if type(val) == 'table' then
		--if #val > 0 then
			print(string.format('%s BEGIN Printing table data: (%s)%s(function = [%s()])', pre, tostring(val), msg, tostring(fun)));
			DebugUtil.printTableRecursively(val, '.', 0, 3);
			print(string.format('%s END Printing table data: (%s)%s(function = [%s()])', pre, tostring(val), msg, tostring(fun)));
		--else
		--	print(string.format('%s Table is empty: (%s)%s(function = [%s()])', pre, tostring(val), msg, tostring(fun)));
		--end
	else
		print(string.format('%s [%s]%s(function = [%s()])', pre, tostring(val), msg, tostring(fun)));
	end
end

function TipSideDisplay.registerEventListeners(vehicleType)
	local functionNames = {	"onRegisterActionEvents" };
	
	for _, functionName in ipairs(functionNames) do
		SpecializationUtil.registerEventListener(vehicleType, functionName, TipSideDisplay);
	end
end

function TipSideDisplay:onRegisterActionEvents(isSelected, isOnActiveVehicle)
	if self.spec_trailer ~= nil and self.spec_trailer.tipSideCount > 0 and isSelected then	
		local actions = {
				"tsd_toggleConfig",
				"tsd_upConfig",
				"tsd_downConfig",
				"tsd_changeConfig"
			}

		local spec = self.spec_tipSideDisplay
		spec.actionEvents = {}
		
		self:clearActionEventsTable(spec.actionEvents)
		
		for _, action in pairs(actions) do
			local actionMethod = string.format("action_%s", action);
			local _, actionEventId = self:addActionEvent(spec.actionEvents, action, self, TipSideDisplay[actionMethod], false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventActive(actionEventId, false)
			
			if action == "tsd_toggleConfig" then
				spec.actionEvents[action].displayIsVisible = true
				g_inputBinding:setActionEventActive(actionEventId, true)
			else
				if TipSideDisplay.showConfig then
					spec.actionEvents[action].displayIsVisible = true
					g_inputBinding:setActionEventActive(actionEventId, true)
				end
			end
		end
	end		
end

function TipSideDisplay:action_tsd_toggleConfig(actionName, keyStatus, arg3, arg4, arg5)
	TipSideDisplay:dp(string.format('%s action fires', actionName))
	TipSideDisplay.showConfig = not TipSideDisplay.showConfig
	
	if TipSideDisplay.showConfig then
		TipSideDisplay:freezeCam(true)
		--Enable events just needed for our config
		local spec = self.spec_tipSideDisplay
		for _, action in ipairs({"tsd_upConfig", "tsd_downConfig", "tsd_changeConfig"}) do
			local actionEvent = spec.actionEvents[action]
			if actionEvent ~= nil then
				g_inputBinding:setActionEventActive(actionEvent.actionEventId, true)
			end
		end
		
		g_inputBinding.nameActions.SWITCH_IMPLEMENT.bindings[1].isActive = false
	else
		TipSideDisplay:freezeCam(false)
		--Disable events just needed for our config
		local spec = self.spec_tipSideDisplay
		for _, action in ipairs({"tsd_upConfig", "tsd_downConfig", "tsd_changeConfig"}) do
			local actionEvent = spec.actionEvents[action]
			if actionEvent ~= nil then
				g_inputBinding:resetActiveActionBindings()
			end
		end
		g_inputBinding.nameActions.SWITCH_IMPLEMENT.bindings[1].isActive = true
	end
end

function TipSideDisplay:action_tsd_upConfig(actionName, keyStatus, arg3, arg4, arg5)
	TipSideDisplay:dp(string.format('%s action fires', actionName))
	if TipSideDisplay.showConfig then
		local newSelection = TipSideDisplay.configSelectedItem - 1
		if newSelection <= 0 then
			newSelection = #TipSideDisplay.Config
		end
		TipSideDisplay.configSelectedItem = newSelection
		TipSideDisplay:dp(string.format('%s: configSelectedItem: {%f}, newSelection: {%f}, #TipSideDisplay.Config: {%f}', actionName, TipSideDisplay.configSelectedItem, newSelection, #TipSideDisplay.Config))
	end
end


function TipSideDisplay:action_tsd_downConfig(actionName, keyStatus, arg3, arg4, arg5)
	TipSideDisplay:dp(string.format('%s action fires', actionName))
	if TipSideDisplay.showConfig then
		local newSelection = TipSideDisplay.configSelectedItem + 1
		if newSelection > #TipSideDisplay.Config then
			newSelection = 1
		end
		TipSideDisplay.configSelectedItem = newSelection
		TipSideDisplay:dp(string.format('%s: configSelectedItem: {%f}, newSelection: {%f}, #TipSideDisplay.Config: {%f}', actionName, TipSideDisplay.configSelectedItem, newSelection, #TipSideDisplay.Config))
	end
end

function TipSideDisplay:action_tsd_changeConfig(actionName, keyStatus, arg3, arg4, arg5)
	TipSideDisplay:dp(string.format('%s action fires', actionName))
	if TipSideDisplay.showConfig then
		TipSideDisplay:changeConfig(self)
	end
end

function TipSideDisplay:mouseEvent(posX, posY, isDown, isUp, button)
	if TipSideDisplay.showConfig then

		if TipSideDisplay:isActionAllowed() and ( isDown and button == Input.MOUSE_BUTTON_LEFT) then
			TipSideDisplay.action_tsd_changeConfig();
		end

		if TipSideDisplay:isActionAllowed() and ( isDown and Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP)) then
			TipSideDisplay.action_tsd_upConfig();
		end
		
		if TipSideDisplay:isActionAllowed() and ( isDown and Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN)) then
			TipSideDisplay.action_tsd_downConfig();
		end
	
	end
end

function TipSideDisplay:isActionAllowed()
	-- We don't want to accidently switch vehicle when the vehicle list is opened and we change to a menu
	if string.len(g_gui.currentGuiName) > 0 or #g_gui.dialogs > 0 then
		return false
	elseif TipSideDisplay.showConfig then
		return true
	end
end

function TipSideDisplay.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Trailer, specializations)
end

function TipSideDisplay.onStartMission()
	if g_dedicatedServerInfo == nil then
		TipSideDisplay:initTSD()
	end
end

function TipSideDisplay:draw()
	-- Just render and burn CPU with all the other crap when the actual HUD is visible
	-- Order is important here, to cover trucks, trucks with trailers, and trailers alone
	if g_currentMission.hud.isVisible then
		if g_currentMission.controlledVehicle ~= nil and not TipSideDisplay:isCrane(g_currentMission.controlledVehicle) and not TipSideDisplay:isHorse(g_currentMission.controlledVehicle) then
			if g_currentMission.controlledVehicle.spec_drivable ~= nil and g_currentMission.controlledVehicle.spec_tipSideDisplay ~= nil and g_currentMission.controlledVehicle.getAttachedImplements and #g_currentMission.controlledVehicle:getAttachedImplements() > 0 then
				TipSideDisplay:checkRenderDrivable(g_currentMission.controlledVehicle)
				TipSideDisplay:checkRenderImplements(g_currentMission.controlledVehicle)		
			elseif g_currentMission.controlledVehicle.spec_drivable ~= nil and g_currentMission.controlledVehicle.spec_tipSideDisplay ~= nil then
				TipSideDisplay:checkRenderDrivable(g_currentMission.controlledVehicle)
			else
				TipSideDisplay:checkRenderImplements(g_currentMission.controlledVehicle)
			end
			TipSideDisplay:renderConfig()
		end
	end
end

function TipSideDisplay:initTSD()
	-- We've to define all our potential positions here so that the position choice works
	self.Positions = {}
	self.Positions[1] = {}
	self.Positions[1].l10nName = "pos1"
	self.Positions[2] = {}
	self.Positions[2].l10nName = "pos2"
	self.Positions[3] = {}
	self.Positions[3].l10nName = "pos3"
	self.Positions[4] = {}
	self.Positions[4].l10nName = "pos4"
	self.Positions[5] = {}
	self.Positions[5].l10nName = "pos5"

	self.Colors = {}
	self.Colors[1]  = {'col_white', {1, 1, 1, 1}}				
	self.Colors[2]  = {'col_black', {0, 0, 0, 1}}				
	self.Colors[3]  = {'col_grey', {0.7411, 0.7450, 0.7411, 1}}	
	self.Colors[4]  = {'col_blue', {0.0044, 0.15, 0.6376, 1}}	
	self.Colors[5]  = {'col_red', {0.8796, 0.0061, 0.004, 1}}	
	self.Colors[6]  = {'col_green', {0.0263, 0.3613, 0.0212, 1}}
	self.Colors[7]  = {'col_yellow', {0.9301, 0.7605, 0.0232, 1}}
	self.Colors[8]  = {'col_pink', {0.89, 0.03, 0.57, 1}}		
	self.Colors[9]  = {'col_turquoise', {0.07, 0.57, 0.35, 1}}	
	self.Colors[10] = {'col_brown', {0.1912, 0.1119, 0.0529, 1}}
	
	self.Scaling = {0.5, 0.75, 1, 1.25, 1.5}
	
	self.Config = {}
	self.Config[1] = { name='ColorIndex' }
	self.Config[2] = { name='PositionIndex' }
	self.Config[3] = { name='ShowText' }
	self.Config[4] = { name='IconSetIndex' }
	self.Config[5] = { name='Scaling' }
	
	self.ConfigScreen = {}
	self.ConfigScreen['bg'] = createImageOverlay('dataS/menu/blank.png'); --credit: Decker_MMIV, VehicleGroupsSwitcher mod - Minor change for FS22
	self.ConfigScreen['x'] = 0.5
	self.ConfigScreen['y'] = g_currentMission.hud.topNotification.origY
	self.ConfigScreen['BgTransparency'] = 0.75
	self.ConfigScreen['fontSize'] = 0.015
	self.ConfigScreen['fontColor'] = {1, 1, 1, 1}
	self.ConfigScreen['fontColorSelected'] = {0.85, 0.34, 0.011, 1}
	self.ConfigScreen['textPadding'] = 0.005
	self.ConfigScreen['colSpacing'] = 0.02

	self.IconSets = {}
	self.IconSets[1] = { name='Pack 1', path='set1' }
	self.IconSets[2] = { name='Pack 2', path='set2' }
	
	self.PositionIndex = 1	
	self.ColorIndex = 1
	self.ScalingIndex = 3
	self.IconSetIndex = 1
	self.ShowText = true
	self.showConfig = false
	self.configSelectedItem = 1

	self.camBackup = {}
	
	self:initSaveGamePath()
	self:loadConfigFromXML()
end

function TipSideDisplay:setPositions(tipSide)
	-- Just calculate the positions for the positionIndex we actually need
	if self.PositionIndex == 1 then	
		-- Pos1 is below fruit HUD
		self.Positions[1].iconWidth, self.Positions[1].iconHeight = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.FUEL_LEVEL_ICON))
		self.Positions[1].iconWidth = self.Positions[1].iconWidth * self.Scaling[self.ScalingIndex]
		self.Positions[1].iconHeight = self.Positions[1].iconHeight * self.Scaling[self.ScalingIndex]
		self.Positions[1].iconPosX = g_currentMission.inGameMenu.hud.fillLevelsDisplay.origX
		self.Positions[1].iconPosY = (g_currentMission.inGameMenu.hud.fillLevelsDisplay.origY / 2) - (self.Positions[1].iconHeight / 2)
		
		self.Positions[1].textSpacing = 0.001
		self.Positions[1].textSize = g_currentMission.inGameMenu.hud.fillLevelsDisplay.fillLevelTextSize * self.Scaling[self.ScalingIndex]
		self.Positions[1].textHeight, _ = getTextHeight(self.Positions[1].textSize, "DUMMY")	
		self.Positions[1].textPosX = g_currentMission.inGameMenu.hud.fillLevelsDisplay.origX + self.Positions[1].iconWidth + self.Positions[1].textSpacing
		self.Positions[1].textPosY = (g_currentMission.inGameMenu.hud.fillLevelsDisplay.origY * 0.5) - (self.Positions[1].textHeight / 2)

	elseif self.PositionIndex == 2 then
		-- Pos2 is next to VehicleSchema
		self.Positions[2].iconWidth = g_currentMission.hud.vehicleSchema.iconSizeX * self.Scaling[self.ScalingIndex]
		self.Positions[2].iconHeight = g_currentMission.hud.vehicleSchema.iconSizeY * self.Scaling[self.ScalingIndex]
		
		-- Base coordinates
		-- Actually we should always get the proper X values from getVehicleSchemaOverlays. But we'd have to declare iconPosX anyways, so fill it with proper values
		local iconPosX, iconPosY = g_currentMission.hud.vehicleSchema:getPosition()
		
		for _, v in pairs(g_currentMission.hud.vehicleSchema:getVehicleSchemaOverlays(g_currentMission.controlledVehicle)) do
			iconPosX = math.max(iconPosX, v.overlay.x)
			--iconPosY = math.max(iconPosY, v.overlay.y)
		end
		
		-- Docked shouldn't make any difference as we're getting the largest (aka most far right) posX anyways.
		-- Just keep it here in case we need it for later and to proof that I thought about it ;)
		-- g_currentMission.hud.vehicleSchema.isDocked
		
		self.Positions[2].iconPosX = iconPosX + ( self.Positions[2].iconWidth * 1.5 )
		self.Positions[2].iconPosY = iconPosY

		self.Positions[2].textSpacing = 0.001
		self.Positions[2].textSize = g_currentMission.inGameMenu.hud.fillLevelsDisplay.fillLevelTextSize * self.Scaling[self.ScalingIndex]
		self.Positions[2].textHeight, _ = getTextHeight(self.Positions[2].textSize, "DUMMY")
		self.Positions[2].textPosX = self.Positions[2].iconPosX + self.Positions[2].iconWidth + self.Positions[2].textSpacing
		self.Positions[2].textPosY = self.Positions[2].iconPosY + (self.Positions[2].textHeight * 0.5)
		
	elseif self.PositionIndex == 3 then
		-- Pos3 is next to weatherBox
		self.Positions[3].iconWidth, self.Positions[3].iconHeight = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.FUEL_LEVEL_ICON))
		self.Positions[3].iconWidth = self.Positions[3].iconWidth * self.Scaling[self.ScalingIndex]
		self.Positions[3].iconHeight = self.Positions[3].iconHeight * self.Scaling[self.ScalingIndex]		
		--self.Positions[3].iconPosX = g_currentMission.hud.gameInfoDisplay.weatherBox.overlay.x
		--self.Positions[3].iconPosY = g_currentMission.hud.gameInfoDisplay.weatherBox.overlay.y + (self.Positions[3].iconHeight / 2)
		self.Positions[3].iconPosX = g_currentMission.hud.gameInfoDisplay.overlay.x - ( self.Positions[3].iconWidth * 1.2)
		self.Positions[3].iconPosY = g_currentMission.hud.gameInfoDisplay.overlay.y + (self.Positions[3].iconHeight / 2)


		self.Positions[3].textSpacing = 0.001
		self.Positions[3].textSize = g_currentMission.hud.gameInfoDisplay.timeTextSize * self.Scaling[self.ScalingIndex]
		self.Positions[3].textHeight, _ = getTextHeight(self.Positions[3].textSize, tipSide.name)
		self.Positions[3].textWidth = getTextWidth(self.Positions[3].textSize, tipSide.name)
		--Change our iconPosX again to account for the textWidth. We could reorder that here to save this additional step, but I want to keep the same order as before
		if self.ShowText then
			self.Positions[3].iconPosX  = self.Positions[3].iconPosX - self.Positions[3].textWidth - self.Positions[3].textSpacing
		end
		
		self.Positions[3].textPosX = self.Positions[3].iconPosX + self.Positions[3].iconWidth + self.Positions[3].textSpacing
		self.Positions[3].textPosY = self.Positions[3].iconPosY + (self.Positions[3].textHeight * 0.25)

	elseif self.PositionIndex == 4 then
		-- Pos4 is top center
		self.Positions[4].iconWidth, self.Positions[4].iconHeight = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.FUEL_LEVEL_ICON))
		self.Positions[4].iconWidth = self.Positions[4].iconWidth * self.Scaling[self.ScalingIndex]
		self.Positions[4].iconHeight = self.Positions[4].iconHeight * self.Scaling[self.ScalingIndex]		
		self.Positions[4].iconPosX = 0.5 - (self.Positions[4].iconWidth / 2)
		self.Positions[4].iconPosY = 1 - self.Positions[4].iconHeight

		self.Positions[4].textSpacing = 0.001
		self.Positions[4].textSize = g_currentMission.hud.gameInfoDisplay.timeTextSize * self.Scaling[self.ScalingIndex]
		self.Positions[4].textHeight, _ = getTextHeight(self.Positions[4].textSize, tipSide.name)
		self.Positions[4].textWidth = getTextWidth(self.Positions[4].textSize, tipSide.name)
		--Change our iconPosX again to account for the textWidth. We could reorder that here to save this additional step, but I want to keep the same order as before
		if self.ShowText then
			self.Positions[4].iconPosX  = self.Positions[4].iconPosX - ((self.Positions[4].textWidth - self.Positions[4].textSpacing) / 2)
		end
		
		self.Positions[4].textPosX = self.Positions[4].iconPosX + self.Positions[4].iconWidth + self.Positions[4].textSpacing
		self.Positions[4].textPosY = self.Positions[4].iconPosY + (self.Positions[4].textHeight * 0.25)
		
	elseif self.PositionIndex == 5 then
		-- Pos5 is bottom center, actually above vehicleNameDisplay
		self.Positions[5].iconWidth, self.Positions[5].iconHeight = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.FUEL_LEVEL_ICON))
		self.Positions[5].iconWidth = self.Positions[5].iconWidth * self.Scaling[self.ScalingIndex]
		self.Positions[5].iconHeight = self.Positions[5].iconHeight * self.Scaling[self.ScalingIndex]		
		self.Positions[5].iconPosX = 0.5 - (self.Positions[5].iconWidth / 2)
		self.Positions[5].iconPosY = g_currentMission.hud.vehicleNameDisplay.initialPosY + getTextHeight(g_currentMission.hud.vehicleNameDisplay.screenTextSize,"DUMMY")

		self.Positions[5].textSpacing = 0.001
		self.Positions[5].textSize = g_currentMission.hud.gameInfoDisplay.timeTextSize * self.Scaling[self.ScalingIndex]
		self.Positions[5].textHeight, _ = getTextHeight(self.Positions[5].textSize, tipSide.name)
		self.Positions[5].textWidth = getTextWidth(self.Positions[5].textSize, tipSide.name)
		--Change our iconPosX again to account for the textWidth. We could reorder that here to save this additional step, but I want to keep the same order as before
		if self.ShowText then
			self.Positions[5].iconPosX  = self.Positions[5].iconPosX - ((self.Positions[5].textWidth - self.Positions[5].textSpacing) / 2)
		end
		
		self.Positions[5].textPosX = self.Positions[5].iconPosX + self.Positions[5].iconWidth + self.Positions[5].textSpacing
		self.Positions[5].textPosY = self.Positions[5].iconPosY + (self.Positions[5].textHeight * 0.25)

	end
end

function TipSideDisplay:checkRenderDrivable(vehicle)
	if vehicle.spec_trailer ~= nil and vehicle:getIsSelected() and vehicle.spec_trailer.tipSideCount > 0 then
		local tipSideIndex = vehicle.spec_trailer.preferedTipSideIndex
		TipSideDisplay:setPositions(vehicle.spec_trailer.tipSides[tipSideIndex])
		if TipSideDisplay.ShowText then
			TipSideDisplay:renderText(vehicle.spec_trailer.tipSides[tipSideIndex])
		end
		TipSideDisplay:renderIcon(vehicle.spec_trailer.tipSides[tipSideIndex])		
	end
end

function TipSideDisplay:checkRenderImplements(vehicle)
	local allImp = {}
	-- Credits to Tardis from FS17
	local function addAllAttached(obj)
		if obj.getAttachedImplements ~= nil then
			for _, imp in pairs(obj:getAttachedImplements()) do
				addAllAttached(imp.object)
				table.insert(allImp, imp)
			end
		end
	end
	
	addAllAttached(vehicle)

	if allImp ~= nil then
		for i = 1, #allImp do
			local imp = allImp[i]
			if imp ~= nil and imp.object ~= nil and imp.object.spec_trailer ~= nil and imp.object:getIsSelected() and imp.object.spec_trailer.tipSideCount > 0 then
				local tipSideIndex = imp.object.spec_trailer.preferedTipSideIndex
				
				TipSideDisplay:setPositions(imp.object.spec_trailer.tipSides[tipSideIndex])
				if TipSideDisplay.ShowText then
					TipSideDisplay:renderText(imp.object.spec_trailer.tipSides[tipSideIndex])
				end
				TipSideDisplay:renderIcon(imp.object.spec_trailer.tipSides[tipSideIndex])
			end
		end
	end
end

function TipSideDisplay:renderText(tipSide)
	setTextBold(true)
	setTextColor(unpack(self.Colors[self.ColorIndex][2]))
	setTextAlignment(RenderText.ALIGN_LEFT)
	renderText(self.Positions[self.PositionIndex].textPosX, self.Positions[self.PositionIndex].textPosY, self.Positions[self.PositionIndex].textSize, tipSide.name)
	
	-- Back to defaults
	setTextBold(false)
	setTextColor(1,1,1,1)
	setTextAlignment(RenderText.ALIGN_LEFT)
end

function TipSideDisplay:renderIcon(tipSide)
	local img = "none.dds"
	
	if tipSide.name == g_i18n:getText("info_tipSideFront") then
		img = "front.dds"
	elseif tipSide.name == g_i18n:getText("info_tipSideBack") then
		img = "back.dds"
	elseif tipSide.name == g_i18n:getText("info_tipSideLeft") then
		img = "left.dds"
	elseif tipSide.name == g_i18n:getText("info_tipSideRight") then
		img = "right.dds"
	elseif tipSide.name == g_i18n:getText("info_tipSideBackGrainDoor") then
		img = "grain.dds"
	elseif string.find(string.lower(tipSide.animation.name), 'pipe') then
		img = "pipe.dds"		
	end

	-- Make things easier
	--Utils.getFilename("icons/" .. TipSideDisplay.IconSets[TipSideDisplay.IconSetIndex]['path'] .. "/" .. img, self.ModDirectory), TipSideDisplay.Positions[self.PositionIndex].iconPosX, TipSideDisplay.Positions[self.PositionIndex].iconPosY, TipSideDisplay.Positions[self.PositionIndex].iconWidth, TipSideDisplay.Positions[self.PositionIndex].iconHeight

	local file = Utils.getFilename("icons/" .. TipSideDisplay.IconSets[TipSideDisplay.IconSetIndex]['path'] .. "/" .. img, self.ModDirectory)
	local posX = TipSideDisplay.Positions[self.PositionIndex].iconPosX
	local posY = TipSideDisplay.Positions[self.PositionIndex].iconPosY
	local width = TipSideDisplay.Positions[self.PositionIndex].iconWidth
	local height = TipSideDisplay.Positions[self.PositionIndex].iconHeight

	--TipSideDisplay:dp(string.format('P1: %s - P2: %s - P3: %s', tostring(file), tostring(posX), tostring(posY)))
	--TipSideDisplay:dp(string.format('P1: %s - P2: %s - P3: %s', tostring(width), tostring(height), tostring("Empty")))

	local icon = Overlay.new(tostring(file), posX, posY, width, height)
	
	icon:setColor(unpack(self.Colors[self.ColorIndex][2]))
	icon:render()
end

function TipSideDisplay:loadConfigFromXML()
	if fileExists(TipSideDisplay.xmlFilename) then
		TipSideDisplay.saveFile = loadXMLFile('TipSideDisplay.config', TipSideDisplay.xmlFilename);

		if hasXMLProperty(TipSideDisplay.saveFile, "TipSideDisplay") then
			TipSideDisplay.PositionIndex = Utils.getNoNil(getXMLInt(TipSideDisplay.saveFile, "TipSideDisplay.PositionIndex"), 1)
			TipSideDisplay.ColorIndex = Utils.getNoNil(getXMLInt(TipSideDisplay.saveFile, "TipSideDisplay.ColorIndex"), 1)
			TipSideDisplay.ScalingIndex = Utils.getNoNil(getXMLInt(TipSideDisplay.saveFile, "TipSideDisplay.ScalingIndex"), 1)
			TipSideDisplay.IconSetIndex = Utils.getNoNil(getXMLInt(TipSideDisplay.saveFile, "TipSideDisplay.IconSetIndex"), 1)
			TipSideDisplay.ShowText = Utils.getNoNil(getXMLBool(TipSideDisplay.saveFile, "TipSideDisplay.ShowText"), true)

		end
	end
end

function TipSideDisplay:saveConfigToXML()
	TipSideDisplay.saveFile = createXMLFile('TipSideDisplay.config', TipSideDisplay.xmlFilename, "TipSideDisplay")
	setXMLInt(TipSideDisplay.saveFile, "TipSideDisplay.PositionIndex" , TipSideDisplay.PositionIndex)
	setXMLInt(TipSideDisplay.saveFile, "TipSideDisplay.ColorIndex" , TipSideDisplay.ColorIndex)
	setXMLInt(TipSideDisplay.saveFile, "TipSideDisplay.ScalingIndex" , TipSideDisplay.ScalingIndex)
	setXMLInt(TipSideDisplay.saveFile, "TipSideDisplay.IconSetIndex" , TipSideDisplay.IconSetIndex)	
	setXMLBool(TipSideDisplay.saveFile, "TipSideDisplay.ShowText" , TipSideDisplay.ShowText)
	saveXMLFile(TipSideDisplay.saveFile)
end

function TipSideDisplay:renderConfig()
	if self.showConfig then
		local configDescs = {}
		local configValues = {}
		local maxTextWidth = 0
		local confNameWidth = 0
		local confValueWidth = 0
		
		local txtX = self.ConfigScreen.x
		local txtY = self.ConfigScreen.y
		
		setTextAlignment(RenderText.ALIGN_CENTER)
		
		--Render the heading outside of anything else
		setTextBold(true)
		renderText(txtX, txtY, self.ConfigScreen.fontSize, g_i18n.modEnvironments[TipSideDisplay.ModName].texts.conf_heading)
		setTextBold(false)
		
		for index, _ in ipairs(self.Config) do
			table.insert(configDescs, g_i18n.modEnvironments[TipSideDisplay.ModName].texts[self.Config[index].name])
			
			if self.Config[index].name == 'ColorIndex' then
				local colorName = g_i18n.modEnvironments[TipSideDisplay.ModName].texts[tostring(self.Colors[self.ColorIndex][1])]
				table.insert(configValues, colorName)
			elseif self.Config[index].name == 'PositionIndex' then
				local posName = g_i18n.modEnvironments[TipSideDisplay.ModName].texts[tostring(self.Positions[self.PositionIndex]['l10nName'])]
				table.insert(configValues, posName)
			elseif self.Config[index].name == 'IconSetIndex' then
				local setName = self.IconSets[self.IconSetIndex]['name']
				table.insert(configValues, setName)				
			elseif self.Config[index].name == 'Scaling' then
				table.insert(configValues, tostring(self.Scaling[self.ScalingIndex]))				
			else
				if self[self.Config[index].name] then
					table.insert(configValues, g_i18n:getText("ui_yes"))
				else
					table.insert(configValues, g_i18n:getText("ui_no"))
				end
			end
			--ToDo: ConfName from moddesc
			confNameWidth = math.max(confNameWidth, getTextWidth(self.ConfigScreen.fontSize, configDescs[index]))
			confValueWidth = math.max(confValueWidth, getTextWidth(self.ConfigScreen.fontSize, configValues[index]))
			maxTextWidth = math.max(maxTextWidth, confNameWidth + confValueWidth)
			--TipSideDisplay:dp(string.format('%s%s', confName, tostring(self.Config[index].value)))
		end

		
		local textHeight = getTextHeight(self.ConfigScreen.fontSize, 'DUMMY')
		
		local bgWidth = maxTextWidth + (self.ConfigScreen.textPadding * 2) + self.ConfigScreen.colSpacing
		local bgHeight = (textHeight + self.ConfigScreen.textPadding) * ( #configDescs + 2)		-- +2 to include the heading, hence we've to add it at the Y position again, which happens below
		local bgX = self.ConfigScreen['x'] - (bgWidth / 2)
		
		renderOverlay(self.ConfigScreen.bg, bgX, self.ConfigScreen['y'] - bgHeight + (textHeight * 1.5), bgWidth, bgHeight)
		
		local textY = self.ConfigScreen.y
		
		
		for index, confName in pairs(configDescs) do
			local nameX = bgX + (confNameWidth / 2)
			local valX = bgX + confNameWidth + (confValueWidth / 2) + self.ConfigScreen.colSpacing
			textY = textY - textHeight - self.ConfigScreen.textPadding
			
			if index == TipSideDisplay.configSelectedItem then
				setTextColor(unpack(self.ConfigScreen.fontColorSelected))
			else
				setTextColor(unpack(self.ConfigScreen.fontColor))
			end
			renderText(nameX, textY, self.ConfigScreen.fontSize, confName)
			renderText(valX, textY, self.ConfigScreen.fontSize, tostring(configValues[index]))
		end

		--Back to defaults
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1, 1, 1, 1)	
		
		--TipSideDisplay:dp(string.format('maxTextWidth {%s}', maxTextWidth))
		--TipSideDisplay:dp(string.format('bgX {%s}, bgY {%s}, bgWidth {%s}, bgHeight {%s}', self.ConfigScreen['x'], self.ConfigScreen['y'], bgWidth, bgHeight))
	end
end

function TipSideDisplay:changeConfig(veh)
	if self.Config[self.configSelectedItem].name == "ColorIndex" then
		if #TipSideDisplay.Colors > 0 then
			local newIndex = TipSideDisplay.ColorIndex + 1
			if newIndex <= #TipSideDisplay.Colors then
				TipSideDisplay.ColorIndex = newIndex
			else
				TipSideDisplay.ColorIndex = 1
			end
			TipSideDisplay:saveConfigToXML()
		end	
	elseif self.Config[self.configSelectedItem].name == "PositionIndex" then
		if #TipSideDisplay.Positions > 0 then
			local newIndex = TipSideDisplay.PositionIndex + 1
			if newIndex <= #TipSideDisplay.Positions then
				TipSideDisplay.PositionIndex = newIndex
			else
				TipSideDisplay.PositionIndex = 1
			end
			TipSideDisplay:saveConfigToXML()
		end
	elseif self.Config[self.configSelectedItem].name == "Scaling" then
		if #TipSideDisplay.Scaling > 0 then
			local newIndex = TipSideDisplay.ScalingIndex + 1
			if newIndex <= #TipSideDisplay.Scaling then
				TipSideDisplay.ScalingIndex = newIndex
			else
				TipSideDisplay.ScalingIndex = 1
			end
			TipSideDisplay:saveConfigToXML()
		end	
	elseif self.Config[self.configSelectedItem].name == "ShowText" then
		self.ShowText = not self.ShowText
	elseif self.Config[self.configSelectedItem].name == "IconSetIndex" then
		if #TipSideDisplay.IconSets > 0 then
			local newIndex = TipSideDisplay.IconSetIndex + 1
			if newIndex <= #TipSideDisplay.IconSets then
				TipSideDisplay.IconSetIndex = newIndex
			else
				TipSideDisplay.IconSetIndex = 1
			end
			TipSideDisplay:saveConfigToXML()
		end		
	end
end

function TipSideDisplay:freezeCam(setFreeze)
	local veh = g_currentMission.controlledVehicle

	if setFreeze then
		if veh ~= nil then
			-- We just want to mess with the cameras when we can ensure that we can do a backup first
			if TipSideDisplay.camBackup[veh.id] == nil then
				TipSideDisplay.camBackup[veh.id] = {}
				for	i, v in ipairs(veh.spec_enterable.cameras) do
					local cam = {i, v.isRotatable}
					table.insert(TipSideDisplay.camBackup[veh.id], cam)
					v.isRotatable = false
				end
			end
		else
			g_currentMission.isPlayerFrozen = true
		end
	else
		if veh ~= nil then
			if TipSideDisplay.camBackup[veh.id] ~= nil then
				for _, v in ipairs(TipSideDisplay.camBackup[veh.id]) do
					veh.spec_enterable.cameras[v[1]]['isRotatable'] = v[2]
				end
				TipSideDisplay.camBackup[veh.id] = nil
			end
		end
		--Always unfreeze player
		g_currentMission.isPlayerFrozen = false
	end
end

function TipSideDisplay:initSaveGamePath()
	self.userPath = getUserProfileAppPath()
	self.saveBasePath = self.userPath .. 'modSettings/TipSideHud/'
	if g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission:getIsClient() then
		self.mpSavegameName = string.gsub(g_currentMission.missionInfo.savegameName, "%s+", "")
		self.mpMapId = g_currentMission.missionInfo.mapId
		self.mpMapTitle = string.gsub(g_currentMission.missionInfo.mapTitle, "%s+", "")
		if self.mpSavegameName == nil or self.mpMapId == nil or self.mpMapTitle == nil then
			self.mpSavegameName = "UnknownSavegame"
			self.mpMapId = "UnknownMapId"
			self.mpMapTitle = "UnknownMapTitle"
		end
		self.savePath = self.saveBasePath .. "MP_" .. self.mpSavegameName .. '_' .. self.mpMapId .. '_' .. self.mpMapTitle .. '/'
	else
		self.savePath = self.saveBasePath .. 'savegame' .. g_careerScreen.savegameList.selectedIndex .. '/'
	end	
	createFolder(self.userPath .. 'modSettings/')
	createFolder(self.saveBasePath)
	createFolder(self.savePath)
	self.xmlFilename = self.savePath .. 'Config.xml'
end

function TipSideDisplay:isCrane(obj)
	if (obj['typeName'] == 'crane') or (obj['typeName'] == 'FS19_addon_strawHarvest.hallCrane') then
		return true;
	end
end

function TipSideDisplay:isHorse(obj)
	return obj['typeName'] == 'horse';
end

-- This is required to block the camera zoom & handtool selection while drawlist or drawconfig is open
--
function TipSideDisplay.onInputCycleHandTool(self, superFunc, _, _, direction)
	if not TipSideDisplay.showConfig then
		superFunc(self, _, _, direction);
	end
end

function TipSideDisplay.zoomSmoothly(self, superFunc, offset)
	if not TipSideDisplay.showConfig then -- don't zoom camera when mouse wheel is used to scroll displayed list
		superFunc(self, offset);
	end
end

if g_dedicatedServerInfo == nil then
  VehicleCamera.zoomSmoothly = Utils.overwrittenFunction(VehicleCamera.zoomSmoothly, TipSideDisplay.zoomSmoothly);
  Player.onInputCycleHandTool = Utils.overwrittenFunction(Player.onInputCycleHandTool, TipSideDisplay.onInputCycleHandTool);
end


addModEventListener(TipSideDisplay)
Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, TipSideDisplay.onStartMission)

