//
//  ContentView.swift
//  WatchRideTracker Extension
//
//  Created by Martina Hinz on 30.05.21.
//

import SwiftUI
struct WatchView: View {
    @ObservedObject var model = ViewModelWatch()
    @ObservedObject var workoutModel = WorkoutModel()
    
    var body: some View {
        VStack{
            if model.startedWorkout {
                HStack {
                    Text("\(workoutModel.heartRate , specifier: "%.0f")")
                        .font(.system(size: 40))
                    Text("BPM")
                        .foregroundColor(.red)
                        .padding(.bottom)
                }.padding()
                Text("Your Heart Rate")
                    .font(.system(size: 14))
                //Text only for debugging purposes
                Text("Tracking on")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                
                
            } else {
                Text("Tracking off")
            }
        }.onChange(of: model.startedWorkout, perform: { value in
            if model.startedWorkout {
                workoutModel.startWorkoutWithHealthStore()
            } else {
                workoutModel.endWorkout()
            }
        })
    }
}
