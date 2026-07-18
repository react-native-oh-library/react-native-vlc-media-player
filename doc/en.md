> > Template version:：v0.3.0

<p align="center">
  <h1 align="center"> <code>react-native-vlc-media-player</code> </h1>
</p>

This project is based on [react-native-vlc-media-player@1.0.88](https://github.com/razorRun/react-native-vlc-media-player).

Please go to the Releases release address of the third-party library to view the supporting version information: [@react-native-ohos/react-native-vlc-media-player Releases](https://github.com/react-native-oh-library/react-native-vlc-media-player/releases). For older versions that are not published to npm, install the tgz package by referring to the [Installation Guide](/en/tgz-usage-en.md).

| Version | Releases info |  Support RN version |
| - | - | - |
| 1.1.0 |[@react-native-ohos/react-native-vlc-media-player Releases](https://github.com/react-native-oh-library/react-native-vlc-media-player/releases) | 0.77 |
| 1.0.89 | [@react-native-ohos/react-native-vlc-media-player Releases](https://github.com/react-native-oh-library/react-native-vlc-media-player/releases) | 0.72 |


## Installation and Usage

Run the following command in your project directory:

#### **npm**

```bash
npm install @react-native-ohos/react-native-vlc-media-player
```

#### **yarn**

```bash
yarn add @react-native-ohos/react-native-vlc-media-player
```

The following code shows the basic use scenario of the repository:

> [!WARNING] The name of the imported repository remains unchanged.

```js
import {useRef, useState } from 'react';
import {
  StyleSheet,
  ScrollView,
  View,
  StatusBar,
} from 'react-native';
import { VLCPlayer } from 'react-native-vlc-media-player';

function App() {
  const vlcPlayerRef = useRef(null);
  return (
    <ScrollView 
      style={{ flex: 1, backgroundColor: '#fff' }}
      contentContainerStyle={{ paddingBottom: 150 }}
    >

      <StatusBar barStyle="dark-content" />
      <View style={styles.videoContainer}>
        <VLCPlayer
          ref={vlcPlayerRef}
          source={{
            initType: 2,
            uri: "rtmp://ns8.indexforce.com/home/mystream",
            initOptions: [
              '--verbose=4'
            ],
          }}
          autoplay={true}
          style={styles.backgroundVideo}
          onPlaying={(event) => {
            console.log(`${event}`)
          }}
        />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  backgroundVideo: {
    width: '100%',
    height: 250,
  },
  videoContainer: {
    padding: 16,
  },
});

export default App;
```

## Link

This step provides guidance for manually configuring native dependencies.

Open the `harmony` directory of the HarmonyOS project in DevEco Studio.

### 1. Adding the overrides Field to oh-package.json5 File in the Root Directory of the Project

```json
{
  ...
  "overrides": {
    "@rnoh/react-native-openharmony" : "./react_native_openharmony"
  }
}
```

### 2. Introducing Native Code

Currently, two methods are available:

Method 1 (recommended): Use the HAR file.

> [!TIP] The HAR file is stored in the `harmony` directory in the installation path of the third-party library.

Open `entry/oh-package.json5` file and add the following dependencies:

```json
"dependencies": {
    "@rnoh/react-native-openharmony": "file:../react_native_openharmony",
    "@react-native-ohos/react-native-vlc-media-player": "file:../../node_modules/@react-native-ohos/react-native-vlc-media-player/harmony/rn_vlc.har"
  }
```

Click the `sync` button in the upper right corner.

Alternatively, run the following instruction on the terminal:

```bash
cd entry
ohpm install
```

Method 2: Directly link to the source code.

> [!TIP] For details, see [Directly Linking Source Code](/en/link-source-code.md).

### 3. Configuring CMakeLists and Introducing RNVlcMediaPlayerPackage

Open `entry/src/main/cpp/CMakeLists.txt` and add the following code:

```diff
project(rnapp)
cmake_minimum_required(VERSION 3.4.1)
set(CMAKE_SKIP_BUILD_RPATH TRUE)
set(RNOH_APP_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(NODE_MODULES "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../node_modules")
+ set(OH_MODULES "${CMAKE_CURRENT_SOURCE_DIR}/../../../oh_modules")
set(RNOH_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../../react-native-harmony/harmony/cpp")
set(LOG_VERBOSITY_LEVEL 1)
set(CMAKE_ASM_FLAGS "-Wno-error=unused-command-line-argument -Qunused-arguments")
set(CMAKE_CXX_FLAGS "-fstack-protector-strong -Wl,-z,relro,-z,now,-z,noexecstack -s -fPIE -pie")
set(WITH_HITRACE_SYSTRACE 1) # for other CMakeLists.txt files to use
add_compile_definitions(WITH_HITRACE_SYSTRACE)

add_subdirectory("${RNOH_CPP_DIR}" ./rn)

# RNOH_BEGIN: manual_package_linking_1
add_subdirectory("../../../../sample_package/src/main/cpp" ./sample-package)
+ add_subdirectory("${OH_MODULES}/@react-native-ohos/react-native-vlc-media-player/src/main/cpp" ./rn_vlc)
# RNOH_END: manual_package_linking_1

file(GLOB GENERATED_CPP_FILES "./generated/*.cpp")

add_library(rnoh_app SHARED
    ${GENERATED_CPP_FILES}
    "./PackageProvider.cpp"
    "${RNOH_CPP_DIR}/RNOHAppNapiBridge.cpp"
)
target_link_libraries(rnoh_app PUBLIC rnoh)

# RNOH_BEGIN: manual_package_linking_2
target_link_libraries(rnoh_app PUBLIC rnoh_sample_package)
+ target_link_libraries(rnoh_app PUBLIC rnoh_vlc)
# RNOH_END: manual_package_linking_2
```

Open `entry/src/main/cpp/PackageProvider.cpp` and add the following code:

```diff
#include "RNOH/PackageProvider.h"
#include "generated/RNOHGeneratedPackage.h"
#include "SamplePackage.h"
+ #include "RNVlcMediaPlayerPackage.h"

using namespace rnoh;

std::vector<std::shared_ptr<Package>> PackageProvider::getPackages(Package::Context ctx) {
    return {
        std::make_shared<RNOHGeneratedPackage>(ctx),
        std::make_shared<SamplePackage>(ctx),
+       std::make_shared<RNVlcMediaPlayerPackage>(ctx),
    };
}
```

### Introduce the RNVLC component on the ArkTs side

Open the `entry/src/main/ets/pages/index.ets` file and add the following code:

```diff
  ...
+ import {RNVLC, RNC_VLC_TYPE} from "@react-native-ohos/react-native-vlc-media-player"
@Builder
export function buildCustomRNComponent(ctx: ComponentBuilderContext) {
  ...
+ if (ctx.componentName === RNC_VLC_TYPE) {
+   RNVLC({
+     ctx: ctx.rnComponentContext,
+     tag: ctx.tag
+   })
+ }
...
}
...
```

### 5. Running

Click the `sync` button in the upper right corner.

Alternatively, run the following instruction on the terminal:

```bash
cd entry
ohpm install
```

Then build and run the code.

## Constraints

### Compatibility

Verified in the following versions:

1. RNOH: 0.72.90; SDK: HarmonyOS 6.0.0 Release SDK; IDE: DevEco Studio 6.0.0 Release; ROM: 6.0.0.115;
2. RNOH: 0.77.33; SDK: HarmonyOS 6.0.0 Release SDK; IDE: DevEco Studio 6.0.0 Release; ROM: 5.0.0.208;

## Properties

> [!TIP] The **Platform** column indicates the platform where the properties are supported in the original third-party library.

> [!TIP] If the value of **HarmonyOS Support** is **yes**, it means that the HarmonyOS platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

| Name | Description | Type | Required |  Platform   | HarmonyOS Support |
| - | - | - | - | - | - |
| PlayerAspectRatio | Video aspect ratio type, Expected options: "16:9", "1:1", "4:3", "3:2", "21:9", "9:16" | string | no | all | yes |
| PlayerResizeMode |  Video resize mode, Expected options: "fill", "contain", "cover", "none", "scale-down" | string | no | no | no |
| VLCPlayerSource | VLC Player source configuration options | object: {uri: string; initType?: 1 \| 2; initOptions?: string[];} | no | all | yes |
| Track | Represents a track type in playback | object: { id: number, name: string } | no | all | yes |
| VideoInfo | Represents a full playback information | object: { duration: number; target: number; videoSize: Record<"width" \| "height", number>; audioTracks: Track[]; textTracks: Track[]; } | no | all | yes |
| source | Object that contains the uri of a video or song to play | VLCPlayerSource | yes | all | yes |
| subtitleUri | local subtitle file path，if you want to hide subtitle, you can set this to an empty subtitle file， current we don't support a hide subtitle prop. | string | no | all | yes |
| paused | Set to `true` or `false` to pause or play the media | boolean | no | all | yes |
| repeat |  Set to `true` or `false` to loop the media | boolean | no | no | no |
| rate | Set the playback rate of the player | number | no | all | yes |
| seek | Set position to seek between 0 and 1 (0 being the start, 1 being the end, use position from the progress object) | number | no | all | yes |
| volume | Set the volume of the player | number | no| all | yes |
| muted | Set to `true` or `false` to mute the player | boolean| no | all | yes |
| audioTrack | Set audioTrack id (number) (see onLoad callback VideoInfo.audioTracks) | number | no | all | yes |
| textTrack | Set textTrack(subtitle) id (number) (see onLoad callback - VideoInfo.textTracks) | number | no | all | yes |
| playInBackground | Set to `true` or `false` to allow playing in the background | boolean| no | no | no |
| videoAspectRatio | Video aspect ratio | PlayerAspectRatio | no | all | yes |
| autoAspectRatio |  Set to `true` or `false` to enable auto aspect ratio | boolean | no | all | yes |
| resizeMode | Set the behavior for the video size (fill, contain, cover, none, scale-down) | PlayerResizeMode | no | no | no |
| style | React native view stylesheet styles | StyleProp\<ViewStyle\> | no | no | no |
| autoplay | Enables autoplay | boolean | no | all | yes |


## Function

> [!TIP] The **Platform** column indicates the platform where the properties are supported in the original third-party library.

> [!TIP] If the value of **HarmonyOS Support** is **yes**, it means that the HarmonyOS platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

| Name | Description | Type | Required | Platform | HarmonyOS Support  |
| ---- | ----------- | ---- | -------- | -------- | ------------------ |
| startRecording(path: string) | Start a new recording session at the given path | function | no | all | no |
| stopRecording() | Stop current recording session | function | no | all | no |
| stopPlayer() | Stop playing  | function | no | all | yes |
| snapshot(path: string) | Take a screenshot of the current video frame | function | no | all | yes |
| seek(pos: number) | Seek to the given position | function | no | all | yes |
| resume() | Resume playback | function | no | all | yes |
| autoAspectRatio(useAuto: boolean) | Change auto aspect ratio setting | function | no | all | yes |
| changeVideoAspectRatio(ratio: string) | Update video aspect ratio e.g. `"16:9"` | function | no | all | yes |
| onPlaying?: (event: OnPlayingEventProps) => void | Called when media starts playing returns | function | no | all | yes |
| onProgress?: (event: OnProgressEventProps) => void | Callback containing position as a fraction, and duration, currentTime and remainingTime in seconds | function | no | all | yes |
| onPaused?: (event: SimpleCallbackEventProps) => void | Called when media is paused | function | no | all | yes |
| onStopped?: (event: SimpleCallbackEventProps) => void | Called when media is stoped | function | no | all | yes |
| onBuffering?: (event: SimpleCallbackEventProps) => void | Called when media is buffering | function | no | all | yes |
| onEnd?: (event: SimpleCallbackEventProps) => void | Called when media playing ends | function | no | all | yes |
| onError?: (event: SimpleCallbackEventProps) => void | Called when an error occurs whilst attempting to play media | function | no | all | yes |
| onLoad?: (event: VideoInfo) => void | Called when video info is loaded, Callback containing `VideoInfo` | function | no | all | yes |
| onRecordingCreated?: (recordingPath: string) => void | Called when a new recording is created | function | no | all | no |
| onSnapshot?: (event: { success: boolean; path?: string; error?: string; }) => void | Called when a new snapshot is created | function | no | all | yes |


## Known Issues

- [ ] The functions onRecordingCreated, startRecording, and stopRecording are custom video recording features for Android and iOS. They have not been merged into the mainline version of the libvlc library and therefore will not be implemented.[issues](https://github.com/react-native-oh-library/react-native-vlc-media-player/issues/10)
- [ ] The repeat property provides loop playback functionality. It is not implemented on either Android or iOS and will not be implemented on HarmonyOS.[issues](https://github.com/react-native-oh-library/react-native-vlc-media-player/issues/10)
- [ ] The playInBackground property enables background playback. This feature is not implemented on Android or iOS. On HarmonyOS, background playback requires users to explicitly request background permissions; therefore, it will not be implemented.[issues](https://github.com/react-native-oh-library/react-native-vlc-media-player/issues/10)
- [ ] The resizeMode property controls the video scaling/fill mode. It is not implemented on Android or iOS and will not be implemented on HarmonyOS.[issues](https://github.com/react-native-oh-library/react-native-vlc-media-player/issues/10)
- [ ] The style field of VLCPlayerProps is not implemented on either Android or ios. It has been aligned with SE and is not implemented on HarmonyOS either.[issues](https://github.com/react-native-oh-library/react-native-vlc-media-player/issues/10)

## Others

## License

This project is licensed under [The MIT License (MIT)](https://github.com/razorRun/react-native-vlc-media-player/blob/master/LICENSE).