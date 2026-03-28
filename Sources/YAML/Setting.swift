//
//  Setting.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

final class Setting<T> {
    private var value: T
    private var defaultValue: T

    init(_ defaultValue: T) {
        self.value = defaultValue
        self.defaultValue = defaultValue
    }

    func get() -> T { value }

    @discardableResult
    func set(_ newValue: T) -> () -> Void {
        let oldValue = value
        value = newValue
        return { [weak self] in self?.value = oldValue }
    }

    func restore() { value = defaultValue }
}

final class SettingChanges {
    private var undos: [() -> Void] = []

    func push(_ undo: @escaping () -> Void) {
        undos.append(undo)
    }

    func restore() {
        for undo in undos.reversed() {
            undo()
        }
    }

    func clear() {
        undos.removeAll()
    }
}
