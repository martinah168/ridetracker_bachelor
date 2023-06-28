# README

This iOS-Application developed as part of a bachelor thesis tracks various factors of a bicycle trip to predict calories burned.

## Features
- The application is developed for iPhones using the Swift programming language.
- Apple's frameworks, such as CLLocation and Health Kit, are utilized to collect data from reliable and easy-to-use sources.
- Factors such as location, accelerometer data, weight, biological sex, bike type, and weight are tracked and saved for accurate calculations.
- The application can connect to an Apple Watch via Bluetooth to gather heart rate data.
- Personal data can be manually set, including bike type, weight, efficiency, and break metabolic rate.
- Weather data is collected hourly or every five kilometers using the OpenWeatherMap API.
- MEi (mechanical energy expenditure) and calories burned based on heart rate are calculated using regression equations.
- Tracked data can be saved to a CSV file for further analysis in Excel.
- Persistent storage of data is implemented using Apple's Core Data Framework.
- A user-friendly interface displays trip summaries, including duration, average speed, calories burned, and average wind speed.

## Usage
1. On first use, users can enter their personal information by tapping the profile icon and selecting "Edit".
2. To start tracking a trip, tap "Start Tracking" and view the displayed distance while the application saves location information in the background.
3. Manually stop the tracking process by pressing "Stop Tracking".
4. Tap "Save" to associate heart rate data from the Health App with the user's location and fetch weather data from the OpenWeatherMap API.
5. Calculations for MEi and calories burned based on heart rate are performed.
6. The collected data is saved to a CSV file and stored persistently for future reference.
7. Previously saved rides can be viewed in the app, providing an overview of trip details and performance.
8. The mapped route, colored based on speed, is displayed on a map.

Please note that server storage for data is not implemented in this version of the application.
