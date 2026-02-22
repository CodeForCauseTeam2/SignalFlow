# CODE FOR CAUSE 2026

- Emily Morazan
- Aolany Acosta
- Jose Flores
- Keitaro Cho
- Hernan Zapien
- Kayla Mendoza

To run our web browser you MUST be in the flutter_application_1 folder and use the command in the terminal "flutter run -d chrome"

Tasks:

Web/Brower Application (Kayla, Hernan,Emily):
  - Created a web brower
  - User freindly buttons
  - Includes settings button that can change to dark mode
  - Back arrows to go to previous page

Video Capture of Hand (Aolany & Keitaro): 
  - Using MediaPipe, we used their model to capture hands.
  - The MediaPipe model recognizes when a hand appears on screen and maps 21 point to the hand.
  - Each of these points on the hand have a and x, y, and z axis (value) that correseponds with them.
  - The 21 points can then be used to train an AI to understand what hand gestures are being shown to it by using the coordinates.

AI Integration (Jose):
  - Sending captured gestures through a trained AI model to understand what gesture is being showned.
  - Used python to access a trained AI model using a CDN (Content Directory Network)
