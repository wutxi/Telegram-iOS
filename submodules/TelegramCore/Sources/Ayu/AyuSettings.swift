import Foundation

// AyuGram feature flags, stored in the standard user defaults of the main app.
// Every "send" flag defaults to true, so a fresh install behaves like stock Telegram.
public enum AyuSettings {
    private enum Key: String {
        case sendReadMessages = "ayu.sendReadMessages"
        case sendReadStories = "ayu.sendReadStories"
        case sendOnlinePackets = "ayu.sendOnlinePackets"
        case sendTypingPackets = "ayu.sendTypingPackets"
        case saveDeletedMessages = "ayu.saveDeletedMessages"
    }

    private static func load(_ key: Key, default defaultValue: Bool) -> Bool {
        if let value = UserDefaults.standard.object(forKey: key.rawValue) as? Bool {
            return value
        }
        return defaultValue
    }

    private static func store(_ key: Key, _ value: Bool) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    public static var sendReadMessages: Bool {
        get { return load(.sendReadMessages, default: true) }
        set { store(.sendReadMessages, newValue) }
    }

    public static var sendReadStories: Bool {
        get { return load(.sendReadStories, default: true) }
        set { store(.sendReadStories, newValue) }
    }

    public static var sendOnlinePackets: Bool {
        get { return load(.sendOnlinePackets, default: true) }
        set { store(.sendOnlinePackets, newValue) }
    }

    public static var sendTypingPackets: Bool {
        get { return load(.sendTypingPackets, default: true) }
        set { store(.sendTypingPackets, newValue) }
    }

    public static var saveDeletedMessages: Bool {
        get { return load(.saveDeletedMessages, default: false) }
        set { store(.saveDeletedMessages, newValue) }
    }

    // Ghost mode is all four "send" flags turned off.
    public static var isGhostModeEnabled: Bool {
        get {
            return !sendReadMessages && !sendReadStories && !sendOnlinePackets && !sendTypingPackets
        }
        set {
            sendReadMessages = !newValue
            sendReadStories = !newValue
            sendOnlinePackets = !newValue
            sendTypingPackets = !newValue
        }
    }
}
