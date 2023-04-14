-- Name: ELS_specialRedemptionPaymentDialog
-- Author: Chissel

ELS_specialRedemptionPaymentDialog = {}
local ELS_specialRedemptionPaymentDialog_mt = Class(ELS_specialRedemptionPaymentDialog, MessageDialog)

ELS_specialRedemptionPaymentDialog.CONTROLS = {
    "yesButton",
    "backButton",
	"amountInput",
	"restAmountField"
}

function ELS_specialRedemptionPaymentDialog.new(target, custom_mt, i18n)
	local self = MessageDialog.new(target, custom_mt or ELS_specialRedemptionPaymentDialog_mt)

	self:registerControls(ELS_specialRedemptionPaymentDialog.CONTROLS)

    self.i18n = i18n
	self.callbackArgs = nil
    self.restAmount = 0
    self.currentMoney = 0

	return self
end
function ELS_specialRedemptionPaymentDialog:onOpen()
	ELS_specialRedemptionPaymentDialog:superClass().onOpen(self)

    self:resetUI()

	FocusManager:setFocus(self.amountInput)
end

function ELS_specialRedemptionPaymentDialog:resetUI()
    self.amountInput:setText("")
    self.restAmountField:setText(string.format("%s: %s", self.i18n:getText("els_ui_specialRedemptionPaymentRestAmount"), tostring(self.restAmount)))
    self.amountInput.lastValidText = ""
    self.yesButton:setDisabled(true)
end

function ELS_specialRedemptionPaymentDialog:setAvailableProperties(restAmount, currentMoney)
    self.restAmount = restAmount
    if currentMoney > 0 then
        self.currentMoney = currentMoney
    end
end

function ELS_specialRedemptionPaymentDialog:setCallback(callbackFunc, target)
    self.callbackFunc = callbackFunc
    self.target = target
end

function ELS_specialRedemptionPaymentDialog:onClickOk()
    self:sendCallback(true)
end

function ELS_specialRedemptionPaymentDialog:onClickCancel()
    self:sendCallback(false)
end

function ELS_specialRedemptionPaymentDialog:sendCallback(success)
    self:close()

    if self.callbackFunc ~= nil then
        if self.target ~= nil then
            local amountInput = tonumber(self.amountInput.lastValidText)
            self.callbackFunc(self.target, success, amountInput)
        end
    end
end

function ELS_specialRedemptionPaymentDialog:onTextChanged(element, text)
    if text ~= "" then
        if tonumber(text) ~= nil then
            local currentValue = tonumber(text)

            if currentValue > self.currentMoney then
                currentValue = self.currentMoney
            end

            if currentValue > self.restAmount then
                currentValue = self.restAmount
            end

            local formattedValue = string.format("%.0f", currentValue)
            element:setText(formattedValue)

            element.lastValidText = formattedValue
        else
            element:setText(element.lastValidText)
        end
    else
        element.lastValidText = ""
    end

    self:disableAcceptButtonIfNeeded()
end

function ELS_specialRedemptionPaymentDialog:disableAcceptButtonIfNeeded()
    if self.amountInput.lastValidText ~= nil and self.amountInput.lastValidText ~= "" then
        self.yesButton:setDisabled(false)
    else
        self.yesButton:setDisabled(true)
    end
end