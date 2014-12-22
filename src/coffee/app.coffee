splitField = (x)->
  if x == ''
    null
  else
    x.split('^')

splitSegment = (x)->
  if x == ''
    null
  else
    x.split('|').map (y)->
      if y
        splitField(y)
      else
        null

parse = (msg)->
  msg.split("\n").map(splitSegment)

getf = (seg, pth, tp)->
  if pth.length == 1
    seg
  else
    fld = pth[1]
    res = seg[parseInt(fld)]

get = (msg, path, tp)->
  parts = path.split('.')
  seg = parts[0]
  msg
   .filter((x)-> x[0][0] == seg)
   .map (x)->
     if x == ''
       null
     else
       getf(x, parts, tp)
   .filter((x)-> !!x)



validate = (monad,msg)->
  errs = []
  for fn in monad.chain
    fn(msg, errs)
  errs

validation = (monad, pth, cb)->
  chain = monad.chain.slice(0)
  if cb
    chain.push (msg, errs)->
      cb(pth, get(msg,pth), msg, errs)

  newMonad = {
    chain: chain
    validation: (args...)->
      validation(newMonad, args...)
    apply: (msg)->
      validate(newMonad, msg)
  }

module.exports =
  parse: parse
  get: get
  validation: (args...)->
    validation({chain:[]}, args...)
