//
//  ContentView.swift
//  CombineSample
//
//  Created by akifumi.fukaya on 2019/06/13.
//  Copyright © 2019 Akifumi Fukaya. All rights reserved.
//

import SwiftUI
import Combine

final class ContentViewModel : ObservableObject {
    var willChange = PassthroughSubject<Void, Never>()
    @Published
    var username: String = "" {
        didSet {
            willChange.send(())
        }
    }
    struct StatusText {
        let content: String
        let color: Color
    }
    @Published
    var status: StatusText = StatusText(content: "NG", color: .red) {
        didSet {
            willChange.send(())
        }
    }
    private var validatedUsername: AnyPublisher<String?, Never> {
        return $username
            .debounce(for: 0.1, scheduler: RunLoop.main)
            .removeDuplicates()
            .flatMap { (username) -> AnyPublisher<String?, Never> in
                Future<String?, Never> { (promise) in
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

    private var usernameCancellable: AnyCancellable?
    private var statusCancellable: AnyCancellable?

    lazy var onAppear: () -> Void = { [weak self] in
        guard let self = self else { return }
        self.usernameCancellable = self.validatedUsername
            .sink(receiveValue: { [weak self] (value) in
                if let value = value {
                    self?.username = value
                } else {
                    print("validatedUsername.receiveValue: Invalid username")
                }
            })

        // Update StatusText
        self.statusCancellable = self.validatedUsername
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
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        VStack {
            HStack {
                Text($viewModel.status.value.content)
                    .foregroundColor($viewModel.status.value.color)
                Spacer()
            }
            TextField("Placeholder", text: $viewModel.username, onEditingChanged: { (changed) in
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
