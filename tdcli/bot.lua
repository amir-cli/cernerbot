package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
.. ';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

--amir
tdcli = dofile('tdcli.lua')
redis = (loadfile "./libs/redis.lua")()
serpent = require('serpent')
serp = require 'serpent'.block
sudo_users = {
  317391435
  0
}


function is_sudo(msg)
  local var = false
  for v,user in pairs(sudo_users) do
    if user == msg.sender_user_id_ then
      var = true
    end
  end
  return var
end


-- function owner
function is_owner(msg)
  local var = false
  local chat_id = msg.chat_id_
  local user_id = msg.sender_user_id_
  local group_mods = redis:get('owners:'..chat_id)
  if group_mods == tostring(user_id) then
    var = true
  end
  for v, user in pairs(sudo_users) do
    if user == user_id then
      var = true
    end
  end
  return var
end
--- function promote
function is_mod(msg)
  local var = false
  local chat_id = msg.chat_id_
  local user_id = msg.sender_user_id_
  if redis:sismember('mods:'..chat_id,user_id) then
    var = true
  end
  if  redis:get('owners:'..chat_id) == tostring(user_id) then
    var = true
  end
  for v, user in pairs(sudo_users) do
    if user == user_id then
      var = true
    end
  end
  return var
end
-- Print message format. Use serpent for prettier result.
function vardump(value, depth, key)
  local linePrefix = ''
  local spaces = ''

  if key ~= nil then
    linePrefix = key .. ' = '
  end

  if depth == nil then
    depth = 0
  else
    depth = depth + 1
    for i=1, depth do
      spaces = spaces .. '  '
    end
  end

  if type(value) == 'table' then
    mTable = getmetatable(value)
    if mTable == nil then
      print(spaces .. linePrefix .. '(table) ')
    else
      print(spaces .. '(metatable) ')
      value = mTable
    end
    for tableKey, tableValue in pairs(value) do
      vardump(tableValue, depth, tableKey)
    end
  elseif type(value)  == 'function' or
    type(value) == 'thread' or
    type(value) == 'userdata' or
    value == nil then 
    print(spaces .. tostring(value))
  elseif type(value)  == 'string' then
    print(spaces .. linePrefix .. '"' .. tostring(value) .. '",')
  else
    print(spaces .. linePrefix .. tostring(value) .. ',')
  end
end

-- Print callback
function dl_cb(arg, data)
end


local function setowner_reply(extra, result, success)
  t = vardump(result)
  local msg_id = result.id_
  local user = result.sender_user_id_
  local ch = result.chat_id_
  redis:del('owners:'..ch)
  redis:set('owners:'..ch,user)
  tdcli.sendText(result.chat_id_, 0, 0, 1, nil, 'User '..user..' *ownered*', 1, 'md')
  print(user)
end

local function deowner_reply(extra, result, success)
  t = vardump(result)
  local msg_id = result.id_
  local user = result.sender_user_id_
  local ch = result.chat_id_
  redis:del('owners:'..ch)
  tdcli.sendText(result.chat_id_, 0, 0, 1, nil, 'User '..user..' *demoted Owner*', 1, 'md')
  print(user)
end


local function setmod_reply(extra, result, success)
vardump(result)
local msg = result.id_
local user = result.sender_user_id_
local chat = result.chat_id_
redis:sadd('mods:'..chat,user)
tdcli.sendText(result.chat_id_, 0, 0, 1, nil, 'user '..user..' *Promoted*', 1, 'md')
end

local function remmod_reply(extra, result, success)
vardump(result)
local msg = result.id_
local user = result.sender_user_id_
local chat = result.chat_id_
redis:srem('mods:'..chat,user)
tdcli.sendText(result.chat_id_, 0, 0, 1, nil, 'User '..user..' *Rem Promoted*', 1, 'md')
end

function kick_reply(extra, result, success)
  b = vardump(result)
  tdcli.changeChatMemberStatus(result.chat_id_, result.sender_user_id_, 'Kicked')
  tdcli.sendText(result.chat_id_, 0, 0, 1, nil, 'user '..result.sender_user_id_..' *kicked*', 1, 'md')
end

function ban_reply(extra, result, success)
  b = vardump(result)
  tdcli.changeChatMemberStatus(result.chat_id_, result.sender_user_id_, 'Banned')
  tdcli.sendText(result.chat_id_, 0, 0, 1, nil, 'user '..result.sender_user_id_..' *banned*', 1, 'md')
end


local function setmute_reply(extra, result, success)
  vardump(result)
  redis:sadd('muteusers:'..result.chat_id_,result.sender_user_id_)
  tdcli.sendText(result.chat_id_, 0, 0, 1, nil, 'user '..result.sender_user_id_..' added to mutelist', 1, 'md')
end

local function demute_reply(extra, result, success)
  vardump(result)
  redis:srem('muteusers:'..result.chat_id_,result.sender_user_id_)
  tdcli.sendText(result.chat_id_, 0, 0, 1, nil, 'user '..result.sender_user_id_..' removed to mutelist', 1, 'md')
end



function tdcli_update_callback(data)
  vardump(data)

  if (data.ID == "UpdateNewMessage") then
    local msg = data.message_
    local input = msg.content_.text_
    local chat_id = msg.chat_id_
    local user_id = msg.sender_user_id_
    local reply_id = msg.reply_to_message_id_
    vardump(msg)
    if msg.content_.ID == "MessageText" then
      if input == "ping" then
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '`pong`', 1, 'md')

      end
      if input == "PING" then
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '<b>PONG</b>', 1, 'html')
      end
      if input:match("^[Ii][Dd]$") then
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '<b>SuperGroup ID : </b><code>'..string.sub(chat_id, 5,14)..'</code>\n<b>User ID : </b><code>'..user_id..'</code>\n<b>Channel : </b>@MuteTeam', 1, 'html')
      end

      if input:match("^[Pp][Ii][Nn]$") and reply_id and is_owner(msg) then
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '<b>Message Pinned</b>', 1, 'html')
        tdcli.pinChannelMessage(chat_id, reply_id, 1)
      end

      if input:match("^[Uu][Nn][Pp][Ii][Nn]$") and reply_id and is_owner(msg) then
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '<b>Message UnPinned</b>', 1, 'html')
        tdcli.unpinChannelMessage(chat_id, reply_id, 1)
      end


      -----------------------------------------------------------------------------------------------------------------------------
      if input:match('^([Ss]etowner)$') and is_owner(msg) and msg.reply_to_message_id_ then
        tdcli.getMessage(chat_id,msg.reply_to_message_id_,setowner_reply,nil)
      end
      if input == "delowner" and is_sudo(msg) and msg.reply_to_message_id_ then
        tdcli.getMessage(chat_id,msg.reply_to_message_id_,deowner_reply,nil)
      end

      if input:match('^([Oo]wner)$') then
        local hash = 'owners:'..chat_id
        local owner = redis:get(hash)
        if owner == nil then
          tdcli.sendText(chat_id, 0, 0, 1, nil, 'Group *Not* Owner ', 1, 'md')
        end
        local owner_list = redis:get('owners:'..chat_id)
        text85 = '*Group Owner :*\n\n '..owner_list
        tdcli.sendText(chat_id, 0, 0, 1, nil, text85, 1, 'md')
      end
      if input:match('^setowner (.*)') and not input:find('@') and is_sudo(msg) then
        redis:del('owners:'..chat_id)
        redis:set('owners:'..chat_id,input:match('^[/!#]setowner (.*)'))
        tdcli.sendText(chat_id, 0, 0, 1, nil, 'user '..input:match('^[/!#]setowner (.*)')..' ownered', 1, 'md')
      end

      if input:match('^setowner (.*)') and input:find('@') and is_owner(msg) then
        function Inline_Callback_(arg, data)
          redis:del('owners:'..chat_id)
          redis:set('owners:'..chat_id,input:match('^setowner (.*)'))
          tdcli.sendText(chat_id, 0, 0, 1, nil, 'user '..input:match('^setowner (.*)')..' ownered', 1, 'md')
        end
        tdcli_function ({ID = "SearchPublicChat",username_ =input:match('^setowner (.*)')}, Inline_Callback_, nil)
      end


      if input:match('^delowner (.*)') and is_sudo(msg) then
        redis:del('owners:'..chat_id)
        tdcli.sendText(chat_id, 0, 0, 1, nil, 'user '..input:match('^[/!#]delowner (.*)')..' rem ownered', 1, 'md')
      end
      -----------------------------------------------------------------------------------------------------------------------
      if input:match('^promote') and is_sudo(msg) and msg.reply_to_message_id_ then
tdcli.getMessage(chat_id,msg.reply_to_message_id_,setmod_reply,nil)
end
if input:match('^demote') and is_sudo(msg) and msg.reply_to_message_id_ then
tdcli.getMessage(chat_id,msg.reply_to_message_id_,remmod_reply,nil)
end
			
			sm = input:match('^promote (.*)')
if sm and is_sudo(msg) then
  redis:sadd('mods:'..chat_id,sm)
  tdcli.sendText(chat_id, 0, 0, 1, nil, 'user '..sm..'*Promoted*', 1, 'md')
end

dm = input:match('^demote (.*)')
if dm and is_sudo(msg) then
  redis:srem('mods:'..chat_id,dm)
  tdcli.sendText(chat_id, 0, 0, 1, nil, 'user '..dm..'*demoted*', 1, 'md')
end

if input:match('^modlist') then
if redis:scard('mods:'..chat_id) == 0 then
tdcli.sendText(chat_id, 0, 0, 1, nil, 'Group Not Mod', 1, 'md')
end
local text = "Group Mod List : \n"
for k,v in pairs(redis:smembers('mods:'..chat_id)) do
text = text.."_"..k.."_ - *"..v.."*\n"
end
tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
end
      ---------------------------------------------------------------------------------------------------------------------------------
      if input:match("^[Aa]dd$") and is_sudo(msg) then
        redis:sadd('groups',chat_id)
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Group Has Been Added By* `'..msg.sender_user_id_..'`', 1, 'md')
      end
      -------------------------------------------------------------------------------------------------------------------------------------------
      if input:match("^[Rr]em$") and is_sudo(msg) then
        redis:srem('groups',chat_id)
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Group Has Been Removed By* `'..msg.sender_user_id_..'`', 1, 'md')
      end
      -----------------------------------------------------------------------------------------------------------------------------------------------
      -----------------------------------------------------------------------
      if input:match('^(kick)$') and is_mod(msg) then
        tdcli.getMessage(chat_id,reply,kick_reply,nil)
      end

      if input:match('^kick (.*)') and not input:find('@') and is_mod(msg) then
        tdcli.sendText(chat_id, 0, 0, 1, nil, 'user '..input:match('^[!#/]kick (.*)')..' kicked', 1, 'md')
        tdcli.changeChatMemberStatus(chat_id, input:match('^[!#/]kick (.*)'), 'Kicked')
      end

      if input:match('^kick (.*)') and input:find('@') and is_mod(msg) then
        function Inline_Callback_(arg, data)
          tdcli.sendText(chat_id, 0, 0, 1, nil, 'user '..input:match('^[!#/]kick (.*)')..' kicked', 1, 'md')
          tdcli.changeChatMemberStatus(chat_id, data.id_, 'Kicked')
        end
        tdcli_function ({ID = "SearchPublicChat",username_ =input:match('^[!#/]kick (.*)')}, Inline_Callback_, nil)
      end
      --------------------------------------------------------
      ----------------------------------------------------------
      if input:match('^muteuser') and is_mod(msg) and msg.reply_to_message_id_ then
        redis:set('tbt:'..chat_id,'yes')
        tdcli.getMessage(chat_id,msg.reply_to_message_id_,setmute_reply,nil)
      end
      if input:match('^unmuteuser') and is_mod(msg) and msg.reply_to_message_id_ then
        tdcli.getMessage(chat_id,msg.reply_to_message_id_,demute_reply,nil)
      end
      mu = input:match('^muteuser (.*)')
      if mu and is_mod(msg) then
        redis:sadd('muteusers:'..chat_id,mu)
        redis:set('tbt:'..chat_id,'yes')
        tdcli.sendText(chat_id, 0, 0, 1, nil, 'user '..mu..' added to mutelist', 1, 'md')
      end
      umu = input:match('^unmuteuser (.*)')
      if umu and is_mod(msg) then
        redis:srem('muteusers:'..chat_id,umu)
        tdcli.sendText(chat_id, 0, 0, 1, nil, 'user '..umu..' removed to mutelist', 1, 'md')
      end

      if input:match('^muteusers') then
        if redis:scard('muteusers:'..chat_id) == 0 then
          tdcli.sendText(chat_id, 0, 0, 1, nil, 'Group Not MuteUser', 1, 'md')
        end
        local text = "MuteUser List:\n"
        for k,v in pairs(redis:smembers('muteusers:'..chat_id)) do
          text = text.."<b>"..k.."</b> - <b>"..v.."</b>\n"
        end
        tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
      end
