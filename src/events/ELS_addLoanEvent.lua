-- Name: ELS_addLoanEvent
-- Author: Chissel

ELS_addLoanEvent = {}

local ELS_addLoanEvent_mt = Class(ELS_addLoanEvent, Event)
InitEventClass(ELS_addLoanEvent, "ELS_addLoanEvent")

function ELS_addLoanEvent.emptyNew()
    local self = Event.new(ELS_addLoanEvent_mt)

    return self
end

function ELS_addLoanEvent.new(farmId, amount, interest, duration)
    local self = ELS_addLoanEvent.emptyNew()

    self.farmId = farmId
    self.amount = amount
    self.interest = interest
    self.duration = duration

    return self
end

function ELS_addLoanEvent:readStream(streamId, connection)
    self.farmId = streamReadInt32(streamId)
    self.amount = streamReadInt32(streamId)
    self.interest = streamReadFloat32(streamId)
    self.duration = streamReadInt32(streamId)

    self:run(connection)
end

function ELS_addLoanEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.farmId)
    streamWriteInt32(streamId, self.amount)
    streamWriteFloat32(streamId, self.interest)
    streamWriteInt32(streamId, self.duration)
end

function ELS_addLoanEvent:run(connection)
    if not connection:getIsServer() then
        local loan = ELS_loan.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
        loan:init(self.farmId, self.amount, self.interest, self.duration)
        g_els_loanManager:addLoan(loan)
    end
end