import Foundation

extension Date {
    var shortDayOfWeek: String {
        DateFormatters.dayOfWeekShort.string(from: self)
    }

    var mediumDateString: String {
        DateFormatters.mediumDate.string(from: self)
    }

    var timeString: String {
        DateFormatters.time.string(from: self)
    }

    var relativeString: String {
        DateFormatters.formatRelative(self)
    }
}

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
