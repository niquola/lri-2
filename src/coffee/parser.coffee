parseSegment = (seg, acc)->
  parts = seg.split('|')
  if parts[0] == 'MSH'
    parts.splice(1,0,'|')
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
  if node.elems
    newPath = path.slice(0)
    unless node.name == "ORU_R01"
      newPath.push({name: node.name, min: node.min, max: node.max})
    node.elems.forEach (x)-> flattenInfo(x,newPath,acc)
  if node.$type == 'field'
    field = clone(node)
    field.path = path
    acc.push(field)

clone = (x)->
  JSON.parse(JSON.stringify(x))

lookdown = (info_id,fld, info)->
  while inf = info[info_id]
    if inf.name == fld.name
      return [inf, info_id]
    info_id += 1
  return [null,null]

lookup = (info_id,fld, info)->
  while inf = info[info_id]
    if inf.name == fld.name
      return [inf, info_id]
    info_id -= 1
  return [null,null]

parseFlatten = (msg, info)->
  res = []
  info_id = 0
  inf = null
  for fld in msg when fld.value
    [inf, cursor] = lookdown(info_id, fld, info)
    [inf, cursor] = lookup(info_id, fld, info) unless inf
    unless inf
      throw "Error while parse: field: #{JSON.stringify(fld)} #{info_id}"
    info_id = cursor
    field = clone(inf)
    field.value = fld.value
    res.push(field)
  res

parse = (msg, messageInfo)->
  raw = parseRaw(msg)
  info = []
  flattenInfo(messageInfo, [], info)
  parseFlatten(raw, info)

find = (msg, nm)->
  res = msg.filter((x)-> x.name == nm)[0]
  if res
    res.value
  else
    null

rules =[
  ['LRI-6', (msg, err)->
    subj = find(msg, 'MSH.1')
    if not subj
      err("require MSH.1", subj)
    else if subj.indexOf('|') < 0
      err("MSH.1 should contain | symbol", subj)
  ]
  ['LRI-7', (msg, err)->
    subj = find(msg, 'MSH.2')
    if not (subj == '^~\&' or subj == '^~\&#')
      err("MSH-2 (Encoding Characters) SHALL contain the constant value ‘^~\\&’ or the constant value ‘^~\\&#’.", subj)
  ]
  ['LRI-8', (msg, err)->
    subj = find(msg, 'MSH.9')
    unless subj == 'ORU^R01^ORU_R01'
      err("MSH-9 (Message Type) SHALL contain the constant value ‘ORU^R01^ORU_R01’.)", subj)
  ]
  ['LRI-15', (msg, err)->
    subj = find(msg, 'MSH.15')
    unless subj == 'ALL'
      err('MSH-15 (Accept Acknowledgement Type) SHALL contain the constant value ‘AL’.')
  ]
  ['LRI-11', (msg, err)->
    subj = find(msg, 'MSH.16')
    unless subj == 'NE'
      err('MSH-16 (Application Acknowledgement Type) SHALL contain the constant value ‘NE’.')
  ]
  ['LRI-56', (msg, err)->
    obxs = msg.filter((x)-> x.name == 'OBX.5' || x.name == 'OBX.2')
    for obx,i in obxs when obx.name == 'OBX.5' and obxs[i - 1].value == 'CE'
      subj = obx.value.split('^')
      unless subj[0] and subj[2] and subj[3] and subj[5]
        err('If OBX-5 (Observation Value) is CE (as indicated in OBX-2), then CE.1 (Identifier) and CE.3 (Name of Coding System) or CE. 4 (Alternate Identifier) and CE.6 (Name of Alternate Coding System) SHALL be valued.', subj)
  ]
  ['LRI-41', (msg, err)->
    obrs = msg.filter((x)-> x.name == 'OBR-11')
    for obr in obrs when obr.value
      unless ['A','G','L','O'].indexOf(obr.value) > -1
        err('If valued, OBR-11 (Specimen Action Code) SHALL be a value with “A”, “G”, “L”, or “O”.')
  ]
]


validate = (msg)->
  errs=[]
  for [nm,rule] in rules
    err = (msg,fld)-> errs.push([nm,msg,fld])
    rule(msg, err)
  errs


module.exports =
  parse: parse
  validate: validate
