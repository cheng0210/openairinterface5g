//#include <zmq.h>
//#include <stdio.h>
//#include <stdlib.h>
//#include <string.h>
//
//#define BUFFER_SIZE 1000000  // Adjust based on your expected maximum message size
//#define ZMQ_CLIENT_ADDRESS "tcp://localhost:5555"  // For the subscriber (receiver)
//
//
//int main() {
//  void *context = zmq_ctx_new();
//  void *subscriber = zmq_socket(context, ZMQ_SUB);
//  int rc = zmq_connect(subscriber, ZMQ_CLIENT_ADDRESS);
//  if (rc != 0) {
//    printf("Error connecting to publisher: %s\n", zmq_strerror(errno));
//    return 1;
//  }
//
//  // Subscribe to all messages
//  zmq_setsockopt(subscriber, ZMQ_SUBSCRIBE, "", 0);
//
//  printf("Subscriber connected and waiting for messages...\n");
//
//  while (1) {
//    char buffer[BUFFER_SIZE];
//    int size = zmq_recv(subscriber, buffer, BUFFER_SIZE, 0);
//    if (size == -1) {
//      printf("Error receiving message: %s\n", zmq_strerror(errno));
//      continue;
//    }
//
//    int num_elements = size / sizeof(int32_t);
//    int32_t *data = (int32_t*)buffer;
//
//    printf("Received %d int32_t elements\n", num_elements);
//
//    // Process the received data here
//    // For example, you could print the first few elements:
//    for (int i = 0; i < 10 && i < num_elements; i++) {
//      printf("%d ", data[i]);
//    }
//    printf("\n");
//  }
//
//  zmq_close(subscriber);
//  zmq_ctx_destroy(context);
//  return 0;
//}

#include <zmq.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <matio.h>
#include <signal.h>
#include <unistd.h>

#define BUFFER_SIZE 1000000  // Adjust based on your expected maximum message size
#define MAX_MESSAGES 1000    // Maximum number of messages to store

volatile sig_atomic_t keep_running = 1;

void intHandler(int dummy) {
  keep_running = 0;
}

int main() {
  void *context = zmq_ctx_new();
  void *subscriber = zmq_socket(context, ZMQ_SUB);
  int rc = zmq_connect(subscriber, "tcp://localhost:5555");
  if (rc != 0) {
    printf("Error connecting to publisher: %s\n", zmq_strerror(errno));
    return 1;
  }

  // Subscribe to all messages
  zmq_setsockopt(subscriber, ZMQ_SUBSCRIBE, "", 0);

  printf("Subscriber connected and waiting for messages...\n");
  printf("Press Ctrl+C to stop and save data.\n");

  // Set up signal handler
  signal(SIGINT, intHandler);

  int32_t **all_data = malloc(MAX_MESSAGES * sizeof(int32_t*));
  int message_count = 0;
  int *message_sizes = malloc(MAX_MESSAGES * sizeof(int));

  while (keep_running && message_count < MAX_MESSAGES) {
    char buffer[BUFFER_SIZE];
    int size = zmq_recv(subscriber, buffer, BUFFER_SIZE, ZMQ_DONTWAIT);
    if (size == -1) {
      if (errno == EAGAIN) {
        // No message available, sleep for a short time
        usleep(1000);
        continue;
      }
      printf("Error receiving message: %s\n", zmq_strerror(errno));
      break;
    }

    int num_elements = size / sizeof(int32_t);
    int32_t *data = malloc(size);
    memcpy(data, buffer, size);

    all_data[message_count] = data;
    message_sizes[message_count] = num_elements;
    message_count++;

    printf("Received message %d with %d int32_t elements\n", message_count, num_elements);
  }

  printf("Saving data to srs_data.mat...\n");

  // Save data to .mat file
  mat_t *matfp;
  matvar_t *matvar;

  matfp = Mat_Create("srs_data.mat", NULL);
  if (matfp == NULL) {
    printf("Error creating MAT file\n");
    return 1;
  }

  for (int i = 0; i < message_count; i++) {
    char var_name[20];
    snprintf(var_name, sizeof(var_name), "srs_data_%d", i+1);
    size_t dims[2] = {1, message_sizes[i]};

    matvar = Mat_VarCreate(var_name, MAT_C_INT32, MAT_T_INT32, 2, dims, all_data[i], 0);
    if (matvar == NULL) {
      printf("Error creating variable %s\n", var_name);
      continue;
    }

    Mat_VarWrite(matfp, matvar, MAT_COMPRESSION_NONE);
    Mat_VarFree(matvar);
  }

  Mat_Close(matfp);

  printf("Data saved to srs_data.mat\n");

  // Clean up
  for (int i = 0; i < message_count; i++) {
    free(all_data[i]);
  }
  free(all_data);
  free(message_sizes);

  zmq_close(subscriber);
  zmq_ctx_destroy(context);
  return 0;
}