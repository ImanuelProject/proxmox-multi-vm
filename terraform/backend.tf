terraform {
  backend "pg" {
    conn_str = "postgres://postgres:postgres@localhost:5432/terraform_backend?sslmode=disable"
  }
}
