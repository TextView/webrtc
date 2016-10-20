// This file was GENERATED by command:
//     pump.py refcountedobject.h.pump
// DO NOT EDIT BY HAND!!!

/*
 *  Copyright 2016 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

// To generate refcount.h from refcount.h.pump, execute:
// ./testing/gtest/scripts/pump.py ./webrtc/base/refcountedobject.h.pump

#ifndef WEBRTC_BASE_REFCOUNTEDOBJECT_H_
#define WEBRTC_BASE_REFCOUNTEDOBJECT_H_

#include <utility>

#include "webrtc/base/atomicops.h"

namespace rtc {

template <class T>
class RefCountedObject : public T {
 public:
  RefCountedObject() {}

  template <class P0>
  explicit RefCountedObject(P0&& p0) : T(std::forward<P0>(p0)) {}
  template <class P0, class P1>
  RefCountedObject(P0&& p0, P1&& p1)
      : T(std::forward<P0>(p0), std::forward<P1>(p1)) {}
  template <class P0, class P1, class P2>
  RefCountedObject(P0&& p0, P1&& p1, P2&& p2)
      : T(std::forward<P0>(p0), std::forward<P1>(p1), std::forward<P2>(p2)) {}
  template <class P0, class P1, class P2, class P3>
  RefCountedObject(P0&& p0, P1&& p1, P2&& p2, P3&& p3)
      : T(std::forward<P0>(p0),
          std::forward<P1>(p1),
          std::forward<P2>(p2),
          std::forward<P3>(p3)) {}
  template <class P0, class P1, class P2, class P3, class P4>
  RefCountedObject(P0&& p0, P1&& p1, P2&& p2, P3&& p3, P4&& p4)
      : T(std::forward<P0>(p0),
          std::forward<P1>(p1),
          std::forward<P2>(p2),
          std::forward<P3>(p3),
          std::forward<P4>(p4)) {}
  template <class P0, class P1, class P2, class P3, class P4, class P5>
  RefCountedObject(P0&& p0, P1&& p1, P2&& p2, P3&& p3, P4&& p4, P5&& p5)
      : T(std::forward<P0>(p0),
          std::forward<P1>(p1),
          std::forward<P2>(p2),
          std::forward<P3>(p3),
          std::forward<P4>(p4),
          std::forward<P5>(p5)) {}
  template <class P0,
            class P1,
            class P2,
            class P3,
            class P4,
            class P5,
            class P6>
  RefCountedObject(P0&& p0,
                   P1&& p1,
                   P2&& p2,
                   P3&& p3,
                   P4&& p4,
                   P5&& p5,
                   P6&& p6)
      : T(std::forward<P0>(p0),
          std::forward<P1>(p1),
          std::forward<P2>(p2),
          std::forward<P3>(p3),
          std::forward<P4>(p4),
          std::forward<P5>(p5),
          std::forward<P6>(p6)) {}
  template <class P0,
            class P1,
            class P2,
            class P3,
            class P4,
            class P5,
            class P6,
            class P7>
  RefCountedObject(P0&& p0,
                   P1&& p1,
                   P2&& p2,
                   P3&& p3,
                   P4&& p4,
                   P5&& p5,
                   P6&& p6,
                   P7&& p7)
      : T(std::forward<P0>(p0),
          std::forward<P1>(p1),
          std::forward<P2>(p2),
          std::forward<P3>(p3),
          std::forward<P4>(p4),
          std::forward<P5>(p5),
          std::forward<P6>(p6),
          std::forward<P7>(p7)) {}
  template <class P0,
            class P1,
            class P2,
            class P3,
            class P4,
            class P5,
            class P6,
            class P7,
            class P8>
  RefCountedObject(P0&& p0,
                   P1&& p1,
                   P2&& p2,
                   P3&& p3,
                   P4&& p4,
                   P5&& p5,
                   P6&& p6,
                   P7&& p7,
                   P8&& p8)
      : T(std::forward<P0>(p0),
          std::forward<P1>(p1),
          std::forward<P2>(p2),
          std::forward<P3>(p3),
          std::forward<P4>(p4),
          std::forward<P5>(p5),
          std::forward<P6>(p6),
          std::forward<P7>(p7),
          std::forward<P8>(p8)) {}
  template <class P0,
            class P1,
            class P2,
            class P3,
            class P4,
            class P5,
            class P6,
            class P7,
            class P8,
            class P9>
  RefCountedObject(P0&& p0,
                   P1&& p1,
                   P2&& p2,
                   P3&& p3,
                   P4&& p4,
                   P5&& p5,
                   P6&& p6,
                   P7&& p7,
                   P8&& p8,
                   P9&& p9)
      : T(std::forward<P0>(p0),
          std::forward<P1>(p1),
          std::forward<P2>(p2),
          std::forward<P3>(p3),
          std::forward<P4>(p4),
          std::forward<P5>(p5),
          std::forward<P6>(p6),
          std::forward<P7>(p7),
          std::forward<P8>(p8),
          std::forward<P9>(p9)) {}
  template <class P0,
            class P1,
            class P2,
            class P3,
            class P4,
            class P5,
            class P6,
            class P7,
            class P8,
            class P9,
            class P10>
  RefCountedObject(P0&& p0,
                   P1&& p1,
                   P2&& p2,
                   P3&& p3,
                   P4&& p4,
                   P5&& p5,
                   P6&& p6,
                   P7&& p7,
                   P8&& p8,
                   P9&& p9,
                   P10&& p10)
      : T(std::forward<P0>(p0),
          std::forward<P1>(p1),
          std::forward<P2>(p2),
          std::forward<P3>(p3),
          std::forward<P4>(p4),
          std::forward<P5>(p5),
          std::forward<P6>(p6),
          std::forward<P7>(p7),
          std::forward<P8>(p8),
          std::forward<P9>(p9),
          std::forward<P10>(p10)) {}

  virtual int AddRef() const { return AtomicOps::Increment(&ref_count_); }

  virtual int Release() const {
    int count = AtomicOps::Decrement(&ref_count_);
    if (!count) {
      delete this;
    }
    return count;
  }

  // Return whether the reference count is one. If the reference count is used
  // in the conventional way, a reference count of 1 implies that the current
  // thread owns the reference and no other thread shares it. This call
  // performs the test for a reference count of one, and performs the memory
  // barrier needed for the owning thread to act on the object, knowing that it
  // has exclusive access to the object.
  virtual bool HasOneRef() const {
    return AtomicOps::AcquireLoad(&ref_count_) == 1;
  }

 protected:
  virtual ~RefCountedObject() {}

  mutable volatile int ref_count_ = 0;
};

}  // namespace rtc

#endif  // WEBRTC_BASE_REFCOUNTEDOBJECT_H_