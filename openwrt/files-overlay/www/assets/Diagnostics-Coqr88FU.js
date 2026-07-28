import{_ as V}from"./index-BqihnWnD.js";import{O as C,W as a,aj as n,L as d,a0 as t,_ as N,M as P,P as v,$ as x,Z as q,k as m}from"./vue-HEoUudR2.js";import"./element-plus-CguUK-Ti.js";const h={key:0,class:"diag-output"},w={__name:"Diagnostics",setup(B){const e=m("8.8.8.8"),s=m("ping"),r=m(!1),l=m("");function _(){r.value=!0,l.value="",setTimeout(()=>{s.value==="ping"?l.value=`PING ${e.value} (${e.value}): 56 data bytes
64 bytes from ${e.value}: seq=0 ttl=54 time=8.234 ms
64 bytes from ${e.value}: seq=1 ttl=54 time=7.891 ms
64 bytes from ${e.value}: seq=2 ttl=54 time=8.102 ms
64 bytes from ${e.value}: seq=3 ttl=54 time=7.956 ms
64 bytes from ${e.value}: seq=4 ttl=54 time=8.012 ms

--- ${e.value} ping statistics ---
5 packets transmitted, 5 packets received, 0% packet loss
round-trip min/avg/max = 7.891/8.039/8.234 ms`:s.value==="traceroute"?l.value=`traceroute to ${e.value}, 30 hops max
 1  192.168.1.1  0.523 ms  0.412 ms  0.389 ms
 2  100.64.1.1  3.245 ms  3.102 ms  3.089 ms
 3  10.255.0.1  5.678 ms  5.534 ms  5.412 ms
 4  202.97.33.1  8.901 ms  8.756 ms  8.623 ms
 5  ${e.value}  9.234 ms  9.102 ms  9.056 ms`:s.value==="nslookup"?l.value=`Server:  202.96.128.86
Address: 202.96.128.86#53

Non-authoritative answer:
Name: ${e.value}
Address: 142.250.80.46
Name: ${e.value}
Address: 2404:6800:4008:800::200e`:l.value=`端口扫描: ${e.value}
  22/tcp   open   ssh
  80/tcp   open   http
  443/tcp  open   https
  53/tcp   open   domain
  其他端口关闭

扫描完成: 1000个端口, 4个开放`,r.value=!1},1500)}return(D,o)=>{const f=n("PageHeader"),g=n("el-input"),i=n("el-form-item"),u=n("el-option"),b=n("el-select"),$=n("el-button"),k=n("el-form"),c=n("SectionCard"),y=n("PageContainer");return d(),C(y,null,{default:a(()=>[t(f,{title:"路由表"}),t(c,{class:"page-section-frame",shadow:"never","content-padding":"none"},{default:a(()=>[t(c,{shadow:"never"},{header:a(()=>[...o[2]||(o[2]=[v("span",null,"网络诊断工具",-1)])]),default:a(()=>[t(k,{inline:""},{default:a(()=>[t(i,{label:"目标地址"},{default:a(()=>[t(g,{modelValue:e.value,"onUpdate:modelValue":o[0]||(o[0]=p=>e.value=p),placeholder:"IP或域名"},null,8,["modelValue"])]),_:1}),t(i,{label:"工具"},{default:a(()=>[t(b,{modelValue:s.value,"onUpdate:modelValue":o[1]||(o[1]=p=>s.value=p)},{default:a(()=>[t(u,{label:"Ping",value:"ping"}),t(u,{label:"Traceroute",value:"traceroute"}),t(u,{label:"nslookup",value:"nslookup"}),t(u,{label:"端口扫描",value:"portscan"})]),_:1},8,["modelValue"])]),_:1}),t(i,null,{default:a(()=>[t($,{type:"primary",onClick:_,loading:r.value},{default:a(()=>[...o[3]||(o[3]=[N("执行",-1)])]),_:1},8,["loading"])]),_:1})]),_:1}),l.value?(d(),P("div",h,[v("pre",null,x(l.value),1)])):q("",!0)]),_:1})]),_:1})]),_:1})}}},T=V(w,[["__scopeId","data-v-41caff60"]]);export{T as default};
