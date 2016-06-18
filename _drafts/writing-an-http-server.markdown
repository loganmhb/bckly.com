---
title: Writing a toy HTTP Server in Clojure
---

I don't really understand how web servers work. That must mean, obviously, it's time to write one!

# Beginnings

The [HTTP spec][1] isn't completely impenetrable, but it's too much to implement in a first pass at a web server. At first, I just want to be able to respond to a minimal GET request and serve a file back. So step one is, what does a minimal GET request look like? I could google this but there's another, more fun way to do it.

HTTP operates on top of the TCP protocol, so I'm going to need to know how to use TCP in Clojure. But there's nothing that says you have to respond to an HTTP request with a valid HTTP response; TCP supports sending arbitrary binary data over a socket, so you can just echo whatever data you receive back. Writing this echo server will both give me the skeleton for my HTTP server (once I can read and write data over TCP sockets, all that's left is reading the request and writing the response) and allow me to investigate some HTTP requests that I create with cURL or my browser.

(I actually wrote a TCP echo server a few months ago in Rust, and to my surprise it's become the most useful utility I've written so far in my programming career. But I need to know how to do it in Clojure for this project, so I'll write another one.)

# TCP

The Java standard library includes a simple abstraction over the TCP protocol in the java.net.ServerSocket and java.net.Socket classes. By using these I can ignore the details of TCP's implementation.

I'll open a ServerSocket on the port I want to use, and then get a connection to a client with ServerSocket.accept(), which returns a Socket. I can read from and write to this socket using its getInputStream() and getOutputStream() methods.

My first implementation of the echo server used clojure.java.io's `reader` and `writer` functions to avoid having to read and write raw bytes, but that didn't work well. It echoed each line properly when I connected via telnet, but only wrote back the first line of a curl request.

It turned out to be simpler and more robust to just read and write a byte at a time (not ideal for performance, obviously, but that's not a concern here). Here's the complete echo server, runnable as a boot script (`defclifn`, if you're not familiar with boot, is just a convenience macro for defining a function that accepts command-line flags):

``` clojure
#!/usr/bin/env boot

(require '[clojure.java.io :as io]
         '[boot.cli :refer [defclifn]])

(defn handle-connection [server-sock]
  (with-open [sock (.accept server-sock)
              in (.getInputStream sock)
              out (.getOutputStream sock)]
    (loop [b (.read in)]
      (when (> b -1) ; sentinel value for end of stream
        (.write out b)
        (recur (.read in))))))

(defclifn -main
  [p port VAL int "Port to echo on"]
  (println "Listening on port " port)
  (with-open [server-sock (java.net.ServerSocket. port)]
    (while true
      (handle-connection server-sock))))

```

Now I can use that to get the text of an HTTP request from curl:

``` bash
# An echo server is running on localhost:9123 using `./echo_server -p 9123`
 $ curl http://localhost:9123/whatever/whatever
 GET /whatever/whatever HTTP/1.1
 User-Agent: curl/7.37.1
 Host: localhost:9123
 
 
```

Since this is a GET request, it doesn't have a body. There is a request line (method, path and protocol) followed by a series of headers, which are key-value pairs. The request ends with two newlines. (My echo server isn't doing what curl expects from an HTTP server, so the curl invocation never actually exits, but that's okay.)

