import React from "react";
import ReactNative from "react-native";

const { Component } = React;

import PropTypes from "prop-types";
import RNVLC, {Commands as VLCCommands} from './RNVLCNativeComponent';

const { StyleSheet, requireNativeComponent, NativeModules, View, UIManager } = ReactNative;

export default class VLCPlayer extends Component {
  mRNVLCRef: React.ElementRef<typeof RNVLC> | null =null;
  static defaultProps = {
    autoplay: true,
  };

  snapshot(path) {
    if(this.mRNVLCRef){
      VLCCommands.snapshot(this.mRNVLCRef, path);
    }
  }

  seek(pos) {
    if(this.mRNVLCRef){
      VLCCommands.seek(this.mRNVLCRef, pos);
    }
  }

  resume(isResume) {
    if(this.mRNVLCRef){
      VLCCommands.resume(this.mRNVLCRef, isResume);
    }
  }

  autoAspectRatio(isAuto) {
    this._root.setNativeProps({ autoAspectRatio: isAuto });
  }

  changeVideoAspectRatio(ratio) {
    this._root.setNativeProps({ videoAspectRatio: ratio });
  }

  stopPlayer() {
    if(this.mRNVLCRef){
      VLCCommands.stopPlayer(this.mRNVLCRef);
    }
  }

  onBuffering = e => {
    if (this.props.onBuffering) {
      this.props.onBuffering(e.nativeEvent);
    }
  }

  onPaused = e => {
    if (this.props.onPaused) {
      this.props.onPaused(e.nativeEvent);
    }
  }

  onOpen = e => {
    if (this.props.onOpen) {
      this.props.onOpen(e.nativeEvent);
    }
  }

  onEnded = e => {
    if (this.props.onEnd) {
      this.props.onEnd(e.nativeEvent);
    }
  }

  onStopped = e => {
    if (this.props.onStopped) {
      this.props.onStopped();
    }
  }

  onPlaying = e => {
    if (this.props.onPlaying) {
      this.props.onPlaying(e.nativeEvent);
    }
  }

  onSnapshot = e => {
    if (this.props.onSnapshot) {
      this.props.onSnapshot(e.nativeEvent);
    }
  }

  onLoadStart = e => {
    if (this.props.onLoadStart) {
      this.props.onLoadStart(e.nativeEvent);
    }
  }

  onProgress = e => {
    if (this.props.onProgress) {
      this.props.onProgress(e.nativeEvent);
    }
  }

  onEnd = e => {
    if (this.props.onEnd) {
      this.props.onEnd(e.nativeEvent);
    }
  }

  onError = e => {
    if (this.props.onError) {
      this.props.onError(e.nativeEvent);
    }
  }

  onLoad = e => {
    if (this.props.onLoad) {
      this.props.onLoad(e.nativeEvent);
    }
  }

  assignRoot = component => {
    this._root = component;
    this.mRNVLCRef = component;
  }

  render() {
    const stylesCombined = [styles.base, this.props.styles];
    return (
      <RNVLC
        {...this.props}
        styles={stylesCombined}
        ref={this.assignRoot}
        onPlaying = {this.onPlaying}
        onProgress = {this.onProgress}
        onPaused = {this.onPaused}
        onStopped = {this.onStopped}
        onBuffering = {this.onBuffering}
        onEnd = {this.onEnd}
        onError = {this.onError}
        onLoad = {this.onLoad}
        onSnapshot = {this.onSnapshot}
        onOpen = {this.onOpen}
      />
    );
  }
}

VLCPlayer.propTypes = {
  rate: PropTypes.number,
  seek: PropTypes.number,
  resume: PropTypes.bool,
  paused: PropTypes.bool,

  autoAspectRatio: PropTypes.bool,
  videoAspectRatio: PropTypes.string,
  volume: PropTypes.number,
  disableFocus: PropTypes.bool,
  src: PropTypes.string,
  playInBackground: PropTypes.bool,
  playWhenInactive: PropTypes.bool,
  resizeMode: PropTypes.string,
  poster: PropTypes.string,
  repeat: PropTypes.bool,
  muted: PropTypes.bool,
  audioTrack: PropTypes.number,
  textTrack: PropTypes.number,
  acceptInvalidCertificates: PropTypes.bool,
  progressUpdateInterval: PropTypes.number,

  onPlaying: PropTypes.func,
  onProgress: PropTypes.func,
  onPaused: PropTypes.func,
  onStopped: PropTypes.func,
  onBuffering: PropTypes.func,
  onEnd: PropTypes.func,
  onError: PropTypes.func,
  onLoad: PropTypes.func,
  onSnapshot: PropTypes.func,
  onOpen: PropTypes.func,
};

const styles = StyleSheet.create({
  base: {
    overflow: "hidden",
  },
});
