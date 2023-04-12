-- Name: ELS_specialRedemptionPaymentEvent
-- Author: Chissel

ELS_specialRedemptionPaymentEvent = {}

local ELS_specialRedemptionPaymentEvent_mt = Class(ELS_specialRedemptionPaymentEvent, Event)
InitEventClass(ELS_specialRedemptionPaymentEvent, "ELS_specialRedemptionPaymentEvent")

function ELS_specialRedemptionPaymentEvent.emptyNew()
    local self = Event.new(ELS_specialRedemptionPaymentEvent_mt)

    return self
end

function ELS_specialRedemptionPaymentEvent.new(farmId, loanId, amount)
    local self = ELS_specialRedemptionPaymentEvent.emptyNew()

    self.farmId = farmId
    self.loanId = loanId
    self.amount = amount

    return self
end

function ELS_specialRedemptionPaymentEvent:readStream(streamId, connection)
    self.farmId = streamReadInt32(streamId)
    self.loanId = streamReadInt32(streamId)
    self.amount = streamReadInt32(streamId)

    self:run(connection)
end

function ELS_specialRedemptionPaymentEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.farmId)
    streamWriteInt32(streamId, self.loanId)
    streamWriteInt32(streamId, self.amount)
end

function ELS_specialRedemptionPaymentEvent:run(connection)
    if not connection:getIsServer() then
        g_els_loanManager:excecuteSpecialRedemptionPayment(self.farmId, self.loanId, self.amount)
    end
end