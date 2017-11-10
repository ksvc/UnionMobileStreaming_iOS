//
//  libunionmediaengine.h
//
//  Copyright (c) 2016 Union. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <GPUImage/GPUImage.h>

// sources (player & capture)
#import "UnionAVFCapture.h"
#import "UnionAUAudioCapture.h"
#import "UnionDummyAudioSource.h"

#import "UnionGPUPicInput.h"
#import "AVAudioSession+Union.h"


#import "UnionGPUViewCapture.h"
// mixer
#import "UnionGPUPicMixer.h"
#import "UnionAudioMixer.h"

// streamer
#import "UnionGPUPicOutput.h"
#import "UnionGPUView.h"

// utils
#import "UnionWeakProxy.h"

#define UnionMediaENGINE_VER 0.0.0.0
#define UnionMediaENGINE_ID 0

