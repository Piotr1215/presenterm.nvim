#!/bin/bash

# Set up Lua paths for local luarocks installation
export LUA_PATH="$HOME/.luarocks/share/lua/5.1/?.lua;$HOME/.luarocks/share/lua/5.1/?/init.lua;;"
export LUA_CPATH="$HOME/.luarocks/lib/lua/5.1/?.so;;"

# Use the newest installed busted; luarocks moves past any pinned version
BUSTED=$(printf '%s\n' "$HOME"/.luarocks/lib/luarocks/rocks-5.1/busted/*/bin/busted | sort -V | tail -n 1)
if [ ! -f "$BUSTED" ]; then
  echo "busted not found under ~/.luarocks, install it with: luarocks install --local busted" >&2
  exit 1
fi

# Run busted using our nvim-shim as the Lua interpreter
./test/nvim-shim "$BUSTED" "$@"
