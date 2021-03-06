# connectapi 0.1.0.9001

BREAKING: 
* Rename a handful of functions:
  - `connect$activate_bundle` to `connect$content_deploy`
  - `connect$create_app` to `connect$content_create`
  - `connect$upload_bundle` to `connect$content_upload`
  - `connect$get_users` to `connect$users`
* Change some return types to be consistent with the API
  - `connect$content_upload` returns the response instead of `bundle_id`
  - `connect$content_deploy` returns the response instead of `task_id`
* Switch endpoints from using `app_id` to `guid`
* `get_task$start` renamed to `get_task$first`
* `promote$app_name` renamed to `promote$name`
* rename the package to `connectapi`
* change functions to take a `Connect` object instead of server / api key
  - `cache_apps`
  - `tag_page`

OTHER: 
* Add some endpoints:
  - `content`
  - `audit_logs`
  - `server_settings`
  - `server_settings_r`
  - `inst_shiny_usage`
  - `inst_content_visits`
* Add some helper functions:
  - `deploy_github`, `download_github`
  - `swap_vanity_url`, deployment functions
  - `browse_` family of functions
* Update `connect` R6 object to be compatible with Connect 1.7.0+ APIs
* Added a `NEWS.md` file to track changes to the package.
* Add integration testing to protect against regressions
* Add `tbl_connect()` as a `lazy_tbl` for querying Connect API endpoints
