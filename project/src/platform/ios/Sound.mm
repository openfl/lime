#include <UIKit/UIImage.h>
#import <AVFoundation/AVAudioPlayer.h>
#include <AudioToolbox/AudioToolbox.h>
#include <AudioToolbox/ExtendedAudioFile.h>

#include <Sound.h>
#include <QuickVec.h>
#include <Utils.h>

#include "OpenALSound.h"


@interface AVAudioPlayerChannelDelegate : NSObject <AVAudioPlayerDelegate>  {
@private
    // keeps track of how many times a track still has to play
    int loops;
    float offset;
    bool isPlaying;
}
@end

@implementation AVAudioPlayerChannelDelegate

- (id)init {
    self = [super init];
    return self;
}


-(bool) isPlaying  {
    return isPlaying;
}

-(id) initWithLoopsOffset: (int)theNumberOfLoops offset:(int)theOffset  {
    self = [super init];
    if ( self ) {
        loops = theNumberOfLoops;
        offset = theOffset;
        isPlaying = true;
    }
    return self;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    LOG_SOUND("AVAudioPlayerChannelDelegate audioPlayerDidFinishPlaying()");
    LOG_SOUND("loops : %d", loops );
    LOG_SOUND("offset : %f", offset);
    
    if (loops == 0) {
        LOG_SOUND("finished the mandated number of loops");
        isPlaying = false;
        // the channel has done its job.
        // we should release both the player and the delegate
        // right here, but the problem is that someone has to
        // notify the channel that we are done because he has to do
        // his own cleanup (someone will poll him later whether the channel
        // is done playing).
        // Long story short, because of weird issues, we can't keep
        // a handle to the channel here, so we can't notify him.
        // So what we do instead is we'll let the channel release
        // both the player and the delegate when he'll find out that the
        // player is not playing anymore.        
    }
    else {
        LOG_SOUND("still some loops to go, playing");
        loops--;
        player.currentTime = offset/1000;
        [player play];
    }
}

@end


namespace lime
{
    
    
    
    /*----------------------------------------------------------
     AVSoundPlayer implementation of Sound and SoundChannel classes:
     - higher latency than OpenAL implementation
     - streams sound data using Apple's optimized pathways
     - doesn't allocate uncompressed sound data in memory
     - doesn't expose sound data
     ------------------------------------------------------------*/
    
    class AVAudioPlayerChannel : public SoundChannel  {
        
    public:
        AVAudioPlayerChannel(Object *inSound, const std::string &inFilename,
            NSData *data,
            int inLoops, float  inOffset, const SoundTransform &inTransform)
        {
            LOG_SOUND("AVAudioPlayerChannel constructor");
            mSound = inSound;
            // each channel keeps the originating Sound object alive.
            inSound->IncRef();
           
            LOG_SOUND("AVAudioPlayerChannel constructor - allocating and initilising the AVAudioPlayer");

            if (data == NULL) {
                LOG_SOUND("AVAudioPlayerChannel construct with name");
                std::string name;
                
                if (inFilename[0] == '/') {
                    name = inFilename;
                } else {
                    name = GetResourcePath() + gAssetBase + inFilename;
                }
                
                NSString *theFileName = [[NSString alloc] initWithUTF8String:name.c_str()];
                
                NSURL  *theFileNameAndPathAsUrl = [NSURL fileURLWithPath:theFileName ];
                
                theActualPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:theFileNameAndPathAsUrl error: nil];
#ifndef OBJC_ARC
                [theFileName release];
#endif
            } else {
                LOG_SOUND("AVAudioPlayerChannel construct with data");
                theActualPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
            }

            // for each player there is a delegate
            // the reason for this is that AVAudioPlayer has no way to loop
            // starting at an offset. So what we need to do is to
            // get the delegate to react to a loop end, rewing the player
            // and play again.
            LOG_SOUND("AVAudioPlayerChannel constructor - allocating and initialising the delegate");
            thePlayerDelegate = [[AVAudioPlayerChannelDelegate alloc] initWithLoopsOffset:inLoops offset:inOffset];
            [theActualPlayer setDelegate:thePlayerDelegate];
            
            // the sound channel has been created because play() was called
            // on a Sound, so let's play
            LOG_SOUND("AVAudioPlayerChannel constructor - getting the player to play at offset %f", inOffset);
            theActualPlayer.currentTime = inOffset/1000;
            if ([theActualPlayer respondsToSelector: NSSelectorFromString(@"setPan")])
                [theActualPlayer setPan: inTransform.pan];
            [theActualPlayer setVolume: inTransform.volume];
            [theActualPlayer play];
            
            LOG_SOUND("AVAudioPlayerChannel constructor exiting");
        }
        
        ~AVAudioPlayerChannel()
        {
            LOG_SOUND("AVAudioPlayerChannel destructor");
            
            // when all channels associated with a sound
            // are all destroyed, then the Sound that generates
            // them might be destroyed (if there are no other
            // references to it anywhere else)
            mSound->DecRef();
        }
        
        void playerHasFinishedDoingItsJob() {
            theActualPlayer = nil;
        }
        
        bool isComplete()
        {
            //LOG_SOUND("AVAudioPlayerChannel isComplete()"); 
            bool isPlaying;
            
            if (theActualPlayer == nil) {
                // The AVAudioPlayer has been released before
                // , maybe by a stop() or maybe because
                // someone already called this method before
                // , he might be dead by now
                // so we can't ask him if he is playing.
                // We know that we return that it is complete
                isPlaying = false;
            }
            else {
                //LOG_SOUND("AVAudioPlayerChannel invoking isPlaying"); 
                
                // note that we ask the delegate, not the AVAudioPlayer
                // the reason is that technically AVAudioPlayer might not be playing,
                // but we are in the process of restarting it to play a loop,
                // and we don't want to stop him. So we ask the delegate, which
                // knows when all the loops are properly done.
                isPlaying = [thePlayerDelegate isPlaying];
                
                if (!isPlaying) {
                    // the channel is completely done playing, so we mark
                    // both the channel and its delegate eligible for destruction (if no-one
                    // has any more references to them)
                    // If all the channels associated to a Sound will be destroyed,
                    // then the Sound itself might be eligible for destruction (if there are
                    // no more references to it anywhere else).
                    #ifndef OBJC_ARC
                    [thePlayerDelegate release];
                    [theActualPlayer release];
                    #endif
                    theActualPlayer = nil;
                    thePlayerDelegate = nil;
                }
            }
            
            //LOG_SOUND("AVAudioPlayerSound isComplete() returning%@\n", (!isPlaying ? @"YES" : @"NO")); 
            return !isPlaying;
        }
        
        double getLeft()  {
            LOG_SOUND("AVAudioPlayerChannel getLeft()");
            if ([theActualPlayer respondsToSelector: NSSelectorFromString(@"setPan")])	   
            {
                return (1-[theActualPlayer pan])/2;
            }
            return 0.5;
        }
        double getRight()   {
            LOG_SOUND("AVAudioPlayerChannel getRight()");
            if ([theActualPlayer respondsToSelector: NSSelectorFromString(@"setPan")])
            {
                return ([theActualPlayer pan] + 1)/2;
            }
            return 0.5;
        }
        double getPosition()   {
            LOG_SOUND("AVAudioPlayerChannel getPosition()");
            return [theActualPlayer currentTime] * 1000;
        }
        double setPosition(const float &inFloat) {
            LOG_SOUND("AVAudioPlayerChannel setPosition()");
            theActualPlayer.currentTime = inFloat / 1000;
            return inFloat;
        }

        void setTransform(const SoundTransform &inTransform) {
            LOG_SOUND("AVAudioPlayerChannel setTransform()");
            if ([theActualPlayer respondsToSelector: NSSelectorFromString(@"setPan")])
            {
                [theActualPlayer setPan: inTransform.pan];
            }
            [theActualPlayer setVolume: inTransform.volume];
        }
        void stop()
        {
            LOG_SOUND("AVAudioPlayerChannel stop()");
            [theActualPlayer stop];
            
            // note that once a channel has been stopped, it's destined
            // to be deallocated. It will never play another sound again
            // we decrease the reference count here of both the player
            // and its delegate.
            // If someone calls isComplete() in the future,
            // that function will see the nil and avoid doing another
            // release.
            #ifndef OBJC_ARC
            [theActualPlayer release];
            [thePlayerDelegate release];
            #endif
            theActualPlayer = nil;
            thePlayerDelegate = nil;
            
        }
        
        
        Object *mSound;
        AVAudioPlayer *theActualPlayer;
        AVAudioPlayerChannelDelegate *thePlayerDelegate;
        
    };
    
    
    class AVAudioPlayerSound : public Sound
    {
    public:
        AVAudioPlayerSound(const std::string &inFilename) : mFilename(inFilename)
        {
            LOG_SOUND("AVAudioPlayerSound constructor()");
            IncRef();
            
            // we copy the filename to a local variable,
            // We pass the filename to create one AVSoundPlayer
            // each time the sound is played.
            // Note that we don't need the path, the filename suffices.
            //theFileName = [[NSString alloc] initWithUTF8String:inFilename.c_str()];
            
            // to answer the getLength() method and to see whether there will be any
            // ploblems loading the file we create an "initial" AVAudioPlayer
            // that we'll never actually use to play anything. We just get the length and
            // any potential error and we
            // release it soon after. Note that
            // no buffers are loaded until we invoke either the play or prepareToPlay
            // methods, so very little memory is used.
            
            this->data = nil;

            std::string path = GetResourcePath() + gAssetBase + inFilename;
            NSString *ns_name = [[NSString alloc] initWithUTF8String:path.c_str()];
            NSURL  *theFileNameAndPathAsUrl = [NSURL fileURLWithPath:ns_name];
            #ifndef OBJC_ARC
            [ns_name release];
            #endif
            
            NSError *err = nil;
            AVAudioPlayer *theActualPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:theFileNameAndPathAsUrl error:&err];
            if (err != nil)
            {
                mError = [[err description] UTF8String];
            }
            
            theDuration = [theActualPlayer duration] * 1000;
            #ifndef OBJC_ARC
            [theActualPlayer release];
            #endif
        }
        
        AVAudioPlayerSound(float *inDataPtr, int inDataLen)
        {
            mFilename = "unknown";
            
            LOG_SOUND("AVAudioPlayerSound constructor()");
            IncRef();
            
            //printf("AVAudioPlayerSound!!");
            
            this->data = [[NSData alloc] initWithBytes:inDataPtr length:inDataLen];
            
            NSError *err = nil;
            AVAudioPlayer *theActualPlayer = [[AVAudioPlayer alloc] initWithData:data error:&err];
            if (err != nil)
            {
                mError = [[err description] UTF8String];
            }
            
            theDuration = [theActualPlayer duration] * 1000;
#ifndef OBJC_ARC
            [theActualPlayer release];
#endif
        }
        
        ~AVAudioPlayerSound()
        {
            LOG_SOUND("AVAudioPlayerSound destructor() ##################################");
        }
        
        double getLength()
        {
            LOG_SOUND("AVAudioPlayerSound getLength returning %f", theDuration);
            
            // we got the duration stored already and each Sound only ever
            // loads one file - so no need to re-check, return what we have
            return theDuration;
        }
        
        void getID3Value(const std::string &inKey, std::string &outValue)
        {
            LOG_SOUND("AVAudioPlayerSound getID3Value returning empty string");
            outValue = "";
        }
        int getBytesLoaded()
        {
            int toBeReturned = ok() ? 100 : 0;
            LOG_SOUND("AVAudioPlayerSound getBytesLoaded returning %i", toBeReturned);
            return toBeReturned;
        }
        int getBytesTotal()
        {
            int toBeReturned = ok() ? 100 : 0;
            LOG_SOUND("AVAudioPlayerSound getBytesTotal returning %i", toBeReturned);
            return toBeReturned;
        }
        bool ok()
        {
            bool toBeReturned = mError.empty();
            LOG_SOUND("AVAudioPlayerSound ok() returning BOOL = %s\n", (toBeReturned ? "YES" : "NO")); 
            return toBeReturned;
        }
        std::string getError()
        {
            LOG_SOUND("AVAudioPlayerSound getError()"); 
            return mError;
        }
        
        void close()
        {
            LOG_SOUND("AVAudioPlayerSound close() doing nothing"); 
        }
        
        // This method is called when Sound.play is called.
        SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
        {
            LOG_SOUND("AVAudioPlayerSound openChannel() startTime=%f, loops = %d",startTime,loops); 
            //return new AVAudioPlayerChannel(this,mBufferID,loops,inTransform);
            
            // this creates the channel, note that the channel is an AVAudioPlayer that plays
            // right away
            return new AVAudioPlayerChannel(this, mFilename, data, loops, startTime, inTransform);
        }
        
        std::string mError;
        std::string mFilename;
        double theDuration;
        NSData *data;
    };
    
    
    Sound *Sound::Create(const std::string &inFilename,bool inForceMusic)
    {
        // Here we pick a Sound object based on either OpenAL or Apple's AVSoundPlayer
        // depending on the inForceMusic flag.
        //
        // OpenAL has lower latency but can be expensive memory-wise when playing
        // files more than a few seconds long, and it's not really needed anyways if there is
        // no need to work with the uncompressed data.
        //
        // AVAudioPlayer has slightly higher latency and doesn't give access to uncompressed
        // sound data, but uses "Apple's optimized pathways" and doesn't need to store
        // uncompressed sound data in memory.
        //
        // By default the OpenAL implementation is picked, while AVAudioPlayer is used then
        // inForceMusic is true.
        
        LOG_SOUND("Sound.mm Create()\n");
        
        std::string fileURL;
        
        if (inFilename[0] == '/') {
            fileURL = inFilename;
        } else {
            fileURL = GetResourcePath() + gAssetBase + inFilename;
        }
        
        AudioFormat type = Audio::determineFormatFromFile(fileURL);
        
        if (type == eAF_ogg || !inForceMusic)
        {
            if (!OpenALInit())
                return 0;
            
            OpenALSound *sound = new OpenALSound(inFilename, inForceMusic);
            
            if (sound->ok ())
               return sound;
            else
               return 0;
        }
        else
        {
            return new AVAudioPlayerSound(inFilename);
        }
    }
    
    
    Sound *Sound::Create(float *inData, int len, bool inForceMusic)
    {
        // Here we pick a Sound object based on either OpenAL or Apple's AVSoundPlayer
        // depending on the inForceMusic flag.
        //
        // OpenAL has lower latency but can be expensive memory-wise when playing
        // files more than a few seconds long, and it's not really needed anyways if there is
        // no need to work with the uncompressed data.
        //
        // AVAudioPlayer has slightly higher latency and doesn't give access to uncompressed
        // sound data, but uses "Apple's optimized pathways" and doesn't need to store
        // uncompressed sound data in memory.
        //
        // By default the OpenAL implementation is picked, while AVAudioPlayer is used then
        // inForceMusic is true.
        
        LOG_SOUND("Sound.mm Create()\n");
        if (inForceMusic)
        {
            return new AVAudioPlayerSound(inData, len);
        }
        else
        {
            if (!OpenALInit())
                return 0;
            OpenALSound *sound = new OpenALSound(inData, len);
            
            if (sound->ok ())
               return sound;
            else
               return 0;
        }
    }
    
    
} // end namespace lime