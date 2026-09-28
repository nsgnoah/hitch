import SwiftUI
import UIKit

/// Brings up the system keyboard and forwards keystrokes, without a visible text field.
/// Also receives hardware keyboard input on iPad.
struct KeyCatcher: UIViewRepresentable {
    var active: Bool
    var focusToken: Int
    let onLetter: (Character) -> Void
    let onDelete: () -> Void
    let onEnter: () -> Void
    /// Tab or an arrow key on a hardware keyboard: jump to the other end of the chain.
    let onSwitch: () -> Void

    func makeUIView(context: Context) -> KeyInputView {
        KeyInputView()
    }

    func updateUIView(_ view: KeyInputView, context: Context) {
        view.onLetter = onLetter
        view.onDelete = onDelete
        view.onEnter = onEnter
        view.onSwitch = onSwitch

        let refocus = context.coordinator.lastToken != focusToken
        context.coordinator.lastToken = focusToken
        DispatchQueue.main.async {
            if active, !view.isFirstResponder || refocus {
                view.becomeFirstResponder()
            } else if !active, view.isFirstResponder {
                view.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var lastToken = 0
    }
}

final class KeyInputView: UIView, UIKeyInput {
    var onLetter: (Character) -> Void = { _ in }
    var onDelete: () -> Void = {}
    var onEnter: () -> Void = {}
    var onSwitch: () -> Void = {}

    // Keyboard traits: plain capitals, no autocorrect or suggestions.
    var keyboardType: UIKeyboardType = .asciiCapable
    var autocapitalizationType: UITextAutocapitalizationType = .allCharacters
    var autocorrectionType: UITextAutocorrectionType = .no
    var spellCheckingType: UITextSpellCheckingType = .no
    var smartInsertDeleteType: UITextSmartInsertDeleteType = .no
    var returnKeyType: UIReturnKeyType = .go
    var enablesReturnKeyAutomatically = false

    override var canBecomeFirstResponder: Bool { true }

    override var inputAssistantItem: UITextInputAssistantItem {
        let item = super.inputAssistantItem
        item.leadingBarButtonGroups = []
        item.trailingBarButtonGroups = []
        return item
    }

    override var keyCommands: [UIKeyCommand]? {
        let keys: [(String, UIKeyModifierFlags)] = [
            ("\t", []), ("\t", .shift), (UIKeyCommand.inputUpArrow, []), (UIKeyCommand.inputDownArrow, []),
        ]
        return keys.map { input, flags in
            let command = UIKeyCommand(input: input, modifierFlags: flags, action: #selector(switchWord))
            command.wantsPriorityOverSystemBehavior = true
            return command
        }
    }

    @objc private func switchWord() {
        onSwitch()
    }

    /// Always true so the delete key stays enabled.
    var hasText: Bool { true }

    func insertText(_ text: String) {
        for c in text {
            if c == "\n" {
                onEnter()
            } else if c.isLetter, c.isASCII {
                onLetter(c)
            }
        }
    }

    func deleteBackward() {
        onDelete()
    }
}
