return {
	-- 启用命令行 UI，但只保留命令输入提示
	cmdline = {
		enabled = true, -- 启用命令行 UI
		view = "cmdline_popup", -- 使用弹出式命令行视图
		opts = {
			position = {
				row = "50%",
				col = "50%",
			},
			size = {
				width = 60,
				height = "auto",
			},
		},
		format = {
			-- 禁用其他命令类型的覆盖，只保留常规命令输入
			cmdline = { pattern = "^:", icon = "", lang = "vim" },
			search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
			search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
			filter = false,
			lua = false,
			help = false,
			input = false,
		},
	},

	-- 配置消息显示
	messages = {
		enabled = false, -- 禁用消息 UI
	},

	-- 配置弹窗通知
	notify = {
		enabled = true, -- 启用通知
	},

	-- 配置 LSP 进度
	lsp = {
		progress = {
			enabled = true, -- 保持 LSP 进度提示
		},
		hover = {
			enabled = true, -- 保持 LSP 悬浮提示
		},
		signature = {
			enabled = true, -- 保持函数签名提示
		},
		message = {
			enabled = true, -- 保持 LSP 消息提示
		},
	},

	-- 禁用所有预设视图
	presets = {
		bottom_search = false, -- 使用默认搜索
		command_palette = false, -- 使用默认命令面板
		long_message_to_split = false, -- 长消息不使用分割窗口
		inc_rename = false, -- 使用默认重命名
		lsp_doc_border = false, -- 不使用 LSP 文档边框
	},
}
