import Cocoa
import FlutterMacOS

import desktop_multi_window
import fvp
import video_player_avfoundation
import flutter_window_close

import screen_retriever
import window_manager

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
        FlutterWindowClosePlugin.register(with: controller.registrar(forPlugin: "FlutterWindowClosePlugin"))
        FvpPlugin.register(with: controller.registrar(forPlugin: "FvpPlugin"))
        FVPVideoPlayerPlugin.register(with: controller.registrar(forPlugin: "FVPVideoPlayerPlugin"))


        ScreenRetrieverPlugin.register(with: controller.registrar(forPlugin: "ScreenRetrieverPlugin"))
        WindowManagerPlugin.register(with: controller.registrar(forPlugin: "WindowManagerPlugin"))

    }
    super.awakeFromNib()
  }
}
