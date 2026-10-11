# תרגיל 003 — Expressions & Functions

## מטרה
להכיר כמה ביטויים ופונקציות שימושיות ב-HCL — בלי שום משאב/קונספט חדש, רק "שפה".

## מה יש בקובץ — 4 דברים חדשים

**1. Conditional expression (ternary)** — בדיוק כמו ב-JavaScript/Python:
```hcl
is_prod        = var.environment == "prod"
retention_days = local.is_prod ? 30 : 3
# condition ? true_val : false_val
```

**2. String functions**:
```hcl
team_csv = join(", ", var.team_members)   # ["eyal","dana","noa"] -> "eyal, dana, noa"
upper(var.environment)                     # "dev" -> "DEV"
lower(var.environment)                     # "DEV" -> "dev"
length(var.team_members)                   # 3
```

**3. For expression** — טרנספורמציה של רשימה שלמה, בלי לולאה ידנית:
```hcl
team_upper = [for name in var.team_members : upper(name)]
# ["eyal","dana","noa"] -> ["EYAL","DANA","NOA"]
```
שימו לב להבדל מ-`for_each` (תרגיל 002) — `for_each` יוצר **משאבים**, `for` expression (בתוך `[...]`) יוצר **ערך** (רשימה/map) בתוך `locals`/`output`. אותה מילה, שימוש שונה לגמרי.

## המשימה

```bash
terraform init
terraform apply
```
👀 תבדקו את שני ה-outputs: `team_upper` (רשימה עם שמות באותיות גדולות) ו-`is_prod` (אמור להיות `false`).

**שלב 2 — שנו ל-production:**
```bash
terraform apply -var="environment=prod"
```
👀 `is_prod` אמור להפוך ל-`true`, וה-tag `RetentionDays` ב-S3 bucket (בדקו בקונסולה) אמור לעלות מ-3 ל-30 — **בלי** שנגעתם בלוגיקה עצמה, רק שיניתם את הקלט.

## תרגיל הרחבה
הוסיפו פונקציה נוספת מהתיעוד (<https://registry.terraform.io/providers/hashicorp/aws/latest/docs> → Functions) — למשל `trimspace()` או `substr()` — על אחד הערכים הקיימים, והריצו שוב.

## שאלת הבנה
למה `retention_days` הוא `local` ולא `variable`? (רמז: חישבו האם זה קלט שמישהו אמור לספק מבחוץ, או תוצאה מחושבת מתוך קלט אחר)

## ניקוי
```bash
terraform destroy
```
