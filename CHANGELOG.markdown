# 0.0.6.pre

* Rails 2 - Not collecting traces when an exception occurs
* Increased Transaction Sample Storage to 2 seconds from 1 second to decrease noise in UI

# 0.0.5

* Support for custom categories
* Not raising an exception w/an unbalanced stack
* Only allows controllers as the entry point for a transaction

# 0.0.4

* Transaction Sampling

# 0.0.3.pre

* Removed dynamic ActiveRecord caller instrumentation
* Fixed issue that prevents the app from loading if ActiveRecord isn't used.
* Using a metric hash for each request, then merging when complete. Ensures data associated w/requests that overlap a 
  minute boundary are correctly associated.

# 0.0.2

Doesn't prevent app from loading if no configuration exists for the current environment.

# 0.0.1

Boom! Initial Release.