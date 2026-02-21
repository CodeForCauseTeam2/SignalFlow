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

  const firstHand = results.landmarks[0];
  const gesture = classifyGesture(firstHand);

  return JSON.stringify({
    landmarks: results.landmarks,
    handedness: results.handednesses,
    gesture,
  });
};

function fingerUp(lm, tip, pip) {
  // y increases downward in image coords
  return lm[tip].y < lm[pip].y;
}

// Very rough thumb-up detector: thumb tip is above thumb IP joint
function thumbUp(lm) {
  return lm[4].y < lm[3].y;
}

function classifyGesture(lm) {
  const indexUp = fingerUp(lm, 8, 6);
  const middleUp = fingerUp(lm, 12, 10);
  const ringUp = fingerUp(lm, 16, 14);
  const pinkyUp = fingerUp(lm, 20, 18);
  const tUp = thumbUp(lm);

  const upCount = [indexUp, middleUp, ringUp, pinkyUp].filter(Boolean).length;

  // FIST: no fingers up (thumb can vary)
  if (upCount === 0 && !indexUp && !middleUp && !ringUp && !pinkyUp) {
    return "FIST";
  }

  // OPEN_PALM: all four fingers up
  if (upCount === 4) {
    return "OPEN_PALM";
  }

  // POINT: only index finger up
  if (indexUp && !middleUp && !ringUp && !pinkyUp) {
    return "POINT";
  }

  // THUMB_UP: thumb up + other fingers down
  if (tUp && !indexUp && !middleUp && !ringUp && !pinkyUp) {
    return "THUMB_UP";
  }


  //my edits -a.a
  //PEACE: index + middle up, others down
  if (indexUp && middleUp && !ringUp && !pinkyUp) {
    return "PEACE";
  }

  // ROCK SIGN (index + pinky)
  if (indexUp && !middleUp && !ringUp && pinkyUp) {
    return "ROCK";
  }

  // OK SIGN (thumb + index touching)
  if (middleUp && ringUp && pinkyUp && !indexUp && !tUp) {
    return "OK";
  }

  // THUMB UP
  if (tUp && !indexUp && !middleUp && !ringUp && !pinkyUp) {
    return "THUMB_UP";
  }

  // POINT
  if (indexUp && !middleUp && !ringUp && !pinkyUp) {
    return "POINT";
  }


  return "UNKNOWN";
}
