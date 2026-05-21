#!/bin/bash

hyprctl --batch 'eval hl.config({ animations = { enabled = false }, decoration = { blur = { enabled = false } }, general = { gaps_in = 0, gaps_out = 0 } }); eval hl.monitor({ output = "", mode = "1280x720@60", position = "auto", scale = "1" })'