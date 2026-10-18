-- ===== swing noise =====
-- texturas por pcm: vinilo,
-- cinta, lluvia, fuego, mar,
-- noche. ducking con el bombo
pbit,mbit,patb,pats,ro=0,0,0,0,true
function lstr()
 ln=split(tx("vinilo,cinta,lluvia,fuego,mar,noche","vinyl,tape,rain,fire,sea,night"))
 prn=split(tx("vinilo,cassette,lluvia,tormenta,fogata,playa,noche,sueno","vinyl,cassette,rain,storm,campfire,beach,night,dream"))
end
prs=split("410000,140000,115000,017230,010502,010051,020005,221021",",",false)
lv={}
-- estado del ruido
ca,rum,hy,ry,dpa,dpf,dpp,fy,fca,fb,my,cc,cp,cph=0,0,0,0,0,0,0,0,0,0,0,0,999,0
fph,rph,wph,lpf,dkv,fgn,fgt,ib,tp,tph=0,0,0,0,1,1,1,0,0,0
ckn,ckp,ckf,ia=0,0,0,0

function initpart()
 if gd(255)&128==0 then
  local d={3,2,0,0,0,0,0,2,5,1,2,1,1,5,0,128}
  for i=1,16 do sd(239+i,d[i]) end
 end
end

function preset(k)
 local s=prs[k]
 for i=1,6 do sd(239+i,ord(s,i)-48) end
 sd(246,k-1)
end

-- ---- motor ----
function gen(n)
 for i=1,6 do lv[i]=gd(239+i) end
 local l1,l2,l3,l4,l5,l6=unpack(lv)
 local tc,mv=(gd(248)+1)/8,gd(253)/5
 local pc,pp=l1*.0002,l1*.00001
 for i=0,n-1 do
  if (i>=nxt) service(i)
  local s=0
  -- vinilo: clicks, pops, rumble
  if l1>0 then
   if rnd()<pc then ca=(rnd(25)+12)*sgn(rnd(2)-1)
   elseif rnd()<pp then ca=(rnd(30)+50)*sgn(rnd(2)-1) end
   rum+=(rnd(2)-1-rum)*.02
   s+=ca*l1*.25+rum*l1*8
   ca*=.5
  end
  -- cinta: hiss con flutter
  if l2>0 then
   hy+=(rnd(2)-1-hy)*.3
   s+=hy*l2*4*(1+sin(fph)*.2)
  end
  -- lluvia: ruido brillante y gotas
  if l3>0 then
   local r=rnd(2)-1
   s+=(r-ry)*l3*1.6*(.75+sin(rph)*.25)
   ry=r
   if rnd()<l3*.001 then
    dpa=rnd(8)+4 dpf=(900+rnd(1400))/sr
   end
   dpp+=dpf
   s+=sin(dpp)*dpa
   dpa*=.92
  end
  -- fuego: soplido y chasquidos
  if l4>0 then
   fy+=(rnd(2)-1-fy)*.07
   s+=fy*l4*10*(.6+.4*sin(fph*.37))
   if (rnd()<l4*.0004) fb=flr(rnd(5))+2
   if fb>0 and rnd()<.015 then
    fca=(rnd(40)+20)*sgn(rnd(2)-1) fb-=1
   end
   s+=fca*l4*.3
   fca*=.35
  end
  -- mar: olas lentas
  if l5>0 then
   local w=.55+.35*sin(wph)+.1*sin(wph*2.3)
   my+=(rnd(2)-1-my)*(.03+.3*w)
   s+=my*l5*16*w
  end
  -- noche: grillos
  if l6>0 then
   cc-=1
   if (cc<=0) cc=flr(3800+rnd(3500)) cp=0
   cp+=1
   cph+=.39
   if (cp<420 and cp%140<85) s+=sin(cph)*l6*2.2
  end
  fph+=6/sr rph+=.3/sr wph+=.13/sr
  s*=dkv*fgn
  -- aguja: golpe grave + crujido
  if tp>0 then
   tph+=55/sr
   s+=sin(tph)*tp*60
   tp*=.997
   if (tp<.01) tp=0
  end
  if ib>0 then
   if (rnd()<.01) ia=(rnd(30)+15)*sgn(rnd(2)-1)
   s+=ia ia*=.5 ib-=1
  end
  if ckn>0 then
   ckp+=ckf s+=sin(ckp)*70 ckn-=1
  end
  dkv+=(1-dkv)*.0015
  fgn+=(fgt-fgn)*.0004
  lpf+=(s-lpf)*tc
  poke(0x4300+i,128+mid(-127,127,lpf*mv))
 end
 if (wph>1000) wph-=1000 fph-=1000 rph-=1000
end

-- ---- secuencia ----
function bars()
 local tb,cb=0,0
 for j=0,gd(7)-1 do
  local r=1<<(gd(16+j)>>4&3)
  if (j<ci) cb+=r
  tb+=r
 end
 return cb+rep,tb
end

function trig(i,p,s)
 -- ducking con el bombo de beats
 local e=gd(16+ci)
 if gd(247)>0 and (mode==0 or e&64==0) and fg(32+p*20,s,2)>0 then
  push(i+lead+max(-lead,boff(0,s)),{dk=1})
 end
 local f=1
 if mode==1 then
  local b,tb=bars()
  local pos=b+s/16
  local fi,fo=gd(249),gd(250)
  if (fi>0) f=min(f,pos/fi)
  if (fo>0) f=min(f,(tb-pos)/fo)
  if (b==0 and s==0 and gd(251)>0) push(i+lead,{nd=1})
 end
 fgt=mid(0,1,f)
end

function fire(e)
 if e.ck then ckn,ckf=120,(e.a and 2200 or 1600)/sr
 elseif e.dk then dkv=1-gd(247)*.09
 elseif e.nd then ib=900 tp=1 tph=0
 end
end

function onstart() fgt=0 fgn=0 er=false end
-- tras grabar queda en silencio
-- hasta tocar algo
function onstop() fgt=er and 0 or 1 end
function onend()
 if (gd(252)>0) ib=1200 tp=.6 tph=0
 fgt=0 er=true
end
function onstep() end

-- ---- paginas ----
function scenepage()
 local its={{x=2,y=46,l="preset",v=function() return prn[gd(246)+1] end,
  a=function(d) preset((gd(246)+d)%8+1) end,
  k=function() preset(gd(246)+1) end,w=70}}
 for i=1,6 do
  add(its,{x=40,y=50+i*9,i=i,d=function(t,s)
   print(ln[t.i],2,t.y,s and 7 or 6)
   local l=gd(239+t.i)
   for k=0,6 do
    rectfill(40+k*7,t.y,45+k*7,t.y+4,k<l and (s and 9 or 13) or 1)
   end
   print(l,94,t.y,s and 9 or 5)
  end,a=function(d) clampset(239+i,d,0,7) end})
 end
 return ipage(tx("escena","scene"),its,function()
  if (pcmok==false) print(tx("sin pcm: usa pico-8 oficial","no pcm: use official pico-8"),2,113,8)
 end,tx("o+<>:ajustar  o:preset","o+<>:adjust  o:preset"))
end

function fxpage()
 local function it(x,y,l,i,lo,hi,nm)
  return {x=x,y=y,l=l,w=58,v=function() local v=gd(i) return nm and nm[v+1] or v end,a=function(d) clampset(i,d,lo,hi) end}
 end
 local ag=split(tx("nada,aguja","none,needle"))
 return ipage("fx",{
  it(2,48,"duck",247,0,7),it(66,48,tx("tono","tone"),248,0,7),
  it(2,60,"fade in",249,0,4),it(66,60,"fade out",250,0,4),
  it(2,72,"intro",251,0,1,ag),it(66,72,tx("final","outro"),252,0,1,ag),
  it(2,84,tx("nivel","level"),253,1,7)},function()
  print(tx("duck: baja con cada bombo","duck: dips on every kick"),2,96,5)
  print(tx("fades en compases (modo cadena)","fades in bars (song mode)"),2,103,5)
  cpu(96,84)
 end,tx("o+<>:ajustar","o+<>:adjust"))
end

-- ---- escena: ventana ----
function scene()
 rectfill(0,9,127,33,0)
 fillp(0b1010010110100101.1)
 rectfill(0,9,127,33,1)
 fillp()
 local l={}
 for i=1,6 do l[i]=gd(239+i) end
 local tt=t()
 -- ventana con ciudad
 rectfill(30,10,98,33,4)
 rectfill(32,12,96,31,0)
 for i=0,7 do
  local x,h=32+i*8,4+i*5%7
  rectfill(x,31-h,x+6,31,1)
  if ((i+flr(tt/3))%3==0) pset(x+2,32-h+2,10)
 end
 if l[6]>0 then
  for i=0,7 do
   pset(34+i*29%61,13+i*17%9,(tt*3+i)%4<1 and 7 or 6)
  end
  circfill(88,16,3,10) circfill(86,15,3,0)
 end
 if l[5]>0 then
  for x=32,96 do
   pset(x,28+sin(x/24+tt*.2)*l[5]*.3,12)
   pset(x,30+sin(x/17-tt*.15)*l[5]*.2,3)
  end
 end
 if l[3]>0 then
  for i=1,l[3]*4 do
   local x,y=32+(i*37)%64,12+(i*13+tt*60)%19
   line(x,y,x-1,y+2,13)
  end
 end
 line(64,10,64,33,4) line(30,22,98,22,4)
 -- cassette y fuego
 rectfill(4,11,25,18,l[2]>0 and 2 or 1)
 for c in all({10,19}) do circ(c,14,2,l[2]>0 and 6 or 5) end
 if l[4]>0 then
  for i=0,l[4] do
   local fx=8+i*13%11
   circfill(fx,30-rnd(l[4]),1+rnd(2),({8,9,10})[flr(rnd(3))+1])
  end
 end
 rectfill(3,31,27,32,4)
 -- vinilo
 circfill(114,21,9,l[1]>0 and 0 or 1)
 circ(114,21,6,2)
 circfill(114,21,2,9)
 local a=l[1]>0 and tt*.55 or 0
 line(114,21,114+cos(a)*8,21+sin(a)*8,5)
 -- grillos
 if l[6]>0 and cp<420 then pset(40+cc%50,32,11) end
end

-- ---- principal ----
function _init()
 lofipal()
 pcminit()
end
function mkpages()
 pages={scenepage(),fxpage(),songpage()}
 pg=1
end

function _update60()
 pcmcheck()
 if not song then
  pickupdate()
  return
 end
 if pcmok then
  local n=pcmneed(1024)
  if n>0 then
   bl=stat(108)
   gen(n)
   serial(0x808,0x4300,n)
   shift(n)
  end
 end
 if (not playing and btn()>0) fgt=1 er=false
 inp()
 uitick()
 savetick()
end

function _draw()
 if not song then
  pickdraw("swing noise",tx("texturas y ambiente","textures and ambience"))
  return
 end
 cls(0)
 header("swing noise")
 scene()
 tabs()
 pages[pg].draw()
 statusline()
 footer(pages[pg].h)
end
