# תרגיל 001 — EC2 Instance

## מטרה
להקים משאב ראשון ב-AWS באמצעות Terraform, ולהתרגל קריאה בתיעוד הרשמי.

## לפני שמתחילים — למדו מהתיעוד הרשמי
היכנסו ל-[Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) וחפשו את המשאב:

**`aws_instance`** → <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance>

שימו לב בעמוד לשני חלקים:
- **Argument Reference** — אילו שדות חובה (required) ואילו אופציונליים (optional)
- **Attribute Reference** — אילו ערכים Terraform "מחזיר" אחרי היצירה (כמו `id`, `public_ip`)

## המשימה
הקובץ [main.tf](main.tf) כבר מכיל `resource "aws_instance" "example"` מינימלי: `ami` + `instance_type`.

1. הריצו `terraform init`, `terraform plan`, `terraform apply`
2. בקונסולת AWS, אתרו את ה-instance שנוצר ובדקו שה-region וה-AMI תואמים למה שציפיתם
3. **הרחיבו את הקובץ**: הוסיפו תג (`tags`) עם `Name` למכונה — חפשו בתיעוד איך בדיוק נראה ה-argument `tags` (רמז: זה `map(string)`)

## בדיקה
```bash
terraform state show aws_instance.example
```
ודאו שה-tag שהוספתם מופיע גם בפלט וגם בקונסולה.

## ניקוי
```bash
terraform destroy
```
