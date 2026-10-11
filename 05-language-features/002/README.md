# תרגיל 002 — `for_each`

## מטרה
לראות למה `for_each` עדיף על `count` כשהעותקים **לא** רק "N פעמים אותו דבר", אלא כל אחד עם שם/זהות משלו.

## מה יש בקובץ

```hcl
resource "aws_s3_bucket" "lab" {
  for_each      = var.environments   # set(string): ["dev", "staging", "prod"]
  bucket_prefix = "lab-05-002-${each.value}-"
  ...
}
```

- `for_each` רץ על `set` (או `map`) — לא על מספר כמו `count`
- בתוך הבלוק, `each.value` הוא הערך הנוכחי (ו-`each.key` זהה ל-`each.value` כש-for_each רץ על `set`; אם היה `map`, `each.key` היה המפתח ו-`each.value` הערך)
- כל עותק נגיש בעזרת `aws_s3_bucket.lab["dev"]`, `aws_s3_bucket.lab["prod"]` וכו' — **לפי שם**, לא לפי אינדקס מספרי

## ההבדל הקריטי מ-`count` (מתרגיל 001)

ב-`count`, Terraform מזהה כל עותק לפי **מיקום ברשימה** (0, 1, 2...) — אם מוחקים את האמצעי, הכל "זז" ו-Terraform הורס ובונה מחדש דברים שלא באמת השתנו.

ב-`for_each`, Terraform מזהה כל עותק לפי ה-**key עצמו** (`"dev"`, `"staging"`, `"prod"`) — אם מורידים `"staging"`, Terraform יודע בדיוק איזה bucket למחוק, ולא נוגע בשאר.

## המשימה

```bash
terraform init
terraform apply
```
👀 בדקו את ה-output `bucket_names` — הפעם זה **map**, לא list, עם שם הסביבה כ-key.

**שלב 2 — תורידו "staging" מהרשימה:**

ערכו את ה-`default` של `environments` ב-`main.tf` להיות `["dev", "prod"]` (בלי staging), ואז:
```bash
terraform apply
```
👀 **זו הנקודה המרכזית של התרגיל**: `terraform plan` אמור להראות **רק** `1 to destroy` (ה-bucket של staging) — `dev` ו-`prod` לא מוצגים בכלל כ"שינוי", כי Terraform מזהה אותם לפי השם, לא לפי מיקום.

השוו לתרגיל 001: שם, הקטנת `count` מ-3 ל-1 מחקה גם את index 2 **וגם** את index 1, גם אם רק רציתם להוריד אחד "מהאמצע".

## שאלת הבנה
מתי בכל זאת הגיוני להשתמש ב-`count` במקום `for_each`? (רמז: תחשבו על מצב שבו כל העותקים באמת זהים לגמרי, ואין להם "זהות" משמעותית משלהם)

## ניקוי
```bash
terraform destroy
```
