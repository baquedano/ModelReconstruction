# ModelReconstruction
Model reconstruction through the use of an iOS app and Mac's photogrammetry

## Backend
To run the backend follow these steps:

1. run `cd ./ModelReconstructionBE`
2. run `npm install`
3. create a `.env` file based on the sample provided
4. run `npm run dev`


## iOS App
To run the backend follow these steps:

1. open `ARDetection.xcodeproj` inside the `ARDetection` folder 
2. edit the scheme environment variables and setup the `API_URL` (if running locally just add your IP and the port I.E: `http://127.0.0.1:3000`)
3. click run on a physical device (does not work on simulators due to the need for a camera)



## How it works
Once you get both projects running take pictures of the object you want to scan using the camera scope (photos will be cropped to just what is within the scope), the more pictures the more accurate the model will be (docs recommend between 20 and 200) and then click on the Process button, this will send the images to the BE to be processed with the HelloPhotogrammetry binary inside the `ModelReconstructionBE` project, the time it takes is proportional to the amount of images. Once it's done processing it'll send the model back to the app who will place it in front of the camera



## HelloPhotogrammetry (optional)
HelloPhotogrammetry is sample command line app associated with WWDC21 session that can be found [here](https://developer.apple.com/documentation/realitykit/creating_a_photogrammetry_command-line_app)
