-- ===== nucleo comun swing =====
-- la cancion vive en cartdata
-- (256 bytes en 0x5e00). mapa:
-- 0 magia 1 version 2 bpm
-- 3 swing 4 tono 5 escala
-- 6 semilla 7 largo 8 click
-- (0 no, 1 conteo al grabar,
-- 2 conteo + metronomo)
-- 16-31 cadena (arreglo)
-- 32-127 beats 128-239 keys
-- 9 groove 10 deriva 11-12 flam
-- 13 base swing (0=16, 1=8)
-- 1: b0 version, b1-2 relleno,
-- b3-5 pista poli, b6-7 grilla poli
-- 12 b2-7 y 13 b2-5: recorte de
-- inicio por pista (2 bits)
-- 240-255 noise
dd=0x5e00
sr=5512.5
-- anticipacion ~100ms: deja
-- adelantar golpes (snare dilla)
lead=551
notes=split("c,c#,d,d#,e,f,f#,g,g#,a,a#,b")
-- idioma: 1 espanol, 2 english
-- (x en el selector lo cambia)
lang=1
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

-- relleno de beats (byte 1 bits 1-2:
-- 1 hat, 2 caja, 3 ambos) en el
-- ultimo compas de un bloque x2+
function fillv(t,s,v)
 local f=gd(1)>>1&3
 if mode==1 and f>0 and rep>0 and rep==(1<<(gd(16+ci)>>4&3))-1 then
  if (f&1>0 and t==4 and s==15) v=max(v,2)
  if (f&2>0 and t==1 and s>11) v=max(v,({1,1,2,3})[s-11])
 end
 return v
end

-- recorte de inicio de la pista t
-- (0-3, x3 ms): salta el comienzo
function trim(t)
 return t<3 and fg(11,5+t,2) or fg(13,t-2,2)
end
function settrim(t,v)
 if t<3 then fs(11,5+t,2,v) else fs(13,t-2,2,v) end
end

-- eventos de bateria del paso s del
-- patron bp. una pista (poli) corre
-- en su grilla de n celdas por compas
polyn={12,10,14,8}
function drum(i,s,bp)
 local pt,n=(gd(1)>>3&7)-1,polyn[gd(1)\64+1]
 for t=0,4 do
  local ly=t==pt
  for k=ly and 0 or s,ly and n-1 or s do
   local q=ly and k*16/n or s
   if flr(q)==s then
    local v=fg(32+bp*20,t*16+k,2)
    if (not ly) v=fillv(t,s,v)
    if v>0 then
     local o=i+lead+max(-lead,(ly and (q-s)*steplen()+sgd(112+t)*5.5125 or boff(t,s))+hum(t,k))
     local f=fg(11,t,2)*55.125
     if (f>0 and v>1) push(max(i,o-f),{h=t+1,v=1})
     push(o,{h=t+1,v=v})
    end
   end
  end
 end
end

-- ---- kits de bateria ----
-- por pista: largo,f0,f1,caida
-- tono,caida amp,tono,ruido,
-- caida ruido,filtro,brillo,click
velg={.35,.65,1}
tunes={.84,.89,.94,1,1.06,1.12,1.19}
kits={
"1500,160,50,90,700,1,.08,80,.5,0,.4,1300,230,185,200,250,.45,.85,500,.6,.3,0,400,900,750,100,70,.6,.35,60,1,1,0,300,0,0,1,1,0,.7,60,1,1,0,1500,0,0,1,1,0,.6,500,.9,1,0",
"1800,120,44,140,1000,1,.04,60,.3,0,.15,1100,210,180,300,320,.7,.45,380,.35,.1,0,350,700,650,120,90,.8,.2,50,.7,.6,0,260,0,0,1,1,0,.5,50,.6,1,0,1400,0,0,1,1,0,.45,420,.6,1,0",
"1200,190,58,60,450,1,.15,60,.7,0,.6,1000,250,190,150,200,.35,1,420,.9,.5,.2,300,1300,1100,80,50,.5,.5,40,1,1,.2,260,0,0,1,1,0,.9,45,1,1,.1,1300,0,0,1,1,0,.8,450,1,1,0",
"1700,200,58,70,900,1,.12,60,.5,0,.7,1500,260,200,180,300,.5,1,600,.7,.25,.2,350,1100,900,80,60,.7,.3,50,1,1,0,260,0,0,1,1,0,.8,45,1,1,0,1300,0,0,1,1,0,.7,420,.9,1,0"}

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
bn,hh=0,{}

-- rejilla recta; el swing va
-- como offset de cada evento
function steplen() return sr/gd(2)*15 end

-- offset de swing en el paso s
-- base 16: corre semicorcheas
-- impares. base 8: corre la
-- corchea debil (0,k,2k,k)
function swo(w,s)
 local k,q=(w-50)/50*steplen(),s%4
 if gd(13)&1>0 then
  return (q==2 and 2 or q%2)*k
 end
 return s%2*k
end

-- groove templates: 5 pistas x
-- 16 pasos, offset en 1/48 de
-- paso (char-64). escala con bpm
grv={
"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@",
"@@@@@@@@@@@@@@@@@@@@<@@@@@@@<@@@@@@@@@@@@@@@@@@@@@C@@@@@@@C@@@@@@@@@@@@@@@@@@@@@",
"@@@@@@@@@@@@@@@@@@@@4@@@@@@@4@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@",
"@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@",
"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS",
"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@",
"@@@@@@@@@@@@@@@@4444444444444444@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@",
"@F@F@F@F@F@F@F@F::::::::::::::::@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"}

-- swing de la pista t de beats
-- (0 en bits 3-7 = el global)
-- mas la deriva por compas
function bsw(t)
 local w=gd(118+t)\8
 w=w>0 and w+49 or gd(3)
 if (w>50) w+=gd(10)*(bn%4)
 return w
end

-- offset fijo de la pista t de
-- beats en el paso s (muestras)
function boff(t,s)
 return swo(bsw(t),s)+(ord(grv[gd(9)+1],t*16+s+1)-64)/48*steplen()+sgd(112+t)*5.5125
end

-- humanizacion (muestras). modos:
-- 0 libre: ruido blanco
-- 1 deriva: ar(1) correlacionado
-- 2 fijo: igual en cada compas
function hum(k,s)
 local a,g=gd(117)&15,rnd(2)-1
 local md=gd(117)\16
 if md==1 then
  g=mid(-1,1,(hh[k] or 0)*.85+g*.53) hh[k]=g
 elseif md==2 then
  g=(s*37+k*91+gd(6))*.618034%1*2-1
 end
 return g*a*5.5125
end

function startplay(r)
 rec=r playing=true seqon=true
 srand(gd(6)) bn=0 hh={}
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
 -- click 2: metronomo al tocar
 -- (nunca en la grabacion)
 if (gd(8)>1 and not rec and st%4==0) push(i+lead,{ck=1,a=st==0})
 push(i+lead,{m=st,p=pp,c2=ci})
 if (not mt) trig(i,pp,st)
 st+=1
 if st==16 then
  st=0 bn+=1
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
  -- x+o: duplicar (patron o bloque)
  if o and not po then
   xu=true ou=true
   if (p.dup) p.dup()
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
 -- navegacion por filas: izq/der al
 -- vecino de la misma fila; arriba/
 -- abajo a la fila contigua, al item
 -- mas cerca de la columna que traias
 p.mv=function(dx,dy)
  local c=its[p.ic]
  local function mx(t) return t.x+(t.w or 13)/2 end
  p.cx=p.cx or mx(c)
  local b,bs=nil,999
  if dx~=0 then
   for i,t in pairs(its) do
    local d=abs(t.x-c.x)
    if (t.y==c.y and (t.x-c.x)*dx>0 and d<bs) b,bs=i,d
   end
   if b then p.ic=b p.cx=mx(its[b]) end
  else
   local ty
   for i,t in pairs(its) do
    local d=(t.y-c.y)*dy
    if (d>0 and d<bs) ty,bs=t.y,d
   end
   if ty then
    bs=999
    for i,t in pairs(its) do
     local d=abs(mx(t)-p.cx)
     if (t.y==ty and d<bs) b,bs=i,d
    end
    p.ic=b
   end
  end
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
  {x=46,y=56,l="click",v=function() return split("no,rec,met")[gd(8)+1] end,a=function(d) sd(8,(gd(8)+d)%3) end,w=36},
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
 if fills then
  add(its,{x=2,y=64,l=tx("relleno","fill"),w=52,
   v=function() return split(tx("no,hat,caja,ambos","none,hat,snare,both"))[(gd(1)>>1&3)+1] end,
   a=function(d) sd(1,gd(1)&0xf9|(((gd(1)>>1&3)+d)%4)<<1) end})
  add(its,{x=58,y=64,l="poly",w=34,
   v=function()
    local t=gd(1)>>3&7
    return t>0 and split("k,s,r,h,o")[t].." "..polyn[gd(1)\64+1] or "--"
   end,
   a=function(_,dx,dy)
    local f=gd(1)
    if (dx~=0) f=f&0xc7|(((f>>3&7)+dx)%6)<<3
    if (dy~=0) f=f&0x3f|mid(0,3,f\64+dy)<<6
    sd(1,f)
   end})
 end
 if refd then
  add(its,{x=2,y=64,l=tx("ref bat","ref drm"),w=60,
   v=function() return gd(239)&64>0 and tx("si","on") or "no" end,
   a=function() sd(239,gd(239)^^64) end})
 end
 -- botones de los textos de ayuda
 add(its,{x=96,y=64,l="btn",w=30,
  v=function() return split("a/b,b/a,o/x")[gd(13)\64+1] end,
  a=function(d) sd(13,gd(13)&0x3f|((gd(13)\64+d)%3)<<6) end})
 -- diagnostico: estado del pcm
 local function dg()
  print("pcm "..(pcmok and "ok" or "no").." "..stat(108)..(clkr and " clk "..flr(clkr*100) or ""),2,113,5)
 end
 local p=ipage(tx("cancion","song"),its,dg,ro and tx("arreglo: se edita en beats/keys","arrangement: edit in beats/keys") or tx("o:patron o+^v:x2 x+o:copia","o:pattern o+^v:x2 x+o:copy"))
 -- x+o sobre un bloque: inserta una copia
 -- a continuacion (corre el resto)
 p.dup=function()
  local i=its[p.ic].i
  if ro or not i or i>14 then return end
  for j=15,i+2,-1 do sd(16+j,gd(15+j)) end
  sd(17+i,gd(16+i))
  if (i<gd(7)) sd(7,min(16,gd(7)+1))
  p.ic+=1 p.cx=nil
  say(tx("bloque copiado","block copied"))
 end
 return p
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

-- duplica el patron actual en la letra
-- siguiente si esta vacia y va ahi
function duppat()
 local n=(ep+1)%4
 local e=true
 for i=0,pats-1 do
  if (gd(patb+n*pats+i)>0) e=false
 end
 local l=split("a,b,c,d")[n+1]
 if e then
  for i=0,pats-1 do sd(patb+n*pats+i,gd(patb+ep*pats+i)) end
  say(tx("copiado a ","copied to ")..l)
 else say(l..tx(" no esta vacio"," is not empty")) end
 ep=n
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

-- nombres de botones en los textos de
-- ayuda (byte 13 bits 6-7): 0 a/b,
-- 1 b/a, 2 o/x (nombres de pico-8)
function lbl(h)
 local m=({{"a","b"},{"b","a"},{"o","x"}})[gd(13)\64+1]
 local r=""
 for i=1,#h do
  local c,p,n=sub(h,i,i),sub(h,i-1,i-1),sub(h,i+1,i+1)
  if (c=="o" or c=="x") and (i==1 or p==" " or p=="+") and (n==":" or n=="+" or n==" ") then
   c=m[c=="o" and 1 or 2]
  end
  r..=c
 end
 return r
end

function footer(h)
 rectfill(0,120,127,127,1)
 print(lbl(h),1,121,5)
end

function cpu(x,y)
 local c=flr(stat(1)*100)
 print("cpu "..c.."%",x,y,c>80 and 8 or 5)
end

function say(m) msg,msgt=m,70 end
function statusline()
 if msgt and msgt>0 then
  msgt-=1
  print(msg,64-#msg*2,113,12)
 elseif rec and playing then
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
 local l=lbl(tx("x: english","x: espanol"))
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
