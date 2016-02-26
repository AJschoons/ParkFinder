![park_finder_logotype](https://cloud.githubusercontent.com/assets/7013639/12733155/430b21d8-c907-11e5-8ce7-406f319f2a0c.png)

Repository for the Park Finder iOS app, available at: https://itunes.apple.com/us/app/park-finder-maps-nearby-park/id1078040422

Park Finder is an iOS app that allows users to search for nearby parks to visit and provides basic park information. Users can scroll or zoom the map from their current location and it will update with the 20 most popular parks around them. It is powered by Google Maps and Google Places, ensuring it has the most up-to-date information of local parks regardless of location.

When a park is selected, the app will present its name, address, phone, and website. Selecting the address will open navigation through Google Maps, with Apples Maps as a fall back. Touching the phone number allows the user to call the park, and touching the website link will open the park's website in-app with Safari.

The app and its design, color scheme, and logo, were all done by Adam Schoonmaker.

<img src="https://cloud.githubusercontent.com/assets/7013639/12730935/39e1fff6-c8fc-11e5-8e9b-37aac951b717.png" width="23%"></img> <img src="https://cloud.githubusercontent.com/assets/7013639/12730941/3f8eb084-c8fc-11e5-9707-1833b4acec19.png" width="23%"></img> <img src="https://cloud.githubusercontent.com/assets/7013639/12730942/41f44c30-c8fc-11e5-8cda-e968c24413d6.png" width="23%"></img> <img src="https://cloud.githubusercontent.com/assets/7013639/12730947/46586aae-c8fc-11e5-8da2-cbb8f1b85b55.png" width="23%"></img>

# Design Decisions

Much of the code for the Park Finder app is designed around Delegation, Singletons, State Machines, and typical Model-View-Controller. I tried sticking to "skinny view controllers." Probably the best example of this can be seen in MapViewController. It is the main view controller the user interacts with, however is only ~200 lines despite being responsible for a Google Map and table of parks.

Generally I favor Storyboards because I like how they make the UI flow visibly clear, and lower the amount of boilerplate code needed. For small teams and independent projects I think they are the way to go.

### Google Map + Interaction Management

The meat of this app is the MapViewController. This is where the user spends most of their time searching for nearby parks. As the app developed this became increasingly complex, so I abstracted the logic out of the MapViewController into a MapManager object that has the MapViewController as its delegate. The MapManager is both a state machine (simplified picture below), and just generally a manager for events related to the Google Map. Later I would like to further abstract that state machine into its own class that the MapManager uses. Using this state machine made it much easier to handle all the events that would cause the map to have to reload the parks for the current visible portion of the map. Examples are scrolling, zooming, selecting another park, and animating to current location. More details can be seen in MapManager.swift and MapViewController.swift, but it made the MapViewController a very clean class that's <200 lines despite its complexity.

<img width="480" alt="mapmanagerstatemachine" src="https://cloud.githubusercontent.com/assets/7013639/12732409/6bfafb80-c903-11e5-8a52-b0b2db858d19.png">

### Ensuring Location and Nework Connectivity

A more specific example of the delegation and state machines is with location verification. The app requires the user be able to get their location, or else the app is useless. Whenever the user's location isn't available, it handles that by presenting a LocationVerificationViewController modally. This happens when the app first opens up to verify an initial location. This LocationVerificationViewController handles verifying a location by being a delegate of a LocationVerificationManager. The LocationVerificationManager uses a state machine (pictured below) to automatically handle the different states of verifying a location over time: SearchingForLocation, SearchingForLocationExtended, LocationErrorIdle, and FoundLocation. As a delegate of the LocationVerificationManager, the LocationVerificationViewController then responds and updates its UI accordingly to the changes in state. When the state finally changes to FoundLocation, the LocationVerificationViewController notifies its own delegate, which should be the view controller that presented it, that the location has been verified. This presenting view controller can then respond accordingly. 

I chose to design it this way because it simplifies managing the app's state. Network connectivity is also managed this way. This ensures that whenever the user is on a main functional view controller, location services and network connectivity are available. Spotify handles network connectivity in a similar fashion in its current early 2016 version.

<img width="677" alt="locationverificationstatemachine" src="https://cloud.githubusercontent.com/assets/7013639/12732192/6f709212-c902-11e5-83af-95800f688aa2.png">

### Updating Current Location

Keeping with the theme of using state machines to manage related events over time, I used one to handle keeping the current location updated. The CurrentLocationManager is a singleton that updates keeps the user's location updated, and makes the current location available anywhere in the app. 

<img width="735" alt="currentlocationmanagerstatemachine" src="https://cloud.githubusercontent.com/assets/7013639/12733032/595256b0-c906-11e5-86b4-7a4e0fd4fb70.png">

### Networking

For networking in the app I chose to use the popular AFNetworking library. I like AFNetworking because it's easy to create singletons to handle interacting with each different API. It was slightly overkill since there weren't many calls necessary for each API used in ParkFinder. However, what I like about it is the networking logic is abstracted away to singleton Client objects that make the networking in view controllers (or their associated networking helpers/managers) as simple as:

```swift
GooglePlacesClient.sharedClient.getPlacesNearbySearchParks(location, radius: radius,
  success: { [weak self] task, responseObject in
    guard let strongSelf = self else { return }
    
    ... code that does something with the nearby parks ...
    
  },
  failure: defaultAFHTTPFailureBlock
)
```

### Google Analytics

The app is setup to track how long a user spends on each screen, and also most any significant UI event. This includes touching map markers, making a call, navigating to a park, animating to current location, and so on. Being able to do this was a nice perk of keeping the app simple. It will be interesting to see which parts of the app people use the most.
