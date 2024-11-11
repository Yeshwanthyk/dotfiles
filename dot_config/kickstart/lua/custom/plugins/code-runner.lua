return {
  {
    'CRAG666/code_runner.nvim',
    cmd = { 'RunCode', 'RunFile', 'RunProject' },
    opts = {
      filetype = {
        markdown = 'glow',
        python = 'python3 -u',
        rust = 'cd $dir && rustc $fileName && $dir/$fileNameWithoutExt',
        go = 'go run',
        c = 'cd $dir && gcc $fileName -o $fileNameWithoutExt && $dir/$fileNameWithoutExt',
        cpp = 'cd $dir && g++ $fileName -o $fileNameWithoutExt && $dir/$fileNameWithoutExt',
        javascript = 'node',
        typescript = 'ts-node',
        javascriptreact = 'node',
        typescriptreact = 'ts-node',
      },
    },
  },
}
