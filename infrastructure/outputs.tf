output "public_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.unque-sssignment.public_ip
}

output "docdb_mongo_uri" {
  description = "The MongoDB connection URI for Amazon DocumentDB"
  value       = "mongodb://${aws_docdb_cluster.unque-docdb.master_username}:${aws_docdb_cluster.unque-docdb.master_password}@${aws_docdb_cluster.unque-docdb.endpoint}:27017/?tls=true&tlsCAFile=global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
  sensitive   = true
}
