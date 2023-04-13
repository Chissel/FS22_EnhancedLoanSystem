-- Name: ELS_settingsMenuExtension
-- Author: Chissel

ELS_settingsMenuExtension = {}
ELS_settingsMenuExtension.initSettingsMenuDone = false

local ELS_settingsMenuExtension_mt = Class(ELS_settingsMenuExtension)

function ELS_settingsMenuExtension.new(customMt)
	local self = {}
	setmetatable(self, customMt or ELS_settingsMenuExtension_mt)
	return self
end

function ELS_settingsMenuExtension:onFrameOpen()
    if not self.initSettingsMenuDone then
        local target = ELS_settingsMenuExtension

        self.els_dynamicLoanInterest = self.checkHelperRefillFuel:clone()
        self.els_dynamicLoanInterest.target = target
        self.els_dynamicLoanInterest.id = "els_dynamicLoanInterest"
        self.els_dynamicLoanInterest:setCallback("onClickCallback", "onDynamicLoanInterestChanged")

        self.els_dynamicLoanInterest.elements[4]:setText(g_i18n:getText("els_settingsMenu_dynamicLoanInterestTitle"))
        self.els_dynamicLoanInterest.elements[6]:setText(g_i18n:getText("els_settingsMenu_dynamicLoanInterestDescription"))


        self.els_dynamicLoanInterestValue = self.checkHelperRefillFuel:clone()
        self.els_dynamicLoanInterestValue.target = target
        self.els_dynamicLoanInterestValue.id = "els_dynamicLoanInterestValue"
        self.els_dynamicLoanInterestValue:setCallback("onClickCallback", "onDynamicLoanInterestValueChanged")

        self.els_dynamicLoanInterestValue.elements[4]:setText(g_i18n:getText("els_settingsMenu_dynamicLoanInterestValueTitle"))
        self.els_dynamicLoanInterestValue.elements[6]:setText(g_i18n:getText("els_settingsMenu_dynamicLoanInterestValueDescription"))

        local title = TextElement.new()
        title:applyProfile("settingsMenuSubtitle", true)
        title:setText(g_i18n:getText("els_settingsMenu_sectionTitle"))

        self.boxLayout:addElement(title)
        self.boxLayout:addElement(self.els_dynamicLoanInterest)
        self.boxLayout:addElement(self.els_dynamicLoanInterestValue)

        self.els_dynamicLoanInterest:setTexts({g_i18n:getText("ui_on"), g_i18n:getText("ui_off")})
        g_els_settingsMenuExtension.els_steps = g_els_loanManager.loanManagerProperties:getLoanInterestSteps()
        self.els_dynamicLoanInterestValue:setTexts(g_els_settingsMenuExtension.els_steps)

        g_els_settingsMenuExtension.els_dynamicLoanInterest = self.els_dynamicLoanInterest
        g_els_settingsMenuExtension.els_dynamicLoanInterestValue = self.els_dynamicLoanInterestValue

        ELS_settingsMenuExtension.updateDynmaicLoanInterestState()
        ELS_settingsMenuExtension.updateDynmaicLoanInterestValueState()

        self.initSettingsMenuDone = true
    else
        ELS_settingsMenuExtension.updateDynmaicLoanInterestState()
        ELS_settingsMenuExtension.updateDynmaicLoanInterestValueState()
    end
end

function ELS_settingsMenuExtension.updateDynmaicLoanInterestState()
    if g_els_loanManager.loanManagerProperties.dynamicLoanInterest then
        g_els_settingsMenuExtension.els_dynamicLoanInterest:setState(1)
        g_els_settingsMenuExtension.els_dynamicLoanInterestValue:setDisabled(true)
    else
        g_els_settingsMenuExtension.els_dynamicLoanInterest:setState(2)
        g_els_settingsMenuExtension.els_dynamicLoanInterestValue:setDisabled(false)
    end
end

function ELS_settingsMenuExtension.updateDynmaicLoanInterestValueState()
    for index, value in pairs(g_els_settingsMenuExtension.els_steps) do
        if tonumber(value) == g_els_loanManager.loanManagerProperties.loanInterest then
            g_els_settingsMenuExtension.els_dynamicLoanInterestValue:setState(index)
        end
    end
end

function ELS_settingsMenuExtension:onDynamicLoanInterestChanged(state)
    g_els_loanManager:toggleDynamicLoanInterest()
    ELS_settingsMenuExtension.updateDynmaicLoanInterestState()
end

function ELS_settingsMenuExtension:onDynamicLoanInterestValueChanged(state)
    local loanInterestValue = tonumber(g_els_settingsMenuExtension.els_steps[state])
    g_els_loanManager:setLoanInterestValue(loanInterestValue)
    ELS_settingsMenuExtension.updateDynmaicLoanInterestValueState()
end


function init()
    InGameMenuGameSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuGameSettingsFrame.onFrameOpen, ELS_settingsMenuExtension.onFrameOpen)
end

init()

g_els_settingsMenuExtension = ELS_settingsMenuExtension.new()