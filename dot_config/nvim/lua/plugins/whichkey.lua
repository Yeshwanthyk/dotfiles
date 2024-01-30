local whichkey = require("which-key")

whichkey.register({
  u = { u = "undotree" },
  j = {
    name = "harpoon",
    a = { "pick file" },
    j = { "files" },
  },
}, { prefix = "<leader>" })
