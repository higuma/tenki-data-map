# data presentation settings

# utility: geometric scale generator
generateScale = (x0, rx, n) ->
  x0 /= rx
  x0 *= rx for i in [0..n]

# zoom scale settings (must be same as or bigger than Google Maps limit)
MAXZOOM = 22

# point dot radius sizes for all zoom levels
dotScale = generateScale 0.14, 1.45, MAXZOOM

# temp/prec/sun gradient circle radius sizes for all zoom levels
circleScale = generateScale 0.15, 1.7, MAXZOOM

# wind scales for all zoom levels
windScale = generateScale 0.012, 1.7, MAXZOOM

# Small/Medium/Large option factor for gradient/wind
sizeScale = do ->
  scale = generateScale 1.0, 1.6, 3
  scale.unshift 0       # [0] = none
  scale

# color (fill/gradient) settings

# point fill setting
dotFill = 'rgba(0,0,0,0.5)'
dotFillGray = 'rgba(0,0,0,0.25)'

# gradient definitions

round = Math.round
log = Math.log

# temperature gradient
TempGrad = do ->
  rgb = [       # -50 to 50, RGB(%)
    { t: -50, r:   0, g:   0, b:   0 }
    { t: -45, r:   0, g:   0, b:  25 }
    { t: -40, r:   0, g:   0, b:  50 }
    { t: -35, r:   0, g:   0, b:  75 }
    { t: -30, r:   0, g:   0, b:  90 }
    { t: -25, r:   0, g:   0, b: 100 }
    { t: -20, r:  20, g:  20, b: 100 }
    { t: -15, r:  40, g:  40, b: 100 }
    { t: -10, r:  60, g:  60, b: 100 }
    { t:  -5, r:  80, g:  80, b: 100 }
    { t:   0, r: 100, g: 100, b: 100 }
    { t:   5, r:  50, g:  90, b:  95 }
    { t:  10, r:  35, g:  85, b:  55 }
    { t:  15, r:  80, g: 100, b:  35 }
    { t:  20, r:  90, g:  90, b:   0 }
    { t:  25, r: 100, g:  75, b:   0 }
    { t:  30, r: 100, g:  50, b:   0 }
    { t:  35, r: 100, g:   0, b:   0 }
    { t:  40, r:  75, g:   0, b:   0 }
    { t:  45, r:  50, g:   0, b:   0 }
    { t:  50, r:  25, g:   0, b:   0 }
  ]

  R2N = 255.0 / 100.0

  grad = []
  for bank in [0 ... rgb.length - 1]
    c0 = rgb[bank]
    c1 = rgb[bank + 1]
    t0 = round c0.t
    t1 = round c1.t
    for t in [t0...t1]
      blend1 = 1.0 * (t - t0) / (t1 - t0)
      blend0 = 1.0 - blend1
      r = round R2N * (c0.r * blend0 + c1.r * blend1)
      g = round R2N * (c0.g * blend0 + c1.g * blend1)
      b = round R2N * (c0.b * blend0 + c1.b * blend1)
      grad.push "rgba(#{r},#{g},#{b},0.5)"
  c = rgb[rgb.length - 1]
  r = round R2N * c.r
  g = round R2N * c.g
  b = round R2N * c.b
  grad.push "rgba(#{r},#{g},#{b},0.5)"
  grad

TempGradMax = TempGrad.length - 1

TempOffset = 50.0

tempGradient = (t) ->
  if t?
    if (t = round(t + TempOffset)) < 0
      t = 0
    else if t > TempGradMax
      t = TempGradMax
    TempGrad[t]
  else
    'none'

# precipitation gradient
PrecGrad = do ->
  grad = ["rgba(60,120,255,0)"]
  for i in [1..400]      # 0..200mm (step 0.5mm)
    r =  60 - i * 0.15
    g = 120 - i * 0.3
    b = 255 - i * 0.45
    a = log(i + 1) * 0.15
    grad.push "rgba(#{round r},#{round g},#{round b},#{a.toFixed 3})"
  grad

PrecGradMax = PrecGrad.length - 1

precGradient = (p) ->
  if p?
    if (p = round 2.0 * p) > PrecGradMax
      p = PrecGradMax
    PrecGrad[p]
  else
    'none'

# sunlight gradient
SunGrad = do ->
  grad = ["rgba(255,120,0,0)"]
  for i in [1..10]      # 0.0 to 1.0 step 0.1
    grad.push "rgba(255,120,0,#{(i * 0.075).toFixed 3})"
  grad

sunGradient = (s) ->
  SunGrad[round s * 10] || 'none'

# snowfall gradient
SnowfallGrad = do ->
  i = 0
  while i < PrecGrad.length
    x = PrecGrad[i]
    i += 10
    x

SnowfallGradMax = SnowfallGrad.length - 1

snowfallGradient = (f) ->
  if f?
    if (f = round f) > SnowfallGradMax
      f = SnowfallGradMax
    SnowfallGrad[f]
  else
    'none'

# snow depth gradient
SnowDepthGrad = PrecGrad
SnowDepthGradMax = SnowDepthGrad.length - 1

snowDepthGradient = (d) ->
  if d?
    if (d = round 0.5 * d) > SnowDepthGradMax
      f = SnowDepthGradMax
    SnowDepthGrad[d]
  else
    'none'

# wind path
WindPath = for i in [0..500]    # 0.0 to 50.0 step 0.1 [m/s]
  "M0,#{(i * 0.4).toFixed 1}L4,0L-4,0Z"

WindPathMax = WindPath.length - 1

renderWindPath = (v) ->
  if v?
    if (v = v * 10 >> 0) > WindPathMax
      v = WindPathMax
    WindPath[v]
  else
    'M0,0'

# animation interval
animationInterval = generateScale 1000, 0.5, 4

window.Presentation =
  generateScale: generateScale

  scale:
    dot: dotScale
    circle: circleScale
    wind: windScale
    size: sizeScale
  fill:
    dot:
      regular: dotFill
      grayed: dotFillGray
  gradient:
    temp: tempGradient
    prec: precGradient
    sun: sunGradient
    fall: snowfallGradient
    depth: snowDepthGradient
  path:
    wind:
      fill: 'rgba(0,0,150,0.35)'
      stroke: 'rgba(0,0,150,0.25)'
      strokeWidth: '3'
      strokeLineCap: 'round'
      strokeLineJoin: 'round'
      render: renderWindPath
  animation:
    interval: animationInterval
