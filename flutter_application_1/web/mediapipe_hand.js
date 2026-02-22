// web/mediapipe_hand.js
import {
  HandLandmarker,
  FilesetResolver,
} from "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/vision_bundle.mjs";

let handLandmarker = null;
let videoEl = null;
let running = false;
let lastVideoTime = -1;
let sentence = [];

window.mpHandInit = async function mpHandInit() {
  if (handLandmarker) return true;

  const vision = await FilesetResolver.forVisionTasks(
    "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/wasm",
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

function vecSub(a, b) {
  return { x: a.x - b.x, y: a.y - b.y, z: a.z - b.z };
}

function cross(a, b) {
  return {
    x: a.y * b.z - a.z * b.y,
    y: a.z * b.x - a.x * b.z,
    z: a.x * b.y - a.y * b.x,
  };
}

function palmNormal(lm) {
  const wrist = lm[0];
  const indexMCP = lm[5];
  const pinkyMCP = lm[17];

  const v1 = vecSub(indexMCP, wrist);
  const v2 = vecSub(pinkyMCP, wrist);

  return cross(v1, v2);
}

function fingersTowardCamera(lm) {
  const wristZ = lm[0].z;

  // fingertips of the thumb(4), index(8), middle(12), ring(16), pinky(20)
  const tips = [4, 8, 12, 16, 20];

  // negative z is closer to camera.
  const avgTipZ = tips.reduce((sum, i) => sum + lm[i].z, 0) / tips.length;

  // If tips are noticeably closer than wrist, fingers are toward camera.
  return avgTipZ < wristZ - 0.02; // tweak 0.02 if needed
}

function isPalmFacingCamera(lm) {
  const n = palmNormal(lm);

  // If z component is negative, palm faces camera
  return n.z < 0;
}

function palmFacingCeiling(lm) {
  const n = palmNormal(lm);

  // Screen coords: y increases downward, so "up" (toward ceiling) is negative y.
  // We want the palm normal to point upward.
  return n.y < 0;
}

function isPalmUpFingersToCamera(lm) {
  return palmFacingCeiling(lm) && fingersTowardCamera(lm);
}

function classifyGesture(lm) {
  const indexUp = fingerUp(lm, 8, 6);
  const middleUp = fingerUp(lm, 12, 10);
  const ringUp = fingerUp(lm, 16, 14);
  const pinkyUp = fingerUp(lm, 20, 18);
  const tUp = thumbUp(lm);

  const upCount = [indexUp, middleUp, ringUp, pinkyUp].filter(Boolean).length;

  // Period: no fingers up (thumb can vary)
  if (upCount === 0 && !indexUp && !middleUp && !ringUp && !pinkyUp) {
    sentence = [];
  }

  // OPEN_PALM: all four fingers up
  if (upCount === 4 && tUp) {
    if (!sentence.includes("Hello")) {
      sentence.push("Hello");
    }
  }

  // POINT: only index finger up
  if (indexUp && !middleUp && !ringUp && !pinkyUp) {
    if (!sentence.includes("You")) {
      sentence.push("You");
    }
  }

  // POINT: only index and middle fingers up
  if (indexUp && middleUp && !ringUp && !pinkyUp) {
    if (!sentence.includes("Name")) {
      sentence.push("Name");
    }
  }

  // I LOVE YOU (ASL): thumb + index + pinky up, middle + ring down
  if (tUp && indexUp && !middleUp && !ringUp && pinkyUp) {
    if (!sentence.includes("I love you")) {
      sentence.push("I love you");
    }
  }

  if (isPalmUpFingersToCamera(lm)) {
    if (!sentence.includes("What")) {
      sentence.push("What");
    }
  }
  return sentence.join(" ");
}
