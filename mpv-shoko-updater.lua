--[[
Shoko API v3 - Auto Mark File Watched at Playback Threshold
Runs when playback progress >= TRIGGER_PERCENT (default 50%)
Works across Windows/Linux/macOS with path normalization + logging
Dkjson is required, you can download it from here https://dkolf.de/dkjson-lua/
You need to add the dkjson.lua file to the "lua" folder in the installation directory (not in the scripts directory)
If the lua folder doesn't exist create it

As it was made using an AI, the script is completely in public domain, don't need to credite me or anything, you can use it, edit it, redistribute it or anything else you can imagine doing.
]]

-----------------------
-- Requred modules --
-----------------------

local utils = require("mp.utils")
local json = require("dkjson")

-----------------------
-- USER CONFIGURATION --
-----------------------

local BASE_URL = "http://your-shoko-server-url:00000/api/v3"  -- Shoko API base URL
local API_KEY = "Your API KEY"              -- Shoko API key

--[[ 
Directories to allow (normalized internally)
Leave it blank ("") to allow any directory
This was made so it only calls the Shoko server API if a file is inside your "Anime" directory instead of with every video
]]
local WHITELIST_DIRS = {
    "F:/anime/",
    "//NETWORKSHARE/anime/",
	"/mnt/anime/"
}

-- When to trigger watched update (percentage of total playback)
local TRIGGER_PERCENT = 50


-- Log file location
local LOG_FILE = (os.getenv("APPDATA") and os.getenv("APPDATA") .. "\\mpv\\mpv-shoko-updater.log")
              or (os.getenv("HOME") .. "/.config/mpv/mpv-shoko-updater.log")

-----------------------
-- INTERNAL VARIABLES --
-----------------------
local duration = mp.get_property_number("duration", 0) -- Get duration of the video when the script starts
local has_triggered = false -- Flag to avoid unnecesary processing time if the triggerpoint has been reached already

-----------------------
-- HELPER FUNCTIONS  --
-----------------------

local function log_message(level, message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local entry = string.format("[%s] %s - %s\n", timestamp, level, message)

    if level == "INFO" then
        mp.msg.info(message)
    elseif level == "WARN" then
        mp.msg.warn(message)
    elseif level == "ERROR" then
        mp.msg.error(message)
    else
        mp.msg.log(level, message)
    end

    local file = io.open(LOG_FILE, "a")
    if file then
        file:write(entry)
        file:close()
    else
        mp.msg.error("Failed to write to log file: " .. LOG_FILE)
    end
end

-- Normalize path for cross-platform matching
local function normalize_path(path)
    local p = path:gsub("\\", "/")
    if not p:match("/$") then
        p = p .. "/"
    end
    return p:lower()
end

-- Creates the curl call in the expected Shoko server format
local function shoko_request(method, url, path)
    local args = {"curl", "-s", "-X", method, "-H", "apikey: " .. API_KEY, "-H", "accept: application/json"}
    if path then
        url = url .. "/" .. path  -- Concatenate the path to the URL
    end
    table.insert(args, url)
    return utils.subprocess({args = args})
end

-- Updates the status of the file to watched, including the date
local function set_file_watched(file_id, watched, path)
    local watched_str = tostring(watched)
    local endpoint = string.format("%s/File/%d/Watched/%s", BASE_URL, file_id, watched_str)
    shoko_request("POST", endpoint)
    log_message("INFO", string.format("Marked file ID %d watched=%s (%s)", file_id, watched_str, path))
end

-- Gets the path of the video in order to confirm if is in the whitelisted
local function get_directory(path)
    return path:match("^(.*[\\/])") or path
end

-- Checks if the path of the vide o is whitelisted
local function is_whitelisted(path)
    local dir = normalize_path(get_directory(path))
    for _, wdir in ipairs(WHITELIST_DIRS) do
        if dir:find(normalize_path(wdir), 1, true) == 1 then
            return true
        end
    end
    return false
end

-- Function to URL encode a string
local function url_encode(str)
    if str then
        return str:gsub("([^%w%.%- ])", function(c)
            return string.format("%%%02X", string.byte(c))
        end):gsub(" ", "%%20")  -- Replace spaces with %20
    end
    return str
end

-- Gets the Shoko server file id (not episode ID) using the filename 
local function get_file_id_from_path(path)
    -- Capture everything after the last slash or backslash
    local filename = path:match("([^/\\]+)$") 

    -- URL encode the filename
    local encoded_filename = url_encode(filename)

    local endpoint = BASE_URL .. "/File/Search"
    local res = shoko_request("GET", endpoint, encoded_filename)  -- Use the encoded filename in the request
    
    if res.status == 0 and res.stdout then
        local response, pos, err = json.decode(res.stdout, 1, nil)  -- Decode the JSON response
        if err then
            log_message("ERROR", string.format("Error decoding JSON:%s", err))  -- Handle JSON decoding error
            return nil
        end
        
        if response.Total > 0 and response.List[1] then
            return response.List[1].ID  -- Return the ID of the first item in the List
        end
    end
    return nil
end


-----------------------
-- EVENT HANDLERS    --
-----------------------


mp.observe_property("time-pos", "number", function(_, pos)
    if not pos or has_triggered then return end

    local path = mp.get_property("path")
    if not path or path:find("^https?://") then
        return -- ignore streams
    end

    -- Check if the path is whitelisted first
    if not is_whitelisted(path) then
        -- Comment the statement below if you don't want to log skipped files, this is mostly for testing
        log_message("INFO", "Skipping, path not whitelisted: " .. path)
        has_triggered = true
        return
    end

    if duration > 0 then
        local percent_watched = (pos / duration) * 100

        if percent_watched >= TRIGGER_PERCENT then
            log_message("INFO", string.format(
                "Trigger reached (%.1f%% >= %d%%) for %s",
                percent_watched, TRIGGER_PERCENT, path))

            local file_id = get_file_id_from_path(path)
            log_message("INFO", string.format("The file located is: %d", file_id))
            if file_id then
                set_file_watched(file_id, true, path)
            else
                log_message("WARN", "Could not find file ID for: " .. path)
            end

            has_triggered = true
        end
    end
end)


-- Reset trigger when new file starts
mp.register_event("start-file", function()
    has_triggered = false
end)
