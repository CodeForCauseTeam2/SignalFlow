# ============================================================
# extract_landmarks.py
# This script reads hand gesture images from the Kaggle dataset,
# uses MediaPipe to detect the hand in each image,
# extracts 21 landmark points (x, y, z) = 63 numbers per image,
# then saves everything to a CSV file for model training
# ============================================================

# OpenCV - reads and processes image files
import cv2
# MediaPipe - detects hands and extracts landmark points
import mediapipe as mp
# os - helps us navigate folders and file paths
import os
# csv - lets us write data to a spreadsheet file
import csv
# json - lets us save our gesture labels
import json
# numpy - helps with number operations
import numpy as np

# ── MEDIAPIPE SETUP ──────────────────────────────────────────
# Load the hand detection module from MediaPipe
mp_hands = mp.solutions.hands

# Create our hand detector
# static_image_mode=True because we're processing still images not video
# max_num_hands=1 because we only need to detect one hand at a time
hands = mp_hands.Hands(
    static_image_mode=True,
    max_num_hands=1
)

# ── YOUR 15 GESTURES ─────────────────────────────────────────
# These names must exactly match the folder names in your dataset
GESTURES = [
    'hello', 'yes', 'no', 'thanks', 'please',
    'sorry', 'help', 'more', 'stop', 'good',
    'bad', 'eat', 'drink', 'love', 'you'
]

# ── DATASET PATH ─────────────────────────────────────────────
# This is where your Kaggle dataset folder is located
# Change this path to wherever you downloaded and unzipped the dataset
# Example: '/Users/Jose_1/Downloads/wlasl_dataset'
dataset_path = './wlasl_dataset'

# ── STORAGE LIST ─────────────────────────────────────────────
# Empty list that we fill up as we process images
# Each item = one row in our CSV = [gesture_name, 63 numbers]
output_rows = []

# ── MAIN LOOP ────────────────────────────────────────────────
# Go through each gesture one by one
for gesture in GESTURES:

    # Build the full path to this gesture's folder
    # e.g. './wlasl_dataset/hello'
    folder = os.path.join(dataset_path, gesture)

    # If this gesture folder doesn't exist in the dataset, skip it
    if not os.path.exists(folder):
        print(f"⚠️  Missing folder: {gesture} - skipping")
        continue

    # Counter for how many good samples we get per gesture
    count = 0

    # Go through each image in this gesture's folder
    # [:500] means max 500 images per gesture so dataset stays balanced
    for img_file in os.listdir(folder)[:500]:

        # Build full path to this image
        img_path = os.path.join(folder, img_file)

        # Read the image file
        img = cv2.imread(img_path)

        # Skip if image failed to load (corrupted or wrong format)
        if img is None:
            continue

        # Convert from BGR (OpenCV format) to RGB (MediaPipe format)
        rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        # Run MediaPipe hand detection on this image
        result = hands.process(rgb)

        # Only process if MediaPipe actually found a hand in the image
        if result.multi_hand_landmarks:

            # Get the first detected hand
            lm = result.multi_hand_landmarks[0]

            # Start our data row with the gesture name as the label
            row = [gesture]

            # Loop through all 21 hand landmark points
            # Each point has x, y, z coordinates
            # 21 points x 3 coordinates = 63 numbers total
            for point in lm.landmark:
                row.extend([point.x, point.y, point.z])

            # Add this completed row to our master list
            output_rows.append(row)
            count += 1

    # Print progress for each gesture
    print(f"✅ {gesture}: {count} samples extracted")

# ── SAVE TO CSV ───────────────────────────────────────────────
# Write all our collected data to a CSV file
with open('gesture_data.csv', 'w', newline='') as f:
    writer = csv.writer(f)

    # Write header row - column names
    # label = gesture name, f0-f62 = the 63 landmark coordinates
    writer.writerow(['label'] + [f'f{i}' for i in range(63)])

    # Write all data rows
    writer.writerows(output_rows)

# Done!
print(f"\n✅ Done! Total samples saved: {len(output_rows)}")
print("📁 gesture_data.csv is ready for training!")