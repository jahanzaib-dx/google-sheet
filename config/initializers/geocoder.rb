Geocoder.configure(

  #geocoding service (Look at https://github.com/alexreisner/geocoder
  #:lookup => :mapquest,

  # API KEY
  # mapquest
  #:api_key => "Fmjtd%7Cluub2061nd%2Cb2%3Do5-9ubggw",
  #nestor's google
  #:api_key => "AIzaSyBTg4OMVQSiZlpSvc8mVwdFRPAarF_RdRU"

  # default units
  #:units => :km,
  
  # caching (See github page for documentation)
  #:cache => Redis.new,
  :cache_prefix => "marketrex_geocoding"

)
