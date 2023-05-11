## Operations taking or returning heterogeneous components
import ../backend/laser
import ../backend/ops
import ../backend/sandwich
import ../utils
import ./types

type SomeActed = Point | Line | Plane

# # ===== Group Actions

##############
# Reflection #
##############

func reflect*(acted: Point, actor: Plane): Point =
  ## Reflect a point through the plane
  sw30(actor.p0, acted.p3, result.p3)

func reflect*(acted: Line, actor: Plane): Line =
  ## Reflect a line through the plane
  sw10(actor.p0, acted.p1, result.p1, result.p2)
  var tmp: m128
  sw20(actor.p0, acted.p2, tmp)
  result.p2 = mm_add_ps(result.p2, tmp)

func reflect*(acted: Plane, actor: Plane): Plane =
  ## Reflect a plane through the plane
  sw00(actor.p0, acted.p0, result.p0)

#########
# Rotor #
#########

func rotate*(acted: Line, actor: Rotor): Line =
  ## Rotate lines with this rotor.
  ## It is much more efficient to pack and rotate at once.
  swMM(acted.p1.unsafeAddr, actor.p1, nil, result.p1.addr,
       VARIADIC=false, TRANSLATE=false, INPUT_P2=true)

func rotate*(acted: Branch, actor: Rotor): Branch =
  ## Rotate a single (branch) line with this rotor.
  swMM(acted.p1.unsafeAddr, actor.p1, nil, result.p1.addr,
       VARIADIC=false, TRANSLATE=false, INPUT_P2=false)

func rotate*[T: Point | Direction | Plane](acted: T, actor: Rotor): T =
  ## Rotate a single plane / point / direction with this rotor.
  ## These 3 operations are all identical.
  ## It is much more efficient to pack and rotate at once.
  sw012(cast[ptr m128](acted.unsafeAddr), actor.p1, nil, cast[ptr m128](result.addr),
        VARIADIC=false, TRANSLATE=false)

template `>@`*[T: SomeActed](acted: T | Branch | Direction, actor: Rotor): T =
  acted.rotate(actor)

# Packed Rotate
func rotate*[T: Point | Direction | Plane](actor: Rotor, acted: ptr T, output: ptr T, count: int) =
  ## Rotate packed (plane/point/direction) with this rotor and store in array provided to output.
  ## These operations are identical.
  ## It is much more efficient to pack and rotate at once.
  ## Can alias if acted=output.
  sw012(cast[ptr m128](acted), actor.p1, nil, cast[ptr m128](output),
       count=count, VARIADIC=true, TRANSLATE=false)

func rotate*(actor: Rotor, acted: ptr Line, output: ptr Line, count: int) =
  ## Rotate packed planes with this rotor and store in array provided to output.
  ## It is much more efficient to pack and rotate at once.
  ## Can alias if acted=output.
  swMM(cast[ptr m128](acted), actor.p1, nil, cast[ptr m128](output),
       count=count, VARIADIC=true, TRANSLATE=false, INPUT_P2=true)

template rotate*[T: SomeActed|Direction](actor: Rotor, acted: openArray[T], output: var openArray[T]) =
  actor.rotate(acted[0].unsafeAddr, output[0].addr, count=acted.len)

##########
# Slider #
##########

func slide*(acted: Point, actor: Slider): Point =
  Point(p3: sw32(acted.p3, actor.p2))

func slide*(acted: Line, actor: Slider): Line =
  swL2(acted.p1, acted.p2, actor.p2, result.p1, result.p2)

func slide*(acted: Plane, actor: Slider): Plane =
  let tmp = mm_blend_ps(actor.p2, mm_set_ss(1'f32), 1'u8)
  Plane(p0: sw02(acted.p0, tmp))

################
# Move (Motor) #
################

func move*[T: Point | Direction](acted: T, actor: Motor): T =
  ## Move a single point or direction with this rotor.
  ## It is much more efficient to pack and move at once.
  sw312(cast[ptr m128](acted.p3.unsafeAddr),
        actor.p1, actor.p2.unsafeAddr,
        cast[ptr m128](result.p3.addr),
        VARIADIC=false, TRANSLATE=T is Point)

func moveOrigin*(actor: Motor): Point =
  swo12(actor.p1, actor.p2, result.p3)

func move*[T: Line|Branch](acted: T, actor: Motor): T =
  ## Move a single line (or branch) with this rotor.
  swMM(acted.p1.unsafeAddr,
       actor.p1, actor.p2.unsafeAddr,
       result.p1.addr,
       VARIADIC=false, TRANSLATE=true, INPUT_P2=T is Line)

func move*(acted: Plane, actor: Motor): Plane =
  ## Move a single plane with this rotor.
  ## It is much more efficient to pack and move at once.
  sw012(cast[ptr m128](acted.p0.unsafeAddr),
        actor.p1, actor.p2.unsafeAddr,
        cast[ptr m128](result.p0.addr),
        VARIADIC=false, TRANSLATE=true)

# Packed Move
func move*[T: Point | Direction](actor: Motor, acted: ptr T, output: ptr T, count: int) =
  ## Move packed points with this rotor and store in array provided to output.
  ## It is much more efficient to pack and move at once.
  ## Can alias if acted=output.
  sw312(cast[ptr m128](acted), actor.p1, actor.p2.unsafeAddr,
        cast[ptr m128](output),
        count=count, VARIADIC=true, TRANSLATE=T is Point)

func move*(actor: Motor, acted: ptr Line, output: ptr Line, count: int) =
  ## Move packed planes with this rotor and store in array provided to output.
  ## It is much more efficient to pack and move at once.
  ## Can alias if acted=output.
  swMM(cast[ptr m128](acted), actor.p1, actor.p2.unsafeAddr,
       cast[ptr m128](output),
       count=count, VARIADIC=true, TRANSLATE=true, INPUT_P2=true)

func move*(actor: Motor, acted: ptr Plane, output: ptr Plane, count: int) =
  ## Move packed (plane/point/direction) with this rotor and store in array provided to output.
  ## These operations are identical.
  ## It is much more efficient to pack and move at once.
  ## Can alias if acted=output.
  sw012(cast[ptr m128](acted), actor.p1, actor.p2.unsafeAddr,
        cast[ptr m128](output),
        count=count, VARIADIC=true, TRANSLATE=true)

template move*[T: SomeActed | Direction](actor: Motor, acted: openArray[T], output: var openArray[T]) =
  actor.move(acted[0].unsafeAddr, output[0].addr, count=acted.len)

# # ===== Harm


# Generic Apply for Confused People
template apply*[T: SomeActed](acted: T, actor: Plane): T =
  acted.reflect(actor)

template apply*[T: SomeActed|Branch|Direction](acted: T, actor: Rotor): T =
  acted.rotate(actor)

template apply*[T: SomeActed](acted: T, actor: Slider): T =
  acted.slide(actor)

template apply*[T: SomeActed|Direction](acted: T, actor: Motor): T =
  acted.move(actor)

when defined(ALLOW_HUMAN_HARM):
  template `>|`*[T: SomeActed](acted: T, actor: Plane): T =
    acted.reflect(actor)
    
  template `>@`*[T: SomeActed|Branch|Direction](acted: T, actor: Motor): T =
    acted.rotate(actor)

  template `>>`*[T: SomeActed](acted: T, actor: Slider): T =
    acted.slide(actor)

  template `>%`*[T: SomeActed|Direction](acted: T, actor: Motor): T =
    acted.move(actor)

  # Right-chaining apply
  template `[]`*[T: SomeActed](acted: T, actor: Plane): T =
    acted.reflect(actor)

  template `[]`*[T: SomeActed](acted: T | Branch | Direction, actor: Rotor): T =
    acted.rotate(actor)

  template `[]`*[T: SomeActed](acted: T, actor: Slider): T =
    acted.slide(actor)

  template `[]`*[T: SomeActed|Direction](acted: T, actor: Motor): T =
    acted.move(actor)

