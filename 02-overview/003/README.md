# תרגיל 003 — Load Balancer

## מטרה
להציב Application Load Balancer מול ה-EC2, ולהבין למה לא חושפים שרתים ישירות לאינטרנט.

## לפני שמתחילים — למדו מהתיעוד הרשמי
שלושה משאבים חדשים הפעם:

- **`aws_lb`** → <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb>
- **`aws_lb_target_group`** → <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group>
- **`aws_lb_listener`** → <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener>

וגם `data` source חדש שלא ראיתם עד עכשיו:
- **`aws_subnets`** → <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets> — "שואל" את AWS אילו subnets קיימים ב-VPC, כדי שה-LB ידע איפה לשבת

## מה חדש ב-main.tf הזה לעומת 002

שימו לב ל-**שני Security Groups נפרדים**:
- `alb_sg` — מרשה כניסה מהאינטרנט בפורט 80
- `instance_sg` — מרשה כניסה **רק מה-ALB עצמו** (`security_groups = [aws_security_group.alb_sg.id]`) בפורט 8080, לא מהאינטרנט ישירות

זה ה-pattern הנכון: ה-EC2 instance "מוסתר" מאחורי ה-LB.

## המשימה
1. `terraform init && terraform apply` (ייקח כמה דקות — LB לא נוצר מיידית)
2. בסוף ה-apply, יופיע output בשם `lb_dns_name` — פתחו אותו בדפדפן, תוך דקה-שתיים אמור להופיע "Hello from Terraform Lab 003"
3. **תרגיל**: בדקו ב-Console → EC2 → Target Groups → Health checks. למה לוקח כמה עשרות שניות עד שה-target הופך ל-`healthy`?

## ניקוי
```bash
terraform destroy
```
⚠️ מחיקת ALB לוקחת קצת זמן — תנו לזה להשלים.
