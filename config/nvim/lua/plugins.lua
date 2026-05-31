require("lazy").setup({

  -- ── theme ────────────────────────────────────────────────────────────
  {
    "EdenEast/nightfox.nvim",
    priority = 1000,
    config = function()
      require("nightfox").setup({
        options = { transparent = false, terminal_colors = true },
      })
      vim.cmd("colorscheme nordfox")
    end,
  },

  -- ── treesitter ───────────────────────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "rust", "nix", "c", "cpp", "bash", "toml", "json", "yaml", "markdown" },
        highlight        = { enable = true },
        indent           = { enable = true },
      })
    end,
  },

  -- ── telescope ────────────────────────────────────────────────────────
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = { path_display = { "truncate" } },
      })
      telescope.load_extension("fzf")
    end,
  },

  -- ── lsp ──────────────────────────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      -- keymaps applied whenever an LSP attaches to a buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspKeys", { clear = true }),
        callback = function(ev)
          local map = vim.keymap.set
          local b   = { buffer = ev.buf }
          map("n", "gd",         vim.lsp.buf.definition,      b)
          map("n", "gD",         vim.lsp.buf.declaration,     b)
          map("n", "gr",         vim.lsp.buf.references,      b)
          map("n", "gi",         vim.lsp.buf.implementation,  b)
          map("n", "K",          vim.lsp.buf.hover,           b)
          map("n", "<leader>rn", vim.lsp.buf.rename,          b)
          map("n", "<leader>ca", vim.lsp.buf.code_action,     b)
          map("n", "<leader>D",  vim.lsp.buf.type_definition, b)
        end,
      })

      -- global capabilities (picked up by all servers via vim.lsp.config '*')
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })

      -- server-specific overrides
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace   = { checkThirdParty = false },
            telemetry   = { enable = false },
          },
        },
      })

      vim.lsp.enable({ "rust_analyzer", "nil_ls", "clangd", "lua_ls" })

      vim.api.nvim_create_user_command("LspRestart", function()
        for _, c in ipairs(vim.lsp.get_clients()) do c.stop() end
      end, {})
    end,
  },

  -- ── completion ───────────────────────────────────────────────────────
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp     = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"]     = cmp.mapping.select_next_item(),
          ["<C-p>"]     = cmp.mapping.select_prev_item(),
          ["<C-d>"]     = cmp.mapping.scroll_docs(-4),
          ["<C-f>"]     = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm({ select = false }),
          ["<Tab>"]     = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip"  },
          { name = "buffer"   },
          { name = "path"     },
        }),
      })
    end,
  },

  -- ── formatting ───────────────────────────────────────────────────────
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        -- no format_on_save — use <leader>f explicitly
        formatters_by_ft = {
          rust = { "rustfmt" },
          nix  = { "nixfmt" },
          c    = { "clang_format" },
          cpp  = { "clang_format" },
          lua  = { "stylua" },
        },
      })
    end,
  },

  -- ── autopairs ────────────────────────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({ check_ts = true })
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },

  -- ── file tree ────────────────────────────────────────────────────────
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = { { "<C-n>", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree" } },
    config = function()
      require("nvim-tree").setup({
        view = { width = 30 },
        renderer = {
          group_empty = true,
          icons = { show = { git = true, folder = true, file = true } },
        },
        filters = { dotfiles = false },
        git = { enable = true },
      })
    end,
  },

  -- ── comments ─────────────────────────────────────────────────────────
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },

}, {
  ui      = { border = "rounded" },
  checker = { enabled = false },
})
