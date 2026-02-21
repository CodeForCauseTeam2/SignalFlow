// web/mediapipe_hand.js
import vision from "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest";

const { HandLandmarker, FilesetResolver } = vision;

let handLandmarker = null;
let videoEl = null;
let running = false;
let lastVideoTime = -1;

// Expose functions globally so Dart can call them
window.mpHandInit = async function mpHandInit() {
  if (handLandmarker) return true;

  const fileset = await FilesetResolver.forVisionTasks(
    "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/wasm"
  );

  handLandmarker = await HandLandmarker.createFromOptions(fileset, {
    baseOptions: {
      // Official model: hand_landmarker.task
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

// Returns a JSON string of the latest landmarks (or null if none)
window.mpHandDetectOnce = function mpHandDetectOnce() {
  if (!running || !handLandmarker || !videoEl) return null;

  if (videoEl.currentTime === lastVideoTime) return null;
  lastVideoTime = videoEl.currentTime;

  const nowMs = performance.now();
  const results = handLandmarker.detectForVideo(videoEl, nowMs);

  // results.landmarks: array of hands, each has 21 landmarks: {x,y,z}
  if (!results || !results.landmarks || results.landmarks.length === 0) return null;

  return JSON.stringify({
    landmarks: results.landmarks,
    handedness: results.handednesses, // left/right confidence
  });
};