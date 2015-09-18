#pragma once

#include <pthread.h>
#include <ao/ao.h>

pthread_mutex_t queue_mutex = PTHREAD_MUTEX_INITIALIZER;

struct toPlay_s
{
   int out_samples;
   uint8_t* output;
   ao_device* adevice;
};

#define QUEUE_ELEM struct toPlay_s

/* Queue structure */
#define QUEUE_ELEMENTS 1000
#define QUEUE_SIZE (QUEUE_ELEMENTS + 1)
QUEUE_ELEM* Queue[QUEUE_SIZE];
int QueueIn, QueueOut;


void QueueInit(void)
{
    QueueIn = QueueOut = 0;
}

int QueuePut(QUEUE_ELEM* new_obj)
{
    pthread_mutex_lock(&queue_mutex);
    if(QueueIn == (( QueueOut - 1 + QUEUE_SIZE) % QUEUE_SIZE))
    {
        pthread_mutex_unlock(&queue_mutex);
        return -1; /* Queue Full*/
    }

    Queue[QueueIn] = new_obj;

    QueueIn = (QueueIn + 1) % QUEUE_SIZE;
    pthread_mutex_unlock(&queue_mutex);

    return 0; // No errors
}

int QueueGet(QUEUE_ELEM **old)
{
    pthread_mutex_lock(&queue_mutex);
    if(QueueIn == QueueOut)
    {
        pthread_mutex_unlock(&queue_mutex);
        return -1; /* Queue Empty - nothing to get*/
    }

    *old = Queue[QueueOut];

    QueueOut = (QueueOut + 1) % QUEUE_SIZE;
    pthread_mutex_unlock(&queue_mutex);

    return 0; // No errors
}
