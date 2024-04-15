//
//  ContentView.swift
//  HydroMinder
//
//  Created by Amanda on 4/9/24.
//


import SwiftUI
import CoreData
import UserNotifications

let center = UNUserNotificationCenter.current()
class CustomLabel: UILabel {
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0) // 위에서 10포인트 아래로
        super.drawText(in: rect.inset(by: insets))
    }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("알림에 대한 사용자 반응 처리")
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .badge, .sound])
    }
}


struct Reminder : View{
    // 값이 바껴야하기 때문에 옵저버로 지정
    @ObservedObject var item : Item
    @Environment(\.managedObjectContext) private var viewContext
    
    let notificationMessages = [
        "물 마실 시간입니다! 건강을 위해 잠시 일어나세요.",
        "잠깐! 수분 보충의 시간이에요. 물 한 잔 어때요?",
        "하루에 물 8잔은 건강의 비결입니다. 지금 마셔보세요!",
        "물 한 잔으로 에너지를 충전하세요! 당신의 몸이 감사할 거에요.",
        "잊지 마세요, 물은 최고의 보약입니다. 지금 한 잔 하세요.",
        "물 마시는 시간! 몸을 리프레시하고 에너지를 충전하세요.",
        "물을 마시면 피로가 풀립니다. 잠시 휴식을 취하며 몸을 재충전하세요.",
        "물 한 잔으로 두뇌에 활력을 주세요. 집중력이 필요할 때 바로 그때입니다.",
        "매시간 물 한잔은 건강한 생활의 시작입니다. 잊지 마세요!",
        "물은 자연의 보약입니다. 지금 바로 건강을 챙기세요.",
        "건강을 위해, 오늘 물 충분히 드셨나요? 지금이 마실 때입니다!"
    ]
    
    private func addNotification(datetime: Date, uuid: UUID)
    {
        
        let content = UNMutableNotificationContent()
        content.title = "HydroMinder"
        content.body = notificationMessages.randomElement()!
        content.sound = UNNotificationSound.default

        let hh = itemFormatterHH.string(from: datetime)
        let mm = itemFormatterMM.string(from: datetime)

        // 알림을 보낼 날짜와 시간 설정
        var dateComponents = DateComponents()
        dateComponents.hour = Int(hh)
        dateComponents.minute = Int(mm)
        

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // 알림 요청 생성
        let request = UNNotificationRequest(identifier: uuid.uuidString, content: content, trigger: trigger)

        // 알림 센터에 추가
        center.add(request) { error in
            if let error = error {
                print("알림 스케줄 실패: \(error.localizedDescription)")
            }
        }
    }
    
    func removeNotification(uuid: UUID) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [uuid.uuidString])
    }
    
    func removeAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }
    
    var body: some View{
        HStack{
            if let timestamp = item.timestamp {
                HStack{
                    Text("\(timestamp, formatter: itemFormatterAm)")
                        .offset(x: -10, y: 5)
                    
                    
                    Text("\(timestamp, formatter: itemFormatter)")
                        .font(.system(size: 30))
                        .offset(x: -15)
                }
            } else {
                Text("No timestamp")
                    .offset(x: -10, y: 5)
            }
            Toggle("", isOn: Binding<Bool>(
                get: { self.item.isChecked },
                set: { newValue in
                    self.item.isChecked = newValue
                    // CoreData 컨텍스트에 변경 사항을 저장
                    
                    if(newValue)
                    {
                        addNotification(datetime: item.timestamp!,uuid: item.uuid!)
                    }else
                    {
                        removeNotification(uuid: item.uuid!)
                    }
                    // Date 객체를 원하는 형식의 문자열로 변환

                    try? self.viewContext.save()
                }
            ))
        }
    }
}

struct ContentView: View {
    
    @State private var showingSheet = false
    
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    
    private var items: FetchedResults<Item>
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.forEach { index in
                let item = items[index]
                
                removeNotification(uuid: item.uuid!)
                
                viewContext.delete(item)
            }

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func removeNotification(uuid: UUID) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [uuid.uuidString])
    }
    
    func removeAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }
    
    init(showingSheet: Bool = false) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("알림 허용됨")
                let delegate = NotificationDelegate()
                center.delegate = delegate
       
            } else {
                print("알림 거부됨")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            
            List{
                ForEach(items) { item in
                    Reminder(item: item)
                }
                .onDelete(perform: deleteItems)
            }
                .navigationBarTitle("물마시기")
                .navigationBarItems(trailing: Button(action: {
                    showingSheet = true
                }) {
                    Image(systemName: "plus")
                })
        }
        .sheet(isPresented: $showingSheet) {
            DetailView()
        }
    }
}

struct DetailView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    private func addItem(datetime: Date) {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = datetime
            newItem.isChecked = false
            newItem.uuid = UUID()

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    @State private var date = Date()
    
    var body:some View {
        NavigationView {

            HStack {

                DatePicker("  시간", selection: $date, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .foregroundColor(.black)
                    .contentMargins(-5)

                    .environment(\.colorScheme, .dark) // <- This modifier
            }
            .toggleStyle(.button) // 버튼 스타일 적용
                .navigationBarTitle("알림 추가", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                },
                    trailing: Button("저장") {
                        // 오른쪽 버튼 액션
                        addItem(datetime: date)
                        presentationMode.wrappedValue.dismiss()
                    }
                )
        }
    }
}


private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "hh:mm"
    return formatter
}()

private let itemFormatterAm: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "a"
    formatter.locale = Locale(identifier: "ko_KR")
    return formatter
}()

private let itemFormatterHH: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH"
    formatter.locale = Locale(identifier: "ko_KR")
    return formatter
}()

private let itemFormatterMM: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "mm"
    formatter.locale = Locale(identifier: "ko_KR")
    return formatter
}()


#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
