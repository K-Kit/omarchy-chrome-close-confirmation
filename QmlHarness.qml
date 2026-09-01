import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
  id: harness

  readonly property string responseFifo:
    Quickshell.env("OMARCHY_PLUGIN_QA_RESPONSE_FIFO")
  readonly property string windowTitle:
    Quickshell.env("OMARCHY_PLUGIN_QA_WINDOW_TITLE") || "QML integration test"

  PanelWindow {
    visible: harness.responseFifo.length > 0
    anchors {
      top: true
      right: true
      bottom: true
      left: true
    }
    color: "#626872"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "omarchy-plugin-qa-backdrop"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
      width: parent.width / 2
      height: parent.height
      color: "#8a929e"
    }
  }

  QtObject {
    id: shellHost

    function hide(_pluginId) {
      plugin.close()
    }
  }

  Plugin {
    id: plugin

    shell: shellHost
    manifest: ({
      id: "k-kit.chrome-close-confirmation"
    })
  }

  Component.onCompleted: {
    if (plugin.ping("") !== "ready") {
      console.error("PLUGIN_SMOKE_FAILED")
      return
    }

    console.log("PLUGIN_SMOKE_READY")
    if (responseFifo.length === 0)
      return

    Qt.callLater(function() {
      plugin.open(JSON.stringify({
        responseFifo: harness.responseFifo,
        windowTitle: harness.windowTitle
      }))
      Qt.callLater(function() {
        console.log("PLUGIN_UI_READY")
      })
    })
  }
}
