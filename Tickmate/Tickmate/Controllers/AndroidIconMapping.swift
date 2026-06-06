//
//  AndroidIconMapping.swift
//  Tickmate
//
//  Maps the Glyphicons icons used by Tickmate for Android onto the closest
//  available SF Symbols when importing an Android database export.
//

import Foundation

enum AndroidIconMapping {
    static func systemImage(forAndroidIcon icon: String?, trackName: String) -> String {
        // Android stores the full Glyphicons drawable resource name, e.g.
        // "glyphicons_273_drink_white". Reduce it to its descriptive token
        // ("drink") and look that up in the explicit SF Symbol mapping.
        if let token = iconToken(from: icon), let symbol = glyphiconSymbols[token] {
            return symbol
        }

        // Fall back to fuzzy keyword matching against the (free-text) track name
        // for databases that lack an icon, or icons with no direct counterpart.
        let haystack = ((icon ?? "") + " " + trackName).lowercased()
        let keywordMappings: [(String, String)] = [
            ("water", "drop.fill"),
            ("drink", "wineglass.fill"),
            ("coffee", "cup.and.saucer.fill"),
            ("cake", "birthday.cake.fill"),
            ("food", "fork.knife"),
            ("smok", "smoke.fill"),
            ("hospital", "cross.case.fill"),
            ("med", "pills.fill"),
            ("pill", "pills.fill"),
            ("gym", "dumbbell.fill"),
            ("dumbbell", "dumbbell.fill"),
            ("run", "figure.run"),
            ("sport", "figure.run"),
            ("bike", "bicycle"),
            ("bicycle", "bicycle"),
            ("car", "car.fill"),
            ("train", "tram.fill"),
            ("dog", "dog.fill"),
            ("cat", "cat.fill"),
            ("flower", "camera.macro"),
            ("leaf", "leaf.fill"),
            ("plant", "leaf.fill"),
            ("piano", "pianokeys"),
            ("music", "music.note"),
            ("clean", "sparkles"),
            ("read", "book.fill"),
            ("book", "book.fill"),
            ("sleep", "bed.double.fill"),
            ("work", "briefcase.fill"),
            ("money", "dollarsign.circle.fill"),
            ("facebook", "person.2.fill"),
            ("email", "envelope.fill"),
            ("mail", "envelope.fill")
        ]
        return keywordMappings.first { haystack.contains($0.0) }?.1 ?? "checkmark"
    }

    /// Extracts the descriptive token from an Android Glyphicons drawable name,
    /// e.g. "glyphicons_273_drink_white" -> "drink", "myicons_smiley_white" -> "smiley".
    private static func iconToken(from icon: String?) -> String? {
        guard var token = icon?.lowercased(), !token.isEmpty else { return nil }
        if token.hasSuffix("_white") {
            token.removeLast("_white".count)
        }
        if token.hasPrefix("glyphicons_") {
            token.removeFirst("glyphicons_".count)
            // Drop the leading numeric id ("273_").
            if let underscore = token.firstIndex(of: "_"),
               token[token.startIndex..<underscore].allSatisfy(\.isNumber) {
                token = String(token[token.index(after: underscore)...])
            }
        } else if token.hasPrefix("myicons_") {
            token.removeFirst("myicons_".count)
        }
        return token.isEmpty ? nil : token
    }

    /// Maps Glyphicons descriptive tokens to the closest available SF Symbol.
    /// Tokens with no reasonable SF Symbol counterpart (brand logos, vector path
    /// editing tools, etc.) are intentionally omitted and fall through to the
    /// keyword/track-name heuristics, then to "checkmark".
    private static let glyphiconSymbols: [String: String] = [
        // Food, drink & dining
        "glass": "wineglass.fill",
        "drink": "wineglass.fill",
        "beer": "mug.fill",
        "cup": "cup.and.saucer.fill",
        "coffe_cup": "cup.and.saucer.fill",
        "tea_kettle": "cup.and.saucer.fill",
        "kettle": "cup.and.saucer.fill",
        "french_press": "cup.and.saucer.fill",
        "fast_food": "takeoutbag.and.cup.and.straw.fill",
        "cutlery": "fork.knife",
        "pizza": "fork.knife",
        "cake": "birthday.cake.fill",
        "birthday_cake": "birthday.cake.fill",
        "celebration": "party.popper.fill",

        // Nature, animals & weather
        "leaf": "leaf.fill",
        "flower": "camera.macro",
        "tree_conifer": "tree.fill",
        "tree_deciduous": "tree.fill",
        "dog": "dog.fill",
        "turtle": "tortoise.fill",
        "rabbit": "hare.fill",
        "fishes": "fish.fill",
        "snowflake": "snowflake",
        "fire": "flame.fill",
        "heat": "thermometer.high",
        "moon": "moon.fill",
        "sun": "sun.max.fill",
        "cloud": "cloud.fill",
        "globe": "globe",
        "global": "globe",
        "globe_af": "globe",

        // People
        "user": "person.fill",
        "girl": "person.fill",
        "woman": "person.fill",
        "old_man": "figure.walk",
        "male": "person.fill",
        "female": "person.fill",
        "user_add": "person.badge.plus",
        "user_remove": "person.badge.minus",
        "group": "person.3.fill",
        "parents": "person.2.fill",
        "vcard": "person.crop.rectangle.fill",
        "nameplate": "person.text.rectangle.fill",
        "nameplate_alt": "person.text.rectangle.fill",
        "adress_book": "person.text.rectangle.fill",

        // Health, sport & activity
        "hospital": "cross.case.fill",
        "hospital_h": "cross.fill",
        "cardio": "waveform.path.ecg",
        "dumbbell": "dumbbell.fill",
        "bicycle": "bicycle",
        "baseball": "baseball.fill",
        "rugby": "rugbyball.fill",
        "soccer_ball": "soccerball",
        "table_tennis": "figure.table.tennis",
        "bowling": "figure.bowling",
        "pool": "figure.pool.swim",
        "fins": "figure.pool.swim",
        "snorkel_diving": "figure.open.water.swim",
        "scuba_diving": "figure.open.water.swim",

        // Clothing
        "t_shirt": "tshirt.fill",
        "sweater": "tshirt.fill",
        "scissors": "scissors",

        // Transport & travel
        "car": "car.fill",
        "cars": "car.2.fill",
        "bus": "bus.fill",
        "train": "tram.fill",
        "truck": "truck.box.fill",
        "cargo": "shippingbox.fill",
        "airplane": "airplane",
        "boat": "sailboat.fill",
        "road": "road.lanes",
        "luggage": "suitcase.fill",
        "suitcase": "suitcase.fill",
        "beach_umbrella": "beach.umbrella.fill",
        "compass": "safari.fill",
        "anchor": "ferry.fill",
        "life_preserver": "lifepreserver",
        "buoy": "lifepreserver",
        "direction": "arrow.triangle.turn.up.right.diamond.fill",
        "google_maps": "map.fill",
        "pin": "mappin",
        "pin_flag": "mappin.and.ellipse",
        "pushpin": "pin.fill",

        // Home & objects
        "home": "house.fill",
        "building": "building.2.fill",
        "bank": "building.columns.fill",
        "gift": "gift.fill",
        "umbrella": "umbrella.fill",
        "magnet": "rectangle.portrait.and.arrow.right.fill",
        "ring": "circle.circle.fill",
        "crown": "crown.fill",
        "sheriffs_star": "star.circle.fill",
        "certificate": "rosette",
        "shield": "shield.fill",
        "bomb": "burst.fill",
        "candle": "flame.fill",
        "bell": "bell.fill",
        "bullhorn": "megaphone.fill",
        "bug": "ladybug.fill",
        "spray": "drop.fill",
        "tint": "drop.fill",
        "claw_hammer": "hammer.fill",
        "classic_hammer": "hammer.fill",
        "hand_saw": "wrench.and.screwdriver.fill",
        "riflescope": "scope",

        // Money & shopping
        "coins": "dollarsign.circle.fill",
        "euro": "eurosign.circle.fill",
        "usd": "dollarsign.circle.fill",
        "gbp": "sterlingsign.circle.fill",
        "credit_card": "creditcard.fill",
        "wallet": "wallet.pass.fill",
        "shopping_cart": "cart.fill",
        "cart_in": "cart.badge.plus",
        "cart_out": "cart.badge.minus",
        "shopping_bag": "bag.fill",

        // Communication
        "envelope": "envelope.fill",
        "e_mail": "envelope.fill",
        "message_full": "envelope.fill",
        "message_empty": "envelope",
        "message_in": "envelope.open.fill",
        "message_out": "paperplane.fill",
        "message_plus": "plus.message.fill",
        "message_flag": "flag.fill",
        "message_lock": "lock.fill",
        "message_new": "envelope.badge.fill",
        "conversation": "bubble.left.and.bubble.right.fill",
        "comments": "bubble.left.and.bubble.right.fill",
        "chat": "bubble.left.fill",
        "blog": "text.bubble.fill",
        "phone": "phone.fill",
        "facetime_video": "video.fill",
        "microphone": "mic.fill",
        "webcam": "video.fill",
        "security_camera": "video.fill",
        "signal": "antenna.radiowaves.left.and.right",
        "wifi": "wifi",
        "wifi_alt": "wifi",
        "router": "network",
        "rss": "dot.radiowaves.up.forward",

        // Devices & media
        "imac": "desktopcomputer",
        "macbook": "laptopcomputer",
        "ipad": "ipad",
        "tablet": "ipad",
        "iphone": "iphone",
        "iphone_transfer": "iphone",
        "iphone_exchange": "iphone",
        "iphone_shake": "iphone.radiowaves.left.and.right",
        "ipod": "ipodtouch",
        "ipod_shuffle": "music.note",
        "ear_plugs": "earbuds",
        "headphones": "headphones",
        "headset": "headphones",
        "camera": "camera.fill",
        "camera_small": "camera.fill",
        "screenshot": "camera.viewfinder",
        "picture": "photo.fill",
        "film": "film.fill",
        "albums": "rectangle.stack.fill",
        "display": "display",
        "hdd": "internaldrive.fill",
        "keyboard_wireless": "keyboard.fill",
        "keyboard_wired": "keyboard.fill",
        "gamepad": "gamecontroller.fill",
        "playing_dices": "dice.fill",
        "projector": "videoprojector.fill",
        "keynote": "play.rectangle.fill",
        "podium": "music.mic",

        // Media controls
        "step_backward": "backward.end.fill",
        "fast_backward": "backward.fill",
        "rewind": "backward.fill",
        "play": "play.fill",
        "play_button": "play.circle.fill",
        "pause": "pause.fill",
        "stop": "stop.fill",
        "forward": "forward.fill",
        "fast_forward": "forward.fill",
        "step_forward": "forward.end.fill",
        "eject": "eject.fill",
        "mute": "speaker.slash.fill",
        "volume_down": "speaker.wave.1.fill",
        "volume_up": "speaker.wave.3.fill",
        "playlist": "music.note.list",
        "music": "music.note",
        "note": "music.note",
        "sampler": "music.note",

        // Time
        "alarm": "alarm.fill",
        "clock": "clock.fill",
        "stopwatch": "stopwatch.fill",
        "history": "clock.arrow.circlepath",
        "calendar": "calendar",

        // Symbols & UI
        "heart": "heart.fill",
        "heart_empty": "heart",
        "star": "star.fill",
        "magic": "wand.and.stars",
        "binoculars": "binoculars.fill",
        "search": "magnifyingglass",
        "zoom_in": "plus.magnifyingglass",
        "zoom_out": "minus.magnifyingglass",
        "eye_open": "eye.fill",
        "eye_close": "eye.slash.fill",
        "link": "link",
        "tag": "tag.fill",
        "tags": "tag.fill",
        "flag": "flag.fill",
        "bookmark": "bookmark.fill",
        "book": "book.fill",
        "book_open": "book.fill",
        "log_book": "book.closed.fill",
        "lightbulb": "lightbulb.fill",
        "power": "power",
        "electricity": "bolt.fill",
        "flash": "bolt.fill",
        "electrical_plug": "powerplug.fill",
        "electrical_socket_eu": "powerplug.fill",
        "electrical_socket_us": "powerplug.fill",
        "paperclip": "paperclip",
        "key": "key.fill",
        "keys": "key.fill",
        "lock": "lock.fill",
        "unlock": "lock.open.fill",
        "rotation_lock": "lock.rotation",
        "smiley": "face.smiling",
        "smoking": "smoke.fill",
        "skull": "exclamationmark.triangle.fill",
        "warning_sign": "exclamationmark.triangle.fill",
        "qrcode": "qrcode",
        "barcode": "barcode",
        "spade": "suit.spade.fill",
        "piano": "pianokeys",
        "dashboard": "gauge.medium",
        "settings": "gearshape.fill",
        "cogwheel": "gearshape.fill",
        "cogwheels": "gearshape.2.fill",
        "briefcase": "briefcase.fill",
        "cleaning": "sparkles",

        // Charts & data
        "stats": "chart.bar.fill",
        "charts": "chart.line.uptrend.xyaxis",
        "pie_chart": "chart.pie.fill",
        "calculator": "function",
        "database_lock": "cylinder.fill",
        "database_plus": "cylinder.fill",
        "database_minus": "cylinder.fill",
        "database_ban": "cylinder.fill",
        "table": "tablecells",
        "list": "list.bullet",
        "bullets": "list.bullet",

        // Files
        "file": "doc.fill",
        "notes": "note.text",
        "notes_2": "note.text",
        "file_import": "square.and.arrow.down.fill",
        "file_export": "square.and.arrow.up.fill",
        "inbox": "tray.fill",
        "inbox_in": "tray.and.arrow.down.fill",
        "inbox_out": "tray.and.arrow.up.fill",
        "folder_open": "folder.fill",
        "folder_plus": "folder.fill.badge.plus",
        "folder_minus": "folder.fill.badge.minus",
        "folder_new": "folder.badge.plus",
        "print": "printer.fill",
        "bin": "trash.fill",
        "delete": "trash.fill",
        "edit": "pencil",
        "pencil": "pencil",
        "pen": "pencil",
        "brush": "paintbrush.fill",
        "eyedropper": "eyedropper",
        "ruller": "ruler.fill",
        "new_window": "macwindow",
        "more_windows": "macwindow.on.rectangle",

        // Cloud & transfer
        "download": "arrow.down.circle",
        "download_alt": "arrow.down.circle.fill",
        "upload": "arrow.up.circle",
        "cloud_upload": "icloud.and.arrow.up.fill",
        "cloud_download": "icloud.and.arrow.down.fill",
        "share": "square.and.arrow.up",
        "share_alt": "square.and.arrow.up",
        "unshare": "square.and.arrow.up",

        // Text formatting
        "font": "textformat",
        "italic": "italic",
        "bold": "bold",
        "text_underline": "underline",
        "text_strike": "strikethrough",
        "text_height": "textformat.size",
        "text_width": "textformat.size",
        "text_resize": "textformat.size",
        "text_smaller": "textformat.size.smaller",
        "text_bigger": "textformat.size.larger",
        "left_indent": "decrease.indent",
        "right_indent": "increase.indent",
        "align_left": "text.alignleft",
        "align_center": "text.aligncenter",
        "align_right": "text.alignright",
        "justify": "text.justify",
        "embed": "chevron.left.forwardslash.chevron.right",
        "embed_close": "chevron.left.forwardslash.chevron.right",

        // Religion
        "temple_christianity_church": "cross.fill",
        "temple_islam": "moon.stars.fill",

        // Hands & gestures
        "thumbs_up": "hand.thumbsup.fill",
        "dislikes": "hand.thumbsdown.fill",
        "thumbs_down": "hand.thumbsdown.fill",
        "hand_right": "hand.point.right.fill",
        "hand_left": "hand.point.left.fill",
        "hand_up": "hand.point.up.fill",
        "hand_down": "hand.point.down.fill",

        // Arrows & navigation
        "left_arrow": "arrow.left",
        "right_arrow": "arrow.right",
        "down_arrow": "arrow.down",
        "up_arrow": "arrow.up",
        "circle_arrow_left": "arrow.left.circle.fill",
        "circle_arrow_right": "arrow.right.circle.fill",
        "circle_arrow_top": "arrow.up.circle.fill",
        "circle_arrow_down": "arrow.down.circle.fill",
        "chevron_right": "chevron.right",
        "chevron_left": "chevron.left",
        "refresh": "arrow.clockwise",
        "restart": "arrow.clockwise",
        "retweet": "arrow.2.squarepath",
        "retweet_2": "arrow.2.squarepath",
        "roundabout": "arrow.triangle.2.circlepath",
        "random": "shuffle",
        "repeat": "repeat",
        "sort": "arrow.up.arrow.down",
        "filter": "line.3.horizontal.decrease.circle",
        "move": "arrow.up.and.down.and.arrow.left.and.right",
        "resize_small": "arrow.down.right.and.arrow.up.left",
        "resize_full": "arrow.up.left.and.arrow.down.right",
        "fullscreen": "arrow.up.left.and.arrow.down.right",
        "expand": "arrow.up.left.and.arrow.down.right",
        "collapse": "arrow.down.right.and.arrow.up.left",
        "collapse_top": "chevron.up",
        "brightness_reduce": "sun.min.fill",
        "brightness_increase": "sun.max.fill",

        // Status & marks
        "check": "checkmark",
        "ok": "checkmark",
        "ok_2": "checkmark",
        "unchecked": "square",
        "remove": "xmark",
        "remove_2": "xmark",
        "ban": "nosign",
        "more": "ellipsis",
        "more_items": "ellipsis",
        "asterisk": "asterisk",
        "divide": "divide",
        "circle_plus": "plus.circle.fill",
        "circle_minus": "minus.circle.fill",
        "circle_remove": "xmark.circle.fill",
        "circle_ok": "checkmark.circle.fill",
        "circle_question_mark": "questionmark.circle.fill",
        "circle_info": "info.circle.fill",
        "circle_exclamation_mark": "exclamationmark.circle.fill",
        "adjust": "circle.lefthalf.filled",
        "adjust_alt": "circle.lefthalf.filled",
        "crop": "crop",

        // Vector path tools (approximate shapes)
        "vector_path_square": "square",
        "vector_path_circle": "circle",
        "vector_path_polygon": "hexagon",
        "vector_path_line": "line.diagonal",
        "vector_path_curve": "scribble",
        "vector_path_all": "scribble.variable"
    ]
}
