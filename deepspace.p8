pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
  posx=0
  posy=0
  state = 1
  start_seed = rnd(128)
  debug = true
  dirty = true
  init_player()
end

function _draw()
  cls()
  if state == 0 do
    draw_space()
  elif state == 1 do
    draw_local()
  end
  if debug do
    print("mem: "..stat(0),0,0, 8)
    print("cpu: "..stat(1),0,8, 8)
    print("fps: "..stat(7),0,16, 8)
  end
end

function _update()
  if state == 0 do
    update_space()
  elif state == 1 do
    update_player()
  end
end

function init_player()
  player = {}
  player.x = 0
  player.y = 0
  -- global position
  player.globalx = 0
  player.globaly = 0
  player.dir = 0
  player.vel = 0
end

function update_player()
  if btn(⬅️) do
    player.dir-=5
  end
  if btn(➡️) do
    player.dir+=5
  end
  if btn(⬆️) do
    player.vel-=3
  end
  if btn(⬇️) do
    player.vel+=1
  end
end

-- the all important seed function
-- sets the seed for the specified location in space
function star_seed(x, y)
  srand(flr(start_seed * ((start_seed + x)*y)))
end

-- Seeds a planet for the star at x, y
function planet_seed(x, y, planetnum)
  srand(flr(start_seed * ((planetnum + 1) * 2) * x * (start_seed * y)))
end

-- draw a ship in local space
function draw_ship(ship)
  spr(ship.sprite, ship.x, ship.y)
end

-- draw an astronomical object in the local view
function draw_astro(object)
  circfill(object.x, object.y, object.size, object.color)
end

function get_star_info(x, y)
  star_seed(x, y)
  local star = {}
  local exists = rnd(16) > 15
  star.exists = exists
  -- if the star does not exist there is no reason to probe the rng any further
  if exists do
    star.type = rnd(4)
    -- the star will not be drawn at the exact x,y position, because
    -- it would create an obvious grid. it will be placed at somewhat an offset
    star.xoffset = flr(rnd(128)-64)
    star.yoffset = flr(rnd(128)-64)
  end
  return star
end

function get_planet_info(x, y, planet_num)
  planet_seed(x, y, planet_num)
  local planet = {}
  planet.exists = rnd(8)>6
  if planet.exists do
    planet.type = flr(rnd(8))
    planet.radius = flr(rnd(10)+2)
    planet.mass = flr(rnd(10)+4)
  end
  return planet
end

-- draw the star map
function draw_space()
  for x=posx,posx+100 do
    for y=posy,posy+100 do
      local star = get_star_info(x, y)
      if star.exists do
        pset(x-posx,y-posy,star.type)
      end
    end
  end
end

function update_space()
  if btn(⬅️) do
    posx-=1
    dirty = true
  end
  if btn(➡️) do
    posx+=1
    dirty = true
  end
  if btn(⬆️) do
    posy-=1
    dirty = true
  end
  if btn(⬇️) do
    posy+=1
    dirty = true
  end
end

__gfx__
00000000000bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000bbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000b0000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000b0000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000b000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700b000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000b00b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
