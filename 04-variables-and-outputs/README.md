# Variables and Outputs — הסבר

## הבעיה שמשתנים פותרים

בלי variables, כל ערך (AMI, סוג מכונה, סיסמה, דומיין) חייב להיות כתוב ישירות בקוד. המשמעות: אי אפשר להשתמש באותו קוד לכמה סביבות (dev/prod) בלי להעתיק ולערוך ידנית, ודברים רגישים (סיסמאות) נחשפים בקוד שנשמר ב-git. ה-web-app מ-`03-basics` עם `password = "foobarbaz"` כתוב בגלוי הוא בדיוק הבעיה הזו.

## `variable` — קלט חיצוני

```hcl
variable "ami" {
  type    = string
  default = "ami-01637463b2cbe7cb6" # יש default — לא חובה לספק ערך
}

variable "db_pass" {
  type      = string
  sensitive = true # אין default — Terraform יחייב לספק ערך, ויסתיר אותו בפלט
}
```
בקוד משתמשים ב-`var.<name>` במקום לכתוב את הערך ישירות.

## איך מעבירים ערכים (לפי סדר עדיפות)

1. `-var` ב-CLI: `terraform apply -var="db_pass=$DB_PASS"`
2. קובץ `terraform.tfvars` — נטען **אוטומטית**
3. קובץ `.tfvars` מפורש: `-var-file=prod.tfvars`
4. Prompt אינטראקטיבי — אם אין default ואין ערך ממקור אחר

ב-[examples/terraform.tfvars](examples/terraform.tfvars) **בכוונה** אין `db_pass` — כדי לראות בשיעור את ה-prompt האינטראקטיבי בזמן אמת.

## `locals` — לא לבלבל עם `variable`

```hcl
locals {
  extra_tag = "extra-tag"
}
```
`local` הוא שם לביטוי לשימוש חוזר **בתוך הקובץ בלבד** — אי אפשר להזריק לו ערך מבחוץ, בניגוד ל-`variable`.

## `output` — החזרת מידע החוצה

```hcl
output "instance_ip_addr" {
  value = aws_instance.instance.private_ip
}
```
מציג ערכים שלא ידועים מראש (כמו IP שה-AWS מקצה) אחרי `apply`, או בכל רגע עם `terraform output`.

## מה השתנה ב-web-app לעומת 03-basics

ב-[web-app/variables.tf](web-app/variables.tf) כל מה שהיה hardcoded הפך למשתנה: `region`, `ami`, `instance_type`, `bucket_prefix`, `domain`, `db_name`, `db_user`, ו-**`db_pass` עם `sensitive = true`**. אותו קוד יכול עכשיו לשרת dev/staging/prod עם `.tfvars` שונה, בלי לגעת בקוד עצמו.

---
📖 להפניה מהירה לתחביר (סוגי משתנים, דוגמאות מלאות) — ראו [examples/003/README.md](examples/003/README.md) (באנגלית, מהקורס המקורי).
