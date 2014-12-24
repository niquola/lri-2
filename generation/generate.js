var fs = require('fs');
var xml2js = require('xml2js');
var parser = new xml2js.Parser();
var Q = require('q');


function doIndex (idx, tp, coll){
  (coll || []).forEach(function(x){
    if(idx[x.$.name]){ console.log('DUPLICATE',x.$.name); }
    x.$type = tp;
    idx[x.$.name] = x;
  });
}

function loadXsd(path, type, idx){
  var def = Q.defer();
  fs.readFile(__dirname + '/../2.5.1/' + path, function(err, data) {
    parser.parseString(data, function (err, xml) {

      doIndex(idx, type, get(xml, ['xsd:schema','xsd:complexType']));
      doIndex(idx, type, get(xml, ['xsd:schema','xsd:element']));
      def.resolve(idx);
    });
  });
  return def.promise;
}

function resolveType(el, idx){
  return idx[el.$.type];
}

function resolveRef(el, idx){
  if(!el || !el.$ || !el.$.ref){ return 'ups'; }
  var res = idx[el.$.ref];
  res.minOccurs = el.$.minOccurs;
  res.maxOccurs = el.$.maxOccurs;
  return res;
}

function get(obj, path){
  var val = obj;
  for(var i=0; i < path.length; i++){
    val = val[path[i]];
    if(!val){ return null; }
  }
  return val;
}


function expand(el, idx){
  var tp, elems = null;
  try{
    if(el.$type == 'group' || el.$type == 'segment'){
      tp = resolveType(el, idx);
      elems = (get(tp, ['xsd:sequence',0,'xsd:element']) || [])
        .map(function(x){ return expand(x, idx); });
      return {
        name: (el.$.name).replace(/^ORU_R01\./,''),
          min: el.minOccurs,
          max: el.maxOccurs,
          $type: el.$type,
          elems: elems
      };
    }
    if(el.$type == 'field'){
      tp = resolveType(el, idx);
      var hl7 = get(tp, ["xsd:annotation",0,"xsd:appinfo",0]);

      elems = (get(tp, ['xsd:sequence',0,'xsd:element']) || [])
        .map(function(x){ return expand(x, idx); });

      return {
        name: el.$.name,
          desc: get(tp,["xsd:annotation",0,"xsd:documentation",0,"_"]),
          min: el.minOccurs,
          max: el.maxOccurs,
          hl7: hl7,
          type: get(hl7,["hl7:Type",0]),
          table: get(hl7,["hl7:Table",0]),
          $type: 'field',
          elems: elems
      };
    } else if(el.$.ref){
      return expand(resolveRef(el, idx), idx);
    } else {
      console.log('UPS should not be here', el);
      return el;
    }
  }catch(e){
    console.error(e);
  }
}

function main(){
  var mkLoad = function(pth, tp){
    return function(idx){
      return loadXsd(pth, tp, idx);
    };
  };

  loadXsd('datatypes.xsd', 'type', {})
    .then(mkLoad('segments.xsd', 'segment'))
    .then(mkLoad('fields.xsd', 'field'))
    .then(mkLoad('ORU_R01.xsd', 'group'))
    .then(function(idx){
      var info = JSON.stringify(expand(idx.ORU_R01, idx), null, " ");
      fs.writeFile("result.json", info);
    })
  .catch(function(err){ console.err(err);});
}
main();
