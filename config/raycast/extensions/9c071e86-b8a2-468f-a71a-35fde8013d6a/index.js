"use strict";var de=Object.create;var N=Object.defineProperty;var ge=Object.getOwnPropertyDescriptor;var pe=Object.getOwnPropertyNames;var ve=Object.getPrototypeOf,ye=Object.prototype.hasOwnProperty;var U=(t,e)=>()=>(e||t((e={exports:{}}).exports,e),e.exports),Se=(t,e)=>{for(var r in e)N(t,r,{get:e[r],enumerable:!0})},B=(t,e,r,n)=>{if(e&&typeof e=="object"||typeof e=="function")for(let o of pe(e))!ye.call(t,o)&&o!==r&&N(t,o,{get:()=>e[o],enumerable:!(n=ge(e,o))||n.enumerable});return t};var Q=(t,e,r)=>(r=t!=null?de(ve(t)):{},B(e||!t||!t.__esModule?N(r,"default",{value:t,enumerable:!0}):r,t)),be=t=>B(N({},"__esModule",{value:!0}),t);var z=U(V=>{"use strict";var p=require("react");function F(){return(F=Object.assign||function(t){for(var e=1;e<arguments.length;e++){var r=arguments[e];for(var n in r)Object.prototype.hasOwnProperty.call(r,n)&&(t[n]=r[n])}return t}).apply(this,arguments)}typeof Symbol<"u"&&(Symbol.iterator||(Symbol.iterator=Symbol("Symbol.iterator"))),typeof Symbol<"u"&&(Symbol.asyncIterator||(Symbol.asyncIterator=Symbol("Symbol.asyncIterator")));var he=typeof window<"u"&&window.document!==void 0&&window.document.createElement!==void 0?p.useLayoutEffect:p.useEffect,we={status:"not-requested",loading:!1,result:void 0,error:void 0},W={status:"loading",loading:!0,result:void 0,error:void 0},$=function(){},Ce={initialState:function(t){return t&&t.executeOnMount?W:we},executeOnMount:!0,executeOnUpdate:!0,setLoading:function(t){return W},setResult:function(t,e){return{status:"success",loading:!1,result:t,error:void 0}},setError:function(t,e){return{status:"error",loading:!1,result:void 0,error:t}},onSuccess:$,onError:$},_=function(t,e,r){!e&&(e=[]);var n,o=function(s){return F({},Ce,{},s)}(r),l=p.useState(null),f=l[0],d=l[1],u=function(s){var g=p.useState(function(){return s.initialState(s)}),m=g[0],c=g[1],S=p.useCallback(function(){return c(s.initialState(s))},[c,s]),x=p.useCallback(function(){return c(s.setLoading(m))},[m,c]),A=p.useCallback(function(k){return c(s.setResult(k,m))},[m,c]),H=p.useCallback(function(k){return c(s.setError(k,m))},[m,c]),me=p.useCallback(function(k){return c(F({},m,{},k))},[m,c]);return{value:m,set:c,merge:me,reset:S,setLoading:x,setResult:A,setError:H}}(o),i=(n=p.useRef(!1),p.useEffect(function(){return n.current=!0,function(){n.current=!1}},[]),function(){return n.current}),a=function(){var s=p.useRef(null);return{set:function(g){return s.current=g},get:function(){return s.current},is:function(g){return s.current===g}}}(),b=function(s){return i()&&a.is(s)},O=function(s){var g=p.useRef(s);return he(function(){g.current=s}),p.useCallback(function(){return g.current},[g])}(function(){for(var s=arguments.length,g=new Array(s),m=0;m<s;m++)g[m]=arguments[m];var c=function(){try{return Promise.resolve(t.apply(void 0,g))}catch(S){return Promise.reject(S)}}();return d(g),a.set(c),u.setLoading(),c.then(function(S){b(c)&&u.setResult(S),o.onSuccess(S,{isCurrent:function(){return a.is(c)}})},function(S){b(c)&&u.setError(S),o.onError(S,{isCurrent:function(){return a.is(c)}})}),c}),D=p.useCallback(function(){return O().apply(void 0,arguments)},[O]),q=!i();return p.useEffect(function(){var s=function(){return O().apply(void 0,e)};q&&o.executeOnMount&&s(),!q&&o.executeOnUpdate&&s()},e),F({},u.value,{set:u.set,merge:u.merge,reset:u.reset,execute:D,currentPromise:a.get(),currentParams:f})};function Z(t,e,r){return _(t,e,r)}V.useAsync=Z,V.useAsyncAbortable=function(t,e,r){var n=p.useRef();return Z(function(){for(var o=arguments.length,l=new Array(o),f=0;f<o;f++)l[f]=arguments[f];try{n.current&&n.current.abort();var d=new AbortController;return n.current=d,Promise.resolve(function(u,i){try{var a=Promise.resolve(t.apply(void 0,[d.signal].concat(l)))}catch(b){return i(!0,b)}return a&&a.then?a.then(i.bind(null,!1),i.bind(null,!0)):i(!1,value)}(0,function(u,i){if(n.current===d&&(n.current=void 0),u)throw i;return i}))}catch(u){return Promise.reject(u)}},e,r)},V.useAsyncCallback=function(t,e){return _(t,[],F({},e,{executeOnMount:!1,executeOnUpdate:!1}))}});var te=U(G=>{"use strict";var v=require("react");function R(){return R=Object.assign||function(t){for(var e=1;e<arguments.length;e++){var r=arguments[e];for(var n in r)Object.prototype.hasOwnProperty.call(r,n)&&(t[n]=r[n])}return t},R.apply(this,arguments)}var We=typeof Symbol<"u"?Symbol.iterator||(Symbol.iterator=Symbol("Symbol.iterator")):"@@iterator",$e=typeof Symbol<"u"?Symbol.asyncIterator||(Symbol.asyncIterator=Symbol("Symbol.asyncIterator")):"@@asyncIterator";function xe(t,e){try{var r=t()}catch(n){return e(!0,n)}return r&&r.then?r.then(e.bind(null,!1),e.bind(null,!0)):e(!1,value)}var Ae=typeof window<"u"&&typeof window.document<"u"&&typeof window.document.createElement<"u"?v.useLayoutEffect:v.useEffect,Oe=function(e){var r=v.useRef(e);return Ae(function(){r.current=e}),v.useCallback(function(){return r.current},[r])},Ie={status:"not-requested",loading:!1,result:void 0,error:void 0},X={status:"loading",loading:!0,result:void 0,error:void 0},Pe=function(e){return X},Ee=function(e,r){return{status:"success",loading:!1,result:e,error:void 0}},Re=function(e,r){return{status:"error",loading:!1,result:void 0,error:e}},K=function(){},Le={initialState:function(e){return e&&e.executeOnMount?X:Ie},executeOnMount:!0,executeOnUpdate:!0,setLoading:Pe,setResult:Ee,setError:Re,onSuccess:K,onError:K},De=function(e){return R({},Le,{},e)},ke=function(e){var r=v.useState(function(){return e.initialState(e)}),n=r[0],o=r[1],l=v.useCallback(function(){return o(e.initialState(e))},[o,e]),f=v.useCallback(function(){return o(e.setLoading(n))},[n,o]),d=v.useCallback(function(a){return o(e.setResult(a,n))},[n,o]),u=v.useCallback(function(a){return o(e.setError(a,n))},[n,o]),i=v.useCallback(function(a){return o(R({},n,{},a))},[n,o]);return{value:n,set:o,merge:i,reset:l,setLoading:f,setResult:d,setError:u}},Fe=function(){var e=v.useRef(!1);return v.useEffect(function(){return e.current=!0,function(){e.current=!1}},[]),function(){return e.current}},Me=function(){var e=v.useRef(null);return{set:function(n){return e.current=n},get:function(){return e.current},is:function(n){return e.current===n}}},Y=function(e,r,n){!r&&(r=[]);var o=De(n),l=v.useState(null),f=l[0],d=l[1],u=ke(o),i=Fe(),a=Me(),b=function(m){return i()&&a.is(m)},O=function(){for(var m=arguments.length,c=new Array(m),S=0;S<m;S++)c[S]=arguments[S];var x=function(){try{return Promise.resolve(e.apply(void 0,c))}catch(A){return Promise.reject(A)}}();return d(c),a.set(x),u.setLoading(),x.then(function(A){b(x)&&u.setResult(A),o.onSuccess(A,{isCurrent:function(){return a.is(x)}})},function(A){b(x)&&u.setError(A),o.onError(A,{isCurrent:function(){return a.is(x)}})}),x},D=Oe(O),q=v.useCallback(function(){return D().apply(void 0,arguments)},[D]),s=!i();return v.useEffect(function(){var g=function(){return D().apply(void 0,r)};s&&o.executeOnMount&&g(),!s&&o.executeOnUpdate&&g()},r),R({},u.value,{set:u.set,merge:u.merge,reset:u.reset,execute:q,currentPromise:a.get(),currentParams:f})};function ee(t,e,r){return Y(t,e,r)}var Te=function(e,r,n){var o=v.useRef(),l=function(){for(var d=arguments.length,u=new Array(d),i=0;i<d;i++)u[i]=arguments[i];try{o.current&&o.current.abort();var a=new AbortController;return o.current=a,Promise.resolve(xe(function(){return Promise.resolve(e.apply(void 0,[a.signal].concat(u)))},function(b,O){if(o.current===a&&(o.current=void 0),b)throw O;return O}))}catch(b){return Promise.reject(b)}};return ee(l,r,n)},qe=function(e,r){return Y(e,[],R({},r,{executeOnMount:!1,executeOnUpdate:!1}))};G.useAsync=ee;G.useAsyncAbortable=Te;G.useAsyncCallback=qe});var j=U((_e,J)=>{"use strict";process.env.NODE_ENV==="production"?J.exports=z():J.exports=te()});var je={};Se(je,{default:()=>fe});module.exports=be(je);var T=require("react"),L=require("@raycast/api");var I=require("react"),y=require("@raycast/api"),ne=Q(j()),h=require("react/jsx-runtime"),Ne=({onSubmit:t})=>{let[e,r]=(0,I.useState)(""),[n,o]=(0,I.useState)(),[l,f]=(0,I.useState)("new");(0,ne.useAsync)(async()=>{let u=await y.LocalStorage.getItem("test-string-history");!u||o(JSON.parse(u))},[]),(0,I.useEffect)(()=>{re[l]?r(re[l]):r(n?.find(u=>u.id===l)?.value||"")},[l]);let d=(0,I.useCallback)(()=>{y.LocalStorage.removeItem("test-string-history"),o(void 0)},[]);return(0,h.jsxs)(y.Form,{actions:(0,h.jsxs)(y.ActionPanel,{children:[(0,h.jsx)(y.Action.SubmitForm,{title:"Test Regex",onSubmit:t}),(0,h.jsx)(y.Action,{title:"Clear Previous Test Strings",onAction:d,shortcut:{modifiers:["cmd"],key:"backspace"}})]}),children:[(0,h.jsxs)(y.Form.Dropdown,{id:"source",title:"",defaultValue:"new",onChange:f,children:[(0,h.jsx)(y.Form.Dropdown.Item,{value:"new",title:"New Test String"}),(0,h.jsx)(y.Form.Dropdown.Item,{value:"lorem",title:"Lorem Ipsum"}),n&&(0,h.jsx)(y.Form.Dropdown.Section,{title:"Previous Test Strings",children:n.map(u=>(0,h.jsx)(y.Form.Dropdown.Item,{value:u.id,title:u.value},u.id))})]}),(0,h.jsx)(y.Form.TextArea,{id:"text",title:"",placeholder:"Enter your test string",value:e,onChange:r})]})},re={lorem:"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla malesuada viverra elit, at placerat metus dictum at. Aliquam pretium, massa nec interdum hendrerit, libero ipsum rutrum nibh, iaculis fringilla magna ante sit amet quam. Donec imperdiet leo risus, et accumsan sem malesuada eu. Nunc suscipit urna magna, sit amet tempus lectus laoreet vitae. Fusce in dolor vitae lacus luctus ullamcorper. Maecenas faucibus fringilla feugiat. Phasellus purus mauris, molestie vel dolor eget, posuere iaculis mauris. Nunc blandit neque ut semper ultrices. Cras tempus mollis pharetra. Quisque euismod orci eget augue lobortis feugiat. Suspendisse at consequat eros."},oe=Ne;var le=Q(j());var M=require("@raycast/api"),P=require("react");var ue=require("@raycast/api"),He=require("react/jsx-runtime"),Ve=()=>(0,He.jsx)(ue.List.Item.Detail,{markdown:Ge}),Ge=`
# Regular Expression Cheat Sheet

## Character Classes

\`.\`

any character except newline

\`\\w\\d\\s\`

word, digit, whitespace

\`\\W\\D\\S\`

not word, digit, whitespace

\`[abc]\`

any of a, b, or c

\`[^abc]\`

not a, b, or c

\`[a-g]\`

character between a & g

## Anchors

\`^abc$\`

start / end of the string

\`\\b\\B\`

word, not-word boundary

## Escaped characters

\`\\.\\*\\\\\`

escaped special characters

\`\\t\\n\\r\`

tab, linefeed, carriage return

## Groups & Lookaround

\`(abc)\`

capture group

\`\\1\`

backreference to group #1

\`(?:abc)\`

non-capturing group

\`(?=abc)\`

positive lookahead

\`(?!abc)\`

negative lookahead

## Quantifiers & Alternation

\`a*a+a?\`

0 or more, 1 or more, 0 or 1

\`a{5}a{2,}\`

exactly five, two or more

\`a{1,3}\`

between one & three

\`a+?a{2,}?\`

match as few as possible

\`ab|cd\`

match ab or cd

`,se=Ve;var w=require("@raycast/api"),C=require("react/jsx-runtime"),Ue=({onOptionsChange:t})=>(0,C.jsxs)(w.List.Dropdown,{tooltip:"Regex Options",defaultValue:"gm",onChange:t,children:[(0,C.jsx)(w.List.Dropdown.Item,{title:"No Modifiers",value:""}),(0,C.jsx)(w.List.Dropdown.Item,{title:"Global (/g)",value:"g"}),(0,C.jsx)(w.List.Dropdown.Item,{title:"Case-Insensitive (/i)",value:"i"}),(0,C.jsx)(w.List.Dropdown.Item,{title:"Multiline (/m)",value:"m"}),(0,C.jsx)(w.List.Dropdown.Item,{title:"Global, Case-Insensitive (/gi)",value:"gi"}),(0,C.jsx)(w.List.Dropdown.Item,{title:"Global, Multiline (/gm)",value:"gm"}),(0,C.jsx)(w.List.Dropdown.Item,{title:"Case-Insensitive, Multiline (/im)",value:"im"}),(0,C.jsx)(w.List.Dropdown.Item,{title:"All Modifiers (/gim)",value:"gim"})]}),ae=Ue;var E=require("react/jsx-runtime"),Je=({testString:t})=>{let[e,r]=(0,P.useState)(""),[n,o]=(0,P.useState)(""),[l,f]=(0,P.useState)("gm"),d=(0,P.useCallback)(u=>{f(u)},[]);return(0,P.useEffect)(()=>{if(e===""){o(t);return}try{let u=t.replace(new RegExp(e,l),i=>`|${i}|`);o(u)}catch(u){console.log("regex error",u)}},[t,e,l]),(0,E.jsxs)(M.List,{isShowingDetail:!0,enableFiltering:!1,searchBarPlaceholder:"([A-Z])\\w+",searchText:e,onSearchTextChange:r,searchBarAccessory:(0,E.jsx)(ae,{onOptionsChange:d}),children:[(0,E.jsx)(M.List.Item,{title:"Preview",subtitle:"",detail:(0,E.jsx)(M.List.Item.Detail,{markdown:n})}),(0,E.jsx)(M.List.Item,{title:"Cheat Sheet",subtitle:"",detail:(0,E.jsx)(se,{})})]})},ie=Je;var ce=require("react/jsx-runtime");function fe(){let[t,e]=(0,T.useState)(""),[r,n]=(0,T.useState)(),{push:o}=(0,L.useNavigation)();(0,le.useAsync)(async()=>{if(r==="new"){let f={id:Date.now().toString(),value:t},d=await L.LocalStorage.getItem("test-string-history");if(d){let u=JSON.parse(d),i=[f,...u].slice(0,5);await L.LocalStorage.setItem("test-string-history",JSON.stringify(i))}else await L.LocalStorage.setItem("test-string-history",JSON.stringify([f]))}},[r]);let l=(0,T.useCallback)(f=>{e(f.text),n(f.source),o((0,ce.jsx)(ie,{testString:f.text}))},[]);return(0,ce.jsx)(oe,{onSubmit:l})}0&&(module.exports={});
