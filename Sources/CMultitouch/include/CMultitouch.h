#ifndef CMultitouch_h
#define CMultitouch_h

#include <CoreFoundation/CoreFoundation.h>

// Minimal declarations for Apple's private MultitouchSupport.framework.
// These are stable and have been used by trackpad utilities for many years.

typedef struct { float x, y; } MTPoint;
typedef struct { MTPoint position; MTPoint velocity; } MTVector;

typedef struct {
    int   frame;
    double timestamp;
    int   pathIndex;
    int   state;
    int   fingerID;
    int   handID;
    MTVector normalized; // position/velocity in 0..1 trackpad units
    float size;
    int   pressure;
    float angle;
    float majorAxis;
    float minorAxis;
    MTVector absolute;
    int   pad0;
    int   pad1;
    float zDensity;
} Finger;

typedef void *MTDeviceRef;

// callback(device, fingers[], nFingers, timestamp, frame)
typedef int (*MTContactCallbackFunction)(int, Finger *, int, double, int);

CFMutableArrayRef MTDeviceCreateList(void);
MTDeviceRef       MTDeviceCreateDefault(void);
void MTRegisterContactFrameCallback(MTDeviceRef, MTContactCallbackFunction);
void MTUnregisterContactFrameCallback(MTDeviceRef, MTContactCallbackFunction);
void MTDeviceStart(MTDeviceRef, int);
void MTDeviceStop(MTDeviceRef);

// Swift-friendly wrapper: fills `out` with up to `max` device refs (retained),
// returns the count. Avoids CoreFoundation ownership ambiguity in Swift.
int MT_GetDevices(MTDeviceRef *out, int max);

#endif /* CMultitouch_h */
