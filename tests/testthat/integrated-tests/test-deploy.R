context("deploy")

# should connect with env vars
test_conn_1 <- connect(host = Sys.getenv("TEST_SERVER_1"), api_key = Sys.getenv("TEST_KEY_1"))
test_conn_2 <- connect(host = Sys.getenv("TEST_SERVER_2"), api_key = Sys.getenv("TEST_KEY_2"))

cont1_name <- uuid::UUIDgenerate()
cont1_title <- "Test Content 1"
cont1_guid <- NULL
cont1_bundle <- NULL
cont1_content <- NULL

test_that("bundle_dir deploys", {
  dir_path <- rprojroot::find_testthat_root_file("examples/static")
  tmp_file <- fs::file_temp(pattern = "bundle", ext = ".tar.gz")
  bund <- bundle_dir(path = dir_path, filename = tmp_file)
  
  expect_equal(tmp_file, bund$path)
  
  # with a name / title
  tsk <- deploy(connect = test_conn_1, bundle = bund, name = cont1_name, title = cont1_title)
  
  cont1_guid <<- tsk$get_content()$guid
  cont1_content <<- tsk
  
  # how should we test that deployment happened?
  expect_true(validate_R6_class("Content", tsk))
  expect_equal(tsk$get_content()$name, cont1_name)
  expect_equal(tsk$get_content()$title, cont1_title)
  
  expect_true(validate_R6_class("Task", tsk))
  expect_gt(nchar(tsk$get_task()$task_id), 0)
  
  # with a guid
  tsk2 <- deploy(connect = test_conn_1, bundle = bund, guid = cont1_guid)
  expect_true(validate_R6_class("Content", tsk2))
  expect_equal(tsk2$get_content()$name, cont1_name)
  expect_equal(tsk2$get_content()$title, cont1_title)
  expect_equal(tsk2$get_content()$guid, cont1_guid)
})

test_that("content_item works", {
  cont1_tmp <- test_conn_1 %>% content_item(guid = cont1_guid)
  
  expect_true(validate_R6_class("Content", cont1_tmp))
  expect_equal(cont1_tmp$get_content()$guid, cont1_guid)
})

test_that("bundle_path deploys", {
  tar_path <- rprojroot::find_testthat_root_file("examples/static.tar.gz")
  bund <- bundle_path(path = tar_path)
  
  expect_equal(tar_path, as.character(bund$path))
  
  # deploy to a new endpoint
  tsk <- deploy(connect = test_conn_1, bundle = bund)
  
  # how should we test that deployment happened?
  expect_true(validate_R6_class("Content", tsk))
})

test_that("set_image_path works", {
  scoped_experimental_silence()
  img_path <- rprojroot::find_testthat_root_file("examples/logo.png")
  
  res <- set_image_path(cont1_content, img_path)
  
  expect_true(validate_R6_class("Content", res))
})

test_that("get_image works", {
  scoped_experimental_silence()
  img_path <- rprojroot::find_testthat_root_file("examples/logo.png")
  
  tmp_img <- fs::file_temp(pattern = "img", ext = ".png")
  get_image(cont1_content, tmp_img)
  
  expect_identical(
    readBin(img_path, "raw"),
    readBin(tmp_img, "raw")
  )
  
  # works again (i.e. does not append data)
  get_image(cont1_content, tmp_img)
  expect_identical(
    readBin(img_path, "raw"),
    readBin(tmp_img, "raw")
  )
  
  # works with no path
  auto_path <- get_image(cont1_content)
  expect_identical(
    readBin(img_path, "raw"),
    readBin(auto_path, "raw")
  )
  expect_identical(fs::path_ext(auto_path), "png")
  
})

test_that("has_image works with an image", {
  scoped_experimental_silence()
  
  expect_true(has_image(cont1_content))
})

test_that("delete_image works", {
  scoped_experimental_silence()
  # from above
  img_path <- rprojroot::find_testthat_root_file("examples/logo.png")
  
  tmp_img <- fs::file_temp(pattern = "img", ext = ".png")
  # retains the image at the path
  expect_false(fs::file_exists(tmp_img))
  expect_true(validate_R6_class("Content", delete_image(cont1_content, tmp_img)))
  expect_true(fs::file_exists(tmp_img))
  expect_identical(
    readBin(img_path, "raw"),
    readBin(tmp_img, "raw")
  )
  expect_false(has_image(cont1_content))
  
  # works again - i.e. if no image available
  expect_true(validate_R6_class("Content", delete_image(cont1_content)))
})

test_that("has_image works with no image", {
  scoped_experimental_silence()
  
  expect_false(has_image(cont1_content))
})

test_that("get_image returns NA if no image", {
  scoped_experimental_silence()
  
  tmp_img <- fs::file_temp(pattern = "img", ext = ".png")
  response <- get_image(cont1_content, tmp_img)
  
  expect_false(identical(tmp_img, response))
  expect_true(is.na(response))
})

test_that("set_image_url works", {
  # need to find a reliable image URL that is small
  skip("not implemented yet")
})

test_that("set_image_webshot works", {
  scoped_experimental_silence()
  res <- set_image_webshot(cont1_content)
  
  expect_true(validate_R6_class("Content", res))
})

test_that("set_vanity_url works", {
  scoped_experimental_silence()
  res <- set_vanity_url(cont1_content, cont1_name)
  
  expect_true(validate_R6_class("Vanity", res))
  expect_equal(res$get_vanity()$path_prefix, paste0("/", cont1_name, "/"))
  
  res2 <- set_vanity_url(cont1_content, paste0(cont1_name,"update"))
  expect_true(validate_R6_class("Vanity", res2))
  expect_equal(res2$get_vanity()$path_prefix, paste0("/", cont1_name, "update/"))
})


test_that("get_vanity_url works", {
  scoped_experimental_silence()
  tmp_content_name <- uuid::UUIDgenerate()
  tmp_content_prep <- content_ensure(test_conn_1, name = tmp_content_name)
  tmp_content <- Content$new(connect = test_conn_1, content = tmp_content_prep)
    
  # without a vanity
  curr_vanity <- get_vanity_url(tmp_content)
  expect_true(validate_R6_class("Content", curr_vanity))
  expect_error(validate_R6_class("Vanity", curr_vanity), regexp = "R6 Vanity")
  
  # with a vanity
  res <- set_vanity_url(tmp_content, tmp_content_name)
  existing_vanity <- get_vanity_url(tmp_content)
  expect_true(validate_R6_class("Vanity", existing_vanity))
  expect_equal(existing_vanity$get_vanity()$path_prefix, paste0("/", tmp_content_name, "/"))
})


test_that("poll_task works and returns its input", {
  expect_message(
    res <- poll_task(cont1_content)
  )
  expect_equal(res, cont1_content)
})

test_that("download_bundle works", {
  bnd <- download_bundle(content_item(test_conn_1, cont1_guid))
  
  expect_true(validate_R6_class("Bundle", bnd))
})

test_that("download_bundle throws an error for undeployed content", {
  cont_prep <- content_ensure(test_conn_1)
  cont <- content_item(test_conn_1, cont_prep$guid)
  
  expect_error(
    download_bundle(cont),
    "This content has no bundle_id"
  )
})
