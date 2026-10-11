# יצירת Shared Folder (Mount Point) — Windows + VMware Workstation

מדריך קצר לחשיפת תיקייה מהמחשב (Windows) לתוך ה-Ubuntu VM.

## שלב 1: הפעלת Shared Folder בהגדרות ה-VM

1. פתחו את **VMware Workstation**
2. סמנו את ה-VM (לא חובה לכבות אותו) ולחצו **VM → Settings**
3. עברו ללשונית **Options → Shared Folders**
4. בחרו **Always enabled**
5. לחצו **Add** ובחרו את התיקייה ב-Windows שתרצו לחשוף
6. סמנו **Enable this share**, ואם צריך גם הרשאות כתיבה

## שלב 2: התקנת open-vm-tools בתוך ה-Ubuntu VM

בטרמינל של ה-VM:

```bash
sudo apt update
sudo apt install -y open-vm-tools open-vm-tools-desktop
```

## שלב 3: איתור התיקייה

התיקייה עולה אוטומטית תחת:

```bash
ls /mnt/hgfs/
```

השם שיופיע הוא בדיוק השם שנתתם לתיקייה ב-Windows (שלב 1).

אם `/mnt/hgfs` ריק או לא קיים:

```bash
sudo mkdir -p /mnt/hgfs
sudo vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other -o uid=$(id -u) -o gid=$(id -g)
```

## שלב 4: Mount אוטומטי בכל אתחול (מומלץ)

```bash
echo ".host:/ /mnt/hgfs fuse.vmhgfs-fuse defaults,allow_other,uid=$(id -u),gid=$(id -g) 0 0" | sudo tee -a /etc/fstab
```

## שלב 5: יצירת סימלינק בתיקיית הבית

כדי לא לכתוב את הנתיב המלא כל פעם:

```bash
ln -s /mnt/hgfs/<שם-התיקייה> ~/<שם-קצר>
```

לדוגמה:

```bash
ln -s /mnt/hgfs/devops-course ~/devops-course
```

## בדיקה

```bash
touch ~/<שם-קצר>/test.txt
```

והקובץ אמור להופיע מיד גם בתיקייה המקורית ב-Windows.
