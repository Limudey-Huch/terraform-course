# תרגיל 001 — `count`

## מטרה
ליצור כמה עותקים זהים (כמעט) של אותו משאב, בלי להעתיק-להדביק קוד.

## מה יש בקובץ

```hcl
resource "aws_s3_bucket" "lab" {
  count         = var.bucket_count
  bucket_prefix = "lab-05-001-${count.index}-"
  ...
}
```

- `count = 3` אומר ל-Terraform "תיצור 3 עותקים של המשאב הזה"
- בתוך הבלוק, `count.index` הוא מספר הרץ (0, 1, 2) של כל עותק — זה מה שמבדיל ביניהם (שם, tag)
- כל עותק נגיש בנפרד בעזרת `aws_s3_bucket.lab[0]`, `aws_s3_bucket.lab[1]` וכו'

👀 שימו לב ל-`[*]` ב-`output`:
```hcl
output "bucket_names" {
  value = aws_s3_bucket.lab[*].bucket
}
```
זה **splat expression** — אוסף את ה-`bucket` attribute מכל העותקים לתוך רשימה אחת, בלי ללולאה ידנית.

## המשימה

```bash
terraform init
terraform apply
```
👀 בדקו את ה-output `bucket_names` — אמורה להיות רשימה עם 3 שמות.

**שלב 2 — שנו את הכמות:**
```bash
terraform apply -var="bucket_count=5"
```
👀 Terraform יוסיף 2 buckets חדשים (index 3, 4) בלי לגעת בשלושת הראשונים.

**שלב 3 — עכשיו תקטינו:**
```bash
terraform apply -var="bucket_count=1"
```
👀 **שימו לב טוב**: Terraform ימחק buckets עם index 1, 2, 3, 4 (לא רק "עודפים" - הוא תמיד שומר על index 0 עד N-1 ומוחק את כל מה שמעל). זו בדיוק המגבלה של `count` שנראה בתרגיל הבא עם `for_each`.

## שאלת הבנה
אם היה לכם `count = 3` עם 3 buckets (index 0,1,2), ורציתם למחוק **רק** את האמצעי (index 1) — האם `count` מאפשר את זה בלי להשפיע על index 2? נסו וראו מה קורה בפלט של `plan`.

## ניקוי
```bash
terraform destroy
```
