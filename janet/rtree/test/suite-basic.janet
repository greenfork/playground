(use spork/test)
(import spork/http)
(import spork/json)
(import ../main :as r)
(import ../json :as r :only [json])

(start-suite)

(defn my-app [req]
  (r/route
    (r/is "/basic-full"
      "/basic-full path")

    (r/is "no-slash"
      "/no-slash path")
    (r/is "/double/slash"
      "/double/slash path")
    (r/is ["double" "array"]
      "/double/array path")

    (r/on "partial"
      (r/on "continue-partial"
        "/partial/continue-partial path")
      "/partial path")

    (r/on ["/partial-array"]
      (r/is "/continue-full"
        "/partial-array/continue-full path"))

    # Captures
    (r/is ["string" :string] str
      (string/format "The string is %s!" str))
    (r/on "string2"
      (r/is :string str
        (string/format "The string is %s!" str)))
    (r/on "string3"
      (r/GET :string str
        (string/format "The string is %s!" str)))
    (r/is ["number" :number] n
      (string/format "The number is %d!" n))
    (r/is ["date" :number :number :number] year month day
      (string/format "The date is %04d-%02d-%02d!" year month day))
    (r/on "multi"
      (r/on :string level
        (r/on "capture"
          (string/format "/multi/%s/capture path" level))))

    (r/is "/get-or-post"
      "/get-or-post path")
    (r/GET "/only-get"
      "/only-get path")
    (r/POST "/only-post"
      "/only-post path")

    (def params (r/params))
    (r/GET "/get-query-param"
      (string/format "Got param q: %s" (params :q)))
    (r/POST "/post-form-param"
      (string/format "Got param form: %s" (params :form)))
    (r/POST "post-param-override"
      (string/format "Got param 'q' from form: %s" (params :q)))

    (r/is "redirect"
      (r/redirect))

    (r/is "json"
      (r/json {:key 42}))

    (defn nested-route []
      (r/is "fun"
        "/nested/fun path"))
    (r/on "nested"
      (nested-route)
      ((fn []
         (r/is "lambda"
           "/nested/lambda path"))))))

(def server (r/run-app my-app :host "127.0.0.1" :port 9816))
(defn GET [path] (http/request "GET" (string "http://127.0.0.1:9816" path)))
(defn POST [path &opt body]
  (def headers (when body
                 @{"Content-Type" "x-www-form-urlencoded"}))
  (http/request "POST" (string "http://127.0.0.1:9816" path) :body body :headers headers))

# Basic
(let [{:status status :body body} (GET "/basic-full")]
  (assert (= status 200))
  (assert (= (memcmp body "/basic-full path") 0)))
(let [{:status status :body body} (GET "/no-slash")]
  (assert (= status 200))
  (assert (= (memcmp body "/no-slash path") 0)))
(let [{:status status :body body} (GET "/double/slash")]
  (assert (= status 200))
  (assert (= (memcmp body "/double/slash path") 0)))
(let [{:status status :body body} (GET "/double/array")]
  (assert (= status 200))
  (assert (= (memcmp body "/double/array path") 0)))
(let [{:status status} (GET "/unknown")]
  (assert (= status 404)))
(let [{:status status} (POST "/unknown")]
  (assert (= status 404)))

# Partial match
(let [{:status status :body body} (GET "/partial")]
  (assert (= status 200))
  (assert (= (memcmp body "/partial path") 0)))
(let [{:status status :body body} (GET "/partial/continue-partial")]
  (assert (= status 200))
  (assert (= (memcmp body "/partial/continue-partial path") 0)))
(let [{:status status} (GET "/partial-array")]
  (assert (= status 404)))
(let [{:status status :body body} (GET "/partial-array/continue-full")]
  (assert (= status 200))
  (assert (= (memcmp body "/partial-array/continue-full path") 0)))

# Captures
(let [{:status status :body body} (GET "/string/my-string")]
  (assert (= status 200))
  (assert (= (memcmp body "The string is my-string!") 0)))
(let [{:status status :body body} (GET "/string2/my-string2")]
  (assert (= status 200))
  (assert (= (memcmp body "The string is my-string2!") 0)))
(let [{:status status :body body} (GET "/string3/my-string3")]
  (assert (= status 200))
  (assert (= (memcmp body "The string is my-string3!") 0)))
(let [{:status status :body body} (GET "/number/my-string")]
  (assert (= status 404)))
(let [{:status status :body body} (GET "/number/42")]
  (assert (= status 200))
  (assert (= (memcmp body "The number is 42!") 0)))
(let [{:status status :body body} (GET "/date/2026/8/2")]
  (assert (= status 200))
  (assert (= (memcmp body "The date is 2026-08-02!") 0)))
(let [{:status status :body body} (GET "/multi/level/capture")]
  (assert (= status 200))
  (assert (= (memcmp body "/multi/level/capture path") 0)))

# GET and POST
(let [{:status status :body body} (GET "/get-or-post")]
  (assert (= status 200))
  (assert (= (memcmp body "/get-or-post path") 0)))
(let [{:status status :body body} (POST "/get-or-post")]
  (assert (= status 200))
  (assert (= (memcmp body "/get-or-post path") 0)))
(let [{:status status :body body} (GET "/only-get")]
  (assert (= status 200))
  (assert (= (memcmp body "/only-get path") 0)))
(let [{:status status :body body} (POST "/only-get")]
  (assert (= status 404)))
(let [{:status status :body body} (POST "/only-post")]
  (assert (= status 200))
  (assert (= (memcmp body "/only-post path") 0)))
(let [{:status status :body body} (GET "/only-post")]
  (assert (= status 404)))

# Params
(let [{:status status :body body} (GET "/get-query-param?q=1")]
  (assert (= status 200))
  (assert (= (memcmp body "Got param q: 1") 0)))
(let [{:status status :body body} (POST "/post-form-param" "form=2")]
  (assert (= status 200))
  (assert (= (memcmp body "Got param form: 2") 0)))
(let [{:status status :body body} (POST "/post-param-override?q=1" "q=2")]
  (assert (= status 200))
  (assert (= (memcmp body "Got param 'q' from form: 2") 0)))

# Redirect
(let [{:status status :headers {"location" location}} (POST "/redirect")]
  (assert (= status 303))
  (assert (= (memcmp location "/redirect") 0)))

# JSON
(let [{:status status :body body :headers headers} (GET "/json")
      body (json/decode body)]
  (assert (= status 200))
  (assert (= (body "key") 42))
  (assert (= (memcmp (headers "content-type") "application/json") 0)))

# Nested functions and lambdas
(let [{:status status :body body} (GET "/nested/fun")]
  (assert (= status 200))
  (assert (= (memcmp body "/nested/fun path") 0)))
(let [{:status status :body body} (GET "/nested/lambda")]
  (assert (= status 200))
  (assert (= (memcmp body "/nested/lambda path") 0)))

(:close server)
(end-suite)
