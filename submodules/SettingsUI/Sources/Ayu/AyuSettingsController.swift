import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

private struct AyuSettingsState: Equatable {
    var sendReadMessages: Bool
    var sendReadStories: Bool
    var sendOnlinePackets: Bool
    var sendTypingPackets: Bool
    var saveDeletedMessages: Bool

    static func current() -> AyuSettingsState {
        return AyuSettingsState(
            sendReadMessages: AyuSettings.sendReadMessages,
            sendReadStories: AyuSettings.sendReadStories,
            sendOnlinePackets: AyuSettings.sendOnlinePackets,
            sendTypingPackets: AyuSettings.sendTypingPackets,
            saveDeletedMessages: AyuSettings.saveDeletedMessages
        )
    }

    var isGhostModeEnabled: Bool {
        return !self.sendReadMessages && !self.sendReadStories && !self.sendOnlinePackets && !self.sendTypingPackets
    }
}

private enum AyuSettingsToggle: Int32 {
    case ghostMode
    case sendReadMessages
    case sendReadStories
    case sendOnlinePackets
    case sendTypingPackets
    case saveDeletedMessages
}

private final class AyuSettingsControllerArguments {
    let toggle: (AyuSettingsToggle, Bool) -> Void

    init(toggle: @escaping (AyuSettingsToggle, Bool) -> Void) {
        self.toggle = toggle
    }
}

private enum AyuSettingsSection: Int32 {
    case ghost
    case packets
    case messages
}

private enum AyuSettingsControllerEntry: ItemListNodeEntry {
    case header(AyuSettingsSection, String)
    case toggle(AyuSettingsSection, AyuSettingsToggle, String, Bool)
    case info(AyuSettingsSection, String)

    var section: ItemListSectionId {
        switch self {
        case let .header(section, _), let .toggle(section, _, _, _), let .info(section, _):
            return section.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case let .header(section, _):
            return section.rawValue * 100
        case let .toggle(section, toggle, _, _):
            return section.rawValue * 100 + 1 + toggle.rawValue
        case let .info(section, _):
            return section.rawValue * 100 + 99
        }
    }

    static func ==(lhs: AyuSettingsControllerEntry, rhs: AyuSettingsControllerEntry) -> Bool {
        switch lhs {
        case let .header(lhsSection, lhsText):
            if case let .header(rhsSection, rhsText) = rhs, lhsSection == rhsSection, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .toggle(lhsSection, lhsToggle, lhsText, lhsValue):
            if case let .toggle(rhsSection, rhsToggle, rhsText, rhsValue) = rhs, lhsSection == rhsSection, lhsToggle == rhsToggle, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .info(lhsSection, lhsText):
            if case let .info(rhsSection, rhsText) = rhs, lhsSection == rhsSection, lhsText == rhsText {
                return true
            } else {
                return false
            }
        }
    }

    static func <(lhs: AyuSettingsControllerEntry, rhs: AyuSettingsControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuSettingsControllerArguments
        switch self {
        case let .header(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .toggle(_, toggle, text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                arguments.toggle(toggle, updatedValue)
            })
        case let .info(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private func ayuSettingsControllerEntries(state: AyuSettingsState) -> [AyuSettingsControllerEntry] {
    var entries: [AyuSettingsControllerEntry] = []

    entries.append(.toggle(.ghost, .ghostMode, "Режим призрака", state.isGhostModeEnabled))
    entries.append(.info(.ghost, "Не отправлять отметки о прочтении, статус «в сети», набор текста и просмотры историй."))

    entries.append(.header(.packets, "ОТПРАВЛЯТЬ НА СЕРВЕР"))
    entries.append(.toggle(.packets, .sendReadMessages, "Прочтение сообщений", state.sendReadMessages))
    entries.append(.toggle(.packets, .sendReadStories, "Просмотр историй", state.sendReadStories))
    entries.append(.toggle(.packets, .sendOnlinePackets, "Статус «в сети»", state.sendOnlinePackets))
    entries.append(.toggle(.packets, .sendTypingPackets, "Набор текста", state.sendTypingPackets))

    entries.append(.header(.messages, "СООБЩЕНИЯ"))
    entries.append(.toggle(.messages, .saveDeletedMessages, "Сохранять удалённые", state.saveDeletedMessages))
    entries.append(.info(.messages, "Сообщения, которые удалил собеседник, останутся в чате на этом устройстве."))

    return entries
}

public func ayuSettingsController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(AyuSettingsState.current(), ignoreRepeated: true)

    let arguments = AyuSettingsControllerArguments(toggle: { toggle, value in
        switch toggle {
        case .ghostMode:
            AyuSettings.isGhostModeEnabled = value
        case .sendReadMessages:
            AyuSettings.sendReadMessages = value
        case .sendReadStories:
            AyuSettings.sendReadStories = value
        case .sendOnlinePackets:
            AyuSettings.sendOnlinePackets = value
        case .sendTypingPackets:
            AyuSettings.sendTypingPackets = value
        case .saveDeletedMessages:
            AyuSettings.saveDeletedMessages = value
        }
        statePromise.set(AyuSettingsState.current())
    })

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("AyuGram"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: ayuSettingsControllerEntries(state: state), style: .blocks, animateChanges: false)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    return controller
}
