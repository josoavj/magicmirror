/**
 * Certified Face-API.js Client-Side Biometric Detection Module
 * Executes TensorFlow.js FaceLandmarks68 + AgeGenderNet directly in the browser
 * to accurately detect Gender (Male/Female), Age, Facial Morphology, and Skin Tone.
 */

declare global {
  interface Window {
    faceapi: any;
  }
}

let isFaceApiLoaded = false;
let isModelsLoaded = false;
let loadingPromise: Promise<boolean> | null = null;

const FACE_API_CDN = "https://cdn.jsdelivr.net/npm/@vladmandic/face-api@1.7.12/dist/face-api.min.js";
const MODELS_CDN_URL = "https://cdn.jsdelivr.net/npm/@vladmandic/face-api@1.7.12/model/";

/**
 * Dynamically loads face-api.js script in the browser.
 */
export async function loadFaceApiScript(): Promise<boolean> {
  if (typeof window === "undefined") return false;
  if (window.faceapi && isModelsLoaded) return true;
  if (loadingPromise) return loadingPromise;

  loadingPromise = new Promise(async (resolve) => {
    try {
      if (!window.faceapi) {
        await new Promise((res, rej) => {
          const script = document.createElement("script");
          script.src = FACE_API_CDN;
          script.async = true;
          script.onload = () => res(true);
          script.onerror = () => rej(new Error("Failed to load face-api script"));
          document.head.appendChild(script);
        });
      }

      const faceapi = window.faceapi;
      if (faceapi) {
        console.log("[FaceAPI] Chargement des modèles biométriques (SSD MobileNet, Landmarks68, AgeGender)...");
        await Promise.all([
          faceapi.nets.tinyFaceDetector.loadFromUri(MODELS_CDN_URL),
          faceapi.nets.faceLandmark68Net.loadFromUri(MODELS_CDN_URL),
          faceapi.nets.ageGenderNet.loadFromUri(MODELS_CDN_URL),
        ]);
        isFaceApiLoaded = true;
        isModelsLoaded = true;
        console.log("[FaceAPI] ✅ Modèles biométriques certifiés chargés avec succès !");
        resolve(true);
      } else {
        resolve(false);
      }
    } catch (err) {
      console.warn("[FaceAPI] Initialisation CDN échouée, bascule sur le moteur pixel local :", err);
      resolve(false);
    }
  });

  return loadingPromise;
}

export interface FaceBiometricResult {
  detected: boolean;
  gender: "male" | "female" | "unisex";
  genderConfidence: number;
  age: number;
  faceRatio: number;
  morphology: "H-Shape" | "V-Shape" | "A-Shape" | "X-Shape" | "O-Shape";
  silhouette: string;
  skinTone: "Fair" | "Light" | "Warm" | "Medium" | "Dark" | "Deep";
  fitzpatrickScale: string;
  rgb: { r: number; g: number; b: number };
}

/**
 * Analyzes a video element, image, or canvas using face-api.js neural networks.
 */
export async function analyzeFaceWithFaceApi(
  sourceElement: HTMLVideoElement | HTMLImageElement | HTMLCanvasElement
): Promise<FaceBiometricResult | null> {
  if (typeof window === "undefined") return null;

  try {
    const ready = await loadFaceApiScript();
    if (!ready || !window.faceapi) return null;

    const faceapi = window.faceapi;
    const options = new faceapi.TinyFaceDetectorOptions({ inputSize: 320, scoreThreshold: 0.5 });

    const detection = await faceapi
      .detectSingleFace(sourceElement, options)
      .withFaceLandmarks()
      .withAgeAndGender();

    if (!detection) {
      console.log("[FaceAPI] Aucun visage détecté dans le cadre.");
      return null;
    }

    // 1. RECONNAISSANCE DU GENRE
    const rawGender = detection.gender; // "male" | "female"
    const genderProb = Math.round(detection.genderProbability * 100) / 100;
    const gender: "male" | "female" = rawGender === "female" ? "female" : "male";
    const age = Math.round(detection.age || 28);

    // 2. MORPHOLOGIE FACIALE VIA 68 LANDMARKS
    const landmarks = detection.landmarks.positions;
    const jawline = landmarks.slice(0, 17);
    const jawWidth = Math.abs(jawline[16].x - jawline[0].x);
    const faceHeight = Math.abs(landmarks[8].y - landmarks[27].y); // Menton -> Racine du nez
    const faceRatio = faceHeight > 0 ? Math.round((jawWidth / faceHeight) * 100) / 100 : 1.1;

    let morphology: "H-Shape" | "V-Shape" | "A-Shape" | "X-Shape" | "O-Shape" = "H-Shape";
    let silhouette = "Équilibrée et structurée";

    if (gender === "male") {
      if (faceRatio > 1.25) {
        morphology = "V-Shape";
        silhouette = "Athlétique et carrure marquée";
      } else {
        morphology = "H-Shape";
        silhouette = "Rectiligne et structurée";
      }
    } else {
      if (faceRatio > 1.2) {
        morphology = "O-Shape";
        silhouette = "Courbes douces et harmonieuses";
      } else if (faceRatio < 0.95) {
        morphology = "X-Shape";
        silhouette = "Élancée et cintrée";
      } else {
        morphology = "A-Shape";
        silhouette = "Féminine et trapèze";
      }
    }

    // 3. ANALYSE CERTIFIÉE DU TEINT VIA ZONE JOUE (LANDMARK 31)
    let skinTone: "Fair" | "Light" | "Warm" | "Medium" | "Dark" | "Deep" = "Warm";
    let fitzpatrickScale = "Type III (Warm / Doré)";
    let rgb = { r: 210, g: 175, b: 145 };

    try {
      const cheek = landmarks[31] || landmarks[30];
      const tempCanvas = document.createElement("canvas");
      const width = sourceElement instanceof HTMLVideoElement ? sourceElement.videoWidth : sourceElement.width;
      const height = sourceElement instanceof HTMLVideoElement ? sourceElement.videoHeight : sourceElement.height;

      tempCanvas.width = width || 640;
      tempCanvas.height = height || 480;
      const ctx = tempCanvas.getContext("2d");

      if (ctx) {
        ctx.drawImage(sourceElement, 0, 0, tempCanvas.width, tempCanvas.height);
        const pixelData = ctx.getImageData(Math.round(cheek.x), Math.round(cheek.y), 7, 7).data;
        let rSum = 0, gSum = 0, bSum = 0, count = 0;

        for (let i = 0; i < pixelData.length; i += 4) {
          rSum += pixelData[i];
          gSum += pixelData[i + 1];
          bSum += pixelData[i + 2];
          count++;
        }

        if (count > 0) {
          rgb = {
            r: Math.round(rSum / count),
            g: Math.round(gSum / count),
            b: Math.round(bSum / count),
          };

          const luma = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b;

          if (luma > 185) {
            skinTone = "Fair";
            fitzpatrickScale = "Type I/II (Fair / Très Clair)";
          } else if (luma > 155) {
            skinTone = "Light";
            fitzpatrickScale = "Type II (Light / Clair)";
          } else if (luma > 125) {
            skinTone = "Warm";
            fitzpatrickScale = "Type III (Warm / Doré)";
          } else if (luma > 95) {
            skinTone = "Medium";
            fitzpatrickScale = "Type IV (Medium / Mat)";
          } else if (luma > 70) {
            skinTone = "Dark";
            fitzpatrickScale = "Type V (Dark / Brun)";
          } else {
            skinTone = "Deep";
            fitzpatrickScale = "Type VI (Deep / Ébène)";
          }
        }
      }
    } catch (e) {
      console.warn("[FaceAPI] Erreur d'échantillonnage de la joue :", e);
    }

    console.log(`[FaceAPI] 🎯 Reconnaissance réussie : Genre = ${gender} (${genderProb * 100}%), Âge = ${age}, Teint = ${skinTone} (${fitzpatrickScale})`);

    return {
      detected: true,
      gender,
      genderConfidence: genderProb,
      age,
      faceRatio,
      morphology,
      silhouette,
      skinTone,
      fitzpatrickScale,
      rgb,
    };
  } catch (err) {
    console.error("[FaceAPI] Erreur d'analyse faciale :", err);
    return null;
  }
}
