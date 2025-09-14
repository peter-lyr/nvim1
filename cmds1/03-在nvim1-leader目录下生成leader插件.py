import os
cur_dir = os.path.dirname(__file__) # 当前文件所在目录
up_dir = os.path.split(cur_dir)[0] # 上级目录
leader_dir = os.path.join(up_dir, 'leader')
# print(leader_dir) # C:\Users\depei_liu\Dp1\lazy\nvim1\leader
# leaderx_plugin_dir = os.path.join(leader_dir, 'leader_x', 'plugin')
# leaderx_plugin_leaderxlua = os.path.join(leaderx_plugin_dir, 'leader_x.lua')
# leader_x\plugin\leader_x.lua
for i in range(97, 97+26):
    i = chr(i)
    if i != 's':
        continue
    leaderx_plugin_dir = os.path.join(leader_dir, f'leader_{i}', 'plugin')
    os.makedirs(leaderx_plugin_dir, exist_ok=True)
    # print(leaderx_plugin_dir)
    leaderx_plugin_leaderxlua = os.path.join(leaderx_plugin_dir, f'leader_{i}.lua')
    with open(leaderx_plugin_leaderxlua, 'wb') as f:
        f.write(f'''
local {i.upper()} = require 'leader_{i}'

require 'which-key'.register {{
  ['<leader>{i}'] = {{ name = 'leader_{i}', }},
}}
        '''.encode('utf-8').strip())
    # print(leaderx_plugin_leaderxlua)
    leaderx_lua_dir = os.path.join(leader_dir, f'leader_{i}', 'lua')
    os.makedirs(leaderx_lua_dir, exist_ok=True)
    # print(leaderx_lua_dir)
    leaderx_lua_leaderxlua = os.path.join(leaderx_lua_dir, f'leader_{i}.lua')
    with open(leaderx_lua_leaderxlua, 'wb') as f:
        f.write(f'''
local {i.upper()} = {{}}

return {i.upper()}
        '''.encode('utf-8').strip())
    # print(leaderx_lua_leaderxlua)
    # print()
