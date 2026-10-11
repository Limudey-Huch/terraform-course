# גרסה חלופית — OIDC דרך מודול מוכן

זו **אותה תוצאה בדיוק** כמו ב-[../bootstrap-oidc/](../bootstrap-oidc/) (OIDC provider + IAM role ש-GitHub Actions יכול "ללבוש") — רק דרך מודול קהילתי מוכן במקום כתיבה ידנית.

## מקור המודול
<https://registry.terraform.io/modules/philips-labs/github-oidc/aws> — **1.1 מיליון הורדות**, לא archived, יציב.

## השוואה ישירה

| | `bootstrap-oidc/` (ידני) | `bootstrap-oidc-module/` (מודול) |
|---|---|---|
| כמות קוד | ~60 שורות | ~20 שורות |
| הגבלת גישה | כל branch/PR/tag בריפו (`repo:org/repo:*`) | רק `main`, PRs **חסומים** במפורש כברירת מחדל |
| גמישות | צריך לכתוב תנאים חדשים ידנית | `default_conditions`, `github_environments` מוכנים |
| תחזוקה | אתם אחראים על כל עדכון עתידי | הקהילה מתחזקת |

## 🔍 תגלית אמיתית תוך כדי בניית הדוגמה הזו

כש-ה-provider submodule נבדק, התברר שה-**default** של `thumbprint_list` במודול הוא:
```
6938fd4d98bab03faadb97b34396831e3780aea1
```
זה **בדיוק** אותו thumbprint ישן ומוטעה שכמעט שמנו ב-`bootstrap-oidc/` ותיקנו רק אחרי שבדקנו ישירות מול השרת! גם מודול עם מיליון+ הורדות יכול לשאת ערך default שלא עודכן מאז ש-GitHub עברו ל-CA חדש. בקוד כאן יש `override` מפורש ל-thumbprint הנכון שאימתנו.

💡 **המסקנה הפדגוגית**: "פופולרי ומתוחזק" ≠ "כל שורת קוד בו תמיד מעודכנת". עדיין שווה להציץ בהגדרות קריטיות לאבטחה, גם כשסומכים על מודול טוב.

## המשימה
הריצו את זה **לחשבון/repo אחר** מ-`bootstrap-oidc/` (למשל שם role שונה), כדי לא להתנגש עם ה-OIDC provider שכבר קיים מהגרסה הידנית:

```bash
terraform init
terraform apply -var="github_org=<your-org>" -var="github_repo=09-terraform-ci-cd"
```

⚠️ אם כבר הרצתם את `bootstrap-oidc/` קודם, יש לכם כבר OIDC provider בחשבון — תקבלו שגיאת "already exists" על `module.oidc_provider`. זה צפוי: ל-AWS מותר provider אחד בלבד לכל URL. מחקו את בלוק `module "oidc_provider"` כאן, והחליפו את ההפניה ב-`module.oidc_role` ל:
```hcl
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}
# ואז: openid_connect_provider_arn = data.aws_iam_openid_connect_provider.github.arn
```

## ניקוי
```bash
terraform destroy -auto-approve -var="github_org=<your-org>" -var="github_repo=09-terraform-ci-cd"
```
