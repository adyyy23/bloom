"""Original Bloom human sculpt. CC0-1.0. Rebuild: numpy scipy scikit-image trimesh fast-simplification.
Implicit smooth union produces a connected anatomical skin surface, not a stack of parts.
Coordinates in centimetres; +Z is front. Clothing is a fitted surface material.
"""
from pathlib import Path
import json, math, gzip
import numpy as np
from skimage.measure import marching_cubes
import trimesh
ROOT=Path(__file__).resolve().parents[1]
step=.55
origin=np.array([-43.,-3.,-21.])
x,y,z=np.meshgrid(np.arange(-43,44,step),np.arange(-3,185,step),np.arange(-21,26,step),indexing='ij')
field=np.full(x.shape,100.,dtype=np.float32)
def ell(c,r,k=1.2):
 global field
 d=(np.sqrt(((x-c[0])/r[0])**2+((y-c[1])/r[1])**2+((z-c[2])/r[2])**2)-1)*min(r)
 h=np.maximum(k-np.abs(field-d),0)/k
 field=np.minimum(field,d)-h*h*k*.25
# Spine volumes, pelvis, softly shaped waist, clavicle and neck.
for c,r in [((0,91,-.8),(15,15,10)),((0,107,0),(12,18,8)),((0,125,0),(16,16,9)),((0,136,-.8),(19,7,8)),((0,146,0),(5.7,12,5.7)),((0,164,0),(10.7,14,9)),((0,156,3),(8,7,7))]:ell(c,r,2)
# Coherent cheeks, nose bridge, tip, chin and ears.
for c,r in [((0,162,8.8),(1.9,4,2)),((0,159.8,10),(2.3,1.7,2)),((0,153,5),(5.2,3,4)),((-5.7,159,5.4),(3.6,4,2.8)),((5.7,159,5.4),(3.6,4,2.8)),((-10.3,163,0),(2,3.5,2)),((10.3,163,0),(2,3.5,2))]:ell(c,r,.8)
for s in [-1,1]:
 # Relaxed arms and wrists, joined to shoulders. Legs have knee and calf taper.
 for c,r in [((s*19,132,0),(6.7,9,6.5)),((s*23,121,.1),(5.1,14,5)),((s*26,107,.6),(4.2,5,4)),((s*28,96,1),(4,12,3.7)),((s*30,84,1),(2.6,6,2.5)),((s*30.5,78,1.5),(3.3,5,2)),((s*8.8,74,0),(8.4,23,8)),((s*9.4,54,.4),(5.0,7,4.8)),((s*9.2,39,-1),(5.6,18,5.5)),((s*9.2,17,0),(3.1,10,3)),((s*9.2,5,4),(4.2,4.6,9))]:ell(c,r,1.5)
 # Four individual fingers with webbing at palm and a bent opposing thumb.
 for j,ln in enumerate([6.3,7.4,6.8,5.3]):
  ell((s*(28.4+j*1.55),73-ln*.30,1.5),(0.65,ln*.58,.85),.55)
 ell((s*27.5,76,3),(1.3,3.3,1.5),.6)
v,f,_,_=marching_cubes(field,0,spacing=(step,)*3,gradient_direction='ascent')
v+=origin
body=trimesh.Trimesh(v,f,process=True)
body=body.simplify_quadric_decimation(face_count=11000)
body.fix_normals()
# Subdivide crossing triangles at exact garment planes without moving the surface.
polys=[list(t) for t in body.triangles]
for axis,cuts in [(1,[11,15,61,70,104,108,139]),(0,[-26,-19,-18,18,19,26])]:
 for cut in cuts:
  out=[]
  for poly in polys:
   if min(p[axis] for p in poly)>=cut or max(p[axis] for p in poly)<=cut:
    out.append(poly);continue
   sides=[[],[]]
   for i,p in enumerate(poly):
    q=poly[(i+1)%len(poly)]
    if abs(p[axis]-cut)<1e-8:
     sides[0].append(p);sides[1].append(p)
    else:sides[int(p[axis]>cut)].append(p)
    if (p[axis]-cut)*(q[axis]-cut)<0:
     v=p+(q-p)*(cut-p[axis])/(q[axis]-p[axis])
     sides[0].append(v);sides[1].append(v)
   out.extend(s for s in sides if len(s)>=3)
  polys=out
verts=[];faces=[]
for poly in polys:
 for i in range(1,len(poly)-1):
  off=len(verts);verts.extend([poly[0],poly[i],poly[i+1]]);faces.append([off,off+1,off+2])
body=trimesh.Trimesh(np.round(verts,5),faces,process=True)
body.update_faces(body.nondegenerate_faces())
body.update_faces(body.unique_faces())
body.remove_unreferenced_vertices()
trimesh.repair.fill_holes(body)
body.fix_normals()
print('Body:',len(body.vertices),len(body.faces),'watertight',body.is_watertight,'components',len(body.split()))
# Separate intentionally attached detail meshes: eye whites, iris, lids, lips, shoes.
def uv(c,r,mat,count=(10,12)):
 m=trimesh.creation.uv_sphere(radius=1,count=count);m.vertices*=r;m.vertices+=c
 return m,mat
parts=[(body,0)]
for s in [-1,1]:
 parts.extend([uv((s*4.25,164,8.05),(2.25,1.65,1.4),7),uv((s*4.25,164,9.30),(1.03,1.13,.28),8),uv((s*4.25,164,9.56),(.50,.65,.16),6),uv((s*4.02,164.4,9.70),(.24,.26,.10),7),uv((s*4.3,167,8.1),(2.3,.42,.65),1),uv((s*9.2,5.3,4),(5.25,6.0,10.6),5),uv((s*9.2,.4,4),(5.4,1.2,10.9),4)])
parts.extend([uv((0,155.6,10.4),(2.5,.48,.7),9),uv((0,154.9,10.3),(2.1,.55,.65),9)])
# Hair cap is shaped with an open hairline rather than a sphere over the face.
def cap(style):
 vs=[];fs=[]; n=40; rows=14
 for i in range(rows+1):
  for j in range(n):
   a=j*2*math.pi/n
   front=max(math.cos(a),0)
   end=1.75-.63*front
   if style=='waves':end+=.38*(1-front)
   p=.025+(end-.025)*i/rows
   ripple=(.20*math.sin(a*8+p*5) if style=='waves' else .12*math.sin(a*11))
   vs.append(((11.4+ripple)*math.sin(p)*math.sin(a),165+14.4*math.cos(p), (9.9+ripple)*math.sin(p)*math.cos(a)-.8))
 for i in range(rows):
  for j in range(n):
   a=i*n+j;b=i*n+(j+1)%n;c=b+n;d=a+n
   fs.extend([(a,d,c),(a,c,b)])
 m=trimesh.Trimesh(vs,fs,process=False);m.fix_normals();return m
hair={}
for style in ['shortCrop','athleticBun','softCurls','waves']:
 hp=[(cap(style),1)]
 if style=='athleticBun':hp.append(uv((0,175,-8),(6,6.2,5.5),1))
 if style=='softCurls':
  for a in np.linspace(0,2*math.pi,14,endpoint=False):
   for p in [.5,.9,1.3]:
    hp.append(uv((11*math.sin(p)*math.sin(a),165+14*math.cos(p),10*math.sin(p)*math.cos(a)-1),(2.7,2.8,2.7),1,(6,10)))
 if style=='waves':
  for s in [-1,1]:hp.append(uv((s*9.3,157,-3),(3.8,11,5),1))
 hair[style]=hp
accessories={'none':[],'headband':[],'glasses':[]}
# Rounded ribbon and two spectacle frames (true 3D tubes).
def tube(points,r,mat):
 pts=np.array(points);vs=[];fs=[];N=8
 for i,p in enumerate(pts):
  tangent=pts[min(i+1,len(pts)-1)]-pts[max(i-1,0)];tangent/=np.linalg.norm(tangent)
  ref=np.array([0.,1.,0.])
  if abs(tangent@ref)>.95:ref=np.array([0.,0.,1.])
  u=np.cross(tangent,ref);u/=np.linalg.norm(u);w=np.cross(tangent,u)
  for j in range(N):vs.append(p+r*(u*math.cos(j*2*math.pi/N)+w*math.sin(j*2*math.pi/N)))
 for i in range(len(pts)-1):
  for j in range(N):
   a=i*N+j;b=i*N+(j+1)%N;fs.extend([(a,b,b+N),(a,b+N,a+N)])
 m=trimesh.Trimesh(vs,fs,process=False);m.fix_normals();return m,mat
accessories['headband']=[tube([(11.55*math.sin(a),170,10*math.cos(a)-1) for a in np.linspace(0,2*math.pi,65)],1.0,2)]
for s in [-1,1]:
 accessories['glasses'].append(tube([(s*4.4+3*math.sin(a),164+2.3*math.cos(a),10) for a in np.linspace(0,2*math.pi,41)],.32,6))
 accessories['glasses'].append(tube([(s*7.4,164,10),(s*10.8,164,4),(s*10.5,163,-2)],.32,6))
accessories['glasses'].append(tube([(-1.4,164,10),(0,164.5,10.2),(1.4,164,10)],.32,6))
def pack(parts):
 vs=[];fs=[]; mats=[]
 for m,mat in parts:
  off=len(vs);vs.extend(np.round(m.vertices,4).tolist());fs.extend((m.faces+off).tolist());mats.extend([mat]*len(m.faces))
 return {'vertices':vs,'faces':fs,'materials':mats}
data={'body':pack(parts),'hair':{k:pack(p) for k,p in hair.items()},'accessories':{k:pack(p) for k,p in accessories.items()}}
(ROOT/'assets/models/bloom_human.mesh.gz').write_bytes(gzip.compress(json.dumps(data,separators=(',',':')).encode(),mtime=0))
# Interchange model is the same geometry as the default renderer configuration.
scene=trimesh.Scene()
colors={0:[237,193,157,255],1:[53,38,30,255],2:[137,113,217,255],3:[77,58,120,255],4:[250,250,253,255],5:[218,209,237,255],6:[36,29,35,255],7:[255,253,245,255],8:[83,62,42,255],9:[174,90,83,255]}
for i,(m,mat) in enumerate(parts+hair['athleticBun']):
 m=m.copy()
 if mat==0:
  centers=m.triangles_center
  ids=np.where((centers[:,1]>108)&(centers[:,1]<140)&(np.abs(centers[:,0])<18),2,np.where((centers[:,1]>68)&(centers[:,1]<104)&(np.abs(centers[:,0])<19),3,0))
  m.visual.face_colors=[colors[int(i)] for i in ids]
 else:m.visual.vertex_colors=colors[mat]
 scene.add_geometry(m,node_name=f'Human_{i}')
scene.export(ROOT/'assets/models/bloom_human.glb')
print('Wrote original model assets')
