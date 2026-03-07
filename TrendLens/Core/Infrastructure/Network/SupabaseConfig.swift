import Foundation
import Supabase

nonisolated(unsafe) let supabaseClient: SupabaseClient = {
    guard let urlString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
          let url = URL(string: "https://\(urlString)"),
          let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String
    else { fatalError("Missing Supabase config in Info.plist — ensure Secrets.xcconfig is set up") }
    return SupabaseClient(supabaseURL: url, supabaseKey: key)
}()
