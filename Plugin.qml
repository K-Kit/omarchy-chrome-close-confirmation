import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property bool requestPending: false
  property int selectedIndex: 0
  property string responseFifo: ""
  property string windowTitle: "Google Chrome"

  readonly property string pluginId:
    (manifest && manifest.id) || "k-kit.chrome-close-confirmation"

  function ping(_payload) {
    return "ready"
  }

  function open(payloadJson) {
    if (requestPending)
      writeResponse("keep-open")

    var payload = ({})
    try {
      payload = JSON.parse(String(payloadJson || "{}")) || ({})
    } catch (error) {
      payload = ({})
    }

    responseFifo = String(payload.responseFifo || "")
    windowTitle = String(payload.windowTitle || "Google Chrome").slice(0, 512)
    requestPending = responseFifo.length > 0
    selectedIndex = 0
    opened = true

    Qt.callLater(function() {
      if (root.opened)
        keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    if (requestPending)
      writeResponse("keep-open")
    opened = false
  }

  function writeResponse(value) {
    if (!requestPending)
      return

    var fifo = responseFifo
    requestPending = false
    responseFifo = ""

    Quickshell.execDetached([
      "timeout",
      "2",
      "bash",
      "-c",
      "[[ -p \"$2\" ]] && printf '%s\\n' \"$1\" > \"$2\"",
      "chrome-close-response",
      value,
      fifo
    ])
  }

  function finish(value) {
    writeResponse(value)
    opened = false

    if (shell && typeof shell.hide === "function")
      shell.hide(pluginId)
  }

  Component.onDestruction: {
    if (requestPending)
      writeResponse("keep-open")
  }

  PanelWindow {
    id: panel

    visible: root.opened
    anchors {
      top: true
      right: true
      bottom: true
      left: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "omarchy-chrome-close-confirmation"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus:
      root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.finish("keep-open")
    }

    BorderSurface {
      id: card

      width: Math.min(Style.space(420), panel.width - Style.gapsOut * 2)
      height:
        content.implicitHeight + contentTopInset + contentBottomInset
      anchors.centerIn: parent
      color: Color.menu.background
      borderSpec: Border.surfaceSpec(
        "menu",
        "border",
        Color.menu.border,
        Math.max(1, Style.space(2))
      )
      padding: Style.spacing.panelPadding
      radius: Style.cornerRadius

      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      Column {
        id: content

        x: card.contentLeftInset
        y: card.contentTopInset
        width:
          card.width - card.contentLeftInset - card.contentRightInset
        spacing: Style.spacing.panelGap

        Text {
          width: parent.width
          text: "Close this Chrome window?"
          textFormat: Text.PlainText
          color: Color.menu.text
          font.family: Style.font.menuFamily
          font.pixelSize: Style.font.heading
          font.bold: true
          wrapMode: Text.WordWrap
        }

        Text {
          width: parent.width
          text: root.windowTitle
          textFormat: Text.PlainText
          color: Color.menu.text
          opacity: 0.72
          font.family: Style.font.menuFamily
          font.pixelSize: Style.font.body
          wrapMode: Text.Wrap
          maximumLineCount: 2
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          text: "All tabs in this window will be closed."
          textFormat: Text.PlainText
          color: Color.menu.text
          opacity: 0.58
          font.family: Style.font.menuFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }

        Item {
          width: parent.width
          height: actions.implicitHeight

          Row {
            id: actions

            anchors.right: parent.right
            spacing: Style.spacing.controlGap

            Button {
              text: "Keep Open"
              bordered: true
              hasCursor: root.selectedIndex === 0
              onHovered: function(isHovered) {
                if (isHovered)
                  root.selectedIndex = 0
              }
              onClicked: root.finish("keep-open")
            }

            Button {
              text: "Close"
              bordered: true
              foreground: Color.urgent
              hasCursor: root.selectedIndex === 1
              onHovered: function(isHovered) {
                if (isHovered)
                  root.selectedIndex = 1
              }
              onClicked: root.finish("close")
            }
          }
        }
      }
    }

    Item {
      id: keyCatcher

      anchors.fill: parent
      focus: true

      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.finish("keep-open")
        } else if (
          event.key === Qt.Key_Left
          || event.key === Qt.Key_Right
          || event.key === Qt.Key_Tab
          || event.key === Qt.Key_Backtab
        ) {
          root.selectedIndex = root.selectedIndex === 0 ? 1 : 0
        } else if (
          event.key === Qt.Key_Return
          || event.key === Qt.Key_Enter
          || event.key === Qt.Key_Space
        ) {
          if (root.selectedIndex === 0)
            root.finish("keep-open")
          else
            root.finish("close")
        } else {
          return
        }
        event.accepted = true
      }
    }
  }
}
