import SkipFuseUI
import SupachatModel

enum ContentTab: String, Hashable {
    case messages, settings
}

@MainActor struct ContentView: View {
    @AppStorage("tab") var tab = ContentTab.messages
    @AppStorage("appearance") var appearance = ""
    @State var viewModel = ViewModel()

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                if viewModel.username.isEmpty {
                    Text("Set account name in Settings")
                        .font(.title)
                        .foregroundStyle(.secondary)
                } else {
                    MessageListView()
                        .navigationTitle(Text("\(viewModel.messages.count) Messages"))
                }
            }
            .tabItem { Label("Messages", systemImage: "list.bullet") }
            .tag(ContentTab.messages)

            NavigationStack {
                SettingsView(appearance: $appearance)
                    .navigationTitle("Settings")
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(ContentTab.settings)
        }
        .environment(viewModel)
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
    }
}

struct MessageListView : View {
    @Environment(ViewModel.self) var viewModel: ViewModel

    var body: some View {
        List {
            ForEach(viewModel.messages) { item in
                NavigationLink(value: item) {
                    Label {
                        Text("\(item.sender) -> \(item.recipient): \(item.message)")
                    } icon: {
                        // the icon indicates if a message was sent or received
                        Image(systemName: item.sender == viewModel.username ? "chevron.left" : "chevron.right")
                    }
                }
            }
        }
        .task {
            await viewModel.monitorMessages()
        }
        .refreshable {
            await viewModel.refreshMessages()
        }
        .navigationDestination(for: Message.self) { msg in
            MessageView(message: msg)
        }
//        .toolbar {
//            ToolbarItemGroup {
//                Button {
//                    withAnimation {
//                        viewModel.items.insert(Item(), at: 0)
//                    }
//                } label: {
//                    Label("Add", systemImage: "plus")
//                }
//            }
//        }
    }
}

struct MessageView : View {
    @State var message: Message
    @Environment(ViewModel.self) var viewModel: ViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Text("Message: \(message.message)").font(.title3)
        }
    }
}

struct SettingsView : View {
    @Binding var appearance: String
    @Environment(ViewModel.self) var viewModel: ViewModel

    var body: some View {
        let viewModel = Bindable(wrappedValue: viewModel)

        Form {
            TextField("Account Name", text: viewModel.username)

            Picker("Appearance", selection: $appearance) {
                Text("System").tag("")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Version \(version) (\(buildNumber))")
            }
            HStack {
                PlatformHeartView()
                Text("Powered by [Skip](https://skip.tools)")
            }
        }
    }
}

/// A view that shows a blue heart on iOS and a green heart on Android.
struct PlatformHeartView : View {
    var body: some View {
        #if os(Android)
        ComposeView {
            HeartComposer()
        }
        #else
        Text(verbatim: "💙")
        #endif
    }
}

#if SKIP
/// Use a ContentComposer to integrate Compose content. This code will be transpiled to Kotlin.
struct HeartComposer : ContentComposer {
    @Composable func Compose(context: ComposeContext) {
        androidx.compose.material3.Text("💚", modifier: context.modifier)
    }
}
#endif
