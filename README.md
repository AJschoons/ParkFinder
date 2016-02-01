# Park Finder
Repository for the Park Finder iOS app

Park Finder is an app that allows users to search for nearby parks to visit and provides basic park details for further park research. Users can scroll or zoom the map from their current location and it will update with the 20 most popular parks around them. It is powered by Google Maps and Google Places, ensuring it has the most up-to-date information of local parks regardless of location. 

When a park is selected, the app will present name, address, phone, and website. Selecting the address will open navigation through Google Maps, with Apples Maps as a fall back. Touching the phone number allows the user to call the park, and touching the website link will open the park's website in-app with Safari.

<img src="https://cloud.githubusercontent.com/assets/7013639/12730935/39e1fff6-c8fc-11e5-8e9b-37aac951b717.png" width="23%"></img> <img src="https://cloud.githubusercontent.com/assets/7013639/12730941/3f8eb084-c8fc-11e5-9707-1833b4acec19.png" width="23%"></img> <img src="https://cloud.githubusercontent.com/assets/7013639/12730942/41f44c30-c8fc-11e5-8cda-e968c24413d6.png" width="23%"></img> <img src="https://cloud.githubusercontent.com/assets/7013639/12730947/46586aae-c8fc-11e5-8da2-cbb8f1b85b55.png" width="23%"></img> 

# Park Finder - Design Decisions

Much of the Park Finder app is designed around Delegation and State Machines. 

An example of this is with location verification. The app requires the user be able to get their location, or else the app is useless. Whenever the user's location isn't available, it handles that by presenting a LocationVerificationViewController modally. This happens when the app first opens up to verify an initial location. This LocationVerificationViewController handles verifying a location by being a delegate of a LocationVerificationManager. The LocationVerificationManager uses a state machine (pictured below) to automatically handle the different states of verifying a location over time: SearchingForLocation, SearchingForLocationExtended, LocationErrorIdle, and FoundLocation. As a delegate of the LocationVerificationManager, the LocationVerificationViewController then responds and updates its UI accordingly to the changes in state. When the state finally changes to FoundLocation, the LocationVerificationViewController notifies its own delegate, which should be the view controller that presented it, that the location has been verified. This presenting view controller can then respond accordingly. 

I chose to design it this way because it simplifies managing the app's state. Network connectivity is also managed this way. This ensures that whenever the user is on a main functional view controller, location services and network connectivity are available. Spotify handles network connectivity in a similar fashion in its current early 2016 version.

<img width="677" alt="locationverificationstatemachine" src="https://cloud.githubusercontent.com/assets/7013639/12732192/6f709212-c902-11e5-83af-95800f688aa2.png">

