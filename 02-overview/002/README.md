# תרגיל 002 — Security Group

## מטרה
לחבר EC2 instance ל-Security Group משלו, ולהבין את מושג ה-firewall ברמת AWS.

## לפני שמתחילים — למדו מהתיעוד הרשמי
**`aws_security_group`** → <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group>

שימו לב בעמוד ל:
- בלוקים `ingress` (תעבורה נכנסת) ו-`egress` (תעבורה יוצאת) — כל אחד מגדיר `from_port`, `to_port`, `protocol`, `cidr_blocks`
- `cidr_blocks = ["0.0.0.0/0"]` אומר "מכל כתובת IP בעולם" — זה בסדר ל-HTTP, אבל **בעייתי** ל-SSH (פורט 22)

## המשימה
ב-[main.tf](main.tf) כבר מוגדר SG עם כללי ingress ל-HTTP (80) ו-SSH (22) מכל מקום, ו-EC2 instance שמחובר אליו דרך `vpc_security_group_ids`.

1. `terraform init && terraform apply`
2. בקונסולה, היכנסו ל-EC2 → Security Groups ובדקו שהכללים תואמים למה שכתבתם
3. **תרגיל הקשחה**: שנו את כלל ה-SSH כך שיאפשר גישה **רק מכתובת ה-IP שלכם** (חפשו "what is my ip" בגוגל, והחליפו את `cidr_blocks` לכלל הזה ל-`["<היפ-שלכם>/32"]`)

## שאלת הבנה
למה `/32` ולא `/24` בכלל שהוספתם? (רמז: זה קשור לכמה כתובות ה-CIDR הזה מכסה)

## ניקוי
```bash
terraform destroy
```
