var fs = require('fs');
var xml2js = require('xml2js');
var parser = new xml2js.Parser();
var Q = require('q');


function doIndex (idx, tp, coll){
  (coll || []).forEach(function(x){
    if(idx[x.$.name]){ console.log('Ups dup',x.$.name)}
    x.$type = tp;
    idx[x.$.name] = x;
  });
}

function loadXsd(path, type, idx){
  var def = Q.defer();
  fs.readFile(__dirname + '/../2.5.1/' + path, function(err, data) {
    parser.parseString(data, function (err, xml) {

      doIndex(idx, type, xml['xsd:schema']['xsd:complexType']);
      doIndex(idx, type, xml['xsd:schema']['xsd:element']);
      def.resolve(idx)
    });
  });
  return def.promise;
}

function resolveType(el, idx){
  return idx[el.$.type];
}

function resolveRef(el, idx){
  if(!el || !el.$ || !el.$.ref){
    return 'ups';
  }
  console.log('resolveRef', el)
  var res = idx[el.$.ref];
  res.minOccurs = el.$.minOccurs;
  res.maxOccurs = el.$.maxOccurs;
  return res
}


function expand(el, idx){
  try{
  if(el.$type == 'group'){
    console.log('GROUP', el)
    var tp = resolveType(el, idx)
    var elems = tp['xsd:sequence'] && tp['xsd:sequence'][0]['xsd:element']
      .map(function(x){ return expand(x, idx); });
    return {
      name: (el.$.name).replace(/^ORU_R01\./,''),
      // el: el,
      // tp: tp,
      min: el.minOccurs,
      max: el.maxOccurs,
      $type: 'group',
      elems: elems
    }
  }
  if(el.$type == 'segment'){
    var tp = resolveType(el, idx)
    var elems = tp['xsd:sequence'] && tp['xsd:sequence'][0]['xsd:element']
      .map(function(x){ return expand(x, idx); });
    return {
      name: el.$.name,
      // el: el,
      // tp: tp,
      min: el.minOccurs,
      max: el.maxOccurs,
      $type: 'segment',
      elems: elems
    }
  }
  if(el.$type == 'field'){
    var tp = resolveType(el, idx)
    var elems = tp['xsd:sequence'] && tp['xsd:sequence'][0]['xsd:element']
      .map(function(x){ return expand(x, idx); });
    return {
      name: el.$.name,
      desc: tp["xsd:annotation"][0]["xsd:documentation"][0]["_"],
      // el: el,
      // tp: tp,
      min: el.minOccurs,
      max: el.maxOccurs,
      hl7: tp["xsd:annotation"] && tp["xsd:annotation"][0]["xsd:appinfo"][0],
      $type: 'field',
      elems: elems
    }
  } else if(el.$.ref){
    console.log('REF:', el)
    return expand(resolveRef(el, idx), idx);
  } else {
    console.log('>>:', el)
    return el;
  }
  }catch(e){
    console.error(e);
  }
  // var nm = (el && el.$ && (el.$.ref || el.$.type));
  // var root = idx[nm];
  // res = {}
  // if(!root){ return {orig: el}; }

  // if(root.$.type){
  //   return {orig: root, elems: expand(root,idx)}
  // }

  // if(!root){ return {orig: el}; }

  // if(root['xsd:simpleContent']){ return {orig: root, name: (root.$ && root.$.name)}; }

  // if(root['xsd:complexContent'] && root['xsd:complexContent'][0]['xsd:extension']){
  //   var grp = root['xsd:complexContent'][0]['xsd:extension'][0].$.base
  //   if(grp){
  //     return {orig: root, dt: expand(grp, idx)};
  //   }else{
  //     return {orig: root, name: root.$.name};
  //   }
  // }
  // if(!root){ return {orig: el, name: el.$.name} }
  // var meta = {orig: root, name: root.$.name};
  // // meta.el = el.$;
  // meta.elems = root['xsd:sequence'] && root['xsd:sequence'][0]['xsd:element']
  //   .map(function(x){ return expand(x, idx); })
}

function main(){
  var mkLoad = function(pth, tp){
    return function(idx){
      return loadXsd(pth, tp, idx)
    }
  }

  loadXsd('datatypes.xsd', 'type', {})
    .then(mkLoad('segments.xsd', 'segment'))
    .then(mkLoad('fields.xsd', 'field'))
    .then(mkLoad('ORU_R01.xsd', 'group'))
    .then(function(idx){
      fs.writeFile("result.json",JSON.stringify(expand(idx['ORU_R01'], idx), null, " "));
      console.log('Done');
    })
    .catch(function(err){ console.err(err);})
}
main()
