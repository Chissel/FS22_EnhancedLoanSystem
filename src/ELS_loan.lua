-- Name: ELS_loan
-- Author: Chissel

ELS_loan = {}
local ELS_loan_mt = Class(ELS_loan, Object)

function ELS_loan.new(farmId, amount, interest, duration, paidOff)
    local self = {}
    setmetatable(self, ELS_loan_mt)

    self.farmId = farmId
    self.amount = amount
    self.interest = interest
    self.duration = duration
    self.restDuration = duration * 12
    self.paidOff = paidOff or false
    self.restAmount = amount

	return self
end

function ELS_loan.recovery(farmId, amount, interest, duration, restDuration, paidOff, restAmount)
    local self = {}
    setmetatable(self, ELS_loan_mt)

    self.farmId = farmId
    self.amount = amount
    self.interest = interest
    self.duration = duration
    self.restDuration = restDuration
    self.paidOff = paidOff
    self.restAmount = restAmount

	return self
end

function ELS_loan:calculateTotalAmount()
    local periodRate = self:calculateAnnuity()
    local totalAmount = periodRate * (self.duration * 12)
    return totalAmount
end

function ELS_loan:calculateAnnuity()
    local annuity = (self.amount * self:calculateAnnuityFactor())
    return annuity / 12
end

function ELS_loan:calculateAnnuityFactor()
    local annuityFactor = (((1 + (self.interest / 100))^self.duration) * (self.interest / 100)) / (((1 + (self.interest / 100))^self.duration) - 1)
    return annuityFactor
end

function ELS_loan:calculateInterestPortion()
    local interestPortion = ((self.interest / 100) * self.restAmount)
    return interestPortion / 12
end

function ELS_loan:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

			self:setFillType(fillType)
		end

		if streamReadBool(streamId) then
			self:setFillLevel(streamReadFloat32(streamId))
		end

		if streamReadBool(streamId) then
			if streamReadBool(streamId) then
				local wrapDiffuse = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

				self:setWrapTextures(wrapDiffuse, nil)
			end

			if streamReadBool(streamId) then
				local wrapNormal = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

				self:setWrapTextures(nil, wrapNormal)
			end
		end

		if streamReadBool(streamId) then
			self:setWrappingState(streamReadUInt8(streamId) / 255, false)
		end

		if streamReadBool(streamId) then
			local r = streamReadFloat32(streamId)
			local g = streamReadFloat32(streamId)
			local b = streamReadFloat32(streamId)
			local a = streamReadFloat32(streamId)

			self:setColor(r, g, b, a)
		end

		if streamReadBool(streamId) then
			self.isFermenting = streamReadBool(streamId)
			self.fermentingPercentage = streamReadUInt8(streamId) / 255
		end
	end

	Bale:superClass().readUpdateStream(self, streamId, timestamp, connection)
end

function ELS_loan:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		if streamWriteBool(streamId, bitAND(dirtyMask, self.fillTypeDirtyFlag) ~= 0) then
			streamWriteUIntN(streamId, self.fillType, FillTypeManager.SEND_NUM_BITS)
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, self.fillLevelDirtyFlag) ~= 0) then
			streamWriteFloat32(streamId, self.fillLevel)
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, self.texturesDirtyFlag) ~= 0) then
			if streamWriteBool(streamId, self.wrapDiffuse ~= nil) then
				streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapDiffuse))
			end

			if streamWriteBool(streamId, self.wrapNormal ~= nil) then
				streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapNormal))
			end
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, self.wrapStateDirtyFlag) ~= 0) then
			streamWriteUInt8(streamId, MathUtil.clamp(self.wrappingState * 255, 0, 255))
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, self.wrapColorDirtyFlag) ~= 0) then
			streamWriteFloat32(streamId, self.wrappingColor[1])
			streamWriteFloat32(streamId, self.wrappingColor[2])
			streamWriteFloat32(streamId, self.wrappingColor[3])
			streamWriteFloat32(streamId, self.wrappingColor[4])
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, self.fermentingDirtyFlag) ~= 0) then
			streamWriteBool(streamId, self.isFermenting)
			streamWriteUInt8(streamId, MathUtil.clamp(self.fermentingPercentage * 255, 0, 255))
		end
	end

	Bale:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
end