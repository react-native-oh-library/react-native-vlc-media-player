/**
 * MIT License
 *
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * Ï
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANT KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
import { RNViewBase, RNComponentContext } from '@rnoh/react-native-openharmony'
import { RNC } from "./generated/index"
import { componentSnapshot } from '@kit.ArkUI';
import { LibVLC, Media, MediaListener, MediaPlayer, MediaPlayerListener, Description, libvlc_event_e,
  DialogListener,
  ErrorDialog,
  LoginDialog,
  ProgressDialog,
  CanceledDialog,
  UpdateProgressDialog,
  QuestionDialog,Dialog,libvlc_dialog_question_type} from '@ohos/vlc'
import { JSON, util } from '@kit.ArkTS';
import { image } from '@kit.ImageKit';
import fs from '@ohos.file.fs';

export const RNC_VLC_TYPE: string = "RNVLC"

@Component
export struct RNVLC {
  @State descriptor: RNC.RNVLC.Descriptor = {} as RNC.RNVLC.Descriptor
  ctx!: RNComponentContext
  tag: number = 0
  localURL: string = "";
  preVolume: number = 100;
  isPaused: boolean = true;
  autoAspectRatio: boolean = false;
  screenWidth: number = 0;
  screenHeight: number = 0;
  viewWidth: number | 'auto' | `${number}%` = 0;
  viewHeight: number | 'auto' | `${number}%` = 0;
  prevVideoSize: Size = { width: 0, height: 0 };
  prevAudioTracks: Array<Description> = []
  prevTextTracks: Array<Description> = []
  vlc: LibVLC | null = null;
  mediaPlayer: MediaPlayer | null = null;
  media: Media | null = null;
  xComponentId = '__OHOS_VLC__' + util.generateRandomUUID();
  callbackList: Array<() => void> = []
  mediaListener: MediaListener = {
    onMediaEventCallback: (type: libvlc_event_e) => {

    }
  }
  dialogListener: DialogListener = {
    onQuestion: (data: QuestionDialog) => {
      if (data.text !== "" && (data.text.includes("certificate") || data.text.includes("SSL") || data.text.includes("TLS") || data.text.includes("cert"))) {
        if (this.descriptor.rawProps.acceptInvalidCertificates) {
          data.postAction(1);
        } else {
          data.postAction(2);
        }
      } else {
        data.dismiss();
      }
    },
    onError: (data: ErrorDialog): void => {
    },
    onLogin: (data: LoginDialog): void => {
    },
    onProgress: (data: ProgressDialog): void => {
    },
    onCanceled: (data: CanceledDialog): void => {
    },
    onUpdateProgress: (data: UpdateProgressDialog): void => {
    }
  }
  mediaPlayerListener: MediaPlayerListener = {
    onEvent: (type: libvlc_event_e, para1: number, para2: number, para3: number) => {
      switch (type) {
        case libvlc_event_e.libvlc_MediaPlayerOpening: {
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, "open", {});
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, "load", {});
          break
        }

        case libvlc_event_e.libvlc_MediaPlayerPaused: {
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, "paused", {});
          break;
        }

        case libvlc_event_e.libvlc_MediaPlayerStopped: {
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, "stopped", {});
          break;
        }

        case libvlc_event_e.libvlc_MediaPlayerBuffering: {
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, "buffering", {});
          break;
        }

        case libvlc_event_e.libvlc_MediaPlayerPlaying: {
          this.ctx.rnInstance.emitComponentEvent(
            this.descriptor.tag,
            "playing",
            {
              seekable: this.mediaPlayer?.isSeekable(),
              duration: this.mediaPlayer?.getLength(),
            }
          );
          break;
        }

        case libvlc_event_e.libvlc_MediaPlayerEndReached: {
          let currentTime = this.mediaPlayer?.getTime() ?? 0;
          let length = this.mediaPlayer?.getLength() ?? 0;

          this.ctx.rnInstance.emitComponentEvent(
            this.descriptor.tag,
            "end",
            {
              currentTime: currentTime,
              remainingTime: length - currentTime,
              duration: length,
              position: this.mediaPlayer?.getPosition(),
            }
          );
          break;
        }

        case libvlc_event_e.libvlc_MediaPlayerEncounteredError: {
          this.releasePlayer();
          this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, "error", {});
          break;
        }

        case libvlc_event_e.libvlc_MediaPlayerTimeChanged: {
          this.updateVideoProgress();
          break;
        }
      }
    }
  }

  updateVideoProgress() {
    if (this.mediaPlayer === null || this.isPaused) {
      return;
    }

    const videoSizeTemp = this.mediaPlayer.getSize();
    const audioTracksTemp = this.mediaPlayer.getAudioDescription();
    const textTracksTemp = this.mediaPlayer.getSpuDescription();
    let length = this.mediaPlayer?.getLength() ?? 0
    let time = this.mediaPlayer?.getTime() ?? 0

    const videoSizeChanged =
      !this.prevVideoSize ||
        this.prevVideoSize.width !== videoSizeTemp.width ||
        this.prevVideoSize.height !== videoSizeTemp.height;

    const audioChanged =
      JSON.stringify(this.prevAudioTracks) !== JSON.stringify(audioTracksTemp);

    const textChanged =
      JSON.stringify(this.prevTextTracks) !== JSON.stringify(textTracksTemp);


    if (videoSizeChanged || audioChanged || textChanged) {
      this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, "load", {
        duration: length,
        videoSize: {
          width: videoSizeTemp.width,
          height: videoSizeTemp.height,
        },
        currentTime: time,
        audioTracks: audioTracksTemp,
        textTracks: textTracksTemp,
      });

      this.prevVideoSize = videoSizeTemp;
      this.prevAudioTracks = audioTracksTemp;
      this.prevTextTracks = textTracksTemp;
    }

    this.ctx.rnInstance.emitComponentEvent(
      this.descriptor.tag,
      "progress",
      {
        position: this.mediaPlayer?.getPosition(),
        currentTime: time,
        remainingTime: length - time,
        duration: length,
      }
    );
  }

  async snapshot(path: string) {
    try {
      const dir = path.substring(0, path.lastIndexOf('/'));
      const stat = fs.statSync(dir);
      if (!stat.isDirectory()) {
        this.ctx.rnInstance.emitComponentEvent(
          this.descriptor.tag,
          "snapshot",
          {
            success: false,
            error: "It's not a directory",
          }
        );
        return
      }
      if (!fs.accessSync(dir, fs.AccessModeType.READ_WRITE)) {
        this.ctx.rnInstance.emitComponentEvent(
          this.descriptor.tag,
          "snapshot",
          {
            success: false,
            error: "No permission",
          }
        );
        return
      }
    } catch (err) {
      this.ctx.rnInstance.emitComponentEvent(
        this.descriptor.tag,
        "snapshot",
        {
          success: false,
          error: err,
        }
      );
      return;
    }

    try {
      let screenshot: image.PixelMap = componentSnapshot.getSync(this.xComponentId);
      const imagePackerApi = image.createImagePacker();
      const packOpts: image.PackingOption = {
        format: 'image/png',
        quality: 100
      };

      const data = await imagePackerApi.packToData(screenshot, packOpts);

      if (fs.accessSync(path)) {
        fs.unlinkSync(path);
      }
      const file = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      fs.writeSync(file.fd, data);
      fs.closeSync(file);

      this.ctx.rnInstance.emitComponentEvent(
        this.descriptor.tag,
        "snapshot",
        {
          success: true,
          path: path,
          error: null,
        }
      );
    } catch (err) {
      this.ctx.rnInstance.emitComponentEvent(
        this.descriptor.tag,
        "snapshot",
        {
          success: false,
          error: err,
        }
      );
    }
  }

  watchedProps: Map<string, Function> = new Map();

  watchProp(propName: string, handler: Function) {
    this.watchedProps.set(propName, handler);
  }

  processDescriptorChanges(newDescriptor: RNC.RNVLC.Descriptor): void {
    this.watchedProps.forEach((handler, propName) => {
      const oldProps = this.descriptor.rawProps as RNC.RNVLC.DirectRawProps;
      const newProps = newDescriptor.rawProps as RNC.RNVLC.DirectRawProps;

      const newVal = newProps[propName as keyof RNC.RNVLC.DirectRawProps];
      const oldVal = oldProps[propName as keyof RNC.RNVLC.DirectRawProps];

      if (newVal !== undefined && newVal !== oldVal) {
        console.info(`rnvlc update prop ${propName}: ${oldVal} -> ${newVal}`);
        handler(newVal);
      }
    });

    this.descriptor = newDescriptor;
  }

  aboutToAppear() {
    this.watchProp('subtitleUri', (val: string) => {
      this.mediaPlayer?.addSlave(0, val, true);
    });
    this.watchProp('paused', (val: boolean) => {
      this.pausedModifier(val)
    });
    this.watchProp('rate', (val: number) => this.mediaPlayer?.setRate(val));
    this.watchProp('seek', (val: number) => this.mediaPlayer?.setPosition(val));
    this.watchProp('volume', (val: number) => this.mediaPlayer?.setVolume(val));
    this.watchProp('muted', (val: boolean) => {
      this.mutedModifier(val)
    });
    this.watchProp('audioTrack', (val: number) => {
      this.mediaPlayer?.setAudioTrack(val)
    });
    this.watchProp('textTrack', (val: number) => {
      this.mediaPlayer?.setTextTrack(val)
    });
    this.watchProp('videoAspectRatio', (val: string) => {
      if (!this.autoAspectRatio) {
        this.mediaPlayer?.setAspectRatio(val)
      }
    });
    this.watchProp('autoAspectRatio', (val: boolean) => {
      this.autoAspectRatio = val;
    });

    this.descriptor = this.ctx.descriptorRegistry.getDescriptor<RNC.RNVLC.Descriptor>(this.tag)
    this.callbackList.push(this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
      (newDescriptor) => {
        this.processDescriptorChanges(newDescriptor as RNC.RNVLC.Descriptor)
        const prop = newDescriptor as RNC.RNVLC.Descriptor;
        if (prop.rawProps.source?.uri && this.localURL != prop.rawProps.source.uri) {
          this.localURL = prop.rawProps.source.uri;
          this.createPlayer(true, false);
        }
      }
    ))

    this.screenWidth = this.ctx.getDisplayMetrics().screenPhysicalPixels.width;
    this.screenHeight = this.ctx.getDisplayMetrics().screenPhysicalPixels.height;

    this.viewWidth = this.descriptor.layoutMetrics.frame.size.width;
    this.viewHeight = this.descriptor.layoutMetrics.frame.size.height;

    this.callbackList.push(this.ctx.componentCommandReceiver.registerCommandCallback(
      this.tag,
      (command, args: (string | number)[]) => {
        console.info(`rnvlc command : ${command} ${JSON.stringify(args)}`);
        if (command === "snapshot") {
          this.snapshot(String(args[0]));
        } else if (command === "seek") {
          this.mediaPlayer?.setPosition(Number(args[0]));
        } else if (command === "resume") {
          this.createPlayer(true, true);
        } else if (command === "stopPlayer") {
          this.mediaPlayer?.stop();
        }
      }))
  }

  aboutToDisappear(): void {
    this.mediaPlayer?.stop();
    this.callbackList.forEach(
      callback => {
        callback?.()
      }
    )
  }

  pausedModifier(paused: boolean) {
    if (!this.mediaPlayer) {
      return
    }
    this.isPaused = paused;
    if (paused) {
      this.mediaPlayer.pause()
    } else {
      this.mediaPlayer.play()
    }
  }

  mutedModifier(muted: boolean) {
    if (this.mediaPlayer !== null) {
      if (muted) {
        this.preVolume = this.mediaPlayer.getVolume()
        this.mediaPlayer.setVolume(0)
      } else {
        this.mediaPlayer.setVolume(this.preVolume)
      }
    }
  }

  releasePlayer() {
    if (this.vlc === null) {
      return
    }
    this.mediaPlayer?.stop()
  }

  createPlayer(autoplayResume: boolean, isResume: boolean) {
    if (!this.descriptor.rawProps.source?.uri) {
      console.log(`rnvlc uri is undefined`);
      return
    }

    this.releasePlayer();
    let list: string[] = [];
    if (this.descriptor.rawProps.source?.initType === 2) {
      if (this.descriptor.rawProps.source?.initOptions) {
        list = this.descriptor.rawProps.source?.initOptions;
      }
    }

    this.vlc = new LibVLC(list, '/data/storage/el2/base/haps/entry/cache/' + this.xComponentId);
    this.mediaPlayer = new MediaPlayer(this.vlc);
    this.mutedModifier(this.descriptor.rawProps?.muted ?? false)
    this.mediaPlayer.setVideoOut(this.xComponentId);
    this.mediaPlayer.setEventListener(this.mediaPlayerListener);
    Dialog.setCallbacks(this.vlc, this.dialogListener);

    console.info(`rnvlc video path: ${this.descriptor.rawProps.source?.uri}`);
    this.media = new Media(this.vlc, this.descriptor.rawProps.source?.uri ?? "");
    this.media.setEventListener(this.mediaListener);
    this.media.parse();
    this.mediaPlayer.setMedia(this.media);

    if (this.descriptor.rawProps.subtitleUri) {
      console.info(`rnvlc subtitleUri path: ${this.descriptor.rawProps.subtitleUri}`);
      this.mediaPlayer.addSlave(0, this.descriptor.rawProps.subtitleUri, true);
    }

    this.watchedProps.forEach((handler, propName) => {
      const val = this.descriptor.rawProps[propName as keyof RNC.RNVLC.DirectRawProps];
      if (val) {
        console.log(`rnvlc init prop: ${propName}: ${val}`)
        handler(val);
      }
    });

    console.log(`rnvlc play props: ${isResume}, ${autoplayResume}, ${this.descriptor.rawProps.autoplay}`);
    if (isResume) {
      if (autoplayResume) {
        this.mediaPlayer.play();
      }
    } else {
      if (this.descriptor.rawProps.autoplay) {
        this.isPaused = false;
        this.mediaPlayer.play();
      }
    }
  }

  build() {
    Column() {
      RNViewBase({ ctx: this.ctx, tag: this.tag }) {
        XComponent({ id: this.xComponentId, type: XComponentType.SURFACE, libraryname: 'vlc_napi' })
          .id(this.xComponentId)
          .width(this.viewWidth)
          .height(this.viewHeight)
          .onLoad(() => {
            this.createPlayer(true, false);
          })
      }
    }
  }
}