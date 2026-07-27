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
afterward only tweak the already-live scene (light color/intensity and
mouth morph targets) rather than tearing down and reloading the 8MB model on
every mood swap or every time the mic starts/stops.

Static-asset note: this expects harry.glb to be served from
`/static/harry.glb`. The dev Vite server (`.jac/client/configs/
vite.dev.config.js`) turns off Vite's own `public/` convention
(`publicDir: false`) and instead proxies `/static/*` to the Python
backend, which serves project-root `assets/<name>` for any `/static/<name>`
request regardless of extension - unlike its generic asset route, which
only serves recognized extensions and would silently reject `.glb`. So the
model lives at project-root `assets/harry.glb`, not `public/`. If it 404s
in your build, MODEL_URL below is the one line to change.
"""

import from react { useEffect, useRef }
import from three {
    Scene, PerspectiveCamera, WebGLRenderer, AmbientLight,
    DirectionalLight, Color
}
import from "three/examples/jsm/loaders/GLTFLoader.js" { GLTFLoader }

glob MODEL_URL: str = "/static/harry.glb";

def:pub Avatar3DView(isSpeaking: bool, mood: str = "calm") -> JsxElement {
    has isLoading: bool = True,
        loadError: bool = False;

    mood_key = mood if mood in ["calm", "cheerful", "concerned"] else "calm";

    # Same idle-vs-speaking language as AvatarView's 2D pulse: mood tints
    # the light while idle, speaking always brightens to the same warm
    # amber-ish tone and animates the model's real mouthOpen morph - never the reverse,
    # so "is Ember talking?" reads the same way across every mood here too.
    mood_light_colors = {"calm": 0xf0b06e, "cheerful": 0xffc08a, "concerned": 0xc89066};
    light_color = 0xff9b4a if isSpeaking else mood_light_colors[mood_key];
    light_intensity = 1.6 if isSpeaking else 1.0;

    mountRef = useRef(None);
    lightRef = useRef(None);
    mouthMeshesRef = useRef([]);
    speakingRef = useRef(False);

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
            # Head-and-shoulders framing instead of showing the avatar's
            # full body. Panned down from the old (0, 1.52, 1.1) so the
            # hands/forearms clear the bottom of the 280x320 canvas,
            # with only a small pull-back (1.1 -> 1.25) - a pan changes
            # *which* vertical slice is framed without shrinking the
            # subject the way a bigger dolly-back would.
            camera = new(PerspectiveCamera, 40, 280 / 320, 0.1, 100);
            camera.position.set(0, 1.38, 1.25);
            camera.lookAt(0, 1.38, 0);

            renderer = new(WebGLRenderer, {"antialias": True, "alpha": True});
            renderer.setSize(280, 320);
            el.appendChild(renderer.domElement);

            ambient = new(AmbientLight, 0xffffff, 0.6);
            scene.add(ambient);

            key_light = new(DirectionalLight, 0xf0b06e, 1.0);
            key_light.position.set(1, 2, 2);
            scene.add(key_light);
            lightRef.current = key_light;

            loader = new(GLTFLoader);
            loader.load(
                MODEL_URL,
                lambda (gltf: any) {
                    model = gltf.scene;
                    model.position.set(0, 0, 0);
                    scene.add(model);
                    head = model.getObjectByName("Wolf3D_Head");
                    teeth = model.getObjectByName("Wolf3D_Teeth");
                    mouthMeshesRef.current = [part for part in [head, teeth] if part];
                    isLoading = False;
                },
                None,
                lambda (_err: any) {
                    loadError = True;
                    isLoading = False;
                }
            );

            # Randomized amplitude per tick (rather than a fixed open/close
            # flap) reads as more natural chatter - a real mouth doesn't
            # snap between exactly two positions while talking.
            timer = setInterval(lambda {
                mouth_amount = (0.16 + Math.random() * 0.58) if speakingRef.current else 0.0;
                for raw_mesh in mouthMeshesRef.current {
                    mesh = raw_mesh as any;
                    mouth_index = mesh.morphTargetDictionary["mouthOpen"];
                    mesh.morphTargetInfluences[mouth_index] = mouth_amount;
                }
                renderer.render(scene, camera);
            }, 90);

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
        speakingRef.current = isSpeaking;
        if not isSpeaking {
            for raw_mesh in mouthMeshesRef.current {
                mesh = raw_mesh as any;
                mouth_index = mesh.morphTargetDictionary["mouthOpen"];
                mesh.morphTargetInfluences[mouth_index] = 0.0;
            }
        }
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
                "backgroundColor": "#FFF9EE",
                "border": "1px solid #D9C8AC",
                "borderRadius": "12px"
            }}
        >
            <p style={{"margin": "0", "color": "#6F5D4A", "fontSize": "1.05rem", "textAlign": "center", "maxWidth": "220px"}}>
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
