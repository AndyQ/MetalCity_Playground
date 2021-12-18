import SwiftUI

struct ContentView: UIViewControllerRepresentable {
    
    func makeUIViewController( context: Context ) -> UIViewController {
        
        let vc = GameViewController()
        return vc
    }
    
    func updateUIViewController ( _ uiViewController: UIViewController, context: Context ) {
        
    }
}

