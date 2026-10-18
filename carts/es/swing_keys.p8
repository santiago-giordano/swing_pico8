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

-- ===== swing keys =====
-- bajo, lead y acordes por grados
-- de la escala de la cancion
pbit,mbit,patb,pats=2,128,128,24
function lstr()
 rn=split(tx("baj,led,aco","bas,led,chd"))
 wn=split(tx("tri,sier,sie2,cuad,puls,orga,fase","tri,saw,saw2,sqr,puls,orgn,phas"))
end
wid={0,1,2,3,4,5,7}
defk={
"1010000500000000708000004040000800000f0000500000",
"7070000300000000200000003030000000000100002f0000"}
last={1,5,1}
lit={}
kx,ky=0,0

function initpart()
 if gd(239)&128==0 then
  for p=1,2 do
   local s=defk[p]
   for k=0,47 do
    fs(128+(p-1)*24,k,4,tonum("0x"..sub(s,k+1,k+1)))
   end
  end
  local d={0,0,6,4,70, 0,2,4,66,64, 5,2,3,25,74, 133}
  for i=1,16 do sd(223+i,d[i]) end
 end
end

-- ---- parametros ----
function kp(r,j) return gd(224+r*5+j) end
function kfx(r,b,w) return kp(r,3)>>b&(1<<w)-1 end

-- grado (1-14) a pitch
function deg(d,o)
 local s=scl[gd(5)+1]
 local p=gd(4)+12*o+s[(d-1)%7+1]+12*((d-1)\7)
 while (p>63) p-=12
 return p
end

-- nombre del acorde sobre grado c
function cname(c)
 local s=scl[gd(5)+1]
 local function iv(k) return (s[(c+k-1)%7+1]-s[c])%12 end
 local q=({["4711"]="maj7",["3710"]="m7",["4710"]="7",["3610"]="m7b5"})[iv(2)..iv(4)..iv(6)] or ""
 return notes[(gd(4)+s[c])%12+1]..q
end

-- ---- escritura de sfx ----
function wnote(sl,i,p,w,v,f)
 local a,x=0x3200+sl*68+i*2-2,p+w*64+v*512+(f or 0)*4096
 poke(a,x%256,x\256)
end

-- arma el sonido de la pista r
-- en el slot sl. modo: 0 nota,
-- 1 release
function wsfx(sl,r,p,rel)
 local w,lv=wid[kp(r,0)+1],kp(r,2)
 local fx=kfx(r,6,1)*2
 local sp,l0,l1=4,0,0
 local e=0
 for i=1,32 do
  local v=0
  if rel then
   v=max(0,lv-i+1)
  elseif r==0 then
   sp=3
   v=i<=10 and lv or max(0,lv-(i-10)\3)
  elseif r==1 then
   local ec=gd(239)&3
   if ec>0 then
    sp=max(1,flr(45/gd(2)*120/11))
    e=flr(45/gd(2)*120/sp+.5)
   end
   if i<=8 then v=max(0,lv-(i-1)\2)
   elseif e>0 and i>e and i<=e+4 then v=max(1,lv\2-(i-e-1)\2)
   elseif ec>1 and e>0 and i>2*e and i<=2*e+3 then v=max(1,lv\4)
   end
  else
   v=gd(239)&4>0 and min(lv,i) or lv
   l0,l1=8,16
  end
  wnote(sl,i,p,w,v,v>0 and fx or 0)
 end
 local f=kfx(r,4,2)*8+kfx(r,0,2)*24+kfx(r,2,2)*72
 poke(0x3200+sl*68+64,f,sp,l0,l1)
end

-- ---- notas ----
function chordp(c)
 local o=kp(2,1)
 local lo=gd(4)+12*o+3
 local p3,p7=deg(c+2,o),deg(c+6,o)
 while (p3<lo) p3+=12
 while (p3>=lo+12) p3-=12
 while (p7<lo) p7+=12
 while (p7>=lo+12) p7-=12
 return p3,p7
end

function play(r,v)
 if v==15 then
  for k=r,r+tonum(r==2) do
   if (pl[k]) wsfx(k,r,pl[k],true) sfx(k,k)
  end
  lit[r]=nil
  return
 end
 if r<2 then
  local p=deg(v,kp(r,1))
  wsfx(r,r,p) sfx(r,r)
  pl[r]=p lit[r]={p}
 else
  local a,b=chordp(v)
  wsfx(2,2,a) wsfx(3,2,b)
  sfx(2,2) sfx(3,3)
  pl[2],pl[3]=a,b
  lit[2]={a,b,deg(v,kp(2,1)-1)}
  chord=cname(v)
 end
end
pl={}

-- ---- secuencia ----
function trig(i,p,s)
 for r=0,2 do
  local v=fg(128+p*24,s*3+r,4)
  if v>0 then
   push(i+lead+(sgd(228+r*5)+(rnd(2)-1)*gd(117))*5.5125,{r=r,v=v})
  end
 end
end

function fire(e)
 if e.ck then
  for i=1,32 do wnote(4,i,i<3 and (e.a and 46 or 41) or 0,4,i<3 and 5 or 0) end
  poke(0x3200+4*68+64,0,2,0,0)
  sfx(4,3)
 else play(e.r,e.v) end
end

function onstart() end
function onstop()
 for k=0,3 do sfx(-1,k) end
 lit={}
end
function onend() play(2,15) play(0,15) play(1,15) end
function onstep() end

-- ---- paginas ----
function cellch(r,v)
 if (v==15) return "x"
 if (r==2) return v
 return (v-1)%7+1
end

function gridpage()
 local p={n=tx("patron","pattern"),h=tx("o:nota o+^v:grado o+<>:rota","o:note o+^v:degree o+<>:rotate")}
 p.mv=function(dx,dy) kx=(kx+dx)%16 ky=mid(0,2,ky+dy) end
 local function at() return 128+ep*24,kx*3+ky end
 p.act=function()
  local b,k=at()
  local v=fg(b,k,4)
  if v==0 then
   v=last[ky+1] play(ky,v)
  else
   last[ky+1]=v v=0
  end
  fs(b,k,4,v)
 end
 p.adj=function(dx,dy)
  local b,k=at()
  if dy~=0 then
   local v,mx=fg(b,k,4),ky==2 and 7 or 14
   if (v==15) v=mx+1
   v=mid(1,mx+1,v+dy)
   if (v>mx) v=15
   fs(b,k,4,v) last[ky+1]=v play(ky,v)
  end
  if dx~=0 then
   local q={}
   for s=0,15 do q[s]=fg(b,s*3+ky,4) end
   for s=0,15 do fs(b,s*3+ky,4,q[(s-dx)%16]) end
  end
 end
 p.draw=function()
  local b,cc=128+ep*24,{12,9,14}
  for r=0,2 do
   local y=47+r*14
   print(rn[r+1],1,y+4,ky==r and 7 or 6)
   for s=0,15 do
    local x,v=14+s*7,fg(b,s*3+r,4)
    local c=s%4==0 and 2 or 1
    if v>0 then
     c=v==15 and 5 or cc[r+1]
     if (r<2 and v>7 and v<15) c=r==0 and 3 or 10
    end
    rectfill(x,y,x+5,y+11,c)
    if (v>0) print(cellch(r,v),x+1,y+4,0)
   end
  end
  rect(13+kx*7,46+ky*14,20+kx*7,59+ky*14,7)
  if playing and cur>=0 and curp==ep then
   rectfill(14+cur*7,90,19+cur*7,91,11)
  end
  local v=fg(b,kx*3+ky,4)
  local s="-"
  if v==15 then s=tx("corte","cut")
  elseif v>0 then
   if ky==2 then s=tx("acorde ","chord ")..cname(v)
   else
    local pp=deg(v,kp(ky,1))
    s=tx("grado ","degree ")..v.." = "..notes[pp%12+1]..(pp\12+2)
   end
  end
  print(s,2,95,6)
  print(sub(scn[gd(5)+1],1,6),102,95,12)
  if (chord and playing) print(tx("suena ","playing ")..chord,2,103,13)
 end
 return p
end

function soundpage()
 local its={}
 local rows=split(tx("onda,octava,nivel,reverb,filtro,detune,wobble,nudge,eco/at","wave,octave,level,reverb,filter,detune,wobble,nudge,echo/at"))
 for r=0,2 do
  local x=44+r*28
  local function fxi(b,w,mx)
   return {v=function() return kfx(r,b,w) end,a=function(d)
    local f=kp(r,3)
    local v=mid(0,mx,(f>>b&(1<<w)-1)+d)
    sd(227+r*5,f&~((1<<w)-1<<b)|v<<b) end}
  end
  local def={
   {v=function() return wn[kp(r,0)+1] end,a=function(d) sd(224+r*5,(kp(r,0)+d)%7) end},
   {v=function() return kp(r,1) end,a=function(d) clampset(225+r*5,d,0,3) end},
   {v=function() return kp(r,2) end,a=function(d) clampset(226+r*5,d,1,7) end},
   fxi(0,2,2),fxi(2,2,2),fxi(4,2,2),fxi(6,1,1),
   {v=function() return sgd(228+r*5) end,a=function(d) clampset(228+r*5,d*2,24,104) end}}
  if (r==1) add(def,{v=function() return gd(239)&3 end,a=function(d) local f=gd(239) sd(239,f&0xfc|mid(0,2,(f&3)+d)) end})
  if (r==2) add(def,{v=function() return gd(239)&4>0 and tx("len","slow") or tx("rap","fast") end,a=function() sd(239,gd(239)^^4) end})
  for j,t in pairs(def) do
   t.x,t.y,t.d,t.r=x,53+(j-1)*7,soundcell,r
   t.k=function() play(r,r==2 and 1 or 5) end
   add(its,t)
  end
 end
 return ipage(tx("sonido","sound"),its,function()
  for j=1,#rows do print(rows[j],2,53+(j-1)*7,5) end
 end,tx("o:escuchar  o+<>:ajustar","o:listen  o+<>:adjust"))
end

function soundcell(t,s)
 if (t.y==53) print(rn[t.r+1],t.x+8,46,s and 9 or 13)
 local v=tostr(t.v())
 if (s) rectfill(t.x,t.y-1,t.x+25,t.y+5,4)
 print(v,t.x+13-#v*2,t.y,s and 7 or 6)
end

-- ---- escena: teclado ----
function scene()
 rectfill(0,9,127,33,0)
 fillp(0b1010010110100101.1)
 rectfill(0,9,127,33,1)
 fillp()
 local hl={}
 local cc={12,9,14}
 for r=0,2 do
  if lit[r] then
   for p in all(lit[r]) do hl[p%24]=cc[r+1] end
  end
 end
 local wk={0,2,4,5,7,9,11}
 rectfill(3,11,102,32,4)
 for i=0,13 do
  local p=wk[i%7+1]+i\7*12
  local x=4+i*7
  rectfill(x,12,x+5,31,hl[p] or 7)
 end
 for i=0,13 do
  local n=i%7
  if n~=2 and n~=6 then
   local p=wk[n+1]+1+i\7*12
   local x=8+i*7
   rectfill(x,12,x+3,23,hl[p] or 0)
  end
 end
 -- cassette
 rectfill(106,14,125,30,2)
 rectfill(108,16,123,24,0)
 local a=playing and t() or 0
 for c in all({111,120}) do
  circfill(c,20,3,6)
  pset(c+cos(a)*2,20+sin(a)*2,0)
 end
 rectfill(110,26,121,28,1)
end

-- ---- principal ----
function _init()
 lofipal()
 pcminit()
end
function mkpages()
 pages={gridpage(),soundpage(),songpage()}
 pg=1
end

function _update60()
 pcmcheck()
 if not song then
  pickupdate()
  return
 end
 local n=91.875
 if pcmok then
  n=pcmneed(768)
  memset(0x4300,128,n)
  if (n>0) serial(0x808,0x4300,n)
 end
 if (playing) advance(n)
 inp()
 uitick()
 savetick()
end

function _draw()
 if not song then
  pickdraw("swing keys",tx("bajo, lead y acordes","bass, lead and chords"))
  return
 end
 cls(0)
 header("swing keys")
 scene()
 tabs()
 pages[pg].draw()
 statusline()
 footer(pages[pg].h)
end
