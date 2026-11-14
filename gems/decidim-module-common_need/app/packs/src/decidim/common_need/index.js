import { Application } from "@hotwired/stimulus"
import CatalogFilterController from "./controllers/catalog_filter_controller"
import CalendarViewController from "./controllers/calendar_view_controller"
import VoiceNavController from "./controllers/voice_nav_controller"
import OfflineSyncController from "./controllers/offline_sync_controller"
import PaperworkCopilotController from "./controllers/paperwork_copilot_controller"

const application = window.Stimulus || Application.start()
window.Stimulus = application

application.register("catalog-filter", CatalogFilterController)
application.register("calendar-view", CalendarViewController)
application.register("voice-nav", VoiceNavController)
application.register("offline-sync", OfflineSyncController)
application.register("paperwork-copilot", PaperworkCopilotController)

export {
  CatalogFilterController,
  CalendarViewController,
  VoiceNavController,
  OfflineSyncController,
  PaperworkCopilotController
}
