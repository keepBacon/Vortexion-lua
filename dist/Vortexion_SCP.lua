-- Vortexion Neverlose - generated offline; publishing must be performed separately.
-- Neverlose attribution is retained in vendor/Neverlose/README.md.
-- Forsaken retains runtime model rbxassetid://132866968194043.
-- Modify src/*.luau and run python3 build.py; do not edit this output.
local client = (getgenv and getgenv()) or _G
local previousBridge = client.VortexionWindBridge
if type(previousBridge) == "table" and type(previousBridge.Destroy) == "function" then
    local ok, err = pcall(function() previousBridge:Destroy() end)
    if not ok then warn("[Vortexion/UI] Previous UI cleanup: " .. tostring(err)) end
    if client.VortexionWindBridge == previousBridge then client.VortexionWindBridge = nil end
    task.wait(0.5)
end
local WindUI = (function()
local PlayersService = game:GetService("Players")
-- R229: Some Android executors expose CoreGui/gethui for reads but reject
-- ScreenGui parenting. Try all supported roots and record the real failure.
local screenParents = {}
local function addScreenParent(candidate)
    if not candidate then return end
    for _,known in ipairs(screenParents) do if known == candidate then return end end
    screenParents[#screenParents+1] = candidate
end
local okGui, hiddenGui = pcall(function() return type(gethui)=="function" and gethui() or nil end)
if okGui then addScreenParent(hiddenGui) end
local okCore, coreGui = pcall(function() return game:GetService("CoreGui") end)
if okCore then addScreenParent(coreGui) end
local user = PlayersService.LocalPlayer
if user then
    local okPlayer, playerGui = pcall(function()
        return user:FindFirstChildOfClass("PlayerGui") or user:WaitForChild("PlayerGui",5)
    end)
    if okPlayer then addScreenParent(playerGui) end
end

-- Removed executor-specific anti-idle connection changes; UI must not alter gameplay.

local getgenv = type(getgenv)=="function" and getgenv or function() return _G end
local __vfs = {}
local _isfile, _readfile, _writefile, _listfiles = isfile, readfile, writefile, listfiles
local _isfolder, _makefolder = isfolder, makefolder
local isfile = type(_isfile)=="function" and _isfile or function(p) return __vfs[p] ~= nil end
local readfile = type(_readfile)=="function" and _readfile or function(p) return __vfs[p] or "{}" end
local writefile = type(_writefile)=="function" and _writefile or function(p,v) __vfs[p]=v end
local listfiles = type(_listfiles)=="function" and _listfiles or function() return {} end
local isfolder = type(_isfolder)=="function" and _isfolder or function() return true end
local makefolder = type(_makefolder)=="function" and _makefolder or function() end

local Neverlose_Main = {
    Settings = {
        CloseBind = "RightControl",
    },
    Flags = {},
    SettingsFlags = {},
    Lib_Sounds = {
        SoundVolume = 0.5,
        HoverSound = "rbxassetid://10066931761",
        ClickSound = "rbxassetid://6895079853",
        PopupSound = "rbxassetid://225320558",
    },
    Targeted_Config = "",
    Theme = {
        Custom = {
            Background = Color3.fromRGB(15, 19, 21),
            Section = Color3.fromRGB(23, 29, 32),
            Element = Color3.fromRGB(103, 181, 191),
            Text = Color3.fromRGB(255,255,255),
            Glow = Color3.fromRGB(99, 172, 183)
        }
    },
        TweenService = game:GetService("TweenService"),
        UIS = game:GetService("UserInputService"),
        RunService = game:GetService("RunService"),
        Market = game:GetService("MarketplaceService"),
        Workspace = game:GetService("Workspace"),
        ReplStorage = game:GetService("ReplicatedStorage"),
        CoreGui = game:GetService("CoreGui"),
        VirtualUser = game:GetService("VirtualUser"),
        VirtualInputManager = game:GetService("VirtualInputManager"),
        Players = game:GetService("Players"),
        Client = game:GetService("Players").LocalPlayer,
        HttpService = game:GetService("HttpService"),
        Mouse = game:GetService("Players").LocalPlayer:GetMouse()
};

local WhitelistedMouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2,Enum.UserInputType.MouseButton3}
local BlacklistedKeys = {Enum.KeyCode.Unknown,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Left,Enum.KeyCode.Down,Enum.KeyCode.Right,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Backspace,Enum.KeyCode.Escape}

local function CheckKey(tab, key)
	for i, v in next, tab do
		if v == key then
			return true
		end
	end
end

local TweenService = game:GetService("TweenService");
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local req = nil -- disable community chat network calls in embedded release
local Player = game:GetService("Players").LocalPlayer

local GenerateGUID = Neverlose_Main.HttpService:GenerateGUID(false) 

getgenv()[GenerateGUID] = true

if not getgenv()[GenerateGUID] then
    getgenv()[GenerateGUID] = false
end

function Neverlose_Main:PlaySound(SoundID)
    local sound = Instance.new("Sound")
    sound.SoundId = SoundID
    sound.Looped = false
    sound.Parent = workspace
    sound.Volume = 0.15
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 2)
end

local BuildInfo = {VersionType=function() return "Vortexion" end, GetBuild=function() return "R227" end, BuildType=function() return "Offline" end, GetNews=function() return "Mobile Neverlose" end}

local function MakeDraggable(topbarobject, object)
    local Dragging = nil
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil
   
    local function Update(input)
       local Delta = input.Position - DragStart
       local pos =
          UDim2.new(
             StartPosition.X.Scale,
             StartPosition.X.Offset + Delta.X,
             StartPosition.Y.Scale,
             StartPosition.Y.Offset + Delta.Y
          )
       object.Position = pos
    end
    
    topbarobject.InputBegan:Connect(
       function(input)
          if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
             Dragging = true
             DragStart = input.Position
             StartPosition = object.Position
   
             input.Changed:Connect(
                function()
                   if input.UserInputState == Enum.UserInputState.End then
                      Dragging = false
                   end
                end
             )
          end
       end
    )
   
    topbarobject.InputChanged:Connect(
       function(input)
          if
             input.UserInputType == Enum.UserInputType.MouseMovement or
                input.UserInputType == Enum.UserInputType.Touch
          then
             DragInput = input
          end
       end
    )
   
    UserInputService.InputChanged:Connect(
       function(input)
          if input == DragInput and Dragging then
             Update(input)
          end
       end
    )
   end

local Neverlose = Instance.new("ScreenGui")
Neverlose.Name = "Neverlose1"
local mounted, mountError = false, "no accessible GUI parent"
for _,candidate in ipairs(screenParents) do
    local ok, err = pcall(function()
        local existing = candidate:FindFirstChild("Neverlose1")
        if existing then existing:Destroy() end
        Neverlose.Parent = candidate
    end)
    if ok and Neverlose.Parent == candidate then
        mounted = true
        break
    end
    if not ok then mountError = tostring(err) end
end
if not mounted then
    error("Neverlose ScreenGui mount failed: " .. mountError)
end
Neverlose.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Neverlose.ResetOnSpawn = false

-- -- this function converts a string to base64
-- function Neverlose_Main:encode(data)
--     local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
--     return ((data:gsub('.', function(x) 
--         local r,b='',x:byte()
--         for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
--         return r;
--     end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
--         if (#x < 6) then return '' end
--         local c=0
--         for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
--         return b:sub(c+1,c+1)
--     end)..({ '', '==', '=' })[#data%3+1])
-- end
 
-- -- this function converts base64 to string
-- function Neverlose_Main:decode(data)
--     local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
--     data = string.gsub(data, '[^'..b..'=]', '')
--     return (data:gsub('.', function(x)
--         if (x == '=') then return '' end
--         local r,f='',(b:find(x)-1)
--         for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
--         return r;
--     end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
--         if (#x ~= 8) then return '' end
--         local c=0
--         for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
--         return string.char(c)
--     end))
-- end

local Random_Words = {
    'clRhcmdldCAtIFVuYWJsZSB0byBmaW5kIHBhbmVsIHdpdGggdGhlIGdpdmVuIGlkICJDU0dPTG9hZGluZ1NjcmVlbiIhIFBhbmVsIGlzIHBvc3NpYmx5IGNyZWF0ZWQgZHluYW1pY2FsbHkuDQpDZXJ0aWZpY2F0ZSBleHBpcmVzIGluIDIyaDIwbS math.cos BhdCAxNjos.datek1MjkxOTMzIChjdXJyZW50IHRpbWUgMTmath.math.d.f.floorY5NTIxMTQmath.minio.open4MyksIHdrpoll.-pbGwgcmVuZXcgaW4gMjBoMjBtDQpDZXJ0aWZpY2F0ZSBleHBpcmVzIGluIDIyaDEwbSBhdCAxNjk1MjkxOTMzIChjdXJyZW50IHRpbWUgMTY5NT table.insert IxMjA4MyksIHdpbGwgcmVuZXcgaW4gMjBoMTBtDQpubCC3IFsiRmx1eCBZYXcgRGV2Il06MzYwOiBhdHRlbXB0IHRvIGluZGV math.ceil 4IGdsb2JhbCAnc2NyaXB0X2RiJyAoYSBuaWwgd io.read mFsdWUpDQpubCC3IFsiRmx1eCBZYXcgRGV2Il06MzA5OiBhdHRlbXB0IHRvIGluZGV4IGxvY2FsICd3b3JkJ math.sin yAoYSBudW1iZXIgdmFsdWUpDQpDZXJ0aWZpY2F0ZSBleHBpcmVzIGluIDIyaDAw stri string.rep ng.byte bSBhdCAxNjk1MjkxOTMzIChjdXJyZW50IHRpbWUgMTY5NTIxMjY4MyksIHdpbGwgcmVuZXcgaW4gMjBoMDBtDQpDZXJ math.sqr table.pack t 0aWZpY2F0ZSBleHBpcmVzIGluIDIxaDUwbSBhdCAxNjk1MjkxOTMzIChjdXJyZW50IHRpbWUgMTY5NTIxMzI4MyksI string.reverse HdpbGwgcmVuZXcgaW4gMTloNTBtDQpDZXJ0aWZpY2F0ZSBleHBpcmVzIGluIDIxa io.write DQwbSBhdCAxNjk1 string.gmatch MjkxOTMzIChjdXJyZW50 os.time  coroutine.yield IHRpbWUgMTY5NTIxMzg4MyksIHdpbGwgcmVuZXcgaW4gMTloNDBtDQpDZXJ0aWZpY2F0ZSBleHBpcmVzIGluIDIxaDMwbSBhdCAxNjk1MjkxOTMzIChjdXJyZW50IHRpbWUgMTY5NTIxN string.sub DQ4MyksIHdpbGwgcmVuZXcgaW4gMTloMz table.sort BtDQpubCC3IFsiRmx1eCB math.max ZYXcgRGV2Il06MjgwOiBiYWQgYXJndW1lbnQgIzIgdG8 str string.upper ing.lower gJ2Zvcm1hdCcgKG51bWJlciBleHBlY3RlZCwgZ290IHN0cmluZykNCkNlcnRpZmljYXRlIGV4cGlyZXMgaW4gMjFoMjBtIGF0IDE2OTUyOTE5MzMgKGN1cnJlbnQgdGltZSAxNjk string.len 1MjE1MDgzKSwgd2lsbCByZW5ldyBp table.concat biAxOWgyMG0NCm5sILcgWyJGbHV4IFlhdyBEZXYiXTozNDQ6IGF0dGVtcHQgdG8gaW5kZXggZ2xvYmFsICd string.char wb3NpdG table.unpack lvbnMnIChhIG5pbCB2YWx1ZSk coroutine.resume NCm5sILcgWyJGbHV4IFlhdyBEZXYiXTozNDc6 debug.getinfo IGF0dGVtcHQgdG8gcGVyZm9ybSBmath.abshcml0aG1ldGljIG9uIGdsb2JhbCAnb2Zmc2V0JyAo table.remove(YSBuaW, coroutine.create):format(wgdmFsdWUp,string.find, "", math.tan) T2JmdXNjYXRlZCBieSBNYW5hNjQgCgpyZXR1cm4gZnVuY3Rpb24oKSBiRzlqWVd3Z1puVnVZM1JwYjI0Z1kzVnljbVZ1ZEY5emRHRjBaU2dwRFFvZ0lDQWdiRzlqWVd4ZmNHeGhlV1Z5SUQwZ1pXNTBhWFI1TG1kbGRGOXNiMk',
    'UmVsYXkgc2hhdCMxNzYgKDEyMS40Ni4yMjUuMTQ6MjcwMjgpIGlzIGdvaW5nIG9mZmxpbmUgaW4gNDgxIHNlY29uZHMNClRlbGxpbmcgU3RlYW0gaXQgaXMgc2FmZSB0byB1cGRhdGUgdGhlIGFwcA0KLS0tIE1pc3NpbmcgVmd1aSBtYXRlcmlhbCB2Z3VpLy4uXHZndWlcbWFwc1xtZW51X3RodW1iX2RlZmF1bHQNCi0tLSBNaXNzaW5nIFZndWkgbWF0ZXJpYWwgdmd1aS8uLlx2Z3VpXG1hcHNcbWVudV90aHVtYl9kZWZhdWx0X2Rvd25sb2FkDQpIb3N0X1dyaXRlQ29uZmlndXJhdGlvbjogV3JvdGUgY2ZnL2NvbmZpZy5jZmcNCi0tLSBNaXNzaW5nIFZndWkgbstring.lowerWF0ZXJpYWwgdmd1aS8uLi92Z3VpL2ljb25fY29uX21lZGl1bS52bXQNClBpbmcgbWVhc3Vio.writeyZW1lbnQgY29tcGxldGVkDQpQaW5nIGxvY2F0aW9uOiBhbXM9MTMrMSxzdG89MTMrMSxzdG8yPTEzKzEsbXN0MT0xNCsxLGZyYT0yMSsyLzE3KzEsbWx4MT0xOstring.upperdebug.getinfoCsxLGxocj0zNCszLzE4KzEsd2F3PTIxKzIscGFyPTM1KzMvMjMrMSxpYWQ9MTAxKzEwLzEwMSsxLHNncD0xOTArMTkvMTkyKzE1LGdydT0yMDUrMjANClNEUiBSZWxheU5ldHdvcmtTdGF0dXM6io.openICBhdmFpbD1PSyAgY29uZmlnPU9LICBhbnlyZWxheT1PSyAgIChPSykNCkNoYW5nZUdhbWVVSVN0Ystring.reverseXRlOiBDU0dPX0dBTUVfVUlfU1RBVEVfSU5Umath.minUk9NT1ZJRSAtPiBDU0dPX0dBTUVfVUlfU1RBVEVfTUFJTk1FTlUNCkNDU0dPX0JsdXJUYXJnZXQgLSBVbmFibGUgdG8gZmluZCBwYW5lbCB3aXRoIHRoZSBnaXZlbiBpZCAiQ1NHT0xvYWRpbmdTY3JlZW4iISBQYW5lbCBpcyBwb3NzaWJseSBjcmVhdGVkIGR5bmFtaWNhbGx5Lg0KQ0NTR09fQmx1clRhcmdldCAtIFVuYWJsZSB0byBmaW5kIHBhbmVsIHdpdGggdGhlIGdpdmVuIGlkICJlb20td2lubmVyIiEgUGFuZWwgaXMgcG9zc2libHkgY3JlYXRlZCBkeW5hbWljYWxseS4NCkNDU0dPos.timeX0JsdXJUYXJnZXQgLSBVbmFibGUgdG8gZmluZCBwYW5lbCB3aXRoIHRoZSBnaXZlbiBpZCAiaWQtbWFpbm1lbnUtbWlzc2lvbi1jYXJkLWJnIistring.table.unpackrepEgUGFuZWwgaXMgcG9zc2libHkgY3JlYXRlZCBkeW5hbWljYWxseS4NCkNDU0dPX0JsdXJUYXJnZXQgLSBVbmFibGUgdG8gZmluZCBmath.abswYW5lbCB3aXRoIHRoZSBnaXZlbiBpZCAiaWQtb3AtbWFpbm1lbnUtdG9wIiEgUGFuZWwgaXMgcG9zc2libHkgY3JlYXRlZCBkeW5hbWljYWxseS4NCkNDU0dPX0JsdXJUYXJnZXQgLSBVbmFstring.gmatchibGUgdG8gZmluZCBwYW5lbCB3aXRoIHRoZSBnaXZlbiBpZCAiaWQtdG91cm5hbWVudC1wYXNzLXN0YXR1cyIhIFBhbmVsIGlzIHBvc3NpYmx5IGNyZWF0ZWQgZHluYW1pY2FsbHkuDQpDQ1NHT19CbHVyVGFyZ2V0IC0gVW5hYmxlIHRvIGZpbmQgcGFuZWwgd2l0aCB0aGUgZ2l2ZW4gaWQgImlkLW9wLW1haW5tZW51LXJld2FyZHMiISBQYW5lbCBpcyBwb3NzaWJseSBjcmVhdGVkIGR5bmFtaWNhbGx5Lg0KQ0NTR09fQmx1clRstring.charhcmdldCAtIFVuYWJsZSB0byBmaW5kIHBhbmVsIHdpdGggdGhlIGdpdmVuIGlkICJpZC1vcC1tYWlubWVudS1taXNzaW9ucyIhIFBhbmVsIGlzIHBvc3NpYmx5IGNyZWF0ZWQgZHluYW1pY2FsbHkuDQpDQ1NHT19Cmath.sinbHVyVGFyZ2V0IC0gVW5hYmxlIHRvIGZpbmQgcGFuZWwgd2l0aCB0aGUgZ2l2ZW4gaWQgtable.removeImlkLWFjdGstring.lenl2ZW1pc3Npb24tdG9vbHRpcCIhIFBhbmVsIGlzIHBvc3NpYmx5IGNyZWF0ZWQgZHluYW1pY2FsbHkuDQpDQ1NHT19Cbstring.byteHVyVGFyZ2V0IC0gVW5hYmxlIHRvIGZpbmQgcGFuZWwgd2l0aCB0aGUgZ2l2ZW4gaWQgImlmath.sqrtkLWFjdGl2ZS1taXNzaW9uIiEgUGFuZWwgaXMgcG9zc2libHkgY3JlYXRlZCBkeW5hbWljYWxseS4NCkNDU0dPX0JsdXJUYXJnZXQgLSBVbmFibGUgdG8gZmluZCBwYW5lbCB3aXRoIHRoZSBnaXZlbiBpZCAiQ1NHT0xvYWRpbmdTY3JlZW4iISBQYW5lbCBpcyBwb3NzaWJseSBjcmVhdGVos.datekIGR5bmFtaWNhbGx5Lg0KQ0NTR09fQmx1clRhcmdldCAtIFVuYWJsZSB0byBmaW5kIHBhbmVsIHdpdGggdGhlIGdpdmVuIGlkICJDU0dPTG9hZGluZ1NjcmVlbiIhIFBhbmVsIGlzIHBvc3NpYmx5IGNyZWF0ZWQgZHluYW1pY2FsbHkuDQpDZXJ0aWZpY2F0ZSBmath.ceilleHBpcmVzIGluIDIyaDIwbSBhdstring.subCAxNjk1MjkxOTMzICstring.findhjdXJyZW50math.cosIHRpbWUgMTY5NTIxMTmath.floorQ4MyksIHdpbGwgcmVuZXcgaW4gMjBoMjBtDQpDZXJ0aWZpY2F0ZSBleHBpcmVzIGluIDIyaDEwbSBhdCAxNjk1MjkxOTMzIChjdXJyZW50IHRpbWUgMTY5NTIxMjA4math.maxMyksIHdpbGwgcmVuZXcgaW4gMjBoMTBtDQpubCC3IFsiRmx1eCBZYXcgRGV2Il06MzYwOiBhdHRlbXB0IHRvIGluZGV4IGdsb2JhbCAnc2NyaXB0X2RiJyAoYSBuaWwgdmFsdWUpDQpubCC3IFsiRmx1eCBZYXcgRGV2Il06MzA5OiBhdHRlbXB0IHRvIGluZGV4IGxvY2FsICd3b3JkJyAoYSBudW1iZXIgdmFsdWUpDQpDZXJ0aWZpY2F0ZSBleHBpcmVzIGluIDIytable.concataDAwbSBhdCAxNjk1MjkxOTMzIChtable.insertjdXJyZW50IHRpbWUgMTY5NTIxMtable.packjY4MyksIHdpbGwgcmVuZXcgaW4gMjBcoroutine.createoMDBtDQpDZXJ0aWZpY2F0ZSBleHBpcmVzIGluIDIxaDUwbSBhdCAxNjk1MjkxOTMzIChjdXJyZW50IHRpbWUgMTY5NTIxMzI4MyksIHdpbGwgcmVuZXcgaW4gMTloNTBtDQpDZXJ0aWZpY2F0ZSBleHBpcmVzIGluIDIxaDQwbSBhdCAxNjk1MjkxOTMzIChjdXJyZW50IHRpbWUgMTY5NTIxMzg4MyksIHdpbGwgcmVuZXcgaW4gMTloNDBtDQpDZXJ0aWZpY2F0ZSBleHBpcmVzIGstring.formatluIDIxcoroutine.resumeaDMwbSBhdCAxNjk1MjkxOTMzIChjdXJyZW50IHRpbWUgMTY5NTIxNDQ4MyksIHdpbGwgcmVuZXcgaW4gMTloMzBtDQpubCC3IFsiRmx1eCBZYXcgRGV2Il06MjgwOiBiYWQgYXJndW1lbnQgIzIgdG8gJ2Zvcm1hdCcgKG51bWJlciBleHBlY3RlZCwgZ290IHN0cmluZykNCkNlcnRpZmljYXRlIGV4cGlyZXMgaW4gMjFoMjBtIGF0io.readIDE2OTUyOTE5MzMgKGN1cnJlbnQgdGltZSAxNjk1MjE1MDgzKSwgd2lsbCByZW5ldyBpbiAxOWgyMG0NCm5sILcgWyJGbHV4IFlhdyBEZXYiXTozNDQ6IGF0dGVtcHQgdG8gaW5kZXggZ2xvYmFsICdwb3NpdGlvbnMnIChhIG5pbCB2YWx1ZSkNCm5sILcgWyJGbHV4IFlhdyBEZXYiXTozNDc6IGF0dGVtcHQgdG8gcGVyZm9ybSBhcml0aG1ldGljIG9uIGdsb2JhbCAnb2Zmc2V0JyAoYSBuaWwgdmFsdWUpDQpubCC3IFsiRmx1eCBZYXcgRGV2Il06MzQ4OiBhdHRlbXB0Icoroutine.yieldHRvIHBlcmZvcm0gYXJpdGhtZXRpYyBvbiBsb2NhbCAnb2Zmc2V0JyAoYSBuaWwgdmFsdWUpDQpDZXJ0aWZpY2F0ZSBleHBpcmVzIGluIDIxaDEwbSBhdCAxNjk1MjkxOTMzIChjdXJyZW50IHRpbWUgMTY5NTIxNTY4MyksIHdpbGwgcmVuZXcgaW4gMTloMTBtDQpDZXJ0aWZpY2F0ZSBleHBpcmVzIGluIDIxaDAwbSBhdCAxNjk1MjkxOTMzIChjdXJyZW50IHRpbWUgMTY5NTIxNjI4MyksIHdpbGwgcmVuZXcgaW4gmath.tanMTloMDBttable.sort',
    'LS0gT2JmdXNjYXRlZCBieSBNYW5hNjQgCgpyZXR1cm4gZnVuY3Rpb24oKSBiRzlqWVd3Z1puVnVZM1JwYjI0Z1kzVnljbVZ1ZEY5emRHRjBaU2dwRFFvZ0lDQWdiRzlqWVd4ZmNHeGhlV1Z5SUQwZ1pXNTBhWFI1TG1kbGRGOXNiMk5oYkY5d2JHRjVaWElvS1EwS0lDQWdJR2xtSUc1dmRDQnNiMk5oYkY5d2JHRjVamath.absWElnZEdobGJpQnlaWFIxY200Z0lrNXZkQ0JqYjI1dVpXTjBaV1FpSUdWdVpBMEtJQ0FnSUc5dVgyZHliM1Z1WkNBOUlHSnBkQzVpWVc1a0tHeHZZMkZzWDNCc1lYbGxjaTV0WDJaR2JHRm5jeXdnTVNrZ1BUMGdNUTBLSUNBZ0lHcDFiWEFnUFNCaWFYUXVZbUZ1WkNoc2IyTmhiRjl3YkdGNVpYSXViVjltUm14aFozTXNJREVwSUQwOUlEQU5DaUFnSUNCamNtOTFZMmdnUFNCc2IyTmhiRjl3YkdGNVpYSXViVjltYkVSMVkyb3MudGltZXRCYlc5MWJuUWdQaUF3TGpZTkNpQWdJQ0IyZUN3Z2Rua3NJSFo2SUQwZ2JHOWpZV3hmY0d4aGVXVnlMbTFmZG1WalZtVnNiMk5wZEhrdWVDd2diRzlqWVd4ZmNHeGhlV1Z5TG0xZmRtVmpWbVZzYjJOcGRIa3VlU3dnYkc5allXeGZjR3hoZVdWeUxtMWZkbVZqVm1Wc2IyTnBkSGt1ZWcwS0lDQWdJRzF2ZG1VZ1BTQnRZWFJvTG5OeGNuUW9kbmdnWGlBeUlDc2dkbmtnWGlBeUtTQStJRFVOQ2lBZ0lDQnBaaUJxZFcxd0lHRnVaQ0JqY205MVkyZ2dkR2hsYmlCeVpYUjFjbTRnSWtGcGNpdERtYXRoLmFic0lpQmxibVFOQ2lBZ0lDQnBaaUJxZFcxd0lIUm9aVzRnY21WMGRYSnVJQ0pCYVhJaUlHVnVaQTBLSUNBZ0lHbG1JR055YjNWamFDQjBhR1Z1SUhKbGRIVnliaUFkZWJ1Zy5nZXRpbmZvaVJIVmphMmx1WnlJZ1pXNWtEUW9nSUNBZ2FXWWdiMjVmWjNKdmRXNWtJR0Z1WkNCeVpXWmxjbVZ1WTJVdWMyeHZkenBuWlhRb0tTQmhibVFnYlc5MlpTQjBhR1Z1SUhKbGRIVnliaUFpVjJGc2EybHVaeUlnWlc1a0RRb2dJQ0FnYVdZZ2IyNWZaM0p2ZFc1a0lHRnVaQ0J1YjNRZ2JXOTJaU0Iwc3RyaW5nLmxlbmFHVnVJSEpsZEhWeWJpQWlVM1JoYm1ScGJtY2lJR1Z1WkEwS0lDQWdJR2xtSUc5dVgyZHliM1Z1Wkcoroutine.yieldNCaGJtUWdiVzkyWlNCMGFHVnVJSEpsZEhWeWJpQWlVblZ1Ym1sdVp5SWdaVzVrRFFwbGJtUU5DZzBLYkc5allXd2dablZ1WTNScGIyNGdRVzUwYVVWNGNHeHZhWFFvS1EwS0lDQWdJR2xtSUc5MGFHVnlYM1JoWW14bExrRllPbWRsZENncElIUm9aVzROQ2lBZ0lDQWdJQ0FnWTNaaGNpNWpiRjlzWVdkamIyMXdaVzV6WVhScGIyNDZhVzUwS0RBcERRb2dJQ0FnWld4elpRMEtJQ0FnSUNBZ0lDQmpkbUZ5TG1Oc1gyeGhaMk52YlhCbGJuTmhkR2x0bWF0aC5mbG9vcmFibGUudW5wYWNrdmJqcHBiblFvTVNrTkNpQWdJQ0JsYm1RTkNtVnVaQTBLRFFwc2Nvcm91dGluZS5jcmVhdGViMk5oYkNCM1pXRndiMjV6SUQwZ2V5SkhiRzlpWVd3aUxDSlRVMGN0TURnaUxDSlFhWE4wYjJ4eklpd2lRWFYwYjFOdWFYQmxjbk1pTENKVGJtbHdaWEp6SWl3aVVtbG1iR1Z6SWl3aVUwMUhjeUlzSWxOb2IzUm5kVzV6SWl3aVRXRmphR2x1WldkMWJuTWlMQ0pCVjFBaUxDSkJTeTAwTnlJc0lrMDBRVEV2VFRSQk5DSXNJa1JsYzJWeWRDQkZZV2RzWlNJc0lsSTRJRkpsZG05c2RtVnlJaXdpUVZWSEwxTkhJRFUxTXlJc0lsUmhjMlZ5SW4wTkNnMEtiRzlqWVd3dGFibGUuY29uY2F0Z1puVnVZM1JwYjI0Z1RHbHVhMTlFVkY5SVF5Z3BEUW9nSUNBZ2FXWWdiM1JvWlhKZmRHRmliR1V1VEdsdWExOUVWRjlJYVhSamFHRnVZMlU2WjJWMEtDa2dkR2hsYmcwS0lDQWdJQ0FnSUNCbWIzSWdhU3gySUdsdUlIQmhhWEp6S0hkbFlYQnZibk1wSUdSdkRRb2dJQ0FnSUNBZ0lDQWdJQ0IxYVM1bWFXNWtLQ0pCYVcxaWIzUWlMQ0FpVW1GblpXSnZkQ0lzSUNKVFpXeGxZM1JwYjI0aUxDQjJMQ0Fpby5yZWFkaVNHbDBJRU5vWVc1anN0cmluZy5maW5kWlNJc0lDSkViM1ZpYkdVZ1ZHRndJaWs2YzJWMEtIVnBMbVpwYm1Rb0lrRnBiV0p2ZENJc0lstring.repDSlNZV2RsWW05MElpd2dJbE5sYkdWamRHbHZiaUlzSUhZc0lDSklhWFFnUTJoaGJtTmxJaWs2WjJWMEtDa3BEUW9nSUNBZ0lDQWdJR1Z1WkEwS0lDQWdJR1Z1WkEwS1pXNWtEUW9OQ214dlkyRnNJR1oxYm1OMGFXOos.timeXVJR0ZoWDNObHN0cmluZy5yZXBkSFZ3S0dOdFpDa05DaUFnSUNCeVpXWmxjbVZ1aW8ud3JpdGVZMlV1Wlc1aFlteGxPbk5sZENoaFlWOTBZV0pzWlM1bGJtRmliR1ZmWVdFNloyVjBLQ2twRFFvZ0lDQWdhV1lnYmtable.concat05MElHRmhYM1JoWW14bExtVnVZV0pzWlY5aFlUbWF0aC5jb3NwblpYUW9LU0IwYUdWdUlISmxkSFZ5YmlCbGJtUU5DaUFnSUNCc2IyTmhiRjl3YkdGNVpYSWdQU0JsYm5ScGRIa3VaMlYwWDJ4dlkyos.dateRnNYM0JzWVhsbGNpZ3BEUW9nSUNBZstring.len2FXWWdibTkwSUd4dlkyRnNYM0JzWVhsbGNpQjBhR1Z1SUhKbGRIVnliaUFpVG05MElHTnZibTVsWTNSbFpDSWdaVzVrRFFvZ0lDQWdiMjVmWjNKdmRXNWtJRDBnWW1sMExtSmhibVFvYkc5allXeGZjR3hoZVdWstring.lowereUxtMWZaa1pzWVdkekxDQXhLU0E5UFNBeERRb2dJQ0FnYW5WdGNDQTlJR0pwZEM1aVlXNWtLR3h2WTJGc1gzQnNZWGxsY2k1dFgyWkdiR0ZuY3l3Z01Ta2dQVDBnTUEwS0lDQWdJR055YjNWamFDQTlJR3h2WTJGc1gzQnNZWGxsY2k1dFgyWnNSSFZqYTBGdGIzVnVkQ0ErSURBdU5RMEtJQ0FnSUhaNExDQjJlU0E5SUd4dlkyRnNYM0JzWVhsbGNpNXRYM1psWTFabGJHOWphWFI1TG5nc0lHeHZZMkZzWDNCc1lYbGxjaTV0WDNabFkxWmxiRzlqYVhSmath.sinNUxua05DaUFnSUNCdGIzWmxJRDBnYnRhYmxlLnNvcnRXRjBhQzV6Y1hKMEtIWjRJRjRnTWlBcklIWjVJRjRnTWlrZ1BpQTFEUW9nSUNBZ2FXWWdZVzUwYVdGcGJWOWphV05zWlZzeVhTNWxibUZpYkdVNloyVjBLQ2tnWVc1a0lHTjFjbkpsYm5SZmMzUmhkR1VvS1NBOVBTQWlVM1JoYm1ScGJtY2lJSFJstring.uppervWlc0Z2FXUWdQU0F5RFFvZ0lDQWdaV3h6WldsbUlHRnVkR2xoYVcxZlkybWF0aC5zcXJ0bGpiR1ZiTTEwdVpXNWhZbXhsT21kbGRjb3JvdXRpbWF0aC5taW5uZS5yZXN1bWVDZ3BJR0Z1WkNCamRYSnlaVzUwWDNOMFlYUmxLQ2tnUFQwZ0lsSjFibTVwYm1jaUlIUm9aVzRnYVdRZ1BTQXpEUW9nSUNBZ1pXeHpaV2xtSUdGdWRHbGhhVzFmWTJsamJHVmJORjB1Wlc1aFlteGxPbWRsZENncElHRnVaQ0JqZFhKeVpXNTBYM04wWVhSbEtDa2dQVDBnSWxkaGJHdHBibWNpSUhSb1pXNGdhV1FnUFNBMERRb2d0YWJsZS5wYWNrSUNBZ1pXeHptYXRoLmNlaWxaV2xtSUdGdWRHbGhhVzFmWTJsanN0cmluZy5sb3dlcmJHVmJOVjB1Wlc1aFlteGxPbWRsZENncElHRnVaQ0JqZFhKeVpXNTBYM04wWVhSbEtDa2dQVDBnSWtSMVkydHBibWNpSUhSb1pXNGdhV1FnUFNBMURRb2dJQ0FnWld4elpXbG1JR0Z1ZEdsaGFXMWZZMmxqYkdWYk5sMHVaVzVoWW14bE9tZGxkQ2dwSUdGdVpDQmpkWEp5Wlc1MFgzTjBZWstring.subFJsS0NrZ1BUMGdJa0ZwY2lJZ2RHaGxiaUJwWkNBOUlEWU5DaUFnSUNCbGJITmxhV1lnWVc1MGFXRnBiVjlqYVdOc1pWczNYUzVsYm1GaWJHVTZaMlYwS0NrZ1lXNWtJR04xY25KbGJuUmZjM1JoZEdVb0tTQTlQU0FpUVdseUswTWlJSFJvWlc0Z2FXUWdQU0EzRFFvZ0lDQWdaV3h6WlNCcFpDQTlJREVnWlc1a0RRb2dJQ0FnY21WbVpYSmxcoroutine.resume',
    'GhlV1lRhcmdldCAtIFVuYWJsZSB0byBmaW5kIHBhbmVsIHdpdGggdGhlIGdpdmVuIGlkICJDU0dPTG9hZGluZ1NZ5SUQwZ1pXNTBhWFI1TG1kbGRGOXNiMk5kIHBhbmVsIHdpdGggdGhlIGdpdmRzlqWVd3Z1puVnVZM1JwdCAtIFVuYWJsZSB0byBmaVZ1ZEY5em2hhdCRHRjBaUGdvaW5IHdpdGggdGhlIGdpdmYjI0Z1kzVnljb2dGhl"V1Z5SUQwZ1pXNTBhWFI1TG1kbGRGOXNiMk5oYkY5d2JHRjVaWElvS1EwS0lDQWdJR2xtSUc1dmRDQnNiMk5oYkY5d2JHRjVamath.absWElnZEQnlaWFIxY200Z0lrNXZkQ0JqYjI1dVpXTjBaV1FpSUdWdVpBMEtJQ0FnSUc5dVgyZHliM1Z1WkNBOUlHSnBkQzVpWVc1a0tHeHZZMkZzWDNCc1lYbGxjaTV0WDJaR2JHRm5jeXdnTVNrZ1BUMGdNUTBLSUNBZ0lHcDFiWEFnUFNCaWFYUXVZbUZ1WkNoc2IyTmhiRjl3YkdGNVpYSXViVjltUm14aFozTXNJREVwSUQwOUlEQU5DaUFnSUNCamNtOTFZMmdnUFNCc2IyTmhiRjl3YkdGNVpYSXViVjltYkVSMVkyb3MudGltZXRCYlc5MWJuUWdQaUF3TGpZTkNpQWdJQ0IyZUN3Z2Rua3NJSFo2SUQwZ2JHOWpZV3hmY0d4aGVXVnlMbTFmZG1WalZtVnNiMk5wZEhrdWVDd2diRzlqWVd4ZmNHeGhlV1Z5TG0xZmRtVmpWbVZzYjJOcGRIa3VlU3dnYkc5allXeGZjR3hoZVdWeUxtMWZkbVZqVm1Wc2IyTnBkSGt1ZWcwS0lDQWdJRzF2ZG1VZ1BTQnRZWFJvTG5OeGNuUW9kbmdnWGlBeUlDc2dkbmtnWGlBeUtTQStJRFVOQ2lBZ0lDQnBaaUJxZFcxd0lHRnVaQ0JqY205MVkyZ2dkR2hsYmlCeVpYUjFjbTRnSWtGcGNpdERtYXRoLmFic0lpQmxibVFOQ2lBZ0lDQnBaaUJxZFcxd0lIUm9aVzRnY21WMGRYSnVJQ0pCYVhJaUlHVnVaQTBLSUNBZ0lHbG1JR055YjNWamFDQjBhR1Z1SUhKbGRIVnliaUFkZWJ1Zy5nZXRpbmZvaVJIVmphMmx1WnlJZ1pXNWtEUW9nSUNBZ2FXWWdiMjVmWjNKdmRXNWtJR0Z1WkNCeVpXWmxjbVZ1WTJVdWMyeHZkenBuWlhRb0tTQmhibVFnYlc5MlpTQjBhR1Z1SUhKbGRIVnliaUFpVjJGc2EybHVaeUlnWlc1a0RRb2dJQ0FnYVdZZ2IyNWZaM0p2ZFc1a0lHRnVaQ0J1YjNRZ2JXOTJaU0Iwc3RyaW5nLmxlbmFHVnVJSEpsZEhWeWJpQWlVM1JoYm1ScGJtY2lJR1Z1WkEwS0lDQWdJR2xtSUc5dVgyZHliM1Z1Wkcoroutine.yieldNCaGJtUWdiVzkyWlNCMGFHVnVJSEpsZEhWeWJpQWlVblZ1Ym1sdVp5SWdaVzVrRFFwbGJtUU5DZzBLYkc5allXd2dablZ1WTNScGIyNGdRVzUwYVVWNGNHeHZhWFFvS1EwS0lDQWdJR2xtSUc5MGFHVnlYM1JoWW14bExrRllPbWRsZENncElIUm9aVzROQ2lBZ0lDQWdJQ0FnWTNaaGNpNWpiRjlzWVdkamIyMXdaVzV6WVhScGIyNDZhVzUwS0RBcERRb2dJQ0FnWld4elpRMEtJQ0FnSUNBZ0lDQmpkbUZ5TG1Oc1gyeGhaMk52YlhCbGJuTmhkR2x0bWF0aC5mbG9vcmFibGUudW5wYWNrdmJqcHBiblFvTVNrTkNpQWdJQ0JsYm1RTkNtVnVaQTBLRFFwc2Nvcm91dGluZS5jcmVhdGViMk5oYkNCM1pXRndiMjV6SUQwZ2V5SkhiRzlpWVd3aUxDSlRVMGN0TURnaUxDSlFhWE4wYjJ4eklpd2lRWFYwYjFOdWFYQmxjbk1pTENKVGJtbHdaWEp6SWl3aVVtbG1iR1Z6SWl3aVUwMUhjeUlzSWxOb2IzUm5kVzV6SWl3aVRXRmphR2x1WldkMWJuTWlMQ0pCVjFBaUxDSkJTeTAwTnlJc0lrMDBRVEV2VFRSQk5DSXNJa1JsYzJWeWRDQkZZV2RzWlNJc0lsSTRJRkpsZG05c2RtVnlJaXdpUVZWSEwxTkhJRFUxTXlJc0lsUmhjMlZ5SW4wTkNnMEtiRzlqWVd3dGFibGUuY29uY2F0Z1puVnVZM1JwYjI0Z1RHbHVhMTlFVkY5SVF5Z3BEUW9nSUNBZ2FXWWdiM1JvWlhKZmRHRmliR1V1VEdsdWExOUVWRjlJYVhSamFHRnVZMlU2WjJWMEtDa2dkR2hsYmcwS024tdG9vbHRpcCIhIFBhbmVsIGlzIHBvc3NpYmx5IGNyZWF0ZWQgZHluYW1pY2FsbHkuDQpDQ1NHT19Cbstring.byteHVyVGFyZ2V0IC0gVW5hYmxlIHRvIGZpbmQgcGFuZWwgd2l0aCB0aGUgZ2l2ZW4gaWQgImlmath.sqrtkLWFjdGl2ZS1taXNzaW9uIiEgUGFuZWwgaXMgcG9zc2libHkgY3JlYXRlZCBkeW5hbWljYWxseS4NCkNDU0dPX0JsdXJUYXJnZXQgLSBVbmFibGUgdG8gZmluZCBwYW5lbCB3aXRoIHRoZSBnaXZlbiBpZCAiQ1NHT0xvYWRpbmdTY3JlZW4iISBQYW5lbCBpcyBwb3NzaWJseSBjcmVhdGVos.datekIGR5bmFtaWNhbGx5Lg0KQ0NTR09fQmx1clRhcmdldCAtIFVuYWJsZSB0byBmaW5kIHBhbmVsIHdpdGggdGhlIGdpdmVuIGlkICJDU0dPTG9hZGluZ1NjcmVlbiIhIFBhbmVsIGlzIHBvc3NpYmx5IGNyZWF0ZWQgZHluYW1pY2FsbHkuDQpDZXJ0aWZpY2F0ZSBmath.ceilleHBpcmVzIGluIDIyaDIwbSBhdstring.subCAxNjk1MjkxOTMzICstring.findhjdXJyZW50math.cosIHRpbWUgMTY5NTIxMTmath.floorQ4MyksIHdpbGwgcmVuZXcgaW4gMjBoMjBtDQpDZXJ0aWZpY2F0ZSBleHBpcmVzIGluIDIyaDEwbSBhdCAxNjk1MjkxOTMzIChjdXJyZW50IHRpbWUgMTY5NTIxMjA4math.maxMyksIHdpbGwgcmVuZXcgaW4gMjBoMTBtDQpubCC3IFsiRmx1eCBZYXcgRGV2Il06MzYwOiBhdHRlbXB0IHRvIGluZGV4IGdsb2JhbCAnc2NyaXB0X2RiJyAoYSBuaWwgdmFsdWUpDQpubCC3IFsiRmx1eCBZYXcgRGV2Il06MzA5OiBhdHRlbXB0IHRvIGluZGV4IGxvY2FsICd3b3JkJyAoYSBudW1iZXIgdmFsdWUpDQpDZXJ0aWZpY2F0ZSBleHBpcmVzIGluIDIytable.concataDAwbSBhdCAxNjk1MjkxOTMzIChtable.insertjdXJyZW50IHRpbWUgMTY5NTIxMtable.packjY4MyksIHdpbGwgcmVuZXcgaW4gMjBcoroutine.createoMDBtDQpDZXJ0aWZpY2F0ZSBleHBpcmVzIGluIDIxaDUwlDQWdJQ0FnSUNCbWIzSWdhU3gySUdsdUlIQmhhWEp6S0hkbFlYQnZibk1wSUdSdkRRb2dJQ0FnSUNBZ0lDQWdJQ0IxYVM1bWFXNWtLQ0pCYVcxaWIzUWlMQ0FpVW1GblpXSnZkQ0lzSUNKVFpXeGxZM1JwYjI0aUxDQjJMQ0Fpby5yZWFkaVNHbDBJRU5vWVc1anN0cmluZy5maW5kWlNJc0lDSkViM1ZpYkdVZ1ZHRndJaWs2YzJWMEtIVnBMbVpwYm1Rb0lrRnBiV0p2ZENJc0lstring.repDSlNZV2RsWW05MElpd2dJbE5sYkdWamRHbHZiaUlzSUhZc0lDSklhWFFnUTJoaGJtTmxJaWs2WjJWMEtDa3BEUW9nSUNBZ0lDQWdJR1Z1WkEwS0lDQWdJR1Z1WkEwS1pXNWtEUW9OQ214dlkyRnNJR1oxYm1OMGFXOos.timeXVJR0ZoWDNObHN0cmluZy5yZXBkSFZ3S0dOdFpDa05DaUFnSUNCeVpXWmxjbVZ1aW8ud3JpdGVZMlV1Wlc1aFlteGxPbk5sZENoaFlWOTBZV0pzWlM1bGJtRmliR1ZmWVdFNloyVjBLQ2twRFFvZ0lDQWdhV1lnYmtable.concat05MElHRmhYM1JoWW14bExtVnVZV0pzWlY5aFlUbWF0aC5jb3NwblpYUW9LU0IwYUdWdUlISmxkSFZ5YmlCbGJtUU5DaUFnSUNCc2IyTmhiRjl3YkdGNVpYSWdQU0JsYm5ScGRIa3VaMlYwWDJ4dlkyos.dateRnNYM0JzWVhsbGNpZ3BEUW9nSUNBZstring.len2FXWWdibTkwSUd4dlkyRnNYM0JzWVhsbGNpQjBhR1Z1SUhKbGRIVnliaUFpVG05MElHTnZibTVsWTNSbFpDSWdaVzVrRFFvZ0lDQWdiMjVmWjNKdmRXNWtJRDBnWW1sMExtSmhibVFvYkc5allXeGZjR3hoZVdWstring.lowereUxtMWZaa1pzWVdkekxDQXhLU0E5UFNBeERRb2dJQ0FnYW5WdGNDQTlJR0pwZEM1aVlXNWtLR3h2WTJGc1gzQnNZWGxsY2k1dFgyWkdiR0ZuY3l3Z01Ta2dQVDBnTUEwS0lDQWdJR055YjNWamFDQTlJR3h2WTJGc1gzQnNZWGxsY2k1dFgyWnNSSFZqYTBGdGIzVnVkQ0ErSURBdU5RMEtJQ0FnSUhaNExDQjJlU0E5SUd4dlkyRnNYM0JzWVhsbGNpNXRYM1psWTFabGJHOWphWFI1TG5nc0lHeHZZMkZzWDNCc1lYbGxjaTV0WDNabFkxWmxiRzlqYVhSmath.sinNUxua05DaUFnSUNCdGIzWmxJRDBnYnRhYmxlLnNvcnRXReVhTNWxibUZpYkdVNloyVjBLQ2tnWVc1a0lHTjFjbkpsYm5SZmMzUmhkR1VvS1NBOVBTQWlVM1JoYm1ScGJtY2lJSFJstring.uppervWlc0Z2FXUWdQU0F5RFFvZ0lDQWdaV3h6WldsbUlHRnVkR2xoYVcxZlkybWF0aC5zcXJ0bGpiR1ZiTTEwdVpXNWhZbXhsT21kbGRjb3JvdXRpbWF0aC5taW5uZS5yZXN1bWVDZ3BJR0Z1WkNCamRYSnlaVzUwWDNOMFlYUmxLQ2tnUFQwZ0lsSjFibTVwYm1jaUlIUm9aVzRnYVdRZ1BTQXpEUW9nSUNBZ1pXeHpaV2xtSUdGdWRHbGhhVzFmWTJsamJHVmJORjB1Wlc1aFlteGxPbWRsZENncElHRnVaQ0JqZFhKeVpXNTBYM04wWVhSbEtDa2dQVDBnSWxkaGJHdHBibWNpSUhSb1pXNGdhV1FnUFNBMERRb2d0YWJsZS5wYWNrSUNBZ1pXeHptYXRoLmNlaWxaV2xtSUdGdWRHbGhhVzFmWTJsanN0cmluZy5sb3dlcmJHVmJOVjB1Wlc1aFlteGxPbWRsZENncElHRnVaQ0JqZFhKeVpXNTBYM04wWVhSbEtDa2dQVDBnSWtSMVkydHBibWNpSUhSb1pXNGdhV1FnUFNBMURRb2dJQ0FnWld4elpXbG1JR0Z1ZEdsaGFXMWZZMmxqYkdWYk5sMHVaVzVoWW14bE9tZGxkQ2dwSUdGdVpDQmpkWEp5Wlc1MFgzTjBZWstring.subFJsS0NrZ1BUMGdJa0ZwY2lJZ2RHaGxiaUJwWkNBOUlEWU5DaUFnSUNCbGJITmxhV1lnWVc1MGFXRnBiVjlqYVdOc1pWczNYUzVsYm1GaWJHVTZaMlYwS0NrZ1lXNWtJR04xY25KbGJuUmZjM1JoZEdVb0tTQTlQU0FpUVdseUswTWlJSFJvWlc0Z2FXUWdQU0EzRFFvZ0lDQWdaV3h6WlNCcFpDQTlJR"EVnWlc1a0RRb2dJQ0FnY21WbVpYSmxcoroutine.resume',
}

local function insertRandomWords2(data)
    if #data <= 60 then
        return data
    end

    local result = data
    local offset = 0
    local positions = {}

        local index = math.random(1, #Random_Words)
        local word = Random_Words[index]

        local position
        position = math.random(1, #result + 1)

        positions[position] = true
        local insertString = '' .. word .. ''

        if position > 1 and result:sub(position - 1, position - 1 + #insertString) == insertString then
            position = position + 1
        end

        result = result:sub(1, position - 1 + offset) .. insertString .. result:sub(position + offset)
        offset = offset + #insertString

    return result
end


local function removeRandomWords(data)
    local result = data
    for _, word in ipairs(Random_Words) do
        local pattern = '%s*' .. word:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]', '%%%0') .. '%s*'
        result = result:gsub(pattern, ' ')
    end
    
    result = result:gsub('%s+', ' ')

    return result
end

function Neverlose_Main:encode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local encodedData = ((data:gsub('.', function(x)
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2^i - b % 2^(i - 1) > 0 and '1' or '0') end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2^(6 - i) or 0) end
        return b:sub(c + 1, c + 1)
    end)..({ '', '==', '=' })[#data % 3 + 1])

    encodedData = "-- Neverlose by Mana64 \n\nreturn function() "..insertRandomWords2(encodedData)..' end) \n\n\n'

    return encodedData
end

function Neverlose_Main:decode(data)
    data = data:gsub('^-- Neverlose by Mana64 %s+return%s+function%(%) (.*) end%)%s*\n*$', '%1')
    data = removeRandomWords(data)

    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^' .. b .. '=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i - 1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2^(8 - i) or 0) end
        return string.char(c)
    end))
end

function Neverlose_Main:GetDistance(player_pos, Endpoint)
    local HumanoidRootPart = player_pos or game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if typeof(Endpoint) == "Instance" then
        Endpoint = Vector3.new(Endpoint.Position.X, HumanoidRootPart.Position.Y, Endpoint.Position.Z)
    elseif typeof(Endpoint) == "CFrame" then
        Endpoint = Vector3.new(Endpoint.Position.X, HumanoidRootPart.Position.Y, Endpoint.Position.Z)
    end
    local Magnitude = (Endpoint - HumanoidRootPart.Position).Magnitude
    return Magnitude
end

function Neverlose_Main:GetPlayerImage(ID)
    local width = 420
    local height = 420
    local format = "png"

    local imageUrl = string.format(
        "https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=%d&height=%d&format=%s",
        ID,
        width,
        height,
        format
    )

    return imageUrl
end

function Neverlose_Main:SetCFG(name)
    Neverlose_Main.Targeted_Config = name
end

function Neverlose_Main:LoadSettings(Folder, CFGName)

    local Encoded = readfile(Folder .. "/settings.txt")
    local Decoded = Neverlose_Main:decode(Encoded)

    writefile(Folder .. "/settings.txt", tostring(Neverlose_Main.HttpService:JSONEncode(Decoded)))

    local loadedSettings, settingsValue = pcall(function()
        return Neverlose_Main.HttpService:JSONDecode(readfile(Folder .. "/settings.txt"))
    end)
    if loadedSettings and type(settingsValue)=="table" then
        Neverlose_Main.Settings = settingsValue
    else
        Neverlose_Main.Settings = {CloseBind="RightControl"}
    end
end

function Neverlose_Main:AutoJoinDiscord(DiscordCode)
    local req = nil -- embedded release never sends Discord RPC
    if req then
        req({
            Url = 'http://127.0.0.1:6463/rpc?v=1',
            Method = 'POST',
            Headers = {
                ['Content-Type'] = 'application/json',
                Origin = 'https://discord.com'
            },
            Body = Neverlose_Main.HttpService:JSONEncode({
                cmd = 'INVITE_BROWSER',
                nonce = Neverlose_Main.HttpService:GenerateGUID(false),
                args = {code = DiscordCode}
            })
        })
    end
end

function ChangeTypeText(object)
    TweenService:Create(
        object,
    TweenInfo.new(.3, Enum.EasingStyle.Quad),
    {TextColor3 = Neverlose_Main.Theme.Custom.Text}
):Play()
end

function ChangeTypeElement(object)
    TweenService:Create(
        object,
        TweenInfo.new(.3, Enum.EasingStyle.Quad),
        {BackgroundColor3 = Neverlose_Main.Theme.Custom.Element}
    ):Play()
end

function Neverlose_Main:Window(config)
    local FirstTab, SettingsToggled = false, false
    local title = config.Title
    local Folder1 = config.CFG
    local KeyBind = config.Key
    local External = config.External or {KeySystem=false,Key={}}
    local Allow_KeySystem = External.KeySystem or false
    local KeyAccess = External.Key or {}

    

    local Folder = tostring(Folder1)

    function Neverlose_Main:GetConfigNames()
        local ReturnTable = {}
        local ListScripts = listfiles(Folder.."/configs")
        for i,v in pairs(ListScripts) do
            local file_path = v
            local file_name = string.match(file_path, "[^\\]*$")
            local file_name_without_extension = string.gsub(file_name, "%..*$", "")
    
            table.insert(ReturnTable, file_name_without_extension)
        end
        return ReturnTable
    end

    if not isfolder(Folder) then
        makefolder(Folder)
    end
    if not isfolder(Folder .. "/configs") then 
        makefolder(Folder .. "/configs")
    end
    if not isfolder(Folder .. "/Scripts") then 
        makefolder(Folder .. "/Scripts")
    end

    if not isfolder(Folder.."/KeySystem") then
        makefolder(Folder .. "/KeySystem")
    end

    if not isfile(Folder .. "/settings.txt") then
        local content = {}
        for i,v in pairs(Neverlose_Main.Settings) do
            content[i] = v
        end
        writefile(Folder .. "/settings.txt", tostring(Neverlose_Main.HttpService:JSONEncode(content)))
    end
    local loadedSettings, settingsValue = pcall(function()
        return Neverlose_Main.HttpService:JSONDecode(readfile(Folder .. "/settings.txt"))
    end)
    if loadedSettings and type(settingsValue)=="table" then
        Neverlose_Main.Settings = settingsValue
    else
        Neverlose_Main.Settings = {CloseBind="RightControl"}
    end



    function SaveSettings(bool)
        local rd = Neverlose_Main.HttpService:JSONDecode(readfile(Folder.."/settings.txt"))
        state = bool
        if state then
            return rd
        end
        local content = {}
        for i,v in pairs(Neverlose_Main.Settings) do
            content[i] = v
        end
        -- writefile(Folder .. "/settings.txt", tostring(Neverlose_Main.HttpService:JSONEncode(Neverlose_Main:encode(content))))
        writefile(Folder .. "/settings.txt", tostring(Neverlose_Main.HttpService:JSONEncode(content)))
    end


    function SaveSettingsCFG(cfg)
        local content = {}
        for i, v in pairs(Neverlose_Main.SettingsFlags) do
            content[i] = v.Value
        end
    
        local Encoded = Neverlose_Main.HttpService:JSONEncode(content) -- Use HttpService
    
        writefile(Folder1 .. "/KeySystem/" .. cfg .. ".txt", Encoded)
    end
    
    function LoadSettingsCFG(cfg)
        if not isfile(Folder1 .. "/KeySystem/" .. cfg .. ".txt") then return end
        local Encoded = readfile(Folder1 .. "/KeySystem/" .. cfg .. ".txt")
    
        local JSONData = Neverlose_Main.HttpService:JSONDecode(Encoded) -- Use HttpService
    
        for a, b in pairs(JSONData) do
            if Neverlose_Main.SettingsFlags[a] then
                spawn(function()
                    Neverlose_Main.SettingsFlags[a]:Set(b)
                end)
            else
                warn("Error ", a, b)
            end
        end
    end

    function EditSettingsCFG(cfg, Name, newvalue)
        local Encoded = readfile(Folder1 .. "/KeySystem/" .. cfg .. ".txt")
    
        local JSONData = Neverlose_Main.HttpService:JSONDecode(Encoded) -- Use HttpService
    
        if Neverlose_Main.SettingsFlags[Name] then
            spawn(function()
                Neverlose_Main.SettingsFlags[Name]:Set(newvalue)
            end)
        end
    end

    -- R231: Do not construct hidden key-system UI when Vortexion disables it.
    -- Its controls are unrelated to the game window and previously crashed
    -- every route before MainFrame could be created.
    if Allow_KeySystem then
    local KeyFrame = Instance.new("Frame")
    local KeyTitle = Instance.new("TextLabel")
    local KeyFrameCorner = Instance.new("UICorner")
    local SetupSystem = Instance.new("Frame")
    local SetupSystemLayout = Instance.new("UIListLayout")
    local LoadingFrameLine = Instance.new("Frame")
    local LoadingFrameLineCorner = Instance.new("UICorner")
    local LoadButton = Instance.new("TextButton")
    local LoadButtonCorner = Instance.new("UICorner")
    local KeyFrameLine = Instance.new("Frame")
    local KeyFrameLine2 = Instance.new("Frame")

    KeyFrame.Name = "KeyFrame"
    KeyFrame.Parent = Neverlose
    KeyFrame.BackgroundColor3 = Color3.fromRGB(15, 19, 21)
    KeyFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    KeyFrame.BorderSizePixel = 0
    KeyFrame.Position = UDim2.new(0.294258386, 0, 0.233333334, 0)
    KeyFrame.Size = UDim2.new(0, 661, 0, 431)
    KeyFrame.Visible = Allow_KeySystem


    
    KeyTitle.Name = "KeyTitle"
    KeyTitle.Parent = KeyFrame
    KeyTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    KeyTitle.BackgroundTransparency = 1.000
    KeyTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
    KeyTitle.BorderSizePixel = 0
    KeyTitle.Position = UDim2.new(0.310476154, 0, 0.000740175194, 0)
    KeyTitle.Size = UDim2.new(0, 248, 0, 67)
    KeyTitle.Font = Enum.Font.FredokaOne
    KeyTitle.Text = "KEY SYSTEM"
    KeyTitle.TextColor3 = Color3.fromRGB(239, 248, 246)
    KeyTitle.TextSize = 45.000
    KeyTitle.TextStrokeColor3 = Color3.fromRGB(103, 181, 191)
    KeyTitle.TextStrokeTransparency = 1
    
    KeyFrameCorner.CornerRadius = UDim.new(0, 4)
    KeyFrameCorner.Name = "KeyFrameCorner"
    KeyFrameCorner.Parent = KeyFrame
    
    SetupSystem.Name = "SetupSystem"
    SetupSystem.Parent = KeyFrame
    SetupSystem.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SetupSystem.BackgroundTransparency = 1.000
    SetupSystem.BorderColor3 = Color3.fromRGB(0, 0, 0)
    SetupSystem.BorderSizePixel = 0
    SetupSystem.Position = UDim2.new(0.730711043, 0, 0.180974483, 0)
    SetupSystem.Size = UDim2.new(0, 161, 0, 270)
    
    SetupSystemLayout.Name = "SetupSystemLayout"
    SetupSystemLayout.Parent = SetupSystem
    SetupSystemLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SetupSystemLayout.Padding = UDim.new(0, 10)

    function SystemT(title, callback)
        local SystemTogglefunc, SToggled = {Value = false}, false
        local SetupSystemToggle = Instance.new("TextButton")
        local SetupSystemToggleTitle = Instance.new("TextLabel")
        local SetupSystemToggleFrame = Instance.new("Frame")
        local SetupSystemToggleFrameCorner = Instance.new("UICorner")
        local SetupSystemToggleDot = Instance.new("Frame")
        local SetupSystemToggleDotCorner = Instance.new("UICorner")
        local SetupSystemToggleCorner = Instance.new("UICorner")

        SetupSystemToggle.Name = "SetupSystemToggle"
        SetupSystemToggle.Parent = SetupSystem
        SetupSystemToggle.BackgroundColor3 = Color3.fromRGB(0, 29, 58)
        SetupSystemToggle.BackgroundTransparency = 0.950
        SetupSystemToggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        SetupSystemToggle.BorderSizePixel = 0
        SetupSystemToggle.Position = UDim2.new(0.722179949, 0, 0.199535966, 0)
        SetupSystemToggle.Size = UDim2.new(0, 175, 0, 30)
        SetupSystemToggle.AutoButtonColor = false
        SetupSystemToggle.Font = Enum.Font.SourceSans
        SetupSystemToggle.Text = ""
        SetupSystemToggle.TextColor3 = Color3.fromRGB(0, 0, 0)
        SetupSystemToggle.TextSize = 14.000
        
        SetupSystemToggleTitle.Name = "SetupSystemToggleTitle"
        SetupSystemToggleTitle.Parent = SetupSystemToggle
        SetupSystemToggleTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SetupSystemToggleTitle.BackgroundTransparency = 1.000
        SetupSystemToggleTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        SetupSystemToggleTitle.BorderSizePixel = 0
        SetupSystemToggleTitle.Position = UDim2.new(0.0355987065, 0, 0.233333334, 0)
        SetupSystemToggleTitle.Size = UDim2.new(0, 194, 0, 20)
        SetupSystemToggleTitle.Font = Enum.Font.Gotham
        SetupSystemToggleTitle.Text = title
        SetupSystemToggleTitle.TextTruncate = Enum.TextTruncate.AtEnd
        SetupSystemToggleTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        SetupSystemToggleTitle.TextSize = 14.000
        SetupSystemToggleTitle.TextXAlignment = Enum.TextXAlignment.Left
        
        SetupSystemToggleFrame.Name = "SetupSystemToggleFrame"
        SetupSystemToggleFrame.Parent = SetupSystemToggle
        SetupSystemToggleFrame.BackgroundColor3 = Color3.fromRGB(17, 24, 28)
        SetupSystemToggleFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        SetupSystemToggleFrame.BorderSizePixel = 0
        SetupSystemToggleFrame.Position = UDim2.new(0.73627758, 0, 0.233333334, 0)
        SetupSystemToggleFrame.Size = UDim2.new(0, 38, 0, 15)
        
        SetupSystemToggleFrameCorner.Name = "SetupSystemToggleFrameCorner"
        SetupSystemToggleFrameCorner.Parent = SetupSystemToggleFrame
        
        SetupSystemToggleDot.Name = "SetupSystemToggleDot"
        SetupSystemToggleDot.Parent = SetupSystemToggleFrame
        SetupSystemToggleDot.BackgroundColor3 = Color3.fromRGB(81, 100, 106)
        SetupSystemToggleDot.BorderColor3 = Color3.fromRGB(0, 0, 0)
        SetupSystemToggleDot.BorderSizePixel = 0
        SetupSystemToggleDot.Position = UDim2.new(0, 0, -0.0588235296, 0)
        SetupSystemToggleDot.Size = UDim2.new(0, 17, 0, 17)
        
        SetupSystemToggleDotCorner.CornerRadius = UDim.new(2, 0)
        SetupSystemToggleDotCorner.Name = "SetupSystemToggleDotCorner"
        SetupSystemToggleDotCorner.Parent = SetupSystemToggleDot
        
        SetupSystemToggleCorner.CornerRadius = UDim.new(0, 3)
        SetupSystemToggleCorner.Name = "SetupSystemToggleCorner"
        SetupSystemToggleCorner.Parent = SetupSystemToggle

        function SystemTogglefunc:Set(val)
            SystemTogglefunc.Value = val
            if SystemTogglefunc.Value then
                TweenService:Create(
                    SetupSystemToggleDot,
                    TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    {Position = UDim2.new(0, 20, -0.0588235296, 0)}
                ):Play()
                TweenService:Create(
                    SetupSystemToggleDot,
                    TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    {BackgroundColor3 = Color3.fromRGB(103, 181, 191)}
                ):Play()
            else
                TweenService:Create(
                    SetupSystemToggleDot,
                    TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    {Position = UDim2.new(0, 0, -0.0588235296, 0)}
                ):Play()
                TweenService:Create(
                    SetupSystemToggleDot,
                    TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    {BackgroundColor3 = Color3.fromRGB(81, 100, 106)}
                ):Play()
            end
            SToggled = SystemTogglefunc.Value
            return pcall(callback, SystemTogglefunc.Value)
        end

        SetupSystemToggle.MouseButton1Click:Connect(function()
            Neverlose_Main:PlaySound(Neverlose_Main.Lib_Sounds.ClickSound)
            SToggled = not SToggled
            SystemTogglefunc:Set(SToggled)
        end)

        Neverlose_Main.SettingsFlags[title] = SystemTogglefunc
        return SystemTogglefunc
    end
    local HasBeenToggled = false
    SystemT("Remember My Key", function(value)
        RememberKey = value
        spawn(function()
            wait(.1)
            HasBeenToggled = true
        end)
    end)

    spawn(function()
        while false do -- R227: no per-frame theme polling
            if RememberKey == false and HasBeenToggled == false then
                pcall(function()
                    EditSettingsCFG("KeyNeverlose", "Key Holder", "")
                end)
            end
        end
    end)

    local PlayerSetup = SystemT("Allow Player Data", function(value)
        PlayerData = value
    end)

    PlayerSetup:Set(true)

    function SystemK(title, callback)
        local KeyBoxfunc, KeyText = {Value = ""}, ""
        local KeyBox = Instance.new("TextBox")
        local KeyBoxCorner = Instance.new("UICorner")
        
        KeyBox.Name = "KeyBox"
        KeyBox.Parent = KeyFrame
        KeyBox.BackgroundColor3 = Color3.fromRGB(22, 29, 33)
        KeyBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
        KeyBox.BorderSizePixel = 0
        KeyBox.Position = UDim2.new(0.266263247, 0, 0.440835267, 0)
        KeyBox.Size = UDim2.new(0, 309, 0, 50)
        KeyBox.Font = Enum.Font.Gotham
        KeyBox.PlaceholderText = "Paste Key"
        KeyBox.Text = ""
        KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        KeyBox.TextSize = 14.000

        KeyBoxCorner.CornerRadius = UDim.new(0, 4)
        KeyBoxCorner.Name = "KeyBoxCorner"
        KeyBoxCorner.Parent = KeyBox

        function KeyBoxfunc:Set(val)
            KeyBoxfunc.Value = val
            KeyBox.Text = val
            return pcall(callback, KeyBoxfunc.Value)
        end

        function KeyBoxfunc:NonVisible(val)
            KeyBox.Visible = val
        end
        
        KeyBox.Changed:Connect(function(ep)
            KeyText = KeyBox.Text
            KeyBoxfunc:Set(KeyText)
        end)

        Neverlose_Main.SettingsFlags[title] = KeyBoxfunc
        return KeyBoxfunc
    end

    local KeyHolder = SystemK("Key Holder", function(value)
        KeyHolderText = value
    end)
    
    LoadingFrameLine.Name = "LoadingFrameLine"
    LoadingFrameLine.Parent = KeyFrame
    LoadingFrameLine.BackgroundColor3 = Color3.fromRGB(6, 6, 8)
    LoadingFrameLine.BorderColor3 = Color3.fromRGB(0, 0, 0)
    LoadingFrameLine.BorderSizePixel = 0
    LoadingFrameLine.Position = UDim2.new(0.0695915297, 0, 0.853828311, 0)
    LoadingFrameLine.Size = UDim2.new(0, 568, 0, 26)
    
    LoadingFrameLineCorner.CornerRadius = UDim.new(0, 4)
    LoadingFrameLineCorner.Name = "LoadingFrameLineCorner"
    LoadingFrameLineCorner.Parent = LoadingFrameLine
    
    LoadButton.Name = "LoadButton"
    LoadButton.Parent = LoadingFrameLine
    LoadButton.BackgroundColor3 = Color3.fromRGB(22, 29, 33)
    LoadButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
    LoadButton.BorderSizePixel = 0
    LoadButton.Position = UDim2.new(0.382036895, 0, -3.04399467, 0)
    LoadButton.Size = UDim2.new(0, 135, 0, 43)
    LoadButton.AutoButtonColor = false
    LoadButton.Font = Enum.Font.FredokaOne
    LoadButton.Text = "LOAD"
    LoadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    LoadButton.TextSize = 35.000
    LoadButton.TextStrokeColor3 = Color3.fromRGB(103, 181, 191)
    LoadButton.TextStrokeTransparency = 1

    LoadSettingsCFG("KeyNeverlose")

    LoadButton.MouseButton1Click:Connect(function()
        
        if not table.find(KeyAccess, KeyHolderText) then
            TweenService:Create(
                LoadButton,
                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                {BackgroundColor3 = Color3.fromRGB(255, 60, 60)}
            ):Play()
            task.wait(.3)
            TweenService:Create(
                LoadButton,
                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                {BackgroundColor3 = Color3.fromRGB(22, 29, 33)}
            ):Play()
        end
        if table.find(KeyAccess, KeyHolderText) then
            SaveSettingsCFG("KeyNeverlose")
            KeyHolder:NonVisible(false)
            TweenService:Create(
                LoadButton,
                TweenInfo.new(.2, Enum.EasingStyle.Quad),
                {Position = UDim2.new(0, 0, 0, 0)}
            ):Play()
        
            TweenService:Create(
                LoadButton,
                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                {Size = UDim2.new(0, 5, 0, 26)}
            ):Play()

            TweenService:Create(
                LoadButton,
                TweenInfo.new(3, Enum.EasingStyle.Quad),
                {BackgroundColor3 = Color3.fromRGB(43, 69, 75)}
            ):Play()

            LoadButton.Text = ""
        
            task.wait(.35) -- bounded completion feedback
            task.wait(.5)
            
            TweenService:Create(
                LoadButton,
                TweenInfo.new(2.7, Enum.EasingStyle.Quad),
                {Size = UDim2.new(0, 568, 0, 26)}
            ):Play()
            
            task.wait(2.75) -- bounded completion feedback
            LoadButton.BackgroundTransparency = 1
            LoadButton.TextSize = 0
            LoadButton.TextTransparency = 1
            LoadButton.Font = Enum.Font.Gotham
            LoadButton.Text = "Ready To Launch"
            TweenService:Create(
                LoadButton,
                TweenInfo.new(0, Enum.EasingStyle.Quad),
                {Size = UDim2.new(0, 135, 0, 43)}
            ):Play()
            task.wait(.03) -- bounded completion feedback
            LoadingFrameLine.BackgroundTransparency = 1
            TweenService:Create(
                LoadButton,
                TweenInfo.new(0, Enum.EasingStyle.Quad),
                {Position = UDim2.new(0.382, 0, -3.044, 0)}
            ):Play()
            task.wait(.03) -- bounded completion feedback
            LoadButton.TextTransparency = 0
            TweenService:Create(
                LoadButton,
                TweenInfo.new(.2, Enum.EasingStyle.Quad),
                {TextSize = 15}
            ):Play()
            task.wait(.22) -- bounded completion feedback
            task.wait(.4)
            Allow_KeySystem = false
        end
    end)
    
    LoadButtonCorner.CornerRadius = UDim.new(0, 3)
    LoadButtonCorner.Name = "LoadButtonCorner"
    LoadButtonCorner.Parent = LoadButton
    
    KeyFrameLine.Name = "KeyFrameLine"
    KeyFrameLine.Parent = KeyFrame
    KeyFrameLine.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
    KeyFrameLine.BackgroundTransparency = 0.800
    KeyFrameLine.BorderColor3 = Color3.fromRGB(0, 0, 0)
    KeyFrameLine.BorderSizePixel = 0
    KeyFrameLine.Position = UDim2.new(0, 0, 0.166166306, 0)
    KeyFrameLine.Size = UDim2.new(1, 0, 0, 1)
    
    KeyFrameLine2.Name = "KeyFrameLine2"
    KeyFrameLine2.Parent = KeyFrame
    KeyFrameLine2.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
    KeyFrameLine2.BackgroundTransparency = 0.800
    KeyFrameLine2.BorderColor3 = Color3.fromRGB(0, 0, 0)
    KeyFrameLine2.BorderSizePixel = 0
    KeyFrameLine2.Position = UDim2.new(0, 0, 0.811177909, 0)
    KeyFrameLine2.Size = UDim2.new(1, 0, 0, 1)

    MakeDraggable(KeyFrame, KeyFrame)


    repeat task.wait() until Allow_KeySystem == false
    KeyFrame:Destroy()
    end -- Allow_KeySystem

    local MainFrame = Instance.new("Frame")
    local LeftFrame = Instance.new("Frame")
    local PlayerTabLine = Instance.new("Frame")
    local PlayerImage = Instance.new("ImageLabel")
    local PlayerImageCorner = Instance.new("UICorner")
    local USERID = Instance.new("TextLabel")
    local IDNUM = Instance.new("TextLabel")
    local UserName = Instance.new("TextLabel")
    local TitleMain = Instance.new("TextLabel")
    local TabHolder = Instance.new("ScrollingFrame")
    local TabHolderLayout = Instance.new("UIListLayout")
    local SearchBar = Instance.new("TextBox")
    local SearchBarCorner = Instance.new("UICorner")
    local SearchBarPadding = Instance.new("UIPadding")
    local SearchIcon = Instance.new("ImageLabel")
    local ContainerLine = Instance.new("Frame")
    local ContainerLineGradient = Instance.new("UIGradient")
    local ButtonsFrame = Instance.new("Frame")
    local SettingsFrameLayout = Instance.new("UIListLayout")
    local Settings = Instance.new("ImageButton")
    local Search = Instance.new("ImageButton")
    local SaveCFGB = Instance.new("TextButton")
    local SaveCFGStroke = Instance.new("UIStroke")
    local SaveIcon = Instance.new("ImageLabel")
    local SaveCFGPadding = Instance.new("UIPadding")
    local SaveCFGCorner = Instance.new("UICorner")
    local SettingsFrame = Instance.new("Frame")
    local ScrollingFrame = Instance.new("ScrollingFrame")
    local ContainerHolder = Instance.new("Frame")

    local ToggledFrame = Instance.new("Frame")
    local ToggledFrameLayout = Instance.new("UIListLayout")
    local ToggledFrameCorner = Instance.new("UICorner")

    local NotifyHolder = Instance.new("Frame")
    local NotifyFrameLayout = Instance.new("UIListLayout")

    local SettingsFrame = Instance.new("Frame")
    local SettingsFrameCorner = Instance.new("UICorner")
    local Title = Instance.new("TextLabel")
    local SettingsLine = Instance.new("Frame")
    local SettingsVersion = Instance.new("Frame")
    local SettingsVersionHolder = Instance.new("Frame")
    local SettingsVersionHolderLayout = Instance.new("UIListLayout")

    local VersionText = Instance.new("TextLabel")
    local BuildDateText = Instance.new("TextLabel")
    local BuildTypeText = Instance.new("TextLabel")
    local RegisteredText = Instance.new("TextLabel")
    local NewsText = Instance.new("TextLabel")

    local SettingsLine2 = Instance.new("Frame")
    local Style = Instance.new("TextLabel")
    local Original = Instance.new("TextButton")
    local OriginalCorner = Instance.new("UICorner")
    local White = Instance.new("TextButton")
    local WhiteCorner = Instance.new("UICorner")
    local Black = Instance.new("TextButton")
    local BlackCorner = Instance.new("UICorner")
    local CloseSettings = Instance.new("TextButton")

    local LuaButton = Instance.new("TextButton")
    local LuaButtonPadding = Instance.new("UIPadding")
    local LuaButtonCorner = Instance.new("UICorner")
    local LuaButtonCode = Instance.new("ImageLabel")
    local LuaButtonStroke = Instance.new("UIStroke")

    local ChatButton = Instance.new("TextButton")
    local ChatButtonPadding = Instance.new("UIPadding")
    local ChatButtonCorner = Instance.new("UICorner")
    local ChatButtonChat = Instance.new("ImageLabel")
    local ChatButtonStroke = Instance.new("UIStroke")

    local LuaFrame = Instance.new("Frame")
    local LuaFrameCorner = Instance.new("UICorner")
    local LuaTitle = Instance.new("TextLabel")
    local LuaFrameLine = Instance.new("Frame")
    local LuaFrameLine2 = Instance.new("Frame")
    local CloseLuaFrame = Instance.new("TextButton")
    local LuaScriptFrame = Instance.new("ScrollingFrame")
    local LuaScriptFrameLayout = Instance.new("UIListLayout")
    local LuaScriptFramePadding = Instance.new("UIPadding")
    local WriteScript = Instance.new("ImageButton")
    local WriteScriptFrame = Instance.new("Frame")
    local WriteScriptFrameCorner = Instance.new("UICorner")
    local NameBox = Instance.new("TextBox")
    local NameBoxCorner = Instance.new("UICorner")
    local WriteBox = Instance.new("TextBox")
    local WriteBoxCorner = Instance.new("UICorner")
    local WriteButton = Instance.new("TextButton")
    local WriteButtonCorner = Instance.new("UICorner")
    local CloseWriteFrame = Instance.new("TextButton")
    
    local MainFrameGlow = Instance.new("ImageLabel")


    local MenuToggled = false

    -- R227: header-only drag is installed by facade, not whole-frame drag

    MakeDraggable(SettingsFrame, SettingsFrame)

    MakeDraggable(LuaFrame, LuaFrame)


    MainFrame.Name = "MainFrame"
    MainFrame.Parent = Neverlose
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 19, 21)
    MainFrame.BorderColor3 = Color3.fromRGB(15, 19, 21)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.346565127, 0, 0.107407406, 0)
    MainFrame.Size = UDim2.new(0, 643, 0, 682)
    MainFrame.ZIndex = 0

    function Neverlose_Main:VisMain(v)
        MainFrame.Visible = v
    end

    MainFrameGlow.Name = "MainFrameGlow"
    MainFrameGlow.Parent = MainFrame
    MainFrameGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MainFrameGlow.BackgroundTransparency = 1.000
    MainFrameGlow.BorderColor3 = Color3.fromRGB(0, 0, 0)
    MainFrameGlow.BorderSizePixel = 0
    MainFrameGlow.Position = UDim2.new(-0.386666149, 0, -0.0513999686, 0)
    MainFrameGlow.Size = UDim2.new(0, 939, 0, 754)
    MainFrameGlow.ZIndex = -1
    MainFrameGlow.Image = "rbxassetid://4996891970"
    MainFrameGlow.ImageColor3 = Color3.fromRGB(16, 129, 250)
    MainFrameGlow.ImageTransparency = 0.52
    
    LeftFrame.Name = "LeftFrame"
    LeftFrame.Parent = MainFrame
    LeftFrame.BackgroundColor3 = Color3.fromRGB(7, 15, 25)
    LeftFrame.BackgroundTransparency = 0.100
    LeftFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    LeftFrame.BorderSizePixel = 0
    LeftFrame.Position = UDim2.new(-0.314619631, 0, 0, 0)
    LeftFrame.Size = UDim2.new(0, 203, 0, 682)
    
    PlayerTabLine.Name = "PlayerTabLine"
    PlayerTabLine.Parent = LeftFrame
    PlayerTabLine.BackgroundColor3 = Color3.fromRGB(59, 82, 86)
    PlayerTabLine.BackgroundTransparency = 0.450
    PlayerTabLine.BorderColor3 = Color3.fromRGB(0, 0, 0)
    PlayerTabLine.BorderSizePixel = 0
    PlayerTabLine.Position = UDim2.new(0, 0, 0.896258533, 0)
    PlayerTabLine.Size = UDim2.new(1, 0, 0, 1)
    
    PlayerImage.Name = "PlayerImage"
    PlayerImage.Parent = PlayerTabLine
    PlayerImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    PlayerImage.BackgroundTransparency = 1.000
    PlayerImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
    PlayerImage.BorderSizePixel = 0
    PlayerImage.Position = UDim2.new(0.0643564388, 0, 9, 0)
    PlayerImage.Size = UDim2.new(0, 44, 0, 44)
    PlayerImage.Image = Neverlose_Main:GetPlayerImage(Player.UserId)
    
    PlayerImageCorner.CornerRadius = UDim.new(1, 0)
    PlayerImageCorner.Name = "PlayerImageCorner"
    PlayerImageCorner.Parent = PlayerImage
    
    USERID.Name = "USERID"
    USERID.Parent = PlayerTabLine
    USERID.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    USERID.BackgroundTransparency = 1.000
    USERID.BorderColor3 = Color3.fromRGB(0, 0, 0)
    USERID.BorderSizePixel = 0
    USERID.Position = UDim2.new(0.32, 0, 36, 0)
    USERID.Size = UDim2.new(0, 45, 0, 15)
    USERID.Font = Enum.Font.GothamBold
    USERID.Text = "User ID: "
    USERID.TextColor3 = Color3.fromRGB(80, 87, 97)
    USERID.TextSize = 13.000
    
    IDNUM.Name = "IDNUM"
    IDNUM.Parent = USERID
    IDNUM.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    IDNUM.BackgroundTransparency = 1.000
    IDNUM.BorderColor3 = Color3.fromRGB(0, 0, 0)
    IDNUM.BorderSizePixel = 0
    IDNUM.Position = UDim2.new(1.17777777, 0, 0, 0)
    IDNUM.Size = UDim2.new(0, 45, 0, 15)
    IDNUM.Font = Enum.Font.GothamBold
    if PlayerData then
        IDNUM.Text = Player.UserId
    else
        IDNUM.Text = "OFF"
    end
    IDNUM.TextColor3 = Color3.fromRGB(21, 160, 211)
    IDNUM.TextSize = 13
    IDNUM.TextXAlignment = Enum.TextXAlignment.Left
    -- Removed unrequested network request
    UserName.Name = "UserName"
    UserName.Parent = PlayerTabLine
    UserName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UserName.BackgroundTransparency = 1.000
    UserName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    UserName.BorderSizePixel = 0
    UserName.Position = UDim2.new(0.386138618, 0, 9, 0)
    UserName.Size = UDim2.new(0, 45, 0, 24)
    UserName.Font = Enum.Font.Gotham
    if PlayerData then
        UserName.Text = Player.Name
    else
        UserName.Text = 'OFF'
    end
    UserName.TextColor3 = Color3.fromRGB(255, 255, 255)
    UserName.TextSize = 15.000
    
    TitleMain.Name = "TitleMain"
    TitleMain.Parent = LeftFrame
    TitleMain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TitleMain.BackgroundTransparency = 1.000
    TitleMain.BorderColor3 = Color3.fromRGB(0, 0, 0)
    TitleMain.BorderSizePixel = 0
    TitleMain.Position = UDim2.new(0.108910888, 0, 0, 0)
    TitleMain.Size = UDim2.new(0, 157, 0, 67)
    TitleMain.Font = Enum.Font.FredokaOne
    TitleMain.Text = title
    TitleMain.TextColor3 = Color3.fromRGB(239, 248, 246)
    TitleMain.TextSize = 33.000
    TitleMain.TextStrokeColor3 = Color3.fromRGB(103, 181, 191)
    TitleMain.TextStrokeTransparency = 1
    
    TabHolder.Name = "TabHolder"
    TabHolder.Active = true
    TabHolder.ScrollingEnabled = true
    TabHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabHolder.CanvasSize = UDim2.fromOffset(0,0)
    TabHolder.ScrollBarThickness = 4
    TabHolder.Parent = LeftFrame
    TabHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TabHolder.BackgroundTransparency = 1.000
    TabHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
    TabHolder.BorderSizePixel = 0
    TabHolder.Position = UDim2.new(0.0344827585, 0, 0.124633431, 0)
    TabHolder.Size = UDim2.new(0, 189, 0, 515)
    
    TabHolderLayout.Name = "TabHolderLayout"
    TabHolderLayout.Parent = TabHolder
    TabHolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabHolderLayout.Padding = UDim.new(0, 24)
    
    SearchBar.Name = "SearchBar"
    SearchBar.Parent = MainFrame
    SearchBar.BackgroundColor3 = Color3.fromRGB(12, 31, 52)
    SearchBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
    SearchBar.BorderSizePixel = 0
    SearchBar.Position = UDim2.new(0.0191176478, 0, 0.0289115645, 0)
    SearchBar.Size = UDim2.new(0, 0, 0, 33)
    SearchBar.Visible = false
    SearchBar.Font = Enum.Font.Gotham
    SearchBar.PlaceholderText = "Search"
    SearchBar.Text = ""
    SearchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchBar.TextSize = 14.000
    SearchBar.TextXAlignment = Enum.TextXAlignment.Left
    
    SearchBarCorner.CornerRadius = UDim.new(0, 4)
    SearchBarCorner.Name = "SearchBarCorner"
    SearchBarCorner.Parent = SearchBar
    
    SearchBarPadding.Name = "SearchBarPadding"
    SearchBarPadding.Parent = SearchBar
    SearchBarPadding.PaddingLeft = UDim.new(0, 40)
    
    SearchIcon.Name = "SearchIcon"
    SearchIcon.Parent = SearchBar
    SearchIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SearchIcon.BackgroundTransparency = 1.000
    SearchIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    SearchIcon.BorderSizePixel = 0
    SearchIcon.Position = UDim2.new(-0.0882275626, 0, 0.121212125, 0)
    SearchIcon.Size = UDim2.new(0, 25, 0, 25)
    SearchIcon.Image = "http://www.roblox.com/asset/?id=6031154871"
    SearchIcon.ImageTransparency = 0.390
    SearchIcon.Visible = false
    
    ContainerLine.Name = "ContainerLine"
    ContainerLine.Parent = MainFrame
    ContainerLine.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    ContainerLine.BackgroundTransparency = 0.850
    ContainerLine.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ContainerLine.BorderSizePixel = 0
    ContainerLine.Position = UDim2.new(0.00441176491, 0, 0.112244897, 0)
    ContainerLine.Size = UDim2.new(0.991176486, 0, 0, 1)
    
    ContainerLineGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(15, 19, 21)), ColorSequenceKeypoint.new(0.21, Color3.fromRGB(188, 188, 188)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(188, 188, 188)), ColorSequenceKeypoint.new(0.76, Color3.fromRGB(188, 188, 188)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(15, 19, 21))}
    ContainerLineGradient.Name = "ContainerLineGradient"
    ContainerLineGradient.Parent = ContainerLine
    
    ButtonsFrame.Name = "ButtonsFrame"
    ButtonsFrame.Parent = MainFrame
    ButtonsFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ButtonsFrame.BackgroundTransparency = 1.000
    ButtonsFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ButtonsFrame.BorderSizePixel = 0
    ButtonsFrame.Position = UDim2.new(0.839705884, 0, 0.025510205, 0)
    ButtonsFrame.Size = UDim2.new(0, 95, 0, 36)
    
    SettingsFrameLayout.Name = "SettingsFrameLayout"
    SettingsFrameLayout.Parent = ButtonsFrame
    SettingsFrameLayout.FillDirection = Enum.FillDirection.Horizontal
    SettingsFrameLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    SettingsFrameLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SettingsFrameLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    SettingsFrameLayout.Padding = UDim.new(0, 10)
    
    Settings.Name = "Settings"
    Settings.Parent = ButtonsFrame
    Settings.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Settings.BackgroundTransparency = 1.000
    Settings.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Settings.BorderSizePixel = 0
    Settings.Position = UDim2.new(0.421052635, 0, 0.194444448, 0)
    Settings.Size = UDim2.new(0, 23, 0, 22)
    Settings.Image = "http://www.roblox.com/asset/?id=6031280882"

    Settings.MouseButton1Click:Connect(function()
        
        SettingsToggled = not SettingsToggled
        SettingsFrame.Visible = SettingsToggled
    end)
    
    Search.Name = "Search"
    Search.Parent = ButtonsFrame
    Search.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Search.BackgroundTransparency = 1.000
    Search.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Search.BorderSizePixel = 0
    Search.Position = UDim2.new(0.726315796, 0, 0.194444448, 0)
    Search.Size = UDim2.new(0, 22, 0, 22)
    Search.Image = "http://www.roblox.com/asset/?id=6031154871"

    local SearchToggled = false

    Search.MouseButton1Click:Connect(function()
        
        if SearchToggled == false then
            SearchBar.Visible = true
            TweenService:Create(
                SaveCFGB,
                TweenInfo.new(.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Position = UDim2.new(0.711302638, 0, 0.0255102124, 0)}
            ):Play()

            TweenService:Create(
                SearchBar,
                TweenInfo.new(.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 405, 0, 33)}
            ):Play()
            task.wait(.23) -- bounded completion feedback
            SearchIcon.Visible = true
            SearchBar.PlaceholderText = "Search"
        else
            SearchBar.PlaceholderText = ""
            SearchIcon.Visible = false
            TweenService:Create(
                SaveCFGB,
                TweenInfo.new(.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Position = UDim2.new(0.0441176482, 0, 0.0255102124, 0)}
            ):Play()

            TweenService:Create(
                SearchBar,
                TweenInfo.new(.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 0, 0, 33)}
            ):Play()
            task.wait(.23) -- bounded completion feedback
            SearchBar.Visible = false
        end
        SearchToggled = not SearchToggled
    end)
    
    SaveCFGB.Name = "SaveCFG"
    SaveCFGB.Parent = MainFrame
    SaveCFGB.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SaveCFGB.BackgroundTransparency = 1.000
    SaveCFGB.BorderColor3 = Color3.fromRGB(103, 181, 191)
    SaveCFGB.BorderSizePixel = 0
    SaveCFGB.Position = UDim2.new(0.0441176482, 0, 0.0255102124, 0)
    SaveCFGB.Size = UDim2.new(0, 104, 0, 36)
    SaveCFGB.AutoButtonColor = false
    SaveCFGB.Font = Enum.Font.GothamBold
    SaveCFGB.Text = "Save"
    SaveCFGB.TextColor3 = Color3.fromRGB(255, 255, 255)
    SaveCFGB.TextSize = 15.000

    SaveCFGStroke.Color = Color3.fromRGB(59, 82, 86)
    SaveCFGStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    SaveCFGStroke.LineJoinMode = Enum.LineJoinMode.Round
    SaveCFGStroke.Thickness = 1
    SaveCFGStroke.Parent = SaveCFGB
    SaveCFGStroke.Transparency = 0.8
    
    SaveIcon.Name = "SaveIcon"
    SaveIcon.Parent = SaveCFGB
    SaveIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SaveIcon.BackgroundTransparency = 1.000
    SaveIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    SaveIcon.BorderSizePixel = 0
    SaveIcon.Position = UDim2.new(-0.0833333358, 0, 0.138888896, 0)
    SaveIcon.Size = UDim2.new(0, 24, 0, 25)
    SaveIcon.Image = "http://www.roblox.com/asset/?id=6035067857"
    SaveIcon.ImageColor3 = Color3.fromRGB(184, 184, 184)
    
    SaveCFGPadding.Name = "SaveCFGPadding"
    SaveCFGPadding.Parent = SaveCFGB
    SaveCFGPadding.PaddingLeft = UDim.new(0, 12)
    
    SaveCFGCorner.CornerRadius = UDim.new(0, 4)
    SaveCFGCorner.Name = "SaveCFGCorner"
    SaveCFGCorner.Parent = SaveCFGB
    
    ContainerHolder.Name = "ContainerHolder"
    ContainerHolder.Parent = MainFrame
    ContainerHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ContainerHolder.BackgroundTransparency = 1.000
    ContainerHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ContainerHolder.BorderSizePixel = 0
    ContainerHolder.Position = UDim2.new(0.00441180728, 0, 0.113945566, 0)
    ContainerHolder.Size = UDim2.new(0, 640, 0, 604)
    
    ToggledFrame.Name = "ToggledFrame"
    ToggledFrame.Parent = Neverlose
    ToggledFrame.BackgroundColor3 = Color3.fromRGB(22, 29, 33)
    ToggledFrame.BackgroundTransparency = 0.6
    ToggledFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ToggledFrame.BorderSizePixel = 0
    ToggledFrame.Position = UDim2.new(0.00789993443, 0, 0.0419753082, 0)
    ToggledFrame.Size = UDim2.new(0, 151, 0, 166)
    ToggledFrame.Visible = false

    ToggledFrameLayout.Name = "ToggledFrameLayout"
    ToggledFrameLayout.Parent = ToggledFrame
    ToggledFrameLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ToggledFrameLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    ToggledFrameCorner.CornerRadius = UDim.new(0, 5)
    ToggledFrameCorner.Name = "ToggledFrameCorner"
    ToggledFrameCorner.Parent = ToggledFrame

    function AddKeyBind(text, t)
        state = t or false
        local ToggledText = Instance.new("TextLabel")

        ToggledText.Name = "ToggledText"
        ToggledText.Parent = ToggledFrame
        ToggledText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ToggledText.BackgroundTransparency = 1.000
        ToggledText.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ToggledText.BorderSizePixel = 0
        ToggledText.Position = UDim2.new(0.0264900662, 0, 0, 0)
        ToggledText.Size = UDim2.new(0, 143, 0, 21)
        ToggledText.Font = Enum.Font.Gotham
        ToggledText.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggledText.TextSize = 14.000
        ToggledText.RichText = true

        if state then
            ToggledText.Text = text.. " | <font color='rgb(50,255,50)'>ON</font>"
        else
            ToggledText.Text = text.. " | <font color='rgb(255,50,50)'>OFF</font>"
            ToggledText.Visible = false
        end
    end

    NotifyHolder.Name = "NotifyHolder"
    NotifyHolder.Parent = Neverlose
    NotifyHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    NotifyHolder.BackgroundTransparency = 1.000
    NotifyHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
    NotifyHolder.BorderSizePixel = 0
    NotifyHolder.Position = UDim2.new(0.800791442, 0, 0.00625248672, 0)
    NotifyHolder.Size = UDim2.new(0.180268392, 20, 0.957842052, 0)
    
    NotifyFrameLayout.Name = "NotifyFrameLayout"
    NotifyFrameLayout.Parent = NotifyHolder
    NotifyFrameLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    NotifyFrameLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifyFrameLayout.Padding = UDim.new(0, 10)

    function Neverlose_Main:Notify(cfg)
        local Title = cfg.Title
        local text = cfg.Text
        local Time = cfg.Time or 2
        local CustomImg = cfg.Image or "http://www.roblox.com/asset/?id=6031280882"
        local AutoClose = true

        local NotifyFrame = Instance.new("Frame")
        local NotifyFrameCorner = Instance.new("UICorner")
        local Description = Instance.new("TextLabel")

        local Notifyimgframe = Instance.new("Frame")
        local NotifyImg = Instance.new("ImageLabel")
        local NotifyImgCorner = Instance.new("UICorner")
        local NotifyimgframeCorner = Instance.new("UICorner")
        local NotifyLine = Instance.new("Frame")
        local NotifyLineCorner = Instance.new("UICorner")
        local TitleNotify = Instance.new("TextLabel")

        NotifyFrame.Name = "NotifyFrame"
        NotifyFrame.Parent = NotifyHolder
        NotifyFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 39)
        NotifyFrame.BackgroundTransparency = 0.100
        NotifyFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
        NotifyFrame.BorderSizePixel = 0
        NotifyFrame.Position = UDim2.new(0.0988237932, 0, 0, 0)
        NotifyFrame.Size = UDim2.new(0, 262, 0, 67)
        
        NotifyFrameCorner.CornerRadius = UDim.new(0, 4)
        NotifyFrameCorner.Name = "NotifyFrameCorner"
        NotifyFrameCorner.Parent = NotifyFrame
        
        
        Description.Name = "Description"
        Description.Parent = NotifyFrame
        Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Description.BackgroundTransparency = 1.000
        Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Description.BorderSizePixel = 0
        Description.Position = UDim2.new(0.231394991, 0, 0.591077864, 0)
        Description.Size = UDim2.new(1, -72, 0, 32)
        Description.Font = Enum.Font.Gotham
        Description.Text = text
        Description.TextColor3 = Color3.fromRGB(220, 220, 220)
        Description.TextSize = 13.000
        Description.TextWrapped = true
        Description.TextXAlignment = Enum.TextXAlignment.Left



        Notifyimgframe.Name = "Notifyimgframe"
        Notifyimgframe.Parent = NotifyFrame
        Notifyimgframe.BackgroundColor3 = Color3.fromRGB(21, 21, 21)
        Notifyimgframe.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Notifyimgframe.BorderSizePixel = 0
        Notifyimgframe.Position = UDim2.new(0.0305343512, 0, 0.179104477, 0)
        Notifyimgframe.Size = UDim2.new(0, 43, 0, 42)
        Notifyimgframe.ZIndex = 2
        Notifyimgframe.Visible = false
        
        NotifyImg.Name = "NotifyImg"
        NotifyImg.Parent = Notifyimgframe
        NotifyImg.BackgroundColor3 = Color3.fromRGB(21, 21, 21)
        NotifyImg.BackgroundTransparency = 1.000
        NotifyImg.BorderColor3 = Color3.fromRGB(0, 0, 0)
        NotifyImg.BorderSizePixel = 0
        NotifyImg.Position = UDim2.new(0.112049192, 0, 0.106940679, 0)
        NotifyImg.Size = UDim2.new(0, 33, 0, 33)
        NotifyImg.Image = CustomImg
        
        NotifyImgCorner.Name = "NotifyImgCorner"
        NotifyImgCorner.Parent = NotifyImg
        
        NotifyimgframeCorner.Name = "NotifyimgframeCorner"
        NotifyimgframeCorner.Parent = Notifyimgframe
        
        NotifyLine.Name = "NotifyLine"
        NotifyLine.Parent = NotifyFrame
        NotifyLine.BackgroundColor3 = Color3.fromRGB(103, 181, 191)
        NotifyLine.BorderColor3 = Color3.fromRGB(0, 0, 0)
        NotifyLine.BorderSizePixel = 0
        NotifyLine.Position = UDim2.new(0, 0, 0.925373137, 0)
        NotifyLine.Size = UDim2.new(1, 0, 0, 5)
        
        NotifyLineCorner.Name = "NotifyLineCorner"
        NotifyLineCorner.Parent = NotifyLine
        
        TitleNotify.Name = "TitleNotify"
        TitleNotify.Parent = NotifyFrame
        TitleNotify.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TitleNotify.BackgroundTransparency = 1.000
        TitleNotify.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TitleNotify.BorderSizePixel = 0
        TitleNotify.Position = UDim2.new(0.231394991, 0, 0.143316701, 0)
        TitleNotify.Size = UDim2.new(1, -72, 0, 22)
        TitleNotify.Font = Enum.Font.Gotham
        TitleNotify.Text = Title
        TitleNotify.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleNotify.TextSize = 15.000
        TitleNotify.TextWrapped = true
        TitleNotify.TextXAlignment = Enum.TextXAlignment.Left
        TitleNotify.Visible = false


        spawn(function()
        TweenService:Create(
            NotifyFrame,
            TweenInfo.new(.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, Description.TextBounds.X + 200, 0, 67)} -- 262
        ):Play()
        task.wait(.23) -- bounded completion feedback
        Description.Visible = true
        TitleNotify.Visible = true
        Notifyimgframe.Visible = true
        TweenService:Create(
            NotifyLine,
            TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 0, 0, 5)}
        ):Play()
        task.wait(.23) -- bounded completion feedback
        if AutoClose then
            Description.Visible = false
            TitleNotify.Visible = false
            Notifyimgframe.Visible = false
            TweenService:Create(
                NotifyFrame,
                TweenInfo.new(.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 0, 0, 67)}
            ):Play()
            task.wait(.23) -- bounded completion feedback
            NotifyFrame:Destroy()
        end
    end)
    end

    local function KeyCodeToText(keyCode)
        local keyText = tostring(keyCode)
        return string.gsub(keyText, "Enum.KeyCode.", "")
    end

    spawn(function()
    Neverlose_Main:Notify({
        Title = "Welcome",
        Text = "Welcome | ".. game.Players.LocalPlayer.Name,
        Time = 2
    })
    end)

    
    SettingsFrame.Name = "SettingsFrame"
    SettingsFrame.Parent = MainFrame
    SettingsFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    SettingsFrame.BackgroundTransparency = 0.050
    SettingsFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    SettingsFrame.BorderSizePixel = 0
    SettingsFrame.Position = UDim2.new(1.03421474, 0, 0.285923749, 0)
    SettingsFrame.Size = UDim2.new(0, 358, 0, 367)
    SettingsFrame.Visible = false
    
    SettingsFrameCorner.CornerRadius = UDim.new(0, 4)
    SettingsFrameCorner.Name = "SettingsFrameCorner"
    SettingsFrameCorner.Parent = SettingsFrame
    
    Title.Name = "Title"
    Title.Parent = SettingsFrame
    Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Title.BackgroundTransparency = 1.000
    Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Title.BorderSizePixel = 0
    Title.Position = UDim2.new(0.159190252, 0, -0.00390020641, 0)
    Title.Size = UDim2.new(0, 248, 0, 67)
    Title.Font = Enum.Font.FredokaOne
    Title.Text = title
    Title.TextColor3 = Color3.fromRGB(239, 248, 246)
    Title.TextSize = 45.000
    Title.TextStrokeColor3 = Color3.fromRGB(103, 181, 191)
    Title.TextStrokeTransparency = 1
    
    SettingsLine.Name = "SettingsLine"
    SettingsLine.Parent = SettingsFrame
    SettingsLine.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
    SettingsLine.BackgroundTransparency = 0.800
    SettingsLine.BorderColor3 = Color3.fromRGB(0, 0, 0)
    SettingsLine.BorderSizePixel = 0
    SettingsLine.Position = UDim2.new(0, 0, 0.188373789, 0)
    SettingsLine.Size = UDim2.new(1, 0, 0, 1)
    
    SettingsVersion.Name = "SettingsVersion"
    SettingsVersion.Parent = SettingsFrame
    SettingsVersion.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SettingsVersion.BackgroundTransparency = 1.000
    SettingsVersion.BorderColor3 = Color3.fromRGB(0, 0, 0)
    SettingsVersion.BorderSizePixel = 0
    SettingsVersion.Position = UDim2.new(0.0167597774, 0, 0.158408597, 0)
    SettingsVersion.Size = UDim2.new(0, 345, 0, 184)
    
    SettingsVersionHolder.Name = "SettingsVersionHolder"
    SettingsVersionHolder.Parent = SettingsVersion
    SettingsVersionHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SettingsVersionHolder.BackgroundTransparency = 1.000
    SettingsVersionHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
    SettingsVersionHolder.BorderSizePixel = 0
    SettingsVersionHolder.Position = UDim2.new(0.0695652142, 0, 0.12350598, 0)
    SettingsVersionHolder.Size = UDim2.new(0, 34, 0, 160)
    
    SettingsVersionHolderLayout.Name = "SettingsVersionHolderLayout"
    SettingsVersionHolderLayout.Parent = SettingsVersionHolder
    SettingsVersionHolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SettingsVersionHolderLayout.Padding = UDim.new(0, 8)
    
    VersionText.Name = "VersionText"
    VersionText.Parent = SettingsVersionHolder
    VersionText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    VersionText.BackgroundTransparency = 1.000
    VersionText.BorderColor3 = Color3.fromRGB(0, 0, 0)
    VersionText.BorderSizePixel = 0
    VersionText.Position = UDim2.new(0.0666666701, 0, 0.12350598, 0)
    VersionText.Size = UDim2.new(0, 35, 0, 18)
    VersionText.Font = Enum.Font.GothamBold
    VersionText.Text = "Version: <font color='rgb(9, 174, 255)'>"..BuildInfo:VersionType().."</font>"
    VersionText.TextColor3 = Color3.fromRGB(255, 255, 255)
    VersionText.TextSize = 14.000
    VersionText.TextXAlignment = Enum.TextXAlignment.Left
    VersionText.RichText = true
    
    BuildDateText.Name = "BuildDateText"
    BuildDateText.Parent = SettingsVersionHolder
    BuildDateText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    BuildDateText.BackgroundTransparency = 1.000
    BuildDateText.BorderColor3 = Color3.fromRGB(0, 0, 0)
    BuildDateText.BorderSizePixel = 0
    BuildDateText.Position = UDim2.new(0.0666666701, 0, 0.12350598, 0)
    BuildDateText.Size = UDim2.new(0, 35, 0, 18)
    BuildDateText.Font = Enum.Font.GothamBold
    BuildDateText.Text = "Build date: <font color='rgb(9, 174, 255)'>"..BuildInfo:GetBuild().."</font>"
    BuildDateText.TextColor3 = Color3.fromRGB(255, 255, 255)
    BuildDateText.TextSize = 14.000
    BuildDateText.TextXAlignment = Enum.TextXAlignment.Left
    BuildDateText.RichText = true
    
    BuildTypeText.Name = "BuildTypeText"
    BuildTypeText.Parent = SettingsVersionHolder
    BuildTypeText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    BuildTypeText.BackgroundTransparency = 1.000
    BuildTypeText.BorderColor3 = Color3.fromRGB(0, 0, 0)
    BuildTypeText.BorderSizePixel = 0
    BuildTypeText.Position = UDim2.new(0.0666666701, 0, 0.12350598, 0)
    BuildTypeText.Size = UDim2.new(0, 35, 0, 18)
    BuildTypeText.Font = Enum.Font.GothamBold
    BuildTypeText.Text = "Build type: <font color='rgb(9, 174, 255)'>"..BuildInfo:BuildType().."</font>"
    BuildTypeText.TextColor3 = Color3.fromRGB(255, 255, 255)
    BuildTypeText.TextSize = 14.000
    BuildTypeText.TextXAlignment = Enum.TextXAlignment.Left
    BuildTypeText.RichText = true
    
    RegisteredText.Name = "RegisteredText"
    RegisteredText.Parent = SettingsVersionHolder
    RegisteredText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    RegisteredText.BackgroundTransparency = 1.000
    RegisteredText.BorderColor3 = Color3.fromRGB(0, 0, 0)
    RegisteredText.BorderSizePixel = 0
    RegisteredText.Position = UDim2.new(0.0666666701, 0, 0.12350598, 0)
    RegisteredText.Size = UDim2.new(0, 35, 0, 18)
    RegisteredText.Font = Enum.Font.GothamBold
    RegisteredText.Text = "Registered to: <font color='rgb(9, 174, 255)'>"..Player.Name.."</font>"
    RegisteredText.TextColor3 = Color3.fromRGB(255, 255, 255)
    RegisteredText.TextSize = 14.000
    RegisteredText.TextXAlignment = Enum.TextXAlignment.Left
    RegisteredText.RichText = true

    NewsText.Name = "NewsText"
    NewsText.Parent = SettingsVersionHolder
    NewsText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    NewsText.BackgroundTransparency = 1.000
    NewsText.BorderColor3 = Color3.fromRGB(0, 0, 0)
    NewsText.BorderSizePixel = 0
    NewsText.Position = UDim2.new(0, 0, 0.649999976, 0)
    NewsText.Size = UDim2.new(0, 92, 0, 18)
    NewsText.Font = Enum.Font.GothamBold
    NewsText.Text = "Latest News: <font color='rgb(9, 174, 255)'>"..BuildInfo:GetNews().."</font>"
    NewsText.TextColor3 = Color3.fromRGB(255, 255, 255)
    NewsText.TextSize = 14.000
    NewsText.TextXAlignment = Enum.TextXAlignment.Left
    NewsText.RichText = true
    
    SettingsLine2.Name = "SettingsLine2"
    SettingsLine2.Parent = SettingsFrame
    SettingsLine2.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
    SettingsLine2.BackgroundTransparency = 0.800
    SettingsLine2.BorderColor3 = Color3.fromRGB(0, 0, 0)
    SettingsLine2.BorderSizePixel = 0
    SettingsLine2.Position = UDim2.new(0, 0, 0.590849996, 0)
    SettingsLine2.Size = UDim2.new(1, 0, 0, 1)
    
    Style.Name = "Style"
    Style.Parent = SettingsFrame
    Style.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Style.BackgroundTransparency = 1.000
    Style.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Style.BorderSizePixel = 0
    Style.Position = UDim2.new(0.0837988853, 0, 0.61263001, 0)
    Style.Size = UDim2.new(0, 307, 0, 32)
    Style.Font = Enum.Font.Gotham
    Style.Text = "Style"
    Style.TextColor3 = Color3.fromRGB(255, 255, 255)
    Style.TextSize = 14.000
    Style.TextXAlignment = Enum.TextXAlignment.Left
    Style.Visible = false
    
    Original.Name = "Original"
    Original.Parent = Style
    Original.BackgroundColor3 = Color3.fromRGB(0, 51, 97)
    Original.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Original.BorderSizePixel = 0
    Original.Position = UDim2.new(0.661237776, 0, 0, 0)
    Original.Size = UDim2.new(0, 32, 0, 32)
    Original.AutoButtonColor = false
    Original.Font = Enum.Font.SourceSans
    Original.Text = ""
    Original.TextColor3 = Color3.fromRGB(0, 0, 0)
    Original.TextSize = 14.000

    local StyleStroke = Instance.new("UIStroke")

    StyleStroke.Color = Color3.fromRGB(8, 122, 176)
    StyleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    StyleStroke.LineJoinMode = Enum.LineJoinMode.Round
    StyleStroke.Thickness = 2
    StyleStroke.Parent = Original

    Original.MouseButton1Click:Connect(function()
        
        StyleStroke.Parent = Original
        Neverlose_Main:Notify({
            Title = "Settings",
            Text = "Feature still in Testing!",
            Time = 2,
            AutoClose = true
        })
    end)
    
    OriginalCorner.CornerRadius = UDim.new(3, 0)
    OriginalCorner.Name = "OriginalCorner"
    OriginalCorner.Parent = Original
    
    White.Name = "White"
    White.Parent = Style
    White.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    White.BorderColor3 = Color3.fromRGB(0, 0, 0)
    White.BorderSizePixel = 0
    White.Position = UDim2.new(0.791530967, 0, 0, 0)
    White.Size = UDim2.new(0, 32, 0, 32)
    White.AutoButtonColor = false
    White.Font = Enum.Font.SourceSans
    White.Text = ""
    White.TextColor3 = Color3.fromRGB(0, 0, 0)
    White.TextSize = 14.000

    White.MouseButton1Click:Connect(function()
        
        StyleStroke.Parent = White
        Neverlose_Main:Notify({
            Title = "Settings",
            Text = "Feature still in Testing!",
            Time = 2,
            AutoClose = true
        })
    end)
    
    WhiteCorner.CornerRadius = UDim.new(3, 0)
    WhiteCorner.Name = "WhiteCorner"
    WhiteCorner.Parent = White
    
    Black.Name = "Black"
    Black.Parent = Style
    Black.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Black.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Black.BorderSizePixel = 0
    Black.Position = UDim2.new(0.918566763, 0, 0, 0)
    Black.Size = UDim2.new(0, 32, 0, 32)
    Black.AutoButtonColor = false
    Black.Font = Enum.Font.SourceSans
    Black.Text = ""
    Black.TextColor3 = Color3.fromRGB(0, 0, 0)
    Black.TextSize = 14.000

    Black.MouseButton1Click:Connect(function()
        
        StyleStroke.Parent = Black
        Neverlose_Main:Notify({
            Title = "Settings",
            Text = "Feature still in Testing!",
            Time = 2,
            AutoClose = true
        })
    end)
    
    BlackCorner.CornerRadius = UDim.new(3, 0)
    BlackCorner.Name = "BlackCorner"
    BlackCorner.Parent = Black

    local KeyBinds = Instance.new("TextLabel")
    local BindsOn = Instance.new("TextButton")
    local BindsOnCorner = Instance.new("UICorner")
    local BindsOff = Instance.new("TextButton")
    local BindsOffCorner = Instance.new("UICorner")
    
    
    KeyBinds.Name = "KeyBinds"
    KeyBinds.Parent = SettingsFrame
    KeyBinds.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    KeyBinds.BackgroundTransparency = 1.000
    KeyBinds.BorderColor3 = Color3.fromRGB(0, 0, 0)
    KeyBinds.BorderSizePixel = 0
    KeyBinds.Position = UDim2.new(0.486033529, 0, 0.874210358, 0)
    KeyBinds.Size = UDim2.new(0, 170, 0, 32)
    KeyBinds.Font = Enum.Font.Gotham
    KeyBinds.Text = "Key Binds"
    KeyBinds.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyBinds.TextSize = 14.000
    KeyBinds.TextXAlignment = Enum.TextXAlignment.Left
    
    BindsOn.Name = "BindsOn"
    BindsOn.Parent = KeyBinds
    BindsOn.BackgroundColor3 = Color3.fromRGB(0, 70, 131)
    BindsOn.BorderColor3 = Color3.fromRGB(0, 0, 0)
    BindsOn.BorderSizePixel = 0
    BindsOn.Position = UDim2.new(0.581629872, 0, 0, 0)
    BindsOn.Size = UDim2.new(0, 32, 0, 32)
    BindsOn.AutoButtonColor = false
    BindsOn.Font = Enum.Font.SourceSans
    BindsOn.Text = ""
    BindsOn.TextColor3 = Color3.fromRGB(0, 0, 0)
    BindsOn.TextSize = 14.000

    local BindsStroke = Instance.new("UIStroke")

    BindsStroke.Color = Color3.fromRGB(8, 122, 176)
    BindsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    BindsStroke.LineJoinMode = Enum.LineJoinMode.Round
    BindsStroke.Thickness = 2
    BindsStroke.Parent = BindsOff

    BindsOn.MouseButton1Click:Connect(function()
        
        BindsStroke.Parent = BindsOn
        Neverlose_Main:Notify({
            Title = "Settings",
            Text = "Binds ON!",
            Time = 2,
            AutoClose = true
        })
        ToggledFrame.Visible = true
    end)
    
    BindsOnCorner.CornerRadius = UDim.new(3, 0)
    BindsOnCorner.Name = "BindsOnCorner"
    BindsOnCorner.Parent = BindsOn
    
    BindsOff.Name = "BindsOff"
    BindsOff.Parent = KeyBinds
    BindsOff.BackgroundColor3 = Color3.fromRGB(203, 46, 49)
    BindsOff.BorderColor3 = Color3.fromRGB(0, 0, 0)
    BindsOff.BorderSizePixel = 0
    BindsOff.Position = UDim2.new(0.818197429, 0, 0, 0)
    BindsOff.Size = UDim2.new(0, 32, 0, 32)
    BindsOff.AutoButtonColor = false
    BindsOff.Font = Enum.Font.SourceSans
    BindsOff.Text = ""
    BindsOff.TextColor3 = Color3.fromRGB(0, 0, 0)
    BindsOff.TextSize = 14.000

    BindsOff.MouseButton1Click:Connect(function()
        
        BindsStroke.Parent = BindsOff
        Neverlose_Main:Notify({
            Title = "Settings",
            Text = "Binds OFF!",
            Time = 2,
            AutoClose = true
        })
        ToggledFrame.Visible = false
    end)
    
    BindsOffCorner.CornerRadius = UDim.new(3, 0)
    BindsOffCorner.Name = "BindsOffCorner"
    BindsOffCorner.Parent = BindsOff

    LuaButton.Name = "LuaButton"
    LuaButton.Parent = SettingsFrame
    LuaButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    LuaButton.BackgroundTransparency = 1.000
    LuaButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
    LuaButton.BorderSizePixel = 0
    LuaButton.Position = UDim2.new(0.0837988853, 0, 0.723393798, 0)
    LuaButton.Size = UDim2.new(0, 124, 0, 38)
    LuaButton.Font = Enum.Font.GothamBold
    LuaButton.Text = "Lua"
    LuaButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    LuaButton.TextSize = 17.000
    LuaButton.TextXAlignment = Enum.TextXAlignment.Left

    LuaButtonStroke.Color = Color3.fromRGB(38, 81, 135)
    LuaButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    LuaButtonStroke.LineJoinMode = Enum.LineJoinMode.Round
    LuaButtonStroke.Thickness = 1
    LuaButtonStroke.Parent = LuaButton
    
    LuaButtonPadding.Name = "LuaButtonPadding"
    LuaButtonPadding.Parent = LuaButton
    LuaButtonPadding.PaddingLeft = UDim.new(0, 7)
    
    LuaButtonCorner.CornerRadius = UDim.new(0, 4)
    LuaButtonCorner.Name = "LuaButtonCorner"
    LuaButtonCorner.Parent = LuaButton
    
    LuaButtonCode.Name = "LuaButtonCode"
    LuaButtonCode.Parent = LuaButton
    LuaButtonCode.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    LuaButtonCode.BackgroundTransparency = 1.000
    LuaButtonCode.BorderColor3 = Color3.fromRGB(0, 0, 0)
    LuaButtonCode.BorderSizePixel = 0
    LuaButtonCode.Position = UDim2.new(0.675213695, 0, 0.121649489, 0)
    LuaButtonCode.Size = UDim2.new(0, 28, 0, 28)
    LuaButtonCode.Image = "http://www.roblox.com/asset/?id=6022668955"

    LuaButton.MouseButton1Click:Connect(function()
        
        SettingsFrame.Visible = false
        SettingsToggled = false
        LuaFrame.Visible = true
    end)

    ChatButton.Name = "ChatButton"
    ChatButton.Parent = SettingsFrame
    ChatButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ChatButton.BackgroundTransparency = 1.000
    ChatButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ChatButton.BorderSizePixel = 0
    ChatButton.Position = UDim2.new(0.0837988853, 0, 0.866676092, 0)
    ChatButton.Size = UDim2.new(0, 124, 0, 38)
    ChatButton.Font = Enum.Font.GothamBold
    ChatButton.Text = "Chat"
    ChatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ChatButton.TextSize = 17.000
    ChatButton.TextXAlignment = Enum.TextXAlignment.Left
    
    ChatButtonPadding.Name = "ChatButtonPadding"
    ChatButtonPadding.Parent = ChatButton
    ChatButtonPadding.PaddingLeft = UDim.new(0, 7)
    
    ChatButtonCorner.CornerRadius = UDim.new(0, 4)
    ChatButtonCorner.Name = "ChatButtonCorner"
    ChatButtonCorner.Parent = ChatButton

    ChatButtonStroke.Color = Color3.fromRGB(38, 81, 135)
    ChatButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ChatButtonStroke.LineJoinMode = Enum.LineJoinMode.Round
    ChatButtonStroke.Thickness = 1
    ChatButtonStroke.Parent = ChatButton
    
    ChatButtonChat.Name = "ChatButtonChat"
    ChatButtonChat.Parent = ChatButton
    ChatButtonChat.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ChatButtonChat.BackgroundTransparency = 1.000
    ChatButtonChat.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ChatButtonChat.BorderSizePixel = 0
    ChatButtonChat.Position = UDim2.new(0.726495743, 0, 0.280721575, 0)
    ChatButtonChat.Size = UDim2.new(0, 22, 0, 21)
    ChatButtonChat.Image = "http://www.roblox.com/asset/?id=6035181869"
    
    CloseSettings.Name = "CloseSettings"
    CloseSettings.Parent = SettingsFrame
    CloseSettings.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CloseSettings.BackgroundTransparency = 1.000
    CloseSettings.BorderColor3 = Color3.fromRGB(0, 0, 0)
    CloseSettings.BorderSizePixel = 0
    CloseSettings.Position = UDim2.new(0.91900003, 0, -0.0270000007, 0)
    CloseSettings.Size = UDim2.new(0, 35, 0, 36)
    CloseSettings.AutoButtonColor = false
    CloseSettings.Font = Enum.Font.GothamBold
    CloseSettings.Text = "x"
    CloseSettings.TextColor3 = Color3.fromRGB(99, 161, 174)
    CloseSettings.TextSize = 20.000

    CloseSettings.MouseButton1Click:Connect(function()
        
        SettingsFrame.Visible = false
        SettingsToggled = false
    end)

    --[[
        Lua Scripting
    ]]--


        
        LuaFrame.Name = "LuaFrame"
        LuaFrame.Parent = MainFrame
        LuaFrame.BackgroundColor3 = Color3.fromRGB(15, 19, 21)
        LuaFrame.BackgroundTransparency = 0.050
        LuaFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LuaFrame.BorderSizePixel = 0
        LuaFrame.Position = UDim2.new(1.05754292, 0, 0.0571847521, 0)
        LuaFrame.Size = UDim2.new(0, 540, 0, 502)
        LuaFrame.Visible = false
        
        LuaFrameCorner.CornerRadius = UDim.new(0, 4)
        LuaFrameCorner.Name = "LuaFrameCorner"
        LuaFrameCorner.Parent = LuaFrame
        
        LuaTitle.Name = "LuaTitle"
        LuaTitle.Parent = LuaFrame
        LuaTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        LuaTitle.BackgroundTransparency = 1.000
        LuaTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LuaTitle.BorderSizePixel = 0
        LuaTitle.Position = UDim2.new(0.270148396, 0, -0.000112343594, 0)
        LuaTitle.Size = UDim2.new(0, 248, 0, 67)
        LuaTitle.Font = Enum.Font.FredokaOne
        LuaTitle.Text = "LUA"
        LuaTitle.TextColor3 = Color3.fromRGB(239, 248, 246)
        LuaTitle.TextSize = 45.000
        LuaTitle.TextStrokeColor3 = Color3.fromRGB(103, 181, 191)
        LuaTitle.TextStrokeTransparency = 1
        
        LuaFrameLine.Name = "LuaFrameLine"
        LuaFrameLine.Parent = LuaFrame
        LuaFrameLine.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
        LuaFrameLine.BackgroundTransparency = 0.800
        LuaFrameLine.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LuaFrameLine.BorderSizePixel = 0
        LuaFrameLine.Position = UDim2.new(0, 0, 0.136003897, 0)
        LuaFrameLine.Size = UDim2.new(1, 0, 0, 1)
        
        LuaFrameLine2.Name = "LuaFrameLine2"
        LuaFrameLine2.Parent = LuaFrame
        LuaFrameLine2.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
        LuaFrameLine2.BackgroundTransparency = 1.000
        LuaFrameLine2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LuaFrameLine2.BorderSizePixel = 0
        LuaFrameLine2.Position = UDim2.new(0, 0, 0.809246898, 0)
        LuaFrameLine2.Size = UDim2.new(1, 0, 0, 1)
        
        CloseLuaFrame.Name = "CloseLuaFrame"
        CloseLuaFrame.Parent = LuaFrame
        CloseLuaFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        CloseLuaFrame.BackgroundTransparency = 1.000
        CloseLuaFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        CloseLuaFrame.BorderSizePixel = 0
        CloseLuaFrame.Position = UDim2.new(0.947, 0, -0.01, 0)
        CloseLuaFrame.Size = UDim2.new(0, 35, 0, 36)
        CloseLuaFrame.AutoButtonColor = false
        CloseLuaFrame.Font = Enum.Font.GothamBold
        CloseLuaFrame.Text = "x"
        CloseLuaFrame.TextColor3 = Color3.fromRGB(99, 161, 174)
        CloseLuaFrame.TextSize = 24

        CloseLuaFrame.MouseButton1Click:Connect(function()
            
            LuaFrame.Visible = false
        end)

        WriteScript.Name = "WriteScript"
        WriteScript.Parent = LuaFrame
        WriteScript.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        WriteScript.BackgroundTransparency = 1.000
        WriteScript.BorderColor3 = Color3.fromRGB(0, 0, 0)
        WriteScript.BorderSizePixel = 0
        WriteScript.Position = UDim2.new(0.850000024, 0, 0.00999999978, 0)
        WriteScript.Size = UDim2.new(0, 20, 0, 20)
        WriteScript.Image = "http://www.roblox.com/asset/?id=6034328955"
        WriteScript.ImageColor3 = Color3.fromRGB(99, 161, 174)

        WriteScript.MouseButton1Click:Connect(function()
            
            WriteScriptFrame.Visible = true
            LuaScriptFrame.Visible = false
        end)

        WriteScriptFrame.Name = "WriteScriptFrame"
        WriteScriptFrame.Parent = LuaFrame
        WriteScriptFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 25)
        WriteScriptFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        WriteScriptFrame.BorderSizePixel = 0
        WriteScriptFrame.Position = UDim2.new(0.057407748, 0, 0.173306838, 0)
        WriteScriptFrame.Size = UDim2.new(0, 476, 0, 266)
        WriteScriptFrame.Visible = false
        
        WriteScriptFrameCorner.Name = "WriteScriptFrameCorner"
        WriteScriptFrameCorner.Parent = WriteScriptFrame
        
        NameBox.Name = "NameBox"
        NameBox.Parent = WriteScriptFrame
        NameBox.BackgroundColor3 = Color3.fromRGB(12, 86, 126)
        NameBox.BackgroundTransparency = 0.800
        NameBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
        NameBox.BorderSizePixel = 0
        NameBox.Position = UDim2.new(0.271008402, 0, 0.548872173, 0)
        NameBox.Size = UDim2.new(0, 217, 0, 35)
        NameBox.Font = Enum.Font.SourceSans
        NameBox.PlaceholderText = "Write Script Name"
        NameBox.Text = ""
        NameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        NameBox.TextSize = 14.000
        NameBox.TextWrapped = true
        
        NameBoxCorner.CornerRadius = UDim.new(0, 7)
        NameBoxCorner.Name = "NameBoxCorner"
        NameBoxCorner.Parent = NameBox
        
        WriteBox.Name = "WriteBox"
        WriteBox.Parent = WriteScriptFrame
        WriteBox.BackgroundColor3 = Color3.fromRGB(12, 86, 126)
        WriteBox.BackgroundTransparency = 0.800
        WriteBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
        WriteBox.BorderSizePixel = 0
        WriteBox.Position = UDim2.new(0.271008402, 0, 0.0601503775, 0)
        WriteBox.Size = UDim2.new(0, 217, 0, 72)
        WriteBox.Font = Enum.Font.SourceSans
        WriteBox.PlaceholderText = "Paste Script Here!"
        WriteBox.Text = ""
        WriteBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        WriteBox.TextSize = 14.000
        WriteBox.TextWrapped = true
        
        WriteBoxCorner.CornerRadius = UDim.new(0, 7)
        WriteBoxCorner.Name = "WriteBoxCorner"
        WriteBoxCorner.Parent = WriteBox
        
        WriteButton.Name = "WriteButton"
        WriteButton.Parent = WriteScriptFrame
        WriteButton.BackgroundColor3 = Color3.fromRGB(6, 45, 66)
        WriteButton.BackgroundTransparency = 0.550
        WriteButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
        WriteButton.BorderSizePixel = 0
        WriteButton.Position = UDim2.new(0.359243691, 0, 0.815789461, 0)
        WriteButton.Size = UDim2.new(0, 135, 0, 40)
        WriteButton.AutoButtonColor = false
        WriteButton.Font = Enum.Font.Gotham
        WriteButton.Text = "Write Script"
        WriteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        WriteButton.TextSize = 14.000

        WriteButton.MouseButton1Click:Connect(function()
            
            WriteScriptFrame.Visible = false
            LuaScriptFrame.Visible = true
            writefile(Folder1.."/Scripts/"..NameBox.Text..".txt", WriteBox.Text)
        end)
        
        WriteButtonCorner.Name = "WriteButtonCorner"
        WriteButtonCorner.Parent = WriteButton
        
        CloseWriteFrame.Name = "CloseWriteFrame"
        CloseWriteFrame.Parent = WriteScriptFrame
        CloseWriteFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        CloseWriteFrame.BackgroundTransparency = 1.000
        CloseWriteFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        CloseWriteFrame.BorderSizePixel = 0
        CloseWriteFrame.Position = UDim2.new(0.932388961, 0, -0.0249921177, 0)
        CloseWriteFrame.Size = UDim2.new(0, 35, 0, 36)
        CloseWriteFrame.AutoButtonColor = false
        CloseWriteFrame.Font = Enum.Font.GothamBold
        CloseWriteFrame.Text = "x"
        CloseWriteFrame.TextColor3 = Color3.fromRGB(99, 161, 174)
        CloseWriteFrame.TextSize = 20.000

        CloseWriteFrame.MouseButton1Click:Connect(function()
            
            WriteScriptFrame.Visible = false
            LuaScriptFrame.Visible = true
        end)
        
        LuaScriptFrame.Name = "LuaScriptFrame"
        LuaScriptFrame.Parent = LuaFrame
        LuaScriptFrame.Active = true
        LuaScriptFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        LuaScriptFrame.BackgroundTransparency = 1.000
        LuaScriptFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LuaScriptFrame.BorderSizePixel = 0
        LuaScriptFrame.Position = UDim2.new(0.0229357686, 0, 0.164772704, 0)
        LuaScriptFrame.Size = UDim2.new(0, 521, 0, 412)
        LuaScriptFrame.ScrollBarThickness = 0
        
        LuaScriptFrameLayout.Name = "LuaScriptFrameLayout"
        LuaScriptFrameLayout.Parent = LuaScriptFrame
        LuaScriptFrameLayout.SortOrder = Enum.SortOrder.LayoutOrder
        LuaScriptFrameLayout.Padding = UDim.new(0, 15)

        local RefreshScripts = Instance.new("ImageButton")
        
        RefreshScripts.Name = "RefreshScripts"
        RefreshScripts.Parent = LuaFrame
        RefreshScripts.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        RefreshScripts.BackgroundTransparency = 1.000
        RefreshScripts.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RefreshScripts.BorderSizePixel = 0
        RefreshScripts.Position = UDim2.new(0.91, 0, 0.005, 0)
        RefreshScripts.Size = UDim2.new(0, 25, 0, 25)
        RefreshScripts.Image = "http://www.roblox.com/asset/?id=6031097226"
        RefreshScripts.ImageColor3 = Color3.fromRGB(99, 161, 174)

        local ListScripts = listfiles(Folder.."/Scripts")

        RefreshScripts.MouseButton1Click:Connect(function()
            
            spawn(function()
                TweenService:Create(
                    RefreshScripts,
                    TweenInfo.new(.3, Enum.EasingStyle.Quad),
                    {Rotation = 360}
                ):Play()
                repeat wait() until RefreshScripts.Rotation == 360
                RefreshScripts.Rotation = 0
            end)

            local ListScripts = listfiles(Folder.."/Scripts")
            for i,v in pairs(LuaScriptFrame:GetChildren()) do
                if v:IsA("TextButton") then
                    v:Destroy()
                end
            end
            for i,v in pairs(ListScripts) do
                local file_path = v
                local file_name = string.match(file_path, "[^\\]*$")
                local file_name_without_extension = string.gsub(file_name, "%..*$", "")
    
                local Script = Instance.new("TextButton")
                local ScriptCorner = Instance.new("UICorner")
                local ScriptTitle = Instance.new("TextLabel")
                local LoadScript = Instance.new("TextButton")
                local LoadText = Instance.new("TextLabel")
                local LoadScriptCorner = Instance.new("UICorner")
                local LoadImage = Instance.new("ImageLabel")
                local ScriptSettings = Instance.new("ImageButton")
                local SettignsLuaFrame = Instance.new("Frame")
                local SettignsLuaFrameLayout = Instance.new("UIListLayout")
                local DeleteLua = Instance.new("ImageButton")
                local EditScript = Instance.new("ImageButton")
                local ShareScript = Instance.new("ImageButton")
    
                Script.Name = "Script"
                Script.Parent = LuaScriptFrame
                Script.BackgroundColor3 = Color3.fromRGB(4, 18, 36)
                Script.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Script.BorderSizePixel = 0
                Script.Position = UDim2.new(0, 0, 7.11365473e-08, 0)
                Script.Size = UDim2.new(0, 509, 0, 44)
                Script.AutoButtonColor = false
                Script.Font = Enum.Font.SourceSans
                Script.Text = ""
                Script.TextColor3 = Color3.fromRGB(0, 0, 0)
                Script.TextSize = 14.000
                
                local ScriptStroke = Instance.new("UIStroke")
        
                ScriptStroke.Color = Color3.fromRGB(4, 28, 44)
                ScriptStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                ScriptStroke.LineJoinMode = Enum.LineJoinMode.Round
                ScriptStroke.Thickness = 1
                ScriptStroke.Parent = Script
                
                ScriptCorner.Name = "ScriptCorner"
                ScriptCorner.Parent = Script
                
                ScriptTitle.Name = "ScriptTitle"
                ScriptTitle.Parent = Script
                ScriptTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ScriptTitle.BackgroundTransparency = 1.000
                ScriptTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ScriptTitle.BorderSizePixel = 0
                ScriptTitle.Position = UDim2.new(0.0308056865, 0, 0.240259692, 0)
                ScriptTitle.Size = UDim2.new(0, 61, 0, 21)
                ScriptTitle.Font = Enum.Font.GothamBold
                ScriptTitle.Text = file_name_without_extension
                ScriptTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                ScriptTitle.TextSize = 15.000
                ScriptTitle.TextXAlignment = Enum.TextXAlignment.Left
                
                LoadScript.Name = "LoadScript"
                LoadScript.Parent = Script
                LoadScript.BackgroundColor3 = Color3.fromRGB(3, 123, 182)
                LoadScript.BorderColor3 = Color3.fromRGB(0, 0, 0)
                LoadScript.Position = UDim2.new(0.824462891, 0, 0.159090906, 0)
                LoadScript.Size = UDim2.new(0, 82, 0, 30)
                LoadScript.AutoButtonColor = false
                LoadScript.Font = Enum.Font.SourceSans
                LoadScript.Text = ""
                LoadScript.TextColor3 = Color3.fromRGB(0, 0, 0)
                LoadScript.TextSize = 14.000
    
                LoadScript.MouseButton1Click:Connect(function()
                    
                    if LoadText.Text == "Load" then
                        getgenv().Lua = getgenv().LuaSection:Tab(file_name_without_extension)
                        local goo, bad = pcall(function()
                            wait(1)
                            loadfile(v)()
                        end)
                        Neverlose_Main:Notify({
                            Title = "Settings",
                            Text = file_name_without_extension.." loaded",
                            Time = 2,
                            AutoClose = true
                        })
                        if goo == false then
                            Neverlose_Main:Notify({
                                Title = "Settings",
                                Text = "Error: "..file_name_without_extension..bad,
                                Time = 2,
                                AutoClose = true
                            })
                            for i,v in pairs(TabHolder.Lua:GetChildren()) do
                                if v.Name == file_name_without_extension then
                                    v:Destroy()
                                end
                            end
                        end
                        LoadText.Text = "UnLoad"
                        LoadImage.Visible = false
                    else
                        -- ContainerHolder
                        for i,v in pairs(TabHolder.Lua:GetChildren()) do
                            if v.Name == file_name_without_extension then
                                v:Destroy()
                            end
                        end
    
                        for i,v in pairs(ContainerHolder:GetChildren()) do
                            if v.Name == file_name_without_extension then
                                v:Destroy()
                            end
                        end
                        Neverlose_Main:Notify({
                            Title = "Settings",
                            Text = file_name_without_extension.." Unloaded",
                            Time = 2,
                            AutoClose = true
                        })
                        LoadText.Text = "Load"
                        LoadImage.Visible = true
                    end
                end)
                
                LoadText.Name = "LoadText"
                LoadText.Parent = LoadScript
                LoadText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                LoadText.BackgroundTransparency = 1.000
                LoadText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                LoadText.BorderSizePixel = 0
                LoadText.Position = UDim2.new(0.434085011, 0, 0.233333334, 0)
                LoadText.Size = UDim2.new(0, 37, 0, 15)
                LoadText.Font = Enum.Font.GothamBold
                LoadText.Text = "Load"
                LoadText.TextColor3 = Color3.fromRGB(255, 255, 255)
                LoadText.TextSize = 14.000
                LoadText.TextXAlignment = Enum.TextXAlignment.Right
                
                LoadScriptCorner.CornerRadius = UDim.new(0, 5)
                LoadScriptCorner.Name = "LoadScriptCorner"
                LoadScriptCorner.Parent = LoadScript
                
                LoadImage.Name = "LoadImage"
                LoadImage.Parent = LoadScript
                LoadImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                LoadImage.BackgroundTransparency = 1.000
                LoadImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
                LoadImage.BorderSizePixel = 0
                LoadImage.Position = UDim2.new(0, 0, 0.100000001, 0)
                LoadImage.Size = UDim2.new(0, 30, 0, 23)
                LoadImage.Image = "http://www.roblox.com/asset/?id=6026663699"
                
                ScriptSettings.Name = "ScriptSettings"
                ScriptSettings.Parent = Script
                ScriptSettings.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ScriptSettings.BackgroundTransparency = 1.000
                ScriptSettings.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ScriptSettings.BorderSizePixel = 0
                ScriptSettings.Position = UDim2.new(0.768745601, 0, 0.295454532, 0)
                ScriptSettings.Size = UDim2.new(0, 18, 0, 18)
                ScriptSettings.Image = "http://www.roblox.com/asset/?id=6031280882"
                local ScriptSettignsToggled = false

                ScriptSettings.MouseButton1Click:Connect(function()
                    
                    ScriptSettignsToggled = not ScriptSettignsToggled
                    SettignsLuaFrame.Visible = ScriptSettignsToggled
                end)
                
                SettignsLuaFrame.Name = "SettignsLuaFrame"
                SettignsLuaFrame.Parent = Script
                SettignsLuaFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SettignsLuaFrame.BackgroundTransparency = 1.000
                SettignsLuaFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SettignsLuaFrame.BorderSizePixel = 0
                SettignsLuaFrame.Position = UDim2.new(0.267190576, 0, 0.181818187, 0)
                SettignsLuaFrame.Size = UDim2.new(0, 231, 0, 29)
                SettignsLuaFrame.Visible = false
                
                SettignsLuaFrameLayout.Name = "SettignsLuaFrameLayout"
                SettignsLuaFrameLayout.Parent = SettignsLuaFrame
                SettignsLuaFrameLayout.FillDirection = Enum.FillDirection.Horizontal
                SettignsLuaFrameLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                SettignsLuaFrameLayout.SortOrder = Enum.SortOrder.LayoutOrder
                SettignsLuaFrameLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                SettignsLuaFrameLayout.Padding = UDim.new(0, 13)
                
                DeleteLua.Name = "DeleteLua"
                DeleteLua.Parent = SettignsLuaFrame
                DeleteLua.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                DeleteLua.BackgroundTransparency = 1.000
                DeleteLua.BorderColor3 = Color3.fromRGB(0, 0, 0)
                DeleteLua.BorderSizePixel = 0
                DeleteLua.Position = UDim2.new(0.0216450226, 0, 0.103448279, 0)
                DeleteLua.Size = UDim2.new(0, 20, 0, 20)
                DeleteLua.Image = "http://www.roblox.com/asset/?id=6035067843"
                DeleteLua.ImageColor3 = Color3.fromRGB(255, 69, 72)
        
                DeleteLua.MouseButton1Click:Connect(function()
                    
                    Neverlose_Main:Notify({
                        Title = "Settings",
                        Text = "Deleted Script!",
                        Time = 2,
                        AutoClose = true
                    })
                    for i,v in pairs(TabHolder.Lua:GetChildren()) do
                        if v.Name == file_name_without_extension then
                            v:Destroy()
                        end
                    end

                    for i,v in pairs(ContainerHolder:GetChildren()) do
                        if v.Name == file_name_without_extension then
                            v:Destroy()
                        end
                    end
                    Neverlose_Main:Notify({
                        Title = "Settings",
                        Text = file_name_without_extension.." Unloaded",
                        Time = 2,
                        AutoClose = true
                    })
                    LoadText.Text = "Load"
                    LoadImage.Visible = true
                    delfile(v)
                    Script:Destroy()
                end)
                
                EditScript.Name = "EditScript"
                EditScript.Parent = SettignsLuaFrame
                EditScript.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                EditScript.BackgroundTransparency = 1.000
                EditScript.BorderColor3 = Color3.fromRGB(0, 0, 0)
                EditScript.BorderSizePixel = 0
                EditScript.Position = UDim2.new(0.0216450226, 0, 0.103448279, 0)
                EditScript.Size = UDim2.new(0, 20, 0, 20)
                EditScript.Image = "http://www.roblox.com/asset/?id=6034328955"
                EditScript.ImageColor3 = Color3.fromRGB(72, 133, 143)
        
                EditScript.MouseButton1Click:Connect(function()
                    
                    Neverlose_Main:Notify({
                        Title = "Settings",
                        Text = "Still in Testing!",
                        Time = 2,
                        AutoClose = true
                    })
                end)
                
                ShareScript.Name = "ShareScript"
                ShareScript.Parent = SettignsLuaFrame
                ShareScript.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ShareScript.BackgroundTransparency = 1.000
                ShareScript.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ShareScript.BorderSizePixel = 0
                ShareScript.Position = UDim2.new(0.0216450226, 0, 0.103448279, 0)
                ShareScript.Size = UDim2.new(0, 20, 0, 20)
                ShareScript.Image = "http://www.roblox.com/asset/?id=6034230648"
                ShareScript.ImageColor3 = Color3.fromRGB(72, 133, 143)
        
                ShareScript.MouseButton1Click:Connect(function()
                    
                    Neverlose_Main:Notify({
                        Title = "Settings",
                        Text = "Copied to clipboard!",
                        Time = 2,
                        AutoClose = true
                    })
                    local readedfile = readfile(v)
                    setclipboard(readedfile)
                end)
            end
    
        end)

        for i,v in pairs(ListScripts) do
            local file_path = v
            local file_name = string.match(file_path, "[^\\]*$")
            local file_name_without_extension = string.gsub(file_name, "%..*$", "")
    
            print(file_name_without_extension)

            local Script = Instance.new("TextButton")
            local ScriptCorner = Instance.new("UICorner")
            local ScriptTitle = Instance.new("TextLabel")
            local LoadScript = Instance.new("TextButton")
            local LoadText = Instance.new("TextLabel")
            local LoadScriptCorner = Instance.new("UICorner")
            local LoadImage = Instance.new("ImageLabel")
            local ScriptSettings = Instance.new("ImageButton")
            local SettignsLuaFrame = Instance.new("Frame")
            local SettignsLuaFrameLayout = Instance.new("UIListLayout")
            local DeleteLua = Instance.new("ImageButton")
            local EditScript = Instance.new("ImageButton")
            local ShareScript = Instance.new("ImageButton")

            Script.Name = "Script"
            Script.Parent = LuaScriptFrame
            Script.BackgroundColor3 = Color3.fromRGB(4, 18, 36)
            Script.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Script.BorderSizePixel = 0
            Script.Position = UDim2.new(0, 0, 7.11365473e-08, 0)
            Script.Size = UDim2.new(0, 509, 0, 44)
            Script.AutoButtonColor = false
            Script.Font = Enum.Font.SourceSans
            Script.Text = ""
            Script.TextColor3 = Color3.fromRGB(0, 0, 0)
            Script.TextSize = 14.000
            
            local ScriptStroke = Instance.new("UIStroke")
    
            ScriptStroke.Color = Color3.fromRGB(4, 28, 44)
            ScriptStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            ScriptStroke.LineJoinMode = Enum.LineJoinMode.Round
            ScriptStroke.Thickness = 1
            ScriptStroke.Parent = Script
            
            ScriptCorner.Name = "ScriptCorner"
            ScriptCorner.Parent = Script
            
            ScriptTitle.Name = "ScriptTitle"
            ScriptTitle.Parent = Script
            ScriptTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ScriptTitle.BackgroundTransparency = 1.000
            ScriptTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ScriptTitle.BorderSizePixel = 0
            ScriptTitle.Position = UDim2.new(0.0308056865, 0, 0.240259692, 0)
            ScriptTitle.Size = UDim2.new(0, 61, 0, 21)
            ScriptTitle.Font = Enum.Font.GothamBold
            ScriptTitle.Text = file_name_without_extension
            ScriptTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            ScriptTitle.TextSize = 15.000
            ScriptTitle.TextXAlignment = Enum.TextXAlignment.Left
            
            LoadScript.Name = "LoadScript"
            LoadScript.Parent = Script
            LoadScript.BackgroundColor3 = Color3.fromRGB(3, 123, 182)
            LoadScript.BorderColor3 = Color3.fromRGB(0, 0, 0)
            LoadScript.Position = UDim2.new(0.824462891, 0, 0.159090906, 0)
            LoadScript.Size = UDim2.new(0, 82, 0, 30)
            LoadScript.AutoButtonColor = false
            LoadScript.Font = Enum.Font.SourceSans
            LoadScript.Text = ""
            LoadScript.TextColor3 = Color3.fromRGB(0, 0, 0)
            LoadScript.TextSize = 14.000

            LoadScript.MouseButton1Click:Connect(function()
                
                if LoadText.Text == "Load" then
                    getgenv().Lua = getgenv().LuaSection:Tab(file_name_without_extension)
                    local goo, bad = pcall(function()
                        wait(1)
                        loadfile(v)()
                    end)
                    Neverlose_Main:Notify({
                        Title = "Settings",
                        Text = file_name_without_extension.." loaded",
                        Time = 2,
                        AutoClose = true
                    })
                    if goo == false then
                        Neverlose_Main:Notify({
                            Title = "Settings",
                            Text = "Error: "..file_name_without_extension..bad,
                            Time = 2,
                            AutoClose = true
                        })
                        for i,v in pairs(TabHolder.Lua:GetChildren()) do
                            if v.Name == file_name_without_extension then
                                v:Destroy()
                            end
                        end
                    end
                    LoadText.Text = "UnLoad"
                    LoadImage.Visible = false
                else
                    -- ContainerHolder
                    for i,v in pairs(TabHolder.Lua:GetChildren()) do
                        if v.Name == file_name_without_extension then
                            v:Destroy()
                        end
                    end

                    for i,v in pairs(ContainerHolder:GetChildren()) do
                        if v.Name == file_name_without_extension then
                            v:Destroy()
                        end
                    end
                    Neverlose_Main:Notify({
                        Title = "Settings",
                        Text = file_name_without_extension.." Unloaded",
                        Time = 2,
                        AutoClose = true
                    })
                    LoadText.Text = "Load"
                    LoadImage.Visible = true
                end
            end)
            
            LoadText.Name = "LoadText"
            LoadText.Parent = LoadScript
            LoadText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            LoadText.BackgroundTransparency = 1.000
            LoadText.BorderColor3 = Color3.fromRGB(0, 0, 0)
            LoadText.BorderSizePixel = 0
            LoadText.Position = UDim2.new(0.434085011, 0, 0.233333334, 0)
            LoadText.Size = UDim2.new(0, 37, 0, 15)
            LoadText.Font = Enum.Font.GothamBold
            LoadText.Text = "Load"
            LoadText.TextColor3 = Color3.fromRGB(255, 255, 255)
            LoadText.TextSize = 14.000
            LoadText.TextXAlignment = Enum.TextXAlignment.Right
            
            LoadScriptCorner.CornerRadius = UDim.new(0, 5)
            LoadScriptCorner.Name = "LoadScriptCorner"
            LoadScriptCorner.Parent = LoadScript
            
            LoadImage.Name = "LoadImage"
            LoadImage.Parent = LoadScript
            LoadImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            LoadImage.BackgroundTransparency = 1.000
            LoadImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
            LoadImage.BorderSizePixel = 0
            LoadImage.Position = UDim2.new(0, 0, 0.100000001, 0)
            LoadImage.Size = UDim2.new(0, 30, 0, 23)
            LoadImage.Image = "http://www.roblox.com/asset/?id=6026663699"
            
            ScriptSettings.Name = "ScriptSettings"
            ScriptSettings.Parent = Script
            ScriptSettings.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ScriptSettings.BackgroundTransparency = 1.000
            ScriptSettings.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ScriptSettings.BorderSizePixel = 0
            ScriptSettings.Position = UDim2.new(0.768745601, 0, 0.295454532, 0)
            ScriptSettings.Size = UDim2.new(0, 18, 0, 18)
            ScriptSettings.Image = "http://www.roblox.com/asset/?id=6031280882"

            local ScriptSettignsToggled = false

            ScriptSettings.MouseButton1Click:Connect(function()
                
                ScriptSettignsToggled = not ScriptSettignsToggled
                SettignsLuaFrame.Visible = ScriptSettignsToggled
            end)
            
            SettignsLuaFrame.Name = "SettignsLuaFrame"
            SettignsLuaFrame.Parent = Script
            SettignsLuaFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SettignsLuaFrame.BackgroundTransparency = 1.000
            SettignsLuaFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
            SettignsLuaFrame.BorderSizePixel = 0
            SettignsLuaFrame.Position = UDim2.new(0.267190576, 0, 0.181818187, 0)
            SettignsLuaFrame.Size = UDim2.new(0, 231, 0, 29)
            SettignsLuaFrame.Visible = false
            
            SettignsLuaFrameLayout.Name = "SettignsLuaFrameLayout"
            SettignsLuaFrameLayout.Parent = SettignsLuaFrame
            SettignsLuaFrameLayout.FillDirection = Enum.FillDirection.Horizontal
            SettignsLuaFrameLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            SettignsLuaFrameLayout.SortOrder = Enum.SortOrder.LayoutOrder
            SettignsLuaFrameLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            SettignsLuaFrameLayout.Padding = UDim.new(0, 13)
            
            DeleteLua.Name = "DeleteLua"
            DeleteLua.Parent = SettignsLuaFrame
            DeleteLua.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            DeleteLua.BackgroundTransparency = 1.000
            DeleteLua.BorderColor3 = Color3.fromRGB(0, 0, 0)
            DeleteLua.BorderSizePixel = 0
            DeleteLua.Position = UDim2.new(0.0216450226, 0, 0.103448279, 0)
            DeleteLua.Size = UDim2.new(0, 20, 0, 20)
            DeleteLua.Image = "http://www.roblox.com/asset/?id=6035067843"
            DeleteLua.ImageColor3 = Color3.fromRGB(255, 69, 72)
    
            DeleteLua.MouseButton1Click:Connect(function()
                
                Neverlose_Main:Notify({
                    Title = "Settings",
                    Text = "Deleted Script!",
                    Time = 2,
                    AutoClose = true
                })
                
                for i,v in pairs(TabHolder.Lua:GetChildren()) do
                    if v.Name == file_name_without_extension then
                        v:Destroy()
                    end
                end

                for i,v in pairs(ContainerHolder:GetChildren()) do
                    if v.Name == file_name_without_extension then
                        v:Destroy()
                    end
                end
                Neverlose_Main:Notify({
                    Title = "Settings",
                    Text = file_name_without_extension.." Unloaded",
                    Time = 2,
                    AutoClose = true
                })
                
                delfile(v)
                Script:Destroy()
            end)
            
            EditScript.Name = "EditScript"
            EditScript.Parent = SettignsLuaFrame
            EditScript.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            EditScript.BackgroundTransparency = 1.000
            EditScript.BorderColor3 = Color3.fromRGB(0, 0, 0)
            EditScript.BorderSizePixel = 0
            EditScript.Position = UDim2.new(0.0216450226, 0, 0.103448279, 0)
            EditScript.Size = UDim2.new(0, 20, 0, 20)
            EditScript.Image = "http://www.roblox.com/asset/?id=6034328955"
            EditScript.ImageColor3 = Color3.fromRGB(72, 133, 143)
    
            EditScript.MouseButton1Click:Connect(function()
                
                Neverlose_Main:Notify({
                    Title = "Settings",
                    Text = "Still in Testing!",
                    Time = 2,
                    AutoClose = true
                })
            end)
            
            ShareScript.Name = "ShareScript"
            ShareScript.Parent = SettignsLuaFrame
            ShareScript.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ShareScript.BackgroundTransparency = 1.000
            ShareScript.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ShareScript.BorderSizePixel = 0
            ShareScript.Position = UDim2.new(0.0216450226, 0, 0.103448279, 0)
            ShareScript.Size = UDim2.new(0, 20, 0, 20)
            ShareScript.Image = "http://www.roblox.com/asset/?id=6034230648"
            ShareScript.ImageColor3 = Color3.fromRGB(72, 133, 143)
    
            ShareScript.MouseButton1Click:Connect(function()
                
                Neverlose_Main:Notify({
                    Title = "Settings",
                    Text = "Copied to clipboard!",
                    Time = 2,
                    AutoClose = true
                })
                local readedfile = readfile(v)
                setclipboard(readedfile)
            end)
            ShareScript.MouseEnter:Connect(function()
                Neverlose_Main:PlaySound(Neverlose_Main.Lib_Sounds.HoverSound)
            end)
        end
        
        LuaScriptFramePadding.Name = "LuaScriptFramePadding"
        LuaScriptFramePadding.Parent = LuaScriptFrame
        LuaScriptFramePadding.PaddingLeft = UDim.new(0, 5)
        LuaScriptFramePadding.PaddingTop = UDim.new(0, 5)




        local ChatFrame = Instance.new("Frame")
        local ChatFrameCorner = Instance.new("UICorner")
        local ChatTitle = Instance.new("TextLabel")
        local ChatFrameLine = Instance.new("Frame")
        local ChatFrameLine2 = Instance.new("Frame")
        local CloseChatFrame = Instance.new("TextButton")
        local ChatFrameFrame = Instance.new("ScrollingFrame")
        local ChatFrameLayout = Instance.new("UIListLayout")
        local ChatFramePadding = Instance.new("UIPadding")

        local ClearChat = Instance.new("ImageButton")
        local ChatBoxText = Instance.new("TextBox")
        local ChatBoxTextCorner = Instance.new("UICorner")
        local ChatBoxTextPadding = Instance.new("UIPadding")

        local SendChatButton = Instance.new("ImageButton")
        local ChatFrameLine_2 = Instance.new("Frame")

        ChatButton.Visible = true
        
        ChatButton.MouseButton1Click:Connect(function()
            
            ChatFrame.Visible = false
            -- SettingsFrame.Visible = false
            -- SettingsToggled = false
            Neverlose_Main:Notify({
                Title = "Neverlose",
                Text = "Feature Temporarily Disabled!"
            })
        end)
        
        ChatFrame.Name = "ChatFrame"
        ChatFrame.Parent = MainFrame
        ChatFrame.BackgroundColor3 = Color3.fromRGB(15, 19, 21)
        ChatFrame.BackgroundTransparency = 0.050
        ChatFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ChatFrame.BorderSizePixel = 0
        ChatFrame.Position = UDim2.new(1.09486794, 0, 0.171554208, 0)
        ChatFrame.Size = UDim2.new(0, 540, 0, 447)
        ChatFrame.Visible = false
        MakeDraggable(ChatFrame, ChatFrame)
        
        ChatFrameCorner.CornerRadius = UDim.new(0, 4)
        ChatFrameCorner.Name = "ChatFrameCorner"
        ChatFrameCorner.Parent = ChatFrame
        
        ChatTitle.Name = "ChatTitle"
        ChatTitle.Parent = ChatFrame
        ChatTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ChatTitle.BackgroundTransparency = 1.000
        ChatTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ChatTitle.BorderSizePixel = 0
        ChatTitle.Position = UDim2.new(0.270148396, 0, -0.000112343594, 0)
        ChatTitle.Size = UDim2.new(0, 248, 0, 67)
        ChatTitle.Font = Enum.Font.FredokaOne
        ChatTitle.Text = "CHATTING"
        ChatTitle.TextColor3 = Color3.fromRGB(239, 248, 246)
        ChatTitle.TextSize = 45.000
        ChatTitle.TextStrokeColor3 = Color3.fromRGB(103, 181, 191)
        
        ChatFrameLine.Name = "ChatFrameLine"
        ChatFrameLine.Parent = ChatFrame
        ChatFrameLine.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
        ChatFrameLine.BackgroundTransparency = 0.800
        ChatFrameLine.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ChatFrameLine.BorderSizePixel = 0
        ChatFrameLine.Position = UDim2.new(0, 0, 0.136003897, 0)
        ChatFrameLine.Size = UDim2.new(1, 0, 0, 1)
        
        ChatFrameLine2.Name = "ChatFrameLine2"
        ChatFrameLine2.Parent = ChatFrame
        ChatFrameLine2.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
        ChatFrameLine2.BackgroundTransparency = 1.000
        ChatFrameLine2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ChatFrameLine2.BorderSizePixel = 0
        ChatFrameLine2.Position = UDim2.new(0, 0, 0.809246898, 0)
        ChatFrameLine2.Size = UDim2.new(1, 0, 0, 1)
        
        CloseChatFrame.Name = "CloseChatFrame"
        CloseChatFrame.Parent = ChatFrame
        CloseChatFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        CloseChatFrame.BackgroundTransparency = 1.000
        CloseChatFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        CloseChatFrame.BorderSizePixel = 0
        CloseChatFrame.Position = UDim2.new(0.944993913, 0, -0.00995453913, 0)
        CloseChatFrame.Size = UDim2.new(0, 35, 0, 36)
        CloseChatFrame.AutoButtonColor = false
        CloseChatFrame.Font = Enum.Font.GothamBold
        CloseChatFrame.Text = "x"
        CloseChatFrame.TextColor3 = Color3.fromRGB(99, 161, 174)
        CloseChatFrame.TextSize = 20.000

        CloseChatFrame.MouseButton1Click:Connect(function()
            
            ChatFrame.Visible = false
        end)
        
        ChatFrameFrame.Name = "ChatFrameFrame"
        ChatFrameFrame.Parent = ChatFrame
        ChatFrameFrame.Active = true
        ChatFrameFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ChatFrameFrame.BackgroundTransparency = 1.000
        ChatFrameFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ChatFrameFrame.BorderSizePixel = 0
        ChatFrameFrame.Position = UDim2.new(0.0229357686, 0, 0.164772734, 0)
        ChatFrameFrame.Size = UDim2.new(0, 521, 0, 292)
        ChatFrameFrame.ScrollBarThickness = 0
        
        ChatFrameLayout.Name = "ChatFrameLayout"
        ChatFrameLayout.Parent = ChatFrameFrame
        ChatFrameLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ChatFrameLayout.Padding = UDim.new(0, 15)
        
        ChatFramePadding.Name = "ChatFramePadding"
        ChatFramePadding.Parent = ChatFrameFrame
        ChatFramePadding.PaddingLeft = UDim.new(0, 5)
        ChatFramePadding.PaddingTop = UDim.new(0, 10)

        getgenv().processedMessages = {}

        -- local loop = coroutine.create(function()
        --     while wait(math.random(1, 2)) do
        --         local data = req({
        --             Url = "https://chatting.madsbrriinckbas.repl.co/api/poll/",
        --             Method = "GET"
        --         })
        --         local data = Neverlose_Main.HttpService:JSONDecode(data.Body)
        --         for i,v in pairs(data.messages) do
        --             if not getgenv().processedMessages[v.uid] then
        --                 getgenv().processedMessages[v.uid] = true -- Mark the message as processed

        --                 local ChatSocketFrame = Instance.new("Frame")
        --                 local ChatText = Instance.new("TextLabel")
        --                 local ChatSocketFrameCorner = Instance.new("UICorner")
        --                 local NameText = Instance.new("TextLabel")
        --                 local NameTextCorner = Instance.new("UICorner")

        --                 ChatSocketFrame.Name = "ChatSocketFrame"
        --                 ChatSocketFrame.Parent = ChatFrameFrame --game:GetService("CoreGui").Neverlose1.MainFrame.ChatFrame.ChatFrameFrame
        --                 ChatSocketFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        --                 ChatSocketFrame.BackgroundTransparency = 1.000
        --                 ChatSocketFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        --                 ChatSocketFrame.BorderSizePixel = 0
        --                 ChatSocketFrame.Position = UDim2.new(0, 0, -1.08218359e-07, 0)
        --                 ChatSocketFrame.Size = UDim2.new(0, 407, 0, 35)

        --                 local ChatSocketFrameStroke = Instance.new("UIStroke")
        
        --                 ChatSocketFrameStroke.Color = Color3.fromRGB(82, 147, 155)
        --                 ChatSocketFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        --                 ChatSocketFrameStroke.LineJoinMode = Enum.LineJoinMode.Round
        --                 ChatSocketFrameStroke.Thickness = 1
        --                 ChatSocketFrameStroke.Parent = ChatSocketFrame
        --                 ChatSocketFrameStroke.Transparency = 0.35

        --                 ChatText.Name = "ChatText"
        --                 ChatText.Parent = ChatSocketFrame
        --                 ChatText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        --                 ChatText.BackgroundTransparency = 1.000
        --                 ChatText.BorderColor3 = Color3.fromRGB(0, 0, 0)
        --                 ChatText.BorderSizePixel = 0
        --                 ChatText.Position = UDim2.new(0.0270270277, 0, 0.297147036, 0)
        --                 ChatText.Size = UDim2.new(0, 41, 0, 16)
        --                 ChatText.Font = Enum.Font.Gotham
        --                 ChatText.Text = tostring(v.msg)
        --                 ChatText.TextColor3 = Color3.fromRGB(255, 255, 255)
        --                 ChatText.TextSize = 14.000
        --                 ChatText.TextXAlignment = Enum.TextXAlignment.Left
        --                 ChatText.RichText = true
                        
        --                 ChatSocketFrameCorner.CornerRadius = UDim.new(0, 3)
        --                 ChatSocketFrameCorner.Name = "ChatSocketFrameCorner"
        --                 ChatSocketFrameCorner.Parent = ChatSocketFrame

        --                 NameText.Name = "NameText"
        --                 NameText.Parent = ChatSocketFrame
        --                 NameText.BackgroundColor3 = Color3.fromRGB(14, 14, 21)
        --                 NameText.BorderColor3 = Color3.fromRGB(0, 0, 0)
        --                 NameText.BorderSizePixel = 0
        --                 NameText.Position = UDim2.new(0.0489999838, 0, -0.229999647, 0)
        --                 NameText.Size = UDim2.new(0, 66, 0, 14)
        --                 NameText.Font = Enum.Font.SourceSans
        --                 NameText.TextColor3 = Color3.fromRGB(255, 255, 255)
        --                 NameText.TextSize = 14.000
        --                 NameText.RichText = true

        --                 if Player.UserId == 2254026356 then
        --                     NameText.Text = "<font color='rgb(255,60,60)'>"..Player.Name.."</font>"
        --                 else
        --                     NameText.Text = "<font color='rgb(60,60,255)'>"..Player.Name.."</font>"
        --                 end

        --                 NameText.Size = UDim2.new(0, NameText.TextBounds.X + 20, 0, 14)

        --                 local NameTextStroke = Instance.new("UIStroke")
        
        --                 NameTextStroke.Color = Color3.fromRGB(82, 147, 155)
        --                 NameTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        --                 NameTextStroke.LineJoinMode = Enum.LineJoinMode.Round
        --                 NameTextStroke.Thickness = 1
        --                 NameTextStroke.Parent = NameText
        --                 NameTextStroke.Transparency = 0.35
                        
        --                 NameTextCorner.Name = "NameTextCorner"
        --                 NameTextCorner.Parent = NameText

        --                 ChatFrameFrame.CanvasSize = UDim2.new(0, 0, 0, ChatFrameLayout.AbsoluteContentSize.Y + 30)
        --             end
        --         end
        --     end
        -- end)
        -- coroutine.resume(loop)
        
        ClearChat.Name = "ClearChat"
        ClearChat.Parent = ChatFrame
        ClearChat.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ClearChat.BackgroundTransparency = 1.000
        ClearChat.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ClearChat.BorderSizePixel = 0
        ClearChat.Position = UDim2.new(0.898000002, 0, 0.00499999989, 0)
        ClearChat.Size = UDim2.new(0, 25, 0, 25)
        ClearChat.Image = "http://www.roblox.com/asset/?id=6035181870"
        ClearChat.ImageColor3 = Color3.fromRGB(99, 161, 174)

        ClearChat.MouseButton1Click:Connect(function()
            
            for i,v in pairs(ChatFrameFrame:GetChildren()) do
                if v:IsA("Frame") then
                    v:Destroy()
                end
            end
        end)
        
        ChatBoxText.Name = "ChatBoxText"
        ChatBoxText.Parent = ChatFrame
        ChatBoxText.BackgroundColor3 = Color3.fromRGB(15, 40, 66)
        ChatBoxText.BackgroundTransparency = 0.300
        ChatBoxText.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ChatBoxText.BorderSizePixel = 0
        ChatBoxText.Position = UDim2.new(0.129629627, 0, 0.86577183, 0)
        ChatBoxText.Size = UDim2.new(0, 405, 0, 38)
        ChatBoxText.ClearTextOnFocus = false
        ChatBoxText.Font = Enum.Font.Gotham
        ChatBoxText.Text = ""
        ChatBoxText.TextColor3 = Color3.fromRGB(255, 255, 255)
        ChatBoxText.TextSize = 14.000
        ChatBoxText.TextXAlignment = Enum.TextXAlignment.Left

        ChatBoxText.FocusLost:Connect(function(ep)
            if ep then
                local Data = Neverlose_Main.HttpService:JSONEncode({
                    msg = ChatBoxText.Text
                })
                if req then req({
                    Url = "https://chatting.madsbrriinckbas.repl.co/api/send/",
                    Method = 'POST',
                    Body = Data,
                    Headers = {
                        ['Content-Type'] = 'application/json'
                    }
                }) end
                ChatBoxText.Text = ""
            end
        end)
        
        ChatBoxTextCorner.CornerRadius = UDim.new(0, 5)
        ChatBoxTextCorner.Name = "ChatBoxTextCorner"
        ChatBoxTextCorner.Parent = ChatBoxText

        ChatBoxTextPadding.Name = "ChatBoxTextPadding"
        ChatBoxTextPadding.Parent = ChatBoxText
        ChatBoxTextPadding.PaddingLeft = UDim.new(0, 12)
        
        SendChatButton.Name = "SendChatButton"
        SendChatButton.Parent = ChatBoxText
        SendChatButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SendChatButton.BackgroundTransparency = 1.000
        SendChatButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
        SendChatButton.BorderSizePixel = 0
        SendChatButton.Position = UDim2.new(0.925999999, 0, 0.163000003, 0)
        SendChatButton.Size = UDim2.new(0, 25, 0, 25)
        SendChatButton.Image = "http://www.roblox.com/asset/?id=6035067832"
        SendChatButton.ImageColor3 = Color3.fromRGB(99, 161, 174)

        SendChatButton.MouseButton1Click:Connect(function()
            
            local Data = Neverlose_Main.HttpService:JSONEncode({
                msg = ChatBoxText.Text
            })
            if req then req({
                Url = "https://chatting.madsbrriinckbas.repl.co/api/send/",
                Method = 'POST',
                Body = Data,
                Headers = {
                    ['Content-Type'] = 'application/json'
                }
            }) end
            ChatBoxText.Text = ""
        end)
        
        ChatFrameLine_2.Name = "ChatFrameLine"
        ChatFrameLine_2.Parent = ChatFrame
        ChatFrameLine_2.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
        ChatFrameLine_2.BackgroundTransparency = 0.800
        ChatFrameLine_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ChatFrameLine_2.BorderSizePixel = 0
        ChatFrameLine_2.Position = UDim2.new(-0.00185185182, 0, 0.818330586, 0)
        ChatFrameLine_2.Size = UDim2.new(1, 0, 0, 1)

        -- Offline host: no automatic RPC or invite requests.

    local TabsSec = {}
    function TabsSec:TSection(title)
        local TabsSection = Instance.new("Frame")
        local TabsSectionStarterFrame = Instance.new("Frame")
        local TabSectionTitle = Instance.new("TextLabel")
        local TabsSectionLayout = Instance.new("UIListLayout")

        TabsSection.Name = title
        TabsSection.Parent = TabHolder
        TabsSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabsSection.BackgroundTransparency = 1.000
        TabsSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TabsSection.BorderSizePixel = 0
        TabsSection.Position = UDim2.new(0.0793650821, 0, 0.0337711051, 0)
        TabsSection.Size = UDim2.new(1, 0, 0.198874295, 20)
        
        TabsSectionStarterFrame.Name = "TabsSectionStarterFrame"
        TabsSectionStarterFrame.Parent = TabsSection
        TabsSectionStarterFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabsSectionStarterFrame.BackgroundTransparency = 1.000
        TabsSectionStarterFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TabsSectionStarterFrame.BorderSizePixel = 0
        TabsSectionStarterFrame.Position = UDim2.new(-0.0767195746, 0, 0.137891337, 0)
        TabsSectionStarterFrame.Size = UDim2.new(0, 159, 0, 28)
        
        TabSectionTitle.Name = "TabSectionTitle"
        TabSectionTitle.Parent = TabsSectionStarterFrame
        TabSectionTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabSectionTitle.BackgroundTransparency = 1.000
        TabSectionTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TabSectionTitle.BorderSizePixel = 0
        TabSectionTitle.Position = UDim2.new(-0.0404311828, 0, 0.229113445, 0)
        TabSectionTitle.Size = UDim2.new(0, 150, 0, 17)
        TabSectionTitle.Font = Enum.Font.Gotham
        TabSectionTitle.Text = title
        TabSectionTitle.TextColor3 = Color3.fromRGB(44, 62, 75)
        TabSectionTitle.TextSize = 12.000
        TabSectionTitle.TextXAlignment = Enum.TextXAlignment.Left
        
        TabsSectionLayout.Name = "TabsSectionLayout"
        TabsSectionLayout.Parent = TabsSection
        TabsSectionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        TabsSectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
        TabsSectionLayout.Padding = UDim.new(0, 4)

        -- function Neverlose_Main:LoadCfg(cfg)
        --     local Encoded = readfile(Folder1 .. "/configs/" .. cfg .. ".txt")
        --     local Decoded = Neverlose_Main:decode(Encoded)
            
        --     local Encode = Neverlose_Main.HttpService:JSONEncode(Decoded)

        --     writefile(Folder1.."/configs/"..cfg..".txt", Encode)
        --     local content = readfile(Folder1.."/configs/"..cfg..".txt")
    
        --     table.foreach(content, function(a,b)
        --         print(a,b)
        --     if Neverlose_Main.Flags[a] then
        --         spawn(function()
        --           Neverlose_Main.Flags[a]:Set(b)
        --        end)
        --     else
        --         warn("Error ", a,b)
        --     end
        -- end)
        -- end
        
        -- function Neverlose_Main:SaveCfg(cfg)
        --     local content = {}
        --     for i,v in pairs(Neverlose_Main.Flags) do
        --         content[i] = v.Value
        --     end
        --     writefile(Folder1.."/configs/"..cfg..".txt", Neverlose_Main:encode(tostring(Neverlose_Main.HttpService:JSONEncode(content)))) -- FolderName.."/configs/"..name..".cfg"
        -- end
      
        -- function Neverlose_Main:CreateCfg(cfg)
        --     local content = {}
        --     for i,v in pairs(Neverlose_Main.Flags) do
        --         content[i] = v.Value
        --     end
        --     writefile(Folder1.."/configs/"..cfg..".txt", Neverlose_Main:encode(Neverlose_Main.HttpService:JSONEncode(content))) -- FolderName.."/configs/"..name..".cfg"
        --     -- writefile("Neverlose/configs/Mana64.txt", Neverlose_Main:encode(tostring(content)))
        -- end

        function Neverlose_Main:LoadCfg(cfg)
            local Encoded = readfile(Folder1 .. "/configs/" .. cfg .. ".txt")

            local JSONData = Neverlose_Main.HttpService:JSONDecode(Neverlose_Main:decode(Encoded))
            
            table.foreach(JSONData, function(a,b)
                if Neverlose_Main.Flags[a] then
                    spawn(function()
                        Neverlose_Main.Flags[a]:Set(b)
                    end)
                else
                    warn("Error ", a, b)
                end
            end)
        end
        
        function Neverlose_Main:SaveCfg(cfg)
            local content = {}
            for i, v in pairs(Neverlose_Main.Flags) do
                content[i] = v.Value
            end

            local Encoded = Neverlose_Main:encode(Neverlose_Main.HttpService:JSONEncode(content))
            
            writefile(Folder1 .. "/configs/" .. cfg .. ".txt", Encoded)
        end

        function Neverlose_Main:Edit_LastLoad(cfg)
            writefile(Folder1.."/LastLoaded.txt", Neverlose_Main.HttpService:JSONEncode({["CFG"] = tostring(cfg)}))
        end

        function Neverlose_Main:LastConfigSaved()
            if isfile(Folder1.."/LastLoaded.txt") then
                return Neverlose_Main.HttpService:JSONDecode(readfile(Folder1.."/LastLoaded.txt")).CFG
            else
                Neverlose_Main:Notify({Title = "Neverlose",
                    Text = 'Please Save a config first!',
                    Time = 2,
                    AutoClose = true
                })
            end
        end
        
        function Neverlose_Main:CreateCfg(cfg)
            local content = {}
            for i, v in pairs(Neverlose_Main.Flags) do
                content[i] = v.Value
            end
            
            local Encoded = Neverlose_Main.HttpService:JSONEncode(content) -- Convert to JSON string
            
            writefile(Folder1 .. "/configs/" .. cfg .. ".txt", Encoded)
        end
        
        SaveCFGB.MouseButton1Click:Connect(function()
            if Neverlose_Main.Targeted_Config == "" then
                Neverlose_Main:Notify({Title = "Neverlose",
                    Text = 'Please Select a config first!',
                    Time = 2,
                    AutoClose = true
                })
            else
                Neverlose_Main:Notify({Title = "Neverlose",
                    Text = "Saved to: "..tostring(Neverlose_Main.Targeted_Config),
                    Time = 2,
                    AutoClose = true
                })
                Neverlose_Main:SaveCfg(tostring(Neverlose_Main.Targeted_Config))
                Edit_LastLoad(tostring(Neverlose_Main.Targeted_Config))
            end
        end)

        SaveCFGB.MouseEnter:Connect(function()
            TweenService:Create(
                SaveCFGStroke,
                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                {Transparency = 0}
            ):Play()
        end)

        SaveCFGB.MouseLeave:Connect(function()
            TweenService:Create(
                SaveCFGStroke,
                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                {Transparency = 0.8}
            ):Play()
        end)

        local Tabs = {}
        function Tabs:Tab(title, iconAsset)
            local Tab = Instance.new("TextButton")
            local TabCorner = Instance.new("UICorner")
            local TabTitle = Instance.new("TextLabel")
            local Container = Instance.new("ScrollingFrame")
            local SectionHolder1 = Instance.new("Frame")
            local SectionHolder1Layout = Instance.new("UIListLayout")

            local SectionHolder2 = Instance.new("Frame")
            local SectionHolder2Layout = Instance.new("UIListLayout")

            Tab.Name = title
            Tab.Parent = TabsSection
            Tab.BackgroundColor3 = Color3.fromRGB(43, 69, 75)
            Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Tab.BorderSizePixel = 0
            Tab.Position = UDim2.new(0.0793650821, 0, 0, 0)
            Tab.Size = UDim2.new(0, 159, 0, 26)
            Tab.AutoButtonColor = false
            Tab.Font = Enum.Font.SourceSans
            Tab.Text = ""
            Tab.TextColor3 = Color3.fromRGB(180,180,180)
            Tab.TextSize = 14.000
            Tab.BackgroundTransparency = 1
            
            TabCorner.Name = "TabCorner"
            TabCorner.Parent = Tab
            TabCorner.CornerRadius = UDim.new(0, 4)
            
            TabTitle.Name = "TabTitle"
            TabTitle.Parent = Tab
            TabTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TabTitle.BackgroundTransparency = 1.000
            TabTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TabTitle.BorderSizePixel = 0
            TabTitle.Position = UDim2.new(0.0880503133, 0, 0.214285716, 0)
            TabTitle.Size = UDim2.new(0, 56, 0, 15)
            TabTitle.Font = Enum.Font.Gotham
            TabTitle.Text = title
            TabTitle.Position = UDim2.fromOffset(35, 5)
            TabTitle.Size = UDim2.fromOffset(120, 19)
            TabTitle.TextTruncate = Enum.TextTruncate.AtEnd
            TabTitle.TextSize = 14
            -- R228: native icon assets from the original Neverlose library set.
            local TabIcon = Instance.new("ImageLabel")
            TabIcon.Name = "TabIcon"
            TabIcon.BackgroundTransparency = 1
            TabIcon.Size = UDim2.fromOffset(16, 16)
            TabIcon.Position = UDim2.fromOffset(12, 5)
            TabIcon.Image = iconAsset or "rbxassetid://6031280882"
            TabIcon.ImageColor3 = Color3.fromRGB(146, 171, 178)
            TabIcon.Parent = Tab
            TabTitle.TextColor3 = Color3.fromRGB(180,180,180)
            TabTitle.TextSize = 14.000
            TabTitle.TextXAlignment = Enum.TextXAlignment.Left

            Container.Name = title
            Container.Parent = ContainerHolder
            Container.Active = true
            Container.ScrollingEnabled = true
            Container.ScrollBarThickness = 5
            Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Container.BackgroundTransparency = 1.000
            Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Container.BorderSizePixel = 0
            Container.Position = UDim2.new(0.0104251858, 0, 0.0230326876, 0)
            Container.Size = UDim2.new(0, 630, 0, 580)
            Container.ScrollBarThickness = 3
            Container.Visible = false

            SectionHolder1.Name = "SectionHolder1"
            SectionHolder1.Parent = Container
            SectionHolder1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SectionHolder1.BackgroundTransparency = 1.000
            SectionHolder1.BorderColor3 = Color3.fromRGB(0, 0, 0)
            SectionHolder1.BorderSizePixel = 0
            SectionHolder1.Position = UDim2.new(0.0167946946, 0, 0, 0)
            SectionHolder1.Size = UDim2.new(1, 0, 0, 580)
            
            SectionHolder1Layout.Name = "SectionHolder1Layout"
            SectionHolder1Layout.Parent = SectionHolder1
            SectionHolder1Layout.SortOrder = Enum.SortOrder.LayoutOrder
            SectionHolder1Layout.Padding = UDim.new(0, 9)

            
            SectionHolder2.Name = "SectionHolder2"
            SectionHolder2.Parent = Container
            SectionHolder2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SectionHolder2.BackgroundTransparency = 1.000
            SectionHolder2.BorderColor3 = Color3.fromRGB(0, 0, 0)
            SectionHolder2.BorderSizePixel = 0
            SectionHolder2.Position = UDim2.new(0.496638328, 0, -0.00172413792, 0)
            SectionHolder2.Size = UDim2.new(1, 0, 0, 580)
            
            SectionHolder2Layout.Name = "SectionHolder2Layout"
            SectionHolder2Layout.Parent = SectionHolder2
            SectionHolder2Layout.SortOrder = Enum.SortOrder.LayoutOrder
            SectionHolder2Layout.Padding = UDim.new(0, 9)

            -- R228: the two native columns stay intact; expanded popovers get
            -- their own scroll clearance rather than permanently bloating content.
            local openPopupExtra = 0
            local function syncNativeCanvas()
                local height=math.max(SectionHolder1Layout.AbsoluteContentSize.Y,
                    SectionHolder2Layout.AbsoluteContentSize.Y) + 28 + openPopupExtra
                Container.CanvasSize=UDim2.fromOffset(0,math.max(580,math.ceil(height)))
            end
            SectionHolder1Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncNativeCanvas)
            SectionHolder2Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncNativeCanvas)

            if FirstTab == false then
                Tab.BackgroundTransparency = 0.500
                TabTitle.TextColor3 = Color3.fromRGB(242, 248, 249)
                TabIcon.ImageColor3 = Neverlose_Main.Theme.Custom.Element
                Container.Visible = true
                FirstTab = true
            end

            Tab.MouseButton1Click:Connect(function()
                Neverlose_Main:PlaySound(Neverlose_Main.Lib_Sounds.ClickSound)
                for i,v in pairs(ContainerHolder:GetChildren()) do
                    if v:IsA("ScrollingFrame") then
                        v.Visible = false
                    end
                end
                for _, group in ipairs(TabHolder:GetChildren()) do
                    if group:IsA("Frame") then
                        for _, other in ipairs(group:GetChildren()) do
                            if other:IsA("TextButton") and other:FindFirstChild("TabTitle") then
                                local active = other == Tab
                                other.BackgroundTransparency = active and 0.5 or 1
                                other.TabTitle.TextColor3 = active
                                    and Color3.fromRGB(242,248,249) or Color3.fromRGB(163,176,180)
                                local ico = other:FindFirstChild("TabIcon")
                                if ico then ico.ImageColor3 = active
                                    and Neverlose_Main.Theme.Custom.Element or Color3.fromRGB(133,155,161) end
                            end
                        end
                    end
                end
                Container.Visible = true
            end)
            
            SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
                if not UserInputService:GetFocusedTextBox() then return end
                    for i,v in pairs(Container:GetChildren()) do
                        if v:IsA("Frame") then
                            for i,v in pairs(v:GetChildren()) do
                                for i,v in pairs(v:GetChildren()) do
                                if v:IsA("TextButton") then
                                    local Search_String = string.lower(SearchBar.Text)
                                    if string.find(string.lower(v.Name), Search_String) then
                                        v.Visible = true
                                    else
                                        v.Visible = false
                                    end
                                    if SearchBar.Text == "" or SearchBar.Text == " " then
                                        v.Visible = true
                                    end
                                end
                                end
                            end
                        end
                    end
            end)
            
            TabsSection.Size = UDim2.new(1, 0, 0, TabsSectionLayout.AbsoluteContentSize.Y)

            local Sections = {}
            function Sections:Select()
                for _, panel in ipairs(ContainerHolder:GetChildren()) do
                    if panel:IsA("ScrollingFrame") then panel.Visible = (panel == Container) end
                end
                for _, group in ipairs(TabHolder:GetChildren()) do
                    if group:IsA("Frame") then
                        for _, other in ipairs(group:GetChildren()) do
                            if other:IsA("TextButton") and other:FindFirstChild("TabTitle") then
                                local active = other == Tab
                                other.BackgroundTransparency = active and 0.5 or 1
                                other.TabTitle.TextColor3 = active
                                    and Color3.fromRGB(242,248,249) or Color3.fromRGB(163,176,180)
                                local ico = other:FindFirstChild("TabIcon")
                                if ico then ico.ImageColor3 = active
                                    and Neverlose_Main.Theme.Custom.Element or Color3.fromRGB(133,155,161) end
                            end
                        end
                    end
                end
            end

            local UniNum = 38
            local nativeSectionCount = 0

            function Sections:Section(title)
                local Section = Instance.new("Frame")
                local SecHolder = Instance.new("Frame")
                local SectionTitle = Instance.new("TextLabel")
                local SectionLine = Instance.new("Frame")
                local SectionLayout = Instance.new("UIListLayout")
                local SectionCorner = Instance.new("UICorner")

                

                Section.Name = "Section"
                Section.BackgroundColor3 = Color3.fromRGB(23, 29, 32)
                Section.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Section.BorderSizePixel = 0
                Section.Position = UDim2.new(0.262390673, 0, 0.0040485831, 0)
                Section.Size = UDim2.new(0, 285, 0, 200)

                SecHolder.Name = "SecHolder"
                SecHolder.Parent = Section
                SecHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SecHolder.BackgroundTransparency = 1.000
                SecHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SecHolder.BorderSizePixel = 0
                SecHolder.Position = UDim2.new(0.00526315812, 0, 0, 0)
                SecHolder.Size = UDim2.new(0, 282, 0, 51)
                SecHolder.ZIndex = 2
                
                SectionTitle.Name = "SectionTitle"
                SectionTitle.Parent = SecHolder
                SectionTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SectionTitle.BackgroundTransparency = 1.000
                SectionTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SectionTitle.BorderSizePixel = 0
                SectionTitle.Position = UDim2.new(0.0343750007, 0, 0.189999998, 0)
                SectionTitle.Size = UDim2.new(0, 250, 0, 23)
                SectionTitle.Font = Enum.Font.SourceSansBold
                SectionTitle.Text = title
                SectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                SectionTitle.TextSize = 17.000
                SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
                
                SectionLine.Name = "SectionLine"
                SectionLine.Parent = SecHolder
                SectionLine.BackgroundColor3 = Color3.fromRGB(59, 82, 86)
                SectionLine.BackgroundTransparency = 0.450
                SectionLine.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SectionLine.BorderSizePixel = 0
                SectionLine.Position = UDim2.new(0.0249999575, 0, 0.73399204, 0)
                SectionLine.Size = UDim2.new(0.948000014, 0, 0, 1)
                
                SectionLayout.Name = "SectionLayout"
                SectionLayout.Parent = Section
                SectionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                SectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
                SectionLayout.Padding = UDim.new(0, 5)
                
                SectionCorner.CornerRadius = UDim.new(0, 8)
                SectionCorner.Name = "SectionCorner"
                SectionCorner.Parent = Section

                spawn(function()
                    while false do -- R227: no per-frame theme polling
                        pcall(function()
                            TweenService:Create(
                                Section,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {BackgroundColor3 = Neverlose_Main.Theme.Custom.Section}
                            ):Play()
                        end)
                    end
                end)

                Section.Size = UDim2.new(0, 285, 0, SectionLayout.AbsoluteContentSize.Y + 10)
                syncNativeCanvas()

                -- Keep native two-column section structure on touch and desktop.
                -- Use deterministic insertion order: pairs/frame enumeration was
                -- occasionally comparing UIListLayout or unordered children.
                nativeSectionCount = nativeSectionCount + 1
                Section.LayoutOrder = nativeSectionCount
                Section.Parent = (nativeSectionCount % 2 == 1) and SectionHolder1 or SectionHolder2

                -- The original fixed-background sizing ran before Roblox measured
                -- its list children, leaving long Chinese labels outside section
                -- backgrounds. Recompute only when content size changes.
                local function syncSectionBounds()
                    if not Section.Parent then return end
                    local newHeight=math.max(52,math.ceil(SectionLayout.AbsoluteContentSize.Y)+12)
                    if Section.Size.Y.Offset~=newHeight then
                        Section.Size=UDim2.fromOffset(285,newHeight)
                    end
                    syncNativeCanvas()
                end
                SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncSectionBounds)
                task.defer(syncSectionBounds)

                local Global_X_Size = 10

                local Elements = {}

                function Elements:Button(title, callback)
                    local Buttonfunc = {}

                    local Button = Instance.new("TextButton")
                    local ButtonCorner = Instance.new("UICorner")
                    local ButtonTitle = Instance.new("TextLabel")
                    local ButtonStroke = Instance.new("UIStroke")

                    Button.Name = "Button"
                    Button.Parent = Section
                    Button.BackgroundColor3 = Color3.fromRGB(34, 49, 53)
                    Button.BackgroundTransparency = 1.000
                    Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Button.BorderSizePixel = 0
                    Button.Position = UDim2.new(0.0381034054, 0, 0.327935219, 0)
                    Button.Size = UDim2.new(0, 274, 0, 30)
                    Button.AutoButtonColor = false
                    Button.Font = Enum.Font.Gotham
                    Button.Text = ""
                    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                    Button.TextSize = 14.000

                    ButtonCorner.CornerRadius = UDim.new(0, 4)
                    ButtonCorner.Name = "ButtonCorner"
                    ButtonCorner.Parent = Button

                    ButtonTitle.Name = "ButtonTitle"
                    ButtonTitle.Parent = Button
                    ButtonTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    ButtonTitle.BackgroundTransparency = 1.000
                    ButtonTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ButtonTitle.BorderSizePixel = 0
                    ButtonTitle.Position = UDim2.new(0.0355987065, 0, 0.233333334, 0)
                    ButtonTitle.Size = UDim2.new(0, 194, 0, 20)
                    ButtonTitle.Font = Enum.Font.Gotham
                    ButtonTitle.Text = title
                    ButtonTitle.TextTruncate = Enum.TextTruncate.AtEnd
                    ButtonTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                    ButtonTitle.TextSize = 14.000
                    ButtonTitle.TextXAlignment = Enum.TextXAlignment.Left
                    ButtonTitle.TextYAlignment = Enum.TextYAlignment.Center

                    spawn(function()
                        while false do -- R227: no per-frame theme polling
                            pcall(function()
                                ChangeTypeText(ButtonTitle)
                                ButtonStroke.Color = Neverlose_Main.Theme.Custom.Element
                            end)
                        end
                    end)

                    ButtonStroke.Color = Color3.fromRGB(103, 181, 191)
                    ButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    ButtonStroke.LineJoinMode = Enum.LineJoinMode.Round
                    ButtonStroke.Thickness = 1
                    ButtonStroke.Transparency = 0.8
                    ButtonStroke.Parent = Button

                    Button.MouseEnter:Connect(function()
                        TweenService:Create(
                            ButtonStroke,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {Transparency = 0.1}
                        ):Play()
                    end)

                    Button.MouseLeave:Connect(function()
                        TweenService:Create(
                            ButtonStroke,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {Transparency = 0.8}
                        ):Play()
                    end)
                    Button.MouseButton1Click:Connect(function()
                        Neverlose_Main:PlaySound(Neverlose_Main.Lib_Sounds.ClickSound)
                        pcall(callback)
                    end)
                    syncSectionBounds()
                    syncNativeCanvas()

                    function Buttonfunc:visibility(state)
                        local Trans = nil
                        for i,v in pairs(Button:GetChildren()) do
                            if v:IsA("GuiObject") and v.Name ~= "ButtonTitle" then
                                v.Visible = state
                            end
                        end
                        if state then
                            Trans = 0
                        elseif state == false then
                            Trans = 1
                        end
                        TweenService:Create(
                            ButtonTitle,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {TextTransparency = Trans}
                        ):Play()
                        task.wait(.3)
                        Button.Visible = state
                        TweenService:Create(
                            Section,
                            TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                            {Size = UDim2.fromOffset(285, math.max(52, math.ceil(SectionLayout.AbsoluteContentSize.Y)+12))}
                        ):Play()
                    end

                    return Buttonfunc
                end

                function Elements:Toggle(title, callback)
                    local Togglefunc, Toggled = {Value = false}, false

                    local Toggle = Instance.new("TextButton")
                    local ToggleTitle = Instance.new("TextLabel")
                    local ToggleFrame = Instance.new("Frame")
                    local ToggleFrameCorner = Instance.new("UICorner")
                    local ToggleDot = Instance.new("Frame")
                    local ToggleDotCorner = Instance.new("UICorner")

                    local ToggledText = Instance.new("TextLabel")

                    ToggledText.Name = "ToggledText"
                    ToggledText.Parent = ToggledFrame
                    ToggledText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    ToggledText.BackgroundTransparency = 1.000
                    ToggledText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ToggledText.BorderSizePixel = 0
                    ToggledText.Position = UDim2.new(0.0264900662, 0, 0, 0)
                    ToggledText.Size = UDim2.new(0, 143, 0, 21)
                    ToggledText.Font = Enum.Font.Gotham
                    ToggledText.TextColor3 = Color3.fromRGB(255, 255, 255)
                    ToggledText.TextSize = 14.000
                    ToggledText.RichText = true
                    ToggledText.Text = title.. " | <font color='rgb(255,50,50)'>OFF</font>"
                    ToggledText.Visible = false

                    Toggle.Name = title
                    Toggle.Parent = Section
                    Toggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Toggle.BackgroundTransparency = 1.000
                    Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Toggle.BorderSizePixel = 0
                    Toggle.Position = UDim2.new(0.0171875004, 0, 0, 0)
                    Toggle.Size = UDim2.new(0, 274, 0, 30)
                    Toggle.AutoButtonColor = false
                    Toggle.Font = Enum.Font.SourceSans
                    Toggle.Text = ""
                    Toggle.TextColor3 = Color3.fromRGB(0, 0, 0)
                    Toggle.TextSize = 14.000
                    
                    ToggleTitle.Name = "ToggleTitle"
                    ToggleTitle.Parent = Toggle
                    ToggleTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    ToggleTitle.BackgroundTransparency = 1.000
                    ToggleTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ToggleTitle.BorderSizePixel = 0
                    ToggleTitle.Position = UDim2.new(0.0355987065, 0, 0.233333334, 0)
                    ToggleTitle.Size = UDim2.new(0, 194, 0, 20)
                    ToggleTitle.Font = Enum.Font.Gotham
                    ToggleTitle.Text = title
                    ToggleTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                    ToggleTitle.TextSize = 14.000
                    ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left
                    
                    ToggleFrame.Name = "ToggleFrame"
                    ToggleFrame.Parent = Toggle
                    ToggleFrame.BackgroundColor3 = Color3.fromRGB(17, 24, 28)
                    ToggleFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ToggleFrame.BorderSizePixel = 0
                    ToggleFrame.Position = UDim2.new(0.870550156, 0, 0.233333334, 0)
                    ToggleFrame.Size = UDim2.new(0, 38, 0, 15)
                    
                    ToggleFrameCorner.Name = "ToggleFrameCorner"
                    ToggleFrameCorner.Parent = ToggleFrame
                    
                    ToggleDot.Name = "ToggleDot"
                    ToggleDot.Parent = ToggleFrame
                    ToggleDot.BackgroundColor3 = Color3.fromRGB(81, 100, 106)
                    ToggleDot.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ToggleDot.BorderSizePixel = 0
                    ToggleDot.Position = UDim2.new(0, 0, -0.0588235296, 0)
                    ToggleDot.Size = UDim2.new(0, 17, 0, 17)
                    
                    ToggleDotCorner.CornerRadius = UDim.new(2, 0)
                    ToggleDotCorner.Name = "ToggleDotCorner"
                    ToggleDotCorner.Parent = ToggleDot

                    syncSectionBounds()
                    syncNativeCanvas()

                    spawn(function()
                        while false do -- R227: no per-frame theme polling
                            pcall(function()
                                ChangeTypeText(ToggleTitle)
                            end)
                        end
                    end)

                    function Togglefunc:Set(val)
                        Togglefunc.Value = val
                        if Togglefunc.Value then
                            ToggleDot.BackgroundColor3 = Neverlose_Main.Theme.Custom.Element
                            TweenService:Create(
                                ToggleDot,
                                TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {Position = UDim2.new(0, 20, -0.0588235296, 0)}
                            ):Play()

                            ToggledText.Text = title.. " | <font color='rgb(50,255,50)'>ON</font>"
                            ToggledText.Visible = true
                        else
                            TweenService:Create(
                                ToggleDot,
                                TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {Position = UDim2.new(0, 0, -0.0588235296, 0)}
                            ):Play()
                            TweenService:Create(
                                ToggleDot,
                                TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {BackgroundColor3 = Color3.fromRGB(81, 100, 106)}
                            ):Play()
                            ToggledText.Text = title.. " | <font color='rgb(255,50,50)'>OFF</font>"
                            ToggledText.Visible = false
                        end
                        Toggled = Togglefunc.Value
                        return pcall(callback, Togglefunc.Value)
                    end

                    function Togglefunc:visibility(t)
                        local state = t == true
                        local Trans = nil
                        for i,v in pairs(Toggle:GetChildren()) do
                            if v:IsA("GuiObject") and v.Name ~= "ToggleTitle" then
                                v.Visible = state
                            end
                        end
                        if state then
                            Trans = 0
                        elseif state == false then
                            Trans = 1
                        end
                        TweenService:Create(
                            ToggleTitle,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {TextTransparency = Trans}
                        ):Play()
                        task.wait(.3)
                        Toggle.Visible = state
                        TweenService:Create(
                            Section,
                            TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                            {Size = UDim2.fromOffset(285, math.max(52, math.ceil(SectionLayout.AbsoluteContentSize.Y)+12))}
                        ):Play()
                    end

                    Toggle.MouseButton1Click:Connect(function()
                        Neverlose_Main:PlaySound(Neverlose_Main.Lib_Sounds.ClickSound)
                        Toggled = not Toggled
                        Togglefunc:Set(Toggled)
                        if Toggled then
                            ToggledText.Visible = true
                            ToggledText.Text = title.. " | <font color='rgb(50,255,50)'>ON</font>"
                        else
                            ToggledText.Text = title.. " | <font color='rgb(255,50,50)'>OFF</font>"
                            ToggledText.Visible = false
                        end
                    end)

                    spawn(function()
                        while false do -- R227: no per-frame theme polling
                            if Toggled then
                                pcall(function()
                                    TweenService:Create(
                                        ToggleDot,
                                        TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                        {BackgroundColor3 = Neverlose_Main.Theme.Custom.Element}
                                    ):Play()
                                end)
                            end
                        end
                    end)

                    Neverlose_Main.Flags[title] = Togglefunc
                    return Togglefunc
                end

                function Elements:Line()
                    local linefunc = {}
                    local SectionLine = Instance.new("Frame")

                    function linefunc:visibility(state)
                        SectionLine.Visible = state
                        TweenService:Create(
                            Section,
                            TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                            {Size = UDim2.fromOffset(285, math.max(52, math.ceil(SectionLayout.AbsoluteContentSize.Y)+12))}
                        ):Play()
                    end

                    SectionLine.Name = "SectionLine"
                    SectionLine.Parent = Section
                    SectionLine.BackgroundColor3 = Color3.fromRGB(59, 82, 86)
                    SectionLine.BackgroundTransparency = 0.65
                    SectionLine.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    SectionLine.BorderSizePixel = 0
                    SectionLine.Position = UDim2.new(0.0249999575, 0, 0.73399204, 0)
                    SectionLine.Size = UDim2.new(0.948000014, 0, 0, 1)

                    syncSectionBounds()
                    syncNativeCanvas()
                    return linefunc
                end

                function Elements:Dropdown(title, list, callback)
                    local Dropfunc, DropToggled = {Value = nil}, false

                    local Dropdown = Instance.new("TextButton")
                    local DropdownTitle = Instance.new("TextLabel")
                    local DropdownFrame = Instance.new("Frame")
                    local DropdownFrameCorner = Instance.new("UICorner")
                    local Arrow = Instance.new("ImageLabel")
                    local ItemSelected = Instance.new("TextLabel")
                    local DropdownFrameHold = Instance.new("Frame")
                    local DropdownFrameHoldCorner = Instance.new("UICorner")
                    local DropdownHolder = Instance.new("ScrollingFrame")
                    local DropdownHolderLayout = Instance.new("UIListLayout")

                    function Dropfunc:visibility(state)
                        local Trans = nil
                        for i,v in pairs(Dropdown:GetChildren()) do
                            if v:IsA("GuiObject") and v.Name ~= "DropdownTitle" then
                                v.Visible = state
                            end
                        end
                        if state then
                            Trans = 0
                        elseif state == false then
                            Trans = 1
                        end
                        TweenService:Create(
                            DropdownTitle,
                            TweenInfo.new(.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                            {TextTransparency = Trans}
                        ):Play()
                        task.wait(.3)
                        Dropdown.Visible = state
                        TweenService:Create(
                            Section,
                            TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                            {Size = UDim2.fromOffset(285, math.max(52, math.ceil(SectionLayout.AbsoluteContentSize.Y)+12))}
                        ):Play()
                    end

                    Dropdown.Name = title
                    Dropdown.Parent = Section
                    Dropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Dropdown.BackgroundTransparency = 1.000
                    Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Dropdown.BorderSizePixel = 0
                    Dropdown.Position = UDim2.new(0.0171875004, 0, 0, 0)
                    Dropdown.Size = UDim2.new(0, 274, 0, 30)
                    Dropdown.AutoButtonColor = false
                    Dropdown.Font = Enum.Font.SourceSans
                    Dropdown.Text = ""
                    Dropdown.TextColor3 = Color3.fromRGB(0, 0, 0)
                    Dropdown.TextSize = 14.000
                    
                    DropdownTitle.Name = "DropdownTitle"
                    DropdownTitle.Parent = Dropdown
                    DropdownTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    DropdownTitle.BackgroundTransparency = 1.000
                    DropdownTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    DropdownTitle.BorderSizePixel = 0
                    DropdownTitle.Position = UDim2.new(0.0355987065, 0, 0.233333334, 0)
                    DropdownTitle.Size = UDim2.new(0, 166, 0, 20)
                    DropdownTitle.Font = Enum.Font.Gotham
                    DropdownTitle.Text = title
                    DropdownTitle.TextTruncate = Enum.TextTruncate.AtEnd
                    DropdownTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                    DropdownTitle.TextSize = 14.000
                    DropdownTitle.TextXAlignment = Enum.TextXAlignment.Left
                    
                    DropdownFrame.Name = "DropdownFrame"
                    DropdownFrame.Parent = Dropdown
                    DropdownFrame.BackgroundColor3 = Color3.fromRGB(17, 24, 28)
                    DropdownFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    DropdownFrame.BorderSizePixel = 0
                    DropdownFrame.Position = UDim2.new(0.640705884, 0, 0.233333334, 0)
                    DropdownFrame.Size = UDim2.new(0, 100, 0, 15)
                    
                    DropdownFrameCorner.CornerRadius = UDim.new(0, 3)
                    DropdownFrameCorner.Name = "DropdownFrameCorner"
                    DropdownFrameCorner.Parent = DropdownFrame
                    
                    Arrow.Name = "Arrow"
                    Arrow.Parent = DropdownFrame
                    Arrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Arrow.BackgroundTransparency = 1.000
                    Arrow.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Arrow.BorderSizePixel = 0
                    Arrow.Position = UDim2.new(0.790000021, 0, -0.13333334, 0)
                    Arrow.Size = UDim2.new(0, 18, 0, 18)
                    Arrow.Image = "http://www.roblox.com/asset/?id=6034818372"
                    
                    ItemSelected.Name = "ItemSelected"
                    ItemSelected.Parent = DropdownFrame
                    ItemSelected.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    ItemSelected.BackgroundTransparency = 1.000
                    ItemSelected.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ItemSelected.BorderSizePixel = 0
                    ItemSelected.Position = UDim2.new(0.0700000003, 0, 0.200000003, 0)
                    ItemSelected.Size = UDim2.new(0, 73, 0, 16)
                    ItemSelected.TextTruncate = Enum.TextTruncate.AtEnd
                    ItemSelected.Font = Enum.Font.Gotham
                    ItemSelected.Text = ""
                    ItemSelected.TextColor3 = Color3.fromRGB(255, 255, 255)
                    ItemSelected.TextSize = 12.000
                    ItemSelected.TextXAlignment = Enum.TextXAlignment.Left
                    
                    DropdownFrameHold.Name = "DropdownFrameHold"
                    DropdownFrameHold.Parent = Dropdown
                    DropdownFrameHold.BackgroundColor3 = Color3.fromRGB(23, 31, 35)
                    DropdownFrameHold.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    DropdownFrameHold.BorderSizePixel = 0
                    DropdownFrameHold.Position = UDim2.fromOffset(8, 33)
                    DropdownFrameHold.Size = UDim2.new(0, 257, 0, 130)
                    DropdownFrameHold.ZIndex = 7
                    DropdownFrameHold.Visible = false
                    DropdownFrameHold.BackgroundTransparency = 0.035
                    
                    DropdownFrameHoldCorner.CornerRadius = UDim.new(0, 3)
                    DropdownFrameHoldCorner.Name = "DropdownFrameHoldCorner"
                    DropdownFrameHoldCorner.Parent = DropdownFrameHold
                    
                    DropdownHolder.Name = "DropdownHolder"
                    DropdownHolder.Parent = DropdownFrameHold
                    DropdownHolder.ZIndex = 8
                    DropdownHolder.Active = true
                    DropdownHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    DropdownHolder.BackgroundTransparency = 1.000
                    DropdownHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    DropdownHolder.BorderSizePixel = 0
                    DropdownHolder.Size = UDim2.new(1, 0, 1, 0)
                    DropdownHolder.ScrollBarThickness = 3
                    DropdownHolder.Visible = false
                    
                    DropdownHolderLayout.Name = "DropdownHolderLayout"
                    DropdownHolderLayout.Parent = DropdownHolder
                    DropdownHolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    DropdownHolderLayout.Padding = UDim.new(0, 3)

                    syncSectionBounds()
                    syncNativeCanvas()

                    spawn(function()
                        while false do -- R227: no per-frame theme polling
                            pcall(function()
                                ChangeTypeText(DropdownTitle)
                                Arrow.ImageColor3 = Neverlose_Main.Theme.Custom.Element
                            end)
                        end
                    end)

                    Dropdown.MouseButton1Click:Connect(function()
                        Neverlose_Main:PlaySound(Neverlose_Main.Lib_Sounds.ClickSound)
                        -- Set the state before tweening: rapid mobile taps stay consistent.
                        DropToggled = not DropToggled
                        local open = DropToggled
                        Dropdown.ZIndex = open and 8 or 1
                        DropdownFrameHold.Visible = open
                        DropdownHolder.Visible = open
                        openPopupExtra = open and 170 or 0
                        syncNativeCanvas()
                        TweenService:Create(DropdownFrameHold,
                            TweenInfo.new(.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                            {Size = UDim2.fromOffset(257, open and 130 or 0)}):Play()
                        TweenService:Create(Arrow,
                            TweenInfo.new(.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                            {Rotation = open and 180 or 0}):Play()
                        syncSectionBounds()
                    end)

                    function Dropfunc:Set(val)
                        Dropfunc.Value = val
                        ItemSelected.Text = tostring(val or "未选择")
                        return pcall(callback, Dropfunc.Value)
                    end

                    for i,v in pairs(list) do
                        local Item = Instance.new("TextButton")
                        local ItemPadding = Instance.new("UIPadding")
                        local DropdownHolderPadding = Instance.new("UIPadding")

                        Item.Name = "Item"
                        Item.Parent = DropdownHolder
                        Item.ZIndex = 9
                        Item.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        Item.BackgroundTransparency = 1.000
                        Item.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Item.BorderSizePixel = 0
                        Item.Size = UDim2.fromOffset(230, 30)
                        Item.Font = Enum.Font.Gotham
                        Item.Text = "- "..tostring(v)
                        Item.TextTruncate = Enum.TextTruncate.AtEnd
                        Item.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Item.TextSize = 14
                        Item.TextXAlignment = Enum.TextXAlignment.Left
                        
                        ItemPadding.Name = "ItemPadding"
                        ItemPadding.Parent = Item
                        ItemPadding.PaddingLeft = UDim.new(0, 5)
                        
                        DropdownHolderPadding.Name = "DropdownHolderPadding"
                        DropdownHolderPadding.Parent = DropdownHolder
                        DropdownHolderPadding.PaddingTop = UDim.new(0, 1)

                        DropdownHolder.CanvasSize = UDim2.new(0, 0, 0, DropdownHolderLayout.AbsoluteContentSize.Y + 10)

                        Item.MouseButton1Click:Connect(function()
                            Neverlose_Main:PlaySound(Neverlose_Main.Lib_Sounds.ClickSound)
                            Dropfunc:Set(v)
                            TweenService:Create(
                                DropdownFrameHold,
                                TweenInfo.new(.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {Size = UDim2.new(0, 257, 0, 0)}
                            ):Play()
                            DropdownHolder.Visible = false

                            TweenService:Create(
                                Arrow,
                                TweenInfo.new(.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {Rotation = 0}
                            ):Play()

                            task.wait(0.21)
                            syncSectionBounds()
                            DropdownFrameHold.Visible = false
                            DropToggled = false
                            Dropdown.ZIndex=1
                            openPopupExtra=0
                            syncNativeCanvas()
                        end)
                    end

                    function Dropfunc:Refresh(newlist)
                        for i,v in pairs(DropdownHolder:GetChildren()) do
                            if v:IsA("TextButton") then
                                v:Destroy()
                            end
                        end
                        for i,v in pairs(newlist) do
                            local Item = Instance.new("TextButton")
                            local ItemPadding = Instance.new("UIPadding")
                            local DropdownHolderPadding = Instance.new("UIPadding")
    
                            Item.Name = "Item"
                            Item.Parent = DropdownHolder
                        Item.ZIndex = 9
                            Item.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            Item.BackgroundTransparency = 1.000
                            Item.BorderColor3 = Color3.fromRGB(0, 0, 0)
                            Item.BorderSizePixel = 0
                            Item.Size = UDim2.fromOffset(230, 30)
                            Item.Font = Enum.Font.Gotham
                            Item.Text = "- "..tostring(v)
                        Item.TextTruncate = Enum.TextTruncate.AtEnd
                            Item.TextColor3 = Color3.fromRGB(255, 255, 255)
                            Item.TextSize = 14
                            Item.TextXAlignment = Enum.TextXAlignment.Left
                            
                            ItemPadding.Name = "ItemPadding"
                            ItemPadding.Parent = Item
                            ItemPadding.PaddingLeft = UDim.new(0, 5)
                            
                            DropdownHolderPadding.Name = "DropdownHolderPadding"
                            DropdownHolderPadding.Parent = DropdownHolder
                            DropdownHolderPadding.PaddingTop = UDim.new(0, 1)
    
                            Item.MouseButton1Click:Connect(function()
                                Neverlose_Main:PlaySound(Neverlose_Main.Lib_Sounds.ClickSound)
                                Dropfunc:Set(v)
                                TweenService:Create(
                                    DropdownFrameHold,
                                    TweenInfo.new(.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                    {Size = UDim2.new(0, 257, 0, 0)}
                                ):Play()
                                DropdownHolder.Visible = false
    
                                TweenService:Create(
                                    Arrow,
                                    TweenInfo.new(.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                    {Rotation = 0}
                                ):Play()
    
                                task.wait(0.21)
                            syncSectionBounds()
                                DropdownFrameHold.Visible = false
                                DropToggled = false
                            Dropdown.ZIndex=1
                            openPopupExtra=0
                            syncNativeCanvas()
                            end)
                        end
                    end

                    Neverlose_Main.Flags[title] = Dropfunc
                    return Dropfunc
                end

                function Elements:Slider(title, min, max, start, callback)
                    local Sliderfunc, dragging = {Value = start}, false

                    local Slider = Instance.new("TextButton")
                    local SliderTitle = Instance.new("TextLabel")
                    local SliderFrame = Instance.new("Frame")
                    local SliderDot = Instance.new("Frame")
                    local SliderDotCorner = Instance.new("UICorner")
                    local Value = Instance.new("TextBox")
                    local ValueCorner = Instance.new("UICorner")

                    function Sliderfunc:visibility(state)
                        local Trans = nil
                        for i,v in pairs(Slider:GetChildren()) do
                            if v:IsA("GuiObject") and v.Name ~= "SliderTitle" then
                                v.Visible = state
                            end
                        end
                        if state then
                            Trans = 0
                        elseif state == false then
                            Trans = 1
                        end
                        TweenService:Create(
                            SliderTitle,
                            TweenInfo.new(.2, Enum.EasingStyle.Quad),
                            {TextTransparency = Trans}
                        ):Play()
                        task.wait(.3)
                        Slider.Visible = state
                        TweenService:Create(
                            Section,
                            TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                            {Size = UDim2.fromOffset(285, math.max(52, math.ceil(SectionLayout.AbsoluteContentSize.Y)+12))}
                        ):Play()
                    end
                    
                    Slider.Name = title
                    Slider.Parent = Section
                    Slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Slider.BackgroundTransparency = 1.000
                    Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Slider.BorderSizePixel = 0
                    Slider.Position = UDim2.new(0.0171875004, 0, 0, 0)
                    Slider.Size = UDim2.new(0, 274, 0, 30)
                    Slider.AutoButtonColor = false
                    Slider.Font = Enum.Font.SourceSans
                    Slider.Text = ""
                    Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
                    Slider.TextSize = 14.000
                    
                    SliderTitle.Name = "SliderTitle"
                    SliderTitle.Parent = Slider
                    SliderTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    SliderTitle.BackgroundTransparency = 1.000
                    SliderTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    SliderTitle.BorderSizePixel = 0
                    SliderTitle.Position = UDim2.new(0.0355987065, 0, 0.233333334, 0)
                    SliderTitle.Size = UDim2.new(0, 128, 0, 20)
                    SliderTitle.Font = Enum.Font.Gotham
                    SliderTitle.Text = title
                    SliderTitle.TextTruncate = Enum.TextTruncate.AtEnd
                    SliderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                    SliderTitle.TextSize = 14.000
                    SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
                    
                    SliderFrame.Name = "SliderFrame"
                    SliderFrame.Parent = Slider
                    SliderFrame.BackgroundColor3 = Color3.fromRGB(38, 49, 53)
                    SliderFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    SliderFrame.BorderSizePixel = 0
                    SliderFrame.Position = UDim2.new(0.503129959, 0, 0.466666669, 0)
                    SliderFrame.Size = UDim2.new(0, 100, 0, 1)
                    
                    SliderDot.Name = "SliderDot"
                    SliderDot.Parent = SliderFrame
                    SliderDot.BackgroundColor3 = Color3.fromRGB(103, 181, 191)
                    SliderDot.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    SliderDot.BorderSizePixel = 0
                    SliderDot.Position = UDim2.new(0, 0, -8, 0)
                    SliderDot.Size = UDim2.new(0, 17, 0, 17)
                    
                    SliderDotCorner.CornerRadius = UDim.new(2, 0)
                    SliderDotCorner.Name = "SliderDotCorner"
                    SliderDotCorner.Parent = SliderDot
                    
                    Value.Name = "Value"
                    Value.Parent = Slider
                    Value.BackgroundColor3 = Color3.fromRGB(17, 24, 28)
                    Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Value.BorderSizePixel = 0
                    Value.Position = UDim2.new(0.909385085, 0, 0.266666681, 0)
                    Value.Size = UDim2.new(0, 23, 0, 13)
                    Value.Font = Enum.Font.SourceSans
                    Value.Text = tostring(start or min)
                    Value.TextColor3 = Color3.fromRGB(255, 255, 255)
                    Value.TextScaled = true
                    Value.TextSize = 14.000
                    Value.TextWrapped = true
                    
                    ValueCorner.CornerRadius = UDim.new(0, 3)
                    ValueCorner.Name = "ValueCorner"
                    ValueCorner.Parent = Value

                    syncSectionBounds()
                    syncNativeCanvas()

                    spawn(function()
                        while false do -- R227: no per-frame theme polling
                            pcall(function()
                                ChangeTypeText(SliderTitle)
                                ChangeTypeText(Value)
                                ChangeTypeElement(SliderDot)
                            end)
                        end
                    end)

                    -- local function updateDotPositionFromValue(value)
                    --     local sliderWidth = SliderFrame.AbsoluteSize.X
                    --     local sliderDotWidth = SliderDot.AbsoluteSize.X
                        
                    --     local minPos = SliderFrame.AbsolutePosition.X
                    --     local maxPos = SliderFrame.AbsolutePosition.X + SliderFrame.AbsoluteSize.X - sliderDotWidth
                        
                    --     local positionX = minPos + (value - min) / (max - min) * (maxPos - minPos)
                        
                    --     local pos = UDim2.new((positionX - SliderFrame.AbsolutePosition.X) / sliderWidth, 0, -8, 0)
                    --     TweenService:Create(
                    --         SliderDot,
                    --         TweenInfo.new(.3, Enum.EasingStyle.Quad),
                    --         {Position = pos}
                    --     ):Play()
                    -- end

                    -- updateDotPositionFromValue(start)

                    function Sliderfunc:Set(val)
                        Sliderfunc.Value = math.clamp(tonumber(val) or min, min, max)
                        SliderDot.Position = UDim2.new(math.clamp((Sliderfunc.Value-min)/math.max(max-min,1),0,1),0,-8,0)
                        Value.Text = tostring(Sliderfunc.Value)
                        return pcall(callback, Sliderfunc.Value)
                    end
                    
                    local function slide(input)
                        local sliderWidth = SliderFrame.AbsoluteSize.X
                        local sliderDotWidth = SliderDot.AbsoluteSize.X
                        
                        local minPos = SliderFrame.AbsolutePosition.X
                        local maxPos = SliderFrame.AbsolutePosition.X + SliderFrame.AbsoluteSize.X - sliderDotWidth
                        
                        local positionX = math.clamp(input.Position.X, minPos, maxPos)
                        
                        local val = min + ((positionX - minPos) / math.max(maxPos - minPos, 1)) * (max - min)
                        Value.Text = tostring(val)
                        Sliderfunc:Set(val)
                        
                        local pos = UDim2.new((positionX - SliderFrame.AbsolutePosition.X) / sliderWidth, 0, -8, 0)
                        SliderDot.Position = pos
                    end
              
                    -- Touch supports frame-wide drag; do not depend on a 16px dot.
                    local activeInput = nil
                    local function begin(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            activeInput = input
                            dragging = true
                            slide(input)
                        end
                    end
                    local touchZone=Instance.new("Frame")
                    touchZone.Name="TouchHitbox"
                    touchZone.Active=true
                    touchZone.BackgroundTransparency=1
                    touchZone.BorderSizePixel=0
                    touchZone.Position=UDim2.fromOffset(136,0)
                    touchZone.Size=UDim2.fromOffset(112,26)
                    touchZone.ZIndex=5
                    touchZone.Parent=Slider
                    touchZone.InputBegan:Connect(begin)
                    SliderFrame.InputBegan:Connect(begin)
                    SliderDot.InputBegan:Connect(begin)
                    UserInputService.InputChanged:Connect(function(input)
                        if not dragging then return end
                        if input == activeInput or (activeInput and activeInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
                            slide(input)
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input == activeInput or (activeInput and activeInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then
                            activeInput = nil
                            dragging = false
                        end
                    end)
                    Value.FocusLost:Connect(function()
                        local n = tonumber(Value.Text)
                        if not n then Value.Text=tostring(Sliderfunc.Value); return end
                        Sliderfunc:Set(math.clamp(n,min,max))
                    end)

                    Neverlose_Main.Flags[title] = Sliderfunc
                    return Sliderfunc
                end

                function Elements:TextBox(title, callback)
                    local Textbocfunc = {}
                    local TextBox = Instance.new("TextButton")
                    local TextBoxCorner = Instance.new("UICorner")
                    local TextBoxTitle = Instance.new("TextLabel")
                    local Box = Instance.new("TextBox")
                    local BoxCorner = Instance.new("UICorner")
                    local TextBoxStroke = Instance.new("UIStroke")

                    function Textbocfunc:visibility(state)
                        local Trans = nil
                        for i,v in pairs(TextBox:GetChildren()) do
                            if v:IsA("GuiObject") and v.Name ~= "TextBoxTitle" then
                                v.Visible = state
                            end
                        end
                        if state then
                            Trans = 0
                        elseif state == false then
                            Trans = 1
                        end
                        TweenService:Create(
                            TextBoxTitle,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {TextTransparency = Trans}
                        ):Play()
                        task.wait(.3)
                        TextBox.Visible = state
                        TweenService:Create(
                            Section,
                            TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                            {Size = UDim2.fromOffset(285, math.max(52, math.ceil(SectionLayout.AbsoluteContentSize.Y)+12))}
                        ):Play()
                    end
                    
                    TextBox.Name = "TextBox"
                    TextBox.Parent = Section
                    TextBox.BackgroundColor3 = Color3.fromRGB(34, 49, 53)
                    TextBox.BackgroundTransparency = 1.000
                    TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    TextBox.BorderSizePixel = 0
                    TextBox.Position = UDim2.new(0.0381034054, 0, 0.327935219, 0)
                    TextBox.Size = UDim2.new(0, 274, 0, 30)
                    TextBox.AutoButtonColor = false
                    TextBox.Font = Enum.Font.Gotham
                    TextBox.Text = ""
                    TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                    TextBox.TextSize = 14.000
                    
                    TextBoxCorner.CornerRadius = UDim.new(0, 4)
                    TextBoxCorner.Name = "TextBoxCorner"
                    TextBoxCorner.Parent = TextBox
                    
                    TextBoxTitle.Name = "TextBoxTitle"
                    TextBoxTitle.Parent = TextBox
                    TextBoxTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    TextBoxTitle.BackgroundTransparency = 1.000
                    TextBoxTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    TextBoxTitle.BorderSizePixel = 0
                    TextBoxTitle.Position = UDim2.new(0.0355987065, 0, 0.233333334, 0)
                    TextBoxTitle.Size = UDim2.new(0, 194, 0, 20)
                    TextBoxTitle.Font = Enum.Font.Gotham
                    TextBoxTitle.Text = title
                    TextBoxTitle.TextTruncate = Enum.TextTruncate.AtEnd
                    TextBoxTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                    TextBoxTitle.TextSize = 14.000
                    TextBoxTitle.TextXAlignment = Enum.TextXAlignment.Left
                    TextBoxTitle.TextYAlignment = Enum.TextYAlignment.Top
                    
                    Box.Name = "Box"
                    Box.Parent = TextBox
                    Box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Box.BackgroundTransparency = 1.000
                    Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Box.BorderSizePixel = 0
                    Box.Position = UDim2.new(0.62156868, 0, 0.153849676, 0)
                    Box.Size = UDim2.new(0, 100, 0, 20)
                    Box.Font = Enum.Font.SourceSans
                    Box.Text = "..."
                    Box.TextColor3 = Color3.fromRGB(255, 255, 255)
                    Box.TextSize = 14.000

                    TextBoxStroke.Color = Color3.fromRGB(103, 181, 191)
                    TextBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    TextBoxStroke.LineJoinMode = Enum.LineJoinMode.Round
                    TextBoxStroke.Thickness = 1
                    TextBoxStroke.Transparency = 0.8
                    TextBoxStroke.Parent = Box

                    syncSectionBounds()
                    syncNativeCanvas()

                    spawn(function()
                        while false do -- R227: no per-frame theme polling
                            pcall(function()
                                ChangeTypeText(TextBoxTitle)
                            end)
                        end
                    end)

                    Box.Changed:Connect(function()
                        TweenService:Create(
                            TextBoxStroke,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {Transparency = 0.1}
                        ):Play()
                        task.wait(.1)
                        TweenService:Create(
                            TextBoxStroke,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {Transparency = 0.8}
                        ):Play()
                    end)

                    Box.FocusLost:Connect(function()
                        pcall(callback, Box.Text)
                    end)
                    
                    BoxCorner.CornerRadius = UDim.new(0, 5)
                    BoxCorner.Name = "BoxCorner"
                    BoxCorner.Parent = Box
                    Textbocfunc.Value = ""
                    function Textbocfunc:Set(v)
                        self.Value = tostring(v or "")
                        Box.Text = self.Value
                        pcall(callback, self.Value)
                    end
                    function Textbocfunc:Get() return Box.Text end
                    Box.FocusLost:Connect(function()
                        Textbocfunc.Value = Box.Text
                    end)
                    return Textbocfunc
                end

                function Elements:Paragraph(title, description)
                    local holder=Instance.new("Frame")
                    holder.Name="VortexionParagraph"
                    holder.BackgroundTransparency=1
                    holder.BorderSizePixel=0
                    holder.Size=UDim2.fromOffset(274,54)
                    holder.Parent=Section
                    local heading=Instance.new("TextLabel")
                    heading.BackgroundTransparency=1
                    heading.TextXAlignment=Enum.TextXAlignment.Left
                    heading.TextSize=13
                    heading.Font=Enum.Font.GothamBold
                    heading.TextColor3=Color3.fromRGB(215,224,234)
                    heading.Size=UDim2.new(1,-8,0,18)
                    heading.Text=tostring(title or "说明")
                    heading.Parent=holder
                    local body=Instance.new("TextLabel")
                    body.BackgroundTransparency=1
                    body.TextWrapped=true
                    body.TextXAlignment=Enum.TextXAlignment.Left
                    body.TextYAlignment=Enum.TextYAlignment.Top
                    body.TextSize=12
                    body.Font=Enum.Font.Gotham
                    body.TextColor3=Color3.fromRGB(155,176,190)
                    body.Position=UDim2.fromOffset(0,19)
                    body.Size=UDim2.new(1,-8,0,32)
                    body.Parent=holder
                    local result={}
                    function result:SetDesc(text)
                        body.Text=tostring(text or "")
                        task.defer(function()
                            if not holder.Parent then return end
                            local height=math.max(32,body.TextBounds.Y+6)
                            body.Size=UDim2.new(1,-8,0,height)
                            holder.Size=UDim2.fromOffset(274,19+height)
                            syncSectionBounds()
                        end)
                    end
                    result:SetDesc(description)
                    return result
                end

                function Elements:Colorpicker(title, preset, callback)
                    local Colorpickerfunc, CToggled = {Value = Color3.fromRGB()}, false
                    local ColorPickerToggled = false
                    local OldToggleColor = Color3.fromRGB(0, 0, 0)
                    local OldColor = Color3.fromRGB(0, 0, 0)
                    local OldColorSelectionPosition = nil
                    local OldHueSelectionPosition = nil
                    local ColorH, ColorS, ColorV = 1, 1, 1
                    local RainbowColorPicker = false
                    local ColorPickerInput = nil
                    local ColorInput = nil
                    local HueInput = nil

                    function Colorpickerfunc:GetRGBText(r,g,b)
                        return string.format("%d,%d,%d", r, g, b)
                    end

                    function Colorpickerfunc:GetFromRGBText(color)
                        local r, g, b = color.r * 255, color.g * 255, color.b * 255
                        return string.format("%d,%d,%d", r, g, b)
                    end

                    local Colorpicker = Instance.new("TextButton")
                    local ColorpickerCorner = Instance.new("UICorner")
                    local ColorpickerTitle = Instance.new("TextLabel")
                    local Colorpreview = Instance.new("TextButton")
                    local ColorpreviewCorner = Instance.new("UICorner")

                    function Colorpickerfunc:visibility(state)
                        local Trans = nil
                        for i,v in pairs(Colorpicker:GetChildren()) do
                            if v:IsA("GuiObject") and v.Name ~= "ColorpickerTitle" then
                                v.Visible = state
                            end
                        end
                        if state then
                            Trans = 0
                        elseif state == false then
                            Trans = 1
                        end
                        TweenService:Create(
                            ColorpickerTitle,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {TextTransparency = Trans}
                        ):Play()
                        task.wait(.3)
                        Colorpicker.Visible = state
                        TweenService:Create(
                            Section,
                            TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                            {Size = UDim2.fromOffset(285, math.max(52, math.ceil(SectionLayout.AbsoluteContentSize.Y)+12))}
                        ):Play()
                    end
                    
                    Colorpicker.Name = "Colorpicker"
                    Colorpicker.Parent = Section
                    Colorpicker.BackgroundColor3 = Color3.fromRGB(34, 49, 53)
                    Colorpicker.BackgroundTransparency = 1.000
                    Colorpicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Colorpicker.BorderSizePixel = 0
                    Colorpicker.Position = UDim2.new(0.0381034054, 0, 0.327935219, 0)
                    Colorpicker.Size = UDim2.new(0, 274, 0, 30)
                    Colorpicker.AutoButtonColor = false
                    Colorpicker.Font = Enum.Font.Gotham
                    Colorpicker.Text = ""
                    Colorpicker.TextColor3 = Color3.fromRGB(255, 255, 255)
                    Colorpicker.TextSize = 14.000
                    
                    ColorpickerCorner.CornerRadius = UDim.new(0, 4)
                    ColorpickerCorner.Name = "ColorpickerCorner"
                    ColorpickerCorner.Parent = Colorpicker
                    
                    ColorpickerTitle.Name = "ColorpickerTitle"
                    ColorpickerTitle.Parent = Colorpicker
                    ColorpickerTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    ColorpickerTitle.BackgroundTransparency = 1.000
                    ColorpickerTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ColorpickerTitle.BorderSizePixel = 0
                    ColorpickerTitle.Position = UDim2.new(0.0355987065, 0, 0.233333334, 0)
                    ColorpickerTitle.Size = UDim2.new(0, 194, 0, 20)
                    ColorpickerTitle.Font = Enum.Font.Gotham
                    ColorpickerTitle.Text = title
                    ColorpickerTitle.TextTruncate = Enum.TextTruncate.AtEnd
                    ColorpickerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                    ColorpickerTitle.TextSize = 14.000
                    ColorpickerTitle.TextXAlignment = Enum.TextXAlignment.Left
                    ColorpickerTitle.TextYAlignment = Enum.TextYAlignment.Top
                    
                    Colorpreview.Name = "Colorpreview"
                    Colorpreview.Parent = Colorpicker
                    Colorpreview.BackgroundColor3 = preset
                    Colorpreview.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Colorpreview.BorderSizePixel = 0
                    Colorpreview.Position = UDim2.new(0.925294995, 0, 0.230770409, 0)
                    Colorpreview.Size = UDim2.new(0, 15, 0, 15)
                    Colorpreview.AutoButtonColor = false
                    Colorpreview.Font = Enum.Font.SourceSans
                    Colorpreview.Text = ""
                    Colorpreview.TextColor3 = Color3.fromRGB(0, 0, 0)
                    Colorpreview.TextSize = 14.000

                    local ColorpreviewStroke = Instance.new("UIStroke")
                    ColorpreviewStroke.Color = Color3.fromRGB(103, 181, 191)
                    ColorpreviewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    ColorpreviewStroke.LineJoinMode = Enum.LineJoinMode.Round
                    ColorpreviewStroke.Thickness = 2
                    ColorpreviewStroke.Transparency = 0.1
                    ColorpreviewStroke.Parent = Colorpreview
                    
                    ColorpreviewCorner.CornerRadius = UDim.new(1, 0)
                    ColorpreviewCorner.Name = "ColorpreviewCorner"
                    ColorpreviewCorner.Parent = Colorpreview

                    local ColorPFrameGlow = Instance.new("ImageLabel")
                    local ColorPFrame = Instance.new("Frame")
                    local ColorpickerCorner_2 = Instance.new("UICorner")
                    local ColorClose = Instance.new("TextButton")
                    local ChoseColor = Instance.new("ImageButton")
                    local ChoseColorCorner = Instance.new("UICorner")
                    local ColorSelection = Instance.new("ImageLabel")
                    local Hue = Instance.new("ImageButton")
                    Hue.AutoButtonColor = false
                    ChoseColor.AutoButtonColor = false
                    local HueCorner = Instance.new("UICorner")
                    local HueSelection = Instance.new("ImageLabel")
                    local HueGradient = Instance.new("UIGradient")
                    local ColorValue = Instance.new("TextBox")
                    local ColorValueCorner = Instance.new("UICorner")

                    ColorPFrameGlow.Name = "ColorPFrameGlow"
                    ColorPFrameGlow.Parent = Section
                    ColorPFrameGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    ColorPFrameGlow.BackgroundTransparency = 1.000
                    ColorPFrameGlow.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ColorPFrameGlow.BorderSizePixel = 0
                    ColorPFrameGlow.Position = UDim2.new(0.0120689655, 0, 0.366449565, 0)
                    ColorPFrameGlow.Size = UDim2.new(0, 286, 0, 0) -- UDim2.new(0, 286, 0, 178)
                    ColorPFrameGlow.Image = "rbxassetid://4996891970"
                    ColorPFrameGlow.ImageColor3 = Color3.fromRGB(99, 172, 183)
                    ColorPFrameGlow.Visible = false
                    -- ColorPFrameGlow.ImageTransparency = 1

                    spawn(function()
                        while false do -- R227: no per-frame theme polling
                            pcall(function()
                                TweenService:Create(
                                    ColorPFrameGlow,
                                    TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                    {ImageColor3 = Neverlose_Main.Theme.Custom.Glow}
                                ):Play()
                            end)
                        end
                    end)

                    ColorPFrame.Name = "ColorPFrame"
                    ColorPFrame.Parent = ColorPFrameGlow
                    ColorPFrame.BackgroundColor3 = Color3.fromRGB(22, 29, 33)
                    ColorPFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ColorPFrame.BorderSizePixel = 0
                    ColorPFrame.Position = UDim2.new(0.0386760868, 0, 0.0423884057, 0)
                    ColorPFrame.Size = UDim2.new(0, 263, 0, 0)
                    ColorPFrame.Visible = false
                    
                    ColorpickerCorner_2.Name = "ColorpickerCorner"
                    ColorpickerCorner_2.Parent = ColorPFrame
                    
                    ColorClose.Name = "ColorClose"
                    ColorClose.Parent = ColorPFrame
                    ColorClose.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    ColorClose.BackgroundTransparency = 1.000
                    ColorClose.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ColorClose.BorderSizePixel = 0
                    ColorClose.Position = UDim2.new(0.904942989, 0, 0.0306754075, 0)
                    ColorClose.Size = UDim2.new(0, 27, 0, 21)
                    ColorClose.Font = Enum.Font.GothamBold
                    ColorClose.Text = "X"
                    ColorClose.TextColor3 = Color3.fromRGB(103, 181, 191)
                    ColorClose.TextSize = 14.000

                    spawn(function()
                        while false do -- R227: no per-frame theme polling
                            pcall(function()
                                TweenService:Create(
                                    ColorpreviewStroke,
                                    TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                    {Color = Neverlose_Main.Theme.Custom.Element}
                                ):Play()
                                ChangeTypeText(ColorpickerTitle)
                            end)
                        end
                    end)

                    ColorClose.MouseButton1Click:Connect(function()
                        if CToggled == true then
                            TweenService:Create(
                                ColorPFrame,
                                TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {Size = UDim2.new(0, 263, 0, 0)}
                            ):Play()
                            TweenService:Create(
                                ColorPFrameGlow,
                                TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {Size = UDim2.new(0, 286, 0, 0)}
                            ):Play()
                            TweenService:Create(
                                ColorPFrameGlow,
                                TweenInfo.new(.2, Enum.EasingStyle.Quad),
                                {ImageTransparency = 1}
                            ):Play()
                            for i,v in pairs(ColorPFrame:GetChildren()) do
                                if v:IsA("GuiObject") then
                                    v.Visible = false
                                    task.wait()
                                end
                            end
                            task.wait(0.2)
                                syncSectionBounds()
                            ColorPFrame.Visible = false
                            ColorPFrameGlow.Visible = false
                            CToggled = false
                        end
                    end)

                    Colorpicker.MouseButton1Click:Connect(function()
                        if CToggled == false then
                            ColorPFrame.Visible = true
                            ColorPFrameGlow.Visible = true
                            TweenService:Create(
                                ColorPFrame,
                                TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {Size = UDim2.new(0, 263, 0, 163)}
                            ):Play()
                            TweenService:Create(
                                ColorPFrameGlow,
                                TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {Size = UDim2.new(0, 286, 0, 178)}
                            ):Play()
                            TweenService:Create(
                                ColorPFrameGlow,
                                TweenInfo.new(.2, Enum.EasingStyle.Quad),
                                {ImageTransparency = 0}
                            ):Play()
                            spawn(function()
                                for i,v in pairs(ColorPFrame:GetChildren()) do
                                    if v:IsA("GuiObject") then
                                        v.Visible = true
                                        task.wait(.1)
                                    end
                                end
                            end)
                            task.wait(0.2)
                                syncSectionBounds()
                            CToggled = true

                        else
                            if CToggled == true then
                                TweenService:Create(
                                    ColorPFrame,
                                    TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                    {Size = UDim2.new(0, 263, 0, 0)}
                                ):Play()
                                TweenService:Create(
                                    ColorPFrameGlow,
                                    TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                    {Size = UDim2.new(0, 286, 0, 0)}
                                ):Play()
                                TweenService:Create(
                                    ColorPFrameGlow,
                                    TweenInfo.new(.2, Enum.EasingStyle.Quad),
                                    {ImageTransparency = 1}
                                ):Play()
                                spawn(function()
                                    for i,v in pairs(ColorPFrame:GetChildren()) do
                                        if v:IsA("GuiObject") then
                                            v.Visible = false
                                            task.wait()
                                        end
                                    end
                                end)
                                task.wait(0.2)
                                syncSectionBounds()
                                ColorPFrame.Visible = false
                                ColorPFrameGlow.Visible = false
                                CToggled = false
                            end
                        end
                    end)
                    
                    ChoseColor.Name = "ChoseColor"
                    ChoseColor.Parent = ColorPFrame
                    ChoseColor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    ChoseColor.BackgroundTransparency = 0
                    ChoseColor.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ChoseColor.BorderSizePixel = 0
                    ChoseColor.Position = UDim2.new(0.0418250933, 0, 0.0883210525, 0)
                    ChoseColor.Size = UDim2.new(0, 174, 0, 114)
                    ChoseColor.Image = "rbxassetid://4155801252"
                    -- ChoseColor.ImageColor3 = Color3.fromRGB(255, 1, 1)
                    ChoseColor.ZIndex = 10
                    
                    ChoseColorCorner.Name = "ChoseColorCorner"
                    ChoseColorCorner.Parent = ChoseColor
                    
                    ColorSelection.Name = "ColorSelection"
                    ColorSelection.Parent = ChoseColor
                    ColorSelection.AnchorPoint = Vector2.new(0.5, 0.5)
                    ColorSelection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    ColorSelection.BackgroundTransparency = 1.000
                    ColorSelection.BorderColor3 = Color3.fromRGB(2, 255, 10)
                    ColorSelection.BorderSizePixel = 0
                    ColorSelection.Position = UDim2.new(0.100689769, 0, 0.0940044597, 0)
                    ColorSelection.Size = UDim2.new(0, 18, 0, 18)
                    ColorSelection.Image = "http://www.roblox.com/asset/?id=4805639000"
                    
                    Hue.Name = "Hue"
                    Hue.Parent = ColorPFrame
                    Hue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Hue.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Hue.BorderSizePixel = 0
                    Hue.Position = UDim2.new(0.766159713, 0, 0.0858901292, 0)
                    Hue.Rotation = 0
                    Hue.Size = UDim2.new(0, 28, 0, 114)
                    Hue.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
                    Hue.ImageTransparency = 1.000
                    
                    HueCorner.CornerRadius = UDim.new(0, 4)
                    HueCorner.Name = "HueCorner"
                    HueCorner.Parent = Hue
                    
                    HueSelection.Name = "HueSelection"
                    HueSelection.Parent = Hue
                    HueSelection.AnchorPoint = Vector2.new(0.5, 0.5)
                    HueSelection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    HueSelection.BackgroundTransparency = 1.000
                    HueSelection.BorderColor3 = Color3.fromRGB(2, 255, 10)
                    HueSelection.BorderSizePixel = 0
                    HueSelection.Position = UDim2.new(0.48, 0, 1 - select(1, Color3.toHSV(preset)))
                    HueSelection.Size = UDim2.new(0, 18, 0, 18)
                    HueSelection.Image = "http://www.roblox.com/asset/?id=4805639000"
                    
                    HueGradient.Name = "HueGradient"
                    HueGradient.Parent = Hue
                    HueGradient.Rotation = 270

                    HueGradient.Color =
                    ColorSequence.new {
                        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)),
                        ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)),
                        ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)),
                        ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)),
                        ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)),
                        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))
                    }
                    
                    ColorValue.Name = "ColorValue"
                    ColorValue.Parent = ColorPFrame
                    ColorValue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    ColorValue.BackgroundTransparency = 1.000
                    ColorValue.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ColorValue.BorderSizePixel = 0
                    ColorValue.Position = UDim2.new(0.0836501867, 0, 0.822085917, 0)
                    ColorValue.Size = UDim2.new(0, 151, 0, 20)
                    ColorValue.ClearTextOnFocus = false
                    ColorValue.Font = Enum.Font.Arial
                    ColorValue.Text = Colorpickerfunc:GetFromRGBText(preset)
                    ColorValue.TextColor3 = Color3.fromRGB(255, 255, 255)
                    ColorValue.TextSize = 14.000

                    local ColorValueStroke = Instance.new("UIStroke")
                    ColorValueStroke.Color = Color3.fromRGB(103, 181, 191)
                    ColorValueStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    ColorValueStroke.LineJoinMode = Enum.LineJoinMode.Round
                    ColorValueStroke.Thickness = 1
                    ColorValueStroke.Transparency = 0.9
                    ColorValueStroke.Parent = ColorValue
                    
                    ColorValueCorner.CornerRadius = UDim.new(0, 6)
                    ColorValueCorner.Name = "ColorValueCorner"
                    ColorValueCorner.Parent = ColorValue
                    
                    syncSectionBounds()
                    syncNativeCanvas()

                    function Colorpickerfunc:Set(val)
                        Colorpickerfunc.Value = val
                        Colorpreview.BackgroundColor3 = val
                        ColorValue.Text = Colorpickerfunc:GetFromRGBText(Colorpreview.BackgroundColor3)
                        return pcall(callback, Colorpreview.BackgroundColor3)
                    end

                    Colorpicker.MouseEnter:Connect(
                        function()
                           TweenService:Create(
                              Colorpicker,
                              TweenInfo.new(.2, Enum.EasingStyle.Quad),
                              {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}
                           ):Play()
                        end
                     )
                     Colorpicker.MouseLeave:Connect(
                        function()
                           TweenService:Create(
                              Colorpicker,
                              TweenInfo.new(.2, Enum.EasingStyle.Quad),
                              {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}
                           ):Play()
                        end
                     )
                    
                        local function UpdateColorPicker()
                            Colorpreview.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
                            ChoseColor.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
                            ColorValue.Text = Colorpickerfunc:GetFromRGBText(Colorpreview.BackgroundColor3)
                        
                            Colorpickerfunc:Set(Colorpreview.BackgroundColor3)
                        end
                        
                        local function UpdateColorFromRGB(r, g, b)
                            ColorH, ColorS, ColorV = Color3.toHSV(Color3.fromRGB(r, g, b))
                            UpdateColorPicker()
                        end
                        
                        ColorH =
                            1 -
                            (math.clamp(HueSelection.AbsolutePosition.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) /
                               Hue.AbsoluteSize.Y)
                        ColorS =
                            (math.clamp(ColorSelection.AbsolutePosition.X - ChoseColor.AbsolutePosition.X, 0, ChoseColor.AbsoluteSize.X) /
                            ChoseColor.AbsoluteSize.X)
                        ColorV =
                            1 -
                            (math.clamp(ColorSelection.AbsolutePosition.Y - ChoseColor.AbsolutePosition.Y, 0, ChoseColor.AbsoluteSize.Y) /
                            ChoseColor.AbsoluteSize.Y)
                        
                        ColorValue.FocusLost:Connect(function(ep)
                            if ep then
                                local inputText = ColorValue.Text
                                local r, g, b = inputText:match("(%d+),(%d+),(%d+)")
                                
                                if r and g and b then
                                    r, g, b = tonumber(r), tonumber(g), tonumber(b)
                                    
                                    if r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255 then
                                        local newColor = Color3.fromRGB(r, g, b)
                                        local normalizedR, normalizedG, normalizedB = r / 255, g / 255, b / 255
                                        
                                        TweenService:Create(
                                            ColorSelection,
                                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                            {Position = UDim2.new(normalizedR, 0, 1 - normalizedB, 0)}
                                        ):Play()
                                        
                                        TweenService:Create(
                                            HueSelection,
                                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                            {Position = UDim2.new(0.48, 0, 1 - select(1, Color3.toHSV(newColor)))}
                                        ):Play()
                                        
                                        TweenService:Create(
                                            ChoseColor,
                                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                            {BackgroundColor3 = newColor}
                                        ):Play()

                                        TweenService:Create(
                                            Colorpreview,
                                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                            {BackgroundColor3 = newColor}
                                        ):Play()
                                        UpdateColorFromRGB(r, g, b)
                                    else
                                        warn("Invalid RGB values entered.")
                                    end
                                else
                                    warn("Invalid input format. Please use 'R,G,B' format.")
                                end
                            end
                        end)
              
                     Colorpreview.BackgroundColor3 = preset
                     ChoseColor.BackgroundColor3 = preset
                     Colorpickerfunc:Set(Colorpreview.BackgroundColor3)
              
                     ChoseColor.InputBegan:Connect(
                        function(input)
                           if input.UserInputType == Enum.UserInputType.MouseButton1 then
              
                              if ColorInput then
                                 ColorInput:Disconnect()
                              end
                              
                              ColorInput =
                                 RunService.RenderStepped:Connect(
                                    function()
                                    local ColorX =
                                       (math.clamp(Neverlose_Main.Mouse.X - ChoseColor.AbsolutePosition.X, 0, ChoseColor.AbsoluteSize.X) /
                                       ChoseColor.AbsoluteSize.X)
                                    local ColorY =
                                       (math.clamp(Neverlose_Main.Mouse.Y - ChoseColor.AbsolutePosition.Y, 0, ChoseColor.AbsoluteSize.Y) /
                                       ChoseColor.AbsoluteSize.Y)
              
                                    ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
                                    ColorS = ColorX
                                    ColorV = 1 - ColorY
              
                                    UpdateColorPicker(true)
                                 end
                                 )
                           end
                        end
                     )
              
                     ChoseColor.InputEnded:Connect(
                        function(input)
                           if input.UserInputType == Enum.UserInputType.MouseButton1 then
                              if ColorInput then
                                 ColorInput:Disconnect()
                              end
                           end
                        end
                     )
              
                     Hue.InputBegan:Connect(
                        function(input)
                           if input.UserInputType == Enum.UserInputType.MouseButton1 then
                              if RainbowColorPicker then
                                 return
                              end
              
                              if HueInput then
                                 HueInput:Disconnect()
                              end
              
                              HueInput =
                                 RunService.RenderStepped:Connect(
                                    function()
                                    local HueY =
                                       (math.clamp(Neverlose_Main.Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) /
                                          Hue.AbsoluteSize.Y)
              
                                    HueSelection.Position = UDim2.new(0.48, 0, HueY, 0)
                                    ColorH = 1 - HueY
              
                                    UpdateColorPicker(true)
                                 end
                                 )
                           end
                        end
                     )
              
                     Hue.InputEnded:Connect(
                        function(input)
                           if input.UserInputType == Enum.UserInputType.MouseButton1 then
                              if HueInput then
                                 HueInput:Disconnect()
                              end
                           end
                        end
                     )
                     
                    Neverlose_Main.Flags[title] = Colorpickerfunc
                    return Colorpickerfunc
                end

                function Elements:Bind(title, callback, external)
                    local Bindfunc = {}

                    local key, BindToggled, BindVersion, BindVerToggled, HoldToggled, ToggleToggled = '', false, "", false, false, false

                    local Bind = Instance.new("TextButton")
                    local BindTitle = Instance.new("TextLabel")
                    local BindFrame = Instance.new("TextButton")
                    local BindText = Instance.new("TextLabel")
                    local BindCorner = Instance.new("UICorner")
                    local ChangeVersion = Instance.new("Frame")
                    local ChangeVersionLayout = Instance.new("UIListLayout")
                    local None = Instance.new("TextButton")
                    local Hold = Instance.new("TextButton")
                    local Toggle_2 = Instance.new("TextButton")
                    local Always = Instance.new("TextButton")

                    function Bindfunc:visibility(state)
                        local Trans = nil
                        for i,v in pairs(Bind:GetChildren()) do
                            if v:IsA("GuiObject") and v.Name ~= "BindTitle" then
                                v.Visible = state
                            end
                        end
                        if state then
                            Trans = 0
                        elseif state == false then
                            Trans = 1
                        end
                        TweenService:Create(
                            BindTitle,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {TextTransparency = Trans}
                        ):Play()
                        task.wait(.3)
                        Bind.Visible = state
                        TweenService:Create(
                            Section,
                            TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                            {Size = UDim2.fromOffset(285, math.max(52, math.ceil(SectionLayout.AbsoluteContentSize.Y)+12))}
                        ):Play()
                    end

                    Bind.Name = "Bind"
                    Bind.Parent = Section
                    Bind.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Bind.BackgroundTransparency = 1.000
                    Bind.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Bind.BorderSizePixel = 0
                    Bind.Position = UDim2.new(-0.001754386, 0, 0.375, 0)
                    Bind.Size = UDim2.new(0, 274, 0, 26)
                    Bind.AutoButtonColor = false
                    Bind.Font = Enum.Font.SourceSans
                    Bind.Text = ""
                    Bind.TextColor3 = Color3.fromRGB(0, 0, 0)
                    Bind.TextSize = 14.000
                    
                    BindTitle.Name = "BindTitle"
                    BindTitle.Parent = Bind
                    BindTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    BindTitle.BackgroundTransparency = 1.000
                    BindTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    BindTitle.BorderSizePixel = 0
                    BindTitle.Position = UDim2.new(0.0355987065, 0, 0.233333334, 0)
                    BindTitle.Size = UDim2.new(0, 145, 0, 20)
                    BindTitle.Font = Enum.Font.Gotham
                    BindTitle.Text = title
                    BindTitle.TextTruncate = Enum.TextTruncate.AtEnd
                    BindTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                    BindTitle.TextSize = 13.000
                    BindTitle.TextXAlignment = Enum.TextXAlignment.Left
                    
                    BindFrame.Name = "BindFrame"
                    BindFrame.Parent = Bind
                    BindFrame.BackgroundColor3 = Color3.fromRGB(17, 24, 28)
                    BindFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    BindFrame.BorderSizePixel = 0
                    BindFrame.Position = UDim2.new(0.80, 0, 0.200000003, 0)
                    BindFrame.Size = UDim2.new(0, 60, 0, 17)
                    BindFrame.AutoButtonColor = false
                    BindFrame.Font = Enum.Font.SourceSans
                    BindFrame.Text = ""
                    BindFrame.TextColor3 = Color3.fromRGB(0, 0, 0)
                    BindFrame.TextSize = 14.000
                    
                    BindText.Name = "BindText"
                    BindText.Parent = BindFrame
                    BindText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    BindText.BackgroundTransparency = 1.000
                    BindText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    BindText.BorderSizePixel = 0
                    BindText.Size = UDim2.new(1, 0, 0.980000019, 0)
                    BindText.Font = Enum.Font.SourceSans
                    BindText.Text = ""
                    BindText.TextColor3 = Color3.fromRGB(255, 255, 255)
                    BindText.TextScaled = false
                    BindText.TextSize = 14.000
                    BindText.TextWrapped = true
                    
                    BindCorner.CornerRadius = UDim.new(0, 3)
                    BindCorner.Name = "BindCorner"
                    BindCorner.Parent = BindFrame

                    local BindFrameGlow = Instance.new("ImageLabel")
                    local BindFrame = Instance.new("Frame")
                    local BindFrameCorner = Instance.new("UICorner")
                    local BindFrameClose = Instance.new("TextButton")
                    local BindsList = Instance.new("ScrollingFrame")
                    local BindsListLayout = Instance.new("UIListLayout")
                    local AddBind = Instance.new("TextButton")
                    local AddBindImage = Instance.new("ImageLabel")
                    local AddBindPadding = Instance.new("UIPadding")
                    local BindedSettings = Instance.new("Frame")

                    local BindKey = Instance.new("TextButton")
                    local BindTitle = Instance.new("TextLabel")
                    local BindKeyFrame = Instance.new("TextButton")
                    local BindKeyFrameText = Instance.new("TextLabel")
                    local BindKeyFrameCorner = Instance.new("UICorner")
                    local BindMode = Instance.new("TextButton")
                    local ModeTitle = Instance.new("TextLabel")
                    local BModeHold = Instance.new("TextButton")
                    local BModeHoldText = Instance.new("TextLabel")
                    local BModeHoldCorner = Instance.new("UICorner")
                    local BModeToggle = Instance.new("TextButton")
                    local BModeToggleText = Instance.new("TextLabel")
                    local BModeToggleCorner = Instance.new("UICorner")

                    BindFrameGlow.Name = "BindFrameGlow"
                    BindFrameGlow.Parent = Section
                    BindFrameGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    BindFrameGlow.BackgroundTransparency = 1.000
                    BindFrameGlow.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    BindFrameGlow.BorderSizePixel = 0
                    BindFrameGlow.Position = UDim2.new(0.0120689655, 0, 0.366449565, 0)
                    BindFrameGlow.Size = UDim2.new(0, 286, 0, 0) -- UDim2.new(0, 286, 0, 178)
                    BindFrameGlow.Image = "rbxassetid://4996891970"
                    BindFrameGlow.ImageColor3 = Color3.fromRGB(99, 172, 183)
                    BindFrameGlow.Visible = false

                    spawn(function()
                        while false do -- R227: no per-frame theme polling
                            pcall(function()
                                TweenService:Create(
                                    BindFrameGlow,
                                    TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                    {ImageColor3 = Neverlose_Main.Theme.Custom.Glow}
                                ):Play()
                                ChangeTypeText(BindTitle)
                            end)
                        end
                    end)
                    
                    BindFrame.Name = "BindFrame"
                    BindFrame.Parent = BindFrameGlow
                    BindFrame.BackgroundColor3 = Color3.fromRGB(22, 29, 33)
                    BindFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    BindFrame.BorderSizePixel = 0
                    BindFrame.Position = UDim2.new(0.0386760868, 0, 0.0423884057, 0)
                    BindFrame.Size = UDim2.new(0, 263, 0, 0) -- UDim2.new(0, 263, 0, 163)
                    BindFrame.Visible = false
                    
                    BindFrameCorner.Name = "BindFrameCorner"
                    BindFrameCorner.Parent = BindFrame
                    
                    BindFrameClose.Name = "BindFrameClose"
                    BindFrameClose.Parent = BindFrame
                    BindFrameClose.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    BindFrameClose.BackgroundTransparency = 1.000
                    BindFrameClose.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    BindFrameClose.BorderSizePixel = 0
                    BindFrameClose.Position = UDim2.new(0.904942989, 0, 0.0306754075, 0)
                    BindFrameClose.Size = UDim2.new(0, 27, 0, 21)
                    BindFrameClose.Font = Enum.Font.GothamBold
                    BindFrameClose.Text = "X"
                    BindFrameClose.TextColor3 = Color3.fromRGB(103, 181, 191)
                    BindFrameClose.TextSize = 14.000
                    
                    BindsList.Name = "BindsList"
                    BindsList.Parent = BindFrame
                    BindsList.Active = true
                    BindsList.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    BindsList.BackgroundTransparency = 1.000
                    BindsList.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    BindsList.BorderSizePixel = 0
                    BindsList.Position = UDim2.new(0.0304182507, 0, 0.291273981, 0)
                    BindsList.Size = UDim2.new(0, 73, 0, 107)
                    BindsList.ScrollBarThickness = 0
                    
                    BindsListLayout.Name = "BindsListLayout"
                    BindsListLayout.Parent = BindsList
                    BindsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                    BindsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    
                    AddBind.Name = "AddBind"
                    AddBind.Parent = BindFrame
                    AddBind.BackgroundColor3 = Color3.fromRGB(0, 13, 26)
                    AddBind.BackgroundTransparency = 1.000
                    AddBind.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    AddBind.BorderSizePixel = 0
                    AddBind.Position = UDim2.new(0.0300007518, 0, 0.076918155, 0)
                    AddBind.Size = UDim2.new(0, 80, 0, 22)
                    AddBind.AutoButtonColor = false
                    AddBind.Font = Enum.Font.SourceSans
                    AddBind.Text = "New Bind"
                    AddBind.TextColor3 = Color3.fromRGB(255, 255, 255)
                    AddBind.TextSize = 15.000
                    AddBind.TextXAlignment = Enum.TextXAlignment.Right
                    
                    AddBindImage.Name = "AddBindImage"
                    AddBindImage.Parent = AddBind
                    AddBindImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    AddBindImage.BackgroundTransparency = 1.000
                    AddBindImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    AddBindImage.BorderSizePixel = 0
                    AddBindImage.Position = UDim2.new(-0.0709379092, 0, 0.150000006, 0)
                    AddBindImage.Size = UDim2.new(0, 15, 0, 15)
                    AddBindImage.Image = "http://www.roblox.com/asset/?id=6035047391"
                    
                    AddBindPadding.Name = "AddBindPadding"
                    AddBindPadding.Parent = AddBind
                    AddBindPadding.PaddingBottom = UDim.new(0, 2)
                    AddBindPadding.PaddingLeft = UDim.new(0, 8)
                    AddBindPadding.PaddingRight = UDim.new(0, 4)

                    local AddBindCorner = Instance.new("UICorner")
                    AddBindCorner.CornerRadius = UDim.new(0, 5)
                    AddBindCorner.Name = "AddBindCorner"
                    AddBindCorner.Parent = AddBind

                    AddBind.MouseEnter:Connect(function()
                        TweenService:Create(
                            AddBind,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {BackgroundTransparency = 0.55}
                        ):Play()
                    end)

                    AddBind.MouseLeave:Connect(function()
                        TweenService:Create(
                            AddBind,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {BackgroundTransparency = 1}
                        ):Play()
                    end)

                    AddBind.MouseButton1Click:Connect(function()
                        for i,v in pairs(BindedSettings:GetChildren()) do
                            if v:IsA("Frame") then
                                v.Visible = false
                            end
                        end

                        local BindSetting = Instance.new("TextButton")
                        local BindSettingPadding = Instance.new("UIPadding")
                        local BindSettingImage = Instance.new("ImageLabel")

                        BindSetting.Name = "BindSetting"
                        BindSetting.Parent = BindsList
                        BindSetting.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BindSetting.BackgroundTransparency = 1.000
                        BindSetting.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BindSetting.BorderSizePixel = 0
                        BindSetting.Position = UDim2.new(0.0300007518, 0, 0.076918155, 0)
                        BindSetting.Size = UDim2.new(0, 75, 0, 22)
                        BindSetting.AutoButtonColor = false
                        BindSetting.Font = Enum.Font.SourceSans
                        BindSetting.TextColor3 = Color3.fromRGB(255, 255, 255)
                        BindSetting.TextSize = 15.000
                        BindSetting.TextXAlignment = Enum.TextXAlignment.Left
                        
                        BindSettingPadding.Name = "BindSettingPadding"
                        BindSettingPadding.Parent = BindSetting
                        BindSettingPadding.PaddingBottom = UDim.new(0, 2)
                        BindSettingPadding.PaddingLeft = UDim.new(0, 1)
                        BindSettingPadding.PaddingRight = UDim.new(0, 8)
                        
                        BindSettingImage.Name = "BindSettingImage"
                        BindSettingImage.Parent = BindSetting
                        BindSettingImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BindSettingImage.BackgroundTransparency = 1.000
                        BindSettingImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BindSettingImage.BorderSizePixel = 0
                        BindSettingImage.Position = UDim2.new(0.911746085, 0, 0.200000003, 0)
                        BindSettingImage.Size = UDim2.new(0, 14, 0, 14)
                        BindSettingImage.Image = "http://www.roblox.com/asset/?id=6031091008"

                        for i,v in pairs(BindsList:GetChildren()) do
                            if v:IsA("TextButton") then
                                TweenService:Create(
                                    v.BindSettingImage,
                                    TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                    {Rotation = 180}
                                ):Play()
                                TweenService:Create(
                                    v.BindSettingImage,
                                    TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                    {ImageColor3 = Color3.fromRGB(81, 100, 106)}
                                ):Play()
                            end
                        end

                        TweenService:Create(
                            BindSettingImage,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {Rotation = 0}
                        ):Play()

                        TweenService:Create(
                            BindSettingImage,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {ImageColor3 = Neverlose_Main.Theme.Custom.Element}
                        ):Play()
                        
                        local NameToggle = Instance.new("Frame")
                        local NameToggleLayout = Instance.new("UIListLayout")
                        local BindKey = Instance.new("TextButton")
                        local BindTitle = Instance.new("TextLabel")
                        local BindKeyFrame = Instance.new("TextButton")
                        local BindKeyFrameText = Instance.new("TextLabel")
                        local BindKeyFrameCorner = Instance.new("UICorner")
                        local BindMode = Instance.new("TextButton")
                        local ModeTitle = Instance.new("TextLabel")
                        local BModeHold = Instance.new("TextButton")
                        local BModeHoldText = Instance.new("TextLabel")
                        local BModeHoldCorner = Instance.new("UICorner")
                        local BModeToggle = Instance.new("TextButton")
                        local BModeToggleText = Instance.new("TextLabel")
                        local BModeToggleCorner = Instance.new("UICorner")

                        NameToggle.Name = title.."Bind"
                        NameToggle.Parent = BindedSettings
                        NameToggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        NameToggle.BackgroundTransparency = 1.000
                        NameToggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        NameToggle.BorderSizePixel = 0
                        NameToggle.Size = UDim2.new(1, 0, 1, 0)
                        NameToggle.Visible = true

                        NameToggleLayout.Name = "NameToggleLayout"
                        NameToggleLayout.Parent = NameToggle
                        NameToggleLayout.SortOrder = Enum.SortOrder.LayoutOrder

                        BindKey.Name = "BindKey"
                        BindKey.Parent = NameToggle
                        BindKey.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BindKey.BackgroundTransparency = 1.000
                        BindKey.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BindKey.BorderSizePixel = 0
                        BindKey.Position = UDim2.new(-0.0017542555, 0, 0.0078125, 0)
                        BindKey.Size = UDim2.new(0, 133, 0, 29)
                        BindKey.AutoButtonColor = false
                        BindKey.Font = Enum.Font.SourceSans
                        BindKey.Text = ""
                        BindKey.TextColor3 = Color3.fromRGB(0, 0, 0)
                        BindKey.TextSize = 14.000
                        
                        BindTitle.Name = "BindTitle"
                        BindTitle.Parent = BindKey
                        BindTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BindTitle.BackgroundTransparency = 1.000
                        BindTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BindTitle.BorderSizePixel = 0
                        BindTitle.Position = UDim2.new(0.0355987065, 0, 0.233333334, 0)
                        BindTitle.Size = UDim2.new(0, 145, 0, 20)
                        BindTitle.Font = Enum.Font.Gotham
                        BindTitle.Text = "Key"
                        BindTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                        BindTitle.TextSize = 13.000
                        BindTitle.TextXAlignment = Enum.TextXAlignment.Left
                        
                        BindKeyFrame.Name = "BindKeyFrame"
                        BindKeyFrame.Parent = BindKey
                        BindKeyFrame.BackgroundColor3 = Color3.fromRGB(16, 22, 26)
                        BindKeyFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BindKeyFrame.BorderSizePixel = 0
                        BindKeyFrame.Position = UDim2.new(0.845000029, 0, 0.200000003, 0)
                        BindKeyFrame.Size = UDim2.new(0, 49, 0, 18)
                        BindKeyFrame.ZIndex = 3
                        BindKeyFrame.AutoButtonColor = false
                        BindKeyFrame.Font = Enum.Font.SourceSans
                        BindKeyFrame.Text = ""
                        BindKeyFrame.TextColor3 = Color3.fromRGB(0, 0, 0)
                        BindKeyFrame.TextSize = 14.000
                        BindKeyFrame.TextScaled = true
                        
                        BindKeyFrameText.Name = "BindKeyFrameText"
                        BindKeyFrameText.Parent = BindKeyFrame
                        BindKeyFrameText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BindKeyFrameText.BackgroundTransparency = 1.000
                        BindKeyFrameText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BindKeyFrameText.BorderSizePixel = 0
                        BindKeyFrameText.Size = UDim2.new(1, 0, 0.980000019, 0)
                        BindKeyFrameText.Font = Enum.Font.SourceSans
                        BindKeyFrameText.Text = KeyCodeToText(key)
                        BindKeyFrameText.TextColor3 = Color3.fromRGB(255, 255, 255)
                        BindKeyFrameText.TextScaled = true
                        BindKeyFrameText.TextSize = 14.000
                        BindKeyFrameText.TextWrapped = true
                        
                        BindKeyFrameCorner.CornerRadius = UDim.new(0, 3)
                        BindKeyFrameCorner.Name = "BindKeyFrameCorner"
                        BindKeyFrameCorner.Parent = BindKeyFrame
                        
                        BindMode.Name = "BindMode"
                        BindMode.Parent = NameToggle
                        BindMode.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BindMode.BackgroundTransparency = 1.000
                        BindMode.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BindMode.BorderSizePixel = 0
                        BindMode.Position = UDim2.new(-0.0017542555, 0, 0.0078125, 0)
                        BindMode.Size = UDim2.new(0, 133, 0, 29)
                        BindMode.AutoButtonColor = false
                        BindMode.Font = Enum.Font.SourceSans
                        BindMode.Text = ""
                        BindMode.TextColor3 = Color3.fromRGB(0, 0, 0)
                        BindMode.TextSize = 14.000
                        
                        ModeTitle.Name = "ModeTitle"
                        ModeTitle.Parent = BindMode
                        ModeTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        ModeTitle.BackgroundTransparency = 1.000
                        ModeTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        ModeTitle.BorderSizePixel = 0
                        ModeTitle.Position = UDim2.new(0.0355987065, 0, 0.233333334, 0)
                        ModeTitle.Size = UDim2.new(0, 145, 0, 20)
                        ModeTitle.Font = Enum.Font.Gotham
                        ModeTitle.Text = "Mode"
                        ModeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                        ModeTitle.TextSize = 13.000
                        ModeTitle.TextXAlignment = Enum.TextXAlignment.Left
                        
                        BModeHold.Name = "BModeHold"
                        BModeHold.Parent = BindMode
                        BModeHold.BackgroundColor3 = Color3.fromRGB(16, 22, 26)
                        BModeHold.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BModeHold.BorderSizePixel = 0
                        BModeHold.Position = UDim2.new(0.845000029, 0, 0.200000003, 0)
                        BModeHold.Size = UDim2.new(0, 49, 0, 18)
                        BModeHold.ZIndex = 3
                        BModeHold.AutoButtonColor = false
                        BModeHold.Font = Enum.Font.SourceSans
                        BModeHold.Text = ""
                        BModeHold.TextColor3 = Color3.fromRGB(0, 0, 0)
                        BModeHold.TextSize = 14.000
                        
                        BModeHoldText.Name = "BModeHoldText"
                        BModeHoldText.Parent = BModeHold
                        BModeHoldText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BModeHoldText.BackgroundTransparency = 1.000
                        BModeHoldText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BModeHoldText.BorderSizePixel = 0
                        BModeHoldText.Size = UDim2.new(1, 0, 0.980000019, 0)
                        BModeHoldText.Font = Enum.Font.SourceSans
                        BModeHoldText.Text = "Hold"
                        BModeHoldText.TextColor3 = Color3.fromRGB(255, 255, 255)
                        BModeHoldText.TextScaled = true
                        BModeHoldText.TextSize = 14.000
                        BModeHoldText.TextWrapped = true
                        
                        BModeHoldCorner.CornerRadius = UDim.new(0, 3)
                        BModeHoldCorner.Name = "BModeHoldCorner"
                        BModeHoldCorner.Parent = BModeHold
                        
                        BModeToggle.Name = "BModeToggle"
                        BModeToggle.Parent = BindMode
                        BModeToggle.BackgroundColor3 = Color3.fromRGB(6, 122, 178)
                        BModeToggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BModeToggle.BorderSizePixel = 0
                        BModeToggle.Position = UDim2.new(0.401391059, 0, 0.199999586, 0)
                        BModeToggle.Size = UDim2.new(0, 49, 0, 18)
                        BModeToggle.ZIndex = 3
                        BModeToggle.AutoButtonColor = false
                        BModeToggle.Font = Enum.Font.SourceSans
                        BModeToggle.Text = ""
                        BModeToggle.TextColor3 = Color3.fromRGB(0, 0, 0)
                        BModeToggle.TextSize = 14.000
    
                        local BModeStroke = Instance.new("UIStroke")
                        BModeStroke.Color = Color3.fromRGB(10, 41, 65)
                        BModeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                        BModeStroke.LineJoinMode = Enum.LineJoinMode.Round
                        BModeStroke.Thickness = 1
                        BModeStroke.Transparency = 0
                        BModeStroke.Parent = BModeHold
    
                        BindSetting.MouseButton1Click:Connect(function()
                            for i,v in pairs(BindedSettings:GetChildren()) do
                                if v:IsA("Frame") then
                                    v.Visible = false
                                end
                            end

                            for i,v in pairs(BindsList:GetChildren()) do
                                if v:IsA("TextButton") then
                                    TweenService:Create(
                                        v.BindSettingImage,
                                        TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                        {Rotation = 180}
                                    ):Play()
                                    TweenService:Create(
                                        v.BindSettingImage,
                                        TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                        {ImageColor3 = Color3.fromRGB(81, 100, 106)}
                                    ):Play()
                                end
                            end
                            
                            TweenService:Create(
                                BindSettingImage,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {Rotation = 0}
                            ):Play()

                            TweenService:Create(
                                BindSettingImage,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {ImageColor3 = Neverlose_Main.Theme.Custom.Element}
                            ):Play()

                            NameToggle.Visible = true
                        end)
    
                        local WhatIsToggled = true
    
                        BindSetting.Text = 'Toggle ""'
                        
                        TweenService:Create(
                            BModeToggle,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {BackgroundColor3 = Neverlose_Main.Theme.Custom.Element}
                        ):Play()
    
                        TweenService:Create(
                            BModeHold,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {BackgroundColor3 = Color3.fromRGB(16, 22, 26)}
                        ):Play()
                        
                        BModeToggle.MouseButton1Click:Connect(function()
                            TweenService:Create(
                                BModeToggle,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {BackgroundColor3 = Neverlose_Main.Theme.Custom.Element}
                            ):Play()
    
                            TweenService:Create(
                                BModeHold,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {BackgroundColor3 = Color3.fromRGB(16, 22, 26)}
                            ):Play()
                            BindSetting.Text = 'Toggle "'..KeyCodeToText(key)..'"'
                            BModeStroke.Parent = BModeHold
                            WhatIsToggled = true
                        end)
    
                        BModeHold.MouseButton1Click:Connect(function()
                            TweenService:Create(
                                BModeHold,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {BackgroundColor3 = Neverlose_Main.Theme.Custom.Element}
                            ):Play()
    
                            TweenService:Create(
                                BModeToggle,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {BackgroundColor3 = Color3.fromRGB(16, 22, 26)}
                            ):Play()
                            BModeStroke.Parent = BModeToggle
                            BindSetting.Text = 'Hold "'..KeyCodeToText(key)..'"'
                            WhatIsToggled = false
                        end)
                        
                        BModeToggleText.Name = "BModeToggleText"
                        BModeToggleText.Parent = BModeToggle
                        BModeToggleText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BModeToggleText.BackgroundTransparency = 1.000
                        BModeToggleText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BModeToggleText.BorderSizePixel = 0
                        BModeToggleText.Size = UDim2.new(1, 0, 0.980000019, 0)
                        BModeToggleText.Font = Enum.Font.SourceSans
                        BModeToggleText.Text = "Toggle"
                        BModeToggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
                        BModeToggleText.TextScaled = true
                        BModeToggleText.TextSize = 14.000
                        BModeToggleText.TextWrapped = true
                        
                        BModeToggleCorner.CornerRadius = UDim.new(0, 4)
                        BModeToggleCorner.Name = "BModeToggleCorner"
                        BModeToggleCorner.Parent = BModeToggle

                        local NameToggleFolder = Instance.new("Folder")
                        local Deletion = Instance.new("Frame")
                        local DeletionLayout = Instance.new("UIListLayout")
                        local DeletionButton = Instance.new("ImageButton")

                        NameToggleFolder.Name = "NameToggleFolder"
                        NameToggleFolder.Parent = NameToggle
                        
                        Deletion.Name = "Deletion"
                        Deletion.Parent = NameToggleFolder
                        Deletion.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        Deletion.BackgroundTransparency = 1.000
                        Deletion.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Deletion.BorderSizePixel = 0
                        Deletion.Position = UDim2.new(-0.0338385366, 0, 0.832324982, 0)
                        Deletion.Size = UDim2.new(0, 160, 0, 26)
                        
                        DeletionLayout.Name = "DeletionLayout"
                        DeletionLayout.Parent = Deletion
                        DeletionLayout.FillDirection = Enum.FillDirection.Horizontal
                        DeletionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                        DeletionLayout.SortOrder = Enum.SortOrder.LayoutOrder
                        
                        DeletionButton.Name = "DeletionButton"
                        DeletionButton.Parent = Deletion
                        DeletionButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        DeletionButton.BackgroundTransparency = 1.000
                        DeletionButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        DeletionButton.BorderSizePixel = 0
                        DeletionButton.Position = UDim2.new(0.1875, 0, 0, 0)
                        DeletionButton.Size = UDim2.new(0, 17, 0, 17)
                        DeletionButton.Image = "http://www.roblox.com/asset/?id=6022668885"
                        DeletionButton.ImageColor3 = Color3.fromRGB(94, 155, 167)

                        DeletionButton.MouseEnter:Connect(function()
                            TweenService:Create(
                                DeletionButton,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {ImageColor3 = Color3.fromRGB(200, 82, 74)}
                            ):Play()
                        end)

                        DeletionButton.MouseLeave:Connect(function()
                            TweenService:Create(
                                DeletionButton,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {ImageColor3 = Color3.fromRGB(94, 155, 167)}
                            ):Play()
                        end)
                        local Completely_Stop = false
                        DeletionButton.MouseButton1Click:Connect(function()
                            NameToggle:Destroy()
                            BindSetting:Destroy()
                            Completely_Stop = true
                        end)

                        local Bind_ = {Value = "", Binding = false, Holding = false, Toggled = WhatIsToggled}

                        BindKey.MouseButton1Click:Connect(function()
                            if Completely_Stop then return end
                            if Bind_.Binding then return end
                            BindKeyFrameText.Text = ""
                            Bind_.Binding = true
                            BindKeyFrameText.Text = "Press a key..."
                            
                            local a, b = UserInputService.InputBegan:Wait()
                            
                            Bind_.Value = a.KeyCode.Name
                            BindKeyFrameText.Text = a.KeyCode.Name
                            key = a.KeyCode
                            if WhatIsToggled == false then
                                BindSetting.Text = 'Hold "'..KeyCodeToText(key)..'"'
                            else
                                BindSetting.Text = 'Toggle "'..KeyCodeToText(key)..'"'
                            end
                            Bind_.Binding = false
                        end)
                        
                        UserInputService.InputBegan:Connect(function(Input)
                            if Completely_Stop then return end
                            if UserInputService:GetFocusedTextBox() then return end
                            if Input.KeyCode.Name == Bind_.Value and not Bind_.Binding then
                                if WhatIsToggled then
                                    Bind_.Toggled = not Bind_.Toggled
                                    callback(Bind_.Toggled)
                                else
                                    Bind_.Holding = true
                                    callback(Bind_.Holding)
                                end
                            end
                        end)
                        
                        UserInputService.InputEnded:Connect(function(Input)
                            if Completely_Stop then return end
                            if Input.KeyCode.Name == Bind_.Value then
                                if not WhatIsToggled then
                                    Bind_.Holding = false
                                    callback(Bind_.Holding)
                                end
                            end
                        end)

                    end) -- Add Bind End

                    for i,v in pairs(external) do
                        for i,v in pairs(BindedSettings:GetChildren()) do
                            if v:IsA("Frame") then
                                v.Visible = false
                            end
                        end

                        local BindSetting = Instance.new("TextButton")
                        local BindSettingPadding = Instance.new("UIPadding")
                        local BindSettingImage = Instance.new("ImageLabel")

                        BindSetting.Name = "BindSetting"
                        BindSetting.Parent = BindsList
                        BindSetting.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BindSetting.BackgroundTransparency = 1.000
                        BindSetting.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BindSetting.BorderSizePixel = 0
                        BindSetting.Position = UDim2.new(0.0300007518, 0, 0.076918155, 0)
                        BindSetting.Size = UDim2.new(0, 75, 0, 22)
                        BindSetting.AutoButtonColor = false
                        BindSetting.Font = Enum.Font.SourceSans
                        BindSetting.TextColor3 = Color3.fromRGB(255, 255, 255)
                        BindSetting.TextSize = 15.000
                        BindSetting.TextXAlignment = Enum.TextXAlignment.Left
                        
                        BindSettingPadding.Name = "BindSettingPadding"
                        BindSettingPadding.Parent = BindSetting
                        BindSettingPadding.PaddingBottom = UDim.new(0, 2)
                        BindSettingPadding.PaddingLeft = UDim.new(0, 1)
                        BindSettingPadding.PaddingRight = UDim.new(0, 8)
                        
                        BindSettingImage.Name = "BindSettingImage"
                        BindSettingImage.Parent = BindSetting
                        BindSettingImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BindSettingImage.BackgroundTransparency = 1.000
                        BindSettingImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BindSettingImage.BorderSizePixel = 0
                        BindSettingImage.Position = UDim2.new(0.911746085, 0, 0.200000003, 0)
                        BindSettingImage.Size = UDim2.new(0, 14, 0, 14)
                        BindSettingImage.Image = "http://www.roblox.com/asset/?id=6031091008"

                        for i,v in pairs(BindsList:GetChildren()) do
                            if v:IsA("TextButton") then
                                TweenService:Create(
                                    v.BindSettingImage,
                                    TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                    {Rotation = 180}
                                ):Play()
                                TweenService:Create(
                                    v.BindSettingImage,
                                    TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                    {ImageColor3 = Color3.fromRGB(81, 100, 106)}
                                ):Play()
                            end
                        end

                        TweenService:Create(
                            BindSettingImage,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {Rotation = 0}
                        ):Play()

                        TweenService:Create(
                            BindSettingImage,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad),
                            {ImageColor3 = Neverlose_Main.Theme.Custom.Element}
                        ):Play()
                        
                        local NameToggle = Instance.new("Frame")
                        local NameToggleLayout = Instance.new("UIListLayout")
                        local BindKey = Instance.new("TextButton")
                        local BindTitle = Instance.new("TextLabel")
                        local BindKeyFrame = Instance.new("TextButton")
                        local BindKeyFrameText = Instance.new("TextLabel")
                        local BindKeyFrameCorner = Instance.new("UICorner")
                        local BindMode = Instance.new("TextButton")
                        local ModeTitle = Instance.new("TextLabel")
                        local BModeHold = Instance.new("TextButton")
                        local BModeHoldText = Instance.new("TextLabel")
                        local BModeHoldCorner = Instance.new("UICorner")
                        local BModeToggle = Instance.new("TextButton")
                        local BModeToggleText = Instance.new("TextLabel")
                        local BModeToggleCorner = Instance.new("UICorner")

                        NameToggle.Name = title.."Bind"
                        NameToggle.Parent = BindedSettings
                        NameToggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        NameToggle.BackgroundTransparency = 1.000
                        NameToggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        NameToggle.BorderSizePixel = 0
                        NameToggle.Size = UDim2.new(1, 0, 1, 0)
                        NameToggle.Visible = true

                        NameToggleLayout.Name = "NameToggleLayout"
                        NameToggleLayout.Parent = NameToggle
                        NameToggleLayout.SortOrder = Enum.SortOrder.LayoutOrder

                        BindKey.Name = "BindKey"
                        BindKey.Parent = NameToggle
                        BindKey.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BindKey.BackgroundTransparency = 1.000
                        BindKey.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BindKey.BorderSizePixel = 0
                        BindKey.Position = UDim2.new(-0.0017542555, 0, 0.0078125, 0)
                        BindKey.Size = UDim2.new(0, 133, 0, 29)
                        BindKey.AutoButtonColor = false
                        BindKey.Font = Enum.Font.SourceSans
                        BindKey.Text = ""
                        BindKey.TextColor3 = Color3.fromRGB(0, 0, 0)
                        BindKey.TextSize = 14.000
                        
                        BindTitle.Name = "BindTitle"
                        BindTitle.Parent = BindKey
                        BindTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BindTitle.BackgroundTransparency = 1.000
                        BindTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BindTitle.BorderSizePixel = 0
                        BindTitle.Position = UDim2.new(0.0355987065, 0, 0.233333334, 0)
                        BindTitle.Size = UDim2.new(0, 145, 0, 20)
                        BindTitle.Font = Enum.Font.Gotham
                        BindTitle.Text = "Key"
                        BindTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                        BindTitle.TextSize = 13.000
                        BindTitle.TextXAlignment = Enum.TextXAlignment.Left
                        
                        BindKeyFrame.Name = "BindKeyFrame"
                        BindKeyFrame.Parent = BindKey
                        BindKeyFrame.BackgroundColor3 = Color3.fromRGB(16, 22, 26)
                        BindKeyFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BindKeyFrame.BorderSizePixel = 0
                        BindKeyFrame.Position = UDim2.new(0.845000029, 0, 0.200000003, 0)
                        BindKeyFrame.Size = UDim2.new(0, 49, 0, 18)
                        BindKeyFrame.ZIndex = 3
                        BindKeyFrame.AutoButtonColor = false
                        BindKeyFrame.Font = Enum.Font.SourceSans
                        BindKeyFrame.Text = ""
                        BindKeyFrame.TextColor3 = Color3.fromRGB(0, 0, 0)
                        BindKeyFrame.TextSize = 14.000
                        BindKeyFrame.TextScaled = true
                        
                        BindKeyFrameText.Name = "BindKeyFrameText"
                        BindKeyFrameText.Parent = BindKeyFrame
                        BindKeyFrameText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BindKeyFrameText.BackgroundTransparency = 1.000
                        BindKeyFrameText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BindKeyFrameText.BorderSizePixel = 0
                        BindKeyFrameText.Size = UDim2.new(1, 0, 0.980000019, 0)
                        BindKeyFrameText.Font = Enum.Font.SourceSans
                        BindKeyFrameText.Text = KeyCodeToText(key)
                        BindKeyFrameText.TextColor3 = Color3.fromRGB(255, 255, 255)
                        BindKeyFrameText.TextScaled = true
                        BindKeyFrameText.TextSize = 14.000
                        BindKeyFrameText.TextWrapped = true
                        
                        BindKeyFrameCorner.CornerRadius = UDim.new(0, 3)
                        BindKeyFrameCorner.Name = "BindKeyFrameCorner"
                        BindKeyFrameCorner.Parent = BindKeyFrame
                        
                        BindMode.Name = "BindMode"
                        BindMode.Parent = NameToggle
                        BindMode.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BindMode.BackgroundTransparency = 1.000
                        BindMode.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BindMode.BorderSizePixel = 0
                        BindMode.Position = UDim2.new(-0.0017542555, 0, 0.0078125, 0)
                        BindMode.Size = UDim2.new(0, 133, 0, 29)
                        BindMode.AutoButtonColor = false
                        BindMode.Font = Enum.Font.SourceSans
                        BindMode.Text = ""
                        BindMode.TextColor3 = Color3.fromRGB(0, 0, 0)
                        BindMode.TextSize = 14.000
                        
                        ModeTitle.Name = "ModeTitle"
                        ModeTitle.Parent = BindMode
                        ModeTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        ModeTitle.BackgroundTransparency = 1.000
                        ModeTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        ModeTitle.BorderSizePixel = 0
                        ModeTitle.Position = UDim2.new(0.0355987065, 0, 0.233333334, 0)
                        ModeTitle.Size = UDim2.new(0, 145, 0, 20)
                        ModeTitle.Font = Enum.Font.Gotham
                        ModeTitle.Text = "Mode"
                        ModeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                        ModeTitle.TextSize = 13.000
                        ModeTitle.TextXAlignment = Enum.TextXAlignment.Left
                        
                        BModeHold.Name = "BModeHold"
                        BModeHold.Parent = BindMode
                        BModeHold.BackgroundColor3 = Color3.fromRGB(16, 22, 26)
                        BModeHold.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BModeHold.BorderSizePixel = 0
                        BModeHold.Position = UDim2.new(0.845000029, 0, 0.200000003, 0)
                        BModeHold.Size = UDim2.new(0, 49, 0, 18)
                        BModeHold.ZIndex = 3
                        BModeHold.AutoButtonColor = false
                        BModeHold.Font = Enum.Font.SourceSans
                        BModeHold.Text = ""
                        BModeHold.TextColor3 = Color3.fromRGB(0, 0, 0)
                        BModeHold.TextSize = 14.000
                        
                        BModeHoldText.Name = "BModeHoldText"
                        BModeHoldText.Parent = BModeHold
                        BModeHoldText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BModeHoldText.BackgroundTransparency = 1.000
                        BModeHoldText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BModeHoldText.BorderSizePixel = 0
                        BModeHoldText.Size = UDim2.new(1, 0, 0.980000019, 0)
                        BModeHoldText.Font = Enum.Font.SourceSans
                        BModeHoldText.Text = "Hold"
                        BModeHoldText.TextColor3 = Color3.fromRGB(255, 255, 255)
                        BModeHoldText.TextScaled = true
                        BModeHoldText.TextSize = 14.000
                        BModeHoldText.TextWrapped = true
                        
                        BModeHoldCorner.CornerRadius = UDim.new(0, 3)
                        BModeHoldCorner.Name = "BModeHoldCorner"
                        BModeHoldCorner.Parent = BModeHold
                        
                        BModeToggle.Name = "BModeToggle"
                        BModeToggle.Parent = BindMode
                        BModeToggle.BackgroundColor3 = Color3.fromRGB(6, 122, 178)
                        BModeToggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BModeToggle.BorderSizePixel = 0
                        BModeToggle.Position = UDim2.new(0.401391059, 0, 0.199999586, 0)
                        BModeToggle.Size = UDim2.new(0, 49, 0, 18)
                        BModeToggle.ZIndex = 3
                        BModeToggle.AutoButtonColor = false
                        BModeToggle.Font = Enum.Font.SourceSans
                        BModeToggle.Text = ""
                        BModeToggle.TextColor3 = Color3.fromRGB(0, 0, 0)
                        BModeToggle.TextSize = 14.000
                        
                        local BModeStroke = Instance.new("UIStroke")
                        BModeStroke.Color = Color3.fromRGB(10, 41, 65)
                        BModeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                        BModeStroke.LineJoinMode = Enum.LineJoinMode.Round
                        BModeStroke.Thickness = 1
                        BModeStroke.Transparency = 0
                        BModeStroke.Parent = BModeHold
    
                        BindSetting.MouseButton1Click:Connect(function()
                            for i,v in pairs(BindedSettings:GetChildren()) do
                                if v:IsA("Frame") then
                                    v.Visible = false
                                end
                            end

                            for i,v in pairs(BindsList:GetChildren()) do
                                if v:IsA("TextButton") then
                                    TweenService:Create(
                                        v.BindSettingImage,
                                        TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                        {Rotation = 180}
                                    ):Play()
                                    TweenService:Create(
                                        v.BindSettingImage,
                                        TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                        {ImageColor3 = Color3.fromRGB(81, 100, 106)}
                                    ):Play()
                                end
                            end
                            
                            TweenService:Create(
                                BindSettingImage,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {Rotation = 0}
                            ):Play()

                            TweenService:Create(
                                BindSettingImage,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {ImageColor3 = Neverlose_Main.Theme.Custom.Element}
                            ):Play()

                            NameToggle.Visible = true
                        end)
    
                        local WhatIsToggled = v.Toggled

                        if WhatIsToggled == false then
                            TweenService:Create(
                                BModeHold,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {BackgroundColor3 = Neverlose_Main.Theme.Custom.Element}
                            ):Play()
    
                            TweenService:Create(
                                BModeToggle,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {BackgroundColor3 = Color3.fromRGB(16, 22, 26)}
                            ):Play()
                            BModeStroke.Parent = BModeToggle
                            BindSetting.Text = 'Hold "'..KeyCodeToText(key)..'"'
                        else
                            TweenService:Create(
                                BModeToggle,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {BackgroundColor3 = Neverlose_Main.Theme.Custom.Element}
                            ):Play()
    
                            TweenService:Create(
                                BModeHold,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {BackgroundColor3 = Color3.fromRGB(16, 22, 26)}
                            ):Play()
                            BindSetting.Text = 'Toggle "'..KeyCodeToText(key)..'"'
                            BModeStroke.Parent = BModeHold
                        end
                        
                        BModeToggle.MouseButton1Click:Connect(function()
                            TweenService:Create(
                                BModeToggle,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {BackgroundColor3 = Neverlose_Main.Theme.Custom.Element}
                            ):Play()
    
                            TweenService:Create(
                                BModeHold,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {BackgroundColor3 = Color3.fromRGB(16, 22, 26)}
                            ):Play()
                            BindSetting.Text = 'Toggle "'..KeyCodeToText(key)..'"'
                            BModeStroke.Parent = BModeHold
                            WhatIsToggled = true
                        end)
    
                        BModeHold.MouseButton1Click:Connect(function()
                            TweenService:Create(
                                BModeHold,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {BackgroundColor3 = Neverlose_Main.Theme.Custom.Element}
                            ):Play()
    
                            TweenService:Create(
                                BModeToggle,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {BackgroundColor3 = Color3.fromRGB(16, 22, 26)}
                            ):Play()
                            BModeStroke.Parent = BModeToggle
                            BindSetting.Text = 'Hold "'..KeyCodeToText(key)..'"'
                            WhatIsToggled = false
                        end)
                        
                        BModeToggleText.Name = "BModeToggleText"
                        BModeToggleText.Parent = BModeToggle
                        BModeToggleText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        BModeToggleText.BackgroundTransparency = 1.000
                        BModeToggleText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        BModeToggleText.BorderSizePixel = 0
                        BModeToggleText.Size = UDim2.new(1, 0, 0.980000019, 0)
                        BModeToggleText.Font = Enum.Font.SourceSans
                        BModeToggleText.Text = "Toggle"
                        BModeToggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
                        BModeToggleText.TextScaled = true
                        BModeToggleText.TextSize = 14.000
                        BModeToggleText.TextWrapped = true
                        
                        BModeToggleCorner.CornerRadius = UDim.new(0, 4)
                        BModeToggleCorner.Name = "BModeToggleCorner"
                        BModeToggleCorner.Parent = BModeToggle

                        local NameToggleFolder = Instance.new("Folder")
                        local Deletion = Instance.new("Frame")
                        local DeletionLayout = Instance.new("UIListLayout")
                        local DeletionButton = Instance.new("ImageButton")

                        NameToggleFolder.Name = "NameToggleFolder"
                        NameToggleFolder.Parent = NameToggle
                        
                        Deletion.Name = "Deletion"
                        Deletion.Parent = NameToggleFolder
                        Deletion.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        Deletion.BackgroundTransparency = 1.000
                        Deletion.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Deletion.BorderSizePixel = 0
                        Deletion.Position = UDim2.new(-0.0338385366, 0, 0.832324982, 0)
                        Deletion.Size = UDim2.new(0, 160, 0, 26)
                        
                        DeletionLayout.Name = "DeletionLayout"
                        DeletionLayout.Parent = Deletion
                        DeletionLayout.FillDirection = Enum.FillDirection.Horizontal
                        DeletionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                        DeletionLayout.SortOrder = Enum.SortOrder.LayoutOrder
                        
                        DeletionButton.Name = "DeletionButton"
                        DeletionButton.Parent = Deletion
                        DeletionButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        DeletionButton.BackgroundTransparency = 1.000
                        DeletionButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        DeletionButton.BorderSizePixel = 0
                        DeletionButton.Position = UDim2.new(0.1875, 0, 0, 0)
                        DeletionButton.Size = UDim2.new(0, 17, 0, 17)
                        DeletionButton.Image = "http://www.roblox.com/asset/?id=6022668885"
                        DeletionButton.ImageColor3 = Color3.fromRGB(94, 155, 167)

                        DeletionButton.MouseEnter:Connect(function()
                            TweenService:Create(
                                DeletionButton,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {ImageColor3 = Color3.fromRGB(200, 82, 74)}
                            ):Play()
                        end)

                        DeletionButton.MouseLeave:Connect(function()
                            TweenService:Create(
                                DeletionButton,
                                TweenInfo.new(.3, Enum.EasingStyle.Quad),
                                {ImageColor3 = Color3.fromRGB(94, 155, 167)}
                            ):Play()
                        end)
                        local Completely_Stop = false
                        DeletionButton.MouseButton1Click:Connect(function()
                            NameToggle:Destroy()
                            BindSetting:Destroy()
                            Completely_Stop = true
                        end)

                        local Bind_ = {Value = v.key.Name, Binding = false, Holding = false, Toggled = WhatIsToggled}

                        BindKey.MouseButton1Click:Connect(function()
                            if Completely_Stop then return end
                            if Bind_.Binding then return end
                            BindKeyFrameText.Text = ""
                            Bind_.Binding = true
                            BindKeyFrameText.Text = "Press a key..."
                            
                            local a, b = UserInputService.InputBegan:Wait()
                            
                            Bind_.Value = a.KeyCode.Name
                            BindKeyFrameText.Text = a.KeyCode.Name
                            key = a.KeyCode
                            if WhatIsToggled == false then
                                BindSetting.Text = 'Hold "'..KeyCodeToText(v.key)..'"'
                            else
                                BindSetting.Text = 'Toggle "'..KeyCodeToText(v.key)..'"'
                            end
                            Bind_.Binding = false
                        end)

                        if WhatIsToggled == false then
                            BindSetting.Text = 'Hold "'..KeyCodeToText(v.key)..'"'
                        else
                            BindSetting.Text = 'Toggle "'..KeyCodeToText(v.key)..'"'
                        end

                        BindKeyFrameText.Text = v.key.Name
                        
                        UserInputService.InputBegan:Connect(function(Input)
                            if Completely_Stop then return end
                            if UserInputService:GetFocusedTextBox() then return end
                            if Input.KeyCode.Name == Bind_.Value and not Bind_.Binding then
                                if WhatIsToggled then
                                    Bind_.Toggled = not Bind_.Toggled
                                    callback(Bind_.Toggled)
                                else
                                    Bind_.Holding = true
                                    callback(Bind_.Holding)
                                end
                            end
                        end)
                        
                        UserInputService.InputEnded:Connect(function(Input)
                            if Completely_Stop then return end
                            if Input.KeyCode.Name == Bind_.Value then
                                if not WhatIsToggled then
                                    Bind_.Holding = false
                                    callback(Bind_.Holding)
                                end
                            end
                        end)
                    end
                    
                    BindedSettings.Name = "BindedSettings"
                    BindedSettings.Parent = BindFrame
                    BindedSettings.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    BindedSettings.BackgroundTransparency = 1.000
                    BindedSettings.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    BindedSettings.BorderSizePixel = 0
                    BindedSettings.Position = UDim2.new(0.353611469, 0, 0.159509197, 0)
                    BindedSettings.Size = UDim2.new(0, 151, 0, 128)
                    


                    syncSectionBounds()

                    local BToggled = false

                    BindFrameClose.MouseButton1Click:Connect(function()
                        if BToggled == true then
                            TweenService:Create(
                                BindFrame,
                                TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {Size = UDim2.new(0, 263, 0, 0)}
                            ):Play()
                            TweenService:Create(
                                BindFrameGlow,
                                TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {Size = UDim2.new(0, 286, 0, 0)}
                            ):Play()
                            TweenService:Create(
                                BindFrameGlow,
                                TweenInfo.new(.2, Enum.EasingStyle.Quad),
                                {ImageTransparency = 1}
                            ):Play()
                            for i,v in pairs(BindFrame:GetChildren()) do
                                if v:IsA("GuiObject") then
                                    v.Visible = false
                                    task.wait()
                                end
                            end
                            task.wait(0.2)
                                syncSectionBounds()
                            BindFrame.Visible = false
                            BindFrameGlow.Visible = false
                            BToggled = false
                        end
                    end)

                    Bind.MouseButton1Click:Connect(function()
                        if BToggled == false then
                            BindFrame.Visible = true
                            BindFrameGlow.Visible = true
                            TweenService:Create(
                                BindFrame,
                                TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {Size = UDim2.new(0, 263, 0, 163)}
                            ):Play()
                            TweenService:Create(
                                BindFrameGlow,
                                TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {Size = UDim2.new(0, 286, 0, 178)}
                            ):Play()
                            TweenService:Create(
                                BindFrameGlow,
                                TweenInfo.new(.2, Enum.EasingStyle.Quad),
                                {ImageTransparency = 0}
                            ):Play()
                            spawn(function()
                                for i,v in pairs(BindFrame:GetChildren()) do
                                    if v:IsA("GuiObject") then
                                        v.Visible = true
                                        task.wait(.1)
                                    end
                                end
                            end)
                            task.wait(0.2)
                                syncSectionBounds()
                            BToggled = true
                        else
                            if BToggled == true then
                                TweenService:Create(
                                    BindFrame,
                                    TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                    {Size = UDim2.new(0, 263, 0, 0)}
                                ):Play()
                                TweenService:Create(
                                    BindFrameGlow,
                                    TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                    {Size = UDim2.new(0, 286, 0, 0)}
                                ):Play()
                                TweenService:Create(
                                    BindFrameGlow,
                                    TweenInfo.new(.2, Enum.EasingStyle.Quad),
                                    {ImageTransparency = 1}
                                ):Play()
                                spawn(function()
                                    for i,v in pairs(BindFrame:GetChildren()) do
                                        if v:IsA("GuiObject") then
                                            v.Visible = false
                                            task.wait()
                                        end
                                    end
                                end)
                                task.wait(0.2)
                                syncSectionBounds()
                                BindFrame.Visible = false
                                BindFrameGlow.Visible = false
                                BToggled = false
                            end
                        end
                    end)
                    return Bindfunc
                end

                return Elements
            end -- Sections end
            return Sections
        end -- Tabs Table end
        return Tabs
    end -- TabsSec end
    -- R227: stock script/config/chat autorun removed. The host owns preferences.
    MainFrame.Visible = true
    Neverlose_Main.Root = Neverlose
    Neverlose_Main.MainFrame = MainFrame
    Neverlose_Main.LeftFrame = LeftFrame
    Neverlose_Main.TabHolder = TabHolder
    Neverlose_Main.ContainerHolder = ContainerHolder
    return TabsSec
end

return Neverlose_Main

end)()
-- Generated from assets/ui/Vortexion_Logo_256.png. Direct user-provided artwork, not a Roblox asset ID.
local VortexionLogoAssetFactory = (function()
    local encoded = [[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]]
    local filename = "Vortexion_r224_brand-772fd5fda849.png"
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local lookup = {}
    for i=1,#chars do lookup[string.sub(chars,i,i)] = i-1 end
    local function decode64(input)
        local out = {}
        for i=1,#input,4 do
            local a,b,c,d = lookup[input:sub(i,i)],lookup[input:sub(i+1,i+1)],lookup[input:sub(i+2,i+2)],lookup[input:sub(i+3,i+3)]
            if not a or not b then return nil end
            local n=a*262144+b*4096+(c or 0)*64+(d or 0)
            out[#out+1]=string.char(math.floor(n/65536)%256)
            if c then out[#out+1]=string.char(math.floor(n/256)%256) end
            if d then out[#out+1]=string.char(n%256) end
        end
        return table.concat(out)
    end
    return function()
        local env = (type(getgenv)=="function" and getgenv()) or _G
        if type(env.VortexionR224BrandAsset)=="string" then return env.VortexionR224BrandAsset, "embedded PNG" end
        local assetFn = type(getcustomasset)=="function" and getcustomasset or
            (type(getsynasset)=="function" and getsynasset) or
            (type(getfileasset)=="function" and getfileasset)
        if not assetFn or type(writefile)~="function" then
            return nil,"执行器不支持本地 PNG 资源（需要 writefile 与 getcustomasset）"
        end
        local ok,result=pcall(function()
            if type(isfolder)=="function" and type(makefolder)=="function" and not isfolder("Vortexion") then makefolder("Vortexion") end
            local exists=type(isfile)=="function" and isfile(filename)
            if not exists then
                local bytes=decode64(encoded)
                assert(type(bytes)=="string" and #bytes>1000,"brand PNG decode failed")
                writefile(filename,bytes)
            end
            return assetFn(filename)
        end)
        if ok and type(result)=="string" and #result>0 then
            env.VortexionR224BrandAsset=result
            return result,"embedded PNG"
        end
        return nil,"PNG 资源加载失败: "..tostring(result)
    end
end)()

local EmergencyWindowFactory = (function()
-- R229: last-resort Neverlose-compatible dual-column shell.
-- Only used if the uploaded UI library cannot construct its Window on an executor.
-- It does not replace the normal Neverlose interface when that interface works.
return function(library, cause)
    local Players = game:GetService('Players')
    local UIS = game:GetService('UserInputService')
    local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
    local background, sectionColor, textColor, accent = rgb(15,19,21),rgb(23,29,32),rgb(234,240,244),rgb(103,181,191)
    local function ui(kind,parent,name,size,position)
        local object=Instance.new(kind)
        object.Name=name or kind
        if size then object.Size=size end
        if position then object.Position=position end
        if parent then object.Parent=parent end
        return object
    end
    local function corner(object,r)
        local c=ui('UICorner',object,'Corners'); c.CornerRadius=UDim.new(0,r or 5)
    end
    local function text(parent,content,size,position,fontSize,color)
        local l=ui('TextLabel',parent,'Label',size,position)
        l.BackgroundTransparency=1; l.Text=tostring(content or '');l.TextColor3=color or textColor
        l.Font=Enum.Font.Gotham; l.TextSize=fontSize or 14
        l.TextXAlignment=Enum.TextXAlignment.Left;l.TextTruncate=Enum.TextTruncate.AtEnd
        return l
    end
    local screen=ui('ScreenGui',nil,'VortexionEmergencyNeverlose')
    screen.IgnoreGuiInset=true;screen.ResetOnSpawn=false;screen.DisplayOrder=200
    local targets={}
    if type(gethui)=='function' then local ok,hidden=pcall(gethui);if ok and hidden then targets[#targets+1]=hidden end end
    local ok,core=pcall(function()return game:GetService('CoreGui')end)
    if ok and core then targets[#targets+1]=core end
    local player=Players.LocalPlayer
    if player then
        local playerGui=player:FindFirstChildOfClass('PlayerGui') or player:WaitForChild('PlayerGui',5)
        if playerGui then targets[#targets+1]=playerGui end
    end
    local mounted=false
    for _,target in ipairs(targets) do
        local placed=pcall(function()screen.Parent=target end)
        if placed and screen.Parent==target then mounted=true;break end
    end
    assert(mounted,'Emergency Neverlose: unable to mount ScreenGui')
    local root=ui('Frame',screen,'MainFrame',UDim2.fromOffset(643,682))
    root.BackgroundColor3=background;root.BorderSizePixel=0;corner(root,6)
    local sidebar=ui('ScrollingFrame',root,'Sidebar',UDim2.fromOffset(203,682),UDim2.fromOffset(-203,0))
    sidebar.BackgroundColor3=sectionColor;sidebar.BorderSizePixel=0
    sidebar.ScrollBarThickness=3;sidebar.CanvasSize=UDim2.fromOffset(0,0);sidebar.AutomaticCanvasSize=Enum.AutomaticSize.Y
    local leftPadding=ui('UIPadding',sidebar,'Padding');leftPadding.PaddingTop=UDim.new(0,16)
    leftPadding.PaddingLeft=UDim.new(0,12);leftPadding.PaddingRight=UDim.new(0,12)
    local navLayout=ui('UIListLayout',sidebar,'NavLayout');navLayout.Padding=UDim.new(0,6)
    navLayout.SortOrder=Enum.SortOrder.LayoutOrder
    text(root,'VORTEXION · 兼容模式',UDim2.new(1,-32,0,38),UDim2.fromOffset(18,8),19,accent)
    local warning=text(root,'原生 UI 创建失败，已使用离线兼容界面',UDim2.new(1,-30,0,24),UDim2.fromOffset(18,43),12,rgb(208,183,130))
    local pages=ui('Frame',root,'Content',UDim2.new(1,-24,1,-87),UDim2.fromOffset(12,78))
    pages.BackgroundTransparency=1
    local activeTab=nil
    local function newButton(parent,label,width,height)
        local button=ui('TextButton',parent,label,width or UDim2.new(1,0,0,36))
        button.BackgroundColor3=rgb(39,49,54);button.TextColor3=textColor;button.BorderSizePixel=0
        button.Font=Enum.Font.GothamMedium;button.TextSize=13;button.Text=tostring(label)
        button.AutoButtonColor=true;corner(button,5);return button
    end
    local function select(page)
        if activeTab then activeTab.Frame.Visible=false;activeTab.Button.BackgroundColor3=rgb(39,49,54) end
        activeTab=page;page.Frame.Visible=true;page.Button.BackgroundColor3=rgb(43,86,99)
    end
    local groups={}
    function groups:TSection(label)
        local title=text(sidebar,label,UDim2.new(1,0,0,29),nil,12,accent)
        local group={}
        function group:Tab(label,icon)
            local button=newButton(sidebar,label)
            if type(icon)=='string' and icon~='' then
                local badge=ui('ImageLabel',button,'Icon',UDim2.fromOffset(16,16),UDim2.fromOffset(7,10))
                badge.BackgroundTransparency=1;badge.Image=icon;badge.ImageColor3=accent
                button.Text='    '..label
            end
            local pane=ui('Frame',pages,'Tab_'..tostring(label),UDim2.fromScale(1,1));pane.BackgroundTransparency=1;pane.Visible=false
            local holder={Frame=pane,Button=button,Sections={},Left=nil,Right=nil}
            button.MouseButton1Click:Connect(function()select(holder)end)
            if activeTab==nil then select(holder)end
            local function column(index)
                local x=(index==1) and 0 or 0.51
                local frame=ui('ScrollingFrame',pane,'Column'..index,UDim2.new(0.49,0,1,0),UDim2.new(x,0,0,0))
                frame.BackgroundTransparency=1;frame.ScrollBarThickness=3
                frame.CanvasSize=UDim2.fromOffset(0,0);frame.AutomaticCanvasSize=Enum.AutomaticSize.Y
                local layout=ui('UIListLayout',frame,'Layout');layout.Padding=UDim.new(0,9)
                layout.SortOrder=Enum.SortOrder.LayoutOrder
                return frame
            end
            function holder:Select()select(holder)end
            function holder:Section(title)
                local index=#self.Sections+1
                local target=((index%2)==1) and (self.Left or column(1)) or (self.Right or column(2))
                if index%2==1 then self.Left=target else self.Right=target end
                local panel=ui('Frame',target,'Section_'..title,UDim2.new(1,-8,0,45))
                panel.AutomaticSize=Enum.AutomaticSize.Y
                panel.BackgroundColor3=sectionColor;panel.BorderSizePixel=0;corner(panel,5)
                local pad=ui('UIPadding',panel,'Padding');pad.PaddingTop=UDim.new(0,10)
                pad.PaddingBottom=UDim.new(0,9);pad.PaddingLeft=UDim.new(0,11);pad.PaddingRight=UDim.new(0,11)
                local list=ui('UIListLayout',panel,'Layout');list.Padding=UDim.new(0,7)
                list.SortOrder=Enum.SortOrder.LayoutOrder
                text(panel,title,UDim2.new(1,0,0,21),nil,14,accent)
                local section={Panel=panel}
                local function row(label)
                    local f=ui('Frame',panel,'Row',UDim2.new(1,0,0,37));f.BackgroundTransparency=1
                    text(f,label,UDim2.new(.6,0,1,0),nil,13)
                    return f
                end
                function section:Toggle(label,callback)
                    local frame=row(label)
                    local button=newButton(frame,'关闭',UDim2.fromOffset(55,29))
                    button.AnchorPoint=Vector2.new(1,.5);button.Position=UDim2.new(1,0,.5,0)
                    local value=false;local control={}
                    function control:Set(v)
                        value=v==true;button.Text=value and '开启' or '关闭'
                        button.BackgroundColor3=value and accent or rgb(39,49,54)
                        if callback then callback(value) end
                    end
                    function control:Get()return value end
                    button.MouseButton1Click:Connect(function()control:Set(not value)end)
                    return control
                end
                function section:Slider(label,lo,hi,default,callback)
                    local frame=row(label)
                    local number=newButton(frame,tostring(default),UDim2.fromOffset(75,29))
                    number.AnchorPoint=Vector2.new(1,.5);number.Position=UDim2.new(1,0,.5,0)
                    local current=default;local control={}
                    function control:Set(v)
                        current=math.max(lo,math.min(hi,tonumber(v) or lo))
                        number.Text=tostring(math.floor(current*100+.5)/100)
                        if callback then callback(current) end
                    end
                    function control:Get()return current end
                    local function update(input)
                        local x=input.Position.X-number.AbsolutePosition.X
                        control:Set(lo+(hi-lo)*math.max(0,math.min(1,x/math.max(1,number.AbsoluteSize.X))))
                    end
                    number.InputBegan:Connect(function(input)
                        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then update(input)end
                    end)
                    number.InputChanged:Connect(function(input)
                        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement then update(input)end
                    end)
                    return control
                end
                function section:Dropdown(label,values,callback)
                    local frame=row(label)
                    local button=newButton(frame,'选择',UDim2.fromOffset(108,29))
                    button.AnchorPoint=Vector2.new(1,.5);button.Position=UDim2.new(1,0,.5,0)
                    local choices=values or {};local chosen=nil;local control={}
                    function control:Set(v)
                        chosen=v;button.Text=tostring(v or '无选项')
                        if callback then callback(v) end
                    end
                    function control:Get()return chosen end
                    function control:Refresh(nextList)choices=nextList or {};control:Set(choices[1])end
                    button.MouseButton1Click:Connect(function()
                        if #choices==0 then return end
                        local nextIdx=1
                        for i,v in ipairs(choices)do if v==chosen then nextIdx=i%#choices+1;break end end
                        control:Set(choices[nextIdx])
                    end)
                    return control
                end
                function section:TextBox(label,callback)
                    local frame=row(label)
                    local input=ui('TextBox',frame,'Input',UDim2.fromOffset(100,29))
                    input.AnchorPoint=Vector2.new(1,.5);input.Position=UDim2.new(1,0,.5,0)
                    input.BackgroundColor3=rgb(39,49,54);input.TextColor3=textColor
                    input.PlaceholderText='输入';input.Text='';input.TextSize=13;input.BorderSizePixel=0;corner(input,5)
                    local control={}
                    function control:Set(value)
                        input.Text=tostring(value or '');if callback then callback(input.Text)end
                    end
                    function control:Get()return input.Text end
                    input.FocusLost:Connect(function()if callback then callback(input.Text)end end)
                    return control
                end
                function section:Colorpicker(label,default,callback)
                    local frame=row(label)
                    local button=newButton(frame,'颜色',UDim2.fromOffset(66,29))
                    button.AnchorPoint=Vector2.new(1,.5);button.Position=UDim2.new(1,0,.5,0)
                    local colors={default or accent,rgb(103,181,191),rgb(255,83,83),rgb(42,42,42),rgb(255,255,255)}
                    local current=colors[1];local control={}
                    function control:Set(c)
                        current=c;button.BackgroundColor3=c
                        if callback then callback(c) end
                    end
                    function control:Get()return current end
                    button.MouseButton1Click:Connect(function()
                        local nextIndex=1
                        for i,c in ipairs(colors) do if c==current then nextIndex=i%#colors+1;break end end
                        control:Set(colors[nextIndex])
                    end)
                    return control
                end
                function section:Button(label,callback)
                    local b=newButton(panel,label)
                    b.MouseButton1Click:Connect(function()if callback then callback()end end)
                    return b
                end
                function section:Paragraph(label,description)
                    local f=ui('Frame',panel,'Paragraph',UDim2.new(1,0,0,66))
                    f.BackgroundTransparency=1
                    text(f,label,UDim2.new(1,0,0,20),nil,13,accent)
                    local desc=text(f,description,UDim2.new(1,0,0,45),UDim2.fromOffset(0,21),12)
                    desc.TextWrapped=true;desc.TextTruncate=Enum.TextTruncate.None
                    return {SetDesc=function(_,value)desc.Text=tostring(value) end}
                end
                self.Sections[index]=section
                return section
            end
            return holder
        end
        return group
    end
    library.Root=screen;library.MainFrame=root
    library.VisMain=function(_,visible)root.Visible=visible end
    library.Window=function()return groups end
    library.EmergencyReason=tostring(cause or 'Neverlose Window returned no handle'):sub(1,800)
    warning.Text='原生 UI 不可用，双列兼容模式已启动；查看启动诊断'
    return groups
end

end)()
local ServerSwitchFactory = (function()
-- Standalone factory; controller methods use colon syntax.
return function(tab, notify)
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local player, placeId = Players.LocalPlayer, game.PlaceId
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local apiRequest = (syn and syn.request) or http_request or request
        or (http and http.request) or (fluxus and fluxus.request)
    local config = {
        PreferredCountries = {"HK", "JP", "SG", "TW", "KR"},
        PreferredIPPrefixes = {}, AutoSwitch = false, StrictRegion = true,
        PingThresholdMs = 180, PingSamplesRequired = 4, SampleIntervalSeconds = 5,
        InitialDelaySeconds = 20, SwitchCooldownSeconds = 240,
        MaxServerPages = 3, MaxIPLookups = 12, MinAvailableSlots = 1,
        MinimumServerFPS = 35, CountryLookupUrl = "https://ipwho.is/",
        RequestTimeoutSeconds = 10, TeleportTimeoutSeconds = 20,
        MaxTeleportAttempts = 3, RetryDelaySeconds = 2,
    }
    local bounds = {
        PingThresholdMs = {50, 1000}, PingSamplesRequired = {1, 12},
        SampleIntervalSeconds = {1, 60}, InitialDelaySeconds = {0, 120},
        SwitchCooldownSeconds = {10, 1800}, MaxServerPages = {1, 10},
        MaxIPLookups = {1, 30}, MinAvailableSlots = {1, 100},
        MinimumServerFPS = {0, 60}, RequestTimeoutSeconds = {1, 60},
        TeleportTimeoutSeconds = {5, 120}, MaxTeleportAttempts = {1, 5},
        RetryDelaySeconds = {1, 30},
    }
    local function copy(value)
        if type(value) ~= "table" then return value end
        local result = {}
        for k, v in pairs(value) do result[k] = copy(v) end
        return result
    end
    local function finite(n)
        return type(n) == "number" and n == n and n > -math.huge and n < math.huge
    end
    local function validIP(ip)
        if type(ip) ~= "string" then return false end
        local a, b, c, d = ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
        if not a then return false end
        a, b, c, d = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
        if a > 255 or b > 255 or c > 255 or d > 255 then return false end
        return not (a == 0 or a == 10 or a == 127 or a >= 224
            or (a == 169 and b == 254) or (a == 172 and b >= 16 and b <= 31)
            or (a == 192 and b == 168) or (a == 100 and b >= 64 and b <= 127))
    end
    local running, busy, generation = true, false, 0
    local highSamples, lastSearch, enabledAt = 0, -math.huge, os.clock()
    local requestInFlight, pendingTeleport = false, nil
    local listeners, regionCache = {}, {}
    local blocked = {[game.JobId] = true}
    local status = {Phase = "idle", Message = "自动切服默认关闭", Busy = false,
        Running = true, AutoSwitch = false, HighSamples = 0, Requests = 0,
        Pages = 0, IPChecks = 0, ResolvedIPs = 0, TeleportAttempts = 0}
    local paragraph
    local controller = {}
    local function emit(phase, message, fields)
        if phase then status.Phase = phase end
        if message then status.Message = message end
        for k, v in pairs(fields or {}) do status[k] = v end
        status.Busy, status.Running = busy, running
        status.AutoSwitch, status.HighSamples = config.AutoSwitch, highSamples
        status.RequestInFlight = requestInFlight
        status.CooldownRemaining = math.max(0, config.SwitchCooldownSeconds - (os.clock() - lastSearch))
        if paragraph and type(paragraph.SetDesc) == "function" then
            local ping = status.PingMs and (tostring(status.PingMs) .. " ms") or "暂无采样"
            pcall(paragraph.SetDesc, paragraph, status.Message .. "\n客户端延迟：" .. ping
                .. " | 连续高延迟：" .. highSamples .. "/" .. config.PingSamplesRequired
                .. "\n列表页：" .. status.Pages .. " | IP 查询：" .. status.IPChecks
                .. " | 传送尝试：" .. status.TeleportAttempts)
        end
        local callbacks = {}
        for fn in pairs(listeners) do callbacks[#callbacks + 1] = fn end
        for _, fn in ipairs(callbacks) do
            if listeners[fn] then pcall(fn, copy(status)) end
        end
    end
    local function alive(token) return running and token == generation end
    local function pause(token, duration)
        local deadline = os.clock() + duration
        while alive(token) and os.clock() < deadline do task.wait(math.min(0.1, deadline - os.clock())) end
        return alive(token)
    end
    -- Keep the physical request fence after timeout; late results never commit state.
    local function bounded(token, timeout, fn)
        if not alive(token) then return nil, "已停止" end
        if requestInFlight then return nil, "上次超时请求尚未返回" end
        requestInFlight = true
        local done, expired, ok, result = false, false, false, nil
        local deadline = os.clock() + timeout
        task.spawn(function()
            if not alive(token) then requestInFlight = false; return end
            local success, value = pcall(fn)
            requestInFlight = false
            if not expired and alive(token) and os.clock() <= deadline then
                ok, result, done = success, value, true
            end
        end)
        while alive(token) and not done and os.clock() < deadline do task.wait(0.05) end
        if not alive(token) then expired = true; return nil, "已停止" end
        if not done then expired = true; return nil, "请求超时" end
        if not ok then return nil, "请求失败：" .. tostring(result) end
        return result
    end
    local function json(token, cfg, method, url, body)
        status.Requests = status.Requests + 1
        local response, reason = bounded(token, cfg.RequestTimeoutSeconds, function()
            if type(apiRequest) == "function" then
                return apiRequest({Url = url, Method = method, Body = body,
                    Headers = {["Content-Type"] = "application/json", Accept = "application/json"}})
            end
            if method == "GET" then return {Body = game:HttpGet(url)} end
            error("执行器未提供 POST 请求接口")
        end)
        if not alive(token) then return nil, "已停止" end
        if type(response) ~= "table" then return nil, reason or "响应格式错误" end
        local code = tonumber(response.StatusCode or response.Status or response.status_code)
        if code and (code < 200 or code >= 300) then return nil, "HTTP " .. code end
        local bodyText = response.Body or response.body
        if type(bodyText) ~= "string" then return nil, "响应正文缺失" end
        local ok, data = pcall(HttpService.JSONDecode, HttpService, bodyText)
        if not alive(token) then return nil, "已停止" end
        if ok and type(data) == "table" then return data end
        return nil, "JSON 解析失败"
    end
    local function resolve(token, cfg, id)
        if type(env.VortexionResolveServerIP) == "function" then
            local ip = bounded(token, cfg.RequestTimeoutSeconds, function()
                return env.VortexionResolveServerIP(placeId, id)
            end)
            if not alive(token) then return nil end
            if validIP(ip) then return ip end
            if requestInFlight then return nil end
        end
        if type(apiRequest) ~= "function" then return nil end
        local body = HttpService:JSONEncode({placeId = placeId, gameId = id,
            gameJoinAttemptId = id, isTeleport = false})
        local data = json(token, cfg, "POST", "https://gamejoin.roblox.com/v1/join-game-instance", body)
        local js = data and data.joinScript
        if type(js) ~= "table" then return nil end
        for _, key in ipairs({"UdmuxEndpoints", "ServerConnections"}) do
            if type(js[key]) == "table" then
                for _, endpoint in ipairs(js[key]) do
                    if type(endpoint) == "table" and validIP(endpoint.Address) then return endpoint.Address end
                end
            end
        end
        return validIP(js.MachineAddress) and js.MachineAddress or nil
    end
    local function rankIP(token, cfg, ip)
        for i, prefix in ipairs(cfg.PreferredIPPrefixes) do
            if ip:sub(1, #prefix) == prefix then return i, "IP 前缀 " .. prefix end
        end
        local cache = regionCache
        local country = cache[ip]
        if not country then
            local geo = json(token, cfg, "GET", cfg.CountryLookupUrl .. ip)
            if not alive(token) then return nil end
            country = geo and geo.success == true and geo.country_code
            if type(country) ~= "string" then return nil, "地区未知" end
            country = country:upper()
            cache[ip] = country
        end
        for i, wanted in ipairs(cfg.PreferredCountries) do
            if country == wanted then return i + #cfg.PreferredIPPrefixes, country end
        end
        return nil, country
    end
    local function candidates(token, cfg)
        local results, seen, cursors = {}, {}, {}
        local cursor
        for _ = 1, cfg.MaxServerPages do
            if not alive(token) then return {} end
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"):format(placeId)
            if cursor then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
            local data, reason = json(token, cfg, "GET", url)
            if not alive(token) then return {} end
            if not data or type(data.data) ~= "table" then return results, reason or "服务器列表格式错误" end
            status.Pages = status.Pages + 1
            for _, server in ipairs(data.data) do
                if type(server) == "table" then
                    local slots = (tonumber(server.maxPlayers) or 0) - (tonumber(server.playing) or 0)
                    local fps = tonumber(server.fps) or 0
                    local listPing = tonumber(server.ping)
                    if type(server.id) == "string" and server.id ~= "" and not blocked[server.id]
                        and not seen[server.id] and slots >= cfg.MinAvailableSlots and fps >= cfg.MinimumServerFPS then
                        seen[server.id] = true
                        results[#results + 1] = {id = server.id, slots = slots,
                            listPing = finite(listPing) and listPing >= 0 and listPing or nil}
                    end
                end
            end
            cursor = data.nextPageCursor
            if type(cursor) ~= "string" or cursor == "" or cursors[cursor] then break end
            cursors[cursor] = true
            if not pause(token, 0.4) then return {} end
        end
        table.sort(results, function(a, b)
            return (a.listPing or math.huge) < (b.listPing or math.huge)
        end)
        return results
    end
    local function search(token, cfg)
        local list, listError = candidates(token, cfg)
        if not alive(token) then return {} end
        if #list == 0 then return {}, listError or "没有可用的公共服务器" end
        local matches = {}
        for _, server in ipairs(list) do
            if not alive(token) or requestInFlight or status.IPChecks >= cfg.MaxIPLookups then break end
            status.IPChecks = status.IPChecks + 1
            local ip = resolve(token, cfg, server.id)
            if not alive(token) then return {} end
            if ip then
                status.ResolvedIPs = status.ResolvedIPs + 1
                local rank, country = rankIP(token, cfg, ip)
                if not alive(token) then return {} end
                if rank or not cfg.StrictRegion then
                    server.ip, server.country, server.rank = ip, country or "地区未知", rank or math.huge
                    matches[#matches + 1] = server
                end
            end
            emit("searching", "正在确认候选服务器 IP 与地区")
            if not pause(token, 0.4) then return {} end
        end
        table.sort(matches, function(a, b)
            if a.rank ~= b.rank then return a.rank < b.rank end
            return (a.listPing or math.huge) < (b.listPing or math.huge)
        end)
        if #matches > 0 then return matches end
        if status.ResolvedIPs == 0 then return {}, "IP 解析失败；未使用虚构 IP 或仅按列表延迟切服" end
        return {}, "没有已确认且符合偏好地区的 IP"
    end
    local failureConnection = TeleportService.TeleportInitFailed:Connect(function(who, result, message, failedPlace, options)
        local attempt = pendingTeleport
        if not running or not attempt or who ~= player or failedPlace ~= placeId then return end
        local identified = false
        if options then
            local ok, id = pcall(function() return options.ServerInstanceId end)
            if ok and type(id) == "string" and id ~= "" then
                if id ~= attempt.id then return end
                identified = true
            end
        end
        if attempt.failed then return end
        -- Legacy events without a target id are terminal, not a basis for chained retries.
        attempt.retryable = identified
        attempt.failed = "传送失败：" .. tostring(message or result)
        if attempt.uncertain then
            pendingTeleport = nil
            emit("failed", attempt.failed, {TeleportUncertain = false})
        end
    end)
    local function finish(token, phase, message)
        if not alive(token) then return end
        busy = false
        emit(phase, message)
        if alive(token) and type(notify) == "function" then pcall(notify, message) end
    end
    function controller:Switch()
        if not running then return false, "已停止" end
        if busy then return false, "正在搜索或传送" end
        if pendingTeleport then return false, "前次传送结果仍待确认，请勿重复切服" end
        if requestInFlight then return false, "前次请求仍在返回中" end
        if os.clock() - lastSearch < config.SwitchCooldownSeconds then return false, "切服冷却中" end
        busy, lastSearch, generation = true, os.clock(), generation + 1
        local token, cfg = generation, copy(config)
        highSamples = 0
        status.Pages, status.IPChecks, status.ResolvedIPs, status.Requests, status.TeleportAttempts = 0, 0, 0, 0, 0
        status.Target, status.LastError, status.TeleportUncertain = nil, nil, false
        emit("searching", "正在搜索低延迟地区服务器")
        task.spawn(function()
            local ok, err = pcall(function()
                local matches, reason = search(token, cfg)
                if not alive(token) then return end
                if #matches == 0 then finish(token, "failed", reason); return end
                for i = 1, math.min(#matches, cfg.MaxTeleportAttempts) do
                    if not alive(token) then return end
                    local target = matches[i]
                    local attempt = {id = target.id}
                    pendingTeleport = attempt
                    status.Target = {id = target.id, ip = target.ip, country = target.country,
                        listPing = target.listPing, slots = target.slots}
                    status.TeleportAttempts = i
                    emit("teleporting", "正在切服至 " .. target.country .. "；列表延迟仅作排序参考")
                    if not alive(token) then return end
                    blocked[target.id] = true
                    local deadline = os.clock() + cfg.TeleportTimeoutSeconds
                    task.spawn(function()
                        if not alive(token) or pendingTeleport ~= attempt then return end
                        attempt.dispatched = true
                        local sent, sendError = pcall(function()
                            TeleportService:TeleportToPlaceInstance(placeId, target.id, player)
                        end)
                        if not alive(token) or pendingTeleport ~= attempt then return end
                        if not sent and not attempt.failed then
                            attempt.failed = "传送调用失败：" .. tostring(sendError)
                            attempt.retryable = true
                            if attempt.uncertain then
                                pendingTeleport = nil
                                emit("failed", attempt.failed, {TeleportUncertain = false})
                            end
                        end
                    end)
                    while alive(token) and not attempt.failed and os.clock() < deadline do task.wait(0.1) end
                    if not alive(token) then return end
                    if not attempt.failed then
                        -- Absence of failure is not success. Never retry an outcome-unknown teleport.
                        attempt.uncertain = true
                        status.TeleportUncertain = true
                        finish(token, "uncertain", "传送等待超时，结果未确认；已阻止重复传送")
                        return
                    end
                    pendingTeleport = nil
                    status.LastError = attempt.failed
                    if not attempt.retryable or i >= math.min(#matches, cfg.MaxTeleportAttempts) then break end
                    emit("retrying", attempt.failed .. "；尝试下一候选服务器")
                    if not pause(token, cfg.RetryDelaySeconds) then return end
                end
                finish(token, "failed", status.LastError or "传送失败")
            end)
            if not ok and alive(token) then
                pendingTeleport = nil
                finish(token, "failed", "切服流程错误：" .. tostring(err))
            end
        end)
        return true
    end
    function controller:Stop()
        if not running then return end
        running, busy, generation = false, false, generation + 1
        config.AutoSwitch, highSamples = false, 0
        failureConnection:Disconnect()
        local dispatched = pendingTeleport and pendingTeleport.dispatched
        pendingTeleport = nil
        emit("stopped", dispatched and "已停止后续操作；已发出的传送由客户端处理" or "已停止切服与采样")
        listeners = {}
    end
    function controller:GetStatus()
        local snapshot = copy(status)
        snapshot.RequestInFlight = requestInFlight
        snapshot.HighSamples, snapshot.AutoSwitch = highSamples, config.AutoSwitch
        snapshot.CooldownRemaining = math.max(0, config.SwitchCooldownSeconds - (os.clock() - lastSearch))
        return snapshot
    end
    function controller:OnChange(fn)
        assert(type(fn) == "function", "OnChange expects a function")
        if not running then return function() end end
        listeners[fn] = true
        pcall(fn, self:GetStatus())
        return function() listeners[fn] = nil end
    end
    function controller:Config(patch)
        if patch == nil then return copy(config) end
        if not running then return false, "已停止" end
        if type(patch) ~= "table" then return false, "配置须为表" end
        local nextConfig = copy(config)
        for key, value in pairs(patch) do
            if bounds[key] then
                local range = bounds[key]
                if not finite(value) or value < range[1] or value > range[2] then return false, "配置数值越界：" .. key end
                nextConfig[key] = math.floor(value)
            elseif key == "AutoSwitch" or key == "StrictRegion" then
                if type(value) ~= "boolean" then return false, "配置须为布尔值：" .. key end
                nextConfig[key] = value
            elseif key == "PreferredCountries" or key == "PreferredIPPrefixes" then
                if type(value) ~= "table" or #value > 30 then return false, "地区配置格式错误" end
                local items = {}
                for _, item in ipairs(value) do
                    if type(item) ~= "string" or item == "" then return false, "地区配置格式错误" end
                    if key == "PreferredCountries" then
                        item = item:upper()
                        if not item:match("^[A-Z][A-Z]$") then return false, "国家代码须为两位字母" end
                    elseif not item:match("^%d[%d%.]*$") or #item > 15 then
                        return false, "IP 前缀格式错误"
                    end
                    items[#items + 1] = item
                end
                nextConfig[key] = items
            elseif key == "CountryLookupUrl" then
                if type(value) ~= "string" or not value:match("^https://") then return false, "地区接口须使用 HTTPS" end
                nextConfig[key] = value
            else return false, "未知配置：" .. tostring(key) end
        end
        if nextConfig.AutoSwitch ~= config.AutoSwitch then enabledAt = os.clock(); highSamples = 0 end
        if nextConfig.PingThresholdMs ~= config.PingThresholdMs or nextConfig.PingSamplesRequired ~= config.PingSamplesRequired then highSamples = 0 end
        if nextConfig.CountryLookupUrl ~= config.CountryLookupUrl then regionCache = {} end
        config = nextConfig
        emit(nil, nil)
        return true
    end
    local function set(key, value)
        local ok, reason = controller:Config({[key] = value})
        if not ok and type(notify) == "function" then pcall(notify, reason) end
    end
    paragraph = tab:AddParagraph({Title = "低延迟切服状态", Content = status.Message})
    tab:AddParagraph({Title = "切服说明", Content = "真实延迟来自客户端 GetNetworkPing 采样。服务器列表 ping 不是你的客户端延迟，也不保证换服后更低。默认严格确认 IP 地区；IP 失败则停止搜索，不虚构地区。冷却同时适用于手动与自动切服。"})
    tab:AddToggle("ServerSwitchAuto", {Title = "持续高延迟时自动切服", Default = false, Callback = function(v) set("AutoSwitch", v) end})
    tab:AddToggle("ServerSwitchStrictRegion", {Title = "严格匹配已确认 IP 地区", Default = true, Callback = function(v) set("StrictRegion", v) end})
    local sliders = {
        {"PingThresholdMs", "客户端延迟阈值（ms）"}, {"PingSamplesRequired", "连续高延迟采样次数"},
        {"SampleIntervalSeconds", "采样间隔（秒）"}, {"SwitchCooldownSeconds", "切服冷却（秒）"},
        {"MaxServerPages", "服务器列表页数预算"}, {"MaxIPLookups", "候选 IP 查询预算"},
        {"MinimumServerFPS", "最低服务器 FPS"},
    }
    for _, item in ipairs(sliders) do
        local key = item[1]
        tab:AddSlider("ServerSwitch" .. key, {Title = item[2], Min = bounds[key][1], Max = bounds[key][2],
            Default = config[key], Rounding = 0, Callback = function(v) set(key, v) end})
    end
    local function split(text)
        local items = {}
        for item in tostring(text):gmatch("[^,%s]+") do items[#items + 1] = item end
        return items
    end
    tab:AddInput("ServerSwitchCountries", {Title = "地区优先顺序（逗号分隔）", Default = "HK,JP,SG,TW,KR", Callback = function(v) set("PreferredCountries", split(v)) end})
    tab:AddInput("ServerSwitchIPPrefixes", {Title = "优先 IP 前缀（可留空）", Default = "", Callback = function(v) set("PreferredIPPrefixes", split(v)) end})
    tab:AddButton({Title = "立即搜索并切服", Callback = function()
        local ok, reason = controller:Switch()
        if not ok and type(notify) == "function" then pcall(notify, reason) end
    end})
    local function showSampleStatus()
        local text
        if not running then
            text = "此切服模块已停止，没有新的采样数据"
        else
            local snapshot = controller:GetStatus()
            local message = (type(snapshot.Message) == "string" and snapshot.Message ~= "") and snapshot.Message or "未采样"
            local ping = finite(snapshot.PingMs) and (tostring(math.floor(snapshot.PingMs * 100 + 0.5) / 100) .. " ms") or "未采样"
            local high = finite(snapshot.HighSamples) and tostring(math.floor(snapshot.HighSamples + 0.5)) or "未采样"
            local cooldown = finite(snapshot.CooldownRemaining) and (tostring(math.floor(snapshot.CooldownRemaining * 100 + 0.5) / 100) .. " 秒") or "未采样"
            text = table.concat({
                "切服采样状态：" .. message,
                "客户端延迟：" .. ping,
                "连续高延迟采样：" .. high .. "/" .. config.PingSamplesRequired,
                "切服冷却剩余：" .. cooldown,
                "请求进行中：" .. (snapshot.RequestInFlight and "是" or "否"),
                "自动切服：" .. (snapshot.AutoSwitch and "开启" or "关闭"),
            }, "\n")
        end
        if type(notify) == "function" then pcall(notify, text) else pcall(paragraph.SetDesc, paragraph, text) end
    end
    tab:AddButton({Title = "查看切服采样状态", Callback = showSampleStatus})
    tab:AddButton({Title = "停止此切服模块", Callback = function() controller:Stop() end})
    emit(nil, nil)
    task.spawn(function()
        while running do
            local ok, seconds = pcall(function() return player:GetNetworkPing() end)
            if not running then return end
            local ping = ok and finite(seconds) and seconds >= 0 and math.floor(seconds * 1000 + 0.5) or nil
            status.PingMs = ping
            local ready = config.AutoSwitch and os.clock() - enabledAt >= config.InitialDelaySeconds
            if ready and ping and ping >= config.PingThresholdMs then highSamples = highSamples + 1 else highSamples = 0 end
            emit(nil, nil)
            if running and config.AutoSwitch and highSamples >= config.PingSamplesRequired then
                controller:Switch()
                highSamples = 0
            end
            local deadline = os.clock() + config.SampleIntervalSeconds
            while running and os.clock() < deadline do task.wait(0.1) end
        end
    end)
    return controller
end

end)()
local RuntimeMonitorFactory = (function()
-- Vortexion R2.16: read-only, touch-transparent performance telemetry.
-- No screen-sized frames, buttons, modal capture or CoreGui modifications.
return function(tab, bridge)
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Stats = game:GetService("Stats")
    local localPlayer = Players.LocalPlayer
    local running, active, accumulator, frames = false, true, 0, 0
    local sampleInterval = 1
    local frameConnection, screenGui, label = nil, nil, nil
    local fps, minimum, maximum, samples = 0, math.huge, 0, 0
    local peakFrameMs, stutterCount, lastAverageFrameMs = 0, 0, 0
    local intervalFrameMs, intervalFrames = 0, 0
    local STUTTER_THRESHOLD_MS = 50
    local lastPing, lastMemory = nil, nil
    local startedAt = os.clock()

    local function elapsedString(seconds)
        local n = math.max(0, math.floor(seconds))
        return string.format("%02d:%02d:%02d", math.floor(n / 3600), math.floor(n / 60) % 60, n % 60)
    end
    local function textReport()
        return ("FPS %d [%d-%d] | %.1fms\nPING %s | RAM %s MB\nPEAK %.0fms | >50ms %d\nUP %s | UI %sHz"):format(
            fps, samples > 0 and minimum or 0, maximum, lastAverageFrameMs,
            lastPing and tostring(math.floor(lastPing + 0.5)) .. "ms" or "--",
            lastMemory and tostring(math.floor(lastMemory + 0.5)) or "--",
            peakFrameMs, stutterCount, elapsedString(os.clock() - startedAt),
            tostring(math.floor(tonumber(bridge.VisualHz) or 0)))
    end
    local function makeGui()
        if screenGui or not active then return end
        local parent
        pcall(function() parent = localPlayer:FindFirstChildOfClass("PlayerGui") end)
        if not parent then return end
        -- A stale HUD from an earlier executor run must not remain as an input overlay.
        pcall(function()
            local stale = parent:FindFirstChild("VortexionPerformanceHUD")
            if stale then stale:Destroy() end
        end)
        local gui = Instance.new("ScreenGui")
        gui.Name = "VortexionPerformanceHUD"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = false
        gui.DisplayOrder = -1000  -- Never compete with game / Roblox menus.
        pcall(function() gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets end)
        local content = Instance.new("TextLabel")
        content.Name = "Metrics"
        content.AnchorPoint = Vector2.new(1, 0)
        content.Position = UDim2.new(1, -6, 0, 5)
        content.Size = UDim2.fromOffset(0, 0)
        if Enum.AutomaticSize then content.AutomaticSize = Enum.AutomaticSize.XY end
        content.BackgroundColor3 = Color3.fromRGB(12, 16, 21)
        content.BackgroundTransparency = 0.45
        content.BorderSizePixel = 0
        content.TextColor3 = Color3.fromRGB(236, 241, 246)
        content.TextStrokeTransparency = 0.7
        content.Font = Enum.Font.Code
        content.TextSize = 12
        content.TextXAlignment = Enum.TextXAlignment.Left
        content.TextYAlignment = Enum.TextYAlignment.Top
        content.TextWrapped = false
        content.Text = textReport()
        content.Active = false
        content.Selectable = false
        pcall(function() content.Interactable = false end)
        pcall(function() content.InputSink = Enum.InputSink.None end)
        -- Padding belongs to the text itself: no oversized backdrop frame.
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 3)
        padding.PaddingRight = UDim.new(0, 3)
        padding.PaddingTop = UDim.new(0, 2)
        padding.PaddingBottom = UDim.new(0, 2)
        padding.Parent = content
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 3)
        corner.Parent = content
        content.Parent = gui
        local ok = pcall(function() gui.Parent = parent end)
        if not ok or not gui.Parent then gui:Destroy(); return end
        screenGui, label = gui, content
    end
    local function snapshot()
        return {
            fps = fps, minFps = samples > 0 and minimum or 0, maxFps = maximum,
            avgFrameMs = lastAverageFrameMs, peakFrameMs = peakFrameMs,
            stutters = stutterCount, pingMs = lastPing, memoryMb = lastMemory,
            samples = samples, uptimeSeconds = math.floor(os.clock() - startedAt),
            gameId = game.GameId, placeId = game.PlaceId,
        }
    end
    local function update(dt)
        if not active or not running then return end
        local delta = tonumber(dt)
        if not delta or delta ~= delta or delta < 0 or delta == math.huge then return end
        local ms = delta * 1000
        peakFrameMs = math.max(peakFrameMs, ms)
        if ms >= STUTTER_THRESHOLD_MS then stutterCount += 1 end
        intervalFrameMs += ms
        intervalFrames += 1
        frames += 1
        accumulator += math.min(delta, 0.5)
        if accumulator < sampleInterval then return end
        fps = accumulator > 0 and math.floor(frames / accumulator + 0.5) or 0
        minimum, maximum = math.min(minimum, fps), math.max(maximum, fps)
        samples += 1
        lastAverageFrameMs = intervalFrames > 0 and intervalFrameMs / intervalFrames or 0
        frames, accumulator, intervalFrameMs, intervalFrames = 0, 0, 0, 0
        local okPing, ping = pcall(function() return localPlayer:GetNetworkPing() * 1000 end)
        if okPing and type(ping) == "number" and ping >= 0 and ping < math.huge then lastPing = ping end
        local okMemory, mem = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
        if okMemory and type(mem) == "number" and mem >= 0 and mem < math.huge then lastMemory = mem end
        if label and label.Parent then label.Text = textReport() end
    end
    local function stop()
        running = false
        if frameConnection then frameConnection:Disconnect(); frameConnection = nil end
        if screenGui then screenGui:Destroy(); screenGui = nil; label = nil end
        accumulator, frames = 0, 0
    end
    local function resetSamples()
        fps, minimum, maximum, samples = 0, math.huge, 0, 0
        peakFrameMs, stutterCount, lastAverageFrameMs = 0, 0, 0
        frames, accumulator, intervalFrameMs, intervalFrames = 0, 0, 0, 0
        lastPing, lastMemory = nil, nil
        startedAt = os.clock()
        if label and label.Parent then label.Text = textReport() end
    end
    local function setEnabled(value)
        if not active then return end
        if not value then stop(); return end
        if running then return end
        makeGui()
        if not screenGui then
            bridge:Notify({Title = "性能监控", Content = "PlayerGui HUD 创建失败", Duration = 4})
            return
        end
        running = true
        frameConnection = RunService.Heartbeat:Connect(update)
    end
    tab:AddParagraph({Title = "性能与触控", Content = "紧凑 HUD 只含文本及 2-3px 内边距；位于系统安全区，不接收触摸，不修改 Roblox 菜单。"})
    tab:AddToggle("VortexionPerfHUD", {Title = "显示性能 HUD", Default = false, Callback = setEnabled})
    tab:AddSlider("VortexionPerfSampleSeconds", {Title = "采样间隔（秒）", Min = 1, Max = 5, Default = 1, Rounding = 0,
        Callback = function(v)
            local n = tonumber(v)
            if not n or n ~= n or n == math.huge or n == -math.huge then n = 1 end
            sampleInterval = math.max(1, math.min(5, n))
        end})
    tab:AddButton({Title = "紧急关闭性能 HUD（排查 Roblox 菜单）", Callback = function()
        stop()
        local option = bridge.Options and bridge.Options.VortexionPerfHUD
        if option and option.SetValue then option:SetValue(false) end
    end})
    tab:AddButton({Title = "重置性能采样", Callback = resetSamples})
    tab:AddButton({Title = "复制性能诊断", Callback = function()
        local s = snapshot()
        local info = ("Vortexion Runtime\nGameId=%s PlaceId=%s\nFPS=%d min=%d max=%d\nFrameAvgMs=%.2f FramePeakMs=%.2f Stutters(>=50ms)=%d\nPing=%s Memory=%s Samples=%d Uptime=%ds")
            :format(tostring(s.gameId), tostring(s.placeId), s.fps, s.minFps, s.maxFps,
                s.avgFrameMs, s.peakFrameMs, s.stutters,
                tostring(s.pingMs or "unavailable"), tostring(s.memoryMb or "unavailable"), s.samples, s.uptimeSeconds)
        local copy = type(setclipboard) == "function" and setclipboard or type(toclipboard) == "function" and toclipboard
        if copy then
            local ok = pcall(copy, info)
            bridge:Notify({Title = "性能诊断", Content = ok and "已复制" or "复制失败，详见控制台", Duration = 4})
        else
            warn(info)
            bridge:Notify({Title = "性能诊断", Content = "无剪贴板接口，已输出到控制台", Duration = 4})
        end
    end})
    bridge:OnDestroy(function() active = false; stop() end)
    return {GetSnapshot = snapshot, Stop = stop, Reset = resetSamples}
end

end)()
local WindBridgeFactory = (function()
-- Vortexion Neverlose bridge. All existing game feature IDs and module APIs are preserved.
-- The shared UI is vendored offline; no HttpGet dependency at runtime.
return function(Neverlose, config)
    config = config or {}
    assert(type(Neverlose) == "table" and type(Neverlose.Window) == "function", "Neverlose UI unavailable")
    local env = config.Env or ((type(getgenv) == "function" and getgenv()) or _G)
    local UIS = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local GuiService = game:GetService("GuiService")
    local Workspace = game:GetService("Workspace")
    local HttpService = game:GetService("HttpService")
    local mobile = UIS.TouchEnabled
    local callbacks, connections, health, recent = {}, {}, {}, {}
    local window, root, scale, viewportCamera, cameraConn = nil, nil, nil, nil, nil
    local createdPages, selectedPage = {}, ""
    local resizing, lastViewport, lastInsets = false, "", ""
    local uiScale = 1
    local stats = {callbacks=0, inputs=0, errors=0, repairs=0, resizes=0}
    local bridge = {Active=true, Library=Neverlose, Options={}, Tabs={}, GameTabs={}, GUI=Neverlose.Holder and Neverlose.Holder.Instance,
        VisualHz=mobile and 30 or 60, NativeNoticesEnabled=not mobile, NoticeHistory={}, AutoFit=true, SafeArea=true,
        Trace=false, Debug=config.Debug == true, TouchMode=mobile and "手指" or "鼠标"}
    env.VortexionWindBridge = bridge -- backwards-compatible key, used for old bundle teardown
    env.VortexionNeverloseBridge = bridge

    local function copy(t)
        if type(t) ~= "table" then return t end
        local r = {}; for k,v in pairs(t) do r[k]=copy(v) end; return r
    end
    local function same(a,b)
        if type(a) ~= type(b) then return false end
        if type(a) ~= "table" then return a == b end
        for k,v in pairs(a) do if not same(v,b[k]) then return false end end
        for k in pairs(b) do if a[k]==nil then return false end end
        return true
    end
    local function finite(n, default)
        n = tonumber(n)
        if not n or n~=n or math.abs(n)==math.huge then return default end
        return n
    end
    local function clamp(n, lo, hi) return math.max(lo,math.min(hi,n)) end
    local function fire(fn,...)
        if type(fn) ~= "function" then return true end
        stats.callbacks=stats.callbacks+1
        local ok,err=pcall(fn,...)
        if not ok then
            stats.errors=stats.errors+1; bridge.LastError=tostring(err)
            warn("[Vortexion/Neverlose] "..tostring(err))
        end
        return ok
    end
    function bridge:Notify(info, message, duration)
        local title,desc,seconds
        if type(info)=="table" then
            title=tostring(info.Title or "Vortexion")
            desc=tostring(info.Content or info.Description or "")
            seconds=finite(info.Duration,4)
        else title=tostring(info or "Vortexion"); desc=tostring(message or ""); seconds=finite(duration,4) end
        local record=(title..": "..desc):sub(1,1500)
        self.NoticeHistory[#self.NoticeHistory+1]=record
        if #self.NoticeHistory>20 then table.remove(self.NoticeHistory,1) end
        if not self.NativeNoticesEnabled then print("[Vortexion/Notice] "..record); return end
        local ok,err=pcall(function() Neverlose:Notify({Title=title,Text=desc,Time=seconds,AutoClose=true}) end)
        if not ok then self.LastError=tostring(err) end
    end
    local function trace(id,from,v,ok)
        recent[#recent+1]=(from.." "..tostring(id).."="..tostring(v).." "..tostring(ok)):sub(1,220)
        if #recent>24 then table.remove(recent,1) end
        if bridge.Trace then print("[Vortexion/Neverlose/Trace] "..recent[#recent]) end
    end
    function bridge:FeatureTrace() return #recent>0 and table.concat(recent,"\n") or "暂无控件事件" end
    function bridge:OnDestroy(fn)
        if self.Active then callbacks[#callbacks+1]=fn else fire(fn) end
    end
    function bridge:Destroy()
        if not self.Active then return end
        self.Active=false
        if self.ServerSwitch then pcall(function() self.ServerSwitch:Stop() end) end
        for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        for _,fn in ipairs(callbacks) do fire(fn) end
        table.clear(callbacks); table.clear(connections); table.clear(health)
        if env.VortexionWindBridge==self then env.VortexionWindBridge=nil end
        if env.VortexionNeverloseBridge==self then env.VortexionNeverloseBridge=nil end
        pcall(function() if Neverlose.Root then Neverlose.Root:Destroy() end end)
        window=nil; root=nil
    end
    bridge.Window=function() return window end
    function bridge:RegisterFeatureHealth(name,fn)
        if not self.Active or type(fn)~="function" then return false end
        health[tostring(name)]=fn; return true
    end
    function bridge:FeatureHealth()
        local out={}
        for name,fn in pairs(health) do
            local ok,v=pcall(fn)
            out[#out+1]=name..": "..(ok and tostring(v) or ("ERROR: "..tostring(v)))
        end
        table.sort(out)
        return #out>0 and table.concat(out,"\n") or "暂无游戏模块状态报告"
    end
    function bridge:GetVisualInterval(base)
        return math.max(finite(base,0),1/clamp(finite(self.VisualHz,30),5,60))
    end
    -- Read native state, including user tap updates. Never overwrite the user's
    -- last action with an older programmatic Set() or repeated default callback.
    function bridge:ReconcileGameplayOptions()
        local repaired=0
        if not self.Active then return 0 end
        for _,item in pairs(self.Options) do
            if item.Kind=="Toggle" and item.Native and (type(item.Native.Get)=="function" or item.Native.Value~=nil) then
                local ok,value=pcall(function() return item.Native:Get() end)
                if ok and type(value)=="boolean" and value~=item.Value then
                    if item:SyncFromNative() then repaired=repaired+1 end
                end
            end
        end
        stats.repairs=stats.repairs+repaired
        return repaired
    end
    local clock=0
    connections[#connections+1]=RunService.Heartbeat:Connect(function(dt)
        if not bridge.Active then return end
        clock=clock+clamp(finite(dt,0),0,0.5)
        if clock>=1 then
            clock=0
            bridge:ReconcileGameplayOptions()
            if bridge.RefreshDiagnostics then bridge:RefreshDiagnostics() end
        end
    end)

    local function readInsets()
        if not bridge.SafeArea then return 0,0,0,0 end
        local ok,t,b=pcall(function()return GuiService:GetGuiInset() end)
        if not ok or not t or not b then return 0,0,0,0 end
        return math.max(0,t.X), math.max(0,t.Y), math.max(0,b.X), math.max(0,b.Y)
    end
    -- Original library geometry: 203 px left navigation + 643 px main canvas,
    -- both at 682 px high. Never collapse columns or alter the Section tree.
    function bridge:FitViewport()
        if not self.Active or not root or not scale or not self.AutoFit then return end
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local view=cam.ViewportSize
        if finite(view.X,0)<100 or finite(view.Y,0)<100 then return end
        local l,t,r,b=readInsets()
        local width=math.max(1,view.X-l-r)
        local height=math.max(1,view.Y-t-b)
        local fit=math.min((width-8)/846,(height-8)/682,1.18)
        local applied=clamp(math.min(fit*1.08*uiScale,(width-8)/846,(height-8)/682),0.2,1.4)
        local key=('%d:%d:%d:%d:%.3f'):format(width,height,l,t,applied)
        if key==lastViewport then return end
        lastViewport=key
        scale.Scale=applied
        root.AnchorPoint=Vector2.new(0,0)
        root.Size=UDim2.fromOffset(643,682)
        root.Position=UDim2.fromOffset(l+(width-846*applied)/2+203*applied,t+(height-682*applied)/2)
        self.LastViewport=('%dx%d · %.0f%% · 原生双列'):format(width,height,applied*100)
        stats.resizes=stats.resizes+1
    end
    local function bindCamera()
        if cameraConn then cameraConn:Disconnect();cameraConn=nil end
        local cam=Workspace.CurrentCamera
        if cam then
            cameraConn=cam:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                lastViewport='';bridge:FitViewport()
            end)
            connections[#connections+1]=cameraConn
        end
        lastViewport='';bridge:FitViewport()
    end

    local tabGroup
    -- Uses asset IDs shipped by this Neverlose UI library (not HTTP icon packs).
    local navIcons = {
        Aim='6031097226', Combat='6031097226', Visual='6035181869',
        Setting='6031280882', Script='6026663699', Other='6034230648',
        Reload='6031097226', Info='6035181869', Move='6035067832'
    }
    local function pageIcon(name)
        local n=tostring(name):lower()
        local key='Other'
        if n:find('瞄') or n:find('rage') or n:find('战斗') or n:find('射') then key='Aim'
        elseif n:find('esp') or n:find('视觉') or n:find('显示') or n:find('感知') then key='Visual'
        elseif n:find('移动') or n:find('速度') or n:find('飞行') then key='Move'
        elseif n:find('脚本') or n:find('代码') then key='Script'
        elseif n:find('设置') or n:find('配置') or n:find('调试') or n:find('界面') then key='Setting'
        elseif n:find('信息') then key='Info' end
        return 'rbxassetid://'..navIcons[key]
    end
    local function createTab(pageName,icon,category)
        -- Preserves native left navigation: TSection -> Tab -> alternating Section.
        if category or not tabGroup then
            tabGroup=window.Native:TSection(category or '游戏功能')
        end
        local sourcePage=tabGroup:Tab(pageName,pageIcon(pageName))
        local tab={Native=sourcePage,Title=pageName,OptionCount=0,Sections={}}
        local headings
        if pageName:find('视觉') or pageName:find('ESP') or pageName:find('感知') then
            headings={'Main','Players ESP','World ESP','Other'}
        elseif pageName:find('战斗') or pageName:find('自瞄') then
            headings={'Main','Targeting','Advanced','Other'}
        elseif pageName:find('世界') then
            headings={'Main','World','Visual','Other'}
        else
            headings={'Main','Settings','Advanced','Other'}
        end
        local sectionLimit=8
        local function newSection()
            local n=#tab.Sections+1
            local name=headings[math.min(n,#headings)]
            if n>#headings then name='Other · '..tostring(n-#headings+1) end
            local native=sourcePage:Section(name)
            tab.Sections[#tab.Sections+1]=native
            return native
        end
        local function sectionFor()
            if #tab.Sections==0 or tab.OptionCount>1 and (tab.OptionCount-1)%sectionLimit==0 then
                return newSection()
            end
            return tab.Sections[#tab.Sections]
        end
        local function addOption(kind,id,c)
            c=c or {};id=tostring(id)
            assert(bridge.Options[id]==nil,'重复选项 ID: '..id)
            local values=copy(c.Values or {})
            local low,high=finite(c.Min,0),finite(c.Max,100)
            local decimals=clamp(math.floor(finite(c.Rounding,0)),0,3)
            if kind=='Slider' then assert(low<high,'Invalid slider range: '..id) end
            local step=10^(-decimals)
            local function normalize(v)
                if kind=='Toggle' then return v==true end
                if kind=='Input' then return tostring(v==nil and '' or v) end
                if kind=='Slider' then
                    local n=clamp(finite(v,low),low,high)
                    return clamp(math.floor(n/step+0.5)*step,low,high)
                end
                if kind=='Colorpicker' then return typeof(v)=='Color3' and v or Color3.fromRGB(0,195,255) end
                if c.Multi then return type(v)=='table' and copy(v) or (v==nil and {} or {v}) end
                if type(v)=='number' then v=values[v] end
                if v==nil then return values[1] end
                return v
            end
            local initial=normalize(c.Default)
            local option={ID=id,Kind=kind,Value=copy(initial),Values=values,listeners={}}
            bridge.Options[id]=option
            local ready=false
            local initialized=false
            local function propagate(v,origin)
                if not bridge.Active and not bridge.Cleaning then return false end
                v=normalize(v)
                if initialized and same(v,option.Value) then return false end
                initialized=true
                option.Value=copy(v)
                trace(id,origin,v,'received')
                local success=fire(c.Callback,copy(v))
                trace(id,origin,v,success and 'OK' or 'ERROR')
                for _,fn in ipairs(option.listeners) do fire(fn,copy(v)) end
                return true
            end
            local function changed(v)
                if not ready or not bridge.Active then return end
                stats.inputs=stats.inputs+1
                propagate(v,'native')
            end
            tab.OptionCount=tab.OptionCount+1
            local section=sectionFor()
            local label=tostring(c.Title or id)
            -- Native Neverlose (Mana42138) controls take positional arguments.
            if kind=='Toggle' then
                option.Native=section:Toggle(label,changed)
            elseif kind=='Slider' then
                option.Native=section:Slider(label,low,high,finite(initial,low),changed)
            elseif kind=='Dropdown' then
                if c.Multi then
                    -- Original library has no multi-dropdown; use a single dropdown
                    -- with a text summary while retaining the existing table API.
                    option.Native=section:Dropdown(label,values,function(v)
                        local nextSelection=copy(option.Value)
                        if type(nextSelection)~='table' then nextSelection={} end
                        local found=false
                        for i,x in ipairs(nextSelection) do
                            if x==v then table.remove(nextSelection,i);found=true;break end
                        end
                        if not found then nextSelection[#nextSelection+1]=v end
                        changed(nextSelection)
                    end)
                else
                    option.Native=section:Dropdown(label,values,changed)
                end
            elseif kind=='Input' then
                option.Native=section:TextBox(label,changed)
            elseif kind=='Colorpicker' then
                option.Native=section:Colorpicker(label,initial,changed)
            end
            function option:GetValue() return copy(self.Value) end
            function option:GetNativeValue()
                if not self.Native then return copy(self.Value) end
                if self.Kind=='Dropdown' and c.Multi then return copy(self.Value) end
                local ok,v=pcall(function()
                    if type(self.Native.Get)=='function' then return self.Native:Get() end
                    return self.Native.Value
                end)
                return ok and v~=nil and normalize(v) or copy(self.Value)
            end
            function option:SyncFromNative()
                return propagate(self:GetNativeValue(),'audit')
            end
            function option:SetValue(v)
                if not bridge.Active and not bridge.Cleaning then return false end
                v=normalize(v)
                if same(v,self.Value) then return true end
                if bridge.Cleaning then return propagate(v,'cleanup') end
                local ok,err=pcall(function()
                    if self.Native and type(self.Native.Set)=='function' then
                        if self.Kind=='Dropdown' and c.Multi then
                            self.Native:Set(table.concat(v,', '))
                        elseif v~=nil then self.Native:Set(v) end
                    end
                end)
                if not ok then bridge.LastError=tostring(err) end
                -- Keep original feature callbacks and ID even when native Set fails.
                propagate(v,'setvalue')
                return ok
            end
            function option:SetValues(new)
                if not bridge.Active or kind~='Dropdown' or type(new)~='table' then return false end
                values=copy(new);self.Values=copy(new)
                local ok,err=pcall(function()
                    if self.Native and type(self.Native.Refresh)=='function' then self.Native:Refresh(values) end
                end)
                if not ok then bridge.LastError=tostring(err); return false end
                if not c.Multi then
                    local valid=false
                    for _,entry in ipairs(values) do if entry==self.Value then valid=true;break end end
                    if not valid then
                        if values[1] then self:SetValue(values[1])
                        else propagate(nil,'refresh-empty') end
                    end
                end
                return true
            end
            function option:OnChanged(fn)
                if type(fn)=='function' then
                    self.listeners[#self.listeners+1]=fn
                    if bridge.Active then fire(fn,copy(self.Value)) end
                end
                return self
            end
            ready=true
            -- Original library expects :Set to update visuals, but callbacks
            -- are protected until after widget construction.
            if option.Native and type(option.Native.Set)=='function' and initial~=nil and not (kind=='Dropdown' and c.Multi) then
                local ok,err=pcall(function()option.Native:Set(initial)end)
                if not ok then bridge.LastError=tostring(err) end
            end
            propagate(initial,'initial')
            return option
        end
        for _,kind in ipairs({'Toggle','Slider','Dropdown','Input','Colorpicker'}) do
            tab['Add'..kind]=function(_,id,c)return addOption(kind,id,c)end
        end
        function tab:AddButton(info)
            info=info or {};self.OptionCount=self.OptionCount+1
            return sectionFor():Button(tostring(info.Title or '运行'),function()
                if bridge.Active and not info.Locked then fire(info.Callback) end
            end)
        end
        function tab:AddParagraph(info)
            info=info or {};self.OptionCount=self.OptionCount+1
            return sectionFor():Paragraph(info.Title or '说明',info.Content or info.Desc or '')
        end
        bridge.Tabs[#bridge.Tabs+1]=tab
        return tab
    end

    local function installSettings()
        local appearance=createTab('界面与布局',nil,'VORTEXION · UI')
        local diagnostics=createTab('UI 调试')
        local configuration=createTab('配置')
        bridge.SettingsTabs={['主题']=appearance,['界面']=appearance,['调试']=diagnostics,['配置']=configuration}
        appearance:AddParagraph({Title='Neverlose · 原生排列', Content='保持侧栏和两列 Section 结构。适配只改变整体缩放和触控区域，不改控件位置。'})
        appearance:AddParagraph({Title='图标资源',Content=tostring(bridge.BrandMode or '读取中')})
        appearance:AddToggle('nl_auto_fit',{Title='自适应屏幕',Default=true,Callback=function(v)bridge.AutoFit=v;lastViewport='';bridge:FitViewport()end})
        appearance:AddToggle('nl_safe_area',{Title='屏幕安全区域',Default=true,Callback=function(v)bridge.SafeArea=v;lastViewport='';bridge:FitViewport()end})
        appearance:AddSlider('nl_scale',{Title='界面缩放',Min=60,Max=160,Default=100,Callback=function(v)uiScale=v/100;lastViewport='';bridge:FitViewport()end})
        appearance:AddButton({Title='恢复窗口位置',Callback=function()lastViewport='';bridge:FitViewport()end})
        appearance:AddToggle('nl_notifications',{Title='屏幕通知',Default=not mobile,Callback=function(v)bridge.NativeNoticesEnabled=v end})
        appearance:AddDropdown('nl_visual_hz',{Title='画面更新频率',Values={'原速','均衡','省电'},Default='均衡',Callback=function(v)bridge.VisualHz=({['原速']=60,['均衡']=30,['省电']=10})[v] or 30 end})
        local debug=diagnostics:AddParagraph({Title='触控与回调状态',Content='等待初始化'})
        function bridge:RefreshDiagnostics()
            debug:SetDesc(self:GetDiagnostics())
        end
        diagnostics:AddButton({Title='输出全部模块运行状态',Callback=function()print(bridge:FeatureHealth())end})
        diagnostics:AddButton({Title='最近控件事件',Callback=function()print(bridge:FeatureTrace())end})
        diagnostics:AddToggle('nl_trace',{Title='跟踪控件回调',Default=false,Callback=function(v)bridge.Trace=v end})
        diagnostics:AddButton({Title='重新同步开关',Callback=function()
            local n=bridge:ReconcileGameplayOptions()
            bridge:Notify('状态校验','同步 '..n..' 项')
        end})
        diagnostics:AddButton({Title='测试触控反馈',Callback=function()
            bridge.LastTouchProbe='点击成功 '..tostring(os.clock())
            bridge:Notify('触控测试','Neverlose 点击已收到')
            bridge:RefreshDiagnostics()
        end})
        bridge.GetDiagnostics=function()
            local n=0;for _ in pairs(bridge.Options)do n=n+1 end
            return ('%s | %s | %s | %d 个控件 | %d 回调 | %d 错误 | %s')
                :format(bridge.UIBackend or '未初始化',bridge.TouchMode,bridge.LastViewport or '等待视口',n,stats.callbacks,stats.errors,bridge.LastError or '无')
        end
        local configName=configuration:AddInput('nl_config_name',{Title='配置名称',Default='default'})
        local function configPath()
            local name=tostring(configName.Value or 'default')
            name=name:match('^[%w_%-]+$') and name or 'default'
            return 'VortexionR227_'..name..'.json'
        end
        configuration:AddButton({Title='保存配置',Callback=function()
            if type(writefile)~='function' then bridge:Notify('配置','执行器不支持 writefile');return end
            local serialized={}
            for id,opt in pairs(bridge.Options) do
                if id~='nl_config_name' and opt.Kind~='Colorpicker' then serialized[id]=opt.Value end
            end
            local ok,err=pcall(function()writefile(configPath(),HttpService:JSONEncode(serialized))end)
            bridge:Notify('配置',ok and '保存成功' or tostring(err))
        end})
        configuration:AddButton({Title='加载配置',Callback=function()
            if type(readfile)~='function' then bridge:Notify('配置','执行器不支持 readfile');return end
            local ok,count=pcall(function()
                local data=HttpService:JSONDecode(readfile(configPath()))
                local changed=0
                for id,value in pairs(data) do
                    local opt=bridge.Options[id]
                    if opt and opt:SetValue(value) then changed=changed+1 end
                end
                return changed
            end)
            bridge:Notify('配置',ok and ('读取 '..count..' 项') or tostring(count))
        end})
    end

    function bridge:CreateWindow(info)
        if window then return window end
        if not self.Active then return nil end
        info=info or {}
        local deadline=os.clock()+6
        while not Workspace.CurrentCamera and self.Active and os.clock()<deadline do task.wait(0.05) end
        assert(Workspace.CurrentCamera,'Neverlose requires CurrentCamera')
        local brandAsset,brandReason
        if type(VortexionLogoAssetFactory)=='function' then
            local okLogo, logoOrError, reason = pcall(VortexionLogoAssetFactory)
            if okLogo then brandAsset,brandReason=logoOrError,reason
            else brandAsset=nil;brandReason='图标不可用: '..tostring(logoOrError) end
        end
        self.BrandMode=brandReason or '默认 Roblox 图标'
        -- R229: keep the original visual library as the preferred path. Its
        -- constructor can throw on Android before returning a window handle.
        -- Capture that error, then create a separate functional dual-column UI.
        local okNative, nativeOrError = xpcall(function()
            return Neverlose:Window({Title='VORTEXION',CFG='Vortexion',Key=Enum.KeyCode.RightControl,
                External={KeySystem=false,Key={}}})
        end, function(error)
            if type(debug)=='table' and type(debug.traceback)=='function' then
                return debug.traceback(tostring(error),2)
            end
            return tostring(error)
        end)
        local native
        if okNative and nativeOrError and Neverlose.MainFrame and Neverlose.Root then
            native = nativeOrError
            self.UIBackend = 'Neverlose'
        else
            local reason = okNative and 'Native UI returned an incomplete window/root' or tostring(nativeOrError)
            self.NativeError = reason:sub(1,1800)
            self.LastError = self.NativeError
            env.VortexionNativeUIError = self.NativeError
            warn('[Vortexion/Neverlose] Native UI failed, entering dual-column fallback: '..self.NativeError)
            -- The failed vendor may have left partially constructed GUI objects.
            pcall(function() if Neverlose.Root then Neverlose.Root:Destroy() end end)
            local okFallback, result = pcall(EmergencyWindowFactory, Neverlose, self.NativeError)
            if not okFallback or not result then
                error('Both native and emergency UI failed. Native: '..self.NativeError
                    ..'; fallback: '..tostring(result))
            end
            native=result
            self.UIBackend='EmergencyNeverlose'
            self.BootStatus='partial'
            self.BootError='原生 Neverlose 创建失败，已启用双列兼容 UI: '..self.NativeError
            self.NativeNoticesEnabled=false
        end
        root=Neverlose.MainFrame
        assert(root,'Neverlose native MainFrame unavailable')
        scale=Instance.new('UIScale');scale.Name='VortexionMobileScale';scale.Scale=1;scale.Parent=root
        self.GUI=Neverlose.Root
        if not self.UIBackend then self.UIBackend='Neverlose' end
        if brandAsset and Neverlose.Root then
            local image=Neverlose.Root:FindFirstChild('PlayerImage',true)
            if image and image:IsA('ImageLabel') then image.Image=brandAsset end
        end
        window={Native=native,Root=root,GameTabs=bridge.GameTabs}
        function window:AddTab(data)
            data=data or {}
            local page=createTab(tostring(data.Title or '功能'))
            bridge.GameTabs[#bridge.GameTabs+1]=page
            return page
        end
        function window:SelectTab(i)
            local tab=bridge.GameTabs[i]
            if not bridge.Active or not tab then return end
            selectedPage=tab.Title
            tab.Native:Select()
        end
        function window:Minimize()Neverlose:VisMain(false)end
        function window:Destroy()bridge:Destroy()end
        function window:InstallSettings()end
        local decorationsOk, decorationsError = pcall(function()
        -- Header-only drag: touching sliders, tabs and the content itself never
        -- moves the window. Works even if the user chooses a zoomed native layout.
        local title=root:FindFirstChild('TitleMain',true)
        if title then
            title.Active=true
            local dragStart,basePosition,dragInput
            local function start(input)
                if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                    dragInput=input;dragStart=input.Position;basePosition=root.Position
                end
            end
            connections[#connections+1]=title.InputBegan:Connect(start)
            connections[#connections+1]=UIS.InputChanged:Connect(function(input)
                if not dragInput then return end
                if input~=dragInput and not (dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then return end
                local delta=input.Position-dragStart
                root.Position=UDim2.fromOffset(basePosition.X.Offset+delta.X,basePosition.Y.Offset+delta.Y)
            end)
            connections[#connections+1]=UIS.InputEnded:Connect(function(input)
                if input==dragInput or dragInput and dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1 then dragInput=nil end
            end)
        end
        -- Fixed-position reopening affordance when native menu is hidden.
        local reopen=Instance.new('TextButton')
        reopen.Name='VortexionReopen';reopen.Text='V';reopen.TextSize=22
        reopen.Font=Enum.Font.GothamBold
        reopen.BackgroundColor3=Color3.fromRGB(14,39,61)
        reopen.TextColor3=Color3.fromRGB(145,207,234)
        reopen.Size=UDim2.fromOffset(46,46)
        reopen.Position=UDim2.fromOffset(24,80)
        reopen.Parent=Neverlose.Root
        connections[#connections+1]=reopen.MouseButton1Click:Connect(function()
            root.Visible=not root.Visible
        end)
        end) -- optional window drag and re-open controls
        if not decorationsOk then
            self.LastError='Window decorations: '..tostring(decorationsError)
            self.BootStatus='partial'; self.BootError=self.LastError
            warn('[Vortexion/Neverlose] '..self.LastError)
        end
        local commonOk, commonError = pcall(function()
        -- All common modules use identical AddTab and Add* controls.
        local common=createTab('低延迟切服',nil,'VORTEXION · COMMON')
        local serverFactory=config.ServerSwitchFactory or ServerSwitchFactory
        if type(serverFactory)=='function' then
            local ok,v=pcall(serverFactory,common,function(msg)bridge:Notify('低延迟切服',msg)end)
            if ok then bridge.ServerSwitch=v else bridge.LastError=tostring(v) end
        end
        local perf=createTab('性能诊断')
        if type(RuntimeMonitorFactory)=='function' then
            local ok,v=pcall(RuntimeMonitorFactory,perf,bridge)
            if ok then bridge.RuntimeMonitor=v else bridge.LastError=tostring(v) end
        end
        installSettings()
        bridge:RefreshDiagnostics()
        end) -- optional shared settings and performance pages
        if not commonOk then
            self.LastError='Common UI settings: '..tostring(commonError)
            self.BootStatus='partial'
            self.BootError=(self.BootError and (self.BootError..'; ') or '')..self.LastError
            warn('[Vortexion/Neverlose] '..self.LastError)
        end
        connections[#connections+1]=Workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(bindCamera)
        bindCamera()
        local ok,inset=pcall(function()return GuiService:GetPropertyChangedSignal('TopbarInset')end)
        if ok and inset then connections[#connections+1]=inset:Connect(function()lastViewport='';bridge:FitViewport()end) end
        return window
    end
    return bridge
end

end)()
local GameRouter = (function()
-- Exact experience routing, independent from game feature initialization.
local Router = {}
local UNIVERSE_ROUTES = {
    [6331902150] = "Forsaken",
    [7633926880] = "BloxStrike",
    [1742264997] = "SCP",
}
local PLACE_FALLBACK = {
    [18687417158] = "Forsaken",
    [114234929420007] = "BloxStrike",
    [5041144419] = "SCP",
}
local AOTR_UNIVERSE = 4658598196
local AOTR_PLACES = {
    [13379208636] = "AOTR_Lobby",
    [14916516914] = "AOTR_Lobby",
    [13379349730] = "AOTR_Battle",
    [14638336319] = "AOTR_Battle",
    [14012874501] = "AOTR_Battle",
    [13904207646] = "AOTR_Battle",
}

function Router.Resolve(universe, place)
    universe, place = tonumber(universe), tonumber(place)
    -- Do not fall through to another game from an unknown AOTR scene.
    if universe == AOTR_UNIVERSE then
        local entry = AOTR_PLACES[place]
        return entry, entry and "aotr-place" or "unsupported-aotr-scene"
    end
    local entry = UNIVERSE_ROUTES[universe]
    if entry then return entry, "universe" end
    entry = PLACE_FALLBACK[place]
    return entry, entry and "place-fallback" or "unsupported-experience"
end

function Router.ShowUnsupported(WindUI, WindBridgeFactory, universe, place, reason, detail)
    local bridge = WindBridgeFactory(WindUI, {
        Name = "Vortexion", Folder = "VortexionWind", Section = "V O R T E X I O N",
    })
    local window = bridge:CreateWindow({Title = "Vortexion"})
    local info = window:AddTab({Title = "游戏说明", Icon = "lucide-info"})
    info:AddParagraph({
        Title = detail and "游戏功能初始化未完成"
            or (reason == "unsupported-aotr-scene" and "AOTR 未识别场景" or "未支持的游戏"),
        Content = ("GameId: %s / PlaceId: %s\n%s")
            :format(tostring(universe), tostring(place), detail
                or "仅加载 Wind 通用功能和 UI 设置，未启动任何游戏功能。"),
    })
    info:AddParagraph({
        Title = "支持的游戏",
        Content = "Forsaken、BloxStrike、SCP；AOTR 主菜单与大厅加载大厅模块，已核实的任务地图加载战斗模块。交易中心及未知 AOTR 场景保留通用界面。",
    })
    window:SelectTab(1)
    return bridge
end

-- Keep the generic interface visible when a game exits before creating its UI.
function Router.Run(WindUI, WindBridgeFactory, entry, universe, place, reason)
    local client = (getgenv and getgenv()) or _G
    client.VortexionBootError = nil -- errors from previous loads must not taint this route
    local ok, result = true, nil
    if entry then ok, result = xpcall(entry, function(err)
        local message = tostring(err)
        if type(debug)=="table" and type(debug.traceback)=="function" then
            return debug.traceback(message,2)
        end
        return message
    end) end
    local bridge = client.VortexionWindBridge
    local summary = not ok and tostring(result):sub(1, 1400) or nil
    local failure = client.VortexionBootError
    -- Prefer the actual constructor error over the caller's abbreviated Lua location.
    -- Entry points often rethrow at CreateWindow({...}), losing the vendor frame.
    if type(failure) == "string" and (failure:find("WindUI/CreateWindow", 1, true)
        or failure:find("Window:", 1, true) or failure:find("CreateWindow:", 1, true)) then
        summary = failure:sub(1, 1400)
    elseif failure and not summary then
        summary = tostring(failure):sub(1, 800)
    end
    local window
    if type(bridge) == "table" and bridge.Active ~= false then
        if type(bridge.Window) == "function" then
            local windowOk, value = pcall(bridge.Window, bridge)
            if windowOk then window = value end
        else
            window = bridge.Window
        end
    end
    if entry and window then
        if summary then
            warn("[Vortexion/Wind] Game initialization: " .. summary)
            if type(bridge.Notify) == "function" then
                pcall(function() bridge:Notify({Title = "游戏初始化失败", Content = summary, Duration = 6}) end)
            end
        end
        local existingPartial = bridge.BootStatus == "partial"
        bridge.BootStatus = (summary or existingPartial) and "partial" or "ready"
        bridge.BootError = summary or (existingPartial and bridge.BootError or nil)
        return ok and result or bridge
    end
    if entry then
        reason = "game-initialization-incomplete"
        summary = summary or "游戏入口提前结束，尚未创建功能界面。"
        client.VortexionBootError = summary
        warn("[Vortexion/Wind] Game initialization: " .. summary)
    end
    if type(bridge) == "table" and type(bridge.Destroy) == "function" then
        pcall(function() bridge:Destroy() end)
    end
    -- A failed vendor CreateWindow destroys the ScreenGui and its Window folder.
    -- Retrying ShowUnsupported against this *same* WindUI object only hides the
    -- first error with "Window is not a valid member of ScreenGui". The loader's
    -- already-visible diagnostic UI is the safe fallback for this case.
    -- Constructor failure can destroy the vendor ScreenGui even when the entry's
    -- error string is just the outer calling line. Never reuse this WindUI instance.
    if (summary and string.find(summary, "WindUI/CreateWindow", 1, true))
        or (type(failure) == "string" and failure:find("WindUI/CreateWindow", 1, true)) then
        client.VortexionBootError = type(failure) == "string" and failure or summary
        warn("[Vortexion/Wind] Skipping unsafe UI fallback after constructor failure: " .. tostring(client.VortexionBootError))
        return nil
    end
    local fallbackOk, fallback = pcall(Router.ShowUnsupported, WindUI, WindBridgeFactory, universe, place, reason, summary)
    if fallbackOk and type(fallback) == "table" then
        fallback.BootStatus = entry and "partial" or "unsupported"
        fallback.BootError = summary
        return fallback
    end
    client.VortexionBootError = "Generic UI fallback: " .. tostring(fallback)
        .. (summary and ("; Original failure: " .. summary) or "")
    warn("[Vortexion/Wind] " .. client.VortexionBootError)
    return nil
end

return Router

end)()
local entry = function()
local SCPCommonFactory = (function()
-- Vortexion SCP common runtime: capability probe, debug channel, guards.
-- Every SCP module receives this singleton as `common` and never globals state.
return function(common)
	common = common or {}
	common.Version = "3.0.0"
	common.Name = "SCP"

	--=========================================================================
	-- Executor capability probe. Each feature degrades instead of hard-failing.
	--=========================================================================
	local Caps = {}
	local function detect(name, test)
		local ok, result = pcall(test)
		Caps[name] = ok and result and true or false
	end
	detect("Drawing", function() return type(Drawing) == "table" and type(Drawing.new) == "function" end)
	detect("DrawingUserdata", function() return type(Drawing) == "userdata" end)
	detect("hookfunction", function() return type(hookfunction) == "function" end)
	detect("replaceclosure", function() return type(replaceclosure) == "function" end)
	detect("hookmetamethod", function() return type(hookmetamethod) == "function" end)
	detect("getrawmetatable", function() return type(getrawmetatable) == "function" end)
	detect("newcclosure", function() return type(newcclosure) == "function" end)
	detect("checkcaller", function() return type(checkcaller) == "function" end)
	detect("mousemoverel", function() return type(mousemoverel) == "function" end)
	detect("gethui", function() return type(gethui) == "function" end)
	detect("getgenv", function() return type(getgenv) == "function" end)
	detect("setclipboard", function() return type(setclipboard) == "function" end)
	common.Caps = Caps
	-- ESP gate: Drawing API present in either userdata or table form.
	common.HasDrawing = (Caps.Drawing or Caps.DrawingUserdata) and true or false

	--=========================================================================
	-- Debug channel: one prefix per module, gated by the Settings/Debug toggle.
	--=========================================================================
	common.Debug = false
	function common.Log(module, ...)
		if not common.Debug then return end
		print(("[Vortexion/SCP/%s]"):format(module), ...)
	end

	--=========================================================================
	-- Guarded execution with 5s warn throttle: one broken subsystem must never
	-- spam the console or stall the shared render loop.
	--=========================================================================
	local lastWarn = {}
	function common.Guard(module, fn, ...)
		local ok, err = pcall(fn, ...)
		if not ok then
			local now = tick()
			if not lastWarn[module] or now - lastWarn[module] > 5 then
				lastWarn[module] = now
				warn(("[Vortexion/SCP/%s] %s"):format(module, tostring(err)))
			end
		end
		return ok
	end

	--=========================================================================
	-- Visual cadence: consume the shared bridge interval clamp when present.
	-- The bridge returns max(baseSeconds, 1/VisualHz); a missing method, a
	-- non-function field or a failing call keeps the original beat untouched.
	--=========================================================================
	function common.VisualInterval(baseSeconds)
		local base = tonumber(baseSeconds) or 0
		if base <= 0 or base ~= base then return baseSeconds end
		local bridge = common.UI
		if type(bridge) == "table" and type(bridge.GetVisualInterval) == "function" then
			local ok, value = pcall(bridge.GetVisualInterval, bridge, base)
			-- the shared clamp may only slow visuals down, never speed them up:
			-- reject NaN / +-inf / non-positive and never return below base.
			if ok and type(value) == "number" and value == value
				and value < math.huge and value > -math.huge and value > 0 then
				return math.max(base, value)
			end
		end
		return base
	end

	--=========================================================================
	-- RandomName: short identifiers for module-owned GUI instances.
	--=========================================================================
	local NAME_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	function common.RandomName(len)
		len = len or 14
		local out = table.create(len)
		for i = 1, len do
			local ci = math.random(1, #NAME_CHARS)
			out[i] = NAME_CHARS:sub(ci, ci)
		end
		return table.concat(out)
	end

	--=========================================================================
	-- getGuiParent: capability-based GUI parent with PlayerGui fallback.
	--=========================================================================
	function common.GetGuiParent()
		if Caps.gethui then
			local ok, hui = pcall(gethui)
			if ok and hui then return hui end
		end
		local coreGui = game:FindService("CoreGui")
		if coreGui then return coreGui end
		local lp = game:GetService("Players").LocalPlayer
		return lp and lp:FindFirstChild("PlayerGui")
	end

	--=========================================================================
	-- Cleanup registry: modules push disposers; Core:Stop() runs them all so a
	-- reload/respawn never leaks connections, drawings or patched closures.
	--=========================================================================
	common.Disposers = common.Disposers or {}
	if not common.OnCleanup then
		function common.OnCleanup(fn)
			table.insert(common.Disposers, fn)
		end
	end

	--=========================================================================
	-- Touch layer: mobile trigger + fly drag. Single finger held = trigger;
	-- single finger drag = horizontal fly; two fingers = vertical fly.
	--=========================================================================
	common.Touch = { Enabled = false, Held = false, Presses = 0, Region = "Right" }
	do
		local UIS = common.Services and (common.Services.UserInputService or common.Services.Input)
		if not UIS then
			local ok, svc = pcall(function() return game:GetService("UserInputService") end)
			if ok then UIS = svc end
		end
		if UIS and UIS.TouchEnabled then
			common.Touch.Enabled = true
			local touchPoints = {}
			local touchConns = {}
			local sequence = 0
			table.insert(touchConns, UIS.TouchStarted:Connect(function(input, processed)
				if processed then return end
				local cam = (common.Services.Workspace or workspace).CurrentCamera
				if common.Touch.Region == "Right" and cam and input.Position.X < cam.ViewportSize.X * 0.5 then return end
				sequence += 1
				touchPoints[input] = { Origin = input.Position, Position = input.Position, Order = sequence }
				if not common.Touch.Held then common.Touch.Presses += 1 end
				common.Touch.Held = true
			end))
			table.insert(touchConns, UIS.TouchMoved:Connect(function(input)
				if touchPoints[input] then touchPoints[input].Position = input.Position end
			end))
			table.insert(touchConns, UIS.TouchEnded:Connect(function(input)
				touchPoints[input] = nil
				common.Touch.Held = next(touchPoints) ~= nil
			end))
			local function resetTouch()
				table.clear(touchPoints)
				common.Touch.Held = false
				common.Touch.FocusEpoch = (common.Touch.FocusEpoch or 0) + 1
			end
			if UIS.WindowFocusReleased then
				table.insert(touchConns, UIS.WindowFocusReleased:Connect(resetTouch))
			end
			function common.Touch:Drag()
				local first, second
				for _, point in pairs(touchPoints) do
					if not first or point.Order < first.Order then
						second, first = first, point
					elseif not second or point.Order < second.Order then second = point end
				end
				if not first then return Vector2.zero, 0 end
				local d = first.Position - first.Origin
				local vertical = second and second.Position.Y - second.Origin.Y or 0
				return Vector2.new(d.X, d.Y), vertical
			end
			common.OnCleanup(function()
				for _, cn in ipairs(touchConns) do pcall(function() cn:Disconnect() end) end
				touchPoints = {}
				common.Touch.Held = false
			end)
		end
	end

	--=========================================================================
	-- Safe service cache (executor-agnostic direct GetService).
	--=========================================================================
	common.Services = common.Services or {
		Players = game:GetService("Players"),
		RunService = game:GetService("RunService"),
		UserInputService = game:GetService("UserInputService"),
		HttpService = game:GetService("HttpService"),
		Lighting = game:GetService("Lighting"),
		TeleportService = game:GetService("TeleportService"),
		VirtualUser = game:GetService("VirtualUser"),
		TweenService = game:GetService("TweenService"),
		Workspace = workspace,
	}
	common.Services.UserInputService = common.Services.UserInputService or common.Services.Input
	common.Services.Input = common.Services.Input or common.Services.UserInputService
	common.LocalPlayer = common.LocalPlayer or common.Services.Players.LocalPlayer

	return common
end

end)()
local SCPCandidatesFactory = (function()
-- Vortexion SCP candidates: event-cached roster and bounded nearest pool.
-- Discovery runs once plus events; geometry refresh uses a configurable tick.
-- All consumers share validated character references.
--
-- R15/R6 rigs are both covered through REGION_PARTS: SCP roleplay mixes
-- custom rigs, and the original UpperTorso-or-Torso check silently skipped
-- every R15 arm/leg region.
return function(common)
	local Players = common.Services.Players
	local Workspace = common.Services.Workspace
	local Camera = Workspace.CurrentCamera

	local Candidates = {}
	Candidates.MAX_CANDIDATES = 56
	Candidates.REGION_PARTS = {
		Head = { "Head" },
		Torso = { "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso" },
		Arms = { "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "Left Arm", "Right Arm" },
		Legs = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot", "Left Leg", "Right Leg" },
	}
	Candidates.REGION_ORDER = { "Head", "Torso", "Arms", "Legs" }

	local pool = {}
	local roster = Players:GetPlayers()
	local accumulator = 0
	local dirty = true
	Candidates.Config = { TickRate = 30 }
    local function normalize(value)
        return tostring(value or ""):lower():gsub("[^%w]", "")
    end
    local function teamName(player)
        if not player then return "" end
        local team=player.Team
        return team and team.Name or player:GetAttribute("Team") or player:GetAttribute("Faction") or ""
    end
    function Candidates:GetSide(player)
        if not player then return "SCP" end
        local raw=normalize(teamName(player))
        if raw:find("chaos") or raw:find("insurgenc") or raw:find("hostile") then return "HOSTILE" end
        if raw:find("classd") or raw:find("prisoner") or raw:find("neutral") then return "NEUTRAL" end
        if raw:find("foundation") or raw:find("security") or raw:find("scientific")
            or raw:find("taskforce") or raw:find("intelligence") or raw:find("response")
            or raw:find("medical") or raw:find("administrative") or raw:find("o5") then
            return "FOUNDATION"
        end
        return "UNKNOWN"
    end
    -- UNKNOWN falls back to exact Team comparison; do not mark all unrecognized teams hostile.
    function Candidates:IsHostile(cand)
        if not cand.Player then return true end
        local targetSide=self:GetSide(cand.Player)
        local localSide=self:GetSide(Players.LocalPlayer)
        if targetSide=="NEUTRAL" or localSide=="NEUTRAL" then return false end
        if targetSide~="UNKNOWN" and localSide~="UNKNOWN" and localSide~="NEUTRAL" then
            return targetSide~=localSide
        end
        if cand.Player.Team and Players.LocalPlayer.Team then
            return cand.Player.Team~=Players.LocalPlayer.Team
        end
        return false
    end
    function Candidates:GetJob(cand)
        if not cand.Player then return "SCP收容体" end
        local player=cand.Player
        for _,attr in ipairs({"Job", "Role", "TeamRole", "Rank", "TeamRank", "Title"}) do
            local value=player:GetAttribute(attr)
            if type(value)=="string" and value~="" then return value end
        end
        local stats=player:FindFirstChild("leaderstats")
        if stats then
            for _,name in ipairs({"Rank","Role","Job"}) do
                local item=stats:FindFirstChild(name)
                if item and item:IsA("StringValue") and item.Value~="" then return item.Value end
            end
        end
        local name=teamName(player)
        return name~="" and tostring(name) or "未知职位"
    end
	local rosterConns = {
		Players.PlayerAdded:Connect(function(player) table.insert(roster, player) dirty = true end),
		Players.PlayerRemoving:Connect(function(player)
			local index = table.find(roster, player)
			if index then table.remove(roster, index) end
			dirty = true
		end),
	}
	common.OnCleanup(function()
		for _, conn in ipairs(rosterConns) do conn:Disconnect() end
		table.clear(pool)
	end)
	Candidates.LocalRootPos = nil
	Candidates.LocalCharacter = nil
	Candidates.Frame = 0

	local function pickRegionPart(character, region)
		local names = Candidates.REGION_PARTS[region]
		if not names then return nil end
		for _, name in ipairs(names) do
			local part = character:FindFirstChild(name)
			if part and part:IsA("BasePart") then return part end
		end
		return nil
	end
	Candidates.pickPartFromRegion = pickRegionPart

	function Candidates.pickAnyPart(character)
		for _, region in ipairs(Candidates.REGION_ORDER) do
			local part = pickRegionPart(character, region)
			if part then return part end
		end
		return nil
	end

	local function resolveCandidate(player, character, humanoid)
		if not character.Parent then return nil end
		local hrp = character:FindFirstChild("HumanoidRootPart")
            or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        local head = character:FindFirstChild("Head") or hrp
        if not (head and hrp and head:IsA("BasePart") and hrp:IsA("BasePart")) then return nil end
		if humanoid.Health <= 0 then return nil end

		local cand = {
			Player = player,
			Character = character,
			Humanoid = humanoid,
			Head = head,
			HRP = hrp,
			Velocity = hrp.AssemblyLinearVelocity,
			WorldDistance = (hrp.Position - Camera.CFrame.Position).Magnitude,
			Anchor = head,
			AnchorScreen = Vector3.zero,
			TopScreen = Vector3.zero,
			BotScreen = Vector3.zero,
			TopOnScreen = false,
		}

		local localPos = Candidates.LocalRootPos
		if localPos then
			cand.WorldDistance = (hrp.Position - localPos).Magnitude
		end

		return cand
	end

	-- Refresh the pool at its own cadence; camera/character changes bypass the timer.
	function Candidates:Update(dt)
		local nextCamera = Workspace.CurrentCamera
		local nextCharacter = Players.LocalPlayer and Players.LocalPlayer.Character
		local changed = nextCamera ~= Camera or nextCharacter ~= Candidates.LocalCharacter
		Camera = nextCamera
		if not Camera then
			table.clear(pool)
			Candidates.LocalRootPos, Candidates.LocalCharacter = nil, nil
			return
		end
		accumulator += dt or 1 / math.clamp(Candidates.Config.TickRate, 1, 60)
		local interval = 1 / math.clamp(Candidates.Config.TickRate, 1, 60)
		if not dirty and not changed and accumulator < interval then return end
		accumulator %= interval
		dirty = false
		Candidates.Frame += 1

		local localPlayer = Players.LocalPlayer
		local localChar = localPlayer and localPlayer.Character
		Candidates.LocalCharacter = localChar
		local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")
		Candidates.LocalRootPos = localHRP and localHRP.Position or nil

		table.clear(pool)
		self.Pool = pool

		local count = 0
		for _, player in ipairs(roster) do
			if player ~= localPlayer then
				local character = player.Character
				local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
				if humanoid then
					local cand = resolveCandidate(player, character, humanoid)
					if cand then
						count += 1
						pool[count] = cand
					end
				end
			end
		end

		-- NPC models are cached by descendant events and validated on refresh.
		if Candidates.NPCs then
			for model, _ in pairs(Candidates.NPCs) do
				if model.Parent and not Players:GetPlayerFromCharacter(model) and model ~= localChar then
					local humanoid = model:FindFirstChildWhichIsA("Humanoid")
					if humanoid and humanoid.Health > 0 then
						local cand = resolveCandidate(nil, model, humanoid)
						if cand then
							count += 1
							pool[count] = cand
						end
					end
				else
					Candidates.NPCs[model] = nil
				end
			end
		end
		table.sort(pool, function(a, b) return a.WorldDistance < b.WorldDistance end)
		for i = #pool, Candidates.MAX_CANDIDATES + 1, -1 do pool[i] = nil end
		-- Only project the bounded nearest pool, not every player in the server.
        for _,cand in ipairs(pool) do
            cand.AnchorScreen = Camera:WorldToViewportPoint(cand.Anchor.Position)
            cand.TopOnScreen = cand.AnchorScreen.Z>0
        end
	end

	function Candidates:Get()
		return self.Pool or pool
	end

	--=========================================================================
	-- NPC discovery: one nested walk, then descendant lifecycle events.
	-- The original script never targeted NPCs; SCP roleplay needs it, but a
	-- per-frame GetDescendants is unaffordable, hence the cache.
	--=========================================================================
	function Candidates:StartNPCScan()
		if Candidates.NPCs then return end
		Candidates.NPCs = {}

		local function consider(model)
			if not model:IsA("Model") then return end
			if Players:GetPlayerFromCharacter(model) then return end
			local humanoid = model:FindFirstChildWhichIsA("Humanoid")
			if humanoid then Candidates.NPCs[model] = true end
		end

		local connAdded = Workspace.DescendantAdded:Connect(function(inst)
			if inst:IsA("Model") then consider(inst)
			elseif inst:IsA("Humanoid") and inst.Parent then consider(inst.Parent) end
		end)
		local connRemoved = Workspace.DescendantRemoving:Connect(function(inst)
			Candidates.NPCs[inst] = nil
			if inst:IsA("Humanoid") and inst.Parent then Candidates.NPCs[inst.Parent] = nil end
		end)
		-- R224: budgeted BFS avoids a blocking GetDescendants allocation on
		-- enormous SCP maps. Pause every 160 nodes (including non-NPC props).
		local stopped=false
		task.spawn(function()
			local queue={Workspace}
			local front,last=1,1
			while front<=last and not stopped do
				local node=queue[front]
				queue[front]=nil -- release processed scene references immediately
				front+=1
				if node then
					if node:IsA("Humanoid") and node.Parent then consider(node.Parent) end
					local ok,children=pcall(function()return node:GetChildren() end)
					if ok and children then
						for _,child in ipairs(children) do last+=1;queue[last]=child end
					end
				end
				if front%160==0 then task.wait() end
			end
		end)
		common.OnCleanup(function()
			stopped=true
			connAdded:Disconnect()
			connRemoved:Disconnect()
			Candidates.NPCs = nil
		end)
	end

	return Candidates
end

end)()
local SCPCloakFactory = (function()
-- Vortexion SCP cloak: hides script-created instances from game scripts.
--
-- Adapted from the Vanity-General-Roblox design (local sandbox study). Game
-- anti-cheat / anti-ESP logic that enumerates children cannot see instances
-- registered here. The hook only rewrites enumeration calls made by game
-- threads (checkcaller() == false); executor-side reads are untouched.
--
-- Two defenses compose:
--   1. Enumeration filter - GetChildren/GetDescendants/FindFirstChild* skip
--      protected instances for game-thread callers.
--   2. RandomName - every created instance gets a 14-letter random name so
--      static name signatures ("_chams", "ESP") never match.
return function(common)
	local Workspace = common.Services.Workspace
	local Players = common.Services.Players

	local Cloak = {}
	local protectedSet = setmetatable({}, { __mode = "k" })
	local hookInstalled = false
	local namecallConnection = nil
	local hookTarget = nil
	local originalNamecall = nil
	local inFilter = false

	local FILTERED_METHODS = {
		GetChildren = true,
		GetDescendants = true,
		FindFirstChild = true,
		FindFirstChildOfClass = true,
		FindFirstChildWhichIsA = true,
	}

	local function isHidden(instance)
		local current = instance
		local depth = 0
		while current and depth < 64 do
			if protectedSet[current] then return true end
			current = current.Parent
			depth += 1
		end
		return false
	end
	Cloak.IsHidden = isHidden

	-- Instances parented into Workspace or PlayerGui are game-visible surfaces:
	-- a hidden instance there still needs its enumeration filtered (handled by
	-- the hook), but gethui-parented instances are outside the game tree and
	-- need nothing. This distinction keeps the hook's hot path short.
	local function exposedToGame(instance)
		local current = instance
		local depth = 0
		while current and depth < 64 do
			if current == Workspace then return true end
			local playerGui = current == Players.LocalPlayer:FindFirstChild("PlayerGui")
			if playerGui then return true end
			current = current.Parent
			depth += 1
		end
		return false
	end
	Cloak.ExposedToGame = exposedToGame

	function Cloak.Protect(instance)
		if typeof(instance) ~= "Instance" then return instance end
		protectedSet[instance] = true
		return instance
	end

	function Cloak.Unprotect(instance)
		protectedSet[instance] = nil
	end

	--=========================================================================
	-- Hook. newcclosure wrapping keeps the hook invisible to islclosure /
	-- getinfo / string.dump probing (looks like a C closure). hookmetamethod
	-- is preferred over getrawmetatable + __namecall assignment because it
	-- restores cleanly and does not disturb other executor hooks.
	--=========================================================================
	local function installHook()
		if hookInstalled then return end
		if not (common.Caps.hookmetamethod and common.Caps.checkcaller) then
			common.Log("Cloak", "hook unavailable; enumeration filter disabled")
			return
		end

		local ok, err = pcall(function()
			local gameMetatable = getrawmetatable(game)
			originalNamecall = gameMetatable.__namecall
			hookTarget = game
			local namecallHook

			namecallHook = hookmetamethod(game, "__namecall", function(self, ...)
				-- Only game threads are filtered. Executor threads (this
				-- script, the UI library) must see everything or the UI dies.
				local fromGameScript = false
				if common.Caps.checkcaller then
					local okCaller, caller = pcall(checkcaller)
					fromGameScript = okCaller and (caller == false)
				end

				if fromGameScript and not inFilter then
					local method = getnamecallmethod and getnamecallmethod() or nil
					if method and FILTERED_METHODS[method] then
						inFilter = true
						local arguments = table.pack(...)
						local okFilter, result = pcall(function()
							if isHidden(self) then
								-- The container itself is hidden: report it empty.
								if method == "GetChildren" or method == "GetDescendants" then
									return {}
								end
								return nil
							end
							local children = originalNamecall(self, table.unpack(arguments, 1, arguments.n))
							if method == "GetChildren" or method == "GetDescendants" then
								local visible = {}
								for _, child in ipairs(children) do
									if not isHidden(child) then
										table.insert(visible, child)
									end
								end
								return visible
							end
							return children
						end)
						inFilter = false
						if okFilter then return result end
					end
				end
				return originalNamecall(self, ...)
			end)

			if common.Caps.newcclosure then
				namecallHook = newcclosure(namecallHook)
			end
			namecallConnection = namecallHook
			hookInstalled = true
			common.Log("Cloak", "enumeration hook installed")
		end)

		if not ok then
			warn("[Vortexion/SCP/Cloak] install failed: " .. tostring(err))
		end
	end

	function Cloak.Start()
		installHook()
	end

	function Cloak.Stop()
		table.clear(protectedSet)
		if hookInstalled and hookTarget and originalNamecall and common.Caps.hookmetamethod then
			pcall(function()
				hookmetamethod(hookTarget, "__namecall", originalNamecall)
			end)
		end
		hookInstalled = false
		namecallConnection = nil
		hookTarget = nil
		originalNamecall = nil
		inFilter = false
	end

	if type(common.OnCleanup) == "function" then
		common.OnCleanup(function() Cloak:Stop() end)
	end

	return Cloak
end

end)()
local SCPCameraFactory = (function()
-- Vortexion SCP aimbot: three modalities behind one target selector.
--
--   Camera  - CFrame:Lerp toward the target (alpha = 1 - smoothness, floored
--             at 0.02 so the smoothest setting still tracks).
--   Mouse   - mousemoverel with BASE_PULL * attraction * dampening; the camera
--             never moves, so nothing camera-side observes the snap.
--   Both    - camera for coarse motion, mouse for sub-FOV micro-correction.
--
-- Human-likeness gates (adapted from the Vanity-General-Roblox study):
--   MaxAngle   - only track when the target is already within a cone around
--                the look vector (default 30 degrees); no 180-degree flicks.
--   HitChance  - per-acquisition random roll; a failed roll idles the frame.
--   Prediction - velocity extrapolation with a low-pass on the smoothed
--                velocity so the aim point never jitters frame to frame.
--
-- Target persistence: once acquired, a lock survives while the target stays
-- alive, inside MaxDistance*1.2 and within FOV*1.5 on screen. The original
-- script re-selected every frame and never re-locked after a loss mid-hold.
return function(common)
	local Players = common.Services.Players
	local Workspace = common.Services.Workspace
	local UserInputService = common.Services.UserInputService
	local LocalPlayer = common.LocalPlayer
	local Cloak = common.Cloak

	local Camera = {}
	local Config = {
		Enabled = false,
		Mode = "Camera",          -- Camera | Mouse | Both
		FOV = 240,
		MaxDistance = 700,
		WallCheck = true,
		TeamCheck = true,        -- R226: game has FOUNDATION / HOSTILE / NEUTRAL
		Smoothness = 0.85,        -- alpha = 1 - smoothness (0.15 -> gradual)
		Hitbox = "Head",          -- Head | Torso | Arms | Legs | Random
		Prediction = 0.12,        -- seconds of velocity extrapolation
		MaxAngle = 30,            -- degrees cone around look vector
		HitChance = 1,          -- per-acquisition roll
		FOVCircle = true,
		TriggerKey = common.Touch.Enabled and "Always" or "Right",     -- None | Left | Right | Touch | Always
		Attraction = 0.6,         -- mouse-mode pull multiplier
		Dampening = true,         -- ease off inside the dampening threshold
		TargetNPCs = true,
		TouchMode = "Hold",
	}
	Camera.Config = Config
    Camera.Stats={ Candidates=0, Rejected=0, Locked="", Reason="disabled" }

	local cam = Workspace.CurrentCamera
	local lockedChar = nil
	local lockedPlayer = nil
	local lockedRegion = nil
	local smoothedVelocity = Vector3.zero
	local hitRoll = 1
	local lastMouseMode = nil
	local lastCrosshair = Vector2.zero
	local aimHighlight = nil

	--=========================================================================
	-- FOV ring: a GUI Frame + UICorner + UIStroke. The original used
	-- Drawing.new("Circle"), which silently no-ops on executors exposing
	-- Drawing as userdata; a ring renders everywhere.
	--=========================================================================
	local fovGui, fovRing
	local disposed = false

	local function ensureFovRing()
		if disposed then return nil end
		if fovRing and fovGui and fovGui.Parent and fovRing.Parent == fovGui then return fovRing end
		if fovGui then fovGui:Destroy() end
		fovGui = Instance.new("ScreenGui")
		fovGui.Name = common.RandomName()
		fovGui.ResetOnSpawn = false
		fovGui.IgnoreGuiInset = true
		fovGui.DisplayOrder = 998
		local ok = pcall(function() fovGui.Parent = common.GetGuiParent() end)
		if disposed then return nil end
		if not ok or not fovGui.Parent then
			-- Missing PlayerGui is retried by the next visual tick, never awaited.
			local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
			if not playerGui then
				fovGui:Destroy(); fovGui, fovRing = nil, nil
				return nil
			end
			fovGui.Parent = playerGui
		end
		if Cloak then Cloak.Protect(fovGui) end
		if disposed then return nil end

		fovRing = Instance.new("Frame")
		fovRing.Name = "Ring"
		fovRing.AnchorPoint = Vector2.new(0.5, 0.5)
		fovRing.Position = UDim2.fromScale(0.5, 0.5)
		fovRing.BackgroundTransparency = 1
		fovRing.BorderSizePixel = 0
		fovRing.Parent = fovGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = fovRing

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1.5
		stroke.Transparency = 0.2
		stroke.Color = Color3.fromRGB(255, 60, 60)
		stroke.Parent = fovRing
		return fovRing
	end

	local function updateFovCircle()
		if not Config.FOVCircle or not Config.Enabled or not cam then
			if fovRing then fovRing.Visible = false end
			return
		end
		local ring = ensureFovRing()
		if not ring then return end
		local diameter = math.max(0, Config.FOV) * 2
		ring.Size = UDim2.fromOffset(diameter, diameter)
		ring.Visible = Config.Enabled
	end

	--=========================================================================
	-- Reuse one highlight marker across lock transitions.
	--=========================================================================
	local function ensureHighlight()
		if aimHighlight then return aimHighlight end
		aimHighlight = Instance.new("Highlight")
		aimHighlight.Name = common.RandomName()
		aimHighlight.FillColor = Color3.fromRGB(255, 0, 0)
		aimHighlight.OutlineColor = Color3.fromRGB(255, 0, 0)
		aimHighlight.FillTransparency = 0.55
		aimHighlight.OutlineTransparency = 0
		aimHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		if Cloak then Cloak.Protect(aimHighlight) end
		return aimHighlight
	end

	local function clearHighlight()
		if aimHighlight then
			aimHighlight.Adornee = nil
			aimHighlight.Parent = nil
		end
	end

	--=========================================================================
	-- Target selection from the shared per-frame pool.
	--=========================================================================
	local function isVisible(position, character)
		local origin = cam.CFrame.Position
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = LocalPlayer.Character and { LocalPlayer.Character } or {}
		local result = Workspace:Raycast(origin, position - origin, params)
		return not result or result.Instance:IsDescendantOf(character)
	end

	local function screenDistance(cand)
		local projected, visible = cam:WorldToViewportPoint(cand.Anchor.Position)
		if not visible or projected.Z <= 0 then return math.huge end
		local screen = Vector2.new(projected.X, projected.Y)
		local center = cam.ViewportSize / 2
		return (screen - center).Magnitude
	end

	local function candidateEligible(cand, fovFactor, distanceFactor)
		if not (cand.Character.Parent and cand.Humanoid.Health > 0 and cand.Anchor.Parent) then return nil end
		if cand.Player and cand.Player.Character ~= cand.Character then return nil end
		if Config.TeamCheck and common.Candidates.IsHostile
            and not common.Candidates:IsHostile(cand) then
            return nil
        end
		if not Config.TargetNPCs and not cand.Player then return nil end
		local distance = screenDistance(cand)
		if distance >= Config.FOV * (fovFactor or 1) then return nil end
		if cand.WorldDistance > Config.MaxDistance * (distanceFactor or 1) then return nil end
		if Config.WallCheck and not isVisible(cand.Anchor.Position, cand.Character) then return nil end
		return distance
	end

	function Camera:FindBestTarget()
		local best, bestDistance = nil, math.huge
		for _, cand in ipairs(common.Candidates:Get()) do
			local distance = candidateEligible(cand)
			if distance and distance < bestDistance then
				bestDistance = distance
				best = cand
			end
		end
		return best
	end

	--=========================================================================
	-- Lock persistence. Returns the candidate to aim at this frame, reusing
	-- the previous lock while it stays valid.
	--=========================================================================
	function Camera:ResolveTarget()
		if lockedChar and lockedChar.Parent then
			for _, cand in ipairs(common.Candidates:Get()) do
				if cand.Character == lockedChar then
					if candidateEligible(cand, 1.5, 1.2) then
						return cand
					end
					break
				end
			end
		end
		lockedChar, lockedPlayer, lockedRegion = nil, nil, nil
		smoothedVelocity = Vector3.zero
		hitRoll = math.random()
		local best = Camera:FindBestTarget()
		if best then lockedChar, lockedPlayer = best.Character, best.Player end
		return best
	end

	local lastRegionMode = nil
	local function resolveRegion(character)
		if lastRegionMode ~= Config.Hitbox then lockedRegion = nil lastRegionMode = Config.Hitbox end
		if Config.Hitbox ~= "Random" and common.Candidates.REGION_PARTS[Config.Hitbox] then return Config.Hitbox end
		if not lockedRegion then
			local available = {}
			for _, region in ipairs(common.Candidates.REGION_ORDER) do
				if common.Candidates.pickPartFromRegion(character, region) then table.insert(available, region) end
			end
			lockedRegion = #available > 0 and available[math.random(#available)] or "Head"
		end
		return lockedRegion
	end

	--=========================================================================
	-- Human-likeness gates.
	--=========================================================================
	local function withinCone(aimPosition)
		local toTarget = aimPosition - cam.CFrame.Position
		if toTarget.Magnitude < 0.1 then return false end
		toTarget = toTarget.Unit
		return cam.CFrame.LookVector:Dot(toTarget) >= math.cos(math.rad(Config.MaxAngle))
	end

	local touchLatch, lastPress, lastEpoch, lastKey = false, common.Touch.Presses or 0, common.Touch.FocusEpoch or 0, Config.TriggerKey
	function Camera:ResetTrigger()
		touchLatch = false
		lastPress, lastEpoch, lastKey = common.Touch.Presses or 0, common.Touch.FocusEpoch or 0, Config.TriggerKey
	end
	local function triggerHeld()
		if UserInputService.GetFocusedTextBox and UserInputService:GetFocusedTextBox() then Camera:ResetTrigger() return false end
		if lastKey ~= Config.TriggerKey or lastEpoch ~= (common.Touch.FocusEpoch or 0) then Camera:ResetTrigger() end
		if Config.TriggerKey == "Always" then return true end
		if Config.TriggerKey == "None" then return false end
		if Config.TriggerKey == "Touch" then
			local press = common.Touch.Presses or 0
			if Config.TouchMode == "Toggle" and (press - lastPress) % 2 == 1 then touchLatch = not touchLatch end
			lastPress = press
			return common.Touch.Enabled and (Config.TouchMode == "Toggle" and touchLatch or Config.TouchMode ~= "Toggle" and common.Touch.Held)
		end
		local button = Config.TriggerKey == "Left" and Enum.UserInputType.MouseButton1 or Enum.UserInputType.MouseButton2
		return UserInputService:IsMouseButtonPressed(button)
	end

	--=========================================================================
	-- Camera modality.
	--=========================================================================
	local function pointCamera(aimPosition, dt)
		local desired = CFrame.lookAt(cam.CFrame.Position, aimPosition)
		local alpha = math.clamp(1 - Config.Smoothness, 0.02, 1)
		alpha = 1 - (1 - alpha) ^ (math.clamp(dt or 1 / 60, 0, 0.25) * 60)
		cam.CFrame = cam.CFrame:Lerp(desired, alpha)
	end

	--=========================================================================
	-- Mouse modality: relative mouse deltas with
	-- dampening near the target and NaN/clamp guards. The camera is untouched.
	--=========================================================================
	local function pointMouse(aimPosition, screenPos)
		local viewport = cam.ViewportSize
		local mouseLocation = UserInputService:GetMouseLocation()
		if not UserInputService.TouchEnabled then
			local dx, dy = screenPos.X - mouseLocation.X, screenPos.Y - mouseLocation.Y
			local mag = math.sqrt(dx * dx + dy * dy)
			if mag < 1 or mag > Config.FOV then return end

			local attraction = Config.Attraction
			if Config.Dampening then
				local threshold = math.max(12, Config.FOV * 0.25)
				if mag < threshold then
					local dampening = math.max(0.25, mag / threshold)
					attraction *= dampening
				end
			end

			local deltaX = dx * 0.2 * attraction
			local deltaY = dy * 0.2 * attraction
			if deltaX ~= deltaX or deltaY ~= deltaY then return end -- NaN guard
			deltaX = math.clamp(deltaX, -viewport.X * 0.5, viewport.X * 0.5)
			deltaY = math.clamp(deltaY, -viewport.Y * 0.5, viewport.Y * 0.5)
			mousemoverel(math.floor(deltaX + 0.5), math.floor(deltaY + 0.5))
		end
	end

	--=========================================================================
	-- Update.
	--=========================================================================
	function Camera:Update(dt)
		if disposed then return nil end
		Camera.CurrentTarget = nil
		clearHighlight()
		cam = Workspace.CurrentCamera
		updateFovCircle()

        if not Config.Enabled or not cam then
            Camera.Stats.Reason="disabled or no camera"
            Camera:ResetTrigger()
			clearHighlight()
			lockedChar, lockedPlayer, lockedRegion = nil, nil, nil
			return nil
		end

        if not triggerHeld() then
            Camera.Stats.Reason="trigger not held"
            clearHighlight()
			lockedChar, lockedPlayer, lockedRegion = nil, nil, nil
			smoothedVelocity = Vector3.zero
			hitRoll = 1
			return nil
		end

		local cand = Camera:ResolveTarget()
        if not cand then
            Camera.Stats.Reason="no valid enemy in FOV / distance / visibility"
            clearHighlight()
            return nil
        end

		local region = resolveRegion(cand.Character)
		local aimPart = common.Candidates.pickPartFromRegion(cand.Character, region)
			or common.Candidates.pickAnyPart(cand.Character)
		if not aimPart or not aimPart:IsDescendantOf(Workspace) then
			return nil
		end

		-- Low-pass the velocity so prediction never jitters.
		smoothedVelocity = smoothedVelocity:Lerp(aimPart.AssemblyLinearVelocity, 1 - 0.7 ^ (math.clamp(dt or 1 / 60, 0, 0.25) * 60))
		local aimPosition = aimPart.Position + smoothedVelocity * Config.Prediction

		-- Gates: cone + per-acquisition roll.
		if (Config.WallCheck and not isVisible(aimPart.Position, cand.Character)) or not withinCone(aimPosition) or hitRoll > Config.HitChance then
			return cand
		end

		local projected = cam:WorldToViewportPoint(aimPosition)
		local aimMode = Config.Mode
		if aimMode ~= "Camera" and (not common.Caps.mousemoverel or UserInputService.TouchEnabled) then
			aimMode = "Camera" -- executor lacks mousemoverel: degrade to camera aim
		end
		if aimMode == "Camera" then
			pointCamera(aimPosition, dt)
		elseif aimMode == "Mouse" then
			pointMouse(aimPosition, Vector2.new(projected.X, projected.Y))
		else -- Both: camera for coarse error, mouse for micro
			local center = cam.ViewportSize / 2
			local screen = Vector2.new(projected.X, projected.Y)
			local mag = (screen - center).Magnitude
			if mag > Config.FOV * 0.25 then
				pointCamera(aimPosition, dt)
			else
				pointMouse(aimPosition, screen)
			end
		end

        lockedPlayer = cand.Player
        Camera.CurrentTarget = cand
        Camera.Stats.Locked=cand.Player and cand.Player.Name or "SCP收容体"
        Camera.Stats.Reason="locked"

		local highlight = ensureHighlight()
		if highlight then
			highlight.Adornee = cand.Character
			highlight.Parent = common.GetGuiParent() or cand.Character
		end

		common.Log("Camera", ("lock=%s region=%s dist=%d"):format(
			cand.Player and cand.Player.Name or "NPC", region, math.floor(cand.WorldDistance)))
		return cand
	end

	function Camera:GetCurrentTarget()
		return Camera.CurrentTarget
	end

	function Camera:Cleanup()
		if disposed then return end
		disposed = true
		pcall(clearHighlight)
		if aimHighlight then pcall(function() aimHighlight:Destroy() end) end
		aimHighlight = nil
		if fovGui then pcall(function() fovGui:Destroy() end) end
		fovGui, fovRing = nil, nil
		lockedChar, lockedPlayer, lockedRegion = nil, nil, nil
		Camera.CurrentTarget = nil
	end

	common.OnCleanup(function() Camera:Cleanup() end)
	return Camera
end

end)()
local SCPSilentAimFactory = (function()
-- Vortexion SCP silent aim: rewrites outgoing shot parameters without
-- moving the camera or the mouse. Nothing local observes the correction; the
-- server only ever receives the rewritten values.
--
-- Two interception points (Vanity-General-Roblox study, local sandbox):
--   __namecall - FireServer / InvokeServer on RemoteEvents/Functions:
--       * a Vector3 with |v| in (0.5, 1.5) is a unit direction -> replaced
--         with the direction toward the resolved aim point
--       * any other Vector3 world coordinate -> replaced with the aim point
--   __index (mouse metatable) - Mouse.Hit / Mouse.Target spoofing so
--     client-side raycast logic that reads the mouse agrees with the aim.
--
-- Gates: MaxAngle cone + HitChance roll + occlusion arc fallback. Only game
-- threads are rewritten (checkcaller() == false); the executor's own calls
-- and UI library traffic pass through untouched.
return function(common)
	local Workspace = common.Services.Workspace
	local LocalPlayer = common.LocalPlayer

	local SilentAim = {}
	local Config = {
		Enabled = false,
		MaxAngle = 15,
		HitChance = 0.72,
		WallCheck = true,
		TeamCheck = true,
		ArcFallback = true,       -- arc over cover when the direct line is blocked
		ARC_PROBE_HEIGHT = 500,
		CLEARANCE = 12,
		MAX_LIFT = 200,
	}
	SilentAim.Config = Config

	local installed = false
	local namecallOriginal = nil
	local indexOriginal = nil
	local mouseMetatable = nil
	local hooked = false
	local saRoll = math.random()
	local lastResolved = nil

	local function fromGameScript()
		if not common.Caps.checkcaller then return false end
		local ok, caller = pcall(checkcaller)
		return ok and (caller == false)
	end

	--=========================================================================
	-- Aim point resolution: prefer the aimbot's current lock, otherwise the
	-- closest candidate to the crosshair (no wall check for the look target,
	-- matching the original aim-highlight behavior).
	--=========================================================================
	local function resolveAimPoint()
		local locked = common.Camera and common.Camera:GetCurrentTarget()
		local cand = locked
		if not cand then
			local cam = Workspace.CurrentCamera
			if not cam then return nil end
			local center = cam.ViewportSize / 2
			local best, bestDistance = nil, math.huge
			for _, candidate in ipairs(common.Candidates:Get()) do
				if Config.TeamCheck and candidate.Player and candidate.Player.Team ~= nil
					and candidate.Player.Team == LocalPlayer.Team then
					continue
				end
				local screen = Vector2.new(candidate.AnchorScreen.X, candidate.AnchorScreen.Y)
				local distance = (screen - center).Magnitude
				if distance < bestDistance then
					bestDistance = distance
					best = candidate
				end
			end
			cand = best
		end
		if not cand then return nil end

		local cam = Workspace.CurrentCamera
		if not cam then return nil end

		local part = common.Candidates.pickPartFromRegion(cand.Character, "Head")
			or common.Candidates.pickAnyPart(cand.Character)
		if not part or not part:IsDescendantOf(Workspace) then return nil end

		local aimPosition = part.Position + part.AssemblyLinearVelocity * 0.1

		-- Cone gate relative to where the camera actually looks.
		local toTarget = aimPosition - cam.CFrame.Position
		if toTarget.Magnitude < 0.1 then return nil end
		if cam.CFrame.LookVector:Dot(toTarget.Unit) < math.cos(math.rad(Config.MaxAngle)) then
			return nil
		end

		-- Occlusion arc: if the direct line is blocked, probe lifted positions
		-- for a clear lane instead of silently shooting the wall.
		if Config.WallCheck or Config.ArcFallback then
			local origin = cam.CFrame.Position
			local function blocked(target)
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				local filterChars = {}
				if LocalPlayer.Character then table.insert(filterChars, LocalPlayer.Character) end
				if cand.Character then table.insert(filterChars, cand.Character) end
				params.FilterDescendantsInstances = filterChars
				local result = Workspace:Raycast(origin, target - origin, params)
				return result ~= nil
			end
			if blocked(aimPosition) then
				if not Config.ArcFallback then return nil end
				local lift = Config.CLEARANCE
				local resolved = nil
				while lift <= Config.MAX_LIFT do
					local probe = aimPosition + Vector3.new(0, lift, 0)
					if not blocked(probe) then
						resolved = probe
						break
					end
					lift += Config.CLEARANCE
				end
				if not resolved then return nil end
				aimPosition = resolved
			end
		end

		return aimPosition, cand.Character
	end

	local function rewriteDirection(direction, aimPosition)
		local cam = Workspace.CurrentCamera
		if not cam then return direction end
		return (aimPosition - cam.CFrame.Position).Unit
	end

	--=========================================================================
	-- Install / remove.
	--=========================================================================
	local function install()
		if installed or hooked then return end
		if not (common.Caps.hookmetamethod or common.Caps.getrawmetatable) then
			common.Log("SilentAim", "metatable hooks unavailable; disabled")
			return
		end

		local ok, err = pcall(function()
			local gameMetatable = getrawmetatable(game)
			namecallOriginal = gameMetatable.__namecall

			local hook = function(self, ...)
				if fromGameScript() then
					local method = getnamecallmethod and getnamecallmethod() or nil
					if method == "FireServer" or method == "InvokeServer" then
						local aimPosition, aimCharacter = resolveAimPoint()
						if aimPosition and aimCharacter and self:IsDescendantOf(aimCharacter) == false then
							local args = { ... }
							local rewritten = false
							for i, arg in ipairs(args) do
								if typeof(arg) == "Vector3" then
									if not rewritten then
										saRoll = math.random()
										rewritten = true
									end
									if saRoll <= Config.HitChance then
										local magnitude = arg.Magnitude
										if magnitude > 0.5 and magnitude < 1.5 then
											args[i] = rewriteDirection(arg, aimPosition)
										else
											args[i] = aimPosition
										end
									end
								end
							end
							return namecallOriginal(self, table.unpack(args))
						end
					end
				end
				return namecallOriginal(self, ...)
			end

			if common.Caps.newcclosure then
				hook = newcclosure(hook)
			end
			hookmetamethod(game, "__namecall", hook)

			-- Mouse.Hit / Mouse.Target spoof through the mouse metatable.
			local mouse = LocalPlayer:GetMouse()
			mouseMetatable = getrawmetatable(mouse)
			indexOriginal = mouseMetatable.__index
			local indexHook = function(self, key)
				local value = indexOriginal(self, key)
				if (key == "Hit" or key == "Target") and fromGameScript() then
					local aimPosition = resolveAimPoint()
					if aimPosition then
						if key == "Hit" then
							value = CFrame.new(aimPosition)
						else
							local cam = Workspace.CurrentCamera
							local params = RaycastParams.new()
							params.FilterType = Enum.RaycastFilterType.Exclude
							params.FilterDescendantsInstances = LocalPlayer.Character and { LocalPlayer.Character } or {}
							local result = cam and Workspace:Raycast(
								cam.CFrame.Position, aimPosition - cam.CFrame.Position, params)
							value = result and result.Instance or value
						end
					end
				end
				return value
			end
			if common.Caps.newcclosure then
				indexHook = newcclosure(indexHook)
			end
			hookmetamethod(mouse, "__index", indexHook)

			installed = true
			common.Log("SilentAim", "hooks installed")
		end)

		if not ok then
			warn("[Vortexion/SCP/SilentAim] install failed: " .. tostring(err))
		end
	end

	local function uninstall()
		if not installed then return end
		pcall(function()
			if namecallOriginal then
				hookmetamethod(game, "__namecall", namecallOriginal)
			end
			if mouseMetatable and indexOriginal then
				hookmetamethod(mouseMetatable, "__index", indexOriginal)
			end
		end)
		installed = false
		common.Log("SilentAim", "hooks removed")
	end

	function SilentAim:Update()
		if Config.Enabled then
			install()
		else
			uninstall()
		end
	end

	function SilentAim:Cleanup()
		uninstall()
	end

	common.OnCleanup(function()
		SilentAim:Cleanup()
	end)

	return SilentAim
end

end)()
local SCPHitboxFactory = (function()
-- Vortexion SCP hitbox expander (anti-detection tuned).
--
-- Scope: BasePart.Size writes are local-only. They never enter the replication
-- stream (replication is server -> client), so the server and other clients
-- keep seeing the original size while local raycasts/projections immediately
-- use the expanded one. That makes this feature purely a local-targeting
-- surface; server-validated hit points are SilentAim's job, which clamps its
-- rewrite back into the original envelope (see SCPSilentAim + Hitbox:GetEnvelope).
--
-- Throttling (a per-frame Size write rebuilds broadphase AABBs and physics
-- islands, so the original Heartbeat loop over every player was both jittery
-- and expensive):
--   * 20 Hz tick accumulator, decoupled from the render frame rate
--   * only candidates inside FOV px and MaxDistance studs are touched
--   * at most MaxActive characters per tick, nearest-first
--   * Size is lerped toward the target (0.35), never stepped
--
-- State machine per character: expanding -> pending (250 ms grace after the
-- target leaves the gate, so re-entry does not oscillate) -> collapsing
-- (lerp back at 0.5/tick) -> cleaned. CharacterRemoving / PlayerRemoving
-- bypass pending and restore immediately.
--
-- Stealth defaults: distance-decayed scale (1.5x max at contact, 1x at 250
-- studs), anisotropic XZ 1.6 / Y 1.3, Transparency 0.55 (local-only visual),
-- CanCollide false with restore. lockedOnly couples to the aimbot lock: only
-- the locked character is expanded, which keeps the number of simultaneous
-- Size writers at one in the default configuration.
return function(common)
	local Players = common.Services.Players

	local Hitbox = {}
	local Config = {
		Enabled = false,
		ScaleMax = 1.8,
		HeadScale = 1,
		TorsoScale = 1,          -- peak multiplier at point blank
		MaxDistance = 500,       -- studs; beyond this no expansion
		FOV = 600,               -- px; only on/near-screen candidates
		TickRate = 12,           -- Hz
		MaxActive = 8,           -- simultaneous characters per tick
		GrowAlpha = 0.35,        -- lerp toward target size
		ShrinkAlpha = 0.5,       -- lerp back during collapsing
		PendingMs = 250,         -- grace period before collapsing
		Transparency = 0.55,
		AnisoXZ = 1.6,
		AnisoY = 1.3,
		MaxEdge = 10,            -- studs, hard clamp on any axis
		MaxRatio = 2.2,          -- multiplier clamp on any axis
		Mode = "all",     -- lockedOnly | fullBody | all
        TargetNPCs = true, OnlyHostile = false,
		RigParts = {
			R15 = { "Head", "UpperTorso", "LowerTorso" },
			R15Full = { "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg" },
			R6 = { "Head", "Torso" },
			R6Full = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "HumanoidRootPart" },
		},
	}
	Hitbox.Config = Config
    Hitbox.Stats = { Eligible=0, Expanded=0, LastError="" }

	-- key: Player (or Model for NPCs) -> state
	local states = {}
	local accumulator = 0

	local function rigKey(character)
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if not humanoid then return nil end
		if humanoid.RigType == Enum.HumanoidRigType.R6 then
			return Config.Mode == "fullBody" and "R6Full" or "R6"
		end
		return Config.Mode == "fullBody" and "R15Full" or "R15"
	end

	local function captureOriginal(state, part)
		if state.parts[part] then return end
		state.parts[part] = {
			size = part.Size,
			transparency = part.Transparency,
			canCollide = part.CanCollide,
		}
	end

	local function targetSizeFor(orig, distance, partName)
		-- Distance decay: full scale at contact, 1x at MaxDistance.
		local falloff = math.clamp(1 - distance / math.max(Config.MaxDistance, 1), 0, 1)
		local regionScale = partName == "Head" and Config.HeadScale or ((partName == "Torso" or partName == "UpperTorso" or partName == "LowerTorso") and Config.TorsoScale or 1)
		local scale = 1 + (Config.ScaleMax * regionScale - 1) * falloff
		local target = Vector3.new(
			orig.X * Config.AnisoXZ,
			orig.Y * Config.AnisoY,
			orig.Z * Config.AnisoXZ
		) * scale
		-- Hard clamps: never exceed MaxEdge studs on any axis or MaxRatio x.
		local maxSize = Vector3.new(
			math.min(Config.MaxEdge, orig.X * Config.MaxRatio),
			math.min(Config.MaxEdge, orig.Y * Config.MaxRatio),
			math.min(Config.MaxEdge, orig.Z * Config.MaxRatio)
		)
		return Vector3.new(
			math.min(target.X, maxSize.X),
			math.min(target.Y, maxSize.Y),
			math.min(target.Z, maxSize.Z)
		)
	end

	local function newState(key, character, rig)
		return {
			key = key,
			character = character,
			rig = rig,
			parts = {},
			phase = "expanding",
			phaseTime = 0,
			distance = 0,
		}
	end

	local function collapseState(state, dt)
		local done = true
		for part, orig in pairs(state.parts) do
			if part.Parent then
				local size = part.Size:Lerp(orig.size, Config.ShrinkAlpha)
				part.Size = size
				part.CanCollide = orig.canCollide
				part.Transparency += (orig.transparency - part.Transparency) * Config.ShrinkAlpha
				if (size - orig.size).Magnitude > 0.02 then
					done = false
				else
					part.Size = orig.size
					part.Transparency = orig.transparency
				end
			end
		end
		if done then
			states[state.key] = nil
		end
	end

	local function restoreState(state)
		for part, orig in pairs(state.parts) do
			if part.Parent then
				part.Size = orig.size
				part.Transparency = orig.transparency
				part.CanCollide = orig.canCollide
			end
		end
		states[state.key] = nil
	end

	local function expandState(state, distance, dt)
		state.phase = "expanding"
		state.phaseTime = 0
		state.distance = distance
		local names = Config.RigParts[state.rig] or Config.RigParts.R15
		for _, name in ipairs(names) do
			local part = state.character:FindFirstChild(name)
			if part and part:IsA("BasePart") then
				captureOriginal(state, part)
				local orig = state.parts[part]
				local target = targetSizeFor(orig.size, distance, part.Name)
				part.Size = part.Size:Lerp(target, Config.GrowAlpha)
				part.Transparency += (Config.Transparency - part.Transparency) * Config.GrowAlpha
				part.CanCollide = false
			end
		end
	end

	--=========================================================================
	-- Candidate gating: screen distance from the shared pool projection,
	-- world distance, liveness. Returns eligible candidates sorted nearest.
	--=========================================================================
	local function gatherEligible()
		local cam = common.Services.Workspace.CurrentCamera
		if not cam then return {} end
		local center = cam.ViewportSize / 2
		local locked = common.Camera and common.Camera:GetCurrentTarget()

		local eligible = {}
		for _, cand in ipairs(common.Candidates:Get()) do
			if (not Config.OnlyHostile or not common.Candidates.IsHostile
                or common.Candidates:IsHostile(cand))
                and (cand.Player or Config.TargetNPCs)
                and (Config.Mode ~= "lockedOnly" or (locked and cand.Character == locked.Character)) then
				if cand.Character.Parent and cand.Humanoid.Health > 0 and (not cand.Player or cand.Player.Character == cand.Character)
					and cand.WorldDistance <= Config.MaxDistance and cand.TopOnScreen then
					local screen = Vector2.new(cand.AnchorScreen.X, cand.AnchorScreen.Y)
					local screenDist = (screen - center).Magnitude
					if screenDist <= Config.FOV then
						table.insert(eligible, { cand = cand, screenDist = screenDist })
					end
				end
			end
		end
		table.sort(eligible, function(a, b) return a.screenDist < b.screenDist end)
		return eligible
	end

	--=========================================================================
	-- Public envelope query for SilentAim's server-side clamp: the ORIGINAL
	-- size of a part, so rewritten hit points stay inside what the server
	-- can validate.
	--=========================================================================
	function Hitbox:GetEnvelope(part)
		for _, state in pairs(states) do
			local orig = state.parts[part]
			if orig then return orig.size end
		end
		return part.Size
	end

	function Hitbox:GetEnvelopeMargin(part)
		for _, state in pairs(states) do
			local orig = state.parts[part]
			if orig then return orig.size * 0.5 + Vector3.new(0.5, 0.5, 0.5) end
		end
		return part.Size * 0.5 + Vector3.new(0.5, 0.5, 0.5)
	end

	--=========================================================================
	-- Update: dt-gated tick.
	--=========================================================================
	function Hitbox:Update(dt)
		if not Config.Enabled then
			Hitbox:Cleanup()
			accumulator = 0
			return
		end

		accumulator += dt
		local interval = 1 / math.clamp(Config.TickRate, 1, 60)
		if accumulator < interval then return end
		local elapsed = accumulator
		accumulator %= interval

        local eligible = gatherEligible()
        Hitbox.Stats.Eligible = #eligible
        local seen = {}

		-- Expand nearest-first, capped at MaxActive.
		local expanded = 0
		for _, entry in ipairs(eligible) do
			if expanded >= Config.MaxActive then break end
			local cand = entry.cand
			local key = cand.Player or cand.Character
			seen[key] = true
			local state = states[key]
			if state and (state.character ~= cand.Character or state.rig ~= rigKey(cand.Character)) then
				restoreState(state)
				state = nil
			end
			if not state then
				local rig = rigKey(cand.Character)
				if rig then
					state = newState(key, cand.Character, rig)
					states[key] = state
				end
			end
			if state then
				expandState(state, cand.WorldDistance, dt)
				expanded += 1
			end
		end

        Hitbox.Stats.Expanded=expanded
        -- Grace/collapse the rest.
		for key, state in pairs(states) do
			if not seen[key] then
				if state.phase == "expanding" then
					state.phase = "pending"
					state.phaseTime = 0
				elseif state.phase == "pending" then
					state.phaseTime += elapsed * 1000
					if state.phaseTime >= Config.PendingMs then
						state.phase = "collapsing"
					end
				else
					collapseState(state, interval)
				end
			end
		end
	end

	--=========================================================================
	-- Hard cleanup paths: character/player removal restores immediately.
	--=========================================================================
	local hookConns = {}
	local function hookRemovals()
		local function hookCharacter(player)
			if hookConns[player] then return end
			local hooks = {}
			hookConns[player] = hooks
			table.insert(hooks, player.CharacterRemoving:Connect(function(character)
				for key, state in pairs(states) do
					if state.character == character then
						restoreState(state)
					end
				end
			end))
			table.insert(hooks, player:GetPropertyChangedSignal("Character"):Connect(function()
				for key, state in pairs(states) do
					if state.key == player then
						restoreState(state)
					end
				end
			end))
		end
		for _, player in ipairs(Players:GetPlayers()) do
			hookCharacter(player)
		end
		local conn = Players.PlayerRemoving:Connect(function(player)
			for _, hook in ipairs(hookConns[player] or {}) do hook:Disconnect() end
			hookConns[player] = nil
			for key, state in pairs(states) do
				if state.key == player then
					restoreState(state)
				end
			end
		end)
		local conn2 = Players.PlayerAdded:Connect(hookCharacter)
		common.OnCleanup(function()
			conn:Disconnect()
			for _, hooks in pairs(hookConns) do
				for _, hook in ipairs(hooks) do pcall(function() hook:Disconnect() end) end
			end
			table.clear(hookConns)
			conn2:Disconnect()
		end)
	end
	hookRemovals()

	function Hitbox:Cleanup()
		for _, state in pairs(states) do
			restoreState(state)
		end
	end

	common.OnCleanup(function()
		Hitbox:Cleanup()
	end)

	return Hitbox
end

end)()
local SCPMovementFactory = (function()
-- Vortexion SCP movement: speed, fly, noclip, teleport, jump.
--
-- One shared physics driver preserves the existing pulse/coast settings.
-- Collision state is captured once per character and restored on every exit.
-- Deferred jump/teleport work validates the same live character and generation.
return function(common)
	local UserInputService = common.Services.UserInputService
	local Workspace = common.Services.Workspace
	local LocalPlayer = common.LocalPlayer

	local Movement = {}
	local Config = {
		SpeedEnabled = false,
		SpeedValue = 16,
		PulseBoostMs = 100,
		PulseCoastMs = 150,
		CoastFactor = 0.16,       -- coast-frame velocity factor
		FlyEnabled = false,
		TouchFly = true,
		TouchDeadzone = 10,
		TouchSensitivity = 120,
		FlySpeed = 60,
		Noclip = false,
		JumpEnabled = false,
		JumpValue = 50,
		TeleportStep = 10,        -- studs per step
		TeleportInterval = 0.05,  -- seconds between steps
		TeleportDistance = 50,    -- studs covered by the one-tap forward teleport
	}
	Movement.Config = Config

	local pulseState = "idle"
	local pulseStart = 0
	local connections = {}
	local active = false
	local epoch = 0
	local jumpPending = false
	local collisionParts = {}
	local collisionCharacter, addedConnection, removedConnection = nil, nil, nil
	local noclipAccum = 0
	local velocityRoot, velocityOriginal, velocityWritten = nil, nil, nil

	local function releaseVelocity()
		if velocityRoot and velocityRoot.Parent and velocityWritten
			and (velocityRoot.AssemblyLinearVelocity - velocityWritten).Magnitude < 0.01 then
			velocityRoot.AssemblyLinearVelocity = velocityOriginal
		end
		velocityRoot, velocityOriginal, velocityWritten = nil, nil, nil
	end
	local function writeVelocity(root, value)
		if velocityRoot ~= root then
			releaseVelocity()
			velocityRoot, velocityOriginal = root, root.AssemblyLinearVelocity
		end
		root.AssemblyLinearVelocity = value
		velocityWritten = value
	end
	local function restoreCollisions()
		for part, original in pairs(collisionParts) do if part.Parent then part.CanCollide = original end end
		table.clear(collisionParts)
		if addedConnection then addedConnection:Disconnect() addedConnection = nil end
		if removedConnection then removedConnection:Disconnect() removedConnection = nil end
		collisionCharacter, noclipAccum = nil, 0
	end

	local function localCharacter()
		local char = LocalPlayer.Character
		if not char then return nil, nil end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local humanoid = char:FindFirstChildWhichIsA("Humanoid")
		if not (hrp and humanoid) or humanoid.Health <= 0 then return nil, nil end
		return char, hrp
	end

	--=========================================================================
	-- Speed: pulse/coast.
	--=========================================================================
	local function updateSpeed()
		local char, hrp = localCharacter()
		if not char then releaseVelocity() pulseState = "idle" return end
		local humanoid = char:FindFirstChildWhichIsA("Humanoid")
		local direction = humanoid.MoveDirection
		if direction.Magnitude <= 0 then releaseVelocity() pulseState = "idle" return end

		local now = tick()
		if pulseState == "idle" then
			pulseState = "boost"
			pulseStart = now
		end

		local boosting
		if pulseState == "boost" then
			if now - pulseStart >= Config.PulseBoostMs / 1000 then
				pulseState = "coast"
				pulseStart = now
				boosting = false
			else
				boosting = true
			end
		else
			if now - pulseStart >= Config.PulseCoastMs / 1000 then
				pulseState = "boost"
				pulseStart = now
				boosting = true
			else
				boosting = false
			end
		end

		local target = direction.Unit * Config.SpeedValue
		if not boosting then
			target = direction.Unit * (Config.SpeedValue * Config.CoastFactor)
		end
		writeVelocity(hrp, Vector3.new(target.X, hrp.AssemblyLinearVelocity.Y, target.Z))
	end

	--=========================================================================
	-- Fly: camera-relative directional control on the Heartbeat physics step.
	--=========================================================================
	local function updateFly()
		local char, hrp = localCharacter()
		if not char then releaseVelocity() return end
		local cam = Workspace.CurrentCamera
		if not cam then releaseVelocity() return end
		if UserInputService.GetFocusedTextBox and UserInputService:GetFocusedTextBox() then releaseVelocity() return end

		local move = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end
		if Config.TouchFly and common.Touch.Enabled and common.Touch.Held then
			local drag, vertical = common.Touch:Drag()
			if drag.Magnitude > Config.TouchDeadzone then
				move += cam.CFrame.RightVector * math.clamp(drag.X / math.max(Config.TouchSensitivity, 1), -1, 1)
				move += cam.CFrame.LookVector * math.clamp(-drag.Y / math.max(Config.TouchSensitivity, 1), -1, 1)
			end
			if math.abs(vertical) > 30 then
				move += Vector3.new(0, math.clamp(-vertical / math.max(Config.TouchSensitivity, 1), -1, 1), 0)
			end
		end

		if move.Magnitude > 0 then
			move = move.Unit * Config.FlySpeed
			writeVelocity(hrp, Vector3.new(move.X, move.Y, move.Z))
		else
			writeVelocity(hrp, Vector3.zero)
		end
	end

	--=========================================================================
	-- Noclip: cache descendants once, then re-assert owned parts at 20 Hz.
	--=========================================================================
	local function updateNoclip(dt)
		local char = LocalPlayer.Character
		if not Config.Noclip or not char then restoreCollisions() return end
		if collisionCharacter ~= char then
			restoreCollisions()
			collisionCharacter = char
			local function capture(part)
				if part:IsA("BasePart") and collisionParts[part] == nil then collisionParts[part] = part.CanCollide end
			end
			for _, part in ipairs(char:GetDescendants()) do capture(part) end
			addedConnection = char.DescendantAdded:Connect(capture)
			removedConnection = char.DescendantRemoving:Connect(function(part)
				if collisionParts[part] ~= nil then part.CanCollide = collisionParts[part] collisionParts[part] = nil end
			end)
			noclipAccum = 0.05
		end
		noclipAccum += dt or 0
		if noclipAccum < 0.05 then return end
		noclipAccum %= 0.05
		for part in pairs(collisionParts) do
			if part.Parent then part.CanCollide = false else collisionParts[part] = nil end
		end
	end
	function Movement:SetNoclip(value)
		Config.Noclip = value
		if not value then restoreCollisions() end
	end

	--=========================================================================
	-- Teleport: stepped motion with replacement, respawn and unload cancellation.
	--=========================================================================
	function Movement:TeleportTo(position)
		if not active then return end
		epoch += 1
		jumpPending = false
		local token = epoch
		local char, hrp = localCharacter()
		if not char then return end
		task.spawn(function()
			local origin = hrp.Position
			local delta = position - origin
			local distance = delta.Magnitude
			if distance < 0.1 then return end
			local direction = delta.Unit
			local step = math.max(Config.TeleportStep, 0.1)
			for i = 1, math.ceil(distance / step) do
				local curChar, curHrp = localCharacter()
				if not active or epoch ~= token or curChar ~= char or curHrp ~= hrp then return end
				hrp.CFrame = CFrame.new(origin + direction * math.min(distance, i * step))
				task.wait(math.max(Config.TeleportInterval, 0.01))
			end
		end)
	end

	-- One-tap forward teleport: the mobile button path, reusing the same
	-- stepped motion and cancellation guarantees as an explicit destination.
	function Movement:TeleportForward()
		if not active then return false end
		local char, hrp = localCharacter()
		if not (char and hrp) then return false end
		local distance = math.clamp(tonumber(Config.TeleportDistance) or 0, 1, 1000)
		Movement:TeleportTo(hrp.Position + hrp.CFrame.LookVector * distance)
		return true
	end

	--=========================================================================
	-- Jump: preserve the Freefall-then-velocity order without yielding input callbacks.
	--=========================================================================
	-- force=true is the explicit mobile button path: it still runs the same
	-- deferred, respawn-cancelled sequence and falls back to the humanoid's own
	-- jump when the super-jump multiplier is switched off.
	function Movement:RequestJump(force)
		if not active or jumpPending or (not Config.JumpEnabled and not force) then return end
		local char, hrp = localCharacter()
		if not char then return end
		local humanoid = char:FindFirstChildWhichIsA("Humanoid")
		local token = epoch
		jumpPending = true
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		task.delay(0.02, function()
			if token ~= epoch then return end
			jumpPending = false
			local curChar, curHrp = localCharacter()
			if active and curChar == char and curHrp == hrp and humanoid.Health > 0 then
				if Config.JumpEnabled then
					hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, Config.JumpValue, hrp.AssemblyLinearVelocity.Z)
				else
					humanoid.Jump = true
				end
			end
		end)
	end

	function Movement:Update(dt)
		if not active then return end
		if Config.FlyEnabled then
			common.Guard("Movement", updateFly)
		elseif Config.SpeedEnabled then
			common.Guard("Movement", updateSpeed)
		else
			releaseVelocity()
			pulseState = "idle"
		end
		common.Guard("Movement", updateNoclip, dt)
	end

	function Movement:Start()
		if active then return end
		active = true
		table.insert(connections, UserInputService.JumpRequest:Connect(function() common.Guard("Movement", function() Movement:RequestJump() end) end))
		table.insert(connections, LocalPlayer.CharacterRemoving:Connect(function()
			epoch += 1
			jumpPending = false
			restoreCollisions()
			releaseVelocity()
			pulseState = "idle"
		end))
	end

	function Movement:Cleanup()
		active = false
		epoch += 1
		jumpPending = false
		for _, conn in ipairs(connections) do conn:Disconnect() end
		table.clear(connections)
		restoreCollisions()
		releaseVelocity()
		pulseState = "idle"
	end

	common.OnCleanup(function()
		Movement:Cleanup()
	end)

	return Movement
end

end)()
local SCPESPFactory = (function()
-- R226: native, pooled SCP collision-envelope ESP.
-- 3D: BoxHandleAdornment (engine tracks part transforms without Lua projection).
-- 2D: ScreenGui+UIStroke frames, projected only on a bounded refresh beat.
-- No Drawing API, global hooks, per-frame Workspace scans or per-tick allocations.
return function(common)
    local Workspace = common.Services.Workspace
    local Players = common.Services.Players
    local Config = {
        Enabled = false, Style = "3D", Box = true, Labels = true, ShowNames = true,
        NameFormat = "用户名", ShowJob = false, OnlyHostile = false,
        TargetNPCs = true, TeamCheck = false, MaxDistance = 850,
        MaxEntries = 36, TickRate = 20,
        Transparency3D = 0.30, Transparency2D = 0.15,
        BoxThickness = 1.6, NameSize = 14, JobSize = 13,
        LabelOffset = 2.4, ShowDistance = false, ShowHealth = false,
        JobTeamColor = true, JobTranslate = true,
        ColorEnemy = Color3.fromRGB(245, 80, 80),
        ColorAlly = Color3.fromRGB(75, 175, 225),
        ColorSCP = Color3.fromRGB(0, 0, 0),
        ColorLowHealth = Color3.fromRGB(255, 160, 0),
        Health = false, Skeleton = false, Tracer = false,
        Chams = false, OffScreen = false, NativeLabels = true,
    }
    local ESP = { Config = Config, Stats = { Seen = 0, Visible = 0, Ms = 0, Hz = 20, Failures = 0 } }
    local entries = {}
    local screen, layer, accumulator, lastCamera = nil, nil, 0, nil
    local stopped, serial, avg = false, 0, 0
    local wasEnabled = false
    local function dispose(entry)
        for _, component in ipairs(entry.parts or {}) do
            if component.adorn then pcall(function() component.adorn:Destroy() end) end
            if component.frame then pcall(function() component.frame:Destroy() end) end
        end
        if entry.label then pcall(function() entry.label:Destroy() end) end
    end
    local function hide(entry)
        for _, component in ipairs(entry.parts or {}) do
            if component.adorn then component.adorn.Visible = false end
            if component.frame then component.frame.Visible = false end
        end
        if entry.label then entry.label.Enabled = false end
    end
    local function clear()
        for key,entry in pairs(entries) do dispose(entry); entries[key]=nil end
    end
    local function mountScreen()
        if screen and screen.Parent then return screen end
        local gui = Instance.new("ScreenGui")
        gui.Name = "VortexionSCPESP2D"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 940
        local parent = common.GetGuiParent and common.GetGuiParent()
        if not parent then
            parent = common.LocalPlayer:FindFirstChildOfClass("PlayerGui")
        end
        if not parent then gui:Destroy() return nil end
        local ok = pcall(function() gui.Parent=parent end)
        if not ok then gui:Destroy() return nil end
        screen = gui
        return screen
    end
    -- SCP: Roleplay community team/rank vocabulary. Unmapped values remain original.
    local ROLE_ZH = {
        ["Class-D"]="D级人员", ["Class - D"]="D级人员", ["Class D"]="D级人员",
        ["Chaos Insurgency"]="混沌分裂者", ["Scientific Department"]="科研部",
        ["Security Department"]="安保部", ["Medical Department"]="医疗部",
        ["Administrative Department"]="行政部", ["Intelligence Agency"]="情报局",
        ["Internal Security Department"]="内部安全部",
        ["Rapid Response Team"]="快速反应部队", ["Mobile Task Forces"]="机动特遣队",
        ["Mobile Task Force"]="机动特遣队", ["O5 Council"]="O5议会",
        ["Foundation"]="基金会", ["Neutral"]="中立", ["Hostile"]="敌对",
        ["Recruit"]="新兵", ["Cadet"]="学员", ["Private"]="列兵",
        ["Corporal"]="下士", ["Sergeant"]="中士", ["Staff Sergeant"]="上士",
        ["Lieutenant"]="中尉", ["Captain"]="上尉", ["Commander"]="指挥官",
        ["Director"]="主管", ["Deputy Director"]="副主管",
        ["Supervisor"]="监督员", ["Special Agent"]="特工",
        ["Entry Agent"]="初级特工", ["Internal Agent"]="内部特工",
        ["Senior Supervisor"]="高级监督员", ["Lead Supervisor"]="首席监督员",
        ["Researcher"]="研究员", ["Junior Researcher"]="初级研究员",
        ["Senior Researcher"]="高级研究员", ["Intern"]="实习生",
        ["Doctor"]="医生", ["Nurse"]="护士", ["Veteran Class - D"]="资深D级人员",
        ["Conscript"]="征召兵", ["Trained Conscript"]="训练征召兵",
        ["Senior Conscript"]="高级征召兵", ["Alpha"]="阿尔法",
        ["Nu-7"]="Nu-7机动特遣队", ["Epsilon-11"]="Epsilon-11机动特遣队",
        ["Beta-7"]="Beta-7机动特遣队", ["Alpha-1"]="Alpha-1机动特遣队",
        ["Dedicated Class - D"]="资深D级人员", ["Adept Class - D"]="熟练D级人员",
        ["Advanced Class - D"]="高级D级人员", ["Board Director"]="董事会主管",
        ["Head Researcher"]="首席研究员", ["Trainee Researcher"]="见习研究员",
        ["General"]="将军", ["Major"]="少校", ["Colonel"]="上校",
        ["Task Force Leader"]="特遣队队长", ["Head Commander"]="总指挥官",
        ["Insurgency Command"]="叛乱指挥官", ["The Engineer"]="工程师",
        ["Intelligence Director"]="情报局局长", ["Internal Security Manager"]="内部安全经理",
        ["Medical Director"]="医疗部主管", ["Site Manager"]="站点经理",
        ["Junior Manager"]="初级经理", ["Senior Manager"]="高级经理",
        ["Site Assistant Manager"]="站点助理经理", ["Site Senior Manager"]="站点高级经理",
        ["Site Director"]="站点主管", ["Site Council"]="站点议会",
        ["Administrative Council"]="行政议会", ["Administrative Regulator"]="行政监察员",
    }
    local function translatedRank(raw)
        if not Config.JobTranslate then return raw end
        if ROLE_ZH[raw] then return ROLE_ZH[raw] end
        local normalized=tostring(raw):gsub("^%s+",""):gsub("%s+$","")
        return ROLE_ZH[normalized] or normalized
    end
    local function roleColor(player)
        if not player then return Config.ColorSCP end
        if not Config.JobTeamColor then return Config.ColorAlly end
        -- Prefer explicit live role color when a game version provides it.
        for _,key in ipairs({"JobColor", "RoleColor", "RankColor", "TeamColor"}) do
            local ok,value=pcall(function()return player:GetAttribute(key)end)
            if ok and typeof(value)=="Color3" then return value end
        end
        local team=player.Team
        if team then
            local ok,color=pcall(function()return team.TeamColor.Color end)
            if ok and typeof(color)=="Color3" then return color end
        end
        return Config.ColorAlly
    end
    local function role(player, cand)
        if not player then return "SCP收容体" end
        if common.Candidates and common.Candidates.GetJob then
            return translatedRank(common.Candidates:GetJob(cand))
        end
        return translatedRank(player.Team and player.Team.Name or "未知职位")
    end
    local function displayName(player,cand)
        if not Config.ShowNames then return "" end
        if not player then return "SCP收容体" end
        local name=(Config.NameFormat=="实体名" and cand.Character and cand.Character.Name) or player.Name
        return tostring(name or "")
    end
    local function labelExtra(cand)
        local info={}
        if Config.ShowDistance then
            info[#info+1] = tostring(math.floor(cand.WorldDistance or 0)) .. " studs"
        end
        if Config.ShowHealth and cand.Humanoid then
            local hp=math.max(0,math.floor(cand.Humanoid.Health or 0))
            local max=math.max(1,math.floor(cand.Humanoid.MaxHealth or 100))
            info[#info+1] = ("%d/%d HP"):format(hp,max)
        end
        return table.concat(info, " · ")
    end
    local function attachLabel(entry, head)
        if entry.label then return end
        local gui=Instance.new("BillboardGui")
        gui.Name="SCPLabel"
        gui.Size=UDim2.fromOffset(260,72)
        gui.StudsOffsetWorldSpace=Vector3.new(0,Config.LabelOffset,0)
        gui.AlwaysOnTop=true
        gui.ResetOnSpawn=false
        gui.Adornee=head
        local function addLine(name)
            local text=Instance.new("TextLabel")
            text.Name=name
            text.Size=UDim2.new(1,0,0,21)
            text.BackgroundTransparency=1
            text.Font=Enum.Font.GothamBold
            text.TextScaled=false
            text.TextSize=14
            text.TextStrokeTransparency=Config.LabelStroke == false and 1 or 0.2
            text.TextStrokeColor3=Color3.fromRGB(10,15,18)
            text.TextTruncate=Enum.TextTruncate.AtEnd
            if Config.LabelFont and Enum.Font[Config.LabelFont] then text.Font=Enum.Font[Config.LabelFont] end
            text.Parent=gui
            return text
        end
        local nameText=addLine("ESPName")
        local jobText=addLine("ESPJob")
        local metaText=addLine("ESPMeta")
        metaText.TextSize=12
        local parent=mountScreen()
        if not parent then gui:Destroy() return end
        gui.Parent=parent
        entry.label,entry.text,entry.roleText,entry.metaText=gui,nameText,jobText,metaText
    end
    local function discoverParts(cand)
        local model=cand.Character
        local parts={}
        local head=model:FindFirstChild("Head")
        if head and head:IsA("BasePart") then parts[#parts+1]=head end
        local torso=model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
            or model:FindFirstChild("HumanoidRootPart")
        if torso and torso:IsA("BasePart") and torso~=head then parts[#parts+1]=torso end
        -- SCP variants may lack a traditional rig.
        if #parts==0 and cand.HRP and cand.HRP:IsA("BasePart") then parts[1]=cand.HRP end
        return parts
    end
    local function construct(cand)
        local key=cand.Character
        local entry=entries[key]
        if entry then return entry end
        entry={parts={},character=key}
        entries[key]=entry
        for _, part in ipairs(discoverParts(cand)) do
            entry.parts[#entry.parts+1]={part=part}
        end
        return entry
    end
    local function ensureAdornment(component)
        if component.adorn and component.adorn.Parent then return component.adorn end
        local part=component.part
        if not part or not part.Parent then return nil end
        local adorn=Instance.new("BoxHandleAdornment")
        adorn.Name="SCP3DCollisionBox"
        adorn.Adornee=part
        adorn.Size=part.Size
        adorn.AlwaysOnTop=true
        adorn.ZIndex=4
        adorn.Transparency=Config.Transparency3D
        adorn.Visible=false
        adorn.Parent=screen or mountScreen() or part
        component.adorn=adorn
        return adorn
    end
    local function ensureFrame(component)
        if component.frame and component.frame.Parent then return component.frame end
        local gui=mountScreen()
        if not gui then return nil end
        local frame=Instance.new("Frame")
        frame.Name="SCP2DCollisionBox"
        frame.BackgroundTransparency=1
        frame.BorderSizePixel=0
        frame.Visible=false
        local stroke=Instance.new("UIStroke")
        stroke.Thickness=Config.BoxThickness
        stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
        stroke.Parent=frame
        frame.Parent=gui
        component.frame,component.stroke=frame,stroke
        return frame
    end
    -- Exact projected rectangle of an oriented BasePart, not a guessed player height.
    local function projectBounds(cam,part)
        local cf,sz=part.CFrame,part.Size*0.5
        local left,top,right,bottom=math.huge,math.huge,-math.huge,-math.huge
        local hasFront=false
        for sx=-1,1,2 do for sy=-1,1,2 do for szSign=-1,1,2 do
            local world=cf:PointToWorldSpace(Vector3.new(sz.X*sx,sz.Y*sy,sz.Z*szSign))
            local p=cam:WorldToViewportPoint(world)
            if p.Z>0.05 then
                hasFront=true
                left=math.min(left,p.X);right=math.max(right,p.X)
                top=math.min(top,p.Y);bottom=math.max(bottom,p.Y)
            end
        end end end
        if not hasFront or right-left<2 or bottom-top<2 then return nil end
        local v=cam.ViewportSize
        if right<0 or bottom<0 or left>v.X or top>v.Y then return nil end
        return left,top,right,bottom
    end
    function ESP:Update(dt)
        if stopped then return end
        if not Config.Enabled or (not Config.Box and not Config.ShowNames and not Config.ShowJob and not Config.ShowDistance and not Config.ShowHealth) then
            if wasEnabled then
                for _,entry in pairs(entries) do hide(entry) end
                wasEnabled=false
            end
            return
        end
        wasEnabled=true
        local cam=Workspace.CurrentCamera
        if not cam then return end
        accumulator += dt or 1/60
        local minHz=math.clamp(tonumber(Config.TickRate) or 20,8,30)
        local interval=1/minHz
        if avg>3 then interval=math.max(interval,1/12) end
        if common.VisualInterval then interval=common.VisualInterval(interval) end
        if accumulator<interval and cam==lastCamera then return end
        lastCamera=cam
        accumulator=0
        serial+=1
        local start=os.clock()
        local visible=0
        local roster=common.Candidates:Get()
        local seen=0
        for _,cand in ipairs(roster) do
            seen+=1
            if visible>=Config.MaxEntries then break end
            local character=cand.Character
            if not (character and character.Parent and cand.Humanoid and cand.Humanoid.Health>0) then continue end
            if not cand.Player and not Config.TargetNPCs then continue end
            if Config.OnlyHostile and common.Candidates.IsHostile and not common.Candidates:IsHostile(cand) then continue end
            if cand.WorldDistance>Config.MaxDistance then continue end
            local anchor=cand.Anchor
            if not anchor or not anchor.Parent then continue end
            local projected=cam:WorldToViewportPoint(anchor.Position)
            if projected.Z<=0 then continue end
            local entry=construct(cand)
            entry.seen=serial
            visible+=1
            local color = not cand.Player and Config.ColorSCP
                or ((common.Candidates.IsHostile and common.Candidates:IsHostile(cand)) and Config.ColorEnemy or Config.ColorAlly)
            local mode=Config.Style
            for _,component in ipairs(entry.parts) do
                local part=component.part
                if part and part.Parent then
                    if mode=="3D" then
                        if component.frame then component.frame.Visible=false end
                        local adorn=ensureAdornment(component)
                        if adorn then
                            adorn.Adornee=part
                            if adorn.Size~=part.Size then adorn.Size=part.Size end
                            adorn.Color3=color
                            adorn.Transparency=Config.Transparency3D
                            adorn.Visible=Config.Box
                        end
                    else
                        if component.adorn then component.adorn.Visible=false end
                        local frame=ensureFrame(component)
                        if frame then
                            local x,y,rx,by=projectBounds(cam,part)
                            if x then
                                frame.Position=UDim2.fromOffset(x,y)
                                frame.Size=UDim2.fromOffset(rx-x,by-y)
                                component.stroke.Color=color
                                component.stroke.Transparency=Config.Transparency2D
                                component.stroke.Thickness=Config.BoxThickness
                                frame.Visible=Config.Box
                            else frame.Visible=false end
                        end
                    end
                end
            end
            local nameText=displayName(cand.Player,cand)
            local jobText=(Config.ShowJob and cand.Player) and role(cand.Player,cand) or ""
            local metaText=labelExtra(cand)
            if (nameText~="" or jobText~="" or metaText~="") and cand.Head then
                attachLabel(entry,cand.Head)
                if entry.label then
                    entry.label.Adornee=cand.Head
                    entry.label.Enabled=true
                    entry.label.StudsOffsetWorldSpace=Vector3.new(0,Config.LabelOffset,0)
                    local y=0
                    for _,line in ipairs({
                        {entry.text,nameText,Config.NameSize,color},
                        {entry.roleText,jobText,Config.JobSize,roleColor(cand.Player)},
                        {entry.metaText,metaText,math.max(10,Config.JobSize-2),color},
                    }) do
                        local label,text,size,tint=line[1],line[2],line[3],line[4]
                        label.Visible=text~=""
                        if label.Visible then
                            label.Position=UDim2.fromOffset(0,y)
                            label.Size=UDim2.new(1,0,0,size+4)
                            label.TextSize=size
                            label.TextStrokeTransparency=Config.LabelStroke == false and 1 or 0.2
                            if Config.LabelFont and Enum.Font[Config.LabelFont] then label.Font=Enum.Font[Config.LabelFont] end
                            label.Text=text
                            label.TextColor3=tint
                            y+=size+4
                        end
                    end
                    entry.label.Size=UDim2.fromOffset(260,math.max(y,18))
                end
            elseif entry.label then entry.label.Enabled=false end
        end
        for key,entry in pairs(entries) do
            if entry.seen~=serial or not key.Parent then
                -- Keep no stale ESP references after death, cull or team changes.
                dispose(entry);entries[key]=nil
            end
        end
        local elapsed=(os.clock()-start)*1000
        avg=avg==0 and elapsed or (avg*.8+elapsed*.2)
        ESP.Stats={Seen=seen,Visible=visible,Ms=elapsed,AverageMs=avg,Hz=1/interval,
            Mode=Config.Style,Failures=ESP.Stats.Failures or 0}
    end
    function ESP:Cleanup()
        if stopped then return end
        stopped=true
        clear()
        if screen then pcall(function()screen:Destroy()end) end
        screen=nil
    end
    common.OnCleanup(function()ESP:Cleanup()end)
    return ESP
end

end)()
local SCPInteractFactory = (function()
-- R226 instant prompt: event-driven HoldDuration=0, never spam remote calls.
-- Server validation, range and authorization are not bypassed.
return function(common)
    local promptService=game:GetService("ProximityPromptService")
    local Interact={Config={Enabled=false},Stats={Modified=0,Triggered=0,Visible=0}}
    local originals={}
    local shown={}
    local conns={}
    local function modify(prompt)
        if not prompt or not prompt.Parent or not prompt:IsA("ProximityPrompt") then return end
        if originals[prompt]==nil then originals[prompt]=prompt.HoldDuration end
        local ok=pcall(function()prompt.HoldDuration=0 end)
        if ok then Interact.Stats.Modified+=1 end
    end
    local function restore(prompt)
        local orig=originals[prompt]
        if orig~=nil then
            pcall(function()if prompt.Parent then prompt.HoldDuration=orig end end)
            originals[prompt]=nil
        end
    end
    function Interact:SetEnabled(value)
        self.Config.Enabled=value==true
        for prompt in pairs(shown) do
            if self.Config.Enabled then modify(prompt) else restore(prompt) end
        end
    end
    conns[#conns+1]=promptService.PromptShown:Connect(function(prompt)
        shown[prompt]=true
        if Interact.Config.Enabled then modify(prompt) end
        local count=0 for _ in pairs(shown) do count+=1 end
        Interact.Stats.Visible=count
    end)
    conns[#conns+1]=promptService.PromptHidden:Connect(function(prompt)
        shown[prompt]=nil
        restore(prompt)
        local count=0 for _ in pairs(shown) do count+=1 end
        Interact.Stats.Visible=count
    end)
    conns[#conns+1]=promptService.PromptTriggered:Connect(function()
        if Interact.Config.Enabled then Interact.Stats.Triggered+=1 end
    end)
    function Interact:Cleanup()
        for _,conn in ipairs(conns) do pcall(function()conn:Disconnect()end) end
        for prompt in pairs(originals) do restore(prompt) end
        table.clear(shown)
    end
    common.OnCleanup(function()Interact:Cleanup()end)
    return Interact
end

end)()
-- Vortexion - SCP v3: game-specific entry, unified WindUI UI.
-- Reference-informed feature coverage: modular subsystems, one
-- budgeted render loop, capability probing and version adaptation instead of
-- the original single mixed RenderStepped/Heartbeat loop.
-- Do not copy source implementations: use lifecycle-managed services in separate modules.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

--=========================================================================
-- Lifecycle: one live generation. A re-execute of the loader bumps the
-- generation and tears the previous instance down instead of stacking loops.
--=========================================================================
local global = (getgenv and getgenv()) or _G
if type(global.VortexionSCPCleanup) == "function" then
    pcall(global.VortexionSCPCleanup)
end
global.VortexionSCPGeneration = (global.VortexionSCPGeneration or 0) + 1
local generation = global.VortexionSCPGeneration
local connections = {}
local cleanups = {}
local function isCurrent()
    return global.VortexionSCPGeneration == generation
end
local function ownConnection(conn)
    if conn then table.insert(connections, conn) end
    return conn
end
local function ownCleanup(fn)
    table.insert(cleanups, fn)
end
local function cleanup()
    if global.VortexionSCPGeneration == generation then
        global.VortexionSCPGeneration += 1
    end
    for i = #connections, 1, -1 do
        pcall(function() connections[i]:Disconnect() end)
        connections[i] = nil
    end
    for i = #cleanups, 1, -1 do
        pcall(cleanups[i])
        cleanups[i] = nil
    end
end
global.VortexionSCPCleanup = cleanup

-- Executor identity is telemetry, not a compatibility oracle.
-- Earlier builds blacklisted Xeno/Velocity/LX63 and returned before creating
-- any UI, making all game features appear broken. Capability-dependent
-- features must degrade individually, not terminate the complete script.
local executorName = "unknown"
pcall(function()
    if type(identifyexecutor) == "function" then
        executorName = tostring(identifyexecutor() or "unknown")
    end
end)
global.VortexionExecutorName = executorName

--=========================================================================
-- UI: WindUI bridge (vendored, zero network). The original script loaded
-- Rayfield over HttpGet, which is both a dependency risk and a client-side
-- trace; the vendored UI keeps the whole hub self-contained.
--=========================================================================
local ok, ui = pcall(function() return WindBridgeFactory(WindUI) end)
if not ok or not ui then
    global.VortexionBootError = "SCP Bridge: " .. tostring(ui)
    warn("[Vortexion/SCP] WindUI initialization failed: " .. tostring(ui))
    return
end
-- R224: a UI constructor or Page registration may fail on an unsupported
-- Android executor. Fail closed with a readable bootstrap reason rather than
-- allowing the entire SCP entrypoint to abort halfway through initialization.
local windowOK, windowResult = pcall(function()
    return ui:CreateWindow({ Title = "Vortexion | SCP", Size = UDim2.fromOffset(790, 590) })
end)
if not windowOK or type(windowResult) ~= "table" or type(windowResult.AddTab) ~= "function" then
    local detail = windowOK and "invalid UI window" or tostring(windowResult)
    global.VortexionBootError = "SCP UI Window: " .. detail
    warn("[Vortexion/SCP] UI window unavailable: " .. detail)
    pcall(function() ui:Destroy() end)
    cleanup()
    return
end
local window = windowResult
ui:OnDestroy(cleanup)
local tabsOK, tabsResult = pcall(function()
    return {
        Aim = window:AddTab({ Title = "自瞄", Icon = "lucide-crosshair" }),
        Silent = window:AddTab({ Title = "静默", Icon = "lucide-target" }),
        Hitbox = window:AddTab({ Title = "碰撞箱", Icon = "lucide-box" }),
        Visual = window:AddTab({ Title = "视觉", Icon = "lucide-eye" }),
        Move = window:AddTab({ Title = "移动", Icon = "lucide-activity" }),
        World = window:AddTab({ Title = "世界", Icon = "lucide-globe" }),
        Info = window:AddTab({ Title = "信息", Icon = "lucide-info" }),
    }
end)
if not tabsOK or type(tabsResult) ~= "table" then
    local detail = tabsOK and "invalid page registry" or tostring(tabsResult)
    global.VortexionBootError = "SCP UI Pages: " .. detail
    warn("[Vortexion/SCP] UI pages unavailable: " .. detail)
    pcall(function() ui:Destroy() end)
    cleanup()
    return
end
local tabs = tabsResult

--=========================================================================
-- common singleton: every subsystem reads capabilities and shared state from
-- this table; nothing module-private leaks into the global environment.
--=========================================================================
local common = {
    Services = {
        Players = Players,
        RunService = RunService,
        Workspace = Workspace,
        HttpService = HttpService,
        TeleportService = TeleportService,
        VirtualUser = VirtualUser,
        Lighting = Lighting,
        Input = UserInputService,
    },
    LocalPlayer = LocalPlayer,
    UI = ui,
    Window = window,
    Tabs = tabs,
    IsCurrent = isCurrent,
    Own = ownConnection,
    OnCleanup = ownCleanup,
    Debug = false,
    PlaceId = game.PlaceId,
    GameVersion = "scp-v3",
}

local bootFailures = {}
local function reportBootFailure(component, message)
    local detail = tostring(component) .. ": " .. tostring(message):sub(1, 160)
    table.insert(bootFailures, detail)
    ui.BootStatus, ui.BootError = "partial", table.concat(bootFailures, "; ")
    warn("[Vortexion/SCP] " .. detail)
end
local function setup(name, factory)
    if type(factory) ~= "function" then
        reportBootFailure(name, "factory missing")
        return nil
    end
    local passed, result = pcall(factory, common)
    if not passed then
        reportBootFailure(name, result)
        return nil
    end
    return result
end

-- Order matters: capabilities first, then the shared candidate pool, then
-- consumers (cloak protects instances the aim/visual layers create).
setup("common", SCPCommonFactory)
common.Log = common.Log or function() end
common.Guard = common.Guard or function(_, fn, ...) local ok, err = pcall(fn, ...) if not ok then warn(tostring(err)) end return ok end
common.Cloak = setup("cloak", SCPCloakFactory) or { Protect = function(object) return object end, Stop = function() end, Start = function() end }
-- R224: never install global __namecall interception during SCP bootstrap.
-- Previous code hooked the entire game BEFORE UI/render setup; on some
-- executors this is a process-level crash, not a catchable Luau exception.
-- Runtime hooking is optional and is not a prerequisite for ESP/UI startup.
common.CloakStatus = "disabled by default (safe bootstrap)"
common.Candidates = setup("candidates", SCPCandidatesFactory) or { Update = function() end, Get = function() return {} end, NPCs = nil }
common.Camera = setup("camera", SCPCameraFactory) or { Update = function() end, GetCurrentTarget = function() end, Config = { Enabled = false } }
common.SilentAim = setup("silentaim", SCPSilentAimFactory) or { Update = function() end, Config = { Enabled = false } }
common.Hitbox = setup("hitbox", SCPHitboxFactory) or { Update = function() end, Config = { Enabled = false } }
common.Movement = setup("movement", SCPMovementFactory) or { Update = function() end, Start = function() end, Config = { SpeedEnabled = false } }
common.ESP = setup("esp", SCPESPFactory) or { Update = function() end, Config = { Enabled = false } }
common.Interact = (type(SCPInteractFactory)=="function" and setup("interact", SCPInteractFactory)) or {SetEnabled=function()end,Stats={Visible=0}}

local Camera = common.Camera
local SilentAim = common.SilentAim
local Hitbox = common.Hitbox
local Movement = common.Movement
local ESP = common.ESP
local Interact = common.Interact
local Candidates = common.Candidates
if type(ui.RegisterFeatureHealth) == "function" then
    ui:RegisterFeatureHealth("SCP", function()
        local frame = Candidates and Candidates.Frame or 0
        return ("存活=%s 角色=%s 候选扫描=%s 模块失败=%d")
            :format(tostring(isCurrent()), tostring(LocalPlayer.Character ~= nil),
                tostring(frame), #bootFailures)
    end)
end


--=========================================================================
-- NPC scan: SCP roleplay populates the map with humanoid NPCs; without the
-- scanner they are invisible to every targeting feature.
--=========================================================================
task.defer(function()
    if isCurrent() then
        common.Guard("Candidates", function()
            if Candidates.StartNPCScan then Candidates:StartNPCScan() end
        end)
    end
end)

--=========================================================================
-- Movement runs on Heartbeat (physics step), not the render step: velocity
-- writes land before the physics solver reads them.
--=========================================================================
common.Guard("Movement", function() Movement:Start() end)
ownConnection(RunService.Heartbeat:Connect(function(dt)
    if not isCurrent() then return end
    common.Guard("Movement", function() Movement:Update(dt) end)
end))

--=========================================================================
-- World features preserved from the original script, re-hosted on the shared
-- loop with low-frequency timers instead of per-frame work.
--=========================================================================
local world = {
    Fullbright = false,
    AntiRagdoll = false,
    AntiAFK = true,
    DeleteDoors = false,
}
local origLighting = nil
local function captureLighting()
    origLighting = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient }
end

local function applyFullbright()
    Lighting.Brightness = 2
    Lighting.ClockTime = 12
    Lighting.FogEnd = 1e10
    Lighting.Ambient = Color3.new(1, 1, 1)
    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
end

local function restoreLighting()
    if not origLighting then return end
    Lighting.Brightness = origLighting.Brightness
    Lighting.ClockTime = origLighting.ClockTime
    Lighting.FogEnd = origLighting.FogEnd
    Lighting.Ambient = origLighting.Ambient
    Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
    origLighting = nil
end
ownCleanup(restoreLighting)

local afkHeld = false
ownCleanup(function()
    if afkHeld then pcall(function() VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new()) end) afkHeld = false end
end)
ownConnection(LocalPlayer.Idled:Connect(function()
    if not isCurrent() or not world.AntiAFK or afkHeld then return end
    pcall(function()
        afkHeld = true
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
        task.wait(1)
        if afkHeld then
            VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
            afkHeld = false
        end
    end)
end))

--=========================================================================
-- Triggerbot: fires while the aimbot holds a lock. Uses executor mouse
-- functions when present, VirtualUser otherwise.
--=========================================================================
local trigger = {
    Enabled = false,
    Mode = "Locked",        -- Locked | Always
    IntervalMs = 180,
    lastFire = 0,
    firing = false,
}
local function mouseDown()
    if type(mouse1press) == "function" then
        mouse1press()
    else
        pcall(function() VirtualUser:Button1Down(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new()) end)
    end
end
local function mouseUp()
    if type(mouse1release) == "function" then
        mouse1release()
    else
        pcall(function() VirtualUser:Button1Up(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new()) end)
    end
end
local function updateTrigger()
    if not trigger.Enabled then
        if trigger.firing then mouseUp() trigger.firing = false end
        return
    end
    local locked = Camera.GetCurrentTarget and Camera:GetCurrentTarget()
    local shouldFire = (trigger.Mode == "Always") or (locked ~= nil)
    local now = tick() * 1000
    if shouldFire and now - trigger.lastFire >= trigger.IntervalMs then
        trigger.lastFire = now
        if not trigger.firing then
            mouseDown()
            trigger.firing = true
            task.delay(0.08, function()
                if trigger.firing then
                    mouseUp()
                    trigger.firing = false
                end
            end)
        end
    elseif not shouldFire and trigger.firing then
        mouseUp()
        trigger.firing = false
    end
end

--=========================================================================
-- Single render loop: one BindToRenderStep(Last) drives every visual-side
-- subsystem. Per-subsystem costs and over-budget streaks are reported in
-- the debug snapshot; Guard isolates errors and throttles warnings.
--
-- Candidate/ESP/hitbox accumulators handle cadence independently of render FPS.
--=========================================================================
local budgets = { Aim = 1.2, Hitbox = 0.6, ESP = 1.0 }
local costs = { Aim = 0, Hitbox = 0, ESP = 0, Candidates = 0 }
local slowLoops = { Aim = 0, Hitbox = 0, ESP = 0 }
local lastSnapshot = 0
local lowFreqTimer = 0

local renderName = "VortexionSCPFrame"
local function renderFrame(dt)
    if not isCurrent() then return end
    common.Guard("Frame", function()
        -- Low-frequency world features (0.5 s cadence).
        lowFreqTimer += dt
        if lowFreqTimer >= 0.5 then
            lowFreqTimer = 0
            if world.Fullbright then applyFullbright() end
            if world.AntiRagdoll and LocalPlayer.Character then
                local rag = LocalPlayer.Character:FindFirstChild("Ragdoll")
                if rag then pcall(function() rag:Destroy() end) end
            end
        end


        -- R226: keep idle frame cost near zero. Each disabled module's toggle
        -- synchronously calls its own reset/restore entrypoint.
        local needCandidates = (Camera.Config and Camera.Config.Enabled)
            or (SilentAim.Config and SilentAim.Config.Enabled)
            or (Hitbox.Config and Hitbox.Config.Enabled)
            or (ESP.Config and ESP.Config.Enabled)
        local t0=tick()
        if needCandidates then common.Guard("Candidates", function() Candidates:Update(dt) end) end
        costs.Candidates=needCandidates and (tick()-t0)*1000 or 0
        t0=tick()
        if Camera.Config and Camera.Config.Enabled then
            common.Guard("Camera", function() Camera:Update(dt) end)
        end
        costs.Aim=(Camera.Config and Camera.Config.Enabled) and (tick()-t0)*1000 or 0
        if SilentAim.Config and SilentAim.Config.Enabled then
            common.Guard("SilentAim", function() SilentAim:Update() end)
        end
        t0=tick()
        if Hitbox.Config and Hitbox.Config.Enabled then
            common.Guard("Hitbox", function() Hitbox:Update(dt) end)
        end
        costs.Hitbox=(Hitbox.Config and Hitbox.Config.Enabled) and (tick()-t0)*1000 or 0
        t0=tick()
        if ESP.Config and ESP.Config.Enabled then
            common.Guard("ESP", function() ESP:Update(dt) end)
        end
        costs.ESP=(ESP.Config and ESP.Config.Enabled) and (tick()-t0)*1000 or 0
        if trigger.Enabled or trigger.firing then common.Guard("Trigger", updateTrigger) end

        -- Budget watchdog: count consecutive over-budget frames per
        -- subsystem; the snapshot surfaces them for tuning.
        for name, cost in pairs(costs) do
            local budget = budgets[name]
            if budget and cost > budget then
                slowLoops[name] = (slowLoops[name] or 0) + 1
            elseif slowLoops[name] then
                slowLoops[name] = 0
            end
        end

        -- Debug snapshot: 2 s cadence, one line per subsystem.
        if common.Debug and tick() - lastSnapshot >= 2 then
            lastSnapshot = tick()
            local locked = Camera.GetCurrentTarget and Camera:GetCurrentTarget()
            common.Log("Frame", ("cand=%.2fms aim=%.2fms hitbox=%.2fms esp=%.2fms slow(a/h/e)=%d/%d/%d lock=%s")
                :format(costs.Candidates, costs.Aim, costs.Hitbox, costs.ESP,
                    slowLoops.Aim or 0, slowLoops.Hitbox or 0, slowLoops.ESP or 0,
                    locked and tostring(locked.Player and locked.Player.Name or "NPC") or "-"))
        end
    end)
end
local renderOk,renderErr=pcall(function()
    RunService:BindToRenderStep(renderName, Enum.RenderPriority.Last.Value, renderFrame)
end)
if not renderOk then
    reportBootFailure("render", renderErr)
    ownConnection(RunService.RenderStepped:Connect(renderFrame))
else
    ownCleanup(function() pcall(function() RunService:UnbindFromRenderStep(renderName) end) end)
end
ownCleanup(function() if trigger.firing then mouseUp() trigger.firing = false end end)

--=========================================================================
-- UI wiring.
--=========================================================================
tabs.Aim:AddToggle("SCPAimEnabled", { Title = "自瞄总开关", Default = false, Callback = function(v) Camera.Config.Enabled = v if not v then Camera:Update(0) end end })
tabs.Aim:AddDropdown("SCPAimMode", { Title = "模式", Values = { "Camera", "Mouse", "Both" }, Default = "Camera", Callback = function(v) Camera.Config.Mode = v end })
tabs.Aim:AddSlider("SCPAimFov", { Title = "FOV (px)", Min = 20, Max = 650, Default = 240, Rounding = 0, Callback = function(v) Camera.Config.FOV = v end })
tabs.Aim:AddSlider("SCPAimDist", { Title = "最大距离 (studs)", Min = 50, Max = 2000, Default = 700, Rounding = 0, Callback = function(v) Camera.Config.MaxDistance = v end })
tabs.Aim:AddSlider("SCPAimSmooth", { Title = "平滑度", Min = 50, Max = 99, Default = 85, Rounding = 0, Callback = function(v) Camera.Config.Smoothness = v / 100 end })
tabs.Aim:AddDropdown("SCPAimPart", { Title = "部位", Values = { "Head", "Torso", "Arms", "Legs", "Random" }, Default = "Head", Callback = function(v) Camera.Config.Hitbox = v end })
tabs.Aim:AddSlider("SCPAimAngle", { Title = "最大夹角 (度)", Min = 5, Max = 90, Default = 30, Rounding = 0, Callback = function(v) Camera.Config.MaxAngle = v end })
tabs.Aim:AddSlider("SCPAimPrediction", { Title = "预瞄", Min = 0, Max = 50, Default = 12, Rounding = 0, Callback = function(v) Camera.Config.Prediction = v / 100 end })
tabs.Aim:AddSlider("SCPAimHitChance", { Title = "锁定命中率", Min = 10, Max = 100, Default = 100, Rounding = 0, Callback = function(v) Camera.Config.HitChance = v / 100 end })
tabs.Aim:AddToggle("SCPAimWall", { Title = "遮挡检查", Default = true, Callback = function(v) Camera.Config.WallCheck = v end })
tabs.Aim:AddToggle("SCPAimTeam", { Title = "只锁定敌对阵营", Default = true, Callback = function(v) Camera.Config.TeamCheck = v end })
tabs.Aim:AddToggle("SCPAimNPC", { Title = "锁定 NPC", Default = true, Callback = function(v) Camera.Config.TargetNPCs = v end })
tabs.Aim:AddDropdown("SCPAimKey", { Title = "触发键", Values = { "Right", "Left", "None", "Touch", "Always" }, Default = Camera.Config.TriggerKey or "Always", Callback = function(v) Camera.Config.TriggerKey = v if Camera.ResetTrigger then Camera:ResetTrigger() end end })
tabs.Aim:AddToggle("SCPAimFovCircle", { Title = "FOV 圈", Default = true, Callback = function(v) Camera.Config.FOVCircle = v end })
tabs.Aim:AddToggle("SCPTrigger", { Title = "自动开火（锁定时）", Default = false, Callback = function(v) trigger.Enabled = v if not v then updateTrigger() end end })

tabs.Silent:AddToggle("SCPSilentEnabled", { Title = "静默瞄准总开关", Default = false, Callback = function(v) SilentAim.Config.Enabled = v end })
tabs.Silent:AddSlider("SCPSilentAngle", { Title = "最大夹角 (度)", Min = 5, Max = 60, Default = 15, Rounding = 0, Callback = function(v) SilentAim.Config.MaxAngle = v end })
tabs.Silent:AddSlider("SCPSilentChance", { Title = "命中率", Min = 10, Max = 100, Default = 72, Rounding = 0, Callback = function(v) SilentAim.Config.HitChance = v / 100 end })
tabs.Silent:AddToggle("SCPSilentWall", { Title = "遮挡检查", Default = true, Callback = function(v) SilentAim.Config.WallCheck = v end })
tabs.Silent:AddToggle("SCPSilentTeam", { Title = "队伍过滤", Default = false, Callback = function(v) SilentAim.Config.TeamCheck = v end })
tabs.Silent:AddParagraph({ Title = "静默瞄准说明", Content = "改写客户端发往服务端的命中参数；参数按单位方向/世界坐标两种形态标定，命中点限制在服务端可判定的原始包络内。" })

tabs.Hitbox:AddToggle("SCPHitboxEnabled", { Title = "碰撞箱扩展", Default = false, Callback = function(v) Hitbox.Config.Enabled = v if not v then Hitbox:Update(0) end end })
tabs.Hitbox:AddDropdown("SCPHitboxMode", { Title = "模式", Values = { "all", "fullBody", "lockedOnly" }, Default = "all", Callback = function(v) Hitbox.Config.Mode = v end })
tabs.Hitbox:AddSlider("SCPHitboxScale", { Title = "峰值倍率", Min = 10, Max = 30, Default = 18, Rounding = 0, Callback = function(v) Hitbox.Config.ScaleMax = v / 10 end })
tabs.Hitbox:AddSlider("SCPHitboxDist", { Title = "作用距离 (studs)", Min = 50, Max = 1000, Default = 500, Rounding = 0, Callback = function(v) Hitbox.Config.MaxDistance = v end })
tabs.Hitbox:AddSlider("SCPHitboxFov", { Title = "屏幕门 (px)", Min = 50, Max = 1000, Default = 600, Rounding = 0, Callback = function(v) Hitbox.Config.FOV = v end })
tabs.Hitbox:AddSlider("SCPHitboxActive", { Title = "同帧目标数", Min = 1, Max = 16, Default = 8, Rounding = 0, Callback = function(v) Hitbox.Config.MaxActive = v end })
tabs.Hitbox:AddToggle("SCPHitboxHostile", {Title="只处理敌对阵营",Default=false,Callback=function(v)Hitbox.Config.OnlyHostile=v end})
tabs.Hitbox:AddToggle("SCPHitboxNPC", {Title="包含SCP收容体",Default=true,Callback=function(v)Hitbox.Config.TargetNPCs=v end})
tabs.Hitbox:AddParagraph({ Title = "碰撞箱说明", Content = "20Hz 节流、尺寸平滑与距离衰减；关闭或角色替换时恢复尺寸、透明度和碰撞属性。" })

-- R226 five essential ESP diagnostics: faction, names, hitbox style, role, SCP classification/color.
tabs.Visual:AddToggle("SCPESPEnabled", {Title="ESP 总开关",Default=false,Callback=function(v)ESP.Config.Enabled=v if not v then ESP:Update(0) end end})
tabs.Visual:AddToggle("SCPESPHostile", {Title="仅显示敌对阵营",Default=false,Callback=function(v)ESP.Config.OnlyHostile=v end})
tabs.Visual:AddToggle("SCPESPNames", {Title="显示名称",Default=true,Callback=function(v)ESP.Config.ShowNames=v end})
tabs.Visual:AddDropdown("SCPESPNameFormat", {Title="名称类型",Values={"用户名","实体名"},Default="用户名",Callback=function(v)ESP.Config.NameFormat=v end})
tabs.Visual:AddDropdown("SCPESPStyle", {Title="ESP 样式（碰撞箱）",Values={"3D","2D"},Default="3D",Callback=function(v)ESP.Config.Style=v end})
tabs.Visual:AddToggle("SCPESPJob", {Title="显示职位 / 军衔",Default=false,Callback=function(v)ESP.Config.ShowJob=v end})
tabs.Visual:AddToggle("SCPESPNPC", {Title="显示 SCP收容体",Default=true,Callback=function(v)ESP.Config.TargetNPCs=v end})
tabs.Visual:AddColorpicker("SCPESPColorSCP", {Title="SCP收容体颜色（默认黑）",Default=ESP.Config.ColorSCP,Callback=function(v)if typeof(v)=="Color3" then ESP.Config.ColorSCP=v end end})
tabs.Visual:AddColorpicker("SCPESPColorEnemy", {Title="敌对阵营颜色",Default=ESP.Config.ColorEnemy,Callback=function(v)if typeof(v)=="Color3" then ESP.Config.ColorEnemy=v end end})
tabs.Visual:AddColorpicker("SCPESPColorAlly", {Title="其他阵营颜色",Default=ESP.Config.ColorAlly,Callback=function(v)if typeof(v)=="Color3" then ESP.Config.ColorAlly=v end end})
tabs.Visual:AddSlider("SCPESPDist", {Title="显示距离",Min=100,Max=2000,Default=850,Rounding=0,Callback=function(v)ESP.Config.MaxDistance=v end})
tabs.Visual:AddSlider("SCPESPFPS", {Title="刷新率（Hz）",Min=8,Max=30,Default=20,Rounding=0,Callback=function(v)ESP.Config.TickRate=v end})
-- R228: ESP appearance controls preserve existing IDs and add separate label/color settings.
tabs.Visual:AddSlider("SCPESPAlpha3D", {Title="3D 盒子透明度 (%)",Min=0,Max=100,Default=30,Rounding=0,Callback=function(v)ESP.Config.Transparency3D=v/100 end})
tabs.Visual:AddSlider("SCPESPAlpha2D", {Title="2D 方框透明度 (%)",Min=0,Max=100,Default=15,Rounding=0,Callback=function(v)ESP.Config.Transparency2D=v/100 end})
tabs.Visual:AddToggle("SCPESPJobColor", {Title="职位跟随游戏队伍颜色",Default=true,Callback=function(v)ESP.Config.JobTeamColor=v end})
tabs.Visual:AddToggle("SCPESPJobZH", {Title="职位中文翻译",Default=true,Callback=function(v)ESP.Config.JobTranslate=v end})
tabs.Visual:AddSlider("SCPESPNameFont", {Title="名称文字大小",Min=10,Max=26,Default=14,Rounding=0,Callback=function(v)ESP.Config.NameSize=v end})
tabs.Visual:AddSlider("SCPESPJobFont", {Title="职位文字大小",Min=10,Max=26,Default=13,Rounding=0,Callback=function(v)ESP.Config.JobSize=v end})
tabs.Visual:AddSlider("SCPESPBoxWidth", {Title="2D 方框线宽",Min=1,Max=4,Default=2,Rounding=0,Callback=function(v)ESP.Config.BoxThickness=v end})
tabs.Visual:AddSlider("SCPESPLabelOffset", {Title="文字显示高度",Min=0,Max=60,Default=24,Rounding=0,Callback=function(v)ESP.Config.LabelOffset=v/10 end})
tabs.Visual:AddToggle("SCPESPDistance", {Title="显示目标距离",Default=false,Callback=function(v)ESP.Config.ShowDistance=v end})
tabs.Visual:AddToggle("SCPESPHealth", {Title="显示目标生命值",Default=false,Callback=function(v)ESP.Config.ShowHealth=v end})
tabs.Visual:AddSlider("SCPESPMaxTargets", {Title="ESP 最大目标数",Min=8,Max=64,Default=36,Rounding=0,Callback=function(v)ESP.Config.MaxEntries=v end})
tabs.Visual:AddParagraph({Title="性能与模式",Content="3D原生渲染自动跟随碰撞部件；2D按刷新率投影实际头/躯干碰撞框，默认不依赖Drawing；关闭后清理全部对象。"})

tabs.Move:AddToggle("SCPSpeed", { Title = "加速", Default = false, Callback = function(v) Movement.Config.SpeedEnabled = v end })
tabs.Move:AddSlider("SCPSpeedVal", { Title = "速度值", Min = 16, Max = 150, Default = 16, Rounding = 0, Callback = function(v) Movement.Config.SpeedValue = v end })
tabs.Move:AddToggle("SCPFly", { Title = "飞行", Default = false, Callback = function(v) Movement.Config.FlyEnabled = v end })
tabs.Move:AddToggle("SCPTouchFly", { Title = "触屏拖动飞行", Default = true, Callback = function(v) Movement.Config.TouchFly = v end })
tabs.Move:AddSlider("SCPFlySpeed", { Title = "飞行速度", Min = 10, Max = 300, Default = 60, Rounding = 0, Callback = function(v) Movement.Config.FlySpeed = v end })
tabs.Move:AddToggle("SCPNoclip", { Title = "穿墙", Default = false, Callback = function(v) if Movement.SetNoclip then Movement:SetNoclip(v) else Movement.Config.Noclip = v end end })
tabs.Move:AddToggle("SCPJump", { Title = "超级跳", Default = false, Callback = function(v) Movement.Config.JumpEnabled = v end })
tabs.Move:AddSlider("SCPJumpVal", { Title = "跳跃力", Min = 20, Max = 250, Default = 50, Rounding = 0, Callback = function(v) Movement.Config.JumpValue = v end })

tabs.World:AddToggle("SCPInstantInteract", {Title="秒交互（ProximityPrompt）",Default=false,Callback=function(v)Interact:SetEnabled(v) end})
tabs.World:AddParagraph({Title="秒交互说明",Content="仅对当前显示的交互提示清零按住时间；不增加交互距离、不越过权限或服务端验证。"})
tabs.World:AddToggle("SCPFullbright", { Title = "全亮", Default = false, Callback = function(v)
    if v and not world.Fullbright then captureLighting() end
    world.Fullbright = v
    if v then applyFullbright() else restoreLighting() end
end })
tabs.World:AddToggle("SCPAntiRagdoll", { Title = "反布娃娃", Default = false, Callback = function(v) world.AntiRagdoll = v end })
tabs.World:AddToggle("SCPAntiAFK", { Title = "反挂机", Default = true, Callback = function(v) world.AntiAFK = v end })
tabs.World:AddButton({ Title = "删除门", Callback = function()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if string.lower(obj.Name):find("door") then
            pcall(function() obj:Destroy() end)
        end
    end
end })
tabs.World:AddButton({ Title = "重新加入", Callback = function()
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end })
tabs.World:AddButton({ Title = "低延迟切服（通用）", Callback = function()
    if not ui.ServerSwitch then return end
    local ok, reason = ui.ServerSwitch:Switch()
    if not ok then ui:Notify({Title = "低延迟切服", Content = reason, Duration = 4}) end
end })

tabs.Info:AddButton({Title="ESP / 自瞄 / 碰撞箱诊断",Callback=function()
    local es=ESP.Stats or {} local cs=Camera.Stats or {} local hs=Hitbox.Stats or {}
    local text=("ESP %s: %d/%d, %.2fms; 自瞄: %s (%s); 碰撞箱: %d/%d; 秒交互: %d")
        :format(tostring(es.Mode or "3D"),es.Visible or 0,es.Seen or 0,es.AverageMs or 0,
          tostring(cs.Reason or "未知"),tostring(cs.Locked or "-"),hs.Expanded or 0,hs.Eligible or 0,
          Interact.Stats and Interact.Stats.Modified or 0)
    pcall(function()ui:Notify({Title="SCP R226 运行诊断",Content=text,Duration=8})end)
end})
tabs.Info:AddToggle("SCPDebug", { Title = "调试输出", Default = false, Callback = function(v) common.Debug = v end })
tabs.Info:AddParagraph({ Title = "兼容性说明",
    Content = ("PlaceId %d / 构建 scp-v3。R15 与 R6 角色自适应；Drawing 缺失时线条停用、Chams 可独立工作；元表钩子缺失时静默瞄准自动停用；候选与绘制刷新率独立于帧率；触屏默认右侧按住。")
        :format(game.PlaceId) })
tabs.Info:AddToggle("SCPAdvancedCloak", {Title="高级隐藏 Hook（兼容性风险，默认关闭）",Default=false,Callback=function(v)
    if type(common.Cloak.Start)~="function" then return end
    if v then
        common.CloakStatus="user enabled"
        common.Guard("Cloak",function() common.Cloak.Start() end)
    else
        common.CloakStatus="user disabled"
        common.Guard("Cloak",function() common.Cloak.Stop() end)
    end
end})
tabs.Info:AddButton({ Title = "子模块初始化诊断", Callback = function()
    pcall(function() ui:Notify({Title = "SCP 启动诊断",
        Content = #bootFailures > 0 and table.concat(bootFailures, " / ") or "模块工厂未报告失败；功能运行仍需实际测试", Duration = 6}) end)
end })
tabs.Info:AddButton({ Title = "检查运行状态", Callback = function()
    local caps = common.Caps or {}
    pcall(function()
        ui:Notify({ Title = "Vortexion SCP", Content = ("Drawing=%s 钩子=%s 鼠标=%s gethui=%s 目标=%d")
            :format(tostring(caps.Drawing or caps.DrawingUserdata), tostring(caps.hookmetamethod or caps.getrawmetatable),
                tostring(caps.mousemoverel), tostring(caps.gethui), #(Candidates:Get() or {})), Duration = 5 })
    end)
end })
tabs.Info:AddButton({ Title = "卸载全部 SCP 功能", Callback = function()
    cleanup()
    pcall(function() ui:Destroy() end)
end })
tabs.Info:AddButton({ Title = "一键恢复普通视角", Callback = function()
    if not isCurrent() then return end
    Camera.Config.Enabled = false
    pcall(function() Camera:ResetTrigger() end)
    pcall(function() Camera:Update(0) end)
    local aimOption = ui and ui.Options and ui.Options.SCPAimEnabled
    if aimOption and type(aimOption.SetValue) == "function" then pcall(function() aimOption:SetValue(false) end) end
    if not isCurrent() then return end
    local ready, cam, hum = pcall(function()
        local char = LocalPlayer and LocalPlayer.Character
        return Workspace.CurrentCamera, char and char:FindFirstChildWhichIsA("Humanoid")
    end)
    if not ready or not cam or not hum then
        pcall(function() ui:Notify({ Title = "Vortexion SCP", Content = "已关闭视角辅助；角色或相机尚未就绪", Duration = 4 }) end)
        return
    end
    local restored = pcall(function()
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = hum
    end)
    if not isCurrent() then return end
    pcall(function() ui:Notify({ Title = "Vortexion SCP", Content = restored and "已恢复普通视角" or "视角属性更新未完成", Duration = 4 }) end)
end })

tabs.Aim:AddDropdown("SCPTouchMode", { Title = "触屏触发方式", Values = { "Hold", "Toggle" }, Default = "Hold", Callback = function(v) Camera.Config.TouchMode = v if Camera.ResetTrigger then Camera:ResetTrigger() end end })
tabs.Aim:AddDropdown("SCPTouchRegion", { Title = "触屏区域（避开摇杆）", Values = { "Right", "Full" }, Default = "Right", Callback = function(v) common.Touch.Region = v end })
tabs.Aim:AddSlider("SCPAimAttraction", { Title = "鼠标吸附力度", Min = 10, Max = 100, Default = 60, Rounding = 0, Callback = function(v) Camera.Config.Attraction = v / 100 end })
tabs.Aim:AddToggle("SCPAimDampening", { Title = "近准星减速", Default = true, Callback = function(v) Camera.Config.Dampening = v end })
tabs.Aim:AddSlider("SCPTriggerInterval", { Title = "开火间隔 (ms)", Min = 100, Max = 1000, Default = 180, Rounding = 0, Callback = function(v) trigger.IntervalMs = v end })
tabs.Hitbox:AddSlider("SCPHitboxHeadScale", { Title = "头部独立倍率", Min = 10, Max = 30, Default = 10, Rounding = 0, Callback = function(v) Hitbox.Config.HeadScale = v / 10 end })
tabs.Hitbox:AddSlider("SCPHitboxTorsoScale", { Title = "躯干独立倍率", Min = 10, Max = 25, Default = 10, Rounding = 0, Callback = function(v) Hitbox.Config.TorsoScale = v / 10 end })
tabs.Visual:AddToggle("SCPESPLabels", { Title = "名字 / 距离", Default = false, Callback = function(v) ESP.Config.Labels = v end })
tabs.Visual:AddDropdown("SCPTracerOrigin", { Title = "射线起点", Values = { "Bottom", "Center" }, Default = "Bottom", Callback = function(v) ESP.Config.TracerOrigin = v end })
tabs.Visual:AddSlider("SCPESPRefresh", { Title = "绘制刷新率 (Hz)", Min = 5, Max = 60, Default = 20, Rounding = 0, Callback = function(v) ESP.Config.TickRate = v end })
tabs.Visual:AddSlider("SCPESPBudget", { Title = "显示目标上限", Min = 8, Max = 96, Default = 64, Rounding = 0, Callback = function(v) ESP.Config.MaxEntries = v end })
tabs.Move:AddSlider("SCPTouchDeadzone", { Title = "触屏拖动死区 (px)", Min = 5, Max = 50, Default = 10, Rounding = 0, Callback = function(v) Movement.Config.TouchDeadzone = v end })
tabs.Move:AddSlider("SCPTouchSensitivity", { Title = "满速拖动距离 (px)", Min = 40, Max = 240, Default = 120, Rounding = 0, Callback = function(v) Movement.Config.TouchSensitivity = v end })
tabs.Info:AddSlider("SCPCandidateRefresh", { Title = "候选刷新率 (Hz)", Min = 5, Max = 60, Default = 20, Rounding = 0, Callback = function(v) if Candidates.Config then Candidates.Config.TickRate = v end end })
tabs.Visual:AddToggle("SCPESPOffScreen", { Title = "屏外方向箭头", Default = false, Callback = function(v) ESP.Config.OffScreen = v if not v then ESP:Update(0) end end })
tabs.Visual:AddToggle("SCPESPOffScreenDistance", { Title = "屏外距离数字（需Drawing）", Default = false, Callback = function(v) ESP.Config.OffScreenDistance = v if not v then ESP:Update(0) end end })
tabs.Visual:AddSlider("SCPESPOffScreenBudget", { Title = "屏外目标独立上限", Min = 1, Max = 64, Default = 16, Rounding = 0, Callback = function(v) ESP.Config.MaxOffScreen = v end })
tabs.Visual:AddSlider("SCPESPOffScreenSize", { Title = "屏外箭头尺寸(px)", Min = 8, Max = 30, Default = 14, Rounding = 0, Callback = function(v)
    if not isCurrent() then return end
    local n = tonumber(v)
    if not n or n ~= n or math.abs(n) == math.huge then n = 14 end
    ESP.Config.OffScreenSize = math.floor(math.clamp(n, 8, 30) + 0.5)
end })
tabs.Visual:AddSlider("SCPESPOffScreenMargin", { Title = "屏外箭头边距(px)", Min = 8, Max = 80, Default = 28, Rounding = 0, Callback = function(v)
    if not isCurrent() then return end
    local n = tonumber(v)
    if not n or n ~= n or math.abs(n) == math.huge then n = 28 end
    ESP.Config.OffScreenMargin = math.floor(math.clamp(n, 8, 80) + 0.5)
end })
tabs.Visual:AddToggle("SCPESPNativeLabels", { Title = "原生标签（无 Drawing 可用）", Default = false, Callback = function(v) ESP.Config.NativeLabels = v if not v then ESP:Update(0) end end })
tabs.Visual:AddSlider("SCPESPLabelTextSize", { Title = "标签字号", Min = 10, Max = 28, Default = 14, Rounding = 0, Callback = function(v) ESP.Config.LabelTextSize = v end })
tabs.Visual:AddDropdown("SCPESPLabelFont", { Title = "原生标签字体", Values = { "GothamBold", "Gotham", "SourceSans", "Code" }, Default = "GothamBold", Callback = function(v) ESP.Config.LabelFont = v end })
tabs.Visual:AddToggle("SCPESPLabelStroke", { Title = "标签文字描边", Default = true, Callback = function(v) ESP.Config.LabelStroke = v end })
tabs.Visual:AddSlider("SCPESPLabelBackground", { Title = "原生标签背景透明度", Min = 0, Max = 100, Default = 100, Rounding = 0, Callback = function(v) ESP.Config.LabelBackgroundTransparency = v / 100 end })
tabs.Move:AddButton({ Title = "立即起跳", Callback = function() Movement:RequestJump(true) end })
tabs.Move:AddSlider("SCPTeleportDist", { Title = "前向传送距离 (studs)", Min = 10, Max = 200, Default = 50, Rounding = 0, Callback = function(v) Movement.Config.TeleportDistance = v end })
tabs.Move:AddButton({ Title = "向前传送", Callback = function() Movement:TeleportForward() end })

window:SelectTab(1)
pcall(function()
    ui:Notify({ Title = "Vortexion - SCP", Content = "模块已加载；进入场景后启用对应功能", Duration = 4 })
end)
common.Log("Core", "loaded place=" .. tostring(game.PlaceId) .. " gen=" .. tostring(generation))

end
return GameRouter.Run(WindUI, WindBridgeFactory, entry, game.GameId, game.PlaceId, "SCP")
