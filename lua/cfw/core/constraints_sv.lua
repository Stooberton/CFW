local connect      = CFW.connect
local disconnect   = CFW.disconnect
local timerSimple  = timer.Simple
local isConstraint = {
    phys_hinge = true, -- axis
    phys_lengthconstraint = true, -- rope
    phys_constraint = true, -- weld
    phys_ballsocket = true, -- ballsocket
    phys_spring = true, -- elastic, hydraulics, muscles
    phys_pulleyconstraint = true, -- pulley (do people ever use these?)
    phys_slideconstraint = true, -- sliders
}

local function onRemove(con)
    disconnect(con.Ent1, con.Ent2 or con.Ent4)
end

-- This is a dumb hack necessitated by SetTable being called on constraints immediately after they are created
-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/modules/constraint.lua#L449
-- Any data stored in the same tick the constraint is created will be removed. Thus, we delay for one tick
-- This also conveniently prevents CFW from responding to constraints created and removed in the same tick
hook.Add("OnEntityCreated", "CFW", function(con)
    if isConstraint[con:GetClass()] then
        timerSimple(0, function()
            if IsValid(con)then
                local a, b = con.Ent1, con.Ent2 or con.Ent4
                
                if not IsValid(a) or a:IsWorld() then return end
                if not IsValid(b) or b:IsWorld() then return end

                con:CallOnRemove("CFW", onRemove)

                connect(a, b)
            end
        end)
    end
end)

-- Elastics and Hydraulics break during undos for some reason. This is a workaround.
-- Since all of the entities are being removed, we don't care about the individual disconnections
-- Just remove the contraption.
hook.Add("PreUndo", "CFW.undo", function(undo)
    if undo.Name == "AdvDupe2" then
        local alreadyRemoved = {}

        for idx, ent in ipairs(undo.Entities) do
            for _, con in ipairs(ent.Constraints) do
                if isConstraint[con:GetClass()] then
                    con._cfwRemoved = true -- For parents
                    con:RemoveCallOnRemove("CFW") -- For constraints
                end
            end

            local c = ent:GetContraption()

            if c and not alreadyRemoved[c] then
                alreadyRemoved[c] = true

                c:Remove()
            end
        end
    end
end)