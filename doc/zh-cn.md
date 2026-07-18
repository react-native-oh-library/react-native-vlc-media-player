> 模板版本：v0.3.0

<p align="center">
  <h1 align="center"> <code>react-native-vlc-media-player</code> </h1>
</p>

本项目基于 [react-native-vlc-media-player@1.0.88](https://github.com/razorRun/react-native-vlc-media-player) 开发。

请到三方库的 Releases 发布地址查看配套的版本信息：[@react-native-ohos/react-native-vlc-media-player Releases](https://github.com/react-native-oh-library/react-native-vlc-media-player/releases)。对于未发布到npm的旧版本，请参考[安装指南](/zh-cn/tgz-usage.md)安装tgz包。

| 三方库版本 | 发布信息 | 支持RN版本 |
| - | - | - |
| 1.1.0 | [@react-native-ohos/react-native-vlc-media-player Releases](https://github.com/react-native-oh-library/react-native-vlc-media-player/releases) | 0.77 |
| 1.0.89 | [@react-native-ohos/react-native-vlc-media-player Releases](https://github.com/react-native-oh-library/react-native-vlc-media-player/releases) | 0.72 |

## 1. 安装与使用

进入到工程目录并输入以下命令：

#### **npm**

```bash
npm install @react-native-ohos/react-native-vlc-media-player
```

#### **yarn**

```bash
yarn add @react-native-ohos/react-native-vlc-media-player
```

下面的代码展示了这个库的基本使用场景：

> [!WARNING] 使用时 import 的库名不变。

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

此步骤为手动配置原生依赖项的指导。

首先需要使用 DevEco Studio 打开项目里的 HarmonyOS 工程 `harmony`

### 1.在工程根目录的 `oh-package.json5` 添加 overrides 字段

```json
{
  ...
  "overrides": {
    "@rnoh/react-native-openharmony" : "./react_native_openharmony"
  }
}
```

### 2.引入原生端代码

目前有两种方法：

1. 通过 har 包引入（在 IDE 完善相关功能后该方法会被遗弃，目前首选此方法）；
2. 直接链接源码。

方法一：通过 har 包引入（推荐）

> [!TIP] har 包位于三方库安装路径的 `harmony` 文件夹下。

打开 `entry/oh-package.json5`，添加以下依赖

```json
"dependencies": {
    "@rnoh/react-native-openharmony": "file:../react_native_openharmony",
    "@react-native-ohos/react-native-vlc-media-player": "file:../../node_modules/@react-native-ohos/react-native-vlc-media-player/harmony/rn_vlc.har"
  }
```

点击右上角的 `sync` 按钮

或者在终端执行：

```bash
cd entry
ohpm install
```

方法二：直接链接源码

> [!TIP] 如需使用直接链接源码，请参考[直接链接源码说明](/zh-cn/link-source-code.md)

### 3.配置 CMakeLists 和引入 RNVlcMediaPlayerPackage

打开 `entry/src/main/cpp/CMakeLists.txt`，添加：

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

打开 `entry/src/main/cpp/PackageProvider.cpp`，添加：

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

### 4.在 ArkTs 侧引入 RNVLC 组件

找到 `function buildCustomRNComponent()`，一般位于 `entry/src/main/ets/pages/index.ets` 或 `entry/src/main/ets/rn/LoadBundle.ets`，添加：

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

### 5.运行

点击右上角的 `sync` 按钮

或者在终端执行：

```bash
cd entry
ohpm install
```

然后编译、运行即可。

## 约束与限制

### 兼容性

本文档内容基于以下环境验证通过：

1. RNOH: 0.72.90; SDK: HarmonyOS 6.0.0 Release SDK; IDE: DevEco Studio 6.0.0 Release; ROM: 6.0.0.115;
2. RNOH: 0.77.33; SDK: HarmonyOS 6.0.0 Release SDK; IDE: DevEco Studio 6.0.0 Release; ROM: 5.0.0.208;


## 属性

> [!TIP] "Platform"列表示该属性在原三方库上支持的平台。

> [!TIP] "HarmonyOS Support"列为 yes 表示 HarmonyOS 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

| Name | Description | Type | Required | Platform | HarmonyOS Support  |
| - | - | - | - | - | - |
| PlayerAspectRatio | 视频纵横比, 可选值: "16:9", "1:1", "4:3", "3:2", "21:9", "9:16" | string | no | all | yes |
| PlayerResizeMode |  视频尺寸变化模式, 可选值: "fill", "contain", "cover", "none", "scale-down" | string | no | no | no |
| VLCPlayerSource | VLC播放器源配置选项 | object: {uri: string; initType?: 1 \| 2; initOptions?: string[];} | no | all | yes |
| Track | 表示播放中的音轨类型 | object: { id: number, name: string } | no | all | yes |
| VideoInfo | 表示完整的播放信息 | object: { duration: number; target: number; videoSize: Record<"width" \| "height", number>; audioTracks: Track[]; textTracks: Track[]; } | no | all | yes |
| source | 视频的 uri以及相关参数 | VLCPlayerSource | yes | all | yes |
| subtitleUri | 本地字幕文件路径 | string | no | all | yes |
| paused | 暂停或播放媒体 | boolean | no | all | yes |
| repeat | 循环播放媒体 | boolean | no | no | no |
| rate | 设置播放器的播放速率 | number | no | all | yes |
| seek | 播放的位置 | number | no | all | yes |
| volume | 设置播放器的音量 | number | no| all | yes |
| muted | 静音播放器 | boolean| no | all | yes |
| audioTrack | 设置音频轨道id | number | no | all | yes |
| textTrack | 设置字幕轨道id | number | no | all | yes |
| playInBackground | 设置后台播放 | boolean| no | no | no |
| videoAspectRatio | 设置视频宽高比 | PlayerAspectRatio | no | all | yes |
| autoAspectRatio | 是否启用自动纵横比 | boolean | no | all | yes |
| resizeMode | 设置视频尺寸的行为 | PlayerResizeMode | no | no | no |
| style | React 原生样式表样式 | StyleProp\<ViewStyle\> | no | no | no |
| autoplay | 是否启用自动播放 | boolean | no | all | yes |


## 方法

> [!TIP] "Platform" 列表示该属性在原三方库上支持的平台。

> [!TIP] "HarmonyOS Support"列为 yes 表示 HarmonyOS 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

| Name | Description | Type | Required | Platform | HarmonyOS Support  |
| ---- | ----------- | ---- | -------- | -------- | ------------------ |
| startRecording(path: string) | 开始将当前视频录制到给定的目录中 | function | no | all | no |
| stopRecording() | 停止当前视频录制 | function | no | all | no |
| stopPlayer() | 停止播放 | function | no | all | yes |
| snapshot(path: string) | 截图 | function | no | all | yes |
| seek(pos: number) | 跳转播放位置 | function | no | all | yes |
| resume() | 重新播放 | function | no | all | yes |
| autoAspectRatio(useAuto: boolean) | 更改自动宽高比设置 | function | no | all | yes |
| changeVideoAspectRatio(ratio: string) | 更新视频宽高比 | function | no | all | yes |
| onPlaying?: (event: OnPlayingEventProps) => void | 当媒体开始播放时调用 | function | no | all | yes |
| onProgress?: (event: OnProgressEventProps) => void | 执行中回调 | function | no | all | yes |
| onPaused?: (event: SimpleCallbackEventProps) => void | 媒体暂停时调用 | function | no | all | yes |
| onStopped?: (event: SimpleCallbackEventProps) => void | 媒体停止时调用 | function | no | all | yes |
| onBuffering?: (event: SimpleCallbackEventProps) => void | 当媒体缓冲时调用 | function | no | all | yes |
| onEnd?: (event: SimpleCallbackEventProps) => void | 媒体播放结束时调用 | function | no | all | yes |
| onError?: (event: SimpleCallbackEventProps) => void | 尝试播放媒体时发生错误时调用 | function | no | all | yes |
| onLoad?: (event: VideoInfo) => void | 视频信息加载时调用 | function | no | all | yes |
| onRecordingCreated?: (recordingPath: string) => void | 录制启动或结束时回调 | function | no | all | no |
| onSnapshot?: (event: { success: boolean; path?: string; error?: string; }) => void | 调用snapshot()后回调 | function | no | all | yes |


## Known Issues

- [ ] 函数onRecordingCreated、startRecording和stopRecording为录制视频功能，是安卓和ios的定制化功能，未合入libvlc库的主干版本，不做实现。[issues](https://github.com/react-native-oh-library/react-native-vlc-media-player/issues/10)
- [ ] 属性repeat为循环播放功能，安卓和ios均未实现，鸿蒙不做实现。[issues](https://github.com/react-native-oh-library/react-native-vlc-media-player/issues/10)
- [ ] 属性playInBackground为后台播放功能，安卓和ios均未实现，鸿蒙需要用户自己申请后台权限，不做实现。[issues](https://github.com/react-native-oh-library/react-native-vlc-media-player/issues/10)
- [ ] 属性resizeMode为视频填充模式，安卓和ios均未实现，鸿蒙不做实现。[issues](https://github.com/react-native-oh-library/react-native-vlc-media-player/issues/10)
- [ ] VLCPlayerProps的style字段安卓和ios都没有是实现，已与SE对齐HarmonyOS也不实现。[issues](https://github.com/react-native-oh-library/react-native-vlc-media-player/issues/10)

## 其他

## 开源协议

本项目基于 [The MIT License (MIT)](https://github.com/razorRun/react-native-vlc-media-player/blob/master/LICENSE) ，请自由地享受和参与开源。
