
# mpv-shoko-updater
## Auto Mark File Watched at Playback Threshold

## Overview
This Lua script integrates with the **[Shoko Server](https://github.com/ShokoAnime/ShokoServer) API v3** and automatically marks a file as watched once playback reaches a specified threshold percentage (default: 50%).  
It is designed for **mpv** media player and works across Windows, Linux, and macOS with proper path normalization and logging.

---

## Features
- Automatically marks files as watched when playback passes a certain percentage.
- Works across Windows, Linux, and macOS.
- Allows whitelisting of specific directories to limit API calls.
- Logs all actions for debugging and record-keeping.
- Uses **Shoko Server API v3** endpoints.

---

## Requirements
1. **mpv media player** installed.
2. **Shoko Server** running with API v3 enabled (default instalation).
3. **dkjson.lua** library:
   - Download from: [https://dkolf.de/dkjson-lua/](https://dkolf.de/dkjson-lua/)
   - Fow Windows place `dkjson.lua` inside the `lua` folder of your mpv installation directory (not in the scripts directory).
      - Create the `lua` folder if it doesn't exist.
   - For linux refer to your ditsro's package names but is usually named `lua51-dkjson`

---

## Installation
1. **Download the script** and place it inside your mpv `scripts` directory:
   - **Windows:** `%APPDATA%\mpv\scripts\`
   - **Linux/macOS:** `~/.config/mpv/scripts/`
2. Ensure `dkjson.lua` is installed as per the requirements above.
3. Configure your **Shoko API base URL** and **API key** inside the script.

---

## Configuration
Edit the following variables inside the script to match your setup:

```lua
local BASE_URL = "http://your-shoko-server-url:00000/api/v3"  -- Shoko API base URL
local API_KEY = "Your API KEY"                                -- Shoko API key

local WHITELIST_DIRS = {
    "F:/anime/",
    "//NETWORKSHARE/anime/",
    "/mnt/anime/"
}

local TRIGGER_PERCENT = 50  -- Playback percentage to trigger watched update
````
---
The script was generated with the assistance of AI and is released into the **public domain**.  
You are free to use, modify, redistribute, and adapt it without any restrictions or attribution.
