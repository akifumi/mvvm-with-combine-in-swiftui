//
//  ContentView.swift
//  CombineSample
//
//  Created by akifumi.fukaya on 2019/06/13.
//  Copyright © 2019 Akifumi Fukaya. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    @State private var username: String = ""

    var body: some View {
        VStack {
            TextField($username, placeholder: Text("Placeholder"), onEditingChanged: { (changed) in
                print("onEditingChanged: \(changed)")
            }, onCommit: {
                print("onCommit")
            })
        }
        .padding(.horizontal)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
