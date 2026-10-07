"""Costume details for reference-inventoried NPCs, built as genuine 3D meshes.

The user-supplied model sheets are the source. Heights and low-poly detail
simplifications are inferred, as documented individually in humanoids.json.
Coordinate system: Blender Z up, facing -Y; dimensions below are fractions of
the reference height. No images or flat sprite planes represent the characters.
"""
import math


def decorate(b):
    s = b.spec
    if s['id'] not in {
        'tiat', 'pannibal', 'collon', 'lakhesh', 'nygglatho', 'almaria',
        'souwong_young', 'souwong_sage', 'elq', 'almita', 'sarya',
        'willemia', 'ecluecla', 'jorget', 'tilfey', 'bitora', 'illustote',
        'rinsha', 'phyr', 'kaiya',
    }:
        return
    h = b.height
    d = s.get('details', {})
    f = set(s.get('features', []))
    pale = s['white_color']
    dark = s['outfit_color']
    accent = s['accent_color']
    hair = s['hair_color']

    def ell(name, p, r, color, bone='chest', segments=12, rings=8):
        return b.ellipsoid(name, tuple(v*h for v in p), tuple(v*h for v in r), color, bone, segments=segments, rings=rings)

    def tube(name, points, radius, color, bone='chest'):
        return b.tube(name, [tuple(v*h for v in p) for p in points],
                      [radius*h]*len(points), color, bone)

    def shell(name, verts, color, bone='chest', thickness=.006):
        n = len(verts)
        back = [(x, y+thickness, z) for x, y, z in verts]
        faces = [tuple(range(n)), tuple(range(2*n-1, n-1, -1))]
        faces += [(i, (i+1)%n, (i+1)%n+n, i+n) for i in range(n)]
        return b.mesh(name, [(x*h,y*h,z*h) for x,y,z in verts+back], faces, color, bone)

    def plate(name, x, z, w, ht, color, y=-.124, bone='chest'):
        return shell(name, [(x-w/2,y,z-ht/2),(x+w/2,y,z-ht/2),
                            (x+w/2,y,z+ht/2),(x-w/2,y,z+ht/2)], color, bone)

    def skirt_ring(name, z, r, color, radius=.004):
        tube(name, [(math.cos(i*math.tau/24)*r,
                     math.sin(i*math.tau/24)*r*.70,z) for i in range(25)],
             radius, color, 'hips')

    def laces(prefix, z0, z1, width, color, y=-.139, n=4):
        for i in range(n):
            za = z0+(z1-z0)*i/n
            zb = z0+(z1-z0)*(i+1)/n
            tube(prefix+'_a_'+str(i), [(-width,y,za),(width,y,zb)], .0023, color)
            tube(prefix+'_b_'+str(i), [(width,y,za),(-width,y,zb)], .0023, color)

    # Open front vests have separate left and right lapels; they change the
    # garment's silhouette and leave the light underlying blouse visible.
    if 'vest' in f:
        vc = d.get('vest_color', accent)
        for sign in (-1,1):
            shell('Reference_Vest_'+str(sign),
                  [(sign*.04,-.105,.598),(sign*.145,-.074,.592),
                   (sign*.13,-.112,.438),(sign*.045,-.126,.435)], vc)
            tube('Reference_Vest_Edge_'+str(sign),
                 [(sign*.04,-.113,.596),(sign*.045,-.134,.435),
                  (sign*.13,-.120,.438)], .0024, pale)

    if 'side_locks' in d:
        for sign in (-1,1):
            tube('Tiat_Fine_Side_Lock_'+str(sign),
                 [(sign*.134,-.075,.76),(sign*.145,-.11,.69),
                  (sign*.125,-.11,.637)], .013, hair, 'head')

    if 'asymmetric_bangs' in f:
        shell('Pannibal_One_Eye_Bang',
              [(-.16,-.102,.945),(.005,-.15,.944),
               (-.028,-.17,.765),(-.132,-.126,.777)], hair, 'head', .025)

    if 'topknot' in f:
        tube('Reference_Upward_Hair_Tie',
             [(0,.018,.952),(0,.018,.995),(-.023,.012,1.012)],
             .020, hair, 'head')
        ell('Reference_Top_Hair_Band',(0,.018,.979),(.024,.024,.009),accent,'head')

    if 'braid' in f:
        for i in range(11):
            ell('Almaria_Back_Braid_'+str(i),
                ((.009 if i%2 else -.009),.169,.734-i*.031),
                (.025,.021,.026), hair, 'head', segments=8, rings=5)
        for sign in (-1,1):
            ell('Almaria_Braid_Ribbon_'+str(sign),
                (sign*.026,.172,.389),(.035,.008,.020),pale,'head')

    if d.get('hair_curls'):
        for i,sign in enumerate((-1,1)):
            for j in range(2):
                x=sign*(.10+j*.035)
                tube('Nygglatho_Ringlet_'+str(i)+'_'+str(j),
                     [(x,.132,.69),(x+sign*.018,.146,.63),
                      (x-sign*.025,.14,.59),(x,.135,.55),
                      (x+sign*.02,.12,.58)], .017, hair, 'head')

    if d.get('hair_waves'):
        for sign in (-1,1):
            for j in range(2):
                x=sign*(.13+j*.038)
                tube('Elq_Floor_Length_Wave_'+str(sign)+'_'+str(j),
                     [(x,.11,.83),(x+sign*.06,.15,.68),
                      (x+sign*.015,.16,.52),(x+sign*.11,.15,.35),
                      (x+sign*.06,.13,.16),(x+sign*.08,.11,.028)],
                     .038, hair, 'head')

    if 'apron_pockets' in f:
        for sign in (-1,1):
            plate('Almita_Apron_Pocket_'+str(sign),sign*.105,.34,.068,.064,
                  d.get('pocket_color','#B4A397'),y=-.155,bone='hips')

    if 'hoodie_pockets' in f:
        for sign in (-1,1):
            ell('Willemia_Patch_Pocket_'+str(sign),
                (sign*.105,-.14,.353),(.039,.009,.041),accent,'hips')

    if 'bib_pocket' in f:
        plate('Tilfey_Overalls_Bib',0,.512,.125,.134,dark,y=-.128)
        plate('Tilfey_Central_Pocket',0,.497,.069,.039,accent,y=-.139)
        for sign in (-1,1):
            tube('Tilfey_Shoulder_Strap_'+str(sign),
                 [(sign*.067,-.127,.454),(sign*.078,-.094,.593),
                  (sign*.076,.072,.593)], .014,dark)

    if 'lace_up' in f:
        laces('Reference_Cross_Lacing',.471,.559,.024,
              '#3F342C' if s['id']!='collon' else '#BB954B')

    if 'hem_stripes' in f:
        end=d.get('skirt_length',.20)
        for i in range(2):
            skirt_ring('Reference_Hem_Stripe_'+str(i),end+.012+i*.017,
                       .192-i*.005,d.get('trim_color',accent),radius=.0035)

    if 'hem_crosses' in f:
        end=d.get('skirt_length',.20)
        color=d.get('trim_color',pale)
        for i in range(5):
            x=(i-2)*.068
            y=-math.sqrt(max(0,.196**2-x*x))*.70-.004
            tube('Reference_Hem_Cross_A_'+str(i),
                 [(x-.015,y,end+.006),(x+.015,y,end+.040)],.0035,color,'hips')
            tube('Reference_Hem_Cross_B_'+str(i),
                 [(x+.015,y,end+.006),(x-.015,y,end+.040)],.0035,color,'hips')

    if 'apron_stitch' in f:
        for sign in (-1,1):
            for i in range(7):
                plate('Sarya_Apron_Stitch_'+str(sign)+'_'+str(i),
                      sign*.13,.18+i*.028,.006,.014,pale,y=-.155,bone='hips')

    if 'tabard' in f:
        col='#F0EEE9'
        shell('Souwong_Front_Tabard',
              [(-.079,-.13,.575),(.079,-.13,.575),
               (.09,-.151,.167),(-.09,-.151,.167)],col,'chest')
        for sign in (-1,1):
            tube('Souwong_Tabard_Border_'+str(sign),
                 [(sign*.081,-.14,.575),(sign*.092,-.162,.164)],
                 .007,accent)
        if s['id']=='souwong_young':
            circle=[(.064*math.cos(i*math.tau/20),-.167,
                     .232+.064*math.sin(i*math.tau/20)) for i in range(21)]
            tube('Souwong_Blue_Tabard_Emblem',circle,.008,accent)
            tube('Souwong_Emblem_Cross',[(0,-.171,.17),(0,-.171,.322)],.008,accent)
            tube('Souwong_Emblem_Crossbar',[(-.076,-.171,.232),(.076,-.171,.232)],.008,accent)
        else:
            for i in range(4):
                z=.45-i*.064
                tube('Sage_Tabard_Diamond_'+str(i),
                     [(0,-.168,z+.024),(.024,-.168,z),
                      (0,-.168,z-.024),(-.024,-.168,z),(0,-.168,z+.024)],
                     .0028,accent)

    if 'reference_cape' in f:
        # Floor-length white capes and short brown capelets require different
        # silhouettes, rather than the generic fixed-length core cape.
        cc=d.get('cape_color',dark)
        bottom=d.get('cape_bottom',.30)
        width=.245 if bottom<.10 else .195
        shell('Reference_Colored_Cape_Back',
              [(-.155,.093,.604),(.155,.093,.604),
               (width,.19,bottom),(-width,.19,bottom)],cc,'chest',.012)
        for sign in (-1,1):
            shell('Reference_Colored_Cape_Shoulder_'+str(sign),
                  [(sign*.027,-.076,.616),(sign*.147,-.063,.606),
                   (sign*.195,-.030,.554),(sign*.055,-.118,.568)],cc)
            if s['id']=='rinsha':
                tube('Rinsha_Cape_Cream_Border_'+str(sign),
                     [(sign*.027,-.084,.616),(sign*.055,-.126,.568),
                      (sign*.195,-.038,.554)],.004,d.get('trim_color',pale))

    if 'gold_clasp' in f:
        for sign in (-1,1):
            ell('Souwong_Cape_Clasp_'+str(sign),
                (sign*.027,-.131,.60),(.018,.006,.018),'#C5A449')

    if s['id'] in {'nygglatho','kaiya','phyr'}:
        for sign in (-1,1):
            ell('Maid_White_Cuff_'+str(sign),
                (sign*.266,-.004,.436),(.029,.037,.018),pale,
                'lower_arm.'+('L' if sign<0 else 'R'))
        collar=d.get('collar_color',pale)
        for sign in (-1,1):
            shell('Maid_Collar_'+str(sign),
                  [(0,-.122,.623),(sign*.060,-.103,.623),
                   (sign*.045,-.135,.586),(0,-.132,.603)],collar)

    if s['id']=='phyr':
        ell('Phyr_Dark_Nose',(0,-.157,.772),(.018,.016,.011),'#233329','head')
        # Small black fascinator sits off center; the source is not a large
        # white cap. Its crown and brim are solid low-poly geometry.
        if 'reference_mini_hat' in f:
            black=d.get('hat_color','#1C3027')
            ell('Phyr_Mini_Hat_Brim',(-.075,-.026,.985),
                (.083,.060,.012),black,'head',segments=10,rings=4)
            b.cone('Phyr_Mini_Hat_Crown',(-.075*h,-.026*h,.986*h),
                   (-.094*h,-.013*h,1.052*h),.051*h,.045*h,
                   black,'head',vertices=10)
            for sign in (-1,1):
                ell('Phyr_Mini_Hat_Bow_'+str(sign),
                    (-.075+sign*.022,-.079,.992),(.028,.010,.014),
                    black,'head',segments=8,rings=4)
    if 'whiskers' in f:
        ell('Kaiya_Dark_Nose',(0,-.147,.767),(.009,.008,.007),'#292629','head')
        for sign in (-1,1):
            for i in range(3):
                z=.758+i*.012
                tube('Kaiya_Whisker_'+str(sign)+'_'+str(i),
                     [(sign*.07,-.148,z),(sign*.138,-.122,z-.009+i*.006)],
                     .0017,'#3E3430','head')
