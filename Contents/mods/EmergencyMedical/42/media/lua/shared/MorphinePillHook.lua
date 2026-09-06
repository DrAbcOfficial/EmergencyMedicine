-- Vanilla painkiller flow: right-click "Take" -> ISTakePillAction (cast/progress)
-- -> complete(). We hook complete() to inject the custom morphine effect
-- and consume one use, exactly like the vanilla pills do in Java.
if ISTakePillAction then
    local ISTakePillAction_complete = ISTakePillAction.complete
    function ISTakePillAction.complete(self)
        local ret = ISTakePillAction_complete(self)
        local item = self.item
        if item and item:getFullType() == "EmergencyMedical.morphine" then
            local container = item:getContainer()
            if container and container:contains(item) then
                container:RemoveOneOf(item:getType())
            end
            InjectMorphine(self.character)
        end
        return ret
    end
end
