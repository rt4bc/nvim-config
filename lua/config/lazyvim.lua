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

	-- 这里传给 setup() 的就是 一个插件列表（table of tables）。
	-- 每个大括号 {} 就代表一个插件的配置，内部就是告诉 lazy.nvim：
	-- 要安装哪个插件（"lewis6991/gitsigns.nvim"）
	-- 装完之后怎么配置（opts = ... 或 config = function() ... end）
	-- 还可以写 event = "InsertEnter"、keys = {...}、cmd = {...} 等触发条件。

	-- opts 和 config的区别
	-- lazy.nvim 会在内部做：
	-- require("gitsigns").setup(opts)
	-- 它会自动 require 插件本身，然后调用 .setup() 把你的 opts 丢进去。
	-- 前提是：插件本身必须导出一个 setup()（大多数 Neovim 插件都是这样设计的，比如 nvim-treesitter、gitsigns.nvim、lualine.nvim）。

	-- 如果一个仓库包含了多个小模块（mini.nvim 就是典型），你就不能简单地只传一个 opts。
	-- 这时候你直接提供 config，告诉 lazy.nvim：
	-- “这个插件需要我手动 require 各个子模块，并手动 .setup() 初始化。”
	-- lazy.nvim 会在插件安装/加载时自动执行这个函数。

	require("lazy").setup({
		-- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).

		-- NOTE: 加载路径
		-- Neovim 的 runtimepath 通常包含以下路径（可通过 :set runtimepath? 查看）
		-- 实际上 Neovim 会从 runtimepath 中的 lua/ 目录去找：
		-- 如果你的配置在 ~/.config/nvim/ 下
		-- 那么 plugins/gitsigns.lua 就是 ~/.config/nvim/lua/plugins/gitsigns.lua

		-- gitsigns
		-- See `:help gitsigns` to understand what the configuration keys do
		{ -- Adds git related signs to the gutter, as well as utilities for managing changes
			"lewis6991/gitsigns.nvim",
			opts = require("plugins.gitsigns"),
		},

		-- colorscheme
		{
			"ellisonleao/gruvbox.nvim",
			dependencies = { "rktjmp/lush.nvim" },
			lazy = false,
			priority = 1000,
			config = function()
				vim.cmd("colorscheme gruvbox")
			end,
		},

		-- UI Dashboard
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

		-- Highlight, edit, and navigate code
		{
			"nvim-treesitter/nvim-treesitter",
			build = ":TSUpdate",
			main = "nvim-treesitter.configs", -- Sets main module to use for opts
			-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
			opts = {
				ensure_installed = {
					"c",
					"python",
					"rust",
					"diff",
					"lua",
					"luadoc",
					"markdown",
					"markdown_inline",
				},
				-- Autoinstall languages that are not installed
				auto_install = true,
				highlight = {
					enable = true,
					-- list of language that will be disabled
					-- disable = { "c", "rust" },
					-- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
					disable = function(lang, buf)
						local max_filesize = 100 * 1024 -- 100 KB
						local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
						if ok and stats and stats.size > max_filesize then
							return true
						end
					end,
				},
				indent = { enable = true, disable = { "ruby" } },
			},
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
			branch = "master",
			event = "VimEnter",
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

		-- code outline widight
		{
			"stevearc/aerial.nvim",
			dependencies = { "nvim-telescope/telescope.nvim" },
			opts = {},
			keys = { { "<leader>sa", "<cmd>Telescope aerial<CR>", desc = "Open Aerial Symbol view" } },
		},

		-- MAIN LSP Plugins
		{
			"neovim/nvim-lspconfig",
			dependencies = {
				-- Automatically install LSPs and related tools to stdpath for Neovim
				-- Mason must be loaded before its dependents so we need to set it up here.
				-- NOTE: opts = {} is the same as calling require('mason').setup({})
				{ "williamboman/mason.nvim", opts = {} },
				"williamboman/mason-lspconfig.nvim",
				"WhoIsSethDaniel/mason-tool-installer.nvim",

				-- Useful status updates for LSP.
				-- NOTE: opts = {} is the same as calling require('fidget').setup({})
				{ "j-hui/fidget.nvim", opts = {} },

				-- Allows extra capabilities provided by nvim-cmp
				"hrsh7th/cmp-nvim-lsp",
			},
			config = require("plugins.lsp"),
			--require("lspconfig").pyright.setup({}),
		},

		-- LUA LSP Plugins, special for lua development under neovim
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

		-- Autocompletion
		{
			"hrsh7th/nvim-cmp",
			event = "InsertEnter",
			dependencies = {
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
				},
				"saadparwaiz1/cmp_luasnip",
				"hrsh7th/cmp-nvim-lsp",
				"hrsh7th/cmp-path",
			},

			config = function()
				local cmp = require("cmp")
				local luasnip = require("luasnip")
				luasnip.config.setup({})

				cmp.setup({
					snippet = {
						expand = function(args)
							luasnip.lsp_expand(args.body)
						end,
					},
					mapping = cmp.mapping.preset.insert({
						["<C-b>"] = cmp.mapping.scroll_docs(-4),
						["<C-f>"] = cmp.mapping.scroll_docs(4),
						["<C-Space>"] = cmp.mapping.complete(),
						["<C-e>"] = cmp.mapping.abort(),
						["<CR>"] = cmp.mapping.confirm({ select = true }),
					}),
					sources = cmp.config.sources({
						{ name = "nvim_lsp" },
						{ name = "luasnip" },
					}, {
						{ name = "buffer" },
						{ name = "path" },
					}),
				})
			end,

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
					-- local disable_filetypes = { c = true, cpp = true }
					local disable_filetypes = {}
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
					python = { "isort", "black" },
					rust = { "rustfmt" },
					c = { "clang_format" },
					cpp = { "clang_format" },
					javascript = { "prettier" },
					javascriptreact = { "prettier" },
					typescript = { "prettier" },
					typescriptreact = { "prettier" },
					html = { "prettier" },
				},
			},
		},

		-- -------------
		-- End
		-- -------------
	})
end

return M.setup()
