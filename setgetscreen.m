
/*
 * setgetscreenres.m
 * 
 * juanfc 2009-04-13
 * jawsoftware 2009-04-17
 * Based on newscreen
 *    Created by Jeffrey Osterman on 10/30/07.
 *    Copyright 2007 Jeffrey Osterman. All rights reserved. 
 *    PROVIDED AS IS AND WITH NO WARRANTIES WHATSOEVER
 *    http://forums.macosxhints.com/showthread.php?t=59575
 *
 * COMPILE:
 *    c++ setgetscreenres.m -framework ApplicationServices -o setgetscreenres
 * USE:
 *    setgetscreenres [ -l | 1..9] [ 1440 900 ]
 */

#include <ApplicationServices/ApplicationServices.h>

struct screenMode {
    size_t width;
    size_t height;
    size_t bitsPerPixel;
};


bool MyDisplaySwitchToMode (CGDirectDisplayID display, CGDisplayModeRef mode);
void ListDisplays( CGDisplayCount dispCount, CGDirectDisplayID *dispArray );
void usage(const char *argv[]);
void GetDisplayParms(CGDirectDisplayID *dispArray,  CGDisplayCount dispNum, int *width, int *height, int *depth, int *freq);
CGDisplayModeRef bestMatchForMode (struct screenMode screenMode);

int main (int argc, const char * argv[])
{
    int    h;                             // horizontal resolution
    int v;                             // vertical resolution
    int depth, freq;
    struct screenMode resMode;

    CGDisplayModeRef switchMode;     // mode to switch to
    CGDirectDisplayID theDisplay;  // ID of  display, display to set
    int displayNum; //display number requested by user
    
    CGDisplayCount maxDisplays = 10;
    CGDirectDisplayID onlineDspys[maxDisplays];
    CGDisplayCount dspyCnt;
    
    CGGetOnlineDisplayList (maxDisplays, onlineDspys, &dspyCnt);

    
    if (argc == 1) {
        CGRect screenFrame = CGDisplayBounds(kCGDirectMainDisplay);
        CGSize screenSize  = screenFrame.size;
        printf("%.0f %.0f\n", screenSize.width, screenSize.height);
        return 0;
    }
    
    if (argc == 2) {
        if (! strcmp(argv[1],"-l")) {
            ListDisplays( dspyCnt, onlineDspys );
            return 0;
        }
        else if (! strcmp(argv[1],"-?")) {
            usage(argv);
            return 0;
        }
        else if ((displayNum = atoi(argv[1]))) {
            if (displayNum <= dspyCnt) {
                GetDisplayParms(onlineDspys, displayNum-1, &h, &v, &depth, &freq);
                printf("%d %d\n", h, v);
                return 0;
            }
            else {
                fprintf(stderr, "ERROR: display number out of bounds; displays on this mac: %d.\n", dspyCnt);
                return -1;
            }
        }
    }
    
    
    if (argc == 4 && (displayNum = atoi(argv[1])) && (h = atoi(argv[2])) && (v = atoi(argv[3])) ) {
        if (displayNum <= dspyCnt) {
            theDisplay= onlineDspys[displayNum-1];
        }
        else return -1;
    }
    else {
        if (argc != 3 || !(h = atoi(argv[1])) || !(v = atoi(argv[2])) ) {
            fprintf(stderr, "ERROR: syntax error.\n");
            usage(argv);
            return -1;
        }
        theDisplay = CGMainDisplayID();
    }

    resMode.height = v;
    resMode.width = h;
    resMode.bitsPerPixel = 32;

    switchMode = bestMatchForMode(resMode);
    
    if (! MyDisplaySwitchToMode(theDisplay, switchMode)) {
        fprintf(stderr, "Error changing resolution to %d %d\n", h, v);
        return 1;
    }
    
    return 0;
}

void ListDisplays( CGDisplayCount dispCount, CGDirectDisplayID *dispArray )
{
    int    h, v, depth, freq;
    int i;
    CGDirectDisplayID mainDisplay = CGMainDisplayID();
    
        printf("Displays found: %d\n", dispCount);
        for    (i = 0 ; i < dispCount ;  i++ ) {

            GetDisplayParms(dispArray, i, &h, &v, &depth, &freq);
            printf("Display %d (id %d):  %d x %d x %d @ %dHz", i+1, dispArray[i], h, v, depth, freq);
            if ( mainDisplay == dispArray[i] ) 
                printf(" (main)\n");
            else
                printf("\n");
        }

    // List all available modes
    printf("Available resolutions:\n");
    CFArrayRef allModes = CGDisplayCopyAllDisplayModes(kCGDirectMainDisplay, NULL);
    for(int i = 0; i < CFArrayGetCount(allModes); i++)    {
        CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(allModes, i);

            printf ("%d: %d x %d\n",i,CGDisplayModeGetWidth(mode),CGDisplayModeGetHeight(mode));
        
    }
}

void GetDisplayParms(CGDirectDisplayID *dispArray,  CGDisplayCount dispNum, int *width, int *height, int *depth, int *freq)
{
    CGDisplayModeRef currentMode = CGDisplayCopyDisplayMode (dispArray[dispNum]);
    *freq = CGDisplayModeGetRefreshRate(currentMode);
    *width = CGDisplayModeGetWidth(currentMode);
    *height = CGDisplayModeGetHeight(currentMode);
    //CFNumberGetValue (number, kCFNumberLongType, depth);
    *depth = 32;
    
}

bool MyDisplaySwitchToMode (CGDirectDisplayID display, CGDisplayModeRef mode)
{
    CGDisplayConfigRef config;
    if (CGBeginDisplayConfiguration(&config) == kCGErrorSuccess) {
        CGConfigureDisplayWithDisplayMode(config, display, mode, NULL);
        CGCompleteDisplayConfiguration(config, kCGConfigureForSession );
        return true;
    }
    return false;
}


void usage(const char *argv[])
{
    printf("\nUsage: %s [-l | 1..9 ] [ hor_res vert_res]\n\n", argv[0]);
    printf("      -l  list resolution, depth and refresh rate of all displays\n");
    printf("    1..9  display # (default: main display)\n");
    printf(" hor_res  horizontal resolution\n");
    printf("vert_res  vertical resolution\n\n");
    printf("Examples:\n");
    printf("%s 800 600      set resolution of main display to 800x600\n", argv[0]);
    printf("%s 2 800 600    set resolution of secondary display to 800x600\n", argv[0]);
    printf("%s 3            get resolution of third display\n", argv[0]);
    printf("%s -l           get resolution, bit depth and refresh rate of all displays\n\n", argv[0]);
}

size_t displayBitsPerPixelForMode (CGDisplayModeRef mode) {
    
    size_t depth = 0;
    
    CFStringRef pixEnc = CGDisplayModeCopyPixelEncoding(mode);
    if(CFStringCompare(pixEnc, CFSTR(IO32BitDirectPixels), kCFCompareCaseInsensitive) == kCFCompareEqualTo)
        depth = 32;
    else if(CFStringCompare(pixEnc, CFSTR(IO16BitDirectPixels), kCFCompareCaseInsensitive) == kCFCompareEqualTo)
        depth = 16;
    else if(CFStringCompare(pixEnc, CFSTR(IO8BitIndexedPixels), kCFCompareCaseInsensitive) == kCFCompareEqualTo)
        depth = 8;
    
    return depth;
}

CGDisplayModeRef bestMatchForMode (struct screenMode screenMode) {
    
    bool exactMatch = false;
    
    // Get a copy of the current display mode
    CGDisplayModeRef displayMode = CGDisplayCopyDisplayMode(kCGDirectMainDisplay);
    
    // Loop through all display modes to determine the closest match.
    // CGDisplayBestModeForParameters is deprecated on 10.6 so we will emulate it's behavior
    // Try to find a mode with the requested depth and equal or greater dimensions first.
    // If no match is found, try to find a mode with greater depth and same or greater dimensions.
    // If still no match is found, just use the current mode.
    CFArrayRef allModes = CGDisplayCopyAllDisplayModes(kCGDirectMainDisplay, NULL);
    for(int i = 0; i < CFArrayGetCount(allModes); i++)    {
        CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(allModes, i);

        if(displayBitsPerPixelForMode(mode) != screenMode.bitsPerPixel)
            continue;
        
        if((CGDisplayModeGetWidth(mode) == screenMode.width) && (CGDisplayModeGetHeight(mode) == screenMode.height))
        {
            displayMode = mode;
            exactMatch = true;
            break;
        }
    }
    
    // No depth match was found
    if(!exactMatch)
    {
        for(int i = 0; i < CFArrayGetCount(allModes); i++)
        {
            CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(allModes, i);
            if(displayBitsPerPixelForMode(mode) >= screenMode.bitsPerPixel)
                continue;
            
            if((CGDisplayModeGetWidth(mode) >= screenMode.width) && (CGDisplayModeGetHeight(mode) >= screenMode.height))
            {
                displayMode = mode;
                break;
            }
        }
    }
    return displayMode;
}
