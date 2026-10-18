-- ===== swing beats =====
-- bateria por pcm (5512hz) con
-- swing y nudge a nivel muestra
pbit,mbit,patb,pats=0,64,32,20
tn=split("kik,snr,rim,hat,opn")
velg={.35,.65,1}
tunes={.84,.89,.94,1,1.06,1.12,1.19}
function lstr()
 kitn=split(tx("polvo,suave,cinta","dusty,soft,tape"))
 hmn=split(tx("azar,suave,fijo","rand,smth,lock"))
 grn=split(tx("ninguno,get dis,septillo,5/192,quint,aureo,apurado,borracho","none,get dis,septet,5/192,quint,golden,rush,drunk"))
end
-- por pista: largo,f0,f1,caida
-- tono,caida amp,tono,ruido,
-- caida ruido,filtro,brillo,click
kits={
"1500,160,50,90,700,1,.08,80,.5,0,.4,1300,230,185,200,250,.45,.85,500,.6,.3,0,400,900,750,100,70,.6,.35,60,1,1,0,300,0,0,1,1,0,.7,60,1,1,0,1500,0,0,1,1,0,.6,500,.9,1,0",
"1800,120,44,140,1000,1,.04,60,.3,0,.15,1100,210,180,300,320,.7,.45,380,.35,.1,0,350,700,650,120,90,.8,.2,50,.7,.6,0,260,0,0,1,1,0,.5,50,.6,1,0,1400,0,0,1,1,0,.45,420,.6,1,0",
"1200,190,58,60,450,1,.15,60,.7,0,.6,1000,250,190,150,200,.35,1,420,.9,.5,.2,300,1300,1100,80,50,.5,.5,40,1,1,.2,260,0,0,1,1,0,.9,45,1,1,.1,1300,0,0,1,1,0,.8,450,1,1,0"}
defp={
"30000002003000000000300000003001001000000100010020102010201020110000000000000020",
"30000002000302000000300000003000000000010000001020102010201020100000000000000020"}

vb,vn,vp,vg={},{},{},{}
lpf,ri,rj,rb,rc=0,1,1,{},{}
for i=1,337 do rb[i]=0 rc[i]=0 end
gx,gy=0,0

function initpart()
 if gd(127)&128==0 then
  for p=1,2 do
   local s=defp[p]
   for k=0,79 do fs(32+(p-1)*20,k,2,ord(s,k+1)-48) end
  end
  local d={64,82,74,56,56,20,6,5,4,4,4,0,5,2,2,140}
  for i=1,16 do sd(111+i,d[i]) end
 end
 renderall()
end

-- ---- sintesis de la bateria ----
function syn(n,f0,f1,pd,ad,ta,na,nd,nc,hp,ck)
 local b,ph,a,an,p,nl,pn={},0,1,1,1,0,0
 local ka,kn,kp=1-.693/ad,1-.693/nd,1-.693/pd
 for i=1,n do
  ph+=(f1+(f0-f1)*p)/sr
  local x=rnd(2)-1
  nl+=(x-nl)*nc
  local v=sin(ph)*a*ta+(nl*(1-hp)+(nl-pn)*hp*2)*an*na
  pn=nl
  if (i<12) v+=x*ck
  if (i>n-60) v*=(n-i)/60
  b[i]=v
  a*=ka an*=kn p*=kp
 end
 return b
end

function renderall()
 -- corta las voces: los buffers
 -- nuevos pueden ser mas cortos
 vp={}
 local k=split(kits[gd(123)+1])
 local tu=tunes[(gd(127)>>2&7)+1]
 for t=1,5 do
  local o=(t-1)*11
  local q={unpack(k,o+1,o+11)}
  q[2]*=tu q[3]*=tu
  vb[t]=syn(unpack(q))
  vn[t]=q[1]
 end
 -- parlante: satura el bombo para
 -- que tenga armonicos audibles en
 -- un parlante chico (bit 5 = off)
 if gd(127)&32<1 then
  local b,ph,a,f=vb[1],0,1,700*tu
  for i,v in ipairs(b) do
   ph+=f/sr f=max(300*tu,f*.997) a*=.993
   v+=sin(ph)*a
   b[i]=v*5/(1+abs(v*4))
  end
 end
 cka=syn(140,2200,2200,1,40,1,0,1,1,0,0)
 ckb=syn(140,1600,1600,1,30,.7,0,1,1,0,0)
 mkchip()
end

function dspvars()
 tc=(gd(124)+1)/8
 drv=1+gd(125)*.5
 rm=gd(126)*.07
 cr=({0,24,12,6})[(gd(127)&3)+1]
end

-- ---- motor pcm ----
function gen(n)
 for i=0,n-1 do
  if (i>=nxt) service(i)
  local s=0
  for t=1,6 do
   local p=vp[t]
   if p then
    s+=vb[t][p]*vg[t]
    vp[t]=p<vn[t] and p+1 or nil
   end
  end
  lpf+=(s-lpf)*tc
  s=lpf*drv
  s=s/(1+abs(s)*.5)
  local a,c=rb[ri],rc[rj]
  rb[ri]=s+a*.5 rc[rj]=s+c*.45
  ri=ri%233+1 rj=rj%337+1
  s+=(a+c)*rm
  if (cr>0) s=flr(s*cr)/cr
  poke(0x4300+i,128+mid(-127,127,s*100))
 end
end

-- ---- motor chip (fake-08) ----
chch={0,1,1,2,2}
function wnote(sl,i,p,w,v,f)
 local a,x=0x3200+sl*68+i*2-2,p+w*64+v*512+(f or 0)*4096
 poke(a,x%256,x\256)
end
function whead(sl,sp,l0,l1)
 poke(0x3200+sl*68+64,0,sp,l0 or 0,l1 or 0)
end
function mkchip()
 local d={
  {2,"6000000000","4828221713100705030201","6777777666554433221"},
  {2,"06666666666666","3044444040363634343232303030","67766554332211"},
  {1,"3333","44403836","6421"},
  {1,"6666666","63636060585858","5432211"},
  {2,"666666666666","606058585656565454545252","554433322211"}}
 for t=1,5 do
  local s=d[t]
  for k=1,3 do
   local sl=(t-1)*3+k-1
   for i=1,32 do
    local w,p,v=ord(s[2],i),0,0
    if w then
     w-=48 p=tonum(sub(s[3],i*2-1,i*2)) v=ord(s[4],i)-48
     if (v>0) v=max(1,flr(v*velg[k]*1.1+.5))
    else w=0 end
    wnote(sl,i,p,w,v)
   end
   whead(sl,s[1])
  end
 end
 for k=0,1 do
  for i=1,32 do wnote(16+k,i,i<3 and 46-k*5 or 0,4,i<3 and 6-k*2 or 0) end
  whead(16+k,2)
 end
end

-- ---- secuencia ----
function trig(i,p,s)
 for t=0,4 do
  local v=fg(32+p*20,t*16+s,2)
  if v>0 then
   local o=i+lead+max(-lead,boff(t,s)+hum(t,s))
   -- flam: golpe ghost antes
   -- de los golpes medios/fuertes
   local f=fg(11,t,2)*55.125
   if (f>0 and v>1) push(max(i,o-f),{h=t+1,v=1})
   push(o,{h=t+1,v=v})
  end
 end
end

function hit(t,v,i)
 add(uiq,{f=(bl+(i or 0))/91.875,pad=t})
 if pcm then
  vp[t],vg[t]=1,(gd(117+t)&7)/7*velg[v]
  if (t==4) vp[5]=nil
 else
  sfx((t-1)*3+v-1,chch[t])
 end
end

function fire(e,i)
 if e.ck then
  if pcm then
   vb[6]=e.a and cka or ckb vn[6]=140 vp[6]=1 vg[6]=.8
  else sfx(e.a and 16 or 17,3) end
 else hit(e.h,e.v,i) end
end

function onstart() end
function onstop() end
function onend() end
function onstep() end

-- ---- paginas ----
function gridpage()
 local p={n=tx("patron","pattern"),h=tx("o:vel o+^v:vel o+<>:rota","o:vel o+^v:vel o+<>:rotate")}
 p.mv=function(dx,dy) gx=(gx+dx)%16 gy=mid(0,4,gy+dy) end
 p.act=function()
  local b=32+ep*20
  local v=(fg(b,gy*16+gx,2)+1)%4
  fs(b,gy*16+gx,2,v)
  if (v>0) hit(gy+1,v)
 end
 p.adj=function(dx,dy)
  local b=32+ep*20
  if dy~=0 then
   local v=mid(0,3,fg(b,gy*16+gx,2)+dy)
   fs(b,gy*16+gx,2,v)
   if (v>0) hit(gy+1,v)
  end
  if dx~=0 then
   local r={}
   for s=0,15 do r[s]=fg(b,gy*16+s,2) end
   for s=0,15 do fs(b,gy*16+s,2,r[(s-dx)%16]) end
  end
 end
 p.draw=function()
  local b,vc=32+ep*20,{5,13,9}
  for t=0,4 do
   local y=46+t*10
   print(tn[t+1],1,y+2,gy==t and 7 or 6)
   for s=0,15 do
    local x,v=14+s*7,fg(b,t*16+s,2)
    local c=s%4==0 and 2 or 1
    if (v>0) c=vc[v]
    rectfill(x,y,x+5,y+7,c)
    if (v==3) rectfill(x+1,y+1,x+4,y+2,10)
   end
  end
  rect(13+gx*7,45+gy*10,20+gx*7,54+gy*10,7)
  if playing and cur>=0 and curp==ep then
   rectfill(14+cur*7,97,19+cur*7,98,11)
  end
  local v=fg(b,gy*16+gx,2)
  print("vel "..split(tx("-,ghost,media,fuerte","-,ghost,mid,hard"))[v+1],2,102,6)
  local s=playing and tx("suena ","playing ")..split("a,b,c,d")[curp+1] or ""
  print(s,126-#s*4,102,12)
 end
 return p
end

-- presets de groove: swing por
-- pista (char-64, @=global), flam
-- por pista, hum, modo, deriva
gpre=split("@@@@@00000000,AAADD00000310,AAAHH00000410,AAACC00000210,AAAAA00000310,AAAMM00000310,AAAAA00000310,AAAHH02000511")
function applyg()
 local s=gpre[gd(9)+1]
 for t=0,4 do
  sd(118+t,gd(118+t)&7|(ord(s,t+1)-64)<<3) sd(112+t,64)
  fs(11,t,2,ord(s,t+6)-48)
 end
 sd(117,ord(s,11)-48|(ord(s,12)-48)<<4)
 sd(10,ord(s,13)-48)
end

function groovepage()
 local function hs(a,m) sd(117,mid(0,15,a)|m<<4) end
 local its={
  {x=2,y=46,l="swg",v=function() return gd(3).."%" end,a=function(d) clampset(3,d,50,75) end,w=32},
  {x=38,y=46,l="base",v=function() return gd(13)>0 and 8 or 16 end,a=function() sd(13,1-gd(13)) end,w=30},
  {x=70,y=46,l="hum",v=function() return (gd(117)&15).."ms" end,a=function(d) hs((gd(117)&15)+d,gd(117)\16) end,w=32},
  {x=106,y=46,l="",v=function() return hmn[(gd(117)\16)+1] end,a=function(d) hs(gd(117)&15,((gd(117)\16)+d)%3) end,w=20},
  {x=2,y=55,l="grv",v=function() return grn[gd(9)+1] end,a=function(d) sd(9,(gd(9)+d)%8) end,k=applyg,w=62},
  {x=70,y=55,l=tx("deriva","drift"),v=function() return "+"..gd(10).."%" end,a=function(d) clampset(10,d,0,3) end,w=56}}
 for t=0,4 do
  local y=72+t*8
  add(its,{x=18,y=y,t=t,d=swcell,a=function(d)
   local b=gd(118+t) sd(118+t,b&7|mid(0,26,b\8+d)<<3) end})
  add(its,{x=36,y=y,t=t,d=nudgecell,a=function(d) clampset(112+t,d*2,0,124) end})
  add(its,{x=92,y=y,t=t,d=flcell,a=function(d) fs(11,t,2,mid(0,3,fg(11,t,2)+d)) end})
  add(its,{x=104,y=y,t=t,d=lvlcell,a=function(d)
   local b=gd(118+t) sd(118+t,b&~7|mid(0,7,(b&7)+d)) end})
 end
 return ipage("groove",its,function()
  print("sw  - nudge ms +  fl",18,64,5)
  print(tx("nvl","lvl"),106,64,5)
  for t=0,4 do print(tn[t+1],1,72+t*8,6) end
 end,tx("o en grv: aplica preset","o on grv: apply preset"))
end

function swcell(t,s)
 local w=gd(118+t.t)\8
 print(w>0 and w+49 or "--",t.x,t.y,s and 9 or w>0 and 6 or 5)
end

function nudgecell(t,s)
 local y,n=t.y,sgd(112+t.t)
 line(36,y+3,70,y+3,1)
 line(53,y,53,y+6,2)
 local x=53+n*.26
 rectfill(min(53,x),y+2,max(53,x),y+4,s and 9 or 13)
 local v=(n>0 and "+" or "")..n
 print(v,89-#v*4,y,s and 7 or 6)
end

function flcell(t,s)
 local f=fg(11,t.t,2)
 print(f>0 and f*10 or "-",t.x,t.y,s and 9 or f>0 and 6 or 5)
end

function lvlcell(t,s)
 local l=gd(118+t.t)&7
 for k=0,6 do
  rectfill(104+k*3,t.y+1,105+k*3,t.y+5,k<l and (s and 9 or 13) or 1)
 end
end

function kitpage()
 -- color, saturacion y sala se aplican
 -- en vivo (dspvars): no resintetizan
 local function cs(i) return function(d) clampset(i,d,0,7) end end
 local its={
  {x=2,y=48,l="kit",v=function() return kitn[gd(123)+1] end,a=function(d) sd(123,(gd(123)+d)%3) renderall() end,w=56},
  {x=66,y=48,l=tx("afinar","tune"),v=function() return (gd(127)>>2&7)-3 end,a=function(d)
   local f=gd(127) sd(127,f&0xe3|mid(0,6,(f>>2&7)+d)<<2) renderall() end,w=56},
  {x=2,y=60,l=tx("color","tone"),v=function() return gd(124) end,a=cs(124),w=56},
  {x=66,y=60,l=tx("saturar","drive"),v=function() return gd(125) end,a=cs(125),w=56},
  {x=2,y=72,l=tx("sala","room"),v=function() return gd(126) end,a=cs(126),w=56},
  {x=66,y=72,l="crush",v=function() return gd(127)&3 end,a=function(d)
   local f=gd(127) sd(127,f&0xfc|mid(0,3,(f&3)+d)) end,w=56},
  {x=2,y=84,l=tx("motor","engine"),v=function() return pcm and "pcm" or "chip" end,a=function()
   if (pcmok) pcm=not pcm
  end,w=56},
  {x=66,y=84,l=tx("parlante","speaker"),v=function() return gd(127)&32<1 and tx("si","on") or "no" end,a=function()
   sd(127,gd(127)^^32) renderall() end,w=56}}
 for t in all(its) do t.k=function() hit(1,3) hit(4,2) end end
 return ipage("kit",its,function()
  if (not pcmok) print(tx("sin pcm: usa pico-8 oficial","no pcm: use official pico-8"),2,106,8)
  cpu(96,96)
 end,tx("o:escuchar  o+<>:ajustar","o:listen  o+<>:adjust"))
end

-- ---- escena ----
function scene()
 rectfill(0,9,127,33,0)
 fillp(0b1010010110100101.1)
 rectfill(0,9,127,33,1)
 fillp()
 -- ventana con luna
 rectfill(96,11,124,31,4)
 rectfill(98,13,122,29,0)
 circfill(115,18,4,10) circfill(113,17,4,0)
 for i=0,5 do
  pset(100+i*37%21,15+i*23%12,(t()*2+i)%3<1 and 6 or 2)
 end
 -- tocadiscos
 rectfill(3,12,36,32,4)
 rectfill(4,13,35,31,2)
 circfill(18,22,9,0)
 circ(18,22,6,1)
 circfill(18,22,2,9)
 local a=playing and t()*.55 or 0
 line(18,22,18+cos(a)*8,22+sin(a)*8,5)
 line(32,14,30,24,6) line(30,24,25,27,6)
 -- pads
 for k=1,5 do
  local f=fl[k] or 0
  local x=42+(k-1)*10
  rectfill(x,15,x+8,25,f>.5 and 9 or f>.15 and 4 or 2)
  print(sub(tn[k],1,1),x+3,18,f>.5 and 0 or 5)
  fl[k]=f*.85
 end
end

-- ---- principal ----
function _init()
 lofipal()
 pcminit()
end
function mkpages()
 pages={gridpage(),groovepage(),kitpage(),songpage()}
 pg=1
end

function _update60()
 if pcm==nil and pcmcheck()~=nil then pcm=pcmok end
 if not song then
  pickupdate()
  return
 end
 dspvars()
 if pcm then
  local n=pcmneed(1024)
  if n>0 then
   bl=stat(108)
   gen(n)
   serial(0x808,0x4300,n)
   shift(n)
  end
 elseif playing then advance(91.875) end
 inp()
 uitick()
 savetick()
end

function _draw()
 if not song then
  pickdraw("swing beats",tx("bateria lofi con swing","swung lofi drums"))
  return
 end
 cls(0)
 header("swing beats")
 scene()
 tabs()
 pages[pg].draw()
 statusline()
 footer(pages[pg].h)
end
