// Placeholder for Kotlin/Java AppWidgetProvider.
// Flutter can't directly define widget providers — the host project uses
// flutter_widget_from_a_package's AppWidgetProvider bridge OR
// a small Kotlin helper. We create the file here so Android recognizes the
// provider and forwards clicks via the AppWidgetReceiver.
//
// In a real integration you'd:
//  1. Add `android:name=".widget.WidgetBoardProvider"` in manifest.
//  2. Tap opens MainActivity so Flutter can read shared prefs for the note.
//  3. Notes written from the Flutter app use SharedPreferences (flutter)
//     + AppWidgetManager.update() (Kotlin) to repaint the widget.
