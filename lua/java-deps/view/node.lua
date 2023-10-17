local M = {}

DataNode = {}

function DataNode:new(parent)
  local o = parent or {}
  setmetatable(o, self)
  self.__index = self
  return o
end
function DataNode:add_child(child)
  if self.childrens == nil then
    self.childrens = {}
  end
  table.insert(self.childrens, child)
  child.parent = self
end

return M
