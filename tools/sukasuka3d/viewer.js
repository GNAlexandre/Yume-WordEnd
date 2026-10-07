import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

const entries = JSON.parse(document.getElementById('models').textContent);
const canvas = document.getElementById('canvas');
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.setClearColor('#dbe3eb');
const scene = new THREE.Scene();
scene.add(new THREE.HemisphereLight(0xffffff, 0x747a89, 2.2));
const light = new THREE.DirectionalLight(0xffecd9, 3);
light.position.set(3, 6, 5);
scene.add(light);
const camera = new THREE.PerspectiveCamera(36, 1, 0.01, 100);
const controls = new OrbitControls(camera, canvas);
controls.enableDamping = true;
const grid = new THREE.GridHelper(4, 16, 0x8d9bab, 0xbcc7d3);
scene.add(grid);
const loader = new GLTFLoader();
const clock = new THREE.Clock();
const person = document.getElementById('person');
const animation = document.getElementById('animation');
const pause = document.getElementById('pause');
let model, mixer, clips = [], skeleton, ticket = 0, playing = true;
for (const entry of entries) {
  person.add(new Option(entry.name, entry.id));
}
person.value = 'chtholly';
function dispose(object) {
  const geometries = new Set(), materials = new Set(), textures = new Set();
  object.traverse(o => {
    if (o.geometry) geometries.add(o.geometry);
    for (const material of (Array.isArray(o.material) ? o.material : o.material ? [o.material] : [])) {
      materials.add(material);
      for (const value of Object.values(material)) if (value?.isTexture) textures.add(value);
    }
  });
  for (const texture of textures) texture.dispose();
  for (const material of materials) material.dispose();
  for (const geometry of geometries) geometry.dispose();
}
function release() {
  if (!model) return;
  mixer?.stopAllAction();
  mixer?.uncacheRoot(model);
  scene.remove(model);
  dispose(model);
  if (skeleton) {
    scene.remove(skeleton);
    skeleton.dispose();
    skeleton = null;
  }
}
function selectAnimation() {
  mixer.stopAllAction();
  const clip = clips.find(c => c.name === animation.value);
  if (!clip) return;
  const action = mixer.clipAction(clip);
  action.setLoop(['repos', 'marche', 'course', 'parle'].includes(clip.name) ? THREE.LoopRepeat : THREE.LoopOnce, Infinity);
  action.clampWhenFinished = true;
  action.reset().play();
  mixer.update(0);
}
async function load() {
  const serial = ++ticket;
  const entry = entries.find(e => e.id === person.value);
  document.getElementById('info').textContent = 'Chargement…';
  const data = Uint8Array.from(atob(entry.glb), c => c.charCodeAt(0)).buffer;
  try {
    const gltf = await loader.parseAsync(data, '');
    if (serial !== ticket) {
      dispose(gltf.scene);
      return;
    }
    release();
    model = gltf.scene;
    model.traverse(o => {
      if (o.material) o.material.wireframe = document.getElementById('wire').checked;
    });
    scene.add(model);
    mixer = new THREE.AnimationMixer(model);
    clips = gltf.animations;
    animation.replaceChildren(...clips.map(c => new Option(c.name, c.name)));
    animation.value = 'repos';
    selectAnimation();
    skeleton = new THREE.SkeletonHelper(model);
    skeleton.visible = document.getElementById('bones').checked;
    scene.add(skeleton);
    controls.target.set(0, entry.height_m * .48, 0);
    camera.position.set(entry.height_m * 1.15, entry.height_m * .95, entry.height_m * 2.2);
    controls.update();
    document.getElementById('info').textContent = `${entry.name} · ${entry.height_m} m · ${clips.length} animations · références : pages ${entry.reference_pages.join(', ')}`;
    canvas.dataset.model = entry.id;
    canvas.dataset.animations = clips.length;
  } catch (error) {
    document.getElementById('info').textContent = `Erreur : ${error.message}`;
    console.error(error);
  }
}
person.addEventListener('change', load);
animation.addEventListener('change', selectAnimation);
pause.addEventListener('click', () => {
  playing = !playing;
  pause.textContent = playing ? 'Pause' : 'Reprendre';
});
document.getElementById('bones').addEventListener('change', e => {
  if (skeleton) skeleton.visible = e.target.checked;
});
document.getElementById('wire').addEventListener('change', e => {
  model?.traverse(o => {
    if (o.material) o.material.wireframe = e.target.checked;
  });
});
function render() {
  const delta = clock.getDelta();
  const w = canvas.clientWidth, h = canvas.clientHeight;
  if (canvas.width !== Math.round(w * renderer.getPixelRatio()) || canvas.height !== Math.round(h * renderer.getPixelRatio())) {
    renderer.setSize(w, h, false);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
  }
  if (playing && mixer) mixer.update(Math.min(delta, .05));
  controls.update();
  renderer.render(scene, camera);
  requestAnimationFrame(render);
}
load();
render();
