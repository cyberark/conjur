# NOTE: Once spec_helper is properly refactored and disentangled, this could be
# moved into there.  But currently, we want to have this available on the load
# paths for specs which *cannot* include spec_helper, because spec_helper has
# too much cruft from non-global use cases.
#
$LOAD_PATH << File.expand_path('../../app/domain', __FILE__)
$LOAD_PATH << File.expand_path('../../app', __FILE__)
