---
---

class Vector
  constructor: (@x, @y) ->

  mag: ->
    return Math.sqrt(@mag_sq())

  mag_sq: ->
    return @x * @x + @y * @y

  minus: (vec) ->
    @x -= vec.x
    @y -= vec.y
    return @

  plus: (vec) ->
    @x += vec.x
    @y += vec.y
    return @

  s_mult: (factor) ->
    @x *= factor
    @y *= factor
    return @

  s_div: (factor) ->
    @x /= factor
    @y /= factor
    return @

  @add: (vec1, vec2) ->
    return new Vector(vec1.x, vec1.y).plus(vec2)

  @subtract: (vec1, vec2) ->
    return new Vector(vec1.x, vec1.y).minus(vec2)

  @unit: (vec) ->
    mag = vec.mag()
    if mag != 0
      return new Vector(vec.x / mag, vec.y / mag)
    else
      return new Vector(0, 0)

  @s_mult: (vec, k) ->
    return new Vector(vec.x, vec.y).s_mult(k)

  @s_div: (vec, k) ->
    return new Vector(vec.x, vec.y).s_div(k)


class Particle
  constructor: (x, y, @mass, @color) ->
    @pos = new Vector(x, y)
    @vel = new Vector(0, 0)


  force: (pos, vel) =>
    difference = Vector.subtract(MOUSE.pos, pos)
    # Set the minimum at 25 to avoid a mouse-singularity
    dist_sq = Math.max(difference.mag_sq(), 25)

    velocity = @vel.mag()
    g_force = 1000 * MOUSE.mass * @mass / dist_sq
    spring_force = 0.01 * Math.sqrt(dist_sq)

    spring_and_g_force_vector = Vector.unit(difference)
      .s_mult(Math.min(g_force, spring_force))

    damp_force_vector = Vector.s_mult(@vel, -0.01)

    return spring_and_g_force_vector.plus(damp_force_vector)

  update: (canvas, ctx, tick) =>
    f = @force(@pos, @vel)
    accel = Vector.s_div(f, @mass)

    # Update position
    delta_pos = Vector.add(@vel, Vector.s_mult(accel, tick).s_div(2))
    @pos.plus(delta_pos.s_mult(tick))

    #console.log("X: #{@pos.x}, VX: #{@vel.x}, AX: #{accel.x}")

    f = @force(@pos, @vel)
    accel2 = Vector.s_div(f, @mass)

    # Update velocity
    delta_vel = Vector.add(accel2, accel).s_div(2)
    @vel.plus(delta_vel.s_mult(tick))
   
    # Bounds check
    if @pos.x < 0 or @pos.x > canvas.width
      @pos.x = Math.min(Math.max(@pos.x, 0), canvas.width)
      @vel.x = -@vel.x * 0.5
    if @pos.y < 0 or @pos.y > canvas.height
      @pos.y = Math.min(Math.max(@pos.y, 0), canvas.height)
      @vel.y = -@vel.y * 0.5

    @mass = Math.min(Math.max(@vel.mag()/1, 0.1), 1)

  draw: (ctx) =>
    ctx.save()
    ctx.beginPath()

    ctx.translate(@pos.x, @pos.y)

    ctx.ellipse(0, 0, 5 * @mass, 5 * @mass, 0, 0, 2*Math.PI, false)
    ctx.fillStyle = @color
    ctx.fill()

    ctx.closePath()
    ctx.restore()

class Animator
  MS_PER_TICK: 1000 / 60.0
  constructor: (canvas) ->
    @$canvas = canvas
    @canvas = @$canvas[0]
    @$canvas.mousemove(@update_mouse_pos)
    @$canvas.mousedown(@explode_particles)
    @particles = @generate_particles(1)
    @tick = window.performance.now()

  generate_particles: (num) ->
    colors = ['#FF5454', '#FF904A', '#FFCD57', '#FFFC85', '#FFF']
    funcs = _.times(num, () =>
      -> return new Particle(_.random(0, @canvas.width),
                             _.random(0, @canvas.height),
                             1,
                             colors[_.random(0, colors.length)])
    )
    return _.map(funcs, (f) -> f())

  update_mouse_pos: (evt) =>
    rect = @canvas.getBoundingClientRect()
    MOUSE.pos.x = evt.clientX - rect.left
    MOUSE.pos.y = evt.clientY - rect.top

  # Make the particles explode away from the mouse
  explode_particles: (evt) =>
    for particle in @particles
      difference = Vector.subtract(MOUSE.pos, particle.pos)
      dist = Math.max(difference.mag(), 1)
      
      push_force = -1000 
      vel_mag = push_force / dist
      particle.vel.plus(Vector.unit(difference).s_mult(vel_mag))

  draw: =>
    while window.performance.now() > @tick
      for particle in @particles
        particle.update(@canvas, ctx, 1)
      @tick += @MS_PER_TICK

    ctx = @canvas.getContext("2d")
    ctx.globalCompositeOperation = 'source-over'
    ctx.fillStyle = "rgba(0, 0, 0, 128)"
    ctx.fillRect(0, 0, @canvas.width, @canvas.height)
    #ctx.clearRect(0, 0, @canvas.width, @canvas.height)
    for particle in @particles
      particle.draw(ctx)

    window.requestAnimationFrame(@draw)

MOUSE =
  pos: 
    x: 0
    y: 0
  mass: 1
$ ->
  MOUSE = 
    pos: new Vector(0, 0)
    mass: 1
  animator = new Animator($("canvas"))
  window.requestAnimationFrame(animator.draw)
