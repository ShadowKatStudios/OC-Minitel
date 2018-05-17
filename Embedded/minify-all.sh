#!/bin/bash
echo vt100.lua
lua minify.lua vt100.lua mini-vt100.lua
echo init-wrapper.lua
lua minify.lua init-wrapper.lua mini-init-wrapper.lua
echo microtel-3.lua
lua minify.lua microtel/microtel-3.lua microtel/mini-microtel-3.lua
echo microtel-4.lua
lua minify.lua microtel/microtel-4.lua microtel/mini-microtel-4.lua
echo microtel-5-core.lua
lua minify.lua microtel/microtel-5-core.lua microtel/mini-microtel-5-core.lua
echo microtel-5-listen.lua
lua minify.lua microtel/microtel-5-listen.lua microtel/mini-microtel-5-listen.lua
echo microtel-5-flisten.lua
lua minify.lua microtel/microtel-5-flisten.lua microtel/mini-microtel-5-flisten.lua
echo microtel-5-open.lua
lua minify.lua microtel/microtel-5-open.lua microtel/mini-microtel-5-open.lua
