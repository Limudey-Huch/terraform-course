# תרגיל 004 — `lifecycle`

## מטרה
לראות בעיניים את ההבדל שעושה `create_before_destroy`, ואת מה ש-`prevent_destroy` עוצר.

## חלק א׳ — `create_before_destroy`

`bucket_prefix` הוא שדה שאי אפשר לשנות במשאב קיים (ForceNew) — כל שינוי בו גורם ל-Terraform **להחליף** את ה-bucket (destroy + create), לא לעדכן אותו.

**ברירת המחדל** (בלי `lifecycle`): Terraform קודם **הורס** את הישן, ורק **אחר כך** יוצר את החדש. יש רגע אמיתי שבו שום bucket לא קיים.

```hcl
lifecycle {
  create_before_destroy = true
}
```
עם זה, הסדר **הפוך**: קודם נוצר ה-bucket החדש, ורק אחרי שהוא קיים בהצלחה — נמחק הישן. אין רגע של "כלום לא קיים".

### המשימה

```bash
terraform init
terraform apply
```
👀 שימו לב לשם ה-bucket ב-output.

**עכשיו גרמו להחלפה:**
```bash
terraform apply -var="bucket_suffix=v2"
```
👀 **תסתכלו טוב בפלט של ה-plan**: תראו `# forces replacement`, ואז בסדר הביצוע בפועל — `Creating...` **לפני** `Destroying...` (ולא ההפך). זו ההוכחה הויזואלית ל-`create_before_destroy`.

💡 **תרגיל השוואה**: תורידו זמנית את בלוק ה-`lifecycle` כולו, תריצו `apply -var="bucket_suffix=v3"`, ותשוו את סדר הפעולות בפלט (הפעם `Destroying...` לפני `Creating...`).

## חלק ב׳ — `prevent_destroy`

זה "נעילת בטיחות" שמונעת מחיקה בטעות של משאב קריטי.

**הוסיפו** לבלוק ה-`lifecycle` הקיים:
```hcl
lifecycle {
  create_before_destroy = true
  prevent_destroy       = true
}
```
תריצו `terraform apply` (כדי שהשינוי ב-lifecycle עצמו ייקלט - אין בזה שינוי resource בפועל).

**עכשיו נסו למחוק:**
```bash
terraform destroy
```
👀 **צפוי**: Terraform **יסרב**, עם שגיאה מפורשת שמזכירה `prevent_destroy`.

**כדי לנקות בסוף** - חובה להסיר את `prevent_destroy = true` מהקוד (או את כל הבלוק) **לפני** שה-`destroy` יעבוד:
```bash
terraform apply   # להחיל את ההסרה
terraform destroy # עכשיו כן יעבוד
```

## שאלת הבנה
באיזה משאבים אמיתיים (לא בלאב) הייתם שוקלים להוסיף `prevent_destroy = true` קבוע? (רמז: חשבו על משהו שמחיקה בטעות שלו תהיה אסון - למשל production database)

## ניקוי
ראו "חלק ב׳" למעלה - קודם מסירים `prevent_destroy`, רק אז `destroy` עובד.
