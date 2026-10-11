# מדריך — לראות את ה-State Locking (DynamoDB) בפעולה

תרגיל מעשי להבנת תפקיד טבלת `terraform-state-locking`. דורש **שני חיבורי SSH נפרדים** ל-VM (שני טרמינלים).

## רקע קצר
כש-Terraform מריץ `apply`/`destroy` (לא `plan` רגיל), הוא כותב רשומה אחת ל-DynamoDB עם `LockID` (נתיב ה-state), `Who` ו-`Operation` — ומוחק אותה בסיום. זו ההגנה מפני שני אנשים שכותבים לאותו state בו-זמנית.

**דרישה מקדימה**: ה-backend כבר צריך להיות migrated ל-S3 (כלומר כבר עברתם את התהליך ב-`aws-backend`, או שאתם עובדים על `web-app` שכבר מוגדר עם backend מרחוק).

---

## שלב 1 — ודאו שהטבלה ריקה (מצב רגיל)

בטרמינל 1:
```bash
aws dynamodb scan --table-name terraform-state-locking
```
👀 **צפוי**: `"Items": []` — ריק, כי אין שום `apply` רץ כרגע.

## שלב 2 — התחילו `apply` ארוך

עבדו על `web-app` (יש שם RDS, זה לוקח כמה דקות — מספיק זמן לתפוס את הנעילה):

בטרמינל 1:
```bash
cd ~/00_devops_course_iccp/terraform/03-basics/web-app
terraform apply
```
אשרו עם `yes` והשאירו את זה רץ.

## שלב 3 — תפסו את הנעילה "באוויר" מטרמינל שני

**תוך כדי** שה-apply מטרמינל 1 עדיין רץ, בטרמינל 2 (SSH נפרד לאותו VM):
```bash
aws dynamodb scan --table-name terraform-state-locking
```
👀 **צפוי**: הפעם `Items` לא ריק — תראו שורה אחת עם שדות כמו `LockID`, `Who` (המשתמש/מחשב), ו-`Operation`.

💡 אם זה חוזר ריק — נסו שוב מהר יותר (ה-apply אולי כבר הסתיים). אפשר גם להריץ scan בלולאה כדי לתפוס את הרגע:
```bash
for i in {1..30}; do
  aws dynamodb scan --table-name terraform-state-locking --query 'Count' --output text
  sleep 2
done
```
👀 תראו `0` רוב הזמן, ו-`1` לרגע אחד או כמה שניות בזמן שה-apply כותב ל-state.

## שלב 4 — נסו להריץ `apply` שני בו-זמנית (אופציונלי, לאמיצים)

בזמן שהראשון עדיין רץ, פתחו **טרמינל שלישי** ונסו:
```bash
cd ~/00_devops_course_iccp/terraform/03-basics/web-app
terraform plan
```
👀 **צפוי**: שגיאת `Error acquiring the state lock` — עם פרטים מי מחזיק את הנעילה ומתי היא נוצרה. זה בדיוק המנגנון שמונע קורפציה כשעובדים בצוות.

## שלב 5 — אחרי שה-apply מסתיים

בטרמינל 1, חכו שה-`apply` יסתיים (`Apply complete!`), ואז בטרמינל 2:
```bash
aws dynamodb scan --table-name terraform-state-locking
```
👀 **צפוי**: חזר להיות `"Items": []` — הנעילה שוחררה אוטומטית.

---

## שאלת סיכום להבנה
למה הנעילה חייבת להיות ב-DynamoDB (או מנגנון דומה) ולא פשוט "קובץ flag" בתוך ה-S3 bucket עצמו?
<details>
<summary>רמז</summary>
S3 (בגרסאות ישנות יותר) לא תמך ב-conditional writes אטומיים ("כתוב רק אם לא קיים") — בלי זה, שני תהליכים יכולים "לחשוב" שהם תפסו את הנעילה בו-זמנית. DynamoDB תומך בזה native. (גרסאות חדשות של Terraform כן מאפשרות locking ישירות דרך S3 — זה בדיוק ה-`use_lockfile` מה-warning שראינו קודם.)
</details>
