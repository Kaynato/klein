## Special types described in 3D PGA useful for render.
##       LSB =================== MSB
##   p0:     e0   e1   e2   e3      
##   p1:     1    e23  e31  e12    
##   p2:     I    e03  e02  e01        
##   p3:     e123 e032 e013 e021      
##                x    y    z

import ../backend/laser

type
  Plane* = object
    ## Plane described by 4 points
    p0*: m128

  Line* = object
    ## Line described by plucker coordinates
    p1*, p2*: m128
    ## (1 I) are both zeroed.

  Branch* = object
    ## A Line through the origin
    p1*: m128

  IdealLine* = object
    ## A line at infinity
    ## a e01 + b e02 + c e03
    p2*: m128

  Point* = object
    ## Point defined by x032 y013 z021 e123 - e123 1
    p3*: m128

  Direction* = object
    ## Direction - Ideal point at infinity - e123 zero
    p3*: m128

  Rotor* = object
    p1*: m128

  Slider* = object
    p2*: m128

  Motor* = object
    p1*, p2*: m128

  Dual* = object
    p*, q*: float32

  SomeLine* = Line|Branch|IdealLine