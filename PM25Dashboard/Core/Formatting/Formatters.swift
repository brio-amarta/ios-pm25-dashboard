import Foundation

enum DashboardFormatters {
    static func concentration(_ value: Double?) -> String {
        guard let value else { return "—" }
        return value.formatted(.number.precision(.fractionLength(1))) + " µg/m³"
    }

    static func number(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic))
    }

    static func signedConcentration(_ value: Double?) -> String {
        guard let value else { return "—" }
        let prefix = value > 0 ? "+" : ""
        return prefix + value.formatted(.number.precision(.fractionLength(1))) + " µg/m³"
    }

    static func relative(_ date: Date?, now: Date = Date()) -> String {
        guard let date else { return "Never" }
        return date.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated))
    }

    static func hour(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    static func dateTime(_ date: Date?) -> String {
        guard let date else { return "Never" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

