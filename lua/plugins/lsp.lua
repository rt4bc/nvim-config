local M = {}

M.config = function()
	-- Brief aside: **What is LSP?**
	--
	-- LSP is an initialism you've probably heard, but might not understand what it is.
	--
	-- LSP stands for Language Server Protocol. It's a protocol that helps editors
	-- and language tooling communicate in a standardized fashion.
	--
	-- In general, you have a "server" which is some tool built to understand a particular
	-- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
	-- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
	-- processes that communicate with some "client" - in this case, Neovim!
	--
	-- LSP provides Neovim with features like:
	--  - Go to definition
	--  - Find references
	--  - Autocompletion
	--  - Symbol Search
	--  - and more!
	--
	-- Thus, Language Servers are external tools that must be installed separately from
	-- Neovim. This is where `mason` and related plugins come into play.

	-- 安全加载内置模块
	local tele_builtin = require("telescope.builtin")

	--  This function gets run when an LSP attaches to a particular buffer.
	--    That is to say, every time a new file is opened that is associated with
	--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
	--    function will be executed to configure the current buffer
	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("Lsp-attach", { clear = true }),
		callback = function(event)
			-- NOTE: Remember that Lua is a real programming language, and as such it is possible
			-- to define small helper and utility functions so you don't have to repeat yourself.
			--
			-- In this case, we create a function that lets us more easily define mappings specific
			-- for LSP related items. It sets the mode, buffer and description for us each time.
			local map = function(keys, func, desc, mode)
				mode = mode or "n"
				vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
			end

			map("gd", tele_builtin.lsp_definitions, "[G]oto [D]efinition")
			map("gr", tele_builtin.lsp_references, "[G]oto [R]eferences")
			map("gI", tele_builtin.lsp_implementations, "[G]oto [I]mplementation")

			map("<leader>ld", tele_builtin.lsp_type_definitions, "[L]SP Type [D]efinition")
			map("<leader>ls", tele_builtin.lsp_document_symbols, "[L]SP Document [S]ymbols")
			map("<leader>ls", tele_builtin.lsp_dynamic_workspace_symbols, "[L]SP Workspace [S]ymbols")
			map("<leader>lr", vim.lsp.buf.rename, "[L]SP [R]ame")
		end,
	})

	-- Change diagnostic symbols in the sign column (gutter)
	if vim.g.have_nerd_font then
		local signs = { ERROR = "", WARN = "", INFO = "", HINT = "" }
		local diagnostic_signs = {}
		for type, icon in pairs(signs) do
			diagnostic_signs[vim.diagnostic.severity[type]] = icon
		end
		vim.diagnostic.config({ signs = { text = diagnostic_signs } })
	end

	-- LSP servers and clients are able to communicate to each other what features they support.
	--  By default, Neovim doesn't support everything that is in the LSP specification.
	--  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
	--  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

	-- Enable the following language servers
	--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
	--
	--  Add any additional override configuration in the following tables. Available keys are:
	--  - cmd (table): Override the default command used to start the server
	--  - filetypes (table): Override the default list of associated filetypes for the server
	--  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
	--  - settings (table): Override the default settings passed when initializing the server.
	--        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
	local servers = {
		clangd = {},
		rust_analyzer = {},
		pyright = { -- 添加pyright配置
			cmd = { "pyright-langserver", "--stdio" },
		},
		verible = {},
		cmake = {},
		autotools_ls = {},
		lua_ls = {
			-- cmd = { ... },
			-- filetypes = { ... },
			-- capabilities = {},
			settings = {
				Lua = {
					completion = {
						callSnippet = "Replace",
					},
					-- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
					-- diagnostics = { disable = { 'missing-fields' } },
				},
			},
		},
	}

	-- Ensure the servers and tools above are installed
	--
	-- To check the current status of installed tools and/or manually install
	-- other tools, you can run
	--    :Mason
	--
	-- You can press `g?` for help in this menu.
	--
	-- `mason` had to be setup earlier: to configure its options see the
	-- `dependencies` table for `nvim-lspconfig` above.
	--
	-- You can add other tools here that you want Mason to install
	-- for you, so that they are available from within Neovim.
	local ensure_installed = vim.tbl_keys(servers or {})
	vim.list_extend(ensure_installed, {
		"stylua", -- Used to format Lua code
	})
	require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

	require("mason-lspconfig").setup({
		handlers = {
			function(server_name)
				local server = servers[server_name] or {}
				-- This handles overriding only values explicitly passed
				-- by the server configuration above. Useful when disabling
				-- certain features of an LSP (for example, turning off formatting for ts_ls)
				server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
				require("lspconfig")[server_name].setup(server)
			end,
		},
	})
end

return M.config
