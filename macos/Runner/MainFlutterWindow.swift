import Cocoa
import FlutterMacOS

import desktop_multi_window
import fvp
import video_player_avfoundation

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
        FvpPlugin.register(with: controller.registrar(forPlugin: "FvpPlugin"))
        FVPVideoPlayerPlugin.register(with: controller.registrar(forPlugin: "FVPVideoPlayerPlugin"))
    }
    super.awakeFromNib()
  }
}
