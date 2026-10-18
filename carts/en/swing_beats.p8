pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- ===== nucleo comun swing =====
-- la cancion vive en cartdata
-- (256 bytes en 0x5e00). mapa:
-- 0 magia 1 version 2 bpm
-- 3 swing 4 tono 5 escala
-- 6 semilla 7 largo 8 click
-- 16-31 cadena (arreglo)
-- 32-127 beats 128-239 keys
-- 240-255 noise
dd=0x5e00
sr=5512.5
lead=230
notes=split("c,c#,d,d#,e,f,f#,g,g#,a,a#,b")
-- idioma: 1 espanol, 2 english
-- (x en el selector lo cambia)
lang=2
function tx(a,b) return lang==2 and b or a end
scl={{0,2,3,5,7,9,10},{0,2,3,5,7,8,10},{0,2,4,5,7,9,11},{0,2,4,5,7,9,10}}

function gd(i) return peek(dd+i) end
function sd(i,v) poke(dd+i,v) dirty=true end
-- campo de w bits nro i desde b
function fg(b,i,w)
 local k=i*w
 return peek(dd+b+k\8)>>k%8&(1<<w)-1
end
function fs(b,i,w,v)
 local k=i*w
 local a,m=dd+b+k\8,((1<<w)-1)<<k%8
 poke(a,peek(a)&~m|v<<k%8)
 dirty=true
end
function sgd(i) return gd(i)-64 end

-- ---- cancion ----
function opensong(n)
 song=n
 cartdata("swingbox_cancion"..n)
 if gd(0)~=0x5b then
  memset(dd,0,256)
  local h={0x5b,1,82,62,9,0,flr(rnd(256)),4,1}
  for i=1,9 do sd(i-1,h[i]) end
  local c={16,16,21,16}
  for i=1,4 do sd(15+i,c[i]) end
 end
 scn=split(tx("dorico,menor,mayor,mixo","dorian,minor,major,mixo"))
 lstr()
 initpart()
 mkpages()
 mkmenu()
 mode=0 ep=0
 xu,ou,px,po=true,true,btn(5),btn(4)
end

-- ---- secuenciador ----
playing=false seqon=false
mode=1 ep=0 cur=-1 curp=0 curc=0
pq={} uiq={} tail=0 fl={}
sq,nxt,bl=0,9999,0

function steplen()
 local l,w=sr/gd(2)*15,gd(3)/50
 return stp%2==0 and l*w or l*(2-w)
end

function startplay(r)
 rec=r playing=true seqon=true
 srand(gd(6))
 ci,rep,st,cnt=0,0,0,0
 if (r) mode=1 cnt=gd(8)>0 and 16 or 0
 pq,uiq={},{}
 sq,nxt,tail=lead,lead,0
 cur=-1
 onstart()
end

function stopplay()
 playing,seqon,rec=false
 pq={} cur=-1
 onstop()
end

function push(t,e)
 e.t=t
 local j=#pq+1
 while j>1 and pq[j-1].t>t do
  pq[j]=pq[j-1] j-=1
 end
 pq[j]=e
end

function seqstep(i)
 if cnt>0 then
  stp=16-cnt cnt-=1
  if (stp%4==0) push(i+lead,{ck=1,a=stp==0})
  return
 end
 if st==0 then
  if mode==0 then pp,mt=ep,false
  else
   local e=gd(16+ci)
   pp,mt=e>>pbit&3,e&mbit>0
  end
 end
 stp=st
 push(i+lead,{m=st,p=pp,c2=ci})
 if (not mt) trig(i,pp,st)
 st+=1
 if st==16 then
  st=0
  if mode==1 then
   rep+=1
   if rep>=1<<(gd(16+ci)>>4&3) then
    rep=0 ci+=1
    if ci>=gd(7) then
     ci=0
     if rec then
      seqon=false
      push(i+steplen()+lead,{x=1})
     end
    end
   end
  end
 end
end

function service(i)
 if seqon and i>=sq then
  seqstep(i) sq+=steplen()
 end
 while pq[1] and pq[1].t<=i do
  local e=deli(pq,1)
  if e.m then
   add(uiq,{f=(bl+i)/91.875,s=e.m,p=e.p,c=e.c2})
  elseif e.x then tail=90 onend()
  else fire(e,i) end
 end
 nxt=pq[1] and pq[1].t or 9999
 if (seqon) nxt=min(nxt,sq)
end

function shift(n)
 sq-=n
 for e in all(pq) do e.t-=n end
 nxt=pq[1] and pq[1].t or 9999
 if (seqon) nxt=min(nxt,sq)
end

-- avanza n muestras sin pcm
-- (los eventos suenan por sfx)
function advance(n)
 bl=0
 while nxt<n do service(nxt) end
 shift(n)
end

function uitick()
 for u in all(uiq) do
  u.f-=1
  if u.f<=0 then
   del(uiq,u)
   if u.pad then fl[u.pad]=1
   else
    cur,curp,curc=u.s,u.p,u.c
    onstep(u.s)
   end
  end
 end
 if tail>0 then
  tail-=1
  if (tail==0) stopplay() done=60
 end
 if (done and done>0) done-=1
end

-- ---- pcm ----
-- deteccion: el pico-8 oficial
-- vacia el buffer; fake-08 no
function pcminit()
 memset(0x4300,128,1024)
 serial(0x808,0x4300,1024)
 pcmok=nil pf=0
end
function pcmcheck()
 if pcmok==nil then
  pf+=1
  if (stat(108)>100 and stat(108)<1024) pcmok=true
  if (pf>4 and not pcmok) pcmok=false
 end
 return pcmok
end
-- cuantas muestras faltan
function pcmneed(tb)
 return mid(0,512,tb-stat(108))
end

-- ---- input ----
px,po,xu,ou=false,false,false,false
function inp()
 local o,x=btn(4),btn(5)
 local dx=(btnp(1) and 1 or 0)-(btnp(0) and 1 or 0)
 local dy=(btnp(3) and 1 or 0)-(btnp(2) and 1 or 0)
 if (x and not px) xu=false
 if (o and not po) ou=false
 local p=pages[pg]
 if x then
  if dx~=0 or dy~=0 then
   xu=true
   if dx~=0 then pg=(pg-1+dx)%#pages+1 end
   if (dy~=0) ep=(ep+dy)%4
  end
 elseif o then
  if dx~=0 or dy~=0 then
   ou=true p.adj(dx,-dy)
  end
 elseif dx~=0 or dy~=0 then
  p.mv(dx,dy)
 end
 if px and not x and not xu then
  if playing then stopplay() else startplay(false) end
 end
 if (po and not o and not ou) p.act()
 px,po=x,o
end

-- ---- paginas de items ----
-- item: x,y,l(abel),v(alor fn)
-- a(djust fn dx,dy) k(acc fn)
function ipage(nm,its,dr,hp)
 local p={n=nm,its=its,ic=1,h=hp}
 p.mv=function(dx,dy)
  local c,b,bs=its[p.ic],p.ic,999
  for i,t in pairs(its) do
   local ex,ey=t.x-c.x,t.y-c.y
   local pr=ex*dx+ey*dy
   if pr>0 then
    local s=pr+2*abs(ex*dy+ey*dx)
    if (s<bs) b,bs=i,s
   end
  end
  p.ic=b
 end
 p.adj=function(dx,dy)
  local t=its[p.ic]
  if (t.a) t.a(dx+dy,dx,dy)
 end
 p.act=function()
  local t=its[p.ic]
  if (t.k) t.k()
 end
 p.draw=function()
  if (dr) dr()
  for i,t in pairs(its) do
   local s=i==p.ic
   if t.d then t.d(t,s)
   else
    print(t.l,t.x,t.y,s and 7 or 6)
    local v=t.v()
    print(v,t.x+(t.w or 28)-#tostr(v)*4,t.y,s and 9 or 13)
    if (s) line(t.x,t.y+6,t.x+(t.w or 28)-2,t.y+6,9)
   end
  end
 end
 return p
end

function clampset(i,d,lo,hi)
 sd(i,mid(lo,hi,gd(i)+d))
end

-- pagina cancion (compartida)
function songpage()
 local its={
  {x=2,y=46,l="bpm",v=function() return gd(2) end,a=function(d) clampset(2,d,60,160) end},
  {x=34,y=46,l="swg",v=function() return gd(3) end,a=function(d) clampset(3,d,50,75) end},
  {x=66,y=46,l=tx("tono","key"),v=function() return notes[gd(4)+1] end,a=function(d) sd(4,(gd(4)+d)%12) end},
  {x=98,y=46,l=tx("esc","scl"),v=function() return sub(scn[gd(5)+1],1,3) end,a=function(d) sd(5,(gd(5)+d)%4) end},
  {x=2,y=56,l=tx("largo","len"),v=function() return gd(7) end,a=function(d) clampset(7,d,1,16) end,w=40},
  {x=46,y=56,l="click",v=function() return gd(8)>0 and tx("si","on") or "no" end,a=function() sd(8,1-gd(8)) end,w=36},
  {x=86,y=56,l=tx("modo","mode"),v=function() return mode==1 and tx("cad","song") or "loop" end,a=function() mode=1-mode end,w=40}
 }
 for i=0,15 do
  add(its,{x=4+i%8*15,y=72+i\8*21,i=i,
   d=chaincell,
   k=function()
    if (ro) return
    local e=gd(16+i)
    local s=pbit
    sd(16+i,e&~(3<<s)|((e>>s&3)+1)%4<<s)
   end,
   a=function(_,dx,dy)
    if (ro) return
    local e=gd(16+i)
    if (dy~=0) sd(16+i,e&0xcf|mid(0,3,(e>>4&3)+dy)<<4)
    if (dx~=0 and mbit) sd(16+i,e^^mbit)
   end})
 end
 return ipage(tx("cancion","song"),its,nil,ro and tx("arreglo: se edita en beats/keys","arrangement: edit in beats/keys") or tx("o:patron o+^v:x2 o+<>:mute","o:pattern o+^v:x2 o+<>:mute"))
end

function chaincell(t,s)
 local i=t.i
 local e,x,y=gd(16+i),t.x,t.y
 local on=i<gd(7)
 local pl=playing and mode==1 and curc==i
 rectfill(x,y,x+12,y+17,pl and 4 or on and 1 or 0)
 rect(x,y,x+12,y+17,s and 7 or on and 2 or 1)
 local l=split("a,b,c,d")
 local b,k=e&3,e>>2&3
 local c1,c2=on and 9 or 5,on and 12 or 5
 print(e&64>0 and "-" or l[b+1],x+2,y+2,c1)
 print(e&128>0 and "-" or l[k+1],x+2,y+10,c2)
 print(1<<(e>>4&3),x+8,y+6,on and 6 or 2)
 if (pl) line(x+1,y+16,x+1+11*cur/15,y+16,10)
end

-- ---- menu de pausa ----
function mkmenu()
 menuitem(1,tx("grabar cancion","record song"),function()
  if (playing) stopplay()
  startplay(true)
 end)
 menuitem(2,tx("copiar patron","copy pattern"),function() copypat(ep) end)
 menuitem(3,tx("pegar patron","paste pattern"),function() pastepat(ep) end)
 menuitem(4,tx("borrar patron","clear pattern"),function() clearpat(ep) end)
 menuitem(5,tx("cambiar cancion","change song"),function() extcmd("reset") end)
end

-- ---- estilo lofi ----
function lofipal()
 local m={[0]=129,130,133,131,132,141,134,15,142,143,135,139,140,13,14,7}
 for i=0,15 do pal(i,m[i],1) end
end

function header(ti)
 rectfill(0,0,127,8,1)
 print(ti,2,2,9)
 local s=song and ("c"..song.." "..gd(2).." "..notes[gd(4)+1]) or ""
 print(s,96-#s*4,2,6)
 if rec and playing then
  circfill(121,4,2,t()%1<.5 and 8 or 2)
 elseif playing then
  for k=0,4 do line(117+k\2,2+k\2,117+k\2,6-k\2,11) end
 else
  rectfill(117,2,121,6,5)
 end
end

function tabs()
 local x=2
 for i,p in pairs(pages) do
  local s=i==pg
  print(p.n,x,36,s and 7 or 5)
  if (s) line(x,42,x+#p.n*4-2,42,9)
  x+=#p.n*4+5
 end
 if pats>0 then
  rectfill(119,34,127,42,12)
  print(split("a,b,c,d")[ep+1],122,36,0)
 end
end

-- ---- portapapeles ----
function copypat(p)
 clip={}
 for i=0,pats-1 do clip[i]=gd(patb+p*pats+i) end
end
function pastepat(p)
 if (not clip) return
 for i=0,pats-1 do sd(patb+p*pats+i,clip[i]) end
end
function clearpat(p)
 for i=0,pats-1 do sd(patb+p*pats+i,0) end
end

-- guarda (oficial y fake-08)
function savetick()
 fc=(fc or 0)+1
 if dirty and fc%30==0 then
  dset(63,dget(63)) dirty=false
 end
end

function footer(h)
 rectfill(0,120,127,127,1)
 print(h,2,121,5)
end

function cpu(x,y)
 local c=flr(stat(1)*100)
 print("cpu "..c.."%",x,y,c>80 and 8 or 5)
end

function statusline()
 if rec and playing then
  local s=cnt and cnt>0 and tx("conteo...","count-in...") or tx("rec bloque ","rec block ")..(curc+1).."/"..gd(7)
  print(s,64-#s*2,113,8)
 elseif done and done>0 then
  local s=tx("listo: corta la grabacion","done: stop your recorder")
  print(s,64-#s*2,113,10)
 end
end

-- ---- selector de cancion ----
sel=1
function pickupdate()
 if (btnp(2)) sel=(sel-2)%8+1
 if (btnp(3)) sel=sel%8+1
 if (btnp(0)) sel=(sel-2)%8+1
 if (btnp(1)) sel=sel%8+1
 if (btnp(5)) lang=3-lang
 if (btnp(4)) opensong(sel)
end

function pickdraw(ti,su)
 cls(0)
 scene()
 rectfill(0,0,127,8,1)
 print(ti,2,2,9)
 print(su,2,40,6)
 print(tx("elegi la cancion","choose a song"),2,50,7)
 local l=tx("x: english","x: espanol")
 print(l,126-#l*4,50,12)
 for i=1,8 do
  local x,y=4+(i-1)%4*31,62+(i-1)\4*22
  local s=i==sel
  rectfill(x,y,x+27,y+17,s and 4 or 1)
  rect(x,y,x+27,y+17,s and 9 or 2)
  print("c"..i,x+10,y+6,s and 7 or 6)
 end
 footer(tx("o: abrir  misma en los 3 carts","o: open  same song in all 3"))
end

-- ===== swing beats =====
-- bateria por pcm (5512hz) con
-- swing y nudge a nivel muestra
pbit,mbit,patb,pats=0,64,32,20
tn=split("kik,snr,rim,hat,opn")
velg={.35,.65,1}
tunes={.84,.89,.94,1,1.06,1.12,1.19}
function lstr()
 kitn=split(tx("polvo,suave,cinta","dusty,soft,tape"))
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
  local d={64,82,74,56,56,4,6,5,4,4,4,0,5,2,2,140}
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
 local k=split(kits[gd(123)+1])
 local tu=tunes[(gd(127)>>2&7)+1]
 for t=1,5 do
  local o=(t-1)*11
  local q={unpack(k,o+1,o+11)}
  q[2]*=tu q[3]*=tu
  vb[t]=syn(unpack(q))
  vn[t]=q[1]
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
   push(i+lead+(sgd(112+t)+(rnd(2)-1)*gd(117))*5.5125,{h=t+1,v=v})
  end
 end
end

function hit(t,v,i)
 add(uiq,{f=(bl+(i or 0))/91.875,pad=t})
 if pcm then
  vp[t],vg[t]=1,gd(117+t)/7*velg[v]
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

function groovepage()
 local its={
  {x=2,y=46,l="swing",v=function() return gd(3).."%" end,a=function(d) clampset(3,d,50,75) end,w=38},
  {x=46,y=46,l="bpm",v=function() return gd(2) end,a=function(d) clampset(2,d,60,160) end,w=32},
  {x=84,y=46,l="hum",v=function() return gd(117).."ms" end,a=function(d) clampset(117,d,0,15) end,w=40}}
 for t=0,4 do
  add(its,{x=16,y=60+t*10,t=t,d=nudgecell,a=function(d) clampset(112+t,d*2,24,104) end})
  add(its,{x=88,y=60+t*10,t=t,d=lvlcell,a=function(d) clampset(118+t,d,0,7) end})
 end
 return ipage("groove",its,function()
  print("-  nudge ms  +",14,54,5) print(tx("nivel","level"),96,54,5)
  for t=0,4 do print(tn[t+1],1,61+t*10,6) end
 end,tx("o+<>:ajustar  x+<>:pagina","o+<>:adjust  x+<>:page"))
end

function nudgecell(t,s)
 local y,n=t.y,sgd(112+t.t)
 line(16,y+3,60,y+3,1)
 line(38,y,38,y+6,2)
 local x=38+n*.5
 rectfill(min(38,x),y+2,max(38,x),y+4,s and 9 or 13)
 local v=(n>0 and "+" or "")..n
 print(v,80-#v*4,y,s and 7 or 6)
end

function lvlcell(t,s)
 local l=gd(118+t.t)
 for k=0,6 do
  rectfill(88+k*5,t.y+1,91+k*5,t.y+5,k<l and (s and 9 or 13) or 1)
 end
end

function kitpage()
 local function rr(i,lo,hi) return function(d) clampset(i,d,lo,hi) renderall() end end
 local its={
  {x=2,y=48,l="kit",v=function() return kitn[gd(123)+1] end,a=function(d) sd(123,(gd(123)+d)%3) renderall() end,w=56},
  {x=66,y=48,l=tx("afinar","tune"),v=function() return (gd(127)>>2&7)-3 end,a=function(d)
   local f=gd(127) sd(127,f&0xe3|mid(0,6,(f>>2&7)+d)<<2) renderall() end,w=56},
  {x=2,y=60,l=tx("color","tone"),v=function() return gd(124) end,a=rr(124,0,7),w=56},
  {x=66,y=60,l=tx("saturar","drive"),v=function() return gd(125) end,a=rr(125,0,7),w=56},
  {x=2,y=72,l=tx("sala","room"),v=function() return gd(126) end,a=rr(126,0,7),w=56},
  {x=66,y=72,l="crush",v=function() return gd(127)&3 end,a=function(d)
   local f=gd(127) sd(127,f&0xfc|mid(0,3,(f&3)+d)) end,w=56},
  {x=2,y=84,l=tx("motor","engine"),v=function() return pcm and "pcm" or "chip" end,a=function()
   if (pcmok) pcm=not pcm
  end,w=56}}
 for t in all(its) do t.k=function() hit(1,3) hit(4,2) end end
 return ipage("kit",its,function()
  if (not pcmok) print(tx("sin pcm: usa pico-8 oficial","no pcm: use official pico-8"),2,100,8)
  cpu(96,84)
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
