lua << EOF

PLUGIN_NAME = 'verim'

function VERIM()
    for pkg, _ in pairs(package.loaded) do
        if string.find(pkg, 'verim[/.]?') then
            package.loaded[pkg] = nil
        end
    end
    require('verim').setup{}
end

EOF

command! -nargs=? -complete=dir Verim lua require('verim').dispatch('<args>')
command! So lua VERIM()
