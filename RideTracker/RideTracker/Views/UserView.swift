//
//  UserView.swift
//  RideTracker
//
//  Created by Martina Hinz on 15.07.21.
//
import HealthKit
import SwiftUI

#warning("Refactor into view & viewmodel")
struct UserView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    
    @State var editable  = true
    @State var sexPicker = false
    @State var bikeTypePicker = false
    
    @AppStorage("bikeType") var bikeType: BikeType = .cityBike
    @AppStorage("bikeWeight") var bikeWeight: String = ""
    @AppStorage("sex") var sex: HKBiologicalSex = HKBiologicalSex.notSet
    @AppStorage("weight") var weight: String = ""
    @AppStorage("restingHeartRate") var restingHR: Double = 0.0
    #warning("TODO: adapt to sex")
    @AppStorage("maximumHeartRate") var maxHR: Int = 0
    @AppStorage("basalMetabolicRate") var mBr: String = ""
    @AppStorage("efficiencyD") var effD: String = ""
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("You & your bike")) {
                    HStack {
                        Text("Sex:")
                        Spacer()
                        if (editable) {
                            Text("\(userViewModel.user.biologicalSex?.stringRepresentation ?? "")")
                        } else {
                            Button("\(userViewModel.user.biologicalSex?.stringRepresentation ?? sex.stringRepresentation)") {
                                self.sexPicker = true
                                self.bikeTypePicker = false
                            }
                        }
                    }
                    HStack {
                        Text("Weight:")
                        Spacer()
                        let weight = self.userViewModel.formatWeight(weight: self.userViewModel.user.weightInKilograms)
                        if (editable) {
                            Text("\(weight)")
                        } else {
                            TextField("", text: self.$weight)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.blue)
                                .onChange(of: self.weight) { x in
                                    self.userViewModel.user.weightInKilograms = Double(self.weight) ?? 0.0
                                }
                            Text("kg").foregroundColor(.blue)
                        }
                    }
                    /*HStack {
                        Text("Resting Heartrate:")
                        Spacer()
                        Text("\(String(format: "%.0f", self.userViewModel.user.restingHeartRate)) count/min")
                        
                    }
                    
                    HStack {
                        Text("Maximum Heartrate:")
                        Spacer()
                        Text("\(220 - self.userViewModel.user.age) count/min")
                    }*/
                    
                    HStack {
                        Text("Bike Type:")
                        Spacer()
                        if (editable) {
                            Text("\(userViewModel.user.bikeType.rawValue)")
                        } else {
                            Button("\(bikeType.rawValue)") {
                                self.sexPicker = false
                                self.bikeTypePicker = true
                            }
                        }
                    }
                    
                    HStack {
                        Text("Bike Weight:")
                        Spacer()
                        if(editable) {
                            Text("\(self.bikeWeight) kg")
                        } else {
                            TextField("", text: $bikeWeight)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.blue)
                                .onChange(of: bikeWeight) { x in
                                    self.userViewModel.user.bikeWeight = Double(bikeWeight) ?? 0.0
                                }
                            Text("kg").foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Text("Break metabolic rate:")
                        Spacer()
                        if(editable) {
                            Text("\(self.mBr) kcal/h")
                        } else {
                            TextField("", text: $mBr)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.blue)
                                .onChange(of: mBr) { x in
                                    self.userViewModel.user.basalMetablicRate = Int(mBr) ?? 2800
                                }
                            Text("kcal/h").foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Text("Adjusted efficiency degree:")
                        Spacer()
                        if(editable) {
                            Text("\(self.effD) %")
                        } else {
                            TextField("", text: $effD)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.blue)
                                .onChange(of: effD) { x in
                                    self.userViewModel.user.efficiencyRate = Double(effD) ?? 0.3
                                }
                            Text("%").foregroundColor(.blue)
                        }
                    }
                }
            }
            
            Button("Load HKData") {
                self.userViewModel.loadHKProperties()
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
            .zIndex(3.0)
            .padding(.bottom)
            
            //Pickers
            if(self.sexPicker) {
                VStack {
                    HStack {
                        Spacer()
                        Button(action:{self.sexPicker = false}){
                            Text("Done")
                        }
                        .padding(.trailing)
                        .buttonStyle(BorderlessButtonStyle())
                        
                    }
                    HStack(alignment: .bottom) {
                        Picker("sex picker", selection: self.$sex) {
                            Text("Female").tag(HKBiologicalSex.female)
                            Text("Male").tag(HKBiologicalSex.male)
                            Text("Other").tag(HKBiologicalSex.other)
                        }
                        .pickerStyle(WheelPickerStyle())
                        .labelsHidden()
                        .onChange(of: sex) { tag in
                            self.userViewModel.user.biologicalSex = self.sex
                        }
                    }
                }
            }
            
            if(self.bikeTypePicker) {
                VStack {
                    HStack {
                        Spacer()
                        Button(action:{self.bikeTypePicker = false}){
                            Text("Done")
                        }
                        .padding(.trailing)
                        .buttonStyle(BorderlessButtonStyle())
                        
                    }
                    HStack(alignment: .bottom) {
                        Picker("Bike Type:", selection: self.$bikeType) {
                            ForEach(BikeType.allCases, id: \.self) { value in
                                Text(value.localizedName)
                                    .tag(value)
                            }
                        }
                        .onChange(of: bikeType) { tag in
                            self.userViewModel.user.bikeType = self.bikeType
                        }
                    }
                }
            }
        }
        .onAppear {
            #warning("TODO: Rethink init of HKProperties")
            /*  self.userViewModel.loadHKProperties()*/
            self.sex = self.userViewModel.user.biologicalSex ?? HKBiologicalSex.notSet
           self.weight = String(self.userViewModel.user.weightInKilograms)
            self.userViewModel.user.bikeWeight = Double(self.bikeWeight) ?? 15
            self.restingHR = self.userViewModel.user.restingHeartRate
            self.maxHR = 220 - self.userViewModel.user.age
        }
        .toolbar {
            if(editable) {
                Button("Edit") {
                    self.editable = false
                }
            } else {
                Button("Done") {
                    self.editable = true
                    self.sexPicker = false
                    self.bikeTypePicker = false
                }
            }
        }
    }
}
