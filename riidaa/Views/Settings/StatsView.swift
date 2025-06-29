//
//  StatsView.swift
//  riidaa
//
//  Created by Pierre on 2025/06/27.
//

import SwiftUI
import CoreData

struct StatsView: View {
    
    @State var stats: [(day: Date, count: Int)] = []
    @State var weekOffset: Int = 0
    
    var body: some View {
        VStack {
            Text("Week of \(formattedWeekRange(for: weekOffset))")
                .font(.headline)
                .padding(.top)
            
            TabView(selection: $weekOffset) {
                ForEach(-5...0, id: \.self) { offset in
                    BarChartView(weekStats: weekStats(for: offset))
                        .tag(offset)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(maxHeight: 300)
            
            Spacer()
        }
        .onAppear {
            try? fetchPageRead()
        }
    }
    
    func fetchPageRead() throws {
        let request = NSFetchRequest<MangaPageModel>(entityName: "MangaPageModel")
        request.predicate = NSPredicate(format: "read_at != nil")
        
        let pages = try CoreDataManager.shared.container.viewContext.fetch(request)
        let calendar = Calendar.current
        var results: [Date: Int] = [:]
        
        for page in pages {
            guard let readAt = page.read_at else { continue }
            let day = calendar.startOfDay(for: readAt as Date)
            results[day, default: 0] += 1
        }
        
        let sortedCounts = results.sorted { $0.key < $1.key }
        self.stats = sortedCounts.map { (day: $0.key, count: $0.value) }
    }
    
    func weekStats(for offset: Int) -> [(day: Date, count: Int)] {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start,
              let targetStart = calendar.date(byAdding: .weekOfYear, value: offset, to: startOfWeek) else {
            return []
        }
        
        let days = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: targetStart)
        }
        
        let dict = Dictionary(uniqueKeysWithValues: stats.map { ($0.day, $0.count) })
        
        return days.map { day in
            let normalized = calendar.startOfDay(for: day)
            return (day: normalized, count: dict[normalized] ?? 0)
        }
    }
    
    func formattedWeekRange(for offset: Int) -> String {
        let calendar = Calendar.current
        guard let currentStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start,
              let targetStart = calendar.date(byAdding: .weekOfYear, value: offset, to: currentStart),
              let targetEnd = calendar.date(byAdding: .day, value: 6, to: targetStart) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: targetStart)) - \(formatter.string(from: targetEnd))"
    }
    
}

struct BarChartView: View {
    var weekStats: [(day: Date, count: Int)]

    func color(for count: Int, min: Int, max: Int) -> Color {
        guard max > min else { return .gray }

        let ratio = CGFloat(count - min) / CGFloat(max - min)
        
        return Color(hue: 0.0 + (0.33 * ratio), saturation: 0.9, brightness: 0.9)
    }

    func shortWeekday(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    var body: some View {
        let counts = weekStats.map { $0.count }
        let maxCount = max(counts.max() ?? 1, 1)

        VStack {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(weekStats, id: \.day) { item in
                    VStack {
                        Text("\(item.count)")
                            .font(.caption2)
                            .foregroundColor(.primary)

                        Rectangle()
                            .fill(color(for: item.count, min: 0, max: maxCount))
                            .frame(width: 20, height: CGFloat(item.count) / CGFloat(maxCount) * 100.0)
                            .clipShape(.capsule)

                        Text(shortWeekday(from: item.day))
                            .font(.caption2)
                            .rotationEffect(.degrees(-45))
                            .frame(height: 30)
                    }
                }
            }
        }
    }
}


#Preview {
    StatsView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
}
