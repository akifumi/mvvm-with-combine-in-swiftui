//
//  ContentView.swift
//  CombineSample
//
//  Created by akifumi.fukaya on 2019/06/13.
//  Copyright © 2019 Akifumi Fukaya. All rights reserved.
//

import SwiftUI
import Combine

final class ContentViewModel : BindableObject {
    var didChange = PassthroughSubject<Void, Never>()
    var username: String = "" {
        didSet {
            guard oldValue != username else { return }
            usernameSubject.send(username)
            didChange.send(())
        }
    }
    struct StatusText {
        let content: String
        let color: Color
    }
    var status: StatusText = StatusText(content: "NG", color: .red) {
        didSet {
            didChange.send(())
        }
    }
    private let usernameSubject = PassthroughSubject<String, Never>()
    private var validatedUsername: AnyPublisher<String?, Never> {
        return usernameSubject
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .flatMap { (username) -> AnyPublisher<String?, Never> in
                Publishers.Future<String?, Never> { (promise) in
                    // FIXME: API request
                    if 1...10 ~= username.count {
                        promise(.success(username))
                    } else {
                        promise(.success(nil))
                    }
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    lazy var onAppear: () -> Void = { [weak self] in
        _ = self?.validatedUsername
            .sink(receiveValue: { (value) in
                if let value = value {
                    self?.username = value
                } else {
                    print("validatedUsername.receiveValue: Invalid username")
                }
            })

        // Update StatusText
        _ = self?.validatedUsername
            .map { (value) -> StatusText in
                if let _ = value {
                    return StatusText(content: "OK", color: .green)
                } else {
                    return StatusText(content: "NG", color: .red)
                }
            }
            .sink(receiveValue: { [weak self] (value) in
                self?.status = value
            })
    }
}

struct ContentView : View {
    @ObjectBinding var viewModel: ContentViewModel

    var body: some View {
        VStack {
            HStack {
                Text($viewModel.status.value.content)
                    .color($viewModel.status.value.color)
                Spacer()
            }
            TextField($viewModel.username, placeholder: Text("Placeholder"), onEditingChanged: { (changed) in
                print("onEditingChanged: \(changed)")
            }, onCommit: {
                print("onCommit")
            })
        }
        .padding(.horizontal)
        .onAppear(perform: viewModel.onAppear)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ContentViewModel())
    }
}
#endif
