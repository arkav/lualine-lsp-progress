-- displays the status of active lsp clients
local LspProgress = require('lualine.component'):new()
local _clients = {}
local _status = ''
local function _update()
	local status = ''
	for i, client in ipairs(_clients) do
		status = status .. '[' .. client.name .. '] '
		for j, task in pairs(client.tasks) do
			status = status .. task.title	
			if task.percentage then status = status .. ' ' .. task.percentage .. '%%' end
			if task.message then status = status .. ' ' .. task.message end
		end
		if i < #_clients then status = status .. ',' end
	end
	return status
end
local function progress_callback(_, _, msg, client_id) 
	local val = msg.value
	if val.kind then 
		if val.kind == 'begin' then
			if not _clients[client_id] then
				_clients[client_id]= {
					name = vim.lsp.get_client_by_id(client_id).name,
					tasks = {}
				}
			end
			_clients[client_id].tasks[msg.token] = {
				title = val.title,
				message = val.message,
				percentage = val.percentage
			}
			_status = _update()
		elseif val.kind == 'report' and _clients[client_id] then
			_clients[client_id].tasks[msg.token].message = val.message
			_clients[client_id].tasks[msg.token].percentage = val.percentage
			_status = _update()
		elseif val.kind == 'end' then
			_clients[client_id].tasks[msg.token] = nil
			_status = _update()
		end
	end 
end

vim.lsp.handlers['$/progress'] = progress_callback

LspProgress.update_status = function()
	return _status
end

return LspProgress
