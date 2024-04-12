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
        // 앱이 포그라운드에서 실행 중일 때도 알림이 표시되도록 설정
        completionHandler([.list, .badge, .sound])
    }
}


struct Reminder : View{
    // 값이 바껴야하기 때문에 옵저버로 지정
    @ObservedObject var item : Item
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View{
        HStack{
            HStack{
                Text("\(item.timestamp!, formatter: itemFormatterAm)")
                    .offset(x: -10, y: 5)
                
                
                Text("\(item.timestamp!, formatter: itemFormatter)")
                    .font(.system(size: 30))
                    .offset(x: -15)
            }
            Toggle("", isOn: Binding<Bool>(
                get: { self.item.isChecked },
                set: { newValue in
                    self.item.isChecked = newValue
                    // CoreData 컨텍스트에 변경 사항을 저장
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
    
    
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.isChecked = false

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func addNotification()
    {
        let content = UNMutableNotificationContent()
        content.title = "물 마시자"
        content.body = "물 마실 시간입니다."
        content.sound = UNNotificationSound.default

        // 알림을 보낼 날짜와 시간 설정
        var dateComponents = DateComponents()
        dateComponents.hour = 19    // 24시간 표기법 사용, 오후 7시
        dateComponents.minute = 7  // 10분
        
        // 5분 후 알림 설정
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // 알림 요청 생성
        let request = UNNotificationRequest(identifier: "UniqueIdentifier", content: content, trigger: trigger)

        // 알림 센터에 추가
        center.add(request) { error in
            if let error = error {
                print("알림 스케줄 실패: \(error.localizedDescription)")
            }
        }
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
        

        
        addNotification()

    }
    
    var body: some View {
        NavigationView {
            
            List{
                ForEach(items) { item in
                    Reminder(item: item)
                }
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
    
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.isChecked = false

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    var body:some View {
        NavigationView {
            HStack{
                Text("시간")

            }
                .navigationBarTitle("알림 추가", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                },
                    trailing: Button("저장") {
                        // 오른쪽 버튼 액션
                        addItem()
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

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
