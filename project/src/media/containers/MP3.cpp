#define MINIMP3_IMPLEMENTATION
#include <minimp3.h>
#include <minimp3_ex.h>
#include <media/containers/MP3.h>
#include <utils/Bytes.h>
#include <utils/ArrayBufferView.h>

namespace lime {

    bool MP3::Decode (Resource *resource, AudioBuffer *audioBuffer) {

        if (!resource || !audioBuffer) {
            return false;
        }

        const uint8_t *inputData = NULL;
        int inputLength = 0;
        Bytes fileBytes;

        if (resource->data) {

            inputData = resource->data->b;
            inputLength = resource->data->length;

        } else if (resource->path) {

            fileBytes.ReadFile (resource->path);

            if (!fileBytes.b || fileBytes.length == 0) {
                return false;
            }

            inputData = fileBytes.b;
            inputLength = fileBytes.length;

        } else {

            return false;

        }

        if (!inputData || inputLength <= 0) {
            return false;
        }

        mp3dec_t decoder;
        mp3dec_init (&decoder);

        mp3dec_file_info_t info = { 0 };
        int result = mp3dec_load_buf (&decoder, inputData, inputLength, &info, NULL, NULL);

        if (result != 0 || !info.buffer || info.samples == 0 || info.channels <= 0 || info.hz <= 0) {

            if (info.buffer) {
                free (info.buffer);
            }

            return false;

        }

        int byteLength = info.samples * static_cast<int>(sizeof (mp3d_sample_t));

        Bytes *decodedBytes = new Bytes ();
        decodedBytes->Resize (byteLength);
        memcpy (decodedBytes->b, info.buffer, byteLength);

        if (audioBuffer->data) {
            delete audioBuffer->data;
        }

        audioBuffer->data = new ArrayBufferView (alloc_null ());
        audioBuffer->data->type = 1;
        audioBuffer->data->byteOffset = 0;
        audioBuffer->data->buffer = decodedBytes;
        audioBuffer->data->byteLength = byteLength;
        audioBuffer->data->length = byteLength;
        audioBuffer->data->bytesPerElement = 1;

        audioBuffer->sampleRate = info.hz;
        audioBuffer->channels = info.channels;
        audioBuffer->bitsPerSample = 16;

        free (info.buffer);

        return true;

    }

}