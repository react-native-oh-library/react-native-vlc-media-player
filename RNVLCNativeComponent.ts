// @flow strict-local

import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import codegenNativeCommands from "react-native/Libraries/Utilities/codegenNativeCommands";
import type { ViewProps, HostComponent } from 'react-native';
import type {
  WithDefault,
  DirectEventHandler,
  Int32,
  Double,
  Float,
} from 'react-native/Libraries/Types/CodegenTypes';

export type VoidEventData = Readonly<{
  target?: Int32;
}>;

export type StringEventData = Readonly<{
  path?: string;
  success?: boolean;
  error?: string;
}>;

export type PlayingEventData = Readonly<{
  target?: Int32;
  duration?: Double;
  seekable?: boolean;
}>;

export type ProgressEventData = Readonly<{
  target?: Int32;
  duration?: Double;
  currentTime?: Double;
  position?: Double;
  remainingTime?: Double;
}>;

export type LoadEventData = Readonly<{
  target?: Int32;
  duration?: Double;
  videoSize?: Readonly<{
    width?: Int32;
    height?: Int32;
  }>;

  audioTracks?: {id: Int32, name: string }[];
  textTracksJson?: {id: Int32, name: string }[];
}>;


export type RecordingEventData = Readonly<{
  path?: string;
}>;

export interface VLCNativeProps extends ViewProps {
  source?: Readonly<{
    uri?: string;
    initType?: WithDefault<Int32, 1>;
    initOptions?: ReadonlyArray<string>;
  }>;

  subtitleUri?: string;
  paused?: WithDefault<boolean, false>;
  repeat?: WithDefault<boolean, false>;
  rate?: WithDefault<Float, 1.0>;
  seek?: Double;
  volume?: Int32;
  muted?: WithDefault<boolean, false>;
  autoplay?: WithDefault<boolean, true>;
  audioTrack?: Int32;
  textTrack?: Int32;
  playInBackground?: WithDefault<boolean, false>;
  videoAspectRatio?: string;
  autoAspectRatio?: WithDefault<boolean, false>;
  resizeMode?: string;
  progressUpdateInterval?: Int32;
  acceptInvalidCertificates?: WithDefault<boolean, false>;

  onPlaying?: DirectEventHandler<PlayingEventData>;
  onProgress?: DirectEventHandler<ProgressEventData>;
  onPaused?: DirectEventHandler<VoidEventData>;
  onStopped?: DirectEventHandler<VoidEventData>;
  onBuffering?: DirectEventHandler<VoidEventData>;
  onEnd?: DirectEventHandler<VoidEventData>;
  onError?: DirectEventHandler<VoidEventData>;
  onLoad?: DirectEventHandler<LoadEventData>;
  onRecordingCreated?: DirectEventHandler<RecordingEventData>;
  onSnapshot?: DirectEventHandler<StringEventData>;
  onOpen?: DirectEventHandler<VoidEventData>;
}

type NativeType = HostComponent<VLCNativeProps>;

interface NativeCommands {
  resume: (viewRef: React.ElementRef<NativeType>) => void;
  snapshot: (viewRef: React.ElementRef<NativeType>, path: string) => void;
  seek: (viewRef: React.ElementRef<NativeType>, pos: Double) => void;
  startRecording: (viewRef: React.ElementRef<NativeType>, path: string) => void;
  stopRecording: (viewRef: React.ElementRef<NativeType>) => void;
  autoAspectRatio: (viewRef: React.ElementRef<NativeType>, useAuto: boolean) => void;
  changeVideoAspectRatio: (viewRef: React.ElementRef<NativeType>, ratio: string) => void;
  stopPlayer: (viewRef: React.ElementRef<NativeType>) => void;
}

export const Commands: NativeCommands = codegenNativeCommands<NativeCommands>({
  supportedCommands: [
    "resume",
    "snapshot",
    "seek",
    "startRecording",
    "stopRecording",
    "autoAspectRatio",
    "changeVideoAspectRatio",
    "stopPlayer"
  ],
});

export default codegenNativeComponent<VLCNativeProps>(
  "RNVLC"
) as HostComponent<VLCNativeProps>;