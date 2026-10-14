-- jdtls 返回的节点数据基类, 字段名与 jdtls 协议保持一致
---@class NodeData
---@field displayName? string
---@field name string
---@field moduleName? string
---@field path? string
---@field handlerIdentifier? string
---@field uri? string
---@field kind NodeKind
---@field children? NodeData[]
---@field metaData? table<string, any>
local NodeData = {}
NodeData.__index = NodeData

---@param data? table jdtls 返回的原始数据
---@return NodeData
function NodeData:new(data)
  return setmetatable(data or {}, self)
end

function NodeData:get_display_name()
  return self.displayName
end

function NodeData:get_name()
  return self.name
end

function NodeData:get_module_name()
  return self.moduleName
end

function NodeData:get_path()
  return self.path
end

function NodeData:get_handler_identifier()
  return self.handlerIdentifier
end

function NodeData:get_uri()
  return self.uri
end

function NodeData:get_kind()
  return self.kind
end

function NodeData:get_children()
  return self.children
end

function NodeData:get_meta_data()
  return self.metaData
end

return NodeData
