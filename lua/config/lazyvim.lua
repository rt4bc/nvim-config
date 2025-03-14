local M = {}

M.setup = function()
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	if not (vim.uv or vim.loop).fs_stat(lazypath) then
		local lazyrepo = "https://github.com/folke/lazy.nvim.git"
		local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
		if vim.v.shell_error ~= 0 then
			vim.api.nvim_echo({
				{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
				{ out, "WarningMsg" },
				{ "\nPress any key to exit..." },
			}, true, {})
			vim.fn.getchar()
			os.exit(1)
		end
	end
	vim.opt.rtp:prepend(lazypath)

	require("lazy").setup({
		-- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).

		-- gitsigns
		-- See `:help gitsigns` to understand what the configuration keys do
		{ -- Adds git related signs to the gutter, as well as utilities for managing changes
			"lewis6991/gitsigns.nvim",
			opts = require("plugins.gitsigns"),
		},

		-- which-keys
		{
			-- event = 'VimEnter'
			-- which loads which-key before all the UI elements are loaded. Events can be
			-- normal autocommands events (`:help autocmd-events`).
			-- Then, because we use the `opts` key (recommended), the configuration runs
			-- after the plugin has been loaded as `require(MODULE).setup(opts)`.
			"folke/which-key.nvim",
			event = "VimEnter", -- Sets the loading event to 'VimEnter'
			opts = require("plugins.whichkey"),
		},

		-- Use the `dependencies` key to specify the dependencies of a particular plugin
		-- Fuzzy Finder
		{
			"nvim-telescope/telescope.nvim",
			event = "VimEnter",
			branch = "0.1.x",
			dependencies = {
				"nvim-lua/plenary.nvim",
				-- plenary.nvim 的功能可以分为
				-- 异步编程支持：文件操作：测试框架：实用工具：进程管理：事件和任务管理：
				{ -- If encountering errors, see telescope-fzf-native README for installation instructions
					"nvim-telescope/telescope-fzf-native.nvim",

					-- `build` is used to run some command when the plugin is installed/updated.
					-- This is only run then, not every time Neovim starts up.
					build = "make",

					-- `cond` is a condition used to determine whether this plugin should be
					-- installed and loaded.
					cond = function()
						return vim.fn.executable("make") == 1
					end,
				},
				{ "nvim-telescope/telescope-ui-select.nvim" },
			},
			--  config need a function variable
			config = require("plugins.telescope"),
		},

		-- LUA LSP Plugins
		{
			-- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
			"folke/lazydev.nvim",
			ft = "lua", -- only load on lua files
			opts = {
				library = {
					-- See the configuration section for more details
					-- Load luvit types when the `vim.uv` word is found
					{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				},
			},
		},

		-- MAIN LSP Plugins
		{
			"neovim/nvim-lspconfig",
			dependencies = {
				-- Automatically install LSPs and related tools to stdpath for Neovim
				-- Mason must be loaded before its dependents so we need to set it up here.
				-- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
				{ "williamboman/mason.nvim", opts = {} },
				"williamboman/mason-lspconfig.nvim",
				"WhoIsSethDaniel/mason-tool-installer.nvim",

				-- Useful status updates for LSP.
				-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
				{ "j-hui/fidget.nvim", opts = {} },

				-- Allows extra capabilities provided by nvim-cmp
				"hrsh7th/cmp-nvim-lsp",
			},
			config = require("plugins.lsp"),
		},
		-- {
		-- 	"ray-x/lsp_signature.nvim",
		-- 	event = "LspAttach",
		-- 	config = function()
		-- 		require("lsp_signature").on_attach({
		-- 			bind = true,
		-- 			handler_opts = { border = "rounded" },
		-- 			floating_window = true,
		-- 			hint_enable = true,
		-- 			hint_prefix = "🐼 ",
		-- 			toggle_key = "<C-k>",
		-- 			select_signature_key = "<C-n>",
		-- 			vim.keymap.set({ "n", "i" }, "<C-k>", function()
		-- 				require("lsp_signature").toggle_float_win()
		-- 			end, { silent = true, noremap = true, desc = "Toggle LSP Signature" }),
		-- 		})
		-- 	end,
		-- },
		{
			"stevearc/aerial.nvim",
			dependencies = { "nvim-telescope/telescope.nvim" },
			opts = {},
			-- keys = { { "<leader>ta", "<cmd>Telescope aerial<CR>", desc = "Open Aerial Symbol view" } },
		},

		{ -- Autoformat
			"stevearc/conform.nvim",
			event = { "BufWritePre" },
			cmd = { "ConformInfo" },
			keys = {
				{
					"<leader>f",
					function()
						require("conform").format({ async = true, lsp_format = "fallback" })
					end,
					mode = "",
					desc = "[F]ormat buffer",
				},
			},
			opts = {
				notify_on_error = false,
				format_on_save = function(bufnr)
					-- Disable "format_on_save lsp_fallback" for languages that don't
					-- have a well standardized coding style. You can add additional
					-- languages here or re-enable it for the disabled ones.
					local disable_filetypes = { c = true, cpp = true }
					local lsp_format_opt
					if disable_filetypes[vim.bo[bufnr].filetype] then
						lsp_format_opt = "never"
					else
						lsp_format_opt = "fallback"
					end
					return {
						timeout_ms = 500,
						lsp_format = lsp_format_opt,
					}
				end,
				formatters_by_ft = {
					lua = { "stylua" },
					-- Conform can also run multiple formatters sequentially
					python = { "isort", "black" },
					--
					-- You can use 'stop_after_first' to run the first available formatter from the list
					-- javascript = { "prettierd", "prettier", stop_after_first = true },
				},
			},
		},

		{ -- Autocompletion
			"hrsh7th/nvim-cmp",
			event = "InsertEnter",
			dependencies = {
				-- Snippet Engine & its associated nvim-cmp source
				{
					"L3MON4D3/LuaSnip",
					build = (function()
						-- Build Step is needed for regex support in snippets.
						-- This step is not supported in many windows environments.
						-- Remove the below condition to re-enable on windows.
						if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
							return
						end
						return "make install_jsregexp"
					end)(),
					dependencies = {
						-- `friendly-snippets` contains a variety of premade snippets.
						--    See the README about individual language/framework/plugin snippets:
						--    https://github.com/rafamadriz/friendly-snippets
						-- {
						--   'rafamadriz/friendly-snippets',
						--   config = function()
						--     require('luasnip.loaders.from_vscode').lazy_load()
						--   end,
						-- },
					},
				},
				"saadparwaiz1/cmp_luasnip",

				-- Adds other completion capabilities.
				--  nvim-cmp does not ship with all sources by default. They are split
				--  into multiple repos for maintenance purposes.
				"hrsh7th/cmp-nvim-lsp",
				"hrsh7th/cmp-path",
			},
			config = function()
				-- See `:help cmp`
				local cmp = require("cmp")
				local luasnip = require("luasnip")
				luasnip.config.setup({})

				cmp.setup({
					snippet = {
						expand = function(args)
							luasnip.lsp_expand(args.body)
						end,
					},
					completion = { completeopt = "menu,menuone,noinsert" },

					-- For an understanding of why these mappings were
					-- chosen, you will need to read `:help ins-completion`
					--
					-- No, but seriously. Please read `:help ins-completion`, it is really good!
					mapping = cmp.mapping.preset.insert({
						-- Select the [n]ext item
						["<C-n>"] = cmp.mapping.select_next_item(),
						-- Select the [p]revious item
						["<C-p>"] = cmp.mapping.select_prev_item(),

						-- Scroll the documentation window [b]ack / [f]orward
						["<C-b>"] = cmp.mapping.scroll_docs(-4),
						["<C-f>"] = cmp.mapping.scroll_docs(4),

						-- Accept ([y]es) the completion.
						--  This will auto-import if your LSP supports it.
						--  This will expand snippets if the LSP sent a snippet.
						["<C-y>"] = cmp.mapping.confirm({ select = true }),

						-- If you prefer more traditional completion keymaps,
						-- you can uncomment the following lines
						--['<CR>'] = cmp.mapping.confirm { select = true },
						--['<Tab>'] = cmp.mapping.select_next_item(),
						--['<S-Tab>'] = cmp.mapping.select_prev_item(),

						-- Manually trigger a completion from nvim-cmp.
						--  Generally you don't need this, because nvim-cmp will display
						--  completions whenever it has completion options available.
						["<C-Space>"] = cmp.mapping.complete({}),

						-- Think of <c-l> as moving to the right of your snippet expansion.
						--  So if you have a snippet that's like:
						--  function $name($args)
						--    $body
						--  end
						--
						-- <c-l> will move you to the right of each of the expansion locations.
						-- <c-h> is similar, except moving you backwards.
						["<C-l>"] = cmp.mapping(function()
							if luasnip.expand_or_locally_jumpable() then
								luasnip.expand_or_jump()
							end
						end, { "i", "s" }),
						["<C-h>"] = cmp.mapping(function()
							if luasnip.locally_jumpable(-1) then
								luasnip.jump(-1)
							end
						end, { "i", "s" }),

						-- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
						--    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
					}),
					sources = {
						{
							name = "lazydev",
							-- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
							group_index = 0,
						},
						{ name = "nvim_lsp" },
						{ name = "luasnip" },
						{ name = "path" },
					},
				})
			end,
		},
		{
			"windwp/nvim-autopairs",
			event = "InsertEnter",
			config = true,
		},

		-- colorscheme
		{
			"folke/tokyonight.nvim",
		},
		{
			"ellisonleao/gruvbox.nvim",
			dependencies = { "rktjmp/lush.nvim" },
			lazy = false,
			priority = 1000,
			config = function()
				vim.cmd("colorscheme gruvbox")
			end,
		},

		{
			"goolord/alpha-nvim",
			config = function()
				local alpha = require("alpha")
				local startify = require("alpha.themes.startify")
				-- startify.section.header.val = [[
				-- ]]
				alpha.setup(startify.config)
				vim.keymap.set("n", "<leader>a", ":Alpha<CR>", { noremap = true, silent = true })
			end,
		},

		-- Useful for getting pretty icons, but requires a Nerd Font.
		{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },

		-- buffline
		{
			"nvim-lualine/lualine.nvim",
			event = "VeryLazy",
			dependencies = { "nvim-tree/nvim-web-devicons" },
			opts = {
				theme = "gruvbox",
				section_separators = " ",
				component_separators = " ",
			},
		},

		-- Highly experimental plugin that completely replaces the UI for messages,
		-- Indent line
		{
			"lukas-reineke/indent-blankline.nvim",
			opts = {
				indent = {
					char = "│", -- 设置缩进线的字符
					tab_char = "│", -- 设置 tab 的缩进字符
				},
				scope = {
					enabled = true,
					show_start = true,
					show_end = true,
					injected_languages = true,
					highlight = { "Function", "Label" },
					priority = 500,
				},
				exclude = {
					filetypes = {
						"help",
						"dashboard",
						"lazy",
						"mason",
						"notify",
						"toggleterm",
						"lazyterm",
					},
				},
			},
			config = function(_, opts)
				require("ibl").setup(opts)

				-- 设置缩进线的颜色（可选）
				vim.cmd([[highlight IndentBlanklineChar guifg=#3b4261 gui=nocombine]])
			end,
		},
		-- cmdline and the popupmenu.
		{
			"folke/noice.nvim",
			opts = {
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
			},
		},

		-- Highlight todo, notes, etc in comments
		{
			"folke/todo-comments.nvim",
			event = "VimEnter",
			dependencies = { "nvim-lua/plenary.nvim" },
			opts = { signs = false },
		},

		{ -- Collection of various small independent plugins/modules
			"echasnovski/mini.nvim",
			config = function()
				-- Better Around/Inside textobjects
				--
				-- Examples:
				--  - va)  - [V]isually select [A]round [)]paren
				--  - yinq - [Y]ank [I]nside [N]ext [Q]uote
				--  - ci'  - [C]hange [I]nside [']quote
				require("mini.ai").setup({ n_lines = 500 })

				-- Add/delete/replace surroundings (brackets, quotes, etc.)
				--
				-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
				-- - sd'   - [S]urround [D]elete [']quotes
				-- - sr)'  - [S]urround [R]eplace [)] [']
				require("mini.surround").setup()

				-- Simple and easy statusline.
				--  You could remove this setup call if you don't like it,
				--  and try some other statusline plugin
				local statusline = require("mini.statusline")
				-- set use_icons to true if you have a Nerd Font
				statusline.setup({ use_icons = vim.g.have_nerd_font })

				-- You can configure sections in the statusline by overriding their
				-- default behavior. For example, here we set the section for
				-- cursor location to LINE:COLUMN
				---@diagnostic disable-next-line: duplicate-set-field
				statusline.section_location = function()
					return "%2l:%-2v"
				end

				-- ... and there is more!
				--  Check out: https://github.com/echasnovski/mini.nvim
			end,
		},
		{ -- Highlight, edit, and navigate code
			"nvim-treesitter/nvim-treesitter",
			build = ":TSUpdate",
			main = "nvim-treesitter.configs", -- Sets main module to use for opts
			-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
			opts = {
				ensure_installed = {
					"bash",
					"c",
					"python",
					"rust",
					"diff",
					"html",
					"lua",
					"luadoc",
					"markdown",
					"markdown_inline",
					"query",
					"vim",
					"vimdoc",
				},
				-- Autoinstall languages that are not installed
				auto_install = true,
				highlight = {
					enable = true,
					-- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
					--  If you are experiencing weird indenting issues, add the language to
					--  the list of additional_vim_regex_highlighting and disabled languages for indent.
					additional_vim_regex_highlighting = { "ruby" },
				},
				indent = { enable = true, disable = { "ruby" } },
			},
			-- There are additional nvim-treesitter modules that you can use to interact
			-- with nvim-treesitter. You should go explore a few and see what interests you:
			--
			--    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
			--    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
			--    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
		},

		-- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
		-- init.lua. If you want these files, they are in the repository, so you can just download them and
		-- place them in the correct locations.

		-- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
		--
		--  Here are some example plugins that I've included in the Kickstart repository.
		--  Uncomment any of the lines below to enable them (you will need to restart nvim).
		--
		-- require 'kickstart.plugins.debug',
		-- require 'kickstart.plugins.indent_line',
		-- require 'kickstart.plugins.lint',
		-- require 'kickstart.plugins.autopairs',
		-- require 'kickstart.plugins.neo-tree',
		-- require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps

		-- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
		--    This is the easiest way to modularize your config.
		--
		--  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
		-- { import = 'custom.plugins' },
		--
		-- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
		-- Or use telescope!
		-- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
		-- you can continue same window with `<space>sr` which resumes last telescope search
	})
end

return M.setup()
