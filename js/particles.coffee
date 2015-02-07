---
---
MOUSE = 
  x: 0
  y: 0
  mass: 1000


class Particle
  constructor: (@x, @y, @mass) ->
    @vx = 0.0
    @vy = 0.0
    @G = 10000

  force: (x_dist, y_dist) =>
    dist_sq = Math.max(x_dist * x_dist + y_dist * y_dist, 25)
    g_force = @G * MOUSE.mass * @mass * 1 / dist_sq
    # TODO Implement spring force
    return g_force

  update: (canvas, ctx, tick) =>
    x_dist = MOUSE.x - @x
    y_dist = MOUSE.y - @y

    f = @force(x_dist, y_dist)
    angle = Math.atan2(y_dist, x_dist)
    ax = f * Math.cos(angle) / @mass
    ay = f * Math.sin(angle) / @mass

    @x += tick * (@vx + tick * ax / 2)
    if @x < 0 or @x > canvas.width
      @x = Math.min(Math.max(@x, 0), canvas.width)
      @vx = -@vx * 0.9
    @y += tick * (@vy + tick * ay / 2)
    if @y < 0 or @y > canvas.height
      @y = Math.min(Math.max(@y, 0), canvas.height)
      @vy = -@vy * 0.9

    #console.log("X: #{@x}, VX: #{@vx}, AX: #{ax}")

    x_dist = MOUSE.x - @x
    y_dist = MOUSE.y - @y

    f = @force(x_dist, y_dist)
    angle = Math.atan2(y_dist, x_dist)
    ax2 = f * Math.cos(angle) / @mass
    ay2 = f * Math.sin(angle) / @mass

    @vx += tick * (ax + ax2) / 2
    @vy += tick * (ay + ay2) / 2

  draw: (ctx) =>
    ctx.save()
    ctx.beginPath()

    ctx.translate(@x, @y)

    ctx.fillStyle = 'green'
    ctx.ellipse(0, 0, 5, 5, 0, 0, 2*Math.PI, false)
    ctx.fill()

    ctx.closePath()
    ctx.restore()

class Animator
  constructor: (canvas) ->
    @$canvas = canvas
    @canvas = @$canvas[0]
    @$canvas.mousemove(@update_mouse_pos)
    @particles = @generate_particles(50)
    @tick = 1

  generate_particles: (num) ->
    funcs = _.times(num, () =>
      -> return new Particle(_.random(0, @canvas.width),
                             _.random(0, @canvas.height),
                             Math.random()*0.01 + 1)
    )
    return _.map(funcs, (f) -> f())

  update_mouse_pos: (evt) =>
    rect = @canvas.getBoundingClientRect()
    MOUSE.x = evt.clientX - rect.left
    MOUSE.y = evt.clientY - rect.top

  draw: =>
    start = Date.now()
    ctx = @canvas.getContext("2d")
    ctx.clearRect(0, 0, @canvas.width, @canvas.height)

    for particle in @particles
      particle.update(@canvas, ctx, @tick)
      particle.draw(ctx)

    end = Date.now()
    @tick = (Math.max(end - start, 10)) / 1000.0

    window.requestAnimationFrame(@draw)

$ ->
  animator = new Animator($("canvas"))
  window.requestAnimationFrame(animator.draw)
