// web/mediapipe_hand.js
import { HandLandmarker, FilesetResolver } from
  "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/vision_bundle.mjs";

let handLandmarker = null;
let videoEl = null;
let running = false;
let lastVideoTime = -1;

window.mpHandInit = async function mpHandInit() {
  if (handLandmarker) return true;

  const vision = await FilesetResolver.forVisionTasks(
    "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/wasm"
  );

  handLandmarker = await HandLandmarker.createFromOptions(vision, {
    baseOptions: {
      modelAssetPath:
        "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/latest/hand_landmarker.task",
      delegate: "GPU",
    },
    runningMode: "VIDEO",
    numHands: 2,
  });

  return true;
};

window.mpHandStart = async function mpHandStart() {
  if (!handLandmarker) await window.mpHandInit();

  if (!videoEl) {
    videoEl = document.createElement("video");
    videoEl.setAttribute("playsinline", "");
    videoEl.autoplay = true;
    videoEl.style.display = "none";
    document.body.appendChild(videoEl);
  }

  const stream = await navigator.mediaDevices.getUserMedia({ video: true });
  videoEl.srcObject = stream;

  await new Promise((resolve) => {
    videoEl.onloadeddata = () => resolve(true);
  });

  running = true;
  lastVideoTime = -1;
  return true;
};

window.mpHandStop = function mpHandStop() {
  running = false;
  if (videoEl?.srcObject) {
    for (const t of videoEl.srcObject.getTracks()) t.stop();
    videoEl.srcObject = null;
  }
  return true;
};

window.mpHandDetectOnce = function mpHandDetectOnce() {
  if (!running || !handLandmarker || !videoEl) return null;

  if (videoEl.currentTime === lastVideoTime) return null;
  lastVideoTime = videoEl.currentTime;

  const nowMs = performance.now();
  const results = handLandmarker.detectForVideo(videoEl, nowMs);

  if (!results?.landmarks?.length) return null;

  return JSON.stringify({
    landmarks: results.landmarks,
    handedness: results.handednesses,
  });
};