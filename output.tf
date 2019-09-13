output "instance_ip" {
  value = "${google_compute_address.static.address}"
}

output "database_ip" {
  value = "${google_sql_database_instance.instance.ip_address.0.ip_address}"
}



