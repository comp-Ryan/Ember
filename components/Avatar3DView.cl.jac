"""Ember's 3D visual presence (avatar track, experimental).

A Three.js viewer for a GLB model, offered as a third, opt-in look alongside
Circle and Fox - AvatarView.cl.jac owns the toggle (and, when 3D is picked,
a second dropdown for which model) and only ever renders one of the three
looks at a time. Isolated in its own file and its own effect/cleanup
lifecycle so a WebGL problem or a slow/failed model load can never break
the working 2D circle/fox paths: this component always renders *something*
reasonable (a loading message, a plain-language fallback on error) instead
of a blank canvas or an uncaught exception.

Two models ship today - Ready Player Me's "Harry" and a Sketchfab "penguin
girl in a plush penguin suit" - each with its own scale, pivot, and rig.
Nothing here is tuned to either one specifically: on load, every model's
Three.js bounding box is measured and used to (1) recenter it and rescale
it to a common height and (2) fit its complete width and height inside the
shared portrait canvas, so a third model dropped into MODEL_CONFIG below
gets the same treatment without hand-tuned camera numbers. Morph targets
are found model-agnostically: Ready Player Me faces get real mood, blink,
and speaking expressions, while an unrigged model gets a restrained
pose-based mood fallback instead of throwing.

Shares AvatarView's `isSpeaking` / `mood` contract so swapping 2D/3D is a
drop-in choice for the parent. The heavy one-time setup (scene, camera,
renderer, loading the model) reruns only when `modelKey` changes; mood/
isSpeaking changes tweak the already-live scene (light color/intensity,
mouth morph targets) rather than tearing down and reloading the model on
every mood swap or every time the mic starts/stops.

Static-asset note: models are expected under `/static/<name>.glb`. The dev
Vite server (`.jac/client/configs/vite.dev.config.js`) turns off Vite's own
`public/` convention (`publicDir: false`) and instead proxies `/static/*`
to the Python backend, which serves project-root `assets/<name>` for any
`/static/<name>` request regardless of extension - unlike its generic asset
route, which only serves recognized extensions and would silently reject
`.glb`. So every model lives at project-root `assets/<name>.glb`, not
`public/`. If one 404s in your build, MODEL_CONFIG below is the one place
to change its URL.
"""

import from react { useEffect, useRef }
import from three {
    Scene, PerspectiveCamera, WebGLRenderer, AmbientLight,
    DirectionalLight, Color, Box3, Vector3
}
import from "three/examples/jsm/loaders/GLTFLoader.js" { GLTFLoader }

glob MODEL_CONFIG: dict = {
    "harry": {"url": "/static/harry.glb", "label": "Harry"},
    "penguin": {"url": "/static/penguin_girl_plush_suit.glb", "label": "Penguin"}
};

# Idle-only breathing pace, same values AvatarView.cl.jac uses for its 2D
# pulse period, so the 3D look's idle "settling" motion paces the same way
# per mood as the other two looks.
glob BREATH_PERIOD: dict = {"calm": 1600, "cheerful": 1300, "concerned": 2200};

def:pub Avatar3DView(isSpeaking: bool, mood: str = "calm", modelKey: str = "harry") -> JsxElement {
    has isLoading: bool = True,
        loadError: bool = False;

    mood_key = mood if mood in ["calm", "cheerful", "concerned"] else "calm";
    model_key = modelKey if modelKey in MODEL_CONFIG else "harry";
    model_url = MODEL_CONFIG[model_key]["url"];
    model_label = MODEL_CONFIG[model_key]["label"];

    # Same idle-vs-speaking language as AvatarView's 2D pulse: mood tints
    # the light while idle, speaking always brightens to the same warm
    # amber-ish tone and animates the model's mouth morph - never the
    # reverse, so "is Ember talking?" reads the same way across every mood.
    mood_light_colors = {"calm": 0xf0b06e, "cheerful": 0xffc08a, "concerned": 0xc89066};
    light_color = 0xff9b4a if isSpeaking else mood_light_colors[mood_key];
    light_intensity = 1.6 if isSpeaking else 1.0;
    breath_period = BREATH_PERIOD[mood_key];

    mountRef = useRef(None);
    lightRef = useRef(None);
    mouthMeshesRef = useRef([]);
    blinkMeshesRef = useRef([]);
    expressionMeshesRef = useRef([]);
    modelRootRef = useRef(None);
    baseScaleRef = useRef(1.0);
    basePositionYRef = useRef(0.0);
    speakingRef = useRef(False);
    moodRef = useRef("calm");
    breathPeriodRef = useRef(1600);
    reduceMotionRef = useRef(False);
    blinkUntilRef = useRef(0);

    # Rebuilds the whole scene when the model changes - swapping models
    # means a fresh bounding box, camera framing, and morph-target scan
    # anyway, so there is nothing worth patching in place.
    useEffect(lambda {
        el = mountRef.current;
        if not el {
            return lambda { };
        }

        try {
            reduceMotion = False;
            if window.matchMedia {
                reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches as bool;
            }
            reduceMotionRef.current = reduceMotion;

            width = el.clientWidth if el.clientWidth else 280;
            height = el.clientHeight if el.clientHeight else 320;

            scene = new(Scene);
            camera = new(PerspectiveCamera, 32, width / height, 0.1, 100);

            renderer = new(WebGLRenderer, {"antialias": True, "alpha": True});
            pixel_ratio = window.devicePixelRatio if window.devicePixelRatio else 1;
            renderer.setPixelRatio(pixel_ratio if pixel_ratio < 2 else 2);
            # updateStyle=False so we control CSS size ourselves below -
            # the canvas's own drawing-buffer resolution (which factors in
            # devicePixelRatio) should not dictate its on-page size. Without
            # this, the canvas falls back to displaying at its raw pixel
            # attributes instead of filling its container, and can visually
            # spill outside the rounded card around it.
            renderer.setSize(width, height, False);
            renderer.domElement.style.width = "100%";
            renderer.domElement.style.height = "100%";
            renderer.domElement.style.display = "block";
            el.appendChild(renderer.domElement);

            # Warm, soft lighting only - no cool/blue tones, matching the
            # rest of Ember's palette.
            ambient = new(AmbientLight, 0xfff4e8, 0.65);
            scene.add(ambient);

            key_light = new(DirectionalLight, 0xf0b06e, 1.0);
            key_light.position.set(1, 2, 2);
            scene.add(key_light);
            lightRef.current = key_light;

            fill_light = new(DirectionalLight, 0xffd9ad, 0.35);
            fill_light.position.set(-1.5, 0.6, 1.5);
            scene.add(fill_light);

            loader = new(GLTFLoader);
            loader.load(
                model_url,
                lambda (gltf: any) {
                    model = gltf.scene;
                    model.updateMatrixWorld(True);

                    if model_key == "harry" {
                        # Preserve Harry's original, proven close portrait.
                        # Skinned Ready Player Me bounds can be stale before
                        # the skeleton updates, which caused the generic fit
                        # path to frame only his legs.
                        model.position.set(0, 0, 0);
                        model.scale.setScalar(1.0);
                        baseScaleRef.current = 1.0;
                        basePositionYRef.current = 0.0;
                        scene.add(model);
                        camera.fov = 40;
                        camera.updateProjectionMatrix();
                        camera.position.set(0, 1.48, 1.25);
                        camera.lookAt(0, 1.48, 0);
                    } else {
                        # Penguin is an unrigged static mesh, so its bounds
                        # are reliable and can drive automatic full fitting.
                        box = new(Box3);
                        box.setFromObject(model);
                        size = new(Vector3);
                        box.getSize(size);

                        size_y = size.y as float;
                        raw_height = size_y if size_y > 0.001 else 1.0;
                        target_height = 1.8;
                        scale_factor = target_height / raw_height;
                        model.scale.setScalar(scale_factor);
                        baseScaleRef.current = scale_factor;

                        model.updateMatrixWorld(True);
                        box.setFromObject(model);
                        center = new(Vector3);
                        box.getCenter(center);
                        model.position.x = (model.position.x as float) - (center.x as float);
                        model.position.z = (model.position.z as float) - (center.z as float);
                        model.position.y = (model.position.y as float) - (box.min.y as float);
                        basePositionYRef.current = model.position.y;
                        scene.add(model);

                        model.updateMatrixWorld(True);
                        box.setFromObject(model);
                        box.getSize(size);
                        box.getCenter(center);
                        total_width_x = size.x as float;
                        total_height_y = size.y as float;
                        total_height = total_height_y if total_height_y > 0.001 else target_height;
                        total_width = total_width_x if total_width_x > 0.001 else total_height * 0.6;
                        total_depth = size.z as float;
                        half_v_fov = ((camera.fov as float) * 3.14159265) / 360;
                        half_h_fov = Math.atan(Math.tan(half_v_fov) * (camera.aspect as float));
                        vertical_distance = (total_height / 2) / Math.tan(half_v_fov);
                        horizontal_distance = (total_width / 2) / Math.tan(half_h_fov);
                        fit_distance = vertical_distance if vertical_distance > horizontal_distance else horizontal_distance;
                        camera_z = (center.z as float) + (total_depth / 2) + (fit_distance * 1.14);
                        camera.position.set(center.x, center.y, camera_z);
                        camera.lookAt(center.x, center.y, center.z);
                    }
                    modelRootRef.current = model;

                    # Morph targets are named per source rig - Ready Player
                    # Me exposes "mouthOpen" on named head/teeth meshes; an
                    # arbitrary Sketchfab model may expose none, some, or
                    # differently-named/differently-cased ones. Scan every
                    # mesh instead of assuming fixed mesh/morph names, so a
                    # model with no matching shapes just quietly gets no
                    # mouth/blink animation instead of throwing.
                    mouth_meshes = [];
                    blink_meshes = [];
                    expression_meshes = [];
                    model.traverse(lambda (mesh_node: any) {
                        morph_dict = mesh_node.morphTargetDictionary if mesh_node.morphTargetDictionary else None;
                        if not morph_dict {
                            return;
                        }
                        for key in Object.keys(morph_dict) {
                            lower = key.lower();
                            if "mouthopen" in lower {
                                mouth_meshes.append({"mesh": mesh_node, "key": key});
                            } elif ("blink" in lower) or ("eyesclosed" in lower) {
                                blink_meshes.append({"mesh": mesh_node, "key": key});
                            }
                            if (
                                ("mouthsmile" in lower) or
                                ("mouthfrown" in lower) or
                                ("cheeksquint" in lower) or
                                ("browinnerup" in lower) or
                                ("browdown" in lower) or
                                ("browouterup" in lower) or
                                ("eyewide" in lower)
                            ) {
                                expression_meshes.append({
                                    "mesh": mesh_node,
                                    "key": key,
                                    "lower": lower
                                });
                            }
                        }
                    });
                    mouthMeshesRef.current = mouth_meshes;
                    blinkMeshesRef.current = blink_meshes;
                    expressionMeshesRef.current = expression_meshes;

                    isLoading = False;
                },
                None,
                lambda (_err: any) {
                    loadError = True;
                    isLoading = False;
                }
            );

            resize_observer = None;
            if window.ResizeObserver {
                resize_observer = new(ResizeObserver, lambda (entries: any) {
                    entry = entries[0];
                    w = entry.contentRect.width;
                    h = entry.contentRect.height;
                    if (w > 0) and (h > 0) {
                        camera.aspect = w / h;
                        camera.updateProjectionMatrix();
                        renderer.setSize(w, h, False);
                    }
                });
                resize_observer.observe(el);
            }

            # Single tick drives mouth chatter, gentle idle breathing/
            # blinking (skipped under prefers-reduced-motion), and the
            # render call.
            timer = setInterval(lambda {
                now = Date.now();

                mouth_amount = (0.16 + Math.random() * 0.58) if speakingRef.current else 0.0;
                for item in mouthMeshesRef.current {
                    mesh = item["mesh"] as any;
                    idx = mesh.morphTargetDictionary[item["key"]];
                    mesh.morphTargetInfluences[idx] = mouth_amount;
                }

                blink_amount = 0.0;
                if now < blinkUntilRef.current {
                    blink_amount = 1.0;
                } elif (
                    (not reduceMotionRef.current) and
                    (not speakingRef.current) and
                    (Math.random() < 0.0035)
                ) {
                    blinkUntilRef.current = now + 140;
                    blink_amount = 1.0;
                }
                for item in blinkMeshesRef.current {
                    mesh = item["mesh"] as any;
                    idx = mesh.morphTargetDictionary[item["key"]];
                    mesh.morphTargetInfluences[idx] = blink_amount;
                }

                # Facial mood for compatible rigs. Speaking uses a separate
                # mouthOpen target, so it layers over these expressions
                # instead of erasing them.
                for item in expressionMeshesRef.current {
                    expression_target = 0.0;
                    expression_name: str = item["lower"] as str;
                    if moodRef.current == "cheerful" {
                        if "mouthsmile" in expression_name {
                            expression_target = 0.5;
                        } elif "cheeksquint" in expression_name {
                            expression_target = 0.16;
                        } elif "browouterup" in expression_name {
                            expression_target = 0.14;
                        }
                    } elif moodRef.current == "concerned" {
                        if "mouthfrown" in expression_name {
                            expression_target = 0.28;
                        } elif "browinnerup" in expression_name {
                            expression_target = 0.34;
                        } elif "browdown" in expression_name {
                            expression_target = 0.12;
                        } elif "eyewide" in expression_name {
                            expression_target = 0.08;
                        }
                    }
                    mesh = item["mesh"] as any;
                    idx = mesh.morphTargetDictionary[item["key"]];
                    current_amount = mesh.morphTargetInfluences[idx];
                    mesh.morphTargetInfluences[idx] = current_amount + ((expression_target - current_amount) * 0.22);
                }

                if modelRootRef.current {
                    breath_amt = 1.0;
                    if (not reduceMotionRef.current) and (not speakingRef.current) {
                        period = breathPeriodRef.current;
                        phase = (now % period) / period;
                        breath_amt = 1.0 + (Math.sin(phase * 2 * 3.14159265) * 0.012);
                    }
                    modelRootRef.current.scale.setScalar(baseScaleRef.current * breath_amt);

                    # Penguin is a single static mesh with no face rig.
                    # A very small whole-character pose gives its moods a
                    # visible non-color cue while keeping the canvas calm.
                    pose_rotation = 0.0;
                    pose_lift = 0.0;
                    if moodRef.current == "cheerful" {
                        pose_rotation = 0.035;
                        pose_lift = 0.012;
                    } elif moodRef.current == "concerned" {
                        pose_rotation = -0.025;
                        pose_lift = -0.006;
                    }
                    modelRootRef.current.rotation.z = (modelRootRef.current.rotation.z as float) + ((pose_rotation - (modelRootRef.current.rotation.z as float)) * 0.08);
                    desired_y = (basePositionYRef.current as float) + pose_lift;
                    modelRootRef.current.position.y = (modelRootRef.current.position.y as float) + ((desired_y - (modelRootRef.current.position.y as float)) * 0.08);
                }

                renderer.render(scene, camera);
            }, 90);

            return lambda {
                clearInterval(timer);
                if resize_observer {
                    resize_observer.disconnect();
                }
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
    }, [model_url]);

    # Lightweight reactive effect: nudge the already-live scene, never
    # rebuild it.
    useEffect(lambda {
        light = lightRef.current;
        if light {
            light.color = new(Color, light_color);
            light.intensity = light_intensity;
        }
        speakingRef.current = isSpeaking;
        moodRef.current = mood_key;
        breathPeriodRef.current = breath_period;
        if not isSpeaking {
            for item in mouthMeshesRef.current {
                mesh = item["mesh"] as any;
                idx = mesh.morphTargetDictionary[item["key"]];
                mesh.morphTargetInfluences[idx] = 0.0;
            }
        }
        return lambda { };
    }, [mood_key, isSpeaking, breath_period]);

    overlay_text = f"The {model_label} avatar isn't available right now - try Circle or Fox instead." if loadError else f"Loading {model_label}...";
    overlay_el =
        <div
            role="status"
            aria-live="polite"
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
                "width": "100%",
                "height": "100%",
                "display": "flex",
                "alignItems": "center",
                "justifyContent": "center",
                "position": "relative",
                "overflow": "hidden",
                "borderRadius": "12px"
            }}
        >
            <div ref={mountRef} style={{"width": "100%", "height": "100%"}} />
            {overlay}
        </div>;
}
