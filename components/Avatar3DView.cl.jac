"""Ember's 3D visual presence (avatar track, experimental).

A Three.js viewer for a Ready Player Me GLB model, offered as a third,
opt-in look alongside Circle and Fox - AvatarView.cl.jac owns the toggle
and only ever renders one of the three at a time. Isolated in its own file
and its own effect/cleanup lifecycle so a WebGL problem or a slow/failed
model load can never break the working 2D circle/fox paths: this component
always renders *something* reasonable (a loading message, a plain-language
fallback on error) instead of a blank canvas or an uncaught exception.

Shares AvatarView's `isSpeaking` / `mood` contract so swapping 2D/3D is a
drop-in choice for the parent. The heavy one-time setup (scene, camera,
renderer, loading the model) runs once on mount; mood/isSpeaking changes
afterward only tweak the already-live scene (light color/intensity, idle
rotation speed) rather than tearing down and reloading the 8MB model on
every mood swap or every time the mic starts/stops.

Static-asset note: this expects harry.glb to be served from `/harry.glb`
(project-root `public/harry.glb` - Vite's default static-asset convention,
since `.jac/client` is a Vite dev server under the hood). If it 404s in
your build, MODEL_URL below is the one line to change.
"""

import from react { useEffect, useRef }
import from three { Scene, PerspectiveCamera, WebGLRenderer, AmbientLight, DirectionalLight, Color }
import from "three/examples/jsm/loaders/GLTFLoader.js" { GLTFLoader }

glob MODEL_URL: str = "/harry.glb";

def:pub Avatar3DView(isSpeaking: bool, mood: str = "calm") -> JsxElement {
    has isLoading: bool = True,
        loadError: bool = False;

    mood_key = mood if mood in ["calm", "cheerful", "concerned"] else "calm";

    # Same idle-vs-speaking language as AvatarView's 2D pulse: mood tints
    # the light while idle, speaking always brightens to the same warm
    # amber-ish tone and speeds up the idle rotation - never the reverse,
    # so "is Ember talking?" reads the same way across every mood here too.
    mood_light_colors = {"calm": 0x9fd3e6, "cheerful": 0xffc9a3, "concerned": 0xb8c2d1};
    light_color = 0xffe08a if isSpeaking else mood_light_colors[mood_key];
    light_intensity = 1.6 if isSpeaking else 1.0;
    rotate_speed = 0.03 if isSpeaking else 0.008;

    mountRef = useRef(None);
    lightRef = useRef(None);
    modelRef = useRef(None);
    rotateSpeedRef = useRef(0.008);

    # Mount-once: build the scene, start loading the model, start the
    # render loop. Deliberately empty deps - this must not re-run when
    # mood/isSpeaking change.
    useEffect(lambda {
        el = mountRef.current;
        if not el {
            return lambda { };
        }

        try {
            scene = new(Scene);
            camera = new(PerspectiveCamera, 40, 1, 0.1, 100);
            camera.position.set(0, 1.4, 2.6);

            renderer = new(WebGLRenderer, {"antialias": True, "alpha": True});
            renderer.setSize(280, 320);
            el.appendChild(renderer.domElement);

            ambient = new(AmbientLight, 0xffffff, 0.6);
            scene.add(ambient);

            key_light = new(DirectionalLight, 0x9fd3e6, 1.0);
            key_light.position.set(1, 2, 2);
            scene.add(key_light);
            lightRef.current = key_light;

            loader = new(GLTFLoader);
            loader.load(
                MODEL_URL,
                lambda (gltf: any) {
                    model = gltf.scene;
                    model.position.set(0, -1.1, 0);
                    scene.add(model);
                    modelRef.current = model;
                    isLoading = False;
                },
                None,
                lambda (_err: any) {
                    loadError = True;
                    isLoading = False;
                }
            );

            timer = setInterval(lambda {
                model = modelRef.current;
                if model {
                    model.rotation.y += rotateSpeedRef.current;
                }
                renderer.render(scene, camera);
            }, 33);

            return lambda {
                clearInterval(timer);
                renderer.dispose();
                if el.contains(renderer.domElement) {
                    el.removeChild(renderer.domElement);
                }
            };
        } except Exception as e {
            loadError = True;
            isLoading = False;
            return lambda { };
        }
    }, []);

    # Lightweight reactive effect: nudge the already-live scene, never
    # rebuild it.
    useEffect(lambda {
        light = lightRef.current;
        if light {
            light.color = new(Color, light_color);
            light.intensity = light_intensity;
        }
        rotateSpeedRef.current = rotate_speed;
        return lambda { };
    }, [mood_key, isSpeaking]);

    overlay_text = "The 3D avatar isn't available right now - try Circle or Fox instead." if loadError else "Loading Ember's 3D avatar...";
    overlay_el =
        <div
            style={{
                "position": "absolute",
                "top": "0",
                "left": "0",
                "width": "100%",
                "height": "100%",
                "display": "flex",
                "alignItems": "center",
                "justifyContent": "center",
                "padding": "1rem",
                "boxSizing": "border-box",
                "backgroundColor": "#f4f8f9"
            }}
        >
            <p style={{"margin": "0", "color": "#8a97a0", "fontSize": "1.05rem", "textAlign": "center", "maxWidth": "220px"}}>
                {overlay_text}
            </p>
        </div>;
    overlay = overlay_el if (isLoading or loadError) else None;

    return
        <div
            style={{
                "width": "280px",
                "height": "320px",
                "display": "flex",
                "alignItems": "center",
                "justifyContent": "center",
                "position": "relative"
            }}
        >
            <div ref={mountRef} style={{"width": "100%", "height": "100%"}} />
            {overlay}
        </div>;
}
