"""Reference-informed costume and salvaged-sword details for seven SukaSuka heroes.

Coordinates: Blender Z up, front -Y. All added costume pieces are real closed
geometry, attached to shared humanoid bones. References are user-supplied pages.
"""
import math


def decorate(b):
    s=b.spec; h=b.height; ident=s['id']; skin=s['skin_color']
    pale=s['white_color']; accent=s['accent_color']; dark=s['outfit_color']
    def mesh(name,vertices,faces,col,bone='chest'):
        return b.mesh(name,[(x*h,y*h,z*h) for x,y,z in vertices],faces,col,bone)
    def ell(name,p,r,c,bone='chest'):
        return b.ellipsoid(name,tuple(v*h for v in p),tuple(v*h for v in r),c,bone)
    def tube(name,points,r,c,bone='chest'):
        return b.tube(name,[tuple(v*h for v in p) for p in points],[r*h]*len(points),c,bone)
    def plate(name,x,z,width,height,col,y=-.107,bone='chest',t=.008):
        return mesh(name,[(x-width/2,y,z-height/2),(x+width/2,y,z-height/2),(x+width/2,y,z+height/2),(x-width/2,y,z+height/2),(x-width/2,y+t,z-height/2),(x+width/2,y+t,z-height/2),(x+width/2,y+t,z+height/2),(x-width/2,y+t,z+height/2)],[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],col,bone)
    def ring(name,z,radius,c,bone='hips',thickness=.004):
        points=[(math.cos(i*math.tau/24)*radius,math.sin(i*math.tau/24)*radius*.65,z) for i in range(25)]
        tube(name,points,thickness,c,bone)
    def diamonds(name,z,col,xcount=5,bone='hips',radius=.16):
        for i in range(xcount):
            x=(i-(xcount-1)/2)*radius*2/xcount
            verts=[(x,-radius*.65-.004,z+.012),(x+.012,-radius*.65-.004,z),(x,-radius*.65-.004,z-.012),(x-.012,-radius*.65-.004,z)]
            mesh(name+str(i),verts,[(0,1,2,3)],col,bone)
    def laces(z0,z1,width,c,bone='chest',y=-.115,n=5):
        for i in range(n):
            z=z0+(z1-z0)*i/n; zn=z0+(z1-z0)*(i+1)/n
            tube('Corset_Lacing_'+str(i),[(-width,y,z),(width,y,zn)],.0028,c,bone)
            tube('Corset_Cross_'+str(i),[(width,y,z),(-width,y,zn)],.0028,c,bone)
    def cape(c,lining,extent=.37,end=.04):
        # Spread toward hem, extending behind body; closed thin shell avoids alpha blend.
        verts=[(-.15,.09,.595),(.15,.09,.595),(.25,.17,end),(-.25,.17,end),(-.15,.105,.595),(.15,.105,.595),(.25,.19,end),(-.25,.19,end)]
        mesh('Reference_Cape_Outer',verts,[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],c,'chest')
        mesh('Reference_Cape_Lining',[(-.14,.087,.58),(.14,.087,.58),(.237,.165,end+.01),(-.237,.165,end+.01)],[(0,1,2,3)],lining,'chest')
    def open_coat(name,end,col):
        # A volumetric curved garment surrounds the white underskirt while leaving
        # its central front visible; a simple flat panel would hide inside it.
        n=20; rings=[(end,.219),( .405,.145),(.585,.156)]
        verts=[]
        for inset in [0,.006]:
            for zz,rr in rings:
                for k in range(n+1):
                    a=-math.pi/2+.25+k*(math.tau-.50)/n
                    verts.append((math.cos(a)*(rr-inset),math.sin(a)*(rr-inset)*.65,zz))
        faces=[]; count=(n+1)*len(rings)
        for surface in range(2):
            off=surface*count
            for j in range(len(rings)-1):
                for k in range(n):
                    a=off+j*(n+1)+k; face=(a,a+1,a+n+2,a+n+1)
                    faces.append(face if surface==0 else tuple(reversed(face)))
        for j in range(len(rings)-1):
            for k in [0,n]:
                a=j*(n+1)+k; c=a+n+1;faces.append((a,c,c+count,a+count))
        for j in [0,len(rings)-1]:
            for k in range(n):
                a=j*(n+1)+k;faces.append((a,a+count,a+count+1,a+1))
        mesh(name,verts,faces,col,'hips')
    if ident=='chtholly':
        # Long white pointed shoulder bib, narrow apron, blue skirt tapes, dark underskirt.
        mesh('Chtholly_Point_Yoke',[(-.15,-.094,.595),(-.055,-.12,.60),(0,-.12,.54),(.055,-.12,.60),(.15,-.094,.595),(.10,-.117,.565),(-.10,-.117,.565)],[(0,1,2,6),(1,3,2),(3,4,5,2)],pale)
        plate('Chtholly_White_Apron',0,.385,.125,.23,pale,y=-.133,bone='hips')
        laces(.44,.525,.028,pale)
        ring('Chtholly_Blue_Hem_Line',.27,.195,accent)
        ring('Chtholly_Blue_Hem_Line2',.285,.189,accent)
        for i in range(12):
            a=i*math.tau/12; da=.1; r=.217; zz=.257
            mesh('Black_Scalloped_Hem'+str(i),[(math.cos(a-da)*r,math.sin(a-da)*r*.65,zz),(math.cos(a+da)*r,math.sin(a+da)*r*.65,zz),(math.cos(a)*r,math.sin(a)*r*.65,zz-.025)],[(0,1,2)],dark,'hips')
        plate('Chtholly_Cream_Hair_Pin',.133,.837,.026,.037,'#DEDCC4',y=-.108,bone='head')
        ell('Chtholly_Chest_Clasp',(0,-.126,.585),(.015,.009,.014),'#4E5161')
        for side in [-1,1]:
            ell('Chtholly_White_Shoulder'+str(side),(side*.16,0,.573),(.046,.07,.038),pale,'upper_arm.'+('L' if side<0 else 'R'))
    elif ident=='willem':
        # His military collar has no suit lapels (p005); suppress the generic
        # uniform lapels before joining, retaining officer buttons and piping.
        import bpy
        for part in list(b.parts):
            if part.name.startswith('Lapel'):
                b.parts.remove(part); bpy.data.objects.remove(part,do_unlink=True)
        plate('Officer_Standing_Collar',0,.618,.105,.033,dark,y=-.063,bone='neck')
        for side in [-1,1]:
            tube('Gold_Collar_Edge'+str(side),[(side*.045,-.084,.629),(side*.045,-.084,.61)],.003,accent,'neck')
            plate('Gold_Shoulder_Board'+str(side),side*.15,.595,.064,.018,accent,y=-.060)
            for j in range(4):ell('Gold_Double_Button'+str(side)+str(j),(side*.033,-.11,.55-j*.033),(.004,.003,.004),accent)
        tube('Officer_Tunic_Piping',[(0,-.11,.602),(0,-.115,.411)],.003,accent)
        ring('Officer_Tunic_Hem',.377,.133,accent)
        ring('Black_Belt',.411,.135,'#141C1D',thickness=.01)
        plate('Gold_Belt_Buckle',0,.411,.032,.019,accent,y=-.117,bone='hips')
    elif ident=='ithea':
        # The orange neck scarf is a primary identity cue, visible from the front
        # as well as its long trailing ends behind her.
        ring('Ithea_Orange_Neck_Scarf',.613,.085,'#E09937',bone='chest',thickness=.018)
        mesh('Ithea_Scarf_Front_Fold',[(-.067,-.101,.605),(.067,-.101,.605),(0,-.114,.548),(-.067,-.086,.605),(.067,-.086,.605),(0,-.098,.548)],[(0,2,1),(3,4,5),(0,1,4,3),(1,2,5,4),(2,0,3,5)],'#D78B32','chest')
        # True hair tufts and slim braids, deliberately no anatomical animal ears.
        for side in [-1,1]:
            mesh('Ithea_Point_Hair_Tuft'+str(side),[(side*.10,.01,.938),(side*.155,.01,.998),(side*.177,.015,.932),(side*.13,.075,.939)],[(0,1,2),(0,3,1),(1,3,2),(0,2,3)],s['hair_color'],'head')
            for j in range(6):
                x=side*(.12+(.007 if j%2 else -.007)); z=.73-j*.027
                ell('Ithea_Braid'+str(side)+'_'+str(j),(x,.10,z),(.018,.018,.028),s['hair_color'],'head')
            tube('Ithea_Long_Scarf'+str(side),[(side*.066,.087,.615),(side*.10,.115,.45),(side*.16,.105,.27)],.025,'#E09937')
            xx=side*.16
            mesh('Scarf_Tip_Diamond'+str(side),[(xx,.08,.283),(xx+.012,.08,.273),(xx,.08,.263),(xx-.012,.08,.273)],[(0,1,2,3)],'#DDC35D','chest')
        for j in range(3):diamonds('Cardigan_Diamond'+str(j),.535-j*.035,'#A36A51',2,'chest',.07)
    elif ident=='nephren':
        open_coat('Nephren_Purple_Open_Coat',.27,dark)
        for side in [-1,1]:
            tube('Nephren_Curled_Twin_Tail'+str(side),[(side*.13,.07,.89),(side*.177,.09,.835),(side*.15,.10,.735),(side*.185,.08,.735),(side*.18,.04,.763)],.035,s['hair_color'],'head')
            tube('Nephren_Gold_Tie'+str(side),[(side*.136,.03,.904),(side*.159,.075,.918)],.005,accent,'head')
            tube('Nephren_Bow'+str(side),[(0,-.12,.576),(side*.019,-.121,.586),(side*.023,-.12,.566),(0,-.12,.576)],.004,accent)
            tube('Nephren_Bow_Tail'+str(side),[(side*.007,-.122,.571),(side*.013,-.122,.548)],.003,accent)
        diamonds('Nephren_White_Triangle_Border',.268,pale,9)
        ring('Nephren_Dark_Skirt_Stripe',.243,.184,'#473832')
        ring('Nephren_Light_Skirt_Stripe',.233,.187,pale)
    elif ident=='nopht':
        for side in [-1,1]:
            tube('Nopht_Red_Suspender'+str(side),[(side*.093,-.055,.584),(side*.072,-.115,.46),(side*.07,-.115,.402)],.011,accent)
            plate('Nopht_Suspender_Buckle'+str(side),side*.07,.41,.017,.014,'#AE9884',y=-.128,bone='hips')
        # Suspender culottes are shorts, with independent trouser legs rather than dress skirt.
        ring('Nopht_Red_Waistband',.405,.15,accent,thickness=.012)
        for side in [-1,1]:
            bone='upper_arm.'+('L' if side<0 else 'R')
            for j in range(3):
                x=side*(.19+j*.013); zz=.531-j*.014
                tube('Nopht_Sleeve_White_Cross'+str(side)+str(j),[(x-.006,-.038,zz+.007),(x+.006,-.038,zz-.007)],.0018,pale,bone)
                tube('Nopht_Sleeve_White_Cross2'+str(side)+str(j),[(x+.006,-.038,zz+.007),(x-.006,-.038,zz-.007)],.0018,pale,bone)
    elif ident=='rhantolk':
        open_coat('Rhantolk_Blue_Long_Coat',.18,dark)
        # Headband follows head shape, blue capelet leaves underdress and lacing visible.
        tube('Rhantolk_White_Headband',[(-.16,.025,.90),(-.14,-.025,.94),(-.075,-.078,.97),(0,-.09,.979),(.075,-.078,.97),(.14,-.025,.94),(.16,.025,.90)],.012,pale,'head')
        plate('Rhantolk_White_Front',0,.49,.10,.16,pale,y=-.112)
        laces(.44,.57,.025,'#534B54',y=-.128,n=6)
        ring('Rhantolk_Black_Waist_Sash',.407,.133,'#343047',thickness=.012)
        tube('Rhantolk_Sash_Tail',[(.01,-.128,.406),(.01,-.13,.337)],.014,'#343047','hips')
        for side in [-1,1]:
            mesh('Rhantolk_Blue_Capelet'+str(side),[(side*.04,-.09,.60),(side*.145,-.06,.60),(side*.205,-.04,.555),(side*.10,-.12,.554)],[(0,1,2,3)],dark)
    elif ident=='lillia':
        cape(pale,dark,end=.055)
        plate('Lillia_White_Breastplate',0,.546,.14,.105,pale,y=-.116)
        ring('Lillia_Gold_Belt',.423,.128,accent,thickness=.008)
        plate('Lillia_Gold_Buckle',0,.421,.039,.022,accent,y=-.122,bone='hips')
        for side in [-1,1]:
            mesh('Lillia_White_Hanging_Panel'+str(side),[(side*.067,-.112,.413),(side*.116,-.105,.412),(side*.143,-.13,.235),(side*.08,-.132,.232)],[(0,1,2,3)],pale,'hips')
            tube('Lillia_Gold_Panel_Edge'+str(side),[(side*.067,-.119,.413),(side*.08,-.139,.232),(side*.143,-.137,.235)],.003,accent,'hips')
            bone='lower_leg.'+('L' if side<0 else 'R')
            plate('Lillia_White_Shin_Plate'+str(side),side*.073,.15,.056,.16,pale,y=-.065,bone=bone)
            ell('Lillia_White_Knee_Guard'+str(side),(side*.073,-.063,.218),(.034,.021,.033),pale,'upper_leg.'+('L' if side<0 else 'R'))
            plate('Lillia_Dark_Knee_Joint'+str(side),side*.073,.202,.041,.017,'#544051',y=-.085,bone=bone)
            plate('Lillia_White_Gauntlet'+str(side),side*.265,.444,.042,.083,pale,y=-.035,bone='lower_arm.'+('L' if side<0 else 'R'))
        tube('Lillia_Gold_Sash',[(0,-.13,.417),(0,-.133,.276)],.017,accent,'hips')
    if s.get('weapon'):
        sword(b,s['weapon'])


def sword(b,w):
    """Closed, extruded blade silhouettes derived from p7/14/23/29/35/39.

    Details are deliberately low-poly simplifications; fracture seams and ornate
    guards identify the individual Dug Weapons. No canonical Lillia sword exists
    in the provided page, and none is invented here.
    """
    h=b.height; x=.30*h; y=-.075*h; z=.39*h; length=w['length']; grip=.17; blade=length-grip-.065
    color=w['color']; guard=w['guard_color']; profile=w['profile']; prefix=w['name']
    def move(o):
        if o in b.parts:b.parts.remove(o)
        b.weapon_objects.append(o)
        return o
    def tube(name,pts,r,c):return move(b.tube(prefix+'_'+name,[(x+a,y+bb,z+cc) for a,bb,cc in pts],[r]*len(pts),c,'hand.R'))
    def mesh(name,v,f,c):return move(b.mesh(prefix+'_'+name,[(x+a,y+bb,z+cc) for a,bb,cc in v],f,c,'hand.R'))
    tube('Grip',[(0,0,-grip/2),(0,0,grip/2)],.018,guard)
    tube('Pommel',[(0,0,-grip/2-.025),(0,0,-grip/2)],.027,color)
    start=grip/2+.04
    # X is blade width, Z longitudinal. Fan triangulation is used on the exterior.
    if profile=='cleaver':
        outline=[(-.04,0),(-.065,blade*.5),(-.145,blade*.86),(-.125,blade),(.125,blade),(.145,blade*.86),(.065,blade*.5),(.04,0)]
    elif profile=='narrow_filigrée':
        outline=[(-.038,0),(-.052,blade*.22),(-.03,blade*.86),(0,blade),(.03,blade*.86),(.052,blade*.22),(.038,0)]
    elif profile=='jagged_broad':
        outline=[(-.13,0),(-.135,blade*.11),(-.105,blade*.22),(-.12,blade*.38),(-.105,blade*.49),(-.085,blade*.68),(0,blade),(.10,blade*.71),(.125,blade*.50),(.10,blade*.33),(.14,blade*.15),(.125,0)]
    elif profile=='wide_pointed':
        outline=[(-.1,0),(-.13,blade*.14),(-.10,blade*.32),(-.085,blade*.66),(0,blade),(.085,blade*.66),(.10,blade*.32),(.13,blade*.14),(.1,0)]
    elif profile=='angular_split_guard':
        outline=[(-.075,0),(-.095,blade*.10),(-.056,blade*.26),(-.035,blade*.79),(0,blade),(.037,blade*.80),(.069,blade*.26),(.087,blade*.08),(.075,0)]
    else:
        outline=[(-.11,0),(-.12,blade*.1),(-.09,blade*.30),(-.063,blade*.77),(0,blade),(.063,blade*.77),(.09,blade*.30),(.12,blade*.10),(.11,0)]
    n=len(outline);th=.013
    verts=[(a,dy,start+c) for dy in [-th,th] for a,c in outline]
    faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh('Segmented_Blade',verts,faces,color)
    # Angular inlaid fractures follow the salvaged-blade design, not regular stripes.
    seam='#D7D5E4' if profile!='cleaver' else '#545143'
    for i in range(4):
        zz=start+blade*(.13+i*.17);ww=.08 if profile!='narrow_filigrée' else .035
        tube('Fracture_'+str(i),[(-ww,-th-.001,zz),(ww*.15,-th-.002,zz+.045),(ww,-th-.001,zz+.07)],.002,seam)
    if profile=='cleaver':
        tube('Crossguard',[(-.08,0,start-.025),(.08,0,start-.025)],.016,guard)
        # Ithea weapon is an axe/cleaver with ornamental central curl.
        tube('Guard_Curl',[(-.027,-.02,start-.015),(-.045,-.02,start+.025),(0,-.02,start+.048),(.045,-.02,start+.025),(.027,-.02,start-.015)],.009,guard)
    else:
        width=.16 if profile!='narrow_filigrée' else .115
        tube('Ornate_Guard',[(-width,0,start+.035),(-width*.6,0,start-.025),(0,0,start), (width*.6,0,start-.025),(width,0,start+.035)],.016,guard)
        for side in [-1,1]:
            tube('Guard_Hook'+str(side),[(side*.045,0,start),(side*width,-.01,start+.095),(side*(width+.025),0,start+.18),(side*.08,0,start+.12)],.009,guard)
        if profile in ['segmented_broad','wide_pointed','narrow_filigrée']:
            for side in [-1,1]:
                tube('Guard_Filigree'+str(side),[(0,-.02,start+.03),(side*.04,-.027,start+.09),(side*.09,-.027,start+.09),(side*.11,-.027,start+.04),(side*.065,-.027,start+.015)],.007,guard)
        if profile=='jagged_broad':
            for side in [-1,1]:
                for k in range(2):
                    mesh('Black_Spike'+str(side)+str(k),[(side*.09,-.02,start+.05+k*.10),(side*.17,-.02,start+.19+k*.10),(side*.14,.02,start+.08+k*.10)],[(0,1,2)],guard)
