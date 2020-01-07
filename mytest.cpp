// Minimal HTTP server in 0MQ
// from http://glaudiston.blogspot.com/2017/08/zmq-zeromq-as-http-server.html

#include <cassert>
#include "zhelpers.h"

static volatile int keepRunning = 1;

void intHandler(int dummy) { keepRunning = 0; }

int main(void) {
  int rc;

  // Set-up our context and sockets
  void *ctx = zmq_ctx_new();
  assert(ctx);

  // Start our server listening
  void *server = zmq_socket(ctx, ZMQ_STREAM);
  zmq_bind(server, "tcp://*:8080");
  assert(server);
  uint8_t id[256];
  size_t id_size = 256;

  signal(SIGINT, intHandler);

  printf("ZMQ-based HTTP server initialized\n");

  zmq_msg_t http_request;
  zmq_msg_init(&http_request);
  while (keepRunning) {
    // Get HTTP request IDENTITY;
    // first frame has ID, the next the request.
    id_size = zmq_recv(server, id, 256, 0);
    if (id_size == -1 && errno == EINTR)
      break;               // user wants to exit with CTRL+C
    assert(id_size == 5);  // identity frames are 5B

    // Get HTTP request PAYLOAD
    rc = zmq_msg_recv(&http_request, server, 0);
    if (rc == -1) break;
    printf("Received HTTP request (%zuB): %s\n", zmq_msg_size(&http_request),
           zmq_msg_data(&http_request));  // Professional Logging(TM)

    while (true) {
      rc = zmq_msg_recv(&http_request, server, ZMQ_DONTWAIT);
      if (rc == -1) break;
      printf("Received HTTP request (%zuB): %s\n", zmq_msg_size(&http_request),
             zmq_msg_data(&http_request));  // Professional Logging(TM)
    }

    // define the response
    char http_response[] =
        "HTTP/1.0 200 OK\n"
        "Content-Type: text/html\n"
        "\n"
        "Hello, World!\n";

    // start sending response
    rc = zmq_send(server, id, id_size, ZMQ_SNDMORE);
    assert(rc != -1);
    // Send the http response
    rc = zmq_send(server, http_response, sizeof(http_response), ZMQ_SNDMORE);
    assert(rc != -1);

    // Send a zero to close connection to client
    rc = zmq_send(server, id, id_size, ZMQ_SNDMORE);
    assert(rc != -1);
    rc = zmq_send(server, NULL, 0, ZMQ_SNDMORE);
    assert(rc != -1);
  }

  printf("ZMQ-based HTTP server shutting down\n");

  rc = zmq_close(server);
  assert(rc == 0);

  rc = zmq_ctx_term(ctx);
  assert(rc == 0);

  return 0;
}
