pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Widgets

RowLayout {
    id: root
    
    spacing: 10
    
    required property MprisPlayer player
    // Fall back to a YouTube cover URL when the player exposes no mpris:artUrl
    // (Firefox MPRIS bridge and plasma-browser-integration both omit it on YT Music).
    property var artUrl: (player?.trackArtUrl && player.trackArtUrl.length > 0)
        ? player.trackArtUrl
        : StringUtils.getYoutubeArtUrl(player?.metadata?.["xesam:url"] ?? "")
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property bool downloaded: false
    
    property string displayedArtFilePath: root.downloaded ? Qt.resolvedUrl(artFilePath) : ""
    
    onArtFilePathChanged: {
        if (root.artUrl.length == 0) {
            return;
        }

        // Binding does not work in Process
        coverArtDownloader.targetFile = root.artUrl 
        coverArtDownloader.artFilePath = root.artFilePath
        // Download
        root.downloaded = false
        coverArtDownloader.running = true
    }
    
    Process { // Cover art downloader
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        // For oEmbed URLs (returned by StringUtils.getYoutubeArtUrl for
        // playlist / channel links), resolve the JSON `thumbnail_url` field
        // first, then download the resulting image with the same curl call.
        command: [ "bash", "-c", `
            out='${artFilePath}'
            url='${targetFile}'
            if [ -z "$url" ] || [ -f "$out" ]; then exit 0; fi
            case "$url" in *"/oembed?"*)
                url=$(curl -4 -fsSL "$url" | sed -n 's/.*"thumbnail_url":"\\([^"]*\\)".*/\\1/p') ;;
            esac
            if [ -n "$url" ]; then curl -4 -fsSL "$url" -o "$out"; fi
        `]
        onExited: (exitCode, exitStatus) => {
            root.downloaded = true
        }
    }
    
    ClippingRectangle {
        id: songArt
        radius: 100
        color: Appearance.colors.colLayer1
        Layout.fillHeight: true
        implicitWidth: height
        
        MaterialSymbol {
            fill: 1
            anchors.centerIn: parent
            text: "music_note"
            iconSize: Appearance.font.pixelSize.hugeass
            color: Appearance.colors.colOnSurfaceVariant
        }
        
        Loader {
            active: root.displayedArtFilePath.length > 0
            visible: active
            anchors.fill: parent
            
            sourceComponent: Image {
                source: root.displayedArtFilePath
                cache: false
                antialiasing: true
                asynchronous: true
                
                width: songArt.width
                height: songArt.height
                sourceSize {
                    width: songArt.width
                    height: songArt.height
                }
            }
        }
    }
    
    ColumnLayout {
        spacing: 2
        
        StyledText {
            id: trackTitle
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            lineHeightMode: Text.FixedHeight
            lineHeight: font.pixelSize
            color: Appearance.colors.colOnSurfaceVariant
            elide: Text.ElideRight
            text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || Translation.tr("No active player")
            animateChange: true
            animationDistanceX: 6
            animationDistanceY: 0
        }
        
        StyledText {
            visible: text.length !== 0
            id: trackArtist
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smallest
            lineHeightMode: Text.FixedHeight
            lineHeight: font.pixelSize
            color: Appearance.colors.colOnSurfaceVariant
            elide: Text.ElideRight
            text: root.player?.trackArtist
            animateChange: true
            animationDistanceX: 6
            animationDistanceY: 0
        }
    }
}