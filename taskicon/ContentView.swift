//
//  ContentView.swift
//  taskicon
//
//  Created by Hoonsun Lee on 5/31/25.
//

import SwiftUI
import ConfettiSwiftUI

struct MyFont {
  static let title = Font.custom("Chalkboard SE", size: 18.0)
  static let body = Font.custom("Chalkboard SE", size: 12.0)
}

struct ContentView: View {
    @State private var newTaskTitle: String = ""
    @ObservedObject var manager = TaskManager.shared
    @State private var isEditing: Bool = false
    @State private var editingTaskID: TaskID? = nil
    @State private var editTaskTitle: String = ""
    @State private var showTaskPopover = false
    @State private var popoverTaskTitle: String = ""
    @State private var popoverTaskType: TaskType = .oneTime
    @State private var confettiCounter = 0
    @FocusState private var isTitleFieldFocused: Bool
    let barWidth: CGFloat = 180
    let turtleSize: CGFloat = 24 // adjust if needed

    var body: some View {

        VStack {
            HStack {
                Spacer()
                Button(isEditing ? "Done" : "Edit") {
                    isEditing.toggle()
                }
                Button(action: {
                    popoverTaskTitle = newTaskTitle
                    popoverTaskType = .oneTime
                    showTaskPopover = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .imageScale(.large)
                }
                .buttonStyle(BorderlessButtonStyle())
                .popover(isPresented: $showTaskPopover) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("New Task")
                            .font(MyFont.title)
                        TextField("What do you need to do?", text: $popoverTaskTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 220)
                            .font(MyFont.body)
                        Picker("Type", selection: $popoverTaskType) {
                            Text("One Time").tag(TaskType.oneTime)
                            Text("Repeat Daily").tag(TaskType.repeatEveryday)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        HStack {
                            Button("Cancel") {
                                showTaskPopover = false
                            }
                            Spacer()
                            Button("Add") {
                                let trimmed = popoverTaskTitle.trimmingCharacters(in: .whitespaces)
                                guard !trimmed.isEmpty else { return }
                                manager.addTask(title: trimmed, type: popoverTaskType)
                                newTaskTitle = ""
                                showTaskPopover = false
                            }
                        }
                    }
                    .padding()
                    .frame(width: 250)
                }
            }
            .frame(width: 250)
            .padding(.trailing,-25)
            .padding(.top,15)
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    Spacer().frame(height: turtleSize)
                    ProgressView(value: manager.progress)
                        .frame(width: barWidth)
                }
                Image(systemName: "tortoise.fill")
                    .imageScale(.large)
                    .foregroundStyle(
                        manager.progress == 1.0
                        ? .purple : .green
                    )
                    .frame(width: turtleSize, height: turtleSize)
                    .offset(
                        x: CGFloat(manager.progress) * (barWidth - turtleSize),
                        y: 2
                    )
                    .animation(.easeInOut, value: manager.progress)
            }
            .onChange(of: manager.progress) {
                if manager.progress == 1.0 {
                    confettiCounter += 1
                }
            }
            .frame(width: barWidth, height: turtleSize + 24) // height: turtle + progress bar
            Text("\(Int(manager.progress * 100))% complete")
                .font(MyFont.body)
                .foregroundColor(.secondary)


            List {
                ForEach(manager.tasks, id: \.id) { task in
                    HStack {
                        Button(action: {
                            manager.toggleTask(id: task.id)
                        }) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        if editingTaskID == task.id {
                            TextField("Task Title", text: $editTaskTitle, onCommit: {
                                manager.editTask(id: task.id, newTitle: editTaskTitle)
                                editingTaskID = nil
                            })
                            .font(MyFont.body)
                            .focused($isTitleFieldFocused)
                            .frame(width: 140)
                            Button(action: {
                                manager.editTask(id: task.id, newTitle: editTaskTitle)
                                editingTaskID = nil
                            }) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(PlainButtonStyle())
                            Button(action: {
                                editingTaskID = nil
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Text(task.title)
                                .font(MyFont.body)
                        }
                        Spacer()
                        if task.type == .repeatEveryday {
                            Image(systemName: "repeat")
                        }
                        if isEditing {
                            Button(action: {
                                editingTaskID = task.id
                                editTaskTitle = task.title
                                isTitleFieldFocused = true
                            }) {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                manager.deleteTask(id: task.id)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .frame(width: 300)
            .confettiCannon(trigger: $confettiCounter, num:40, confettis: [
                .text("🎉"), .text("✨"), .text("🌈"), .text("🐢")
            ], confettiSize: 20,repetitions: 3)
        }
        .contextMenu {
                Button("Quit App") {
                    NSApp.terminate(nil)
                }
            }
    }

}
#Preview {
    ContentView()
}
