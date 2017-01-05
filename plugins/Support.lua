--[[

     CerNer Team
	 
]]
do
    local function run(msg, matches)
    local support = '1050575893'
    local data = load_data(_config.moderation.data)
    local name_log = user_print_name(msg.from)
        if matches[1] == 'support' or 'tosupport' then
        local group_link = data[tostring(support)]['settings']['set_link']
    return " <i>Link</i> : \n"..group_link.."\n\n<code>Channel</code>\n<i>By CerNer Team</i>"
    end
end
return {
    patterns = {
    "^(support)$",
    "^(tosupport)$",
    "^([Ss]upport)$",
    "^([Tt]osupport)$",
     },
    run = run
}
end
--[[

     CerNer Team
	 
]]