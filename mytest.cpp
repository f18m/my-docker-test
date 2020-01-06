// Minimal HTTP server in 0MQ
// from http://glaudiston.blogspot.com/2017/08/zmq-zeromq-as-http-server.html

#include "zhelpers.h"
#include <cassert>

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

  while (1) {
    // Get HTTP request;
    // first frame has ID, the next the request.
    id_size = zmq_recv(server, id, 256, 0);
    assert(id_size > 0);

    // Get HTTP request
    char *request = s_recv(server);
    puts(request); // Professional Logging(TM)
    free(request); // We throw this away

    // define the response
    char http_response[] = "HTTP/1.0 200 OK\n"
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

  rc = zmq_close(server);
  assert(rc == 0);

  rc = zmq_ctx_term(ctx);
  assert(rc == 0);

  return 0;
}
