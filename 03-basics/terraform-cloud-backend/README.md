# Terraform Cloud Backend — הסבר

זו חלופה ל-remote backend מבוסס S3+DynamoDB (ראו `../aws-backend/README.md`) — פתרון עם גישה שונה לגמרי לאחסון ה-state.

## ההבדל המהותי מ-S3 Backend

ב-S3 backend, **אתה** בונה את התשתית לאחסון ה-state (bucket, DynamoDB table) — זה ה"תרנגולת וביצה" (chicken and egg) שדורש bootstrap עצמאי. ב-**Terraform Cloud**, החברה שמפתחת את Terraform (HashiCorp) מפעילה שירות SaaS מוכן שעושה בדיוק את זה בשבילך — **אין chicken-and-egg בכלל**. נרשמים לחשבון, ומקבלים מקום מוכן לאחסון state, עם locking, versioning והצפנה — הכל built-in, בלי ליצור שום משאב בעצמכם.

## מה כל שדה בקובץ אומר

```hcl
backend "remote" {
  organization = "devops-directive"

  workspaces {
    name = "devops-directive-terraform-course"
  }
}
```

- **`organization`** — זה כמו "החשבון/הצוות" שלך ב-[app.terraform.io](https://app.terraform.io) (הפלטפורמה של HashiCorp). `devops-directive` הוא ה-org של יוצר הקורס המקורי — **הוא לא קיים אצלכם**, וצריך להחליף בשם ה-org שתיצרו בחשבון שלכם.
- **`workspaces.name`** — Workspace ב-Terraform Cloud הוא כמו "פרויקט/סביבה" בודדת: יש לו state נפרד, היסטוריית הרצות (runs) נפרדת, ומשתני סביבה/variables נפרדים משלו. שם אחד = state אחד.

## מה בפועל צריך לעשות כדי שזה יעבוד

1. **להירשם** ל-[app.terraform.io](https://app.terraform.io) (חשבון חינמי מספיק ללימוד)
2. **ליצור Organization** משלכם, ולהחליף את `devops-directive` בקובץ בשם שלה
3. **להתחבר מה-VM**:
   ```bash
   terraform login
   ```
   זה פותח דפדפן ל-OAuth ושומר API token מקומית (ב-`~/.terraform.d/credentials.tfrc.json`) — כל פעולת `init/plan/apply` עתידית תזדהה דרך ה-token הזה.
4. `terraform init` — אם ה-workspace עם השם שהגדרתם לא קיים עדיין ב-org, Terraform ייצור אותו אוטומטית.

## הבדל נוסף וחשוב: איפה ה-`apply` בפועל רץ

ב-S3 backend, ה-state נשמר מרוחק, אבל ה**חישוב עצמו** (`plan`/`apply`) עדיין רץ על המחשב/VM שלכם. ב-Terraform Cloud, ברירת המחדל היא **remote execution** — כלומר ה-`apply` בפועל **רץ בשרתים של HashiCorp**, לא אצלכם. רואים את הפלט בזמן אמת בטרמינל (וגם ב-UI של app.terraform.io), אבל ה-worker שמריץ את הפקודות נמצא בענן שלהם.

## טבלת השוואה: S3+DynamoDB מול Terraform Cloud

| | S3 + DynamoDB | Terraform Cloud |
|---|---|---|
| מי מנהל את אחסון ה-state | אתם (bucket משלכם) | HashiCorp (SaaS) |
| Setup ראשוני | דורש bootstrap (`aws-backend`) | רק הרשמה + `terraform login` |
| היכן רץ `apply` | אצלכם מקומית | בשרתי HashiCorp (ברירת מחדל) |
| עלות | S3+DynamoDB כמעט חינם | טיר חינמי מוגבל, בתשלום לצוותים גדולים |
| שימוש נפוץ בפועל | ארגונים שכבר ב-AWS, רוצים שליטה מלאה | צוותים שרוצים UI/collaboration מוכן בלי לבנות תשתית |

💡 **הערה להוראה**: אפשר להציג את זה כ"יש עוד דרך" בלי בהכרח להריץ בפועל עם תלמידים (כי זה דורש הרשמה לחשבון נוסף) — ואם כן רוצים תרגול מעשי, לוודא מראש שכל תלמיד יצר org/workspace משלו לפני השיעור.
