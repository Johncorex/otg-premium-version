function onCreatureAppear(self, creature)
    if self == creature then
        self:registerEvent("salaBoss")
    end
end
