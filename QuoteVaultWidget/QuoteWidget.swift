//
//  QuoteWidget.swift
//  QuoteVaultWidget
//
//  Main widget configuration
//

import WidgetKit
import SwiftUI

/// Main widget configuration
@main
struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteWidgetProvider()) { entry in
            QuoteWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "quotevault://qotd"))
        }
        .configurationDisplayName("Quote of the Day")
        .description("Display your daily inspirational quote on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Preview

struct QuoteWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            QuoteWidgetEntryView(entry: .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            QuoteWidgetEntryView(entry: .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
