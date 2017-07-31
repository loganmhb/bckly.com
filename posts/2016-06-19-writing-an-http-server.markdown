---
title: Writing a toy HTTP Server in Clojure
date: June 19, 2016
layout: post
category: code
---

_The code for this post can be found [on Github][weasel]._

Though I use them all the time, I don't really understand how HTTP web servers work. That must mean, obviously, it's time to write one!

# Beginnings

The [HTTP spec][httpspec] isn't completely impenetrable, but it's too much to implement in a first pass at a web server. At first, I just want to be able to respond to a minimal GET request and serve a file back. So step one is, what does a minimal GET request look like? I could google this but there's another, more fun way to do it.

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

For a completely minimal implementation, I could ignore the headers, as they're not required -- you can see this if you telnet to google.com on port 80 and type "GET / <enter> <enter>". But I want to be able to curl my web server, so that means it has to handle the headers that curl includes by default.

# Instaparse

[Instaparse][insta] is a delightful Clojure parser that answers the question, "What if context-free grammars were as easy to use as regular expressions?" Answer: writing parsers is suddenly a lot more fun! If you haven't tried Instaparse you should give it a shot -- the tutorial on its Github page is excellent, and it's a joy to use.

In order to use Instaparse to parse an HTTP request, I need to define a grammar in Backus-Naur form. (The angle brackets are a convenience Instaparse provides to exclude certain tags from the parse tree -- spaces are important for defining the structure of the request, but once I have the parse tree I don't care about the spaces anymore. Instaparse makes this and many other common parsing problems simple.)

This grammar is extremely minimal, but it will get through the first request.

``` ebnf
request = request-line headers

<request-line> = method <sp> path <sp> [protocol] <crlf>
method = "GET"                               (* incomplete *)
path =  #"[/.~a-zA-Z0-9\-?&%]+"
protocol = "HTTP/1.1"
crlf = "\r\n"
sp = " "

headers = header* <crlf>
header = name <": "> val <crlf>
<name> = #"[^\:]*"
<val> = #"[^\r]*"
```

With this grammar saved in a file "minimal.ebnf" on the classpath, it can be invoked like this:

``` clojure
(require '[clojure.java.io :as io]
         '[instaparse.core :as insta])

(def minimal-parser (insta/parser (io/resource "minimal.ebnf")))

(minimal-parser "GET / HTTP/1.1\r\nAccept: text/html\r\n\r\n")
;=> [:request [:method "GET"] [:path "/"] [:protocol "HTTP/1.1"] [:headers [:header "Accept" "text/html"]]]

```

Great. For now, all I want to return for a "GET /" request is a page that says "Hello, world!" inside an HTML header element. For any other path I'd like to return a 404 page.

What does an HTTP response look like? Let's find out.

(In the course of composing this example I learned that Host is a required header in HTTP/1.1. Some servers will let you get away with leaving it off, but example.com's returns a 400 Bad Request.)

``` bash
 $ telnet example.com 80
 GET /index.html HTTP/1.1
 Host: example.com

 HTTP/1.1 200 OK
 Cache-Control: max-age=604800
 Content-Type: text/html
 Date: Sat, 18 Jun 2016 20:24:04 GMT
 Etag: "359670651+gzip+ident"
 Expires: Sat, 25 Jun 2016 20:24:04 GMT
 Last-Modified: Fri, 09 Aug 2013 23:54:35 GMT
 Server: ECS (lga/1384)
 Vary: Accept-Encoding
 X-Cache: HIT
 x-ec-custom-error: 1
 Content-Length: 1270

 <html snipped here>
```

How about a 404?

``` bash
$ telnet example.com 80
GET /badpage HTTP/1.1
Host: example.com

HTTP/1.1 404 Not Found
Cache-Control: max-age=604800
Content-Type: text/html
Date: Sat, 18 Jun 2016 20:27:31 GMT
Etag: "359670651+gzip+ident"
Expires: Sat, 25 Jun 2016 20:27:31 GMT
Last-Modified: Fri, 09 Aug 2013 23:54:35 GMT
Server: ECS (ewr/1445)
Vary: Accept-Encoding
X-Cache: HIT
x-ec-custom-error: 1
Content-Length: 1270

<!doctype html ...(snipped)>
```

So the format seems to be protocol, status code, status code text on the first line followed by headers. (This can be confirmed by reading the HTTP spec, of course.) Poking around on the Internet seems to indicate that Date is a required header, and Content-Type and Content-Length should go one as well. Server is an easy one so I'll include that too.

Before I hook up my HTTP parser to a TCP socket's input stream, there's a small problem. Because Instaparse supports regular expressions as part of its grammar definitions and regular expressions are greedy, it only supports operating on strings, not byte streams. So in order to parse the request with Instaparse I'll have to first pull off the request line and headers as a string. Fortunately, a basic implementation of this just has to look for two carriage return-line feed sequences in a row. I used a little state machine for this:

``` clojure
(defn transition-state
  [current-state next-char]
  (let [expect-char (fn [c succ-state]
                      (if (= next-char c) succ-state :start))]
    (case current-state
      :start (expect-char \return :first-return)
      :first-return (expect-char \newline :first-newline)
      :first-newline (expect-char \return :second-return)
      :second-return (expect-char \newline :success)
      :start)))

(defn read-http-request
  ([^InputStream stream] (read-http-request stream :start ""))
  ([^InputStream stream state request]
   (let [next-char (char (.read stream))
         new-state (transition-state state next-char)
         req-with-char (str request next-char)]
     (if (= new-state :success)
       req-with-char
       (recur stream new-state req-with-char)))))
```

Note that `read-http-request` does not close the input stream. If the server supports persistent connections or requests with bodies, the stream will need to stay open for those.

# Instaparse transforms

With this helper written, I should be able to hook my parser up to an actual TCP socket. Before I do that, I want to take advantage of another feature of Instaparse to make it just a little easier to extract the path from the request. Instead of a tree like this:

``` clojure
[:request [:method "GET"] [:path "/"] [:protocol "HTTP/1.1"] [:headers [:header "Accept" "text/html"]]
```

I'd like to get a map like this:

``` clojure
{:method "GET",
 :path "/",
 :headers {"Accept" "text/html"},
 :protocol "HTTP/1.1"}
```

Instaparse provides a facility for doing this using a map of tags to functions that will be applied to those tags' tree nodes. It looks like this:

``` clojure
(def transforms
   ;; format each header as a map entry
  {:header (fn [& args] (vec args))
   ;; accumulate header kv pairs into a map
   :headers (fn [& args] [:headers (into {} args)])
   ;; accumulate each child of :request (now in kv pair form) into a map
   :request (fn [& args] (into {} args))})

(def parser (insta/parser (io/resource "minimal.ebnf")))

(defn parse-http-request [req]
  (insta/transform transforms
                   (parser req)))

(parse-http-request "GET / HTTP/1.1\r\nAccept: text/html\r\n\r\n")
;;=>{:method "GET", :path "/", :protocol "HTTP/1.1", :headers {"Accept" "text/html"}}
```

That's all it takes! Time to write an HTTP handler. I want to be able to extend this, so I'm going to model it off of Ring, with the handler itself being a function that takes a request map and returns a response map. I'll wrap that in logic to parse the request and write out the response:

``` clojure
(defn handler
  "Ring-style. Takes a request map and returns a response map."
  [request]
  (let [ok-body "<h1>Hello, world!</h1>"
        not-found-body "<h1>Not found :(</h1>"
        base-headers {"Date" (tfmt/unparse (:rfc822 tfmt/formatters)
                                           (time/now))
                      "Server" "Weasel 0.1.0"
                      "Content-Type" "text/html"}]
    (if (= "/" (:path request))
      {:status 200
       :protocol (:protocol request)
       :headers (merge base-headers {"Content-Length" (count ok-body)})
       :body ok-body}
      {:status 404
       :protocol (:protocol request)
       :headers (merge base-headers {"Content-Length" (count not-found-body)})
       :body not-found-body})))

;; Formatters

(defn format-response-line [resp]
  (let [status-msgs {200 "OK"
                     404 "Not Found"}]
    (str (:protocol resp) " "
         (:status resp) " "
         (status-msgs (:status resp)) "\r\n")))

(defn format-headers [headers]
  (apply str
         (for [[k v] headers]
           (str k ": " v "\r\n"))))

(defn format-response [resp]
  (str (format-response-line resp)
       (format-headers (:headers resp))
       "\r\n"
       (:body resp)))

;; Socket handler and server socket handler to tie it all together

(defn handle-http-client
  [^Socket client-sock]
  (try
    (let [request (read-http-request (.getInputStream client-sock))
          response (-> request
                       parse-request
                       handler
                       format-response)
      (with-open [output (io/writer client-sock)]
        (.write output response)
        (.flush output)))
    (finally (.close client-sock))))


(defn start-server
  "Starts a TCP server on the given port.
  Uses `client-handler' to process incoming connections. Returns a
  function that will stop the server after the next connection."
  [port client-handler]
  (let [run (atom true)]
    ;; have to wrap the future body in a try to avoid silent failures
    (future (try (with-open [server-socket (ServerSocket. port)]
                   (while @run
                     (client-handler (.accept server-socket))))
                 (catch Throwable e
                   (println "Problem!" e))))
    (fn [] (reset! run false))))
```

It works!

![hello world][hello]

There are still a few important things to do, of course. There's no provision for handling bad requests, and if there's an error server side there's no provision for a 500 error. And of course it would be nice to serve more than just a hello world file at /. More, perhaps, in a second post.

[hello]: /img/hello-world.png
[httpspec]: https://www.w3.org/Protocols/rfc2616/rfc2616.txt
[insta]: https://github.com/Engelberg/instaparse
[weasel]: https://github.com/loganmhb/weasel
