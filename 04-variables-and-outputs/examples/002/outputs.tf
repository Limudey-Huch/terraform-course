# --- Output שמציג attribute של משאב - ערך שנודע רק אחרי apply ---
output "instance_id" {
  description = "ה-ID של ה-instance שנוצר"
  value       = aws_instance.example.id
}

output "instance_public_ip" {
  description = "כתובת ה-IP הציבורית - AWS מקצה אותה, אי אפשר לדעת מראש"
  value       = aws_instance.example.public_ip
}

# --- Output שפשוט "מהדהד" ערך של variable - נודע כבר לפני apply ---
output "instance_name_tag" {
  description = "מראה ש-output יכול להחזיר גם ערך של var, לא רק attribute של resource"
  value       = var.instance_name
}

# --- Output ששילוב של var + attribute יחד, בתוך string interpolation ---
output "summary" {
  description = "שילוב של variable (ידוע מראש) + resource attribute (ידוע רק אחרי apply)"
  value       = "Instance '${var.instance_name}' (${var.instance_type}) is running at ${aws_instance.example.public_ip}"
}
