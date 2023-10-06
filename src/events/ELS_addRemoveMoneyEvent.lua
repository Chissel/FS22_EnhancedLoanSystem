-- Name: ELS_addRemoveMoneyEvent
-- Author: Chissel

ELS_addRemoveMoneyEvent = {}

local ELS_addRemoveMoneyEvent_mt = Class(ELS_addRemoveMoneyEvent, Event)
InitEventClass(ELS_addRemoveMoneyEvent, "ELS_addRemoveMoneyEvent")

function ELS_addRemoveMoneyEvent.emptyNew()
    local self = Event.new(ELS_addRemoveMoneyEvent_mt)

    return self
end

function ELS_addRemoveMoneyEvent.new(amount, farmId, moneyType)
    local self = ELS_addRemoveMoneyEvent.emptyNew()

    self.amount = amount
    self.farmId = farmId
    self.moneyTypeId = moneyType.id

    return self
end

function ELS_addRemoveMoneyEvent:readStream(streamId, connection)
    self.amount = streamReadInt32(streamId)
    self.farmId = streamReadInt32(streamId, 0)
    self.moneyTypeId = streamReadInt32(streamId, MoneyType.LOAN.id)

    self:run(connection)
end

function ELS_addRemoveMoneyEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.amount)
    streamWriteInt32(streamId, self.farmId, 0)
    streamWriteInt32(streamId, self.moneyTypeId, MoneyType.LOAN.id)
end

function ELS_addRemoveMoneyEvent:run(connection)
    if not connection:getIsServer() then
        local moneyType = MoneyType.getMoneyTypeById(self.moneyTypeId)
        g_els_loanManager:addRemoveMoney(self.amount, self.farmId, moneyType)
    end
end
