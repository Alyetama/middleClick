#include "CMultitouch.h"

int MT_GetDevices(MTDeviceRef *out, int max) {
    CFMutableArrayRef list = MTDeviceCreateList();
    if (!list) return 0;
    int n = (int)CFArrayGetCount(list);
    if (n > max) n = max;
    for (int i = 0; i < n; i++) {
        MTDeviceRef dev = (MTDeviceRef)CFArrayGetValueAtIndex(list, i);
        if (dev) CFRetain(dev); // keep valid after the list is released
        out[i] = dev;
    }
    CFRelease(list);
    return n;
}
