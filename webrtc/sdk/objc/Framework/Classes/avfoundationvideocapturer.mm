/*
 *  Copyright 2015 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#include "avfoundationvideocapturer.h"

#import <AVFoundation/AVFoundation.h>

#import "RTCAVFoundationVideoCapturerInternal.h"
#import "RTCDispatcher+Private.h"
#import "WebRTC/RTCLogging.h"

#include "avfoundationformatmapper.h"
#include "libyuv/rotate.h"
#include "webrtc/base/bind.h"
#include "webrtc/base/checks.h"
#include "webrtc/base/logging.h"
#include "webrtc/base/thread.h"
#include "webrtc/common_video/include/corevideo_frame_buffer.h"
#include "webrtc/common_video/rotation.h"

namespace webrtc {

enum AVFoundationVideoCapturerMessageType : uint32_t {
  kMessageTypeFrame,
};

AVFoundationVideoCapturer::AVFoundationVideoCapturer() : _capturer(nil) {
  _capturer =
      [[RTCAVFoundationVideoCapturerInternal alloc] initWithCapturer:this];

  std::set<cricket::VideoFormat> front_camera_video_formats =
      GetSupportedVideoFormatsForDevice([_capturer frontCaptureDevice]);
  std::set<cricket::VideoFormat> back_camera_video_formats =
      GetSupportedVideoFormatsForDevice([_capturer backCaptureDevice]);
  std::vector<cricket::VideoFormat> intersection_video_formats;
  if (back_camera_video_formats.empty()) {
    intersection_video_formats.assign(front_camera_video_formats.begin(),
                                      front_camera_video_formats.end());

  } else if (front_camera_video_formats.empty()) {
    intersection_video_formats.assign(back_camera_video_formats.begin(),
                                      back_camera_video_formats.end());
  } else {
    std::set_intersection(
        front_camera_video_formats.begin(), front_camera_video_formats.end(),
        back_camera_video_formats.begin(), back_camera_video_formats.end(),
        std::back_inserter(intersection_video_formats));
  }
  SetSupportedFormats(intersection_video_formats);
}

AVFoundationVideoCapturer::~AVFoundationVideoCapturer() {
  _capturer = nil;
}

cricket::CaptureState AVFoundationVideoCapturer::Start(
    const cricket::VideoFormat& format) {
  if (!_capturer) {
    LOG(LS_ERROR) << "Failed to create AVFoundation capturer.";
    return cricket::CaptureState::CS_FAILED;
  }
  if (_capturer.isRunning) {
    LOG(LS_ERROR) << "The capturer is already running.";
    return cricket::CaptureState::CS_FAILED;
  }

  AVCaptureDevice* device = [_capturer getActiveCaptureDevice];
  AVCaptureSession* session = _capturer.captureSession;

  if (!SetFormatForCaptureDevice(device, session, format)) {
    return cricket::CaptureState::CS_FAILED;
  }

  SetCaptureFormat(&format);
  // This isn't super accurate because it takes a while for the AVCaptureSession
  // to spin up, and this call returns async.
  // TODO(tkchin): make this better.
  [_capturer start];
  SetCaptureState(cricket::CaptureState::CS_RUNNING);

  return cricket::CaptureState::CS_STARTING;
}

void AVFoundationVideoCapturer::Stop() {
  [_capturer stop];
  SetCaptureFormat(NULL);
}

bool AVFoundationVideoCapturer::IsRunning() {
  return _capturer.isRunning;
}

AVCaptureSession* AVFoundationVideoCapturer::GetCaptureSession() {
  return _capturer.captureSession;
}

bool AVFoundationVideoCapturer::CanUseBackCamera() const {
  return _capturer.canUseBackCamera;
}

void AVFoundationVideoCapturer::SetUseBackCamera(bool useBackCamera) {
  _capturer.useBackCamera = useBackCamera;
}

bool AVFoundationVideoCapturer::GetUseBackCamera() const {
  return _capturer.useBackCamera;
}

void AVFoundationVideoCapturer::CaptureSampleBuffer(
    CMSampleBufferRef sample_buffer, VideoRotation rotation) {
  if (CMSampleBufferGetNumSamples(sample_buffer) != 1 ||
      !CMSampleBufferIsValid(sample_buffer) ||
      !CMSampleBufferDataIsReady(sample_buffer)) {
    return;
  }

  CVImageBufferRef image_buffer = CMSampleBufferGetImageBuffer(sample_buffer);
  if (image_buffer == NULL) {
    return;
  }

  const int captured_width = CVPixelBufferGetWidth(image_buffer);
  const int captured_height = CVPixelBufferGetHeight(image_buffer);

  int adapted_width;
  int adapted_height;
  int crop_width;
  int crop_height;
  int crop_x;
  int crop_y;
  int64_t translated_camera_time_us;

  if (!AdaptFrame(captured_width, captured_height,
                  rtc::TimeNanos() / rtc::kNumNanosecsPerMicrosec,
                  rtc::TimeMicros(), &adapted_width, &adapted_height,
                  &crop_width, &crop_height, &crop_x, &crop_y,
                  &translated_camera_time_us)) {
    return;
  }

  rtc::scoped_refptr<VideoFrameBuffer> buffer =
      new rtc::RefCountedObject<CoreVideoFrameBuffer>(
          image_buffer,
          adapted_width, adapted_height,
          crop_width, crop_height,
          crop_x, crop_y);

  // Applying rotation is only supported for legacy reasons and performance is
  // not critical here.
  if (apply_rotation() && rotation != kVideoRotation_0) {
    buffer = buffer->NativeToI420Buffer();
    rtc::scoped_refptr<I420Buffer> rotated_buffer =
        (rotation == kVideoRotation_180)
            ? I420Buffer::Create(adapted_width, adapted_height)
            : I420Buffer::Create(adapted_height, adapted_width);
    libyuv::I420Rotate(
        buffer->DataY(), buffer->StrideY(),
        buffer->DataU(), buffer->StrideU(),
        buffer->DataV(), buffer->StrideV(),
        rotated_buffer->MutableDataY(), rotated_buffer->StrideY(),
        rotated_buffer->MutableDataU(), rotated_buffer->StrideU(),
        rotated_buffer->MutableDataV(), rotated_buffer->StrideV(),
        buffer->width(), buffer->height(),
        static_cast<libyuv::RotationMode>(rotation));
    buffer = rotated_buffer;
  }

  OnFrame(webrtc::VideoFrame(buffer, rotation, translated_camera_time_us),
          captured_width, captured_height);
}

}  // namespace webrtc
