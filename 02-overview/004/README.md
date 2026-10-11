# תרגיל 004 — RDS Database

## מטרה
להקים מסד נתונים מנוהל (RDS), ולתרגל שימוש נכון במשתנה `sensitive` לסיסמה (כמו שלמדתם במודול 04).

## לפני שמתחילים — למדו מהתיעוד הרשמי
**`aws_db_instance`** → <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance>

שימו לב בעמוד ל:
- `engine` / `engine_version` — איזה מסד נתונים (postgres, mysql, וכו') ואיזו גרסה
- `instance_class` — "גודל" המכונה שמריצה את ה-DB (למשל `db.t3.micro`)
- `skip_final_snapshot` — אם `false` (ברירת המחדל), Terraform ידרוש גיבוי לפני מחיקה. ל-lab זמני שמים `true`

## המשימה
ב-[main.tf](main.tf) יש משתנה `db_pass` **בלי default וללא ערך** — בכוונה.

1. `terraform init`
2. `terraform apply` — Terraform ישאל אתכם להזין סיסמה (Prompt אינטראקטיבי, בדיוק כמו במודול 04)
3. **לחלופין**, הריצו עם ערך מפורש בלי prompt:
   ```bash
   terraform apply -var="db_pass=SomeStrongPass123!"
   ```
4. בסוף ה-apply, שימו לב ל-output `db_endpoint`

## שאלת הבנה
למה `password = var.db_pass` לא גורם לסיסמה "להיחשף" בפלט של `terraform plan`/`apply`? ומה בכל זאת **כן** קורה לסיסמה הזו בתוך קובץ ה-state (`terraform.tfstate`)?

## ניקוי
```bash
terraform destroy
```
⚠️ מחיקת RDS עשויה לקחת כמה דקות.
