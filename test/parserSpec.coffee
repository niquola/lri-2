subj = require('../src/coffee/app')
_msg = """
MSH|^~\&|EPICADT|DH|LABADT|DH|201301011226||ADT^A01|HL7MSG00001|P|2.3|
EVN|A01|201301011223||
PID|||MRN12345^5^M11||APPLESEED^JOHN^A^III||19710101|M||C|1 CATALYZE STREET^^MADISON^WI^53005-1020|GL|(414)379-1212|(414)271-3434||S||MRN12345001^2^M10|123456789|987654^NC|
NK1|1|APPLESEED^BARBARA^J|WIFE||||||NK^NEXT OF KIN
PV1|1|I|2000^2012^01||||004777^GOOD^SIDNEY^J.|||SUR||||ADM|A0|
"""

pp = (args...)->
  console.log.apply(console, args)

msg = subj.parse(_msg)

FN = [
  {label: "Surname", type: 'ST', required: 'R'}
  {label: "Own Surname Prefix", required: 'O'}
  {label: "Own Surname", required: 'O'}
  {label: "Surname Prefix From"}
  {label: "Partner/Spouse", required: 'O'}
  {label: "Surname From"}
  {label: "Partner/Spouse", required: 'O'}
]

# pp subj.get(msg, 'PID.5', FN)
# pp subj.get(msg, 'NK1.2', FN)
# pp subj.get(msg, 'NK1.2')

required = (path, x, msg, errs)->
  # console.log('validate',path, x)
  if x.length == 0
    errs.push("#{path} required")

debugMsg = (msg)->
  for seg in msg
    for f,i in seg
      console.log("#{seg[0][0]}.#{i}", f)

debug = (pth, x)->
  console.log(pth,x)

errs = subj
  .validation('PID.5', required)
  .validation('PID.2', required)
  .validation('NK1.2', required)
  .validation('MSH.1', debug)
  .validation('PV1.7', debug)
  .validation 'MSH.12', (p, x, m,err)->
    unless x[0] == '2.5'
      err.push(['LRI-19', "#{p} should have value 2.5"])
  .validation 'PID.5', (p, x, m,err)->
    console.log('PID.5:',x[0])
  .validation 'MSH.22', (p, x, m,err)->
    codes = ['2.16.840.1.113883.9.16','2.16.840.1.113883.9.16']
    if x.length == 0
      err.push(['LRI-14', "#{p} is required"])
    if codes.indexOf(x[0]) < 0
      err.push(['LRI-14', "#{p} value expected one of #{JSON.stringify(codes)}, but got #{JSON.stringify(x)}"])
  .apply(msg)

pp errs
