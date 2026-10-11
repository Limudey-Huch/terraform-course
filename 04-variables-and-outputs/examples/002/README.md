# תרגיל 002 — Outputs (והקשר חזרה ל-Variables)

## מטרה
להבין מה `output` בעצם עושה, ולראות ש-output יכול להחזיר לא רק attribute של משאב - גם ערך של variable, או שילוב של שניהם.

## מה חדש לעומת 001
אותו `main.tf` בדיוק (EC2 + variables + locals), ובנוסף קובץ [outputs.tf](outputs.tf) עם **4 outputs שונים**:

| Output | מקור הערך | מתי "נודע" |
|---|---|---|
| `instance_id` | `aws_instance.example.id` | רק אחרי `apply` (AWS מקצה) |
| `instance_public_ip` | `aws_instance.example.public_ip` | רק אחרי `apply` (AWS מקצה) |
| `instance_name_tag` | `var.instance_name` | **כבר לפני** `apply` - זה בסך הכל input שלכם |
| `summary` | שילוב `var` + `aws_instance...` יחד ב-string אחד | רק אחרי `apply` (כי הוא תלוי ב-IP) |

💡 **הנקודה המרכזית**: `output` לא "שמור" רק למה שה-AWS מחזיר. אפשר להחזיר דרכו גם את הקלט (`var`) עצמו - שימושי כשרוצים "סיכום" אחד שמשלב קלט ופלט יחד (כמו ב-`summary`).

## המשימה

```bash
terraform init
terraform apply
```
👀 בסוף ה-apply, Terraform מדפיס את כל ה-outputs אוטומטית. שימו לב ש-`instance_name_tag` מופיע **מיד**, אבל `instance_public_ip` ו-`summary` מחכים לסיום היצירה בפועל.

**לבדוק outputs בכל רגע (לא רק מיד אחרי apply):**
```bash
terraform output
terraform output instance_public_ip   # output בודד
terraform output -json                # לקבל JSON - שימושי לסקריפטים
```

## לאן זה מוביל (preview למודול 06)

outputs הם בדיוק המנגנון שמאפשר ל-**config אחר** (למשל מודול נפרד) "לקרוא" ערכים מה-config הזה - בלי לגשת ישירות ל-state. זה נקרא `terraform_remote_state` data source, ונעמיק בזה במודול 06 (מודולים). הרעיון הבסיסי:

```hcl
# בקונפיג אחר, לגמרי נפרד:
data "terraform_remote_state" "lab002" {
  backend = "s3"
  config = {
    bucket = "REPLACE-WITH-YOUR-BUCKET-NAME"
    key    = "04-variables-and-outputs/examples/002/terraform.tfstate"
    region = "eu-north-1"
  }
}

# ואז אפשר להשתמש בזה כאילו זה var:
resource "aws_instance" "another" {
  # ...
  tags = {
    SourceInstance = data.terraform_remote_state.lab002.outputs.instance_id
  }
}
```
זה בדיוק "ה-outputs הופכים לקלט (כמו var) לקונפיג הבא" — התשובה לשאלה "מה עושים עם output אחרי שיש לי אותו".

## ניקוי
```bash
terraform destroy
```
