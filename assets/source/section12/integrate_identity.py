"""Technical extraction, nearest-neighbour fitting and atlas packing of imagegen art."""
import json,sys,hashlib,shutil
from pathlib import Path
import numpy as np
from scipy.ndimage import label
from PIL import Image
ROOT=Path('/workspace/Yume-WordEnd'); SOURCE=ROOT/'assets/source/section12'
sys.path.insert(0,str(ROOT/'tools'))
import hd2d_sheets as anchors
FILES={'lakhesh-back':'exec-b5d3453a-bf2e-4851-b35e-7ef97a7409bd.png','lakhesh-profile':'exec-054d35d1-dca3-4c3b-90c6-47d96b6607a0.png','lakhesh-portrait':'exec-fc83bc63-fd5f-41ad-8450-3a448b55678d.png','limeskin-targets':'exec-f2a3b2f7-d8d9-4edf-895d-58489d124c64.png'}
for key,filename in FILES.items():
 p=SOURCE/('lakhesh' if key.startswith('lakhesh') else 'limeskin');shutil.copyfile(Path('/workspace/generated_images')/filename,p/(key+'-generated.png'))
def binary(im):
 a=np.asarray(im.convert('RGBA')).copy();a[:,:,3]=np.where(a[:,:,3]>=128,255,0);a[a[:,:,3]==0]=0
 return Image.fromarray(a)
def cut(im,cell,refsize):
 x,y,w,h=cell;sx=im.width/refsize[0];sy=im.height/refsize[1]
 c=binary(im.crop((round(x*sx),round(y*sy),round((x+w)*sx),round((y+h)*sy))))
 a=np.asarray(c).copy();labs,n=label(a[:,:,3]>0)
 if n:
  count=np.bincount(labs.ravel());count[0]=0;a[labs!=count.argmax()]=0;c=Image.fromarray(a)
 return c.crop(c.getchannel('A').getbbox())
def fit(c,target):
 # Section 2 expressly permits nearest-neighbour scaling and binary alpha fitting.
 c=binary(c);c=c.crop(c.getchannel('A').getbbox());c=c.resize((max(1,round(c.width*target/c.height)),target),Image.Resampling.NEAREST)
 for _ in range(3):
  an=anchors.compute_anchor(c,'dark',axis=True);measured=an[1]-anchors.top_of(c)
  if measured==target:return c
  h=c.height+(target-measured);c=c.resize((max(1,round(c.width*h/c.height)),h),Image.Resampling.NEAREST)
 return c
REPORT={}
def match_palette(c, reference):
 colors=sorted({rgb[:3] for rgb in reference.get_flattened_data() if rgb[3]>=128})
 if len(colors)>64:
  ref=reference.convert('RGB').quantize(colors=64,method=Image.Quantize.MEDIANCUT);colors=[tuple(ref.getpalette()[i:i+3]) for i in range(0,192,3)]
 colors=(colors+[colors[-1]]*256)[:256];pal=Image.new('P',(1,1));pal.putpalette([v for rgb in colors for v in rgb]);alpha=c.getchannel('A');c=c.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');c.putalpha(alpha);return binary(c)
def integrate(ident,suffix,overrides):
 p=SOURCE/ident;stem=ident+suffix;before=Image.open(p/('before-'+stem+'.png')).convert('RGBA');data=json.loads((p/('before-'+stem+'.json')).read_text());old=data.copy();parts={};height=0;width=0;summary=[]
 for name,anim in data['animations'].items():
  row=[]
  for j,f in enumerate(anim['images']):
   part=anchors.crop(before,f);key=(name,j)
   if key in overrides:part=match_palette(overrides[key],before)
   row.append((part,f[4:6],key in overrides));
  parts[name]=row;height+=max(c.height for c,_,_ in row)+4;width=max(width,sum(c.width+4 for c,_,_ in row)-4)
 atlas=Image.new('RGBA',(width,height-4));y=0;unchanged=0
 for name,row in parts.items():
  rh=max(c.height for c,_,_ in row);x=0;frames=[]
  for j,(c,an,changed) in enumerate(row):
   py=y+rh-c.height;atlas.alpha_composite(c,(x,py));an=anchors.compute_anchor(c,'dark',axis=True) if changed else an;frames.append([x,py,c.width,c.height,*an]);x+=c.width+4
   if changed:summary.append({'animation':name,'index':j,'height':an[1]-anchors.top_of(c)})
   else:
    original=anchors.crop(before,data['animations'][name]['images'][j]);assert c.tobytes()==original.tobytes();unchanged+=1
  data['animations'][name]['images']=frames;y+=rh+4
 data['planche']=list(atlas.size);data['anchors_validated']=False;data['source_correction']='section12_imagegen_identity_and_scale'
 dest=ROOT/'assets/characters'/ident;atlas.save(dest/(stem+'.png'));(dest/(stem+'.json')).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 REPORT[stem]={'changed':summary,'unchanged_frames_pixel_identical':unchanged,'alpha_values':list(set(atlas.getchannel('A').getdata()))}
 return atlas,data
# Lakhesh profile: the two idle poses only. All existing walk/dialogue pixels are retained.
p=SOURCE/'lakhesh';im=Image.open(p/'lakhesh-profile-generated.png').convert('RGBA');cells=json.loads((p/'reference-profile-idle.json').read_text());ov={}
for cell in cells:ov[(cell['animation'],cell['index'])]=fit(cut(im,cell['cell'],(600,400)),115)
integrate('lakhesh','',ov)
# Back: all 10 hairstyles must change sides; retain each pose's original standing scale.
im=Image.open(p/'lakhesh-back-generated.png').convert('RGBA');cells=json.loads((p/'reference-back-current.json').read_text());old=json.loads((p/'before-lakhesh_back.json').read_text());before=Image.open(p/'before-lakhesh_back.png').convert('RGBA');ov={}
for cell in cells:
 name,j=cell['animation'],cell['index'];f=old['animations'][name]['images'][j];target=int(anchors.standing_height(anchors.crop(before,f),f));ov[(name,j)]=fit(cut(im,cell['cell'],(1024,768)),target)
integrate('lakhesh','_back',ov)
# Front: existing couette already lies screen-right; restore distinct original talking art.
ov={('parle',j):fit(Image.open(p/f'recovered-front-talk-{j}.png').convert('RGBA'),114) for j in range(2)}
integrate('lakhesh','_front',ov)
portrait=binary(Image.open(p/'lakhesh-portrait-generated.png').convert('RGBA'));portrait=portrait.resize((256,256),Image.Resampling.NEAREST);portrait=match_palette(portrait,Image.open(p/'before-lakhesh_portrait.png').convert('RGBA'));portrait.save(ROOT/'assets/characters/lakhesh/lakhesh_portrait.png')
# Limeskin: only four talking poses and the four back idle/talking poses.
p=SOURCE/'limeskin';im=Image.open(p/'limeskin-targets-generated.png').convert('RGBA');cells=json.loads((p/'reference-targets.json').read_text())
for suffix in ['','_front','_back']:
 old=json.loads((p/('before-limeskin'+suffix+'.json')).read_text());before=Image.open(p/('before-limeskin'+suffix+'.png')).convert('RGBA');ov={}
 for cell in cells:
  if cell['direction']!=suffix:continue
  name,j=cell['animation'],cell['index'];f=old['animations'][name]['images'][j];target=269 if suffix!='_back' else int(anchors.standing_height(anchors.crop(before,f),f));ov[(name,j)]=fit(cut(im,cell['cell'],(1200,1050)),target)
 integrate('limeskin',suffix,ov)
(SOURCE/'identity-validation.json').write_text(json.dumps(REPORT,indent=2)+'\n');print(json.dumps(REPORT,indent=2))
