parseSegment = (seg, acc)->
  parts = seg.split('|')
  segname = parts[0]
  for f,i in parts when i > 0
    acc.push({name:"#{segname}.#{i}", value: f})

parseRaw = (msg)->
  res = []
  segments = msg.split("\n")
  for seg in segments
    parseSegment(seg, res)
  res

flattenInfo = (node, path, acc)->
  # console.log(node.name || node.$.name, path, acc)
  if node.elems
    newPath = path.slice(0)
    unless node.name == "ORU_R01"
      newPath.push({name: node.name, min: node.min, max: node.max})
    node.elems.forEach (x)-> flattenInfo(x,newPath,acc)
  else if node.$type == 'field'
    acc.push({path: path, min: node.min, max: node.max, name: node.name, desc: node.desc})

parseFlatten = (msg, info)->
  res = []
  info_id = 0
  search = true
  inf = null
  for fld in msg
    while search
      inf = info[info_id]
      unless inf
        throw JSON.stringify(fld)
      if inf.name == fld.name
        search = false
        res.push({info: inf, field: fld}) if fld.value
      info_id += 1
    search = true
  res

parse = (msg, messageInfo)->
  flatten = []
  flattenInfo(messageInfo, [], flatten)
  raw = parseRaw(msg)
  parseFlatten(raw, flatten)

module.exports =
  parse: parse
