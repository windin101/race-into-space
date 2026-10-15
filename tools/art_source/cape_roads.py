import numpy as np, math, json, sys
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import binary_dilation, gaussian_filter
S=sys.argv[1]+"/"
G=np.asarray(Image.open(__import__('pathlib').Path(__file__).with_name('cape_ground_empty.png')).convert('RGB')).astype(float)
H_,W_=G.shape[:2]
r,gg,b=G[...,0],G[...,1],G[...,2]
sandy=(r>215)&(r-b>18)&(r-gg>5)&(gg>190)
# --- erase original tracks (diagonal from y>=430, the faint horizontal and right branch) ---
yy,xx=np.mgrid[0:H_,0:W_]
diag_x=np.interp(yy,[430,480,520,560,600,640,680,720,760,800,840,880,920,960,1000,1040,1080],[1170,1233,1295,1345,1387,1436,1480,1522,1560,1600,1643,1672,1707,1747,1781,1812,1845])
ed=(sandy|((r>200)&(gg>195)&(r-b>15)))&(yy>=430)&(np.abs(xx-diag_x)<70)
ed=binary_dilation(ed,iterations=4)
hline_y=np.interp(xx,[0,500,1040],[428,410,386]); rb_y=np.interp(xx,[1480,1700,1920],[666,658,650])
eh=((np.abs(yy-hline_y)<5)&(xx<1040)&(r>200))|((np.abs(yy-rb_y)<6)&(xx>1480)&(r>200)&(yy>640))
eh=binary_dilation(eh,iterations=4)
def shift(dx,dy):
    o=np.empty_like(G); xs=np.clip(np.arange(W_)+dx,0,W_-1); ys=np.clip(np.arange(H_)+dy,0,H_-1)
    return G[ys][:,xs]
left=shift(-100,0); right=shift(100,0); below=shift(0,14)
src=np.where((xx<diag_x)[...,None],left,right)
clean=G.copy()
bd=gaussian_filter(ed.astype(float),2.0)[...,None]; clean=clean*(1-bd)+src*bd
bh=gaussian_filter(eh.astype(float),1.5)[...,None]; clean=clean*(1-bh)+below*bh
Image.fromarray(np.clip(clean,0,255).astype(np.uint8)).save(S+"ground_clean.png")
# --- roads ---
def chaikin(p,n=5):
    for _ in range(n):
        q=[p[0]]
        for a,c in zip(p,p[1:]): q+=[(a[0]*.75+c[0]*.25,a[1]*.75+c[1]*.25),(a[0]*.25+c[0]*.75,a[1]*.25+c[1]*.75)]
        q.append(p[-1]); p=q
    return p
def width(y): return 10+15*max(0,min(1,(y-380)/700))
roads=[
 ([(1000,388),(1100,410),(1180,445),(1233,480),(1295,520),(1345,560),(1387,600),(1436,640),(1480,680),(1522,720),(1560,760),(1600,800),(1643,840),(1675,880),(1707,920),(1747,960),(1781,1000),(1812,1040),(1845,1095)],1.0),
 ([(-10,428),(500,410),(1000,388)],0.85),
 ([(1478,667),(1600,661),(1750,655),(1930,650)],0.9),
 ([(522,585),(610,598),(690,625),(750,665),(840,735),(960,815),(1080,900),(1200,985),(1290,1050),(1345,1095)],1.0),
 ([(612,1095),(700,1010),(820,935),(960,860),(1080,800),(1190,735),(1262,705),(1380,682),(1478,667)],1.0),
 ([(1160,628),(1176,650),(1212,690),(1236,712)],0.8),
 ([(186,836),(250,866),(300,895),(400,945),(482,996)],0.9),
 ([(676,622),(612,658),(578,684),(596,703),(626,722)],0.8),
 ([(1252,490),(1290,492)],0.8),
 ([(1426,633),(1478,632)],0.8),
 ([(1604,806),(1662,805)],0.8),
]
A=(0.873,0.488); B=(0.877,-0.479)
def para(P0,lb,la):
    P1=(P0[0]+B[0]*lb,P0[1]+B[1]*lb); P2=(P1[0]+A[0]*la,P1[1]+A[1]*la); P3=(P0[0]+A[0]*la,P0[1]+A[1]*la)
    return [P0,P1,P2,P3]
lots=[para((750,642),110,52),para((1030,600),70,112),para((590,735),56,46),para((42,795),66,182),para((362,1016),78,205)]
runway=[(45.7,185.0),(86.3,182.5),(354.7,398.8),(227.3,406.5)]
K=4; m=Image.new('L',(W_*K,H_*K),0); d=ImageDraw.Draw(m)
for pts,f in roads:
    s=chaikin(pts)
    for p,q in zip(s,s[1:]):
        w=width((p[1]+q[1])/2)*f*K
        d.line([(p[0]*K,p[1]*K),(q[0]*K,q[1]*K)],fill=255,width=max(1,int(w)))
        d.ellipse([q[0]*K-w/2,q[1]*K-w/2,q[0]*K+w/2,q[1]*K+w/2],fill=255)
    p=s[0]; w=width(p[1])*f*K; d.ellipse([p[0]*K-w/2,p[1]*K-w/2,p[0]*K+w/2,p[1]*K+w/2],fill=255)
for q in lots+[runway]: d.polygon([(x*K,y*K) for x,y in q],fill=255)
for cx,cy,rr in ((760,656,11),): d.ellipse([(cx-rr)*K,(cy-rr)*K,(cx+rr)*K,(cy+rr)*K],fill=255)
mask=np.asarray(m.resize((W_,H_),Image.LANCZOS).filter(ImageFilter.GaussianBlur(0.9))).astype(float)
noise=np.asarray(Image.effect_noise((W_,H_),20).convert('L').filter(ImageFilter.GaussianBlur(0.7))).astype(float)-128
SAND=(244,226,199)
rgb=np.dstack([SAND[i]+noise*0.035 for i in range(3)])
Image.fromarray(np.dstack([np.clip(rgb,0,255),mask]).astype(np.uint8),'RGBA').save(S+"sand_roads.png")
# flat background for the game
cl=clean.copy(); al=(mask/255)[...,None]
bg=cl*(1-al)+rgb*al
Image.fromarray(np.clip(bg,0,255).astype(np.uint8)).save(S+"bg_spring.png")
print("ok")
