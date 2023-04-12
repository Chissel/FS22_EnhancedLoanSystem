-- Name: EAS_settingsMenuExtension
-- Author: Chissel

EAS_settingsMenuExtension = {}
EAS_settingsMenuExtension.initSettingsMenuDone = false

function EAS_settingsMenuExtension:init()
    InGameMenuGameSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuGameSettingsFrame.onFrameOpen, EAS_settingsMenuExtension.onFrameOpen)
end

function EAS_settingsMenuExtension:onFrameOpen()
    if not self.initSettingsMenuDone then
        local target = g_els_settingsMenuExtension

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
        g_els_settingsMenuExtension.steps = g_els_loanManager.loanManagerProperties:getLoanInterestSteps()
        self.els_dynamicLoanInterestValue:setTexts(g_els_settingsMenuExtension.steps)

        g_els_settingsMenuExtension.els_dynamicLoanInterest = self.els_dynamicLoanInterest
        g_els_settingsMenuExtension.els_dynamicLoanInterestValue = self.els_dynamicLoanInterestValue
        g_els_settingsMenuExtension:updateDynmaicLoanInterestState()
        g_els_settingsMenuExtension:updateDynmaicLoanInterestValueState()

        self.initSettingsMenuDone = true
    else
        g_els_settingsMenuExtension:updateDynmaicLoanInterestState()
        g_els_settingsMenuExtension:updateDynmaicLoanInterestValueState()
    end
end

function EAS_settingsMenuExtension:updateDynmaicLoanInterestState()
    if g_els_loanManager.loanManagerProperties.dynamicLoanInterest then
        self.els_dynamicLoanInterest:setState(1)
        self.els_dynamicLoanInterestValue:setDisabled(true)
    else
        self.els_dynamicLoanInterest:setState(2)
        self.els_dynamicLoanInterestValue:setDisabled(false)
    end
end

function EAS_settingsMenuExtension:updateDynmaicLoanInterestValueState()
    for index, value in pairs(self.steps) do
        if tonumber(value) == g_els_loanManager.loanManagerProperties.loanInterest then
            self.els_dynamicLoanInterestValue:setState(index)
        end
    end
end


function EAS_settingsMenuExtension:onDynamicLoanInterestChanged(state)
    g_els_loanManager:toggleDynamicLoanInterest()
    self:updateDynmaicLoanInterestState()
end

function EAS_settingsMenuExtension:onDynamicLoanInterestValueChanged(state)
    local loanInterestValue = tonumber(self.steps[state])
    g_els_loanManager:setLoanInterestValue(loanInterestValue)
    self:updateDynmaicLoanInterestValueState()
end

g_els_settingsMenuExtension = EAS_settingsMenuExtension