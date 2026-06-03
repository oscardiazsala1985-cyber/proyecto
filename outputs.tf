output "api_process_url" {
  description = "Public HTTP API endpoint for POST /process."
  value       = "${aws_apigatewayv2_api.http.api_endpoint}/process"
}

output "results_bucket_name" {
  description = "Private S3 bucket where Lambda stores processed results."
  value       = aws_s3_bucket.results.bucket
}

output "redis_endpoint" {
  description = "Private Redis endpoint."
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}
