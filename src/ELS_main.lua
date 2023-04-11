-- Name: ELS_main
-- Author: Chissel

local modName = g_currentModName
local modDirectory = g_currentModDirectory

source(g_currentModDirectory .. "src/ELS_loanManager.lua")
source(g_currentModDirectory .. "src/ELS_loan.lua")
source(g_currentModDirectory .. "src/gui/ELS_inGameMenuLoanSystem.lua")
source(g_currentModDirectory .. "src/gui/ELS_takeLoanDialog.lua")
source(g_currentModDirectory .. "src/gui/ELS_specialRedemptionPaymentDialog.lua")
source(g_currentModDirectory .. "src/events/ELS_addRemoveMoneyEvent.lua")

addModEventListener(ELS_loanManager)

function loadedMission()
    g_gui:loadProfiles(modDirectory.."gui/ELS_guiProfiles.xml")

	local guiLoanSystem = ELS_inGameMenuLoanSystem.new(g_i18n, g_messageCenter)
	g_gui:loadGui(modDirectory.."gui/ELS_inGameMenuLoanSystem.xml", "InGameMenuLoanSystem", guiLoanSystem, true)
		
    fixInGameMenu(guiLoanSystem, "InGameMenuLoanSystem", {0,0,1024,1024}, 3, nil)

	guiLoanSystem:initialize()	
end

function fixInGameMenu(frame, pageName, uvs, position, predicateFunc)
	local inGameMenu = g_gui.screenControllers[InGameMenu]

	-- remove all to avoid warnings
	for k, v in pairs({pageName}) do
		inGameMenu.controlIDs[v] = nil
	end

	inGameMenu:registerControls({pageName})

	
	inGameMenu[pageName] = frame
	inGameMenu.pagingElement:addElement(inGameMenu[pageName])

	inGameMenu:exposeControlsAsFields(pageName)

	for i = 1, #inGameMenu.pagingElement.elements do
		local child = inGameMenu.pagingElement.elements[i]
		if child == inGameMenu[pageName] then
			table.remove(inGameMenu.pagingElement.elements, i)
			table.insert(inGameMenu.pagingElement.elements, position, child)
			break
		end
	end

	for i = 1, #inGameMenu.pagingElement.pages do
		local child = inGameMenu.pagingElement.pages[i]
		if child.element == inGameMenu[pageName] then
			table.remove(inGameMenu.pagingElement.pages, i)
			table.insert(inGameMenu.pagingElement.pages, position, child)
			break
		end
	end

	inGameMenu.pagingElement:updateAbsolutePosition()
	inGameMenu.pagingElement:updatePageMapping()
	
	inGameMenu:registerPage(inGameMenu[pageName], position, predicateFunc)
	local iconFileName = Utils.getFilename('images/menuIcon.dds', modDirectory)
	inGameMenu:addPageTab(inGameMenu[pageName],iconFileName, GuiUtils.getUVs(uvs))
	inGameMenu[pageName]:applyScreenAlignment()
	inGameMenu[pageName]:updateAbsolutePosition()

	for i = 1, #inGameMenu.pageFrames do
		local child = inGameMenu.pageFrames[i]
		if child == inGameMenu[pageName] then
			table.remove(inGameMenu.pageFrames, i)
			table.insert(inGameMenu.pageFrames, position, child)
			break
		end
	end

	inGameMenu:rebuildTabList()
end

function init()
    Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, loadedMission)
    Mission00.load = Utils.appendedFunction(Mission00.load, ELS_loanManager.loadFromXMLFile)
    FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, ELS_loanManager.saveToXMLFile)
    TreePlantManager.readFromServerStream = Utils.appendedFunction(TreePlantManager.readFromServerStream, ELS_loanManager.readFromServerStream)
    TreePlantManager.writeToClientStream = Utils.appendedFunction(TreePlantManager.writeToClientStream, ELS_loanManager.writeToClientStream)
end

init()