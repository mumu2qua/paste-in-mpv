local function pick_paste_command()
   if os.getenv("XDG_SESSION_TYPE") == 'wayland' then
      return "wl-paste"
   else
      return ({ "xclip", "-o", "-selection", "clipboard" })
   end
end

local function urlencode(path)
   if path == nil then
      return
   end
   local char_to_hex = function(c)
      return string.format("%%%02X", string.byte(c))
   end
   local url = path:gsub("([^%w_%%%-%.~/])", char_to_hex)
   return url
end

local function make_list(strings)
   local urls = {}
   for s in strings:gmatch("[^\r\n]+") do
      -- trim trailing spaces from both sides
      s = s:gsub('^%s*(.-)%s*$', '%1')
      -- convert filenames to URLs
      if s:match("^/.+") then
         s = 'file://'..urlencode(s)
      end
      table.insert(urls, s)
   end
   return urls
end

local function openURL()
   local subprocess = {
      name = "subprocess",
      args = pick_paste_command(),
      playback_only = false,
      capture_stdout = true,
      capture_stderr = true
   }

   mp.osd_message("Getting URL from clipboard...")

   local r = mp.command_native(subprocess)

   -- failed getting clipboard data for some reason
   if r.status < 0 then
      mp.osd_message("Failed getting clipboard data!")
      print("Error(string): "..r.error_string)
      print("Error(stderr): "..r.stderr)
   end

   local urls = make_list(r.stdout)
   if not urls[1] then
      mp.osd_message("clipboard empty")
      return
   end

   for i=1, #urls do
      -- MPV will exit if any of urls are invalid
      mp.osd_message("Appending to playlist:\n".. urls[i])
      mp.commandv("loadfile", urls[i], "append-play")
   end
end

mp.add_key_binding("ctrl+v", openURL)

-- vim: ts=3 sts=3 sw=3 et
