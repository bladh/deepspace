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
  MAX_PLANETS = 12

  SECTOR_DISTANCE = 25000 -- pixel difference between sector centers
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
  player.xspeed = 0
  player.yspeed = 0
  -- the radian value is only a helper for converting speed vector to absolute
  -- values.
  player.radian = 0
end

function update_player()
  local recalculate = false
  if btn(⬅️) do
    player.dir-=5
    recalculate = true
  end
  if btn(➡️) do
    player.dir+=5
    recalculate = true
  end
  if btn(⬆️) do
    player.vel-=3
  end
  if btn(⬇️) do
    player.vel+=1
  end
  if recalculate do
    player.radian = player.dir * (3.14159 / 180)
  end
  player.xspeed = player.speed * cos(player.radian)
  player.yspeed = player.speed * sin(player.radian)

  player.x += player.xspeed
  player.y += player.yspeed

  -- wrap player into neighbouring sector
  if player.x > SECTOR_DISTANCE do
    player.x -= SECTOR_DISTANCE
    player.globalx += 1
    sector_enter(player.globalx, player.globaly)
  end
  if player.x < 0 do
    player.x += SECTOR_DISTANCE
    player.globaly -= 1
    sector_enter(player.globalx, player.globaly)
  end
  if player.y > SECTOR_DISTANCE do
    player.y -= SECTOR_DISTANCE
    player.globaly -= 1
    sector_enter(player.globalx, player.globaly)
  end
  if player.y < 0 do
    player.y += SECTOR_DISTANCE
    player.globaly += 1
    sector_enter(player.globalx, player.globaly)
  end
end

-- Seed for the star at sector x,y
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

--
-- in the context of get_star_info and get_planet_info, x and y
-- refer to the x and y of the sector, not neccessarily an absolute
-- x,y position of the objects themselves.
-- stars will be positioned at an offset from the center of the sector
-- and planets will have their position dependent on their planet_num
-- so higher planet_num value translates to a bigger distance to the
-- star. Sometimes a planet_num will be missing a planet, which means
-- the star doesnt have a planet at that distance, same way some
-- stars don't exist as well.
-- Since stars are placed at an offset from the center of their
-- sector, and planets will be placed on an offset from the star
-- as (planetnum + small random offset) and also "rotated" around the
-- star by a random amount (with the star itself as a rotational pivot)
-- things should not end up looking very uniform. actual distance
-- between sectors would need to be tweaked so things are not too dense.
--

-- low over-head function to see if there is a star in the
-- specified sector. also sets the seed for the specified star.
function has_star(x, y)
  star_seed(x, y)
  return rnd(16) > 15
end

function get_star_info(x, y)
  local star = {}
  local exists = has_star(x, y)
  star.exists = exists
  -- if the star does not exist there is no reason to probe the rng any further
  if exists do
    star.type = rnd(4)
    -- the star will not be drawn at the exact x,y position, because
    -- it would create an obvious grid. it will be placed at somewhat an offset
    star.xoffset = flr(rnd(512)-256)
    star.yoffset = flr(rnd(512)-256)
  end
  return star
end

-- only generate planets if there is a star at x,y
function get_planet_info(x, y, planet_num)
  if planet_num > MAX_PLANETS do
    local p = {}
    p.exists = false
    return p
  end
  planet_seed(x, y, planet_num)
  local planet = {}
  planet.exists = rnd(8)>6
  if planet.exists do
    planet.type = flr(rnd(8))+2
    planet.radius = flr(rnd(10)+2)
    planet.mass = flr(rnd(10)+4)
  end
  return planet
end

-- get number of planets in sector
function get_planet_num(x, y)
  if not has_star(x, y) do
    return 0
  end
  local planets = 0
  for i=0,MAX_PLANETS do
    local p = get_planet_info(x, y, i)
    if p.exists do
      planets += 1
    end
  end
  return planets
end

-- local view, draws player ship in dead center of screen
function draw_local()
  local center = (128/2)-4)
  spr(1, center, center)
  -- todo: rotate ship
  -- todo: draw floating space particles to give sense of movement
  if debug do
    line(center, center, center+player.xspeed, center+player.yspeed, 3)
  end
  local starx = ((SECTOR_SIZE / 2) + star.xoffset) - player.x
  local stary = ((SECTOR_SIZE / 2) + star.yoffset) - player.y
  circfill(starx, stary, 5, 7)

  -- todo: draw star/planets when in view
end

-- draw the star map
function draw_space()
  for x=posx,posx+100 do
    for y=posy,posy+100 do
      if has_star(x, y) do
        pset(x-posx,y-posy, 7)
      end
    end
  end
end

-- draw a map of the specified sector
function draw_sector_map(x, y)
  local star = get_star_info(x, y)
  print("sector "..x..":"..y, 0, 0, 7)
  if star.exists do
    circfill(64,64, 3, 7)
    for i=0..MAX_PLANETS do
      local p = get_planet_info(x, y, i)
      if p.exists do
        circfill(64 + 3 + (i*3), 64, 2, p.type)
      end
    end
  else
    print("empty sector", 50, 64, 3)
  end
end

-- called when the player enters a new sector
-- unloads previous stars/planets from memory
-- sectors are too far apart for that to matter.
function sector_enter(x, y)
  star = get_star_info(x, y)
  planets = {}
  if star.exists do
    for i=0, MAX_PLANETS do
      planets[i] = get_planet_info(x, y, i)
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
