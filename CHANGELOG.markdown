# 1.0.5.pre

* Removing duplicate Enviornment#unicorn? method 
* Removing logging when not instrumenting unscoped method (confusing - looks like an error)
* Recording ActiveRecord exists queries as MODEL#exists vs. SQL#UNKNOWN
* Handling log_level config option and defaulting to 'info' instead of 'debug'
* Not crashing the app when log file isn't writeable
* Handling the :reset directive. Resets the metric_lookup when provided.

# 1.0.4

* Added Mongo + Moped instrumentation. Mongo is used for Mongoid < 3.
* Proxy support

# 1.0.3

* MetricMeta equality - downcase
* Suppressing "cat: /proc/cpuinfo: No such file or directory" error on distros that don't support it.

# 1.0.2

* Net::HTTP instrumentation
* ActionController::Metal instrumentation
* Determining number of processors for CPU % calculation

# 1.0.1

* Unicorn support (requires "preload_app true" in unicorn config file)
* Fix for Thin detection - ensure it's actually running
* Fixing name conflict btw Tracer#store and ActiveRecord::Store

# 1.0.0

* Release!

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

* Doesn't prevent app from loading if no configuration exists for the current environment.

# 0.0.1

* Boom! Initial Release.