# deploy the current_bundle
deploy_current <- function(content) {
  res <- content$get_connect()$POST(glue::glue("v1/experimental/content/{content$get_content()$guid}/deploy"), body = list(bundle_id = content$get_content()$bundle_id))
  return(Task$new(connect = content$get_connect(), content = content$get_content(), task = res$task_id))
}

# ACLs ----------------------------------------------------

# TODO: How should we behave if this content is open to the server / world?
get_acl <- function(content) {
  warn_experimental("get_acl")
  client <- content$get_connect()
  res <- client$GET(glue::glue("applications/{content$get_content()$guid}"))
  
  owner <- client$user(res$owner_guid)
  owner$app_role <- "owner"
  return(c(list(owner), res[["users"]]))
}

acl_add_self <- function(content) {
  acl_add_collaborator(content, content$get_connect()$GET("me")$guid)
}

acl_add_user <- function(content, user_guid, role) {
  warn_experimental("acl_add")
  res <- content$get_connect()$POST(
    glue::glue("applications/{content$get_content()$guid}/users"),
    body = list(
      app_role = role,
      guid = user_guid
    )
  )
  return(content)
}

acl_add_collaborator <- function(content, user_guid) {
  acl_add_user(content = content, user_guid = user_guid, role = "owner")
}

# TODO: Should this be a warning if the user is a collaborator? Will downgrade their permissions
# TODO: How should this behave if the content does not have access_type: acl?
acl_add_viewer <- function(content, user_guid) {
  acl_add_user(content = content, user_guid = user_guid, role = "viewer")
}

acl_remove_user <- function(content, user_guid) {
  warn_experimental("acl_remove")
  res <- content$get_connect()$DELETE(
    glue::glue("applications/{content$get_content()$guid}/users/{user_guid}")
  )
  return(content)
}

acl_remove_collaborator <- acl_remove_user

acl_remove_viewer <- acl_remove_user

acl_remove_self <- function(content) {
  acl_remove_user(content, content$get_connect()$GET('me')$guid)
}

acl_user_role <- function(content, user_guid) {
  warn_experimental("acl_user_role")
  scoped_experimental_silence()
  acls <- get_acl(content)
  if (is.null(user_guid) || is.na(user_guid)) return(NULL)
  user_entry <- purrr::flatten(purrr::keep(acls, ~ .x$guid == user_guid))
  
  return(user_entry$app_role)
}
