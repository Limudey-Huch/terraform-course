# תרגיל — מודול מה-Terraform Registry

## מטרה
לראות שימוש במודול **חיצוני** שלא כתבתם, ושמתעדכן ומתוחזק באופן פעיל — בניגוד למקור הישן (`terraform-aws-consul`) שהיה כאן קודם ונזנח ב-2022.

## מקור המודול
<https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest>

מתוחזק ע"י קהילת `terraform-aws-modules` — אחת מקבוצות המודולים הפופולריות והאמינות ביותר ב-Registry (יש להם מודולים כמעט לכל משאב AWS נפוץ: VPC, EC2, RDS, EKS...).

## מה חדש בקובץ לעומת מודול מקומי (`../web-app-module`)

```hcl
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"  # לא נתיב מקומי!
  version = "~> 5.0"                                 # ← פינינג גרסה, קריטי למודול חיצוני
  ...
}
```

- **`source`** בפורמט `<namespace>/<name>/<provider>` — זה המזהה של המודול ב-Registry עצמו, לא כתובת git/נתיב
- **`version`** — **חובה בפועל** כשעובדים עם מודול חיצוני (בניגוד למודול מקומי משלכם, ששולט בו ישירות). בלי pinning, `terraform init` עלול למשוך גרסה חדשה יותר שבירה לקוד שלכם ביום מן הימים

## המשימה

```bash
terraform init
```
👀 שימו לב לפלט — Terraform מוריד את **קוד המודול עצמו** (לא רק provider plugin כמו קודם) לתוך `.terraform/modules/`.

```bash
terraform apply
```
👀 בדקו את ה-outputs `bucket_id`/`bucket_arn` — אלה attributes שהמודול **חושף** החוצה (output משלו), לא attributes גולמיים של `aws_s3_bucket`.

## תרגיל חקירה
היכנסו ל-`.terraform/modules/s3_bucket/` (אחרי `init`) ותראו את קוד המודול בפועל שהורד — בדיוק כמו `web-app-module` שלכם, רק שמישהו אחר כתב אותו.

## שאלת הבנה
למה דווקא עם מודול **חיצוני** פינינג גרסה (`version = "~> 5.0"`) חשוב הרבה יותר מאשר עם מודול מקומי משלכם (`../web-app-module`)?

## ניקוי
```bash
terraform destroy
```
