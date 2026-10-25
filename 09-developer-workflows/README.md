# מודול 09 — Developer Workflows + CI/CD

נושאי המודול (מהסילבוס המקורי): CI/CD, Multi account/project, Terragrunt, Test account + cloud nuke.

התרגיל המעשי במודול הזה מתמקד ב-**CI/CD עם GitHub Actions**.

## טופולוגיה

```
   מפתח/ה                        GitHub Actions                    AWS
┌───────────┐    git push      ┌──────────────────┐   OIDC token  ┌───────────────┐
│  laptop   │ ───────────────► │  Pull Request     │ ─────────────►│  IAM Role      │
│           │   (feature       │  → plan job:      │   (זמני,       │  (בלי access   │
│           │    branch)       │    fmt+init+plan  │   ~15 דקות)    │   key קבוע!)   │
└───────────┘                  │    + תגובה ב-PR   │               └───────┬───────┘
                                └──────────────────┘                        │
                                         │ code review + merge              │
                                         ▼                                  ▼
                                ┌──────────────────┐               ┌───────────────┐
                                │  push ל-main      │ ─────────────►│  S3 bucket     │
                                │  → apply job:     │   terraform   │  (app infra)   │
                                │    init + apply   │    apply      │                │
                                └──────────────────┘               └───────────────┘
```

**שתי תיקיות קוד, שתי מטרות**:
- **`bootstrap-oidc/`** — מורץ **ידנית, פעם אחת** (לא ב-CI!) — יוצר את חיבור האמון בין GitHub ל-AWS
- **`app/`** — זה מה ש-**GitHub Actions** מריץ אוטומטית בכל PR/merge — התשתית "האמיתית" של האפליקציה

## למה OIDC ולא `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` כ-GitHub Secrets?

זוכרים את הדיון על `db_pass` ולמה לא שמים סודות בקוד/ב-git? זו אותה בעיה בדיוק, רק ב-CI: access keys קבועים ב-GitHub Secrets הם עדיין **סוד קבוע וארוך-טווח** ששוכב במקום אחד — אם דולף (לוג שהודפס בטעות, repo שהפך זמנית ל-public, employee offboarding לא תקין) הוא תקף **עד שמישהו שם לב ומבטל אותו ידנית**.

**OIDC** הופך את זה: GitHub Actions "מבקש" מ-AWS טוקן זמני (תקף לכמה דקות) בכל הרצה, בלי שום סוד קבוע בכלל. ה-trust policy ב-AWS מגביל בדיוק מי מורשה לבקש (`repo:<org>/<repo>:*`).

## ⚠️ הערה חשובה על מבנה התיקיות לפני שמתחילים

הקבצים כאן (`bootstrap-oidc/`, `app/`, `.github/`) יושבים בתוך ריפו הקורס הראשי, לצורך ארגון וקריאה נוחה. אבל **GitHub Actions רק מזהה `.github/workflows/` בשורש של ריפו** — כדי שה-workflow באמת ירוץ, צריך **לדחוף את התוכן של התיקייה הזו (לא כל ריפו הקורס!) לריפו GitHub נפרד משלכם**, עם `.github/workflows/terraform.yml` בשורש שלו.

דרך מומלצת:
```bash
# מתוך 09-developer-workflows/, ייצוא לריפו נפרד:
mkdir ~/Desktop/devOps/09-terraform-ci-cd
cp -r bootstrap-oidc app .github README.md ~/Desktop/devOps/09-terraform-ci-cd/
cd ~/Desktop/devOps/09-terraform-ci-cd
git init
git remote add origin https://github.com/<your-org>/09-terraform-ci-cd.git
```

## שלב 1 — Bootstrap (חד פעמי, ידני)

```bash
cd bootstrap-oidc
terraform init
terraform apply -var="github_org=<your-org>" -var="github_repo=09-terraform-ci-cd"
```

👀 בסוף ה-apply, תקבלו `role_arn` ב-output. **העתיקו אותו** ל-`.github/workflows/terraform.yml`, לשדה `ROLE_ARN`.

⚠️ אם תקבלו שגיאה ש-OIDC provider כבר קיים בחשבון — זה בסדר, פשוט מחקו את בלוק `aws_iam_openid_connect_provider` מה-קוד, והחליפו את ההפניה אליו ב-`aws_iam_role` ב-data source:
```hcl
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}
```

## שלב 2 — חיבור הריפו והעלאה

```bash
git add .
git commit -m "Initial CI/CD lab setup"
git branch -M main
git push -u origin main
```

## שלב 3 — התרגיל עצמו: לראות PR plan בפעולה

```bash
git checkout -b feature/add-tag
```
ערכו את `app/main.tf` — הוסיפו tag חדש ל-`aws_s3_bucket.app_data` (למשל `Environment = "lab"`).

```bash
git add app/main.tf
git commit -m "Add Environment tag"
git push -u origin feature/add-tag
```

פתחו Pull Request ב-GitHub. 👀 **תוך דקה-שתיים** אמורה להופיע תגובה אוטומטית ב-PR עם ה-`terraform plan` המלא — בלי שהרצתם שום פקודת terraform בעצמכם!

## שלב 4 — Merge ← Apply אוטומטי

אשרו ומזגו את ה-PR ל-`main`. 👀 עכשיו ה-job השני (`apply`) אמור לרוץ אוטומטית ולהחיל את השינוי בפועל. בדקו ב-AWS Console שה-tag אכן נוסף ל-bucket.

## שאלות הבנה

1. למה ה-`plan` job רץ על `pull_request` וה-`apply` job רץ על `push` ל-`main`, ולא שניהם על אותו trigger?
2. מה היה קורה אם מישהו היה פותח PR מ-fork (לא מאותו ריפו)? (רמז: תסתכלו שוב על ה-`StringLike` condition ב-trust policy)
3. ה-`paths: ["app/**"]` ב-workflow trigger — למה זה חשוב שה-workflow **לא** ירוץ על כל שינוי בריפו (למשל שינוי ב-README)?

## ניקוי

```bash
cd app
terraform destroy -auto-approve

cd ../bootstrap-oidc
terraform destroy -auto-approve -var="github_org=<your-org>" -var="github_repo=09-terraform-ci-cd"
```
⚠️ מחקו את ה-`app` infra **לפני** ה-`bootstrap-oidc` — אחרת תאבדו את ההרשאה להריץ terraform דרך ה-role לפני שסיימתם.

## אתגר מסכם — CI/CD ל-API שרת-less

אחרי שהבנתם את התרגיל למעלה, יש תרגיל חוזים נפרד ב-[`challenge-cicd/`](challenge-cicd/README.md): Lambda + API Gateway + DynamoDB, ו-pipeline שאתם כותבים בעצמכם (plan ב-PR, apply אחרי merge, smoke test). אין פתרון ואין סקריפט בדיקה.

## רפרנס נוסף
דוגמה רשמית של HashiCorp ל-GitHub Actions + Terraform:
<https://github.com/hashicorp/learn-terraform-github-actions/blob/master/.github/workflows/terraform.yml>
