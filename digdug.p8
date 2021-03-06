pico-8 cartridge // http://www.pico-8.com
version 11
__lua__
mode = 0
player = {}
player.x=128/8
player.y=128/8
player.w=1
player.h=1
player.sprite = 1
player.sprites = {2, 3, 4, 5}
player.flipsprites = {18, 19, 20, 21}
player.flipsprite=false
player.step=4
player.frame=1
player.flipx=false
player.flipy=false
player.speed=1
player.t=0
player.digx=player.x
player.digy=player.y
player.rope={} -- series of pxls to hold the rope sinwav?
player.rope_speed=3
player.firing=false
player.firing_t=0
player.lives = 3
player.ttl=30
player.fx={}
enemies = {}
rocks = {}
allfx = {}
t=0
score = 0
level = 0
cam = {x=0, y=0, dx=0, dy=0}

music(0)

function reset_game()
  _init()
  score=0
  t=0
  level=0
  mode = 0
  player.lives=3
  player.dying=false
end

function advance_obj_frame(obj)
  -- obj must have 
  -- step, t, sprites, frame
  obj.t=(obj.t+1)%obj.step
  if (obj.t==0) then
    obj.frame=(obj.frame+1)%#obj.sprites
  end
end

function reset_map()
  for x=0,15 do
    for y=0,15 do
      mset(x,y,mget(16+x,y))
    end
  end
end

function _init()
  reset_map()
  player.x=128/8
  player.y=128/8
  player.dx = 0
  player.dy = 0
  player.w=1
  player.h=1
  player.sprite = 1
  player.sprites = {2, 3, 4, 5}
  player.flipsprites = {18, 19, 20, 21}
  player.flipsprite=false
  player.step=4
  player.frame=1
  player.flipx=false
  player.flipy=false
  player.speed=1
  player.t=0
  player.digx=player.x
  player.digy=player.y
  player.rope={} -- series of pxls to hold the rope sinwav?
  player.rope_speed=3
  player.firing=false
  player.dying=false
  player.firing_t=0
  player.ttl=30
  player.fx={}
  allfx = {}
  enemies = {}
  rocks = {}
  create_enemies()
  create_rocks()
end

function _update()
  if cam.dx > 0 then
    cam.dx-=1
  end
  if cam.dy > 0 then
    cam.dy-=1
  end
  camera(cam.x+cam.dx, cam.y+cam.dy)
  t+=1
  if mode == 0 then
    -- title screen
    if btnp(4) then
      mode=1
    end
    for enemy in all(enemies) do
      update_enemy(enemy)
    end

    for rock in all(rocks) do
      update_rock(rock)
    end
  elseif mode == 2 then
    -- endgame screen
    if btnp(4) then
      reset_game()
    end
  elseif mode == 1 then
    -- main game
    if player.lives <= 0 then
      mode += 1
    end
    if btn(0) or btn(1) or
      btn(2) or btn(3) then
      advance_obj_frame(player)
    else
      --player.moving=false
    end
    if not player.firing and not player.dying then
      if btn(0) then
        -- use regular sprite set
        player.dx=-player.speed
        player.flipy=false
        player.flipx=false
        player.flipsprite=false
        find_new_player_y()
        player.digx=(player.x+2)/8
        player.digy=(player.y)/8
      elseif btn(1) then
        player.dx=player.speed
        player.flipx=true
        player.flipy=false
        player.flipsprite=false
        find_new_player_y()
        player.digx=(player.x+6)/8
        player.digy=(player.y)/8
      elseif btn(2) then
        -- use different sprite set
        player.dy=-player.speed
        player.flipx=false
        player.flipy=true
        player.flipsprite=true
        find_new_player_x()
        player.digx=(player.x)/8
        player.digy=(player.y+2)/8
      elseif btn(3) then
        player.dy=player.speed
        player.flipx=false
        player.flipy=false
        player.flipsprite=true
        find_new_player_x()
        player.digx=(player.x)/8
        player.digy=(player.y+6)/8
      else
        player.dy=0
        player.dx=0
      end
    end

    local canmove = true
    for rock in all(rocks) do
      if check_collision({w=(player.w*8)-3,h=(player.h*8)-3,
                          x=player.x+player.dx,
                          y=player.y+player.dy},
                          {w=(rock.w*8)-2,h=(rock.h*8)-2,
                          x=rock.x,y=rock.y}) then
        canmove = false
      end
    end
    if canmove then
      player.x+=player.dx
      player.y+=player.dy
    end
    if player.x<0 then player.x=0 player.dx=0 end
    if player.x>120 then player.x=120 player.dx=0 end
    if player.y<0 then player.y=0 player.dy=0 end
    if player.y>120 then player.y=120 player.dy=0 end

    if btnp(5) then
      stop_firing()
      detach_all_enemies()
      player.dx=0
      player.dy=0
    end
    if player.flipsprite then
      player.sprite=player.flipsprites[player.frame+1]
      if player.firing then player.sprite=17 end
    else
      player.sprite=player.sprites[player.frame+1]
      if player.firing then player.sprite=1 end
    end
    mset(player.digx, player.digy, 0)

    if player.firing then
      player.dx=0
      player.dy=0
      firing_step()
      if check_hook_collision_wall() then
        stop_firing()
      elseif check_hook_collision_enemy() then
        player.rope_speed=0
      else
        sfx(30)                
      end
      enemy_idx = find_attached_enemy()
      if btnp(4) and enemy_idx then
        sfx(31)
        enemies[enemy_idx].pumps+=1
      end
    else
      if btnp(4) then
        fire()
      end
    end
    if player.dying then
      player.ttl-=1
      player.sprite=37
      if player.ttl<=0 then
        player.ttl=30
        player.lives-=1
        player.dying=false
        _init()
      end
    end

    if #enemies==0 and not player.dying then
      level+=1
      _init()
    end

    for enemy in all(enemies) do
      if (enemy.pumps==0 and not enemy.dying) and
         check_collision({w=player.w*8,h=player.h*8,x=player.x,y=player.y}, 
                         {w=enemy.w*8,h=enemy.h*8,x=enemy.x,y=enemy.y}) then
        player.dying=true
        player.dx=0 player.dy=0
        create_fx(player.x, player.y)
        sfx(32)
        del(enemies, enemy)

      end
      update_enemy(enemy)
    end

    for rock in all(rocks) do
      update_rock(rock)
    end

    update_fx()

  end -- end mode 1 playmode
end

function _draw()
  cls()
  map(0,0,0,0,16,16)

  if mode == 0 then
    -- title screen
    for enemy in all(enemies) do
      pretty_draw_sprite(enemy)
      --rect(enemy.goal.x*8, enemy.goal.y*8, enemy.goal.x*8+8, enemy.goal.y*8+8, 7)
      --for sp in all(enemy.movement_queue) do
      --  rect(sp.x*8, sp.y*8, sp.x*8+8, sp.y*8+8,7)
      --end
    end

    for rock in all(rocks) do
      local prevx=rock.x
      local prevy=rock.y
      if rock.ttf < 30 and rock.ttf != 0 and rock.dy==0 then
        rock.x+=rnd(2)
        rock.y+=rnd(2)
      end
      pretty_draw_sprite(rock)
      rock.x=prevx
      rock.y=prevy
    end

    pretty_print("dig dork", 46, 128/2)
    pretty_print("press z", 47, 168/2)
    pretty_print("by @mccolgst", 40, 104)
  elseif mode == 2 then
    -- endgame screen
    pretty_print("game over", 46, 128/2)
    pretty_print("press z", 47, 168/2)
    draw_hud()
  elseif mode == 1 then
    draw_hud()
    
    -- main game
    if player.firing then
      for rope_piece in all(player.rope) do
        pset(rope_piece.x, rope_piece.y, 7)
      end
    end
    pretty_draw_sprite(player)
    for enemy in all(enemies) do
      pretty_draw_sprite(enemy)
      --rect(enemy.goal.x*8, enemy.goal.y*8, enemy.goal.x*8+8, enemy.goal.y*8+8, 7)
      --for sp in all(enemy.movement_queue) do
      --  rect(sp.x*8, sp.y*8, sp.x*8+8, sp.y*8+8,7)
      --end
    end

    for rock in all(rocks) do
      local prevx=rock.x
      local prevy=rock.y
      if rock.ttf < 30 and rock.ttf != 0 and rock.dy==0 then
        rock.x+=rnd(2)
        rock.y+=rnd(2)
      end
      pretty_draw_sprite(rock)
      rock.x=prevx
      rock.y=prevy
    end
    draw_fx()

    --rect(player.x, player.y, player.x+player.w*8, player.y+player.h*8, 7)
  end
end

function draw_hud()
  -- draw lives
  for i=1,player.lives do
    for p=1,15 do pal(p,0) end
    for j=-1,1 do
      for k=-1,1 do
        spr(1,93+(i*8)+j, 3+k)
      end
    end
    pal()
    spr(1,93+(i*8), 3)
  end
  -- draw score
  local digits=score
  local modx=0
  while flr(digits/10) > 0 do
    modx+=4
    digits=flr(digits/10)
  end
  for i=-1,1 do
    for k=-1,1 do
      print("score:"..score,98+i-modx,13+k,0)
    end
  end
  print("score:"..score,98-modx,13,7)
end

function pretty_draw_sprite(obj)
  for c=1,15 do
    pal(c,0)
  end

  local drawx=obj.x-(4*(obj.w-1))
  local drawy=obj.y-(4*(obj.h-1))

  for i=-1,1 do
    for j=-1,1 do
      spr(obj.sprite, drawx+i, drawy+j, 
          obj.w, obj.h, obj.flipx, obj.flipy)
    end
  end

  pal()
  spr(obj.sprite, drawx, drawy,
      obj.w, obj.h, obj.flipx,
      obj.flipy)
end

print_time=0
function pretty_print(str, x, y)
  print_time+=0.1
  if print_time==60 then print_time=0 end
  local ymod = (print_time%60)/10
  printh(sin(ymod))
  for i=-1,1 do
    for j=-1,1 do
      print(str, x+i, y+j+sin(ymod)*4, 1)
    end
  end
  print(str, x, y+sin(ymod)*4, 7)
end

function find_new_player_x()
    -- going up, find the closest x which is divible by 8 and snap to that
    x1 = (flr(player.x/8))*8
    x2 = (flr(player.x/8)+1)*8
    if player.x !=x1 then
      if abs(player.x-x1) < abs(x2-player.x) then
        player.x=x1
      else
        player.x=x2
      end
      --player.x=x1
    end
end

function find_new_player_y()
    y1 = (flr(player.y/8))*8
    y2 = (flr(player.y/8)+1)*8
    if player.y != y1 then
      if abs(player.y-y1) < abs(y2-player.y) then
        player.y=y1
      else
        player.y=y2
      end
    end
end

function firing_step()
  player.firing_t+=1
  if player.firing_t%5==0 then
    player.firing_t=0
  end
  
  if not player.flipsprite then
    local y = cos(player.firing_t/5)*1.7
    for rope_piece in all(player.rope) do
      if player.flipx then
        rope_piece.x+=player.rope_speed
      else
        rope_piece.x-=player.rope_speed
      end
    end
    add(player.rope,{x=player.x+4, y=player.y+y+4})
    add(player.rope,{x=player.x+4-1, y=player.y+y+4})
    add(player.rope,{x=player.x+4+1, y=player.y+y+4})
  else
    --we're shooting up or down
    local x = cos(player.firing_t/5)*1.7
    for rope_piece in all(player.rope) do
      if player.flipy then
        rope_piece.y-=player.rope_speed
      else
        rope_piece.y+=player.rope_speed
      end
    end
    add(player.rope,{x=player.x+x+4, y=player.y+4})
    add(player.rope,{x=player.x+x+4, y=player.y+4-1})
    add(player.rope,{x=player.x+x+4, y=player.y+4+1})
  end
end

function check_hook_collision_wall()
  if fget(mget(player.rope[1].x/8, player.rope[1].y/8),0) then
    return true
  end
  return false
end

function check_enemy_collision_wall(enemy)

  local enemycheckx = enemy.x+(sgn(enemy.speed.x)*8)
  if enemy.speed.x < 0 then
    enemycheckx+=8
  end
  if fget(mget(enemycheckx/8, enemy.y/8),0) then
    return true
  end
  return false
end

function check_hook_collision_enemy()
  for enemy in all(enemies) do
    if not enemy.dying and 
       player.rope[1].x > enemy.x and
       player.rope[1].x < enemy.x+8 and
       player.rope[1].y > enemy.y and
       player.rope[1].y < enemy.y+8 then
      enemy.attached=true
      player.attached_to_enemy=true
      return true
    end
  end
  return false
end

function create_rocks()
  for i=1,3 do
    rock = {}
    rock.x = flr(rnd(128)/8)*8
    rock.y = 24+flr(rnd(104)/8)*8
    rock.dy = 0
    while not fget(mget(flr((rock.x/8)), flr((rock.y+8)/8)), 0) do
      rock.x = flr(rnd(128)/8)*8
      rock.y = 24+flr(rnd(104)/8)*8
    end
    rock.w=1
    rock.h=1
    rock.sprite=50
    rock.sprites={50}
    rock.frame=1
    rock.t=0
    rock.ttf=30 -- frames it takes until rock starts falling
    rock.default_speed=2
    add(rocks, rock)
  end
end

function create_enemies()
  --create enemy
  for i=1,2+(flr(level/2)) do
    enemy = {}
    enemy.step=10
    enemy.t=0
    enemy.tt=flr(rnd(30))
    enemy.sprites={8, 9, 10, 11}
    enemy.frame=1
    enemy.flipx=false
    enemy.flipy=false
    enemy.x=16+flr(rnd(100)/8)*8
    enemy.y=16+flr(rnd(100)/8)*8
    enemy.w=1
    enemy.h=1
    enemy.sprite=1
    enemy.attached=false
    enemy.pumps=0
    enemy.speed={x=0.5,y=0}
    enemy.default_speed=0.5
    enemy.pump_timer=30*1 -- minus 1 every frame = 1 sec
    enemy.ttl=45 -- 1.5sec to live after killed
    enemy.dying=false

    -- pathfinding stuff
    enemy.closed_nodes = {}
    enemy.start_node = {x=enemy.x, y=enemy.y}
    enemy.openset = {enemy.start_node}
    enemy.goal = {x=player.x, y=player.y}
    enemy.current_node = {x=enemy.x, y=enemy.y}
    enemy.g_score, enemy.f_score = {}, {}
    enemy.came_from = {}
    enemy.winning_path = {}
    enemy.g_score[enemy.start_node] = find_distance(enemy.start_node, enemy.goal)
    enemy.f_score[enemy.start_node] = enemy.g_score[enemy.start_node]
    enemy.movement_queue = {}
    add(enemies, enemy)
    --create terrain gaps
    mset(enemy.x/8, enemy.y/8, 0)
    mset((enemy.x-8)/8, enemy.y/8, 0)
    mset((enemy.x+8)/8, enemy.y/8, 0)
  end
end

function update_rock(rock)
  rock.dy=0
  if rock.ttf > 0 and not fget(mget(flr((rock.x/8)), flr((rock.y+8)/8)), 0) then
    rock.ttf-=1
    sfx(33)
  end
  if rock.ttf==0 then
    if not fget(mget(flr((rock.x/8)), flr((rock.y+8)/8)), 0) then
      rock.dy=rock.default_speed
      for enemy in all(enemies) do
        if not enemy.dying and
         check_collision({w=rock.w*8,h=rock.h*8,x=rock.x,y=rock.y},
                         {w=enemy.w*8,h=enemy.h*8,x=enemy.x,y=enemy.y}) then
          enemy.pumps=3
          enemy.sprite = 40+(enemy.pumps*2) - 2
          enemy.dying=true
          create_fx(enemy.x, enemy.y)
          sfx(32)
          score+=1000
        end
      end
    else
      rock.ttf=30
      sfx(32)
    end
  end
  rock.y+=rock.dy
  if rock.y>120 then rock.y=120 end
end

function update_enemy(enemy)
  if enemy.dying then
    enemy.ttl-=1
    if enemy.ttl<=0 then
      del(enemies, enemy)
    end
  else
    enemy.tt+=1
    advance_obj_frame(enemy)
    enemy.sprite=enemy.sprites[enemy.frame+1]
    if enemy.attached then
      enemy.sprite=7
    end
    if enemy.pumps>0 then
      enemy.sprite = 40+(enemy.pumps*2) - 2
      enemy.w=2
      enemy.h=2
      if enemy.pumps==3 then
        --del(enemies, enemy)
        enemy.dying=true
        create_fx(enemy.x, enemy.y)
        sfx(32)
        score+=200
        stop_firing()
      end
      if enemy.pump_timer > 0 then
        enemy.pump_timer-=1
      else
        enemy.pumps-=1
        enemy.pump_timer=30*1
      end
    else
      enemy.w=1
      enemy.h=1
    end

    --enemy movement code
    if (not enemy.attached and enemy.pumps==0) then
      if enemy.x<0 then enemy.x=0 end
      if enemy.x>120 then enemy.x=120 end
      if enemy.y<0 then enemy.y=0 end
      if enemy.y>120 then enemy.y=120 end
      if check_enemy_collision_wall(enemy) or
        enemy.x > 120 or enemy.x < 0 then
        enemy.speed.x = -enemy.speed.x
      end
      if enemy.speed.x > 0 then enemy.flipx=true else enemy.flipx=false end

      -- follow path
      if #enemy.movement_queue>0 then
        if enemy.movement_queue[1].x > (enemy.x/8) then
          enemy.speed.x = enemy.default_speed
        elseif enemy.movement_queue[1].x < (enemy.x/8) then
          enemy.speed.x = -enemy.default_speed
        else
          enemy.speed.x=0
        end

        if enemy.movement_queue[1].y > (enemy.y/8) then
          enemy.speed.y = enemy.default_speed
        elseif enemy.movement_queue[1].y < (enemy.y/8) then
          enemy.speed.y = -enemy.default_speed
        else
          enemy.speed.y=0
        end
        --if enemy.speed.y != 0 and enemy.speed.x != 0 then enemy.speed.y=0 end
        if enemy.speed.x == 0 and enemy.speed.y == 0  or 
           (enemy.x/8 ==0 and enemy.y/8 == 0) then
          del(enemy.movement_queue, enemy.movement_queue[1])
          --del(enemy.movement_queue, enemy.movement_queue[1])
          --add(enemy.movement_queue, {x=flr((player.x/8)),y=flr((player.y/8))})
        end
      end
      enemy.x+=enemy.speed.x
      enemy.y+=enemy.speed.y
    end
  end

  if enemy.tt%15==0 then
    local newpath = astar(enemy)
    if newpath != nil then
      enemy.movement_queue = {}
      enemy.winning_path=newpath
      --enemy.winning_path=astar(enemy)
      if enemy.winning_path != nil then
        for i=#enemy.winning_path,1,-1 do
          add(enemy.movement_queue, enemy.winning_path[i])
        end
        del(enemy.movement_queue, enemy.movement_queue[1])
        del(enemy.movement_queue, enemy.movement_queue[1])
        --add(enemy.movement_queue, {x=flr((player.x/8)),y=flr((player.y/8))})

      end
    end

  end
end

function find_distance(pointa, pointb)
  local horz = pointb.x - pointa.x
  local vert = pointb.y - pointa.y
  return sqrt((horz*horz) + (vert*vert))
end

function find_attached_enemy()
  for i=1,#enemies do
    if enemies[i].attached then
      return i
    else
    end
  end
  return false
end

function detach_all_enemies()
  for enemy in all(enemies) do
    enemy.attached=false
  end
end

function fire()
  player.rope={}
  player.firing=true
  player.firing_t=0
  player.rope_speed=3
end

function stop_firing()
  player.rope={}
  player.firing=false
  player.firing_t=0
  player.rope_speed=0
end

function check_collision(thing1, thing2)
  if thing1.x < thing2.x+thing2.w and
     thing1.x+thing1.w > thing2.x and
     thing1.y+thing1.h > thing2.y and
     thing1.y < thing2.y+thing2.h and
     thing1.y+thing1.h > thing2.y then
    return true
  end
  return false
end

function draw_fx()
  for fx in all(allfx) do
    for cir in all(fx.circs) do
      circfill(cir.x, cir.y, cir.r+1, 0)
      circfill(cir.x, cir.y, cir.r, 7)
    end
  end
end

function create_fx(x, y)
  cam.dx+=rnd(3)
  cam.dy+=rnd(3)
  local fx = {}
  fx.x = x
  fx.y = y
  fx.dx=0
  fx.dy=0
  fx.circs = {}
  fx.ttl = 15
  for i=1,10 do
    local newcirc = {}
    newcirc.r=3
    newcirc.x=fx.x
    newcirc.dx=rnd(4)
    newcirc.dy=rnd(4)
    if flr(rnd(2)) == 0 then
      newcirc.dx*=-1
    end
    newcirc.y=fx.y
    if flr(rnd(2)) == 0 then
      newcirc.dy*=-1
    end
    newcirc.c = flr(rnd(5))+1
    add(fx.circs, newcirc)
  end
  add(allfx, fx)
end

function update_fx()
  for fx in all(allfx) do
    printh('found fx! '..t)
    fx.x+=fx.dx
    fx.y+=fx.dy
    for cir in all(fx.circs) do
      cir.x+=cir.dx
      cir.y+=cir.dy
      if fx.ttl%2==0 then
        cir.r-=(rnd(2))
      end
      if cir.r<=0 then
        del(fx.circs, cir)
      end
    end
    fx.ttl-=1
    if fx.ttl<=0 then
      del(allfx, fx)
    end
  end
end

------------pathfindingcode---------
function astar(obj)
    obj.closed_nodes = {}
    obj.came_from = {}
    obj.start_node = {x=flr(obj.x/8), y=flr(obj.y/8)}
    obj.openset = {obj.start_node}
    obj.goal = {x=flr((player.x+4)/8), y=flr((player.y+4)/8)}
    obj.current_node = obj.start_node
    obj.g_score, obj.f_score = {}, {}
    obj.winning_path = {}
    obj.g_score[obj.start_node] = find_distance(obj.start_node, obj.goal)
    obj.f_score[obj.start_node] = obj.g_score[obj.start_node]
    while #obj.openset > 0 do
      local current_node = lowest_f_score(obj.openset, obj.f_score)

      current_node = lowest_f_score(obj.openset, obj.f_score)
      if current_node.x == obj.goal.x and current_node.y == obj.goal.y then
        obj.winning_path = unwind_path(obj.winning_path, obj.came_from, current_node)
        add(obj.winning_path, current_node)
        return obj.winning_path
      end

      --del(openset, current_node)
      remove_node(obj.openset, current_node)
      add(obj.closed_nodes, current_node)

      local neighbors = get_valid_neighbors(current_node)
      for neighbor in all(neighbors) do
        if not_in(obj.closed_nodes, neighbor) then
          local tentative_g_score = obj.g_score[current_node] + find_distance(current_node, neighbor)
          if not_in(obj.openset, neighbor) then
            -- found a good node?
            obj.came_from[neighbor] = current_node
            obj.g_score[neighbor] = tentative_g_score
            obj.f_score[neighbor] = obj.g_score[neighbor] + find_distance(neighbor, obj.goal)

            if not_in(obj.openset, neighbor) then
              add(obj.openset, neighbor)
            end
          end
        end
      end

    end
end

function lowest_f_score(nodes, f_score)
  local lowest, best_node = 10000, 0
  for node in all(nodes) do
    local score = f_score[node]
    if score < lowest then
      lowest, best_node = score, node
    end
  end
  return best_node
end

function get_valid_neighbors(node)
  local nodes = {}
  local potential_nodes = {}
  --for x=-1,1 do
  --  for y=-1,1 do
  --    local new_node = {x=node.x+x, y=node.y+y}
  --    if not (x==0 and y==0) and not (y==-1 and x==-1) and not (x==1 and y==1) and not (x==-1 and y==1)
  --       and not_in(closed_nodes, new_node) and is_valid_node(new_node) and
  --       (new_node.x*8 > 0 and new_node.x*8 < 120 and 
  --        new_node.y*8 > 0 and new_node.y*8 < 120) then
  --      add(nodes, new_node)
  --    end
  --  end
  --end
  add(potential_nodes, {x=node.x-1, y=node.y})
  add(potential_nodes, {x=node.x+1, y=node.y})
  add(potential_nodes, {x=node.x, y=node.y-1})
  add(potential_nodes, {x=node.x, y=node.y+1})
  for n in all(potential_nodes) do
    if not_in(closed_nodes, n) and is_valid_node(n) and
       n.x*8>0 and n.x*8<128 and
       n.y*8>0 and n.y*8<128 then
       add(nodes, n)
    end
  end
  return nodes
end

function remove_node (nodes, node_to_find)
  for node in all(nodes) do
    if node == node_to_find then del(nodes, node_to_find) end
  end
end

function not_in(nodes, node_to_find)
  for node in all(nodes) do
    if node.x == node_to_find.x and node.y == node_to_find.y then return false end
    if node == node_to_find then return false end
  end
  return true
end

function is_valid_node(node)
  local is_valid = not fget(mget(flr(node.x), flr(node.y)), 0)
  for rock in all(rocks) do
    is_valid = is_valid and not (flr(node.x*8) == rock.x and flr(node.y*8) == rock.y)
  end
  return is_valid
end

function unwind_path ( flat_path, nodemap, current_node )
	if nodemap [ current_node ] then
		add ( flat_path, nodemap [ current_node ] ) 
		return unwind_path ( flat_path, nodemap, nodemap [ current_node ] )
	else
		return flat_path
	end
end

__gfx__
0000000000077700000000000007770000000000000777000000000000dddd000000000000dddd000000000000dddd0000000000000000000000000000000000
000000000077777000077700007777700007770000777770000000000dddddd000dddd000dddddd000dddd000dddddd000000000000000000000000000000000
00700700001c1c7000777770001c1c7000777770001c1c7000000000e66e66ed0dddddd0eeeeeeed0dddddd0eeeeeeed00000000000000000000000000000000
0007700000cccc70001c1c7000cccc70001c1c7000cccc7000000000e16e16eeeeeeeeede16e16eeeeeeeeede16e16ee00000000000000000000000000000000
00077000c00777c000cccc70080777c000cccc70080777c000000000eeeeeeede16e16eeeeeeeeede16e16eeeeeeeeed00000000000000000000000000000000
007007000cc7cc00080777c088888c80080777c088888c80000000000dddddd0eeeeeeed0dddddd0eeeeeeed0dddddd000000000000000000000000000000000
000000000007077088888c800877007088888c80080707700000000000dddd000dddddd000ddee000dddddd000eedd0000000000000000000000000000000000
000000000077007008070770000007700877007000770000000000000ee0ee0000ddee0000ee000000eedd000000ee0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000777c07700777c870777c87700777c870777c87000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000077cc7c70077cc7c777cc7c07077cc7c077cc7c7000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000771c7c000771c780771c78000771c780771c780000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000077cc7777077cc78777cc7870077cc78777cc787700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000071c0c070071c080071c08700071c087071c080700000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000c000000088800008880000008880000888000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000c0000000008000000800000000800000080000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000099999999444449442222222211111111008000000000000000dddd00000000000000000000000000000000000000d000000000000000000000000000
000000009a99999944444444222422241111111108880000000000000dddddd00000000000000000000000000000000000ddd00000dd00000000000000000000
0000000099999a994944449422222222111111117080cc7000000000e66e66ed0000000000000000000000dddd0000000dddd00000dddd000000000000000000
00000000999999994444444424222222111111117787cc7700000000e16e16ee000000dddd0000000000dddddddd000006666d0000ddddd00000000000000000
00000000999999994444444422222222111111110087cc7700000000eeeeeeed00000ddddddd0000000dddddddddd00006116d000d6666dd0000000000000000
000000009999999994444444222222221111111177c7cc77000000000dddddd00000ddddddddd0000006666d6666dd000000006d066116dd0000000000000000
0000000099a9999a444444442222242211111111708c77700000000000dddd00000d666e666dd0000006116e6116dd000000016e0000dd000000000000000000
000000009999999944494444242222221111111100800000000000000ee0ee00000e611e116ee0000006116e6116ee00000600000010ee000000000000000000
0000000000000000000090000000000000000000000000000000000000000000000e611e116ee0000006666e6661ed00000000006661ed000000000000000000
00000000000000000a09400000000000000000000000000000000000000000000000ddddddddd000000dddddddd1dd00006666e00dd00d000000000000000000
0000000000000000aa994400000000000000000000000000000000000000000000000ddddddd00000000ddddddddd00000d11dd000006ee00000000000000000
000000000800000094444a40000000000000000000000000000000000000000000000ee0eed0000000000ee0eedd0000066111e0e0661ed00000000000000000
00000000880000009444a4920000000000000000000000000000000000000000000000000000000000000000000000000dddddd00ddd1dd00000000000000000
00000000080000004444942200000000000000000000000000000000000000000000000000000000000000000000000000ddddd00ddddd000000000000000000
000000000000000044442220000000000000000000000000000000000000000000000000000000000000000000000000000ee0000eedd0000000000000000000
00000000000000000222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2424242424242424242424242424242424242424242424242424242424242424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2424242424242424242424242424242424242424242424242424242424242424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2424242424242424242424242424242424242424242424242424242424242424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121212121212121212121212121212121212121212121212121212121212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121212121212121212121212121212121212121212121212121212121212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121212121212121212121212121212121212121212121212121212121212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121212121212121212121212121212121212121212121212121212121212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232323232323232323232323232323232323000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232323232323232323232323232323232323000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232323232323232323232323232323232323000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232323232323232323232323232323232323000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2424242424242424242424242424242424242424242424242424242424242424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011c000002050040500505007050090500a0500c0500e050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000002140021200e11002140021250e11002140021200e11002140021200e110021400e110021400e11002140021200e11002140021250e11002140021200e11002140021200e110021400e110021400e110
011000000414004120101100414004125101100414004120101100414004120101100414010110041401011004140041201011004140041251011004140041201011004140041201011004140101100414010110
01100000051400512011110051400512511110051400512011110051400512011110051401111005140111100714007120131100714007125131100714007120151100914009120151100a140161100a14016110
0110000007000000000b0000c000100000c000130000c00007000000000b0000c000100000c000130000c00007000000000b0000c000100000c000130000c00007000000000b0000c000100000c000130000c000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000c053000000c053000000064000645000000c0530c05300000000000c0530064000645000000c0530c053000000c053000000064000645000000c0530c053000000c053006000064000645006000c000
011000000c053000000c053000000064000645000000c0530c05300000000000c0530064000645000000c0530c053000000c053000000064000645000000c0530c05300000006550060000655006550000000655
011000000c000000000c000000000060000600000000c0000c00000000000000c0000060000600000000c0000c000000000c000000000060000600000000c0000c00000000006550060000655006550000000655
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003705037032370223701035050350323502235010340503403234022340103205032032320223201030050300423003230022300103000034050340403403034020350503503032050320423203232020
011000002405024032240222401022050220322202222010210502103221022210101f0501f0321f0221f0101d0501d0421d0321d0221d0101d0001d0401d0301d0301d0201c0501c0301a0501a0421a0321a020
011000002b0502b0322b0222b01029050290322902229010280502803228022280102605026032260222601024050240422403224022240102400029040290302903029020280502803026050260422603226020
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102000030056300061a0561800634056300061d05618006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600000
010300000c0510e051100511105113051150511705100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001835318253187001864018640186301863018625006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600000000000000000
010200000c755187550c755187550c755187550c75518755007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 024a4344
00 034a4344
00 040c4344
01 020a5444
00 030a4344
00 040b4344
00 024a1544
00 034a1644
00 040c1444
00 020a5544
00 030a5644
00 040a5444
00 020a1544
00 030a1644
02 040a1444
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

