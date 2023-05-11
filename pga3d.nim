## Fast 3D Projective Geometric Algebra
## Contains special types for fast computation
## A port of sorts of klein
## 
## Since there are 16 (4x4) distinct elements of the 3D PGA
## We can represent it by 4 m128s
## 
##       LSB =================== MSB
##   p0:     e0   e1   e2   e3      
##   p1:     1    e23  e31  e12    
##   p2:     I    e03  e02  e01        
##   p3:     e123 e032 e013 e021      
##                x    y    z
import pga3d/types
import pga3d/[access, hetgen]
import pga3d/[hetops, exp_log, products, arithmetic]
import pga3d/[exterior_meet, join_dual, inner]
import pga3d/dual
import pga3d/[plane, rotor, slider, motor, line, point]

## BUG Must have __vectorcall for procs / funcs including SSE if compiling via MSVC

export
  Plane, Line, Direction, Point, Rotor, Slider, Motor,
  Branch, IdealLine, Dual, Origin,
  plane, rotor, slider, motor, line, point, dual,
  hetops, exp_log, products, arithmetic, access, hetgen,
  exterior_meet, join_dual, inner
