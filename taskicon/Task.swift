//
//  Task.swift
//  taskicon
//
//  Created by Hoonsun Lee on 6/1/25.
//

import Foundation
import Cocoa

enum TaskType: String, Codable {
    case oneTime
    case repeatEveryday
}

// MARK: - Task Model
typealias TaskID = UUID

struct Task: Codable {
    let id: TaskID
    var title: String
    var type: TaskType
    var isCompleted: Bool
    var createdAt: Date
    
    init(title: String, type: TaskType = .oneTime){
        self.id = UUID()
        self.title = title
        self.type = type
        self.isCompleted = false
        self.createdAt = Date()
    }
}

// MARK: - Task Manager
final class TaskManager: ObservableObject {
    static let shared =  TaskManager()
    @Published private(set) var tasks: [Task] = []
    private let storageURL: URL
    private var resetTimer: Timer?
    
    private init(){
        // Determine file URL in Application Support
        let fm = FileManager.default
        if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let folder = appSupport.appendingPathComponent("TaskiferTasks")
            try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
            storageURL = folder.appendingPathComponent("tasks.json")
        } else {
            storageURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tasks.json")
        }
        loadTasks()
        scheduleDailyReset()
    }
    
    func addTask(title: String, type: TaskType = .oneTime){
        tasks.append(Task(title: title, type: type))
        saveTasks()
    }
    
    func deleteTask(id: TaskID) {
        tasks.removeAll { $0.id == id }
        saveTasks()
    }
    
    func editTask(id: TaskID, newTitle: String) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].title = newTitle
        saveTasks()
    }
    
    func toggleTask(id: TaskID){
        guard let idx = tasks.firstIndex(where: {$0.id == id}) else { return }
        tasks[idx].isCompleted.toggle()
        saveTasks()
    }
    
    // Progress: fraction of completed tasks (0.0 - 1.0)
    var progress: Double {
        guard !tasks.isEmpty else { return 0.0 }
        let completedCount = tasks.count(where: {$0.isCompleted })
        return Double(completedCount) / Double(tasks.count)
        
    }

    // MARK: - Persistance
    private func loadTasks(){ // called when user opens app
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([Task].self, from: data) else {
            tasks = []
            return
        }
        self.tasks = decoded
        saveTasks() // save to disk
    }
    
    // Reset daily tasks
    private func resetDailyTasks(_ tasksList: [Task]) -> [Task] {
        return tasksList.compactMap { task in
            var mutableTask = task
            switch mutableTask.type {
            case .oneTime:
                return mutableTask
            case .repeatEveryday:
                // Reset completion and keep
                mutableTask.isCompleted = false
                return mutableTask
            } 
        }
    }
    
    private func saveTasks(){
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        try? data.write(to: storageURL)
    }
    
    // resets task at midnight
    private func scheduleDailyReset(){
        let calendar = Calendar.current
        if let nextMidnight = calendar.nextDate(after: Date(), matching: DateComponents(hour:0, minute:0, second:0), matchingPolicy: .nextTime) {
            resetTimer = Timer(fireAt: nextMidnight, interval: 24*60*60, target: self, selector: #selector(dailyReset), userInfo: nil, repeats: true)
            
            RunLoop.main.add(resetTimer!, forMode: .common)
        }
    }
    
    @objc private func dailyReset(){
        // Reset repeatEveryday tasks
        self.tasks = resetDailyTasks(self.tasks)
        saveTasks()
    }
 }

