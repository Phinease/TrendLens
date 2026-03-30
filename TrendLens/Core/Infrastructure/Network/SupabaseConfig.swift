import Foundation
import OSLog
import Supabase

nonisolated let supabaseClient: SupabaseClient = {
    guard let urlString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
          let url = URL(string: urlString),
          let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String
    else { fatalError("Missing Supabase config in Info.plist — ensure Secrets.xcconfig is set up") }
    AppLog.network.info("SUPABASE_INIT url=\(url.absoluteString)")
    return SupabaseClient(supabaseURL: url, supabaseKey: key)
}()
