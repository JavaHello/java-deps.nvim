local NodeKind = require("java-deps.java.enums").NodeKind

---@class TreeItem
---@field label? string
---@field id? string
---@field icon? string
---@field depth? number
---@field description? string
---@field resourceUri? string
---@field command? string
---@field isLast? boolean
---@field data? DataNode
---@field hierarchy? table
---@field prefix_length? number
local TreeItem = {}
TreeItem.__index = TreeItem

---@enum TreeItemCollapsibleState
TreeItem.CollapsibleState = {
  None = 0,
  Collapsed = 1,
  Expanded = 2,
}
local CollapsibleState = TreeItem.CollapsibleState

---@param data DataNode
---@return TreeItem
function TreeItem:new(data)
  return setmetatable({ data = data }, self)
end

---@return TreeItemCollapsibleState
function TreeItem:collapsible_state()
  return self.data:collapsible_state()
end

---@return boolean
function TreeItem:is_foldable()
  local state = self:collapsible_state()
  return state == CollapsibleState.Collapsed or state == CollapsibleState.Expanded
end

---@return boolean
function TreeItem:is_expanded()
  return self:collapsible_state() == CollapsibleState.Expanded
end

---@return boolean
function TreeItem:is_collapsed()
  return self:collapsible_state() == CollapsibleState.Collapsed
end

function TreeItem:expanded()
  if not self:is_foldable() or self:is_expanded() then
    return
  end
  self.data._collapsibleState = CollapsibleState.Expanded
  self.data:get_children()
end

function TreeItem:collapsed()
  if not self:is_foldable() or self:is_collapsed() then
    return
  end
  self.data._collapsibleState = CollapsibleState.Collapsed
end

function TreeItem:fold_toggle()
  if self:is_expanded() then
    self:collapsed()
  else
    self:expanded()
  end
end

---是否是文件可以打开
function TreeItem:can_open()
  local kind = self.data:kind()
  return kind == NodeKind.PrimaryType or kind == NodeKind.ClassFile or kind == NodeKind.File
end

return TreeItem
