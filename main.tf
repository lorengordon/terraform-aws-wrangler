module "file_cache" {
  source = "git::https://github.com/plus3it/terraform-external-file-cache.git?ref=2.0.2"

  python_cmd = var.python_cmd
  uris       = keys(var.uri_map)
}

resource "aws_s3_bucket_object" "file" {
  # Construct a resource id that represents the bucket and key
  for_each = { for uri, key in var.uri_map : "s3://${var.bucket_name}/${var.prefix}${key}${basename(uri)}" => uri }

  bucket = var.bucket_name
  key    = local.uri_objects[each.value].key
  source = module.file_cache.filepaths[each.value]
  etag   = filemd5(module.file_cache.filepaths[each.value])
}

resource "aws_s3_bucket_object" "hash" {
  # Construct a resource id that represents the bucket and key
  for_each = var.create_hashes ? { for uri, key in var.uri_map : "s3://${var.bucket_name}/${var.prefix}${key}${basename(uri)}.SHA512" => uri } : {}

  bucket       = var.bucket_name
  key          = "${local.uri_objects[each.value].key}.SHA512"
  content      = local.uri_objects[each.value].hash_content
  content_type = "application/octet-stream"
  etag         = md5(local.uri_objects[each.value].hash_content)
}

locals {
  uri_objects = {
    for uri, filepath in module.file_cache.filepaths : uri => {
      key          = "${var.prefix}${var.uri_map[uri]}${basename(filepath)}"
      hash_content = "${filesha512(filepath)} ${basename(filepath)}"
    }
  }
}
