import SwiftUI

public struct ExampleView: View {
    public init() { }

    var largestScreenDimension: CGFloat = {
        max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
    }()

    public var body: some View {
        VStack {
            Text("Line one of content")
            Text("Line two of content")
            Text("Line three of content")
        }
        .padding(0)
//        .frame(maxWidth: largestScreenDimension, alignment: .center)
//        .ignoresSafeArea()
        .border(Color.yellow, width: 2)
    }
}
