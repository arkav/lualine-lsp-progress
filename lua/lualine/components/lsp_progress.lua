local highlight = require('lualine.highlight')
local utils = require('lualine.utils.utils')

local LspProgress = require('lualine.component'):new()

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
		component = ' ',
		progress = ' | ',
		message = { pre = '(', post = ')'},
		percentage = { pre = '', post = '%% ' },
		title = { pre = '', post = ': ' },
		lsp_client_name = { pre = '[', post = ']' },
		spinner = { pre = '', post = '' },
	},
	display_components = { 'lsp_client_name', 'spinner', { 'title', 'percentage', 'message' } },
	timer = { progress_enddelay = 500, spinner = 500, lsp_client_name_enddelay = 1000 },
	spinner_symbols_dice = { ' ', ' ', ' ', ' ', ' ', ' ' }, -- Nerd fonts needed
	spinner_symbols_moon = { '🌑 ', '🌒 ', '🌓 ', '🌔 ', '🌕 ', '🌖 ', '🌗 ', '🌘 ' },
	spinner_symbols_square = {'▙ ', '▛ ', '▜ ', '▟ ' },
	spinner_symbols = {'▙ ', '▛ ', '▜ ', '▟ ' },
	message = { commenced = 'In Progress', completed = 'Completed' },
}

-- Initializer
LspProgress.new = function(self, options, child)
  local new_lsp_progress = self._parent:new(options, child or LspProgress)

  new_lsp_progress.options.colors = vim.tbl_extend('force', LspProgress.default.colors, 
										new_lsp_progress.options.colors or {})
  new_lsp_progress.options.seperators = vim.tbl_extend('force', LspProgress.default.seperators, 
										new_lsp_progress.options.seperators or {})
  new_lsp_progress.options.display_components = new_lsp_progress.options.display_components or LspProgress.default.display_components
  new_lsp_progress.options.timer = vim.tbl_extend('force', LspProgress.default.timer, 
										new_lsp_progress.options.timer or {})
  new_lsp_progress.options.spinner_symbols = vim.tbl_extend('force', LspProgress.default.spinner_symbols, 
										new_lsp_progress.options.spinner_symbols or {})
  new_lsp_progress.options.message = vim.tbl_extend('force', LspProgress.default.message, 
										new_lsp_progress.options.message or {})

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
  for _, display_component in pairs(new_lsp_progress.options.display_components) do
	  if display_component == 'spinner' then
		  new_lsp_progress:setup_spinner()
		  break
	  end
  end

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


  	if key then
		if self.clients[client_id] == nil then
			self.clients[client_id] = { progress = {}, name = vim.lsp.get_client_by_id(client_id_int).name }
		end
		local progress_collection = self.clients[client_id].progress
		if progress_collection[key] == nil then
			progress_collection[key] = { title = nil, message = nil, percentage = nil }
		end

		local progress = progress_collection[key]

  		if val then
  			if val.kind == 'begin' then
				progress.title = val.title
				progress.message = self.options.message.commenced
  			end
			if val.kind == 'report' then
				if val.percentage then
					progress.percentage = val.percentage
				end
				if val.message then
					progress.message = val.message
				end
  			end
			if val.kind == 'end' then
				if progress.percentage then
					progress.percentage = '100'
				end
				progress.message = self.options.message.completed
				vim.defer_fn(function() 
					if self.clients[client_id] then
						self.clients[client_id].progress[key] = nil
					end
					vim.defer_fn(function()
						local has_items = false
						if self.clients[client_id] and self.clients[client_id].progress then
							for _, _ in pairs(self.clients[client_id].progress) do
								has_items = 1
								break
							end
						end
						if has_items == false then
							self.clients[client_id] = nil
						end
					end, self.options.timer.lsp_client_name_enddelay)
				end, self.options.timer.progress_enddelay)
			end
  		end
  	end
  end

  vim.lsp.handlers["$/progress"] = self.progress_callback
end

LspProgress.update_progress = function(self)
	local options = self.options
	local result = {}


	for _, client in pairs(self.clients) do
		for _, display_component in pairs(self.options.display_components) do
			if display_component == 'lsp_client_name' then
				if options.colors.use then
					table.insert(result, highlight.component_format_highlight(self.highlights.lsp_client_name) .. options.seperators.lsp_client_name.pre .. client.name .. options.seperators.lsp_client_name.post)
				else
					table.insert(result, options.seperators.lsp_client_name.pre .. client.name .. options.seperators.lsp_client_name.post)
				end
			end
			if display_component == 'spinner' then
				local progress = client.progress
				for _, _ in pairs(progress) do
					if options.colors.use then
						table.insert(result, highlight.component_format_highlight(self.highlights.spinner) .. options.seperators.spinner.pre .. self.spinner.symbol .. options.seperators.spinner.post)
					else
						table.insert(result, options.seperators.spinner.pre .. self.spinner.symbol .. options.seperators.spinner.post)
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
		self.progress_message = table.concat(result, options.seperators.component)
	else
		self.progress_message = ''
	end
end

LspProgress.update_progress_components = function(self, result, display_components, client_progress)
	local p = {}
	local options = self.options
	for _, progress in pairs(client_progress) do
		if progress.title then
			local d = {}
			for _, i in pairs(display_components) do
				if progress[i] and progress[i] ~= '' then
					if options.colors.use then
						table.insert(d, highlight.component_format_highlight(self.highlights[i]) .. options.seperators[i].pre .. progress[i] .. options.seperators[i].post)
					else 
						table.insert(d, options.seperators[i].pre .. progress[i] .. options.seperators[i].post)
					end
				end
			end
			table.insert(p, table.concat(d, ''))
		end
		table.insert(result, table.concat(p, options.seperators.progress))
	end
end


LspProgress.setup_spinner = function(self)
	self.spinner = {}
	self.spinner.index = 0
	self.spinner.symbol_mod = #self.options.spinner_symbols
	self.spinner.symbol = self.options.spinner_symbols[1]
	local timer = vim.loop.new_timer()
	timer:start(0, self.options.timer.spinner,
	function()
		self.spinner.index = (self.spinner.index % self.spinner.symbol_mod) + 1
		self.spinner.symbol = self.options.spinner_symbols[self.spinner.index]
	end)
end

return LspProgress
