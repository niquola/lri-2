subj = require('../src/coffee/parser')

_msg = """
MSH|^~\&|^2.16.840.1.113883.3.72.5.20^ISO|^2.16.840.1.113883.3.72.5.21^ISO||^2.16.840.1.113883.3.72.5.23^ISO|20110331160551-0700||ORU^R01^ORU_R01|NIST-LRI-TC-NG-XXX.XX|T|2.5.1|||AL|NE|||||Base Profile LRI R1^^2.16.840.1.113883.9.16^ISO~Profile NG^^2.16.840.1.113883.9.13^ISO~Profile RU^^2.16.840.1.113883.9.14^ISO
PID|1||PATID1234^^^&2.16.840.1.113883.3.72.5.30.1&ISO^MR||JONES^WILLIAM||||||||||||||||||||||
ORC|RE|ORD723222^^2.16.840.1.113883.3.72.5.24^ISO|R-783274^^2.16.840.1.113883.3.72.5.25^ISO|GORD874211^^2.16.840.1.113883.3.72.5.24^ISO||||||||57422^RADON^NICHOLAS^^^^^^&2.16.840.1.113883.3.72.5.30.1&ISO
OBR|1|ORD723222^^2.16.840.1.113883.3.72.5.24^ISO|R-783274^^2.16.840.1.113883.3.72.5.25^ISO|30341-2^Erythrocyte sedimentation rate^LN|||20110331140551-0700|||||||||57422^RADON^NICHOLAS^^^^^^&2.16.840.1.113883.3.72.5.30.1&ISO||||||20110331160428-0700|||F|||10092^HAMLIN^PAFFORD
"""

_msg=require('raw!./msg.hl7')
messageInfo = require('json!../generation/result.json')

pp = (args...)->
  console.log.apply(console, args)

msg = subj.parse(_msg, messageInfo)

pp subj.validate(msg)

