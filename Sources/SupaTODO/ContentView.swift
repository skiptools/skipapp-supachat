// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import SwiftUI
import SkipKit
import SkipSupabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://zncizygaxuzzvxnsfdvp.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpuY2l6eWdheHV6enZ4bnNmZHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDc4NjE1NDksImV4cCI6MjAyMzQzNzU0OX0.yoFteItT4FVu_kbMuMnQCzE8YYU5jEVWLU7NDBY94-E"
)


/// The current Supabase session, which contains information about the current user
class SessionViewModel : ObservableObject {
    @Published var session: Session? = nil

    init() {
    }
}

public struct ContentView: View {
    @AppStorage("tab") var tab = Tab.welcome
    @AppStorage("name") var name = "Skipper"
    @AppStorage("appearance") var appearance: String = ""
    @State var isLoggedOut = true
    @ObservedObject var sessionViewModel = SessionViewModel()

    public init() {
    }

    public var body: some View {
        TabView(selection: $tab) {
            VStack(spacing: 0) {
                Text("Hello \(name)!")
                    .padding()
            }
            .font(.largeTitle)
            .tabItem { Label("Welcome", systemImage: "heart.fill") }
            .tag(Tab.welcome)

            NavigationStack {
                List {
                    ForEach(1..<1_000) { i in
                        NavigationLink("Item \(i)", value: i)
                    }
                }
                .navigationTitle("Home")
                .navigationDestination(for: Int.self) { i in
                    Text("Item \(i)")
                        .font(.title)
                        .navigationTitle("Screen \(i)")
                }
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(Tab.home)

            SettingsView(appearance: $appearance)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .environmentObject(sessionViewModel)
        .sheet(isPresented: $isLoggedOut) {
            VStack {
                Spacer()
                AuthView()
                Spacer()
            }
        }
        .task {
            #if !SKIP
            // see: https://supabase.com/docs/guides/getting-started/tutorials/with-swift
            for await state in supabase.auth.authStateChanges {
                if [.initialSession, .signedIn, .signedOut].contains(state.event) {
//                    logger.info("supabase authStateChanges: \(state.event)")
                    logger.info("supabase authStateChange")
                    isLoggedOut = state.session == nil
                    self.sessionViewModel.session = state.session
                }
            }
            #endif
        }
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
    }
}


struct SettingsView : View {
    @Binding var appearance: String
    @EnvironmentObject var sessionViewModel: SessionViewModel

    var body: some View {
        NavigationStack {
            Form {
                Picker("Appearance", selection: $appearance) {
                    Text("System").tag("")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }

                if let session = sessionViewModel.session {
                    Text("Logged in as: \(session.user.email ?? session.user.id.description)")
                    Button("Sign Out") {
                        Task {
                            do {
                                try await supabase.auth.signOut()
                            } catch {
                                logger.error("error signing out: \(error)")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.title2)
                }
            }
            .navigationTitle("Settings")
        }

    }

}

enum Tab : String, Hashable {
    case welcome, home, settings
}

struct AuthView: View {
    @State var email = ""
    @State var password = ""
    @State var password2 = ""
    @State var signUp = false
    @State var isLoading = false
    @State var result: Result<Void, Error>?

    var body: some View {
        VStack {
            Form {
                TextField("Email", text: $email)
                    .autocorrectionDisabled()
                    #if !SKIP
                    //.textContentType(.emailAddress)
                    #endif
                    //.textInputAutocapitalization(.never)
                SecureField("Password", text: $password)
                if signUp {
                    SecureField("Confirm", text: $password2)
                }
            }

            if isLoading {
                ProgressView()
            } else if !signUp {
                Button("Sign In") {
                    signInButtonTapped()
                }
                .buttonStyle(.borderedProminent)
                .font(.title2)
                .disabled(email.isEmpty || password.isEmpty)
                HStack {
                    Text("New user?")
                    Button("Sign up") {
                        signUp = true
                    }
                }
            } else if signUp {
                Button("Sign Up") {
                    signUpButtonTapped()
                }
                .buttonStyle(.borderedProminent)
                .font(.title2)
                .disabled(password.count < 6 || password != password2)
                HStack {
                    Text("Already have an account?")
                    Button("Sign in") {
                        signUp = false
                    }
                }
            }

            if let result {
                Section {
                    switch result {
                    case .success:
                        Text("Check your inbox.")
                    case .failure(let error):
                        Text(error.localizedDescription).foregroundStyle(.red)
                    }
                }
            }
        }
        #if !SKIP
        .onOpenURL(perform: { url in
            Task {
                do {
                    try await supabase.auth.session(from: url)
                } catch {
                    self.result = .failure(error)
                }
            }
        })
        #endif
    }

    func signInButtonTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                logger.info("signing in with email: \(email)")
                try await supabase.auth.signIn(email: email, password: password)
                result = .success(())
                logger.info("successfully signed in with email: \(email)")
            } catch {
                result = .failure(error)
                logger.error("error signing in with email: \(email): \(error)")
                #if SKIP
                //error.printStackTrace()
                android.util.Log.e("supa.todo.SupaTODO", "error", error as? Throwable) // show stack trace in logcat
                #endif
            }
        }
    }

    func signUpButtonTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                try await supabase.auth.signUp(email: email, password: password)
                result = .success(())
            } catch {
                result = .failure(error)
            }
        }
    }
}


struct ProfileView: View {
    @State var username = ""
    @State var fullName = ""
    @State var website = ""

    @State var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Username", text: $username)
                        #if !SKIP
                        //.textContentType(.username)
                        #endif
                        //.textInputAutocapitalization(.never)
                    TextField("Full name", text: $fullName)
                        #if !SKIP
                        //.textContentType(.name)
                        #endif
                    TextField("Website", text: $website)
                        #if !SKIP
                        //.textContentType(.URL)
                        #endif
                        //.textInputAutocapitalization(.never)
                }

                Section {
                    Button("Update profile") {
                        updateProfileButtonTapped()
                    }
                    .bold()

                    if isLoading {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading){
                    Button("Sign out", role: .destructive) {
                        Task {
                            try? await supabase.auth.signOut()
                        }
                    }
                }
            })
        }
        .task {
            await getInitialProfile()
        }
    }

    func getInitialProfile() async {
        do {
            let currentUser = try await supabase.auth.session.user

            #if !SKIP
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: currentUser.id)
                .single()
                .execute()
                .value

            self.username = profile.username ?? ""
            self.fullName = profile.fullName ?? ""
            self.website = profile.website ?? ""
            #endif
        } catch {
            debugPrint(error)
        }
    }

    func updateProfileButtonTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let currentUser = try await supabase.auth.session.user

                try await supabase
                    .from("profiles")
                    .update(
                        UpdateProfileParams(
                            username: username,
                            fullName: fullName,
                            website: website
                        )
                    )
                    .eq("id", value: currentUser.id)
                    .execute()
            } catch {
                debugPrint(error)
            }
        }
    }
}

struct Profile: Decodable {
    let username: String?
    let fullName: String?
    let website: String?

    enum CodingKeys: String, CodingKey {
        case username
        case fullName = "full_name"
        case website
    }
}

struct UpdateProfileParams: Encodable {
    let username: String
    let fullName: String
    let website: String

    enum CodingKeys: String, CodingKey {
        case username
        case fullName = "full_name"
        case website
    }
}
