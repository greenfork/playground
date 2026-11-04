(import spork/http)
(import ../main :as r)
(import ../json :as r :only [json])
(import ../public :as r :only [public])

(defn my-app [req]
  (r/route
    (r/public)

    (r/is "/me/mi"
          "/me/mi")
    (r/is ["me" "arr"]
          "/me/arr")
    (r/is "mo"
          "/mo")

    (r/is ["date" :number :number :number] year month day
          (string/format "Date is %04d-%02d-%02d" year month day))
    (r/is ["number" :number] n
          (string/format "The number is %d!" n))

    (r/on "me"
          (r/on "mo"
                "/me/mo")
          "/me")

    (r/on ["/arr"]
          (r/is "/ma"
                "/arr/ma"))

    (def params (r/params))
    (r/is "get-query-param"
          (string/format "Got param %s: %s" :q (params :q)))

    (r/is "redirect"
          (r/redirect))

    (r/is "json"
          (r/json {:key "value"}))))

(r/run-app my-app :middlewares [http/logger])
