local highlight = require('lualine.highlight')
local utils = require('lualine.utils.utils')

local LspProgress = require('lualine.component'):new()

--print('Hello\n')
-- LuaFormatter off
LspProgress.default = {
	colors = {
	  percentage  = '#ffffff',
	  title  = '#ffffff',
	  message  = '#ffffff',
	  spinner = '#008080',
	  lsp_client_name = '#c678dd',
	  use = true,
	},
	seperators = {
		seperator = ' | ',
		message = { pre = '(', post = ')'},
		percentage = { pre = '', post = '%% ' },
		title = { pre = '', post = ': ' },
		lsp_client_name = { pre = '[', post = ']' },
		spinner = { pre = '', post = '' },
	},
	display_components = { 'lsp_client_name', 'spinner', { 'title', 'percentage', 'message' } },
	display_spinner = true,
	display_lsp_client_name = true,
	timer = { progress_enddelay = 500, spinner = 1000, lsp_client_name_enddelay = 1000 },
	--spinner_symbols_spinner = { '-', '/', '|', "\\" },
	spinner_symbols = { ' ', ' ', ' ', ' ', ' ', ' ' },
}

-- Initializer
LspProgress.new = function(self, options, child)
  local new_lsp_progress = self._parent:new(options, child or LspProgress)

  new_lsp_progress.options.colors = vim.tbl_extend('force', LspProgress.default.colors, 
										new_lsp_progress.options.colors or {})
  new_lsp_progress.options.seperators = vim.tbl_extend('force', LspProgress.default.seperators, 
										new_lsp_progress.options.seperators or {})
  new_lsp_progress.options.display_components = vim.tbl_extend('force', LspProgress.default.display_components, 
										new_lsp_progress.options.display_components or {})
  new_lsp_progress.options.timer = vim.tbl_extend('force', LspProgress.default.timer, 
										new_lsp_progress.options.timer or {})
  new_lsp_progress.options.spinner_symbols = vim.tbl_extend('force', LspProgress.default.spinner_symbols, 
										new_lsp_progress.options.spinner_symbols or {})
  new_lsp_progress.options.display_spinner = new_lsp_progress.options.display_spinner or LspProgress.default.display_spinner
  new_lsp_progress.options.display_lsp_client_name = new_lsp_progress.options.display_lsp_client_name or LspProgress.default.display_lsp_client_name

  new_lsp_progress.highlights = { percentage = '', title = '', message = '' }
  if new_lsp_progress.options.colors.use then
    new_lsp_progress.highlights.title = highlight.create_component_highlight_group(
	  { fg = new_lsp_progress.options.colors.title }, 'lspprogress_title', new_lsp_progress.options
    )
    new_lsp_progress.highlights.percentage = highlight.create_component_highlight_group(
	  { fg = new_lsp_progress.options.colors.percentage }, 'lspprogress_percentage', new_lsp_progress.options
    )
    new_lsp_progress.highlights.message = highlight.create_component_highlight_group(
	  { fg = new_lsp_progress.options.colors.message }, 'lspprogress_message', new_lsp_progress.options
    )
    new_lsp_progress.highlights.spinner = highlight.create_component_highlight_group(
	  { fg = new_lsp_progress.options.colors.spinner }, 'lspprogress_spinner', new_lsp_progress.options
    )
    new_lsp_progress.highlights.lsp_client_name = highlight.create_component_highlight_group(
	  { fg = new_lsp_progress.options.colors.lsp_client_name }, 'lspprogress_lsp_client_name', new_lsp_progress.options
    )
  end



  -- Setup callback to get updates from the lsp to update lualine.

  new_lsp_progress:register_progress()
  -- No point in setting spinner callbacks if it is not displayed.
  if new_lsp_progress.options.display_spinner then
	  new_lsp_progress:setup_spinner()
  end

  -- print(LspProgress.progress.message)
  return new_lsp_progress
end

LspProgress.update_status = function(self)
	self:update_progress()
	return self.progress_message
end


LspProgress.register_progress = function(self)
  self.clients = {}

  self.progress_callback = function (_, _, msg, client_id_int)
  	local key = msg.token
  	local val = msg.value
	local client_id = tostring(client_id_int)

	-- print(vim.inspect(msg))

  	if key then
		if self.clients[client_id] == nil then
			self.clients[client_id] = { progress = {}, name = vim.lsp.get_client_by_id(client_id_int).name }
			--print('INITIALISE!!!!!!!!!!!!!!!!')
		end
		local progress_collection = self.clients[client_id].progress
		if progress_collection[key] == nil then
			--print(key)
			--print(vim.inspect(progress_collection))
			--print(vim.inspect(msg))
			progress_collection[key] = { title = nil, message = nil, percentage = nil }
		end

		local progress = progress_collection[key]
		--print("'" .. client_id .. "'")
		--print(vim.inspect(progress_collection))

  		if val then
  			if val.kind == 'begin' then
				progress.title = val.title
				--print('"' .. key .. ': ' .. val.title .. '"')
  			end
			if val.kind == 'report' then
				--print('"progress: ' .. key .. '.. ' .. vim.inspect(progress) .. '"')
				if val.percentage then
					progress.percentage = val.percentage
				end
				if val.message then
					progress.message = val.message
				end
				--print('"progress: ' .. key .. '.. ' .. vim.inspect(progress) .. '"')
  			end
			if val.kind == 'end' then
				if progress.percentage then
					progress.percentage = '100'
					progress.message = 'Completed'
				end
				vim.defer_fn(function() 
					--print('Removing: "' .. key .. '"')
					if self.clients[client_id] then
						self.clients[client_id].progress[key] = nil
					end
					vim.defer_fn(function()
						local has_items = false
						for _, _ in pairs(self.clients[client_id].progress) do
							has_items = 1
							break
						end
						if has_items == false then
							self.clients[client_id] = nil
						end
					end, self.options.timer.lsp_client_name_enddelay)
				end, self.options.timer.progress_enddelay)
			end
  		end
		--print(vim.inspect(msg))
  	end
  end

  vim.lsp.handlers["$/progress"] = self.progress_callback
end

LspProgress.update_progress = function(self)
	local options = self.options
	local result = {}


	for _, client in pairs(self.clients) do
		for _, display_component in pairs(self.options.display_components) do
			if display_component == 'lsp_client_name' and options.display_lsp_client_name then
				if options.colors.use then
					table.insert(result, highlight.component_format_highlight(self.highlights.lsp_client_name) .. client.name)
				else
					table.insert(result, client.name)
				end
			end
			if display_component == 'spinner' and options.display_spinner then
				local progress = client.progress
				for _, _ in pairs(progress) do
					if options.colors.use then
						table.insert(result, highlight.component_format_highlight(self.highlights.spinner) .. self.spinner.symbol)
					else
						table.insert(result, self.spinner.symbol)
					end
					break
				end
			end
			if type(display_component) == "table" then
				self:update_progress_components(result, display_component, client.progress)
			end
		end
	end
	if #result > 0 then
		self.progress_message = table.concat(result, options.seperators.seperator)
	else
		self.progress_message = ''
	end
end

LspProgress.update_progress_components = function(self, result, display_components, client_progress)
	local p = {}
	local options = self.options
	for _, progress in pairs(client_progress) do
		--print(vim.inspect(progress) .. '\n\r')
		if progress.title then
			for _, i in pairs(display_components) do
				if progress[i] then
					if options.colors.use then
						table.insert(p, highlight.component_format_highlight(self.highlights[i]) .. options.seperators[i].pre .. progress[i] .. options.seperators[i].post)
					else 
						table.insert(p, options.seperators[i].pre .. progress[i] .. options.seperators[i].post)
					end
				end
			end
			table.insert(result, table.concat(p, ''))
		end
	end
--	print(vim.inspect(progress))
end


LspProgress.setup_spinner = function(self)
	self.spinner = {}
	self.spinner.index = 0
	self.spinner.symbol_mod = #self.options.spinner_symbols
	self.spinner.symbol = self.options.spinner_symbols[1]
	local timer = vim.loop.new_timer()
	timer:start(0, self.options.timer.spinner,
	function()
	--	print('Spinner\n\r')
	--	print(LspProgress.spinner.index .. '\n\r')
		self.spinner.index = (self.spinner.index % self.spinner.symbol_mod) + 1
	--	print(LspProgress.spinner.index .. '\n\r')
		self.spinner.symbol = self.options.spinner_symbols[self.spinner.index]
	--	print(LspProgress.spinner.index .. ': ' .. LspProgress.spinner.symbol .. '\n\r')
	end)
end

return LspProgress
