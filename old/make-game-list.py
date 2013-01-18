import os
import re
game_list = []
game_re = re.compile(r'^(.+)\.coffee$')
for f in os.listdir('js/supersecret/games'):
  m = game_re.search(f)
  if m:
    game_list.append(m.groups()[0])
import json
f = open('js/supersecret/game-list.json', 'w')
f.write(json.dumps({'games': game_list}))