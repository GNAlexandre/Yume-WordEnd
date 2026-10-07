"""Reproducible real, rigged chibi GLBs for Godot. Run inside Blender 4.3.

API: generate(spec: dict, output_dir: Path, render=True) -> validation dict.
Axes are Blender Z-up/front -Y until the glTF exporter converts to Y-up/front +Z.
Primitives are solid geometry, weighted to a shared humanoid skeleton. geometry_hook
may add reference-specific geometry through Builder.mesh/cone/tube/ellipsoid.
"""
import argparse
import json
import importlib
import math
import os
from pathlib import Path
import sys
import tempfile
import bpy
from mathutils import Vector, Matrix

COMBAT = {
    'repos': {'ips': 10, 'images': 20, 'boucle': True},
    'marche': {'ips': 10, 'images': 6, 'boucle': True},
    'course': {'ips': 14, 'images': 5, 'boucle': True},
    'attaque': {'ips': 14, 'images': 4, 'boucle': False, 'coup': [1, 2, 3]},
    'charge': {'ips': 10, 'images': 4, 'boucle': False, 'onde': 3},
    'degats': {'ips': 10, 'images': 4, 'boucle': False},
    'mort': {'ips': 10, 'images': 12, 'boucle': False},
}
NPC = {k: dict(COMBAT[k]) for k in ('repos', 'marche')}
NPC['parle'] = {'ips': 10, 'images': 20, 'boucle': True}

def rgb(value):
    if isinstance(value, (tuple, list)):
        return tuple(value[:3])
    value = value.lstrip('#')
    return tuple(int(value[i:i+2], 16) / 255 for i in (0, 2, 4))

class Builder:
    def __init__(self, spec):
        self.spec = spec
        self.height = float(spec.get('height', 1.5))
        self.parts = []
        self.weapon_objects = []
        self.colors = []
        self.palette = {
            'skin': spec.get('skin_color', '#f8d2bd'),
            'hair': spec.get('hair_color', '#779cc6'),
            'eyes': spec.get('eye_color', '#5796be'),
            'outfit': spec.get('outfit_color', '#33425b'),
            'accent': spec.get('accent_color', '#d6b775'),
            'white': spec.get('white_color', '#fff2df'),
            'dark': '#292738', 'black': '#151622', 'shoe': spec.get('details',{}).get('shoe_color','#3d3547'),
            'blush': '#eaa19a', 'mouth': '#b46269', 'metal': '#afd4df',
        }
        mat = bpy.data.materials.new('PaintedPalette')
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get('Principled BSDF')
        bsdf.inputs['Roughness'].default_value = 0.82
        bsdf.inputs['Metallic'].default_value = 0
        self.material = mat
        self.image_node = mat.node_tree.nodes.new('ShaderNodeTexImage')
        mat.node_tree.links.new(self.image_node.outputs['Color'], bsdf.inputs['Base Color'])
        self.armature = None
        self.rig_scale = 1.0
        self.rig_offset = 0.0

    def color_index(self, color):
        c = self.palette.get(color, color)
        c = tuple(rgb(c))
        if c not in self.colors:
            self.colors.append(c)
        if len(self.colors) > 256:
            raise ValueError('Palette requires more than 256 colors')
        return self.colors.index(c)

    def decorate(self, obj, name, color, bone):
        obj.name = name
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        obj.data.materials.clear()
        obj.data.materials.append(self.material)
        ci = self.color_index(color)
        uv = obj.data.uv_layers.active or obj.data.uv_layers.new(name='UVMap')
        for v in uv.data:
            v.uv = ((ci % 16 + 0.5) / 16, (ci // 16 + 0.5) / 16)
        if bone:
            group = obj.vertex_groups.new(name=bone)
            group.add(list(range(len(obj.data.vertices))), 1, 'REPLACE')
        for poly in obj.data.polygons:
            poly.use_smooth = True
        self.parts.append(obj)
        obj.select_set(False)
        return obj

    def ellipsoid(self, name, loc, scale, color, bone='head', segments=12, rings=8):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=loc)
        obj = bpy.context.object
        obj.scale = scale
        return self.decorate(obj, name, color, bone)

    def cone(self, name, a, b, r0, r1, color, bone='chest', vertices=12):
        a, b = Vector(a), Vector(b)
        axis = b-a
        bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=r0, radius2=r1,
                                        depth=axis.length, location=(a+b)/2)
        obj = bpy.context.object
        obj.rotation_euler = axis.to_track_quat('Z', 'Y').to_euler()
        return self.decorate(obj, name, color, bone)

    def mesh(self, name, verts, faces, color, bone='chest'):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(verts, [], faces)
        mesh.update()
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        return self.decorate(obj, name, color, bone)

    def tube(self, name, points, radii, color, bone='head', sides=7):
        verts, faces = [], []
        for i, point in enumerate(points):
            p = Vector(point)
            tangent = Vector(points[min(i+1, len(points)-1)])-Vector(points[max(i-1, 0)])
            tangent.normalize()
            normal = tangent.cross(Vector((0, 0, 1)))
            if normal.length < 0.1:
                normal = tangent.cross(Vector((0, 1, 0)))
            normal.normalize()
            binormal = tangent.cross(normal).normalized()
            for j in range(sides):
                t = j * 2 * math.pi / sides
                v = p + radii[i] * (math.cos(t)*normal + math.sin(t)*binormal)
                verts.append(tuple(v))
        for i in range(len(points)-1):
            for j in range(sides):
                a = i*sides+j
                b = i*sides+(j+1)%sides
                faces.append((a,b,b+sides,a+sides))
        faces.extend((tuple(reversed(range(sides))), tuple(range(len(verts)-sides,len(verts)))))
        return self.mesh(name, verts, faces, color, bone)

    def disk(self, name, center, rx, rz, color, bone='head', segments=16):
        x,y,z=center
        verts = [(x,y,z)] + [(x+rx*math.cos(i*2*math.pi/segments), y,
                  z+rz*math.sin(i*2*math.pi/segments)) for i in range(segments)]
        faces=[(0,i+1,(i+1)%segments+1) for i in range(segments)]
        return self.mesh(name,verts,faces,color,bone)

    def ring(self, name, z, rx, ry, thickness, color, bone='chest'):
        points = [(rx*math.cos(i*math.tau/16),ry*math.sin(i*math.tau/16),z) for i in range(17)]
        return self.tube(name,points,[thickness]*17,color,bone,sides=5)

    def shell(self, name, bottom, top, rx0, ry0, rx1, ry1, color, bone='hips', count=16):
        verts=[]
        for z,rx,ry in ((bottom,rx0,ry0),(top,rx1,ry1)):
            verts.extend((rx*math.cos(i*math.tau/count),ry*math.sin(i*math.tau/count),z)
                         for i in range(count))
        faces=[(i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count)]
        faces.append(tuple(reversed(range(count))))
        faces.append(tuple(range(count,2*count)))
        return self.mesh(name,verts,faces,color,bone)

    def head(self):
        h=self.height
        species=self.spec.get('species','human')
        self.ellipsoid('Face',(0,0,.80*h),(.17*h,.135*h,.185*h),'skin','head',16,10)
        self.ellipsoid('Neck',(0,0,.62*h),(.055*h,.052*h,.05*h),'skin','neck',10,6)
        for s in (-1,1):
            self.ellipsoid('Ear',(s*.164*h,.001*h,.78*h),(.023*h,.026*h,.044*h),'skin','head',8,6)
        if species in ('dog','cat','reptile','frog','rabbit','bird'):
            self.animal_head(species)
        elif species=='skull':
            self.palette['skin']=self.spec.get('skin_color','#e4ddd0')
        # Eyes are layered curved solids, visible from all front angles.
        eyey=-.124*h
        if species in ('dog','reptile','bird'):
            eyey=-.137*h
        for s in (-1,1):
            x=s*.067*h
            self.ellipsoid('EyeWhite',(x,eyey,.817*h),(.048*h,.015*h,.055*h),'white','head',12,8)
            self.ellipsoid('EyeIris',(x,eyey-.014*h,.812*h),(.028*h,.009*h,.039*h),'eyes','head',12,8)
            self.ellipsoid('EyePupil',(x,eyey-.021*h,.814*h),(.014*h,.004*h,.024*h),'black','head',10,6)
            self.ellipsoid('EyeSparkle',(x-.008*h,eyey-.025*h,.831*h),(.008*h,.003*h,.010*h),'white','head',8,6)
            self.tube('UpperEyelash',[(x-.040*h,eyey-.006*h,.843*h),(x,eyey-.012*h,.866*h),(x+.040*h,eyey-.006*h,.843*h)],[.005*h,.006*h,.005*h],'dark','head',5)
            self.tube('Brow',[(x-.032*h,-.132*h,.877*h),(x+.027*h,-.134*h,.875*h)],[.005*h,.004*h],'hair','head',5)
            self.ellipsoid('Blush',(s*.113*h,-.112*h,.768*h),(.025*h,.004*h,.010*h),'blush','head',10,6)
        self.ellipsoid('Nose',(0,-.141*h,.772*h),(.010*h,.012*h,.012*h),'skin','head',8,6)
        self.tube('Smile',[(-.017*h,-.137*h,.743*h),(0,-.144*h,.738*h),(.017*h,-.137*h,.743*h)],[.002*h]*3,'mouth','head',5)

    def animal_head(self,species):
        h=self.height
        fur=self.spec.get('details',{}).get('ear_color',self.palette['hair'])
        if species in ('cat','dog','rabbit'):
            for s in (-1,1):
                if species=='rabbit':
                    self.ellipsoid('RabbitEar',(s*.105*h,.009*h,1.02*h),(.043*h,.028*h,.155*h),fur,'head',10,8)
                    self.ellipsoid('RabbitEarInside',(s*.105*h,-.02*h,1.035*h),(.025*h,.006*h,.10*h),'blush','head',8,6)
                elif species=='cat':
                    self.cone('CatEar',(s*.12*h,0,.91*h),(s*.14*h,0,1.035*h),.059*h,.005*h,fur,'head',3)
                    self.cone('CatEarInside',(s*.12*h,-.021*h,.925*h),(s*.14*h,-.021*h,1.025*h),.028*h,.001*h,'blush','head',3)
                else:
                    self.ellipsoid('DogEar',(s*.16*h,0,.88*h),(.062*h,.03*h,.10*h),fur,'head',10,8)
            self.ellipsoid('Muzzle',(0,-.124*h,.747*h),(.078*h,.059*h,.045*h),'white','head',12,8)
            self.ellipsoid('AnimalNose',(0,-.181*h,.767*h),(.022*h,.012*h,.017*h),'dark','head',10,6)
        elif species=='reptile':
            self.ellipsoid('ReptileMuzzle',(0,-.121*h,.74*h),(.13*h,.1*h,.063*h),'skin','head',12,8)
            for s in (-1,1):
                self.ellipsoid('Nostril',(s*.053*h,-.21*h,.754*h),(.008*h,.004*h,.007*h),'dark','head',8,6)
            for i in range(4):
                self.cone('Crest',(0,.027*h,(.84+i*.042)*h),(0,.027*h,(.91+i*.042)*h),.04*h,0,'accent','head',5)
        elif species=='frog':
            for s in (-1,1):
                self.ellipsoid('EyeBulge',(s*.10*h,-.03*h,.932*h),(.073*h,.060*h,.07*h),'skin','head',10,8)
        elif species=='bird':
            self.cone('Beak',(0,-.11*h,.755*h),(0,-.265*h,.74*h),.07*h,.009*h,'accent','head',4)

    def hair(self):
        h=self.height
        style=self.spec.get('hair_style','bob')
        if style in ('none','bald'):
            return
        # Dome stops above face, plus back shell and individual volume locks.
        verts=[(0,0,1.008*h)]
        nr,ns=5,16
        for j in range(1,nr+1):
            t=(math.pi*.54)*j/nr
            for i in range(ns):
                phi=i*math.tau/ns
                verts.append((.176*h*math.sin(t)*math.cos(phi),.144*h*math.sin(t)*math.sin(phi),
                              .808*h+.20*h*math.cos(t)))
        faces=[(0,1+i,1+(i+1)%ns) for i in range(ns)]
        for j in range(nr-1):
            off=1+j*ns
            faces.extend((off+i,off+(i+1)%ns,off+(i+1)%ns+ns,off+i+ns) for i in range(ns))
        self.mesh('HairCap',verts,faces,'hair','head')
        # Swept bangs with visible divisions. Face stays open underneath.
        for i in range(7):
            x=(i-3)*.045*h
            tip=.858*h+(.022*h if i%2 else 0)
            self.tube('FringeLock',[(x*.8,-.10*h,.963*h),(x,-.144*h,.92*h),(x+.022*h,-.153*h,tip)],
                      [.034*h,.035*h,.003*h],'hair','head',7)
        for s in (-1,1):
            end=.72*h if style in ('crop','short') else .63*h if style=='bob' else (1-float(self.spec.get('details',{}).get('hair_length',.4)))*h
            self.tube('SideLock',[(s*.15*h,-.06*h,.94*h),(s*.174*h,-.046*h,.79*h),(s*.166*h,-.02*h,end)],
                      [.041*h,.042*h,.011*h],'hair','head',7)
        if style in ('crop','short'):
            return
        length=float(self.spec.get('details',{}).get('hair_length',.4))
        for i in range(7):
            x=(i-3)*.046*h
            end=.60*h if style=='bob' else (1.0-length)*h
            self.tube('BackHairLock',[(x*.95,.105*h,.89*h),(x,.142*h,.75*h),(x*.95,.13*h,end)],
                      [.038*h,.042*h,.007*h],'hair','head',7)
        if style in ('twintails','ponytail','side_ponytail'):
            sides=(-1,1) if style=='twintails' else (1,)
            for s in sides:
                x=s*.18*h if style!='ponytail' else 0
                y=.05*h if style!='ponytail' else .16*h
                self.ellipsoid('HairTie',(x,y,.84*h),(.035*h,.032*h,.026*h),'accent','head',8,6)
                for j in range(3):
                    self.tube('Ponytail',[(x,y,.85*h),(x+s*.06*h,y+.07*h,.71*h),(x+s*(.05+.02*j)*h,y+.06*h,(1-length)*h)],
                              [.033*h,.05*h,.006*h],'hair','head',7)

    def body(self):
        h=self.height
        outfit=self.spec.get('outfit','uniform')
        width=float(self.spec.get('details',{}).get('body_width',1))
        self.shell('Torso',.37*h,.59*h,.13*h*width,.075*h,.15*h*width,.08*h,'outfit','chest',16)
        self.ellipsoid('Hips',(0,0,.375*h),(.124*h*width,.073*h,.067*h),'outfit','hips',12,6)
        self.ring('Collar',.599*h,.062*h,.048*h,.012*h,'white','chest')
        self.ring('WaistTrim',.395*h,.132*h*width,.079*h,.011*h,'accent','hips')
        features=self.spec.get('features',[])
        sleevecolor=self.spec.get('details',{}).get('sleeve_color','outfit')
        trousercolor=self.spec.get('details',{}).get('trouser_color','outfit')
        # Sleeves and articulated limbs overlap over the bone pivots.
        for s,suffix in ((-1,'.L'),(1,'.R')):
            shoulder=(s*.155*h*width,0,.587*h)
            elbow=(s*.235*h*width,0,.492*h)
            wrist=(s*.292*h*width,-.005*h,.395*h)
            self.ellipsoid('Shoulder'+suffix,shoulder,(.055*h,.054*h,.052*h),sleevecolor,'upper_arm'+suffix,10,6)
            self.cone('Sleeve'+suffix,shoulder,elbow,.055*h,.041*h,sleevecolor,'upper_arm'+suffix,12)
            self.ellipsoid('Elbow'+suffix,elbow,(.039*h,.038*h,.039*h),sleevecolor,'lower_arm'+suffix,10,6)
            armcolor=self.spec.get('details',{}).get('forearm_color',self.spec.get('details',{}).get('sleeve_color','skin' if outfit in ('dress','shorts','overalls') else 'outfit'))
            self.cone('Forearm'+suffix,elbow,wrist,.036*h,.026*h,armcolor,'lower_arm'+suffix,10)
            self.ellipsoid('Hand'+suffix,(wrist[0],wrist[1],wrist[2]-.014*h),(.028*h,.024*h,.043*h),'skin','hand'+suffix,10,8)
            self.cone('Cuff'+suffix,Vector(elbow)*.05+Vector(wrist)*.95,Vector(elbow)*.13+Vector(wrist)*.87,.031*h,.032*h,self.spec.get('details',{}).get('cuff_color','white'),'lower_arm'+suffix,12)
            hip=(s*.067*h,0,.37*h)
            knee=(s*.067*h,-.006*h,.218*h)
            ankle=(s*.067*h,0,.066*h)
            legscolor=self.spec.get('details',{}).get('leg_color',self.spec.get('details',{}).get('trouser_color','skin' if outfit in ('dress','maid','shorts') else 'outfit'))
            self.cone('Thigh'+suffix,hip,knee,.054*h,.039*h,legscolor,'upper_leg'+suffix,12)
            self.ellipsoid('Knee'+suffix,knee,(.038*h,.036*h,.039*h),legscolor,'lower_leg'+suffix,10,6)
            self.cone('Shin'+suffix,knee,ankle,.038*h,.029*h,legscolor,'lower_leg'+suffix,12)
            shoe='skin' if 'barefoot' in features else 'shoe'
            self.ellipsoid('Foot'+suffix,(s*.067*h,-.028*h,.034*h),(.048*h,.077*h,.034*h),shoe,'foot'+suffix,12,8)
            if 'barefoot' not in features:
                boot_height=float(self.spec.get('details',{}).get('boot_height',.15))
                sock_height=float(self.spec.get('details',{}).get('sock_height',boot_height))
                if 'white_socks' in features: sock_height=max(sock_height,.17);boot_height=.055
                self.cone('Sock'+suffix,(s*.067*h,0,.045*h),(s*.067*h,0,sock_height*h),.035*h,.037*h,'white','lower_leg'+suffix,12)
                self.cone('Boot'+suffix,(s*.067*h,0,.04*h),(s*.067*h,0,boot_height*h),.036*h,.039*h,'shoe','lower_leg'+suffix,12)
                self.ring_side('BootTrim'+suffix,s*.067*h,(boot_height-.006)*h,.041*h,'accent','lower_leg'+suffix)
        if outfit in ('dress','robe','maid') or (outfit=='hoodie' and self.spec.get('details',{}).get('skirt_length',0)>0):
            bottom=.18*h if outfit=='robe' else .29*h
            bottom=float(self.spec.get('details',{}).get('skirt_length',bottom/h))*h
            self.shell('BellSkirt',bottom,.405*h,.207*h*width,.123*h,.133*h*width,.08*h,self.spec.get('details',{}).get('skirt_color','outfit'),'hips',20)
            self.ring('HemTrim',bottom+.008*h,.207*h*width,.123*h,.012*h,'accent','hips')
            if outfit in ('dress','maid'):
                self.ring('Petticoat',bottom-.008*h,.21*h*width,.126*h,.011*h,'white','hips')
        elif outfit=='shorts':
            for s,suffix in ((-1,'.L'),(1,'.R')):
                self.cone('Shorts',(s*.067*h,0,.29*h),(s*.067*h,0,.39*h),.06*h,.065*h,trousercolor,'upper_leg'+suffix,12)
        if outfit in ('uniform','robe'):
            # V-shaped lapels, small uniform buttons, pocket and seam.
            for s in (-1,1):
                self.mesh('Lapel',[(s*.018*h,-.084*h,.56*h),(s*.07*h,-.084*h,.585*h),(s*.044*h,-.09*h,.49*h)],[(0,1,2)],'accent','chest')
            for z in (.53,.48,.43):
                self.ellipsoid('Button',(0,-.084*h,z*h),(.008*h,.006*h,.008*h),'accent','chest',8,6)
        if outfit=='overalls':
            for s in (-1,1):
                self.cone('OverallStrap',(s*.08*h,-.08*h,.43*h),(s*.085*h,-.075*h,.59*h),.015*h,.015*h,'accent','chest',6)
            self.mesh('Bib',[(-.077*h,-.086*h,.4*h),(.077*h,-.086*h,.4*h),(.077*h,-.086*h,.51*h),(-.077*h,-.086*h,.51*h)],[(0,1,2,3)],'accent','chest')
        if outfit=='hoodie' or 'hood' in features:
            self.ellipsoid('HoodBack',(0,.083*h,.64*h),(.15*h,.058*h,.11*h),'outfit','chest',12,8)
            for s in (-1,1):
                self.tube('HoodString',[(s*.025*h,-.08*h,.6*h),(s*.031*h,-.09*h,.51*h)],[.003*h,.003*h],'white','chest',5)
        if outfit=='maid' or 'apron' in features:
            apron_bottom=max(.04,float(self.spec.get('details',{}).get('skirt_length',.26))+.02)*h
            self.mesh('Apron',[(-.087*h,-.089*h,.54*h),(.087*h,-.089*h,.54*h),(.155*h,-.125*h,apron_bottom),(-.155*h,-.125*h,apron_bottom)],[(0,1,2,3)],self.spec.get('details',{}).get('apron_color','white'),'hips')
            self.ring('ApronBand',.40*h,.138*h,.085*h,.009*h,'white','hips')
            self.ellipsoid('ApronBow',(0,.099*h,.4*h),(.063*h,.021*h,.029*h),'white','hips',10,6)
        self.features()

    def ring_side(self,name,x,z,r,color,bone):
        points=[(x+r*math.cos(i*math.tau/12),r*math.sin(i*math.tau/12),z) for i in range(13)]
        self.tube(name,points,[.006*self.height]*13,color,bone,5)

    def features(self):
        h=self.height
        features=self.spec.get('features',[])
        for feature in features:
            if feature in ('bow','tie'):
                if feature=='tie':
                    self.mesh('Necktie',[(0,-.093*h,.587*h),(-.022*h,-.096*h,.5*h),(0,-.098*h,.476*h),(.022*h,-.096*h,.5*h)],[(0,1,2,3)],'accent','chest')
                else:
                    for s in (-1,1):
                        self.ellipsoid('NeckBow',(s*.032*h,-.096*h,.574*h),(.031*h,.013*h,.021*h),'accent','chest',10,6)
            elif feature=='headband':
                self.tube('Headband',[(-.165*h,0,.84*h),(-.13*h,-.03*h,.955*h),(0,-.015*h,1.018*h),(.13*h,-.03*h,.955*h),(.165*h,0,.84*h)],[.012*h]*5,'white','head',6)
            elif feature=='glasses':
                for s in (-1,1):
                    pts=[(s*.067*h+.047*h*math.cos(i*math.tau/16),-.147*h,.817*h+.052*h*math.sin(i*math.tau/16)) for i in range(17)]
                    self.tube('Glasses',pts,[.0035*h]*17,'dark','head',5)
                self.tube('GlassesBridge',[(-.02*h,-.151*h,.82*h),(.02*h,-.151*h,.82*h)],[.003*h]*2,'dark','head',5)
            elif feature in ('cape','coat','long_coat'):
                bottom=.23*h if feature=='long_coat' else .34*h
                verts=[(-.15*h,.047*h,.60*h),(.15*h,.047*h,.60*h),(.19*h,.105*h,bottom),(-.19*h,.105*h,bottom),(-.15*h,.067*h,.60*h),(.15*h,.067*h,.60*h),(.19*h,.12*h,bottom),(-.19*h,.12*h,bottom)]
                self.mesh('Cape' if feature=='cape' else 'CoatTails',verts,[(0,1,2,3),(4,7,6,5),(0,4,5,1),(3,2,6,7),(0,3,7,4),(1,5,6,2)],'outfit','chest')
                if feature!='cape':
                    for s in (-1,1):
                        self.mesh('FrontCoatPanel',[(s*.07*h,-.085*h,.42*h),(s*.14*h,-.08*h,.41*h),(s*.16*h,-.1*h,bottom),(s*.09*h,-.10*h,bottom)],[(0,1,2,3)],'outfit','hips')
            elif feature=='beard':
                self.ellipsoid('Beard',(0,-.105*h,.70*h),(.1*h,.061*h,.065*h),'hair','head',12,8)
            elif feature=='puff_sleeves':
                for s,suffix in ((-1,'.L'),(1,'.R')):
                    self.ellipsoid('PuffSleeve',(s*.18*h,0,.56*h),(.08*h,.071*h,.065*h),self.spec.get('details',{}).get('sleeve_color','outfit'),'upper_arm'+suffix,12,8)
            elif feature in ('cap','hat'):
                self.ellipsoid('HatCrown',(0,0,.976*h),(.179*h,.147*h,.065*h),'accent','head',12,8)
                self.ellipsoid('HatBrim',(0,-.078*h,.947*h),(.205*h,.155*h,.014*h),'accent','head',12,6)
            elif feature=='animal_ears' and self.spec.get('species','human')=='human':
                self.animal_head('cat')
            elif feature=='cross_buttons':
                for z in (.52,.47):
                    self.tube('CrossTrim',[(-.014*h,-.093*h,z*h),(.014*h,-.093*h,z*h)],[.004*h]*2,'accent','chest',5)
                    self.tube('CrossTrim',[(0,-.093*h,(z-.014)*h),(0,-.093*h,(z+.014)*h)],[.004*h]*2,'accent','chest',5)
        species=self.spec.get('species','human')
        if species in ('cat','dog','reptile','rabbit'):
            color='skin' if species=='reptile' else 'hair'
            self.tube('Tail',[(0,.04*h,.37*h),(0,.19*h,.38*h),(.05*h,.25*h,.47*h),(.09*h,.26*h,.53*h)],
                      [.03*h,.035*h,.022*h,.009*h],color,'hips',7)

    def weapon(self):
        weapon=self.spec.get('weapon')
        if not weapon:
            return
        h=self.height
        weapon=weapon if isinstance(weapon,dict) else {'name':weapon}
        name=weapon.get('name','Seniolis' if self.spec['id']=='chtholly' else 'Sword')
        x=.292*h
        # Long sword points downward in rest pose; blade lies in XZ plane.
        gripz=.39*h
        length=float(weapon.get('length',1.2 if name=='Seniolis' else .75))
        color=weapon.get('color','#a8c9e9')
        start=len(self.parts)
        self.cone('SwordGrip',(x,-.018*h,gripz+.06),(x,-.018*h,gripz-.09),.017,.017,'dark','hand.R',8)
        self.cone('SwordGuard',(x-.11,-.018*h,gripz-.075),(x+.11,-.018*h,gripz-.075),.022,.022,'dark','hand.R',8)
        # Diagonal forward/down restblade does not cross feet.
        a=Vector((x,-.018*h,gripz-.09)); b=a+Vector((.46,0,-.82)).normalized()*(length-.15)
        axis=(b-a).normalized(); side=Vector((axis.z,0,-axis.x))
        verts=[]
        for center,w,d in ((a,.067,.014),(b-axis*.1,.042,.009),(b,0,.002)):
            verts += [tuple(center+side*w+Vector((0,-d,0))),tuple(center-side*w+Vector((0,-d,0))),
                      tuple(center+side*w+Vector((0,d,0))),tuple(center-side*w+Vector((0,d,0)))]
        faces=[(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5),(4,5,9,8),(6,10,11,7),(4,8,10,6),(5,7,11,9),(0,2,3,1)]
        self.mesh('SwordBlade',verts,faces,color,'hand.R')
        self.tube('SwordFuller',[tuple(a+Vector((0,-.015,0))),tuple(b-axis*.06+Vector((0,-.01,0)))],[.007,.003],'white','hand.R',5)
        parts=self.parts[start:]
        self.parts=self.parts[:start]
        bpy.ops.object.select_all(action='DESELECT')
        for obj in parts: obj.select_set(True)
        bpy.context.view_layer.objects.active=parts[0]
        bpy.ops.object.join()
        sword=bpy.context.object
        sword.name=name
        self.weapon_objects.append(sword)
        sword.select_set(False)

    def make_palette(self,temp):
        image=bpy.data.images.new(self.spec['id']+'_palette',width=256,height=256,alpha=False)
        pixels=[]
        for y in range(256):
            for x in range(256):
                ci=(y//16)*16+x//16
                c=self.colors[ci] if ci<len(self.colors) else self.colors[0]
                pixels.extend((*c,1))
        image.pixels=pixels
        image.filepath_raw=str(temp / (self.spec['id']+'_palette.png'))
        image.file_format='PNG'
        image.save()
        image.pack()
        self.image_node.image=image

    def normalize_height(self):
        coordinates=[(obj.matrix_world @ vertex.co).z for obj in self.parts for vertex in obj.data.vertices]
        min_z,max_z=min(coordinates),max(coordinates)
        self.rig_scale=self.height/(max_z-min_z)
        self.rig_offset=min_z*self.rig_scale
        for obj in self.parts+self.weapon_objects:
            obj.location.z-=min_z
            obj.location *= self.rig_scale
            for vertex in obj.data.vertices: vertex.co *= self.rig_scale

    def skeleton(self):
        h=self.height*self.rig_scale
        width=float(self.spec.get('details',{}).get('body_width',1))
        data=bpy.data.armatures.new('Humanoid')
        arm=bpy.data.objects.new('Armature',data)
        bpy.context.collection.objects.link(arm)
        bpy.context.view_layer.objects.active=arm
        arm.select_set(True)
        bpy.ops.object.mode_set(mode='EDIT')
        definitions=[('root',(0,0,0),(0,0,.1*h),None,False),
            ('hips',(0,0,.37*h),(0,0,.44*h),'root',False),
            ('spine',(0,0,.44*h),(0,0,.51*h),'hips',True),
            ('chest',(0,0,.51*h),(0,0,.60*h),'spine',True),
            ('neck',(0,0,.60*h),(0,0,.65*h),'chest',True),
            ('head',(0,0,.65*h),(0,0,.94*h),'neck',True)]
        for s,suffix in ((-1,'.L'),(1,'.R')):
            shoulder=(s*.155*h*width,0,.587*h);elbow=(s*.235*h*width,0,.492*h);hand=(s*.292*h*width,-.005*h,.395*h)
            definitions.extend([
                ('shoulder'+suffix,(0,0,.587*h),shoulder,'chest',False),
                ('upper_arm'+suffix,shoulder,elbow,'shoulder'+suffix,True),
                ('lower_arm'+suffix,elbow,hand,'upper_arm'+suffix,True),
                ('hand'+suffix,hand,(s*.296*h*width,-.005*h,.351*h),'lower_arm'+suffix,True),
                ('upper_leg'+suffix,(s*.067*h,0,.37*h),(s*.067*h,-.006*h,.218*h),'hips',False),
                ('lower_leg'+suffix,(s*.067*h,-.006*h,.218*h),(s*.067*h,0,.066*h),'upper_leg'+suffix,True),
                ('foot'+suffix,(s*.067*h,0,.066*h),(s*.067*h,-.07*h,.034*h),'lower_leg'+suffix,True)])
        for name,head,tail,parent,connected in definitions:
            bone=data.edit_bones.new(name)
            offset=self.rig_offset if name!='root' else 0
            bone.head=(head[0],head[1],head[2]-offset)
            bone.tail=(tail[0],tail[1],tail[2]-offset)
            if parent:
                bone.parent=data.edit_bones[parent];bone.use_connect=connected
        bpy.ops.object.mode_set(mode='OBJECT')
        arm.select_set(False)
        self.armature=arm
        return arm

    def finish_mesh(self):
        bpy.ops.object.select_all(action='DESELECT')
        for obj in self.parts: obj.select_set(True)
        bpy.context.view_layer.objects.active=self.parts[0]
        bpy.ops.object.join()
        body=bpy.context.object
        body.name=self.spec.get('name',self.spec['id'])
        # Root, mesh and rig have identity transforms; origin remains feet center.
        bpy.context.scene.cursor.location=(0,0,0)
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        body.select_set(False)
        for obj in [body]+self.weapon_objects:
            obj.parent=None
            mod=obj.modifiers.new('HumanoidSkin','ARMATURE');mod.object=self.armature
        return body

def animate(builder,clips):
    arm=builder.armature
    arm.animation_data_create()
    h=builder.height*builder.rig_scale
    for name,meta in clips.items():
        action=bpy.data.actions.new(name);action.use_fake_user=True
        arm.animation_data.action=action
        ticks=round(meta['images']/meta['ips']*70)
        # Curves are authored at exact 70fps, common to 10 and 14ips.
        for frame in range(ticks+1):
            t=frame/ticks
            w=math.sin(math.tau*t)
            c=math.cos(math.tau*t)
            for pb in arm.pose.bones:
                pb.rotation_mode='XYZ';pb.rotation_euler=(0,0,0);pb.location=(0,0,0)
            def rot(bone,x=0,y=0,z=0): arm.pose.bones[bone].rotation_euler=(x,y,z)
            # Bring A-pose arms slightly inward during default clips.
            rot('upper_arm.L',z=-.30);rot('upper_arm.R',z=.30)
            rot('lower_arm.L',x=-.1);rot('lower_arm.R',x=-.1)
            if name=='repos':
                arm.pose.bones['hips'].location.y=.005*h*w
                rot('chest',x=.015*w,z=.017*w)
                rot('head',x=-.013*w,z=-.02*w)
                rot('upper_arm.L',x=.015*w,z=-.3);rot('upper_arm.R',x=-.015*w,z=.3)
            elif name in ('marche','course'):
                amp=.43 if name=='marche' else .70
                rot('upper_leg.L',x=amp*w);rot('upper_leg.R',x=-amp*w)
                rot('lower_leg.L',x=-max(0,-w)*.65);rot('lower_leg.R',x=-max(0,w)*.65)
                rot('foot.L',x=.15*w);rot('foot.R',x=-.15*w)
                rot('upper_arm.L',x=-amp*.65*w,z=-.30);rot('upper_arm.R',x=amp*.65*w,z=.30)
                rot('chest',x=.04 if name=='marche' else .16,z=.04*w)
                arm.pose.bones['hips'].location.y=.015*h*(1-math.cos(4*math.pi*t))
            elif name=='parle':
                rot('head',x=.05*w,z=.03*c)
                rot('upper_arm.L',x=-.22+.08*w,z=-.6)
                rot('lower_arm.L',x=-.5+.12*w)
                rot('hand.L',z=.12*w)
                rot('chest',z=.026*w)
            elif name=='attaque':
                sweep=math.sin(math.pi*(t-.25))
                rot('chest',z=.55*sweep)
                rot('upper_arm.R',x=-.95,z=-.5+1.65*t,y=.3)
                rot('lower_arm.R',x=-.35)
                rot('hand.R',y=.1,z=-.4*sweep)
                rot('upper_arm.L',x=-.4,z=-.45)
            elif name=='charge':
                release=max(0,(t-.70)/.30)
                rot('upper_arm.R',x=-.50-1.10*release,z=.08)
                rot('lower_arm.R',x=-.90+.60*release)
                rot('upper_arm.L',x=-.40-.45*release,z=-.55)
                rot('lower_arm.L',x=-.65)
                rot('chest',x=-.05+.12*release)
                rot('head',x=.045)
            elif name=='degats':
                shock=math.sin(math.pi*t)
                rot('chest',x=-.28*shock)
                rot('head',x=-.12*shock)
                rot('upper_arm.L',x=.25*shock,z=-.3-.15*shock)
                rot('upper_arm.R',x=.25*shock,z=.3+.15*shock)
                rot('upper_leg.L',x=.17*shock)
            elif name=='mort':
                fall=min(1,t/.75)
                # Actual terminal prone pose and vertical-only root movement.
                rot('hips',x=-math.pi/2*fall)
                arm.pose.bones['hips'].location.y=-.198*h*fall
                rot('head',x=.1*fall)
                rot('upper_arm.L',z=-.3-.3*fall);rot('upper_arm.R',z=.3+.3*fall)
            # Salvaged weapons stand upright in rest; orient the hand so their
            # actual blade sweeps the front sector and charge fires along +Z glTF.
            weapon=builder.spec.get('weapon')
            if weapon and name in ('attaque','charge'):
                bpy.context.view_layer.update()
                hand=arm.pose.bones['hand.R']
                rest_axis=Vector((0,0,1)) if isinstance(weapon,dict) and weapon.get('profile') else Vector((.46,0,-.82)).normalized()
                current=(hand.matrix.to_quaternion() @ hand.bone.matrix_local.to_quaternion().inverted()) @ rest_axis
                if name=='attaque':
                    angle=math.pi/2-math.pi*min(t,.75)
                    target=Vector((math.sin(angle),-math.cos(angle),.025)).normalized()
                else:
                    release=max(0,(t-.70)/.30)
                    target=Vector((0,-release,1-release)).normalized()
                correction=current.rotation_difference(target)
                hand.matrix=Matrix.LocRotScale(hand.matrix.translation,correction @ hand.matrix.to_quaternion(),hand.matrix.to_scale())
                bpy.context.view_layer.update()
            for pb in arm.pose.bones:
                pb.keyframe_insert('rotation_euler',frame=frame)
                if pb.name=='hips': pb.keyframe_insert('location',frame=frame)
        for fc in action.fcurves:
            for kp in fc.keyframe_points: kp.interpolation='LINEAR'
    arm.animation_data.action=bpy.data.actions.get('repos')
    bpy.context.scene.frame_set(0)

def render_portrait(builder,outpath,temp):
    h=builder.height
    scene=bpy.context.scene
    scene.render.engine='CYCLES'
    scene.cycles.samples=64
    scene.cycles.use_denoising=False
    scene.render.resolution_x=256;scene.render.resolution_y=256;scene.render.resolution_percentage=100
    scene.render.film_transparent=True
    scene.render.image_settings.file_format='PNG'
    scene.render.image_settings.color_mode='RGBA'
    scene.view_settings.view_transform='Standard'
    scene.view_settings.look='Medium High Contrast'
    scene.world.color=(.25,.25,.25)
    species=builder.spec.get('species','human')
    center=.66 if species=='ball' else .75 if species=='skull' else .86 if species=='rabbit' else .79
    framing=.72 if species=='ball' else .75 if species=='rabbit' else .55 if species=='skull' else .51
    # Reference hats need more headroom than the default neutral bust.
    if builder.spec['id']=='knight_feline': center,framing=.88,.70
    elif builder.spec['id']=='police_golem': center,framing=.89,.73
    target=Vector((0,0,center*h*builder.rig_scale-builder.rig_offset))
    camera_data=bpy.data.cameras.new('PortraitCamera')
    camera=bpy.data.objects.new('PortraitCamera',camera_data);scene.collection.objects.link(camera)
    camera.location=(0,-4*h,.84*h)
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    camera_data.type='ORTHO';camera_data.ortho_scale=framing*h*builder.rig_scale
    scene.camera=camera
    lights=[]
    for name,location,power,size in [('Key',(-2*h,-3*h,4*h),650,3*h),('Fill',(3*h,-2*h,2*h),350,3*h),('Rim',(0,2*h,3*h),450,2*h)]:
        data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size
        obj=bpy.data.objects.new(name,data);scene.collection.objects.link(obj);obj.location=location
        obj.rotation_euler=(Vector((0,0,.6*h))-obj.location).to_track_quat('-Z','Y').to_euler()
        lights.append(obj)
    scene.render.filepath=str(outpath)
    bpy.ops.render.render(write_still=True)
    # Review render is outside shipped models; genuine geometry in three-quarter view.
    camera.location=(2.1*h,-4*h,1.7*h);target=Vector((0,0,.49*h))
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    camera_data.ortho_scale=1.29*h
    scene.render.resolution_x=384;scene.render.resolution_y=512
    scene.render.filepath=str(temp/(builder.spec['id']+'_preview.png'))
    bpy.ops.render.render(write_still=True)
    for obj in lights+[camera]: bpy.data.objects.remove(obj,do_unlink=True)

def generate(spec,output_dir,render=True):
    output_dir=Path(output_dir);output_dir.mkdir(parents=True,exist_ok=True)
    temp=Path(os.environ.get('SUKASUKA_PREVIEW_DIR',str(Path(tempfile.gettempdir())/'sukasuka3d')));temp.mkdir(parents=True,exist_ok=True)
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions): bpy.data.actions.remove(action)
    scene=bpy.context.scene;scene.render.fps=70;scene.render.fps_base=1
    scene.frame_start=0;scene.frame_end=140
    builder=Builder(spec)
    if not spec.get('custom_base',False):
        builder.head();builder.hair();builder.body()
    hook=spec.get('geometry_hook')
    if isinstance(hook,str):
        module,function=hook.rsplit('.',1)
        if str(Path(__file__).parent) not in sys.path: sys.path.insert(0,str(Path(__file__).parent))
        hook=getattr(importlib.import_module(module),function)
    if not (spec.get('weapon') and isinstance(spec['weapon'],dict) and spec['weapon'].get('profile') and callable(hook)):
        builder.weapon()
    if callable(hook): hook(builder)
    if builder.weapon_objects:
        bpy.ops.object.select_all(action='DESELECT')
        for obj in builder.weapon_objects: obj.select_set(True)
        bpy.context.view_layer.objects.active=builder.weapon_objects[0]
        bpy.ops.object.join()
        sword=bpy.context.object
        weapon=spec.get('weapon') or {}
        sword.name=weapon.get('name','Seniolis' if spec['id']=='chtholly' else 'Weapon') if isinstance(weapon,dict) else str(weapon)
        builder.weapon_objects=[sword]
        sword.select_set(False)
    builder.normalize_height()
    builder.skeleton()
    body=builder.finish_mesh()
    # Keep mobile draw/triangle budgets even when a reference adds complex locks.
    budget=15000 if spec['id']=='chtholly' else 12000 if spec.get('kind') in ('combat','player','playable','hero') else 8000
    weapon_tri=sum(sum(len(p.vertices)-2 for p in obj.data.polygons) for obj in builder.weapon_objects)
    body_tri=sum(len(p.vertices)-2 for p in body.data.polygons)
    if body_tri+weapon_tri>budget:
        bpy.context.view_layer.objects.active=body
        dec=body.modifiers.new('MobileTriangleBudget','DECIMATE')
        dec.ratio=max(.05,(budget-weapon_tri)*.97/body_tri)
        dec.use_collapse_triangulate=True
        bpy.ops.object.modifier_apply(modifier=dec.name)
    builder.make_palette(temp)
    clips=COMBAT if spec.get('kind') in ('combat','player','playable','hero') else NPC
    animate(builder,clips)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [body,builder.armature]+builder.weapon_objects: obj.select_set(True)
    bpy.context.view_layer.objects.active=builder.armature
    glb=output_dir/(spec['id']+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(glb),export_format='GLB',use_selection=True,
        export_yup=True,export_apply=True,export_texcoords=True,export_normals=True,
        export_materials='EXPORT',export_cameras=False,export_lights=False,
        export_animations=True,export_animation_mode='ACTIONS',export_frame_range=False,
        export_force_sampling=True,export_frame_step=1,export_skins=True,
        export_all_influences=False,export_def_bones=True,export_morph=False,
        export_draco_mesh_compression_enable=False,export_optimize_animation_size=True)
    metadata={'version':1,'modele':glb.name,'hauteur_m':builder.height,'usage':'combat' if clips is COMBAT else 'npc','animations':clips}
    (output_dir/(spec['id']+'.anim.json')).write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n')
    if render: render_portrait(builder,output_dir/(spec['id']+'_portrait.png'),temp)
    tris=sum(sum(len(p.vertices)-2 for p in obj.data.polygons) for obj in [body]+builder.weapon_objects)
    result={'id':spec['id'],'triangles':tris,'bones':len(builder.armature.data.bones),
            'materials':1,'glb_bytes':glb.stat().st_size,'animations':list(clips),
            'height_m':builder.height,'usage':'combat' if clips is COMBAT else 'npc','outputs':[str(glb)]}
    (temp/(spec['id']+'_validation.json')).write_text(json.dumps(result,indent=2)+'\n')
    print('SUKASUKA_RESULT '+json.dumps(result))
    return result

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--specs',required=True)
    parser.add_argument('--output',required=True)
    parser.add_argument('--only',default='')
    parser.add_argument('--no-render',action='store_true')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    specs=json.loads(Path(args.specs).read_text())
    if isinstance(specs,dict): specs=specs.get('characters',[specs])
    for spec in specs:
        if args.only and spec['id'] not in args.only.split(','): continue
        generate(spec,Path(args.output)/spec['id'],not args.no_render)

if __name__=='__main__': main()
