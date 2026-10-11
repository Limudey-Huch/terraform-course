# תרגיל 001 — Variables + Locals

## מטרה
להבין את ההבדל בין `variable` (קלט מבחוץ) ל-`locals` (חישוב פנימי), ולראות איך שניהם מוזרמים ל-resource בפועל.

## מה יש בקובץ

שלושה `variable` עם `default` — אפשר להריץ ישר בלי לספק כלום:
```hcl
variable "instance_name" {
  type    = string
  default = "lab-001-instance"
}
```

ו-`locals` אחד שמחשב **מתוך** המשתנים:
```hcl
locals {
  environment = "lab"
  common_tags = {
    Name        = var.instance_name   # <- local קורא var
    Environment = local.environment   # <- local קורא local אחר
    ManagedBy   = "terraform"
  }
}
```

ה-resource עצמו לא מכיר שום ערך ישירות — הכל מגיע דרך `var.` או `local.`:
```hcl
resource "aws_instance" "example" {
  ami           = var.ami
  instance_type = var.instance_type
  tags          = local.common_tags
}
```

## המשימה

**שלב 1 — הרצה עם ברירות המחדל:**
```bash
terraform init
terraform apply
```
👀 בדקו בקונסולה את ה-tags של ה-instance — שלושתם אמורים להופיע (`Name`, `Environment`, `ManagedBy`).

**שלב 2 — שנו ערך דרך CLI, בלי לגעת בקוד:**
```bash
terraform apply -var="instance_name=my-custom-name"
```
👀 ה-tag `Name` אמור להשתנות, אבל `Environment`/`ManagedBy` נשארים אותו דבר — כי הם מחושבים מ-`local.environment` הקבוע, לא מהמשתנה ששיניתם.

**שלב 3 — תרגיל הרחבה:**
הוסיפו `variable` חדש בשם `owner` (עם default כלשהו), והוסיפו אותו כ-key נוסף בתוך `local.common_tags`. הריצו שוב ווודאו שה-tag החדש מופיע.

## שאלת הבנה
אם תרצו tag בשם `CreatedBy` עם הערך הקבוע `"terraform-course"` — האם הוא שייך ל-`variable` או ל-`locals`? למה?

## ניקוי
```bash
terraform destroy
```
