local highlight = require('lualine.highlight')

local LspProgress = require('lualine.component'):extend()

-- LuaFormatter off
LspProgress.default = {
	colors = {
	percentage = '#ffffff',
		title = '#ffffff',
		message = '#ffffff',
		spinner = '#008080',
		lsp_client_name = '#c678dd',
		use = false,
	},
	separators = {
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
LspProgress.init = function(self, options)
	LspProgress.super.init(self, options)

	self.options.colors = vim.tbl_extend('force', LspProgress.default.colors, self.options.colors or {})
	self.options.separators = vim.tbl_deep_extend('force', LspProgress.default.separators, self.options.separators or {})
	self.options.display_components = self.options.display_components or LspProgress.default.display_components
	self.options.timer = vim.tbl_extend('force', LspProgress.default.timer, self.options.timer or {})
	self.options.spinner_symbols = vim.tbl_extend('force', LspProgress.default.spinner_symbols, self.options.spinner_symbols or {})
	self.options.message = vim.tbl_extend('force', LspProgress.default.message, self.options.message or {})

	self.highlights = { percentage = '', title = '', message = '' }
	if self.options.colors.use then
		self.highlights.title = highlight.create_component_highlight_group({ fg = self.options.colors.title }, 'lspprogress_title', self.options)
		self.highlights.percentage = highlight.create_component_highlight_group({ fg = self.options.colors.percentage }, 'lspprogress_percentage', self.options)
		self.highlights.message = highlight.create_component_highlight_group({ fg = self.options.colors.message }, 'lspprogress_message', self.options)
		self.highlights.spinner = highlight.create_component_highlight_group({ fg = self.options.colors.spinner }, 'lspprogress_spinner', self.options)
		self.highlights.lsp_client_name = highlight.create_component_highlight_group({ fg = self.options.colors.lsp_client_name }, 'lspprogress_lsp_client_name', self.options)
	end
	-- Setup callback to get updates from the lsp to update lualine.

	self:register_progress()
		-- No point in setting spinner callbacks if it is not displayed.
	for _, display_component in pairs(self.options.display_components) do
		if display_component == 'spinner' then
			self:setup_spinner()
			break
		end
	end
end

LspProgress.update_status = function(self)
	self:update_progress()
	return self.progress_message
end


LspProgress.register_progress = function(self)
	self.clients = {}

	self.progress_callback = function(_, msg, info)
		local key = msg.token
		local val = msg.value
		local client_key = tostring(info.client_id)

		if key then
			if self.clients[client_key] == nil then
				self.clients[client_key] = { progress = {}, name = vim.lsp.get_client_by_id(info.client_id).name }
			end
			local progress_collection = self.clients[client_key].progress
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
						if self.clients[client_key] then
							self.clients[client_key].progress[key] = nil
						end
						vim.defer_fn(function()
							local has_items = false
							if self.clients[client_key] and self.clients[client_key].progress then
								for _, _ in pairs(self.clients[client_key].progress) do
									has_items = 1
									break
								end
							end
							if has_items == false then
								self.clients[client_key] = nil
							end
						end, self.options.timer.lsp_client_name_enddelay)
					end, self.options.timer.progress_enddelay)
				end
			end
		end
	end
	-- TODO: remove once new api makes it into stable
	-- we need a wrapper around our function here to handle the new lsp handler protocol while still supporting stable
	vim.lsp.handlers["$/progress"] = function(...)
		local arg = select(4, ...)
		if type(arg) ~= 'number' then
			self.progress_callback(...)
		else
			self.progress_callback(
				select(1, ...), -- err
				select(3, ...), -- msg
				{
					client_id = select(4, ...)
				}
			)
		end
	end
end

-- add support for new handler format

LspProgress.update_progress = function(self)
	local options = self.options
	local result = {}


	for _, client in pairs(self.clients) do
		for _, display_component in pairs(self.options.display_components) do
			if display_component == 'lsp_client_name' then
				if options.colors.use then
					table.insert(result, highlight.component_format_highlight(self.highlights.lsp_client_name) .. options.separators.lsp_client_name.pre .. client.name .. options.separators.lsp_client_name.post)
				else
					table.insert(result, options.separators.lsp_client_name.pre .. client.name .. options.separators.lsp_client_name.post)
				end
			end
			if display_component == 'spinner' then
				local progress = client.progress
				for _, _ in pairs(progress) do
					if options.colors.use then
						table.insert(result, highlight.component_format_highlight(self.highlights.spinner) .. options.separators.spinner.pre .. self.spinner.symbol .. options.separators.spinner.post)
					else
						table.insert(result, options.separators.spinner.pre .. self.spinner.symbol .. options.separators.spinner.post)
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
		self.progress_message = table.concat(result, options.separators.component)
		if type(vim.g.lualine_progress_msglen) == "number" then
			self.progress_message = string.sub(self.progress_message, 1, vim.g.lualine_progress_msglen)
		end
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
						table.insert(d, highlight.component_format_highlight(self.highlights[i]) .. options.separators[i].pre .. progress[i] .. options.separators[i].post)
					else
						table.insert(d, options.separators[i].pre .. progress[i] .. options.separators[i].post)
					end
				end
			end
			table.insert(p, table.concat(d, ''))
		end
		table.insert(result, table.concat(p, options.separators.progress))
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
